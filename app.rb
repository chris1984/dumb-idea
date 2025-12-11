require 'dotenv/load'
require 'sinatra'
require 'sinatra/json'
require 'sqlite3'
require 'mail'
require 'logger'

# Allow access from any host (for development/local network access)
set :protection, except: [:host_authorization]

# Admin credentials from environment
ADMIN_USERNAME = ENV['ADMIN_USERNAME'] || 'admin'
ADMIN_PASSWORD = ENV['ADMIN_PASSWORD'] || 'changeme'

# Configure logging
LOG = Logger.new('submissions.log', 'daily')
LOG.level = Logger::INFO

# Email configuration
# IMPORTANT: Update these settings with your email credentials
Mail.defaults do
  delivery_method :smtp, {
    address: ENV['SMTP_ADDRESS'] || 'smtp.gmail.com',
    port: ENV['SMTP_PORT'] || 587,
    user_name: ENV['SMTP_USERNAME'],
    password: ENV['SMTP_PASSWORD'],
    authentication: 'plain',
    enable_starttls_auto: true
  }
end

ADMIN_EMAIL = ENV['ADMIN_EMAIL'] || 'your-email@example.com'

# Database connection
def db
  @db ||= SQLite3::Database.new('ideas.db')
  @db.results_as_hash = true
  @db
end

# Rate limiting configuration
RATE_LIMIT_MAX_ATTEMPTS = 3  # Max submissions allowed
RATE_LIMIT_WINDOW = 3600     # Time window in seconds (1 hour)

# Profanity filter - basic word list
PROFANITY_LIST = [
  'fuck', 'shit', 'damn', 'bitch', 'ass', 'bastard', 'crap',
  'cock', 'dick', 'pussy', 'cunt', 'whore', 'slut', 'piss',
  'nazi', 'hitler', 'rape', 'kill yourself', 'kys'
].freeze

# Admin authentication helper
helpers do
  def protected!
    return if authorized?
    headers['WWW-Authenticate'] = 'Basic realm="Restricted Area"'
    halt 401, "Not authorized\n"
  end

  def authorized?
    @auth ||= Rack::Auth::Basic::Request.new(request.env)
    @auth.provided? && @auth.basic? && @auth.credentials &&
      @auth.credentials == [ADMIN_USERNAME, ADMIN_PASSWORD]
  end

  # Check if IP has exceeded rate limit
  def rate_limited?(ip_address)
    # Clean up old rate limit records (older than the time window)
    db.execute(
      "DELETE FROM rate_limits WHERE attempt_time < datetime('now', '-#{RATE_LIMIT_WINDOW} seconds')"
    )

    # Count recent attempts from this IP
    result = db.execute(
      "SELECT COUNT(*) as count FROM rate_limits
       WHERE ip_address = ?
       AND attempt_time >= datetime('now', '-#{RATE_LIMIT_WINDOW} seconds')",
      [ip_address]
    )

    count = result.first['count']
    count >= RATE_LIMIT_MAX_ATTEMPTS
  end

  # Record a rate limit attempt
  def record_rate_limit_attempt(ip_address)
    db.execute(
      'INSERT INTO rate_limits (ip_address, attempt_time) VALUES (?, datetime("now"))',
      [ip_address]
    )
  end

  # Get time until rate limit resets for an IP
  def rate_limit_reset_time(ip_address)
    result = db.execute(
      "SELECT attempt_time FROM rate_limits
       WHERE ip_address = ?
       ORDER BY attempt_time ASC
       LIMIT 1",
      [ip_address]
    )

    return 0 if result.empty?

    oldest_attempt = Time.parse(result.first['attempt_time'])
    reset_time = oldest_attempt + RATE_LIMIT_WINDOW
    seconds_until_reset = (reset_time - Time.now).to_i

    [seconds_until_reset, 0].max
  end

  # Check if text contains profanity
  def contains_profanity?(text)
    return false if text.nil? || text.empty?

    normalized_text = text.downcase.gsub(/[^a-z0-9\s]/, ' ')

    PROFANITY_LIST.any? do |word|
      normalized_text.include?(word)
    end
  end

  # Get list of profane words found in text
  def find_profane_words(text)
    return [] if text.nil? || text.empty?

    normalized_text = text.downcase.gsub(/[^a-z0-9\s]/, ' ')

    PROFANITY_LIST.select do |word|
      normalized_text.include?(word)
    end
  end
end

# Error handlers
not_found do
  erb :error_404
end

error 500 do
  erb :error_500
end

# Main route - serve the HTML page
get '/' do
  # Set cache headers (5 minute cache for HTML)
  cache_control :public, :must_revalidate, max_age: 300

  # Get stats for footer
  total_ideas = db.execute('SELECT COUNT(*) as count FROM ideas').first['count']
  total_submissions = db.execute('SELECT COUNT(*) as count FROM user_submissions').first['count']
  approved_submissions = db.execute("SELECT COUNT(*) as count FROM user_submissions WHERE status = 'approved'").first['count']

  erb :index, locals: {
    total_ideas: total_ideas,
    total_submissions: total_submissions,
    approved_submissions: approved_submissions
  }
end

# API endpoint to get a random curated idea
get '/api/random-idea' do
  # No caching - always return fresh random idea
  cache_control :no_cache, :no_store, :must_revalidate

  result = db.execute('SELECT idea FROM ideas ORDER BY RANDOM() LIMIT 1')

  if result.empty?
    json error: 'No ideas found'
  else
    json idea: result.first['idea']
  end
end

# API endpoint to submit a new idea
post '/api/submit-idea' do
  content_type :json

  payload = JSON.parse(request.body.read)
  idea = payload['idea']

  # Get user info for logging and rate limiting
  ip_address = request.ip
  user_agent = request.user_agent

  # Check rate limit
  if rate_limited?(ip_address)
    reset_time = rate_limit_reset_time(ip_address)
    minutes = (reset_time / 60.0).ceil

    LOG.warn("Rate limit exceeded for IP: #{ip_address}")
    status 429
    return json(
      error: "You've submitted too many ideas. Please try again in #{minutes} minute#{'s' if minutes != 1}.",
      retry_after: reset_time
    )
  end

  if idea.nil? || idea.strip.empty?
    status 400
    return json error: 'Idea cannot be empty'
  end

  if idea.length > 500
    status 400
    return json error: 'Idea is too long (max 500 characters)'
  end

  # Check for profanity
  has_profanity = contains_profanity?(idea)
  flagged_words = has_profanity ? find_profane_words(idea).join(', ') : nil

  # Save to database
  begin
    db.execute(
      'INSERT INTO user_submissions (idea, ip_address, user_agent, profanity_flagged, flagged_words) VALUES (?, ?, ?, ?, ?)',
      [idea, ip_address, user_agent, has_profanity ? 1 : 0, flagged_words]
    )

    submission_id = db.last_insert_row_id

    # Record this submission for rate limiting
    record_rate_limit_attempt(ip_address)

    # Log the submission
    if has_profanity
      LOG.warn("Profanity flagged submission [ID: #{submission_id}] from #{ip_address}: #{idea} (Words: #{flagged_words})")
    else
      LOG.info("New idea submitted [ID: #{submission_id}] from #{ip_address}: #{idea}")
    end

    # Send email notification
    begin
      send_notification_email(submission_id, idea, ip_address, user_agent, has_profanity, flagged_words)
    rescue => e
      LOG.error("Failed to send email notification: #{e.message}")
      # Don't fail the request if email fails
    end

    json success: true, message: 'Thank you for your submission! It will be reviewed.'
  rescue => e
    LOG.error("Failed to save submission: #{e.message}")
    status 500
    json error: 'Failed to save submission'
  end
end

# API endpoint to check rate limit status
get '/api/rate-limit-status' do
  content_type :json

  ip_address = request.ip

  # Clean up old records
  db.execute(
    "DELETE FROM rate_limits WHERE attempt_time < datetime('now', '-#{RATE_LIMIT_WINDOW} seconds')"
  )

  # Count recent attempts
  result = db.execute(
    "SELECT COUNT(*) as count FROM rate_limits
     WHERE ip_address = ?
     AND attempt_time >= datetime('now', '-#{RATE_LIMIT_WINDOW} seconds')",
    [ip_address]
  )

  attempts_used = result.first['count']
  remaining = RATE_LIMIT_MAX_ATTEMPTS - attempts_used
  reset_time = rate_limit_reset_time(ip_address)

  json(
    max_attempts: RATE_LIMIT_MAX_ATTEMPTS,
    attempts_used: attempts_used,
    remaining: [remaining, 0].max,
    reset_in_seconds: reset_time,
    is_limited: remaining <= 0
  )
end

def send_notification_email(id, idea, ip, user_agent, profanity_flagged = false, flagged_words = nil)
  subject_line = profanity_flagged ? "⚠️ FLAGGED Submission ##{id}" : "New Idea Submission ##{id}"

  Mail.deliver do
    from    'noreply@dumbidea.app'
    to      ADMIN_EMAIL
    subject subject_line

    body    <<~EMAIL
      A new idea has been submitted to your Dumb Idea app.

      Submission ID: #{id}
      Submitted at: #{Time.now}
      IP Address: #{ip}
      User Agent: #{user_agent}
      #{profanity_flagged ? "⚠️ PROFANITY FLAGGED: #{flagged_words}" : ""}

      Idea:
      #{idea}

      ---
      #{profanity_flagged ? '⚠️ This submission contains potentially inappropriate language and requires review.' : 'Please review this submission to ensure it\'s appropriate.'}
    EMAIL
  end
end

# Admin Dashboard
get '/admin' do
  protected!

  # Get all submissions ordered by newest first
  submissions = db.execute(
    'SELECT * FROM user_submissions ORDER BY created_at DESC'
  )

  # Get counts by status
  stats = {
    pending: db.execute("SELECT COUNT(*) as count FROM user_submissions WHERE status = 'pending'").first['count'],
    approved: db.execute("SELECT COUNT(*) as count FROM user_submissions WHERE status = 'approved'").first['count'],
    rejected: db.execute("SELECT COUNT(*) as count FROM user_submissions WHERE status = 'rejected'").first['count']
  }

  erb :admin, locals: { submissions: submissions, stats: stats }
end

# API: Approve submission
post '/admin/api/approve/:id' do
  protected!
  content_type :json

  id = params['id'].to_i

  begin
    # Update status to approved
    db.execute('UPDATE user_submissions SET status = ?, rejection_reason = NULL WHERE id = ?', ['approved', id])

    # Get the approved idea
    submission = db.execute('SELECT idea FROM user_submissions WHERE id = ?', [id]).first

    if submission
      # Add to main ideas table
      db.execute('INSERT INTO ideas (idea) VALUES (?)', [submission['idea']])
      LOG.info("Submission ##{id} approved and added to main ideas")
    end

    json success: true, message: 'Submission approved and added to ideas'
  rescue => e
    LOG.error("Failed to approve submission ##{id}: #{e.message}")
    status 500
    json error: 'Failed to approve submission'
  end
end

# API: Reject submission
post '/admin/api/reject/:id' do
  protected!
  content_type :json

  id = params['id'].to_i
  payload = JSON.parse(request.body.read)
  reason = payload['reason'] || 'No reason provided'

  begin
    db.execute(
      'UPDATE user_submissions SET status = ?, rejection_reason = ? WHERE id = ?',
      ['rejected', reason, id]
    )

    LOG.info("Submission ##{id} rejected. Reason: #{reason}")

    json success: true, message: 'Submission rejected'
  rescue => e
    LOG.error("Failed to reject submission ##{id}: #{e.message}")
    status 500
    json error: 'Failed to reject submission'
  end
end

# API: Delete submission
delete '/admin/api/delete/:id' do
  protected!
  content_type :json

  id = params['id'].to_i

  begin
    db.execute('DELETE FROM user_submissions WHERE id = ?', [id])

    LOG.info("Submission ##{id} deleted")

    json success: true, message: 'Submission deleted'
  rescue => e
    LOG.error("Failed to delete submission ##{id}: #{e.message}")
    status 500
    json error: 'Failed to delete submission'
  end
end

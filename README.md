# Dumb Idea Generator

A fun web app that generates stupid ideas and allows users to submit their own.

## Features

### User Features
- **Random Idea Generator**: Mix of curated and template-generated stupid ideas
- **No Repeats**: Never see the same idea twice - tracks your viewing history in localStorage
- **Loading State**: Visual spinner while generating ideas
- **Keyboard Shortcut**: Press SPACE to generate new ideas
- **User Submissions**: Users can submit their own stupid ideas
- **Dark Mode**: Toggle between light and dark themes (saved to localStorage)
- **Social Sharing**: Share ideas to Twitter, Facebook, LinkedIn, Reddit, or copy to clipboard
- **Rate Limiting**: Prevents spam with 3 submissions per hour per IP
- **Live Stats**: View total ideas, submissions, and approvals in footer

### Admin Features
- **Email Notifications**: Get notified when new ideas are submitted
- **Profanity Filter**: Auto-flags submissions with inappropriate content
- **Admin Dashboard**: Review, approve, reject, or delete submissions
- **Submission Status Tracking**: Monitor pending, approved, and rejected ideas
- **Custom Error Pages**: Themed 404 and 500 error pages
- **Logging**: All submissions and admin actions are logged

## Quick Start

1. **Install Dependencies**
   ```bash
   bundle install
   ```

2. **Setup Database**
   ```bash
   ruby setup_db.rb
   ruby seed.rb
   ruby add_submissions_table.rb
   ruby add_submission_status.rb
   ruby add_rate_limiting.rb
   ruby add_profanity_flag.rb
   ```

3. **Configure Environment**
   ```bash
   cp .env.example .env
   # Edit .env and add your credentials
   ```

4. **Start the Server**
   ```bash
   ./start.sh
   ```
   Or manually:
   ```bash
   export $(cat .env | xargs)
   rackup -p 9292
   ```

5. **Access the App**
   - Main app: http://localhost:9292
   - Admin dashboard: http://localhost:9292/admin

## Configuration

Edit `.env` file to configure:

- **Email Notifications**: SMTP settings for email alerts
- **Admin Credentials**: Username and password for admin dashboard

See `EMAIL_SETUP.md` for detailed email configuration instructions.

## Admin Dashboard

Access at `/admin` to:
- View all user submissions
- Approve ideas (adds them to the main pool)
- Reject ideas with reasons
- Delete inappropriate submissions
- View statistics by status

Default credentials: `admin/changeme` (CHANGE THESE!)

See `ADMIN_GUIDE.md` for complete admin documentation.

## File Structure

```
.
├── app.rb                      # Main application
├── config.ru                   # Rack configuration
├── Gemfile                     # Ruby dependencies
├── ideas.db                    # SQLite database
├── submissions.log             # Submission and admin action logs
├── views/
│   ├── index.erb              # Main page
│   └── admin.erb              # Admin dashboard
├── setup_db.rb                # Database setup
├── seed.rb                    # Seed curated ideas
├── add_submissions_table.rb   # Create submissions table
├── add_submission_status.rb   # Add status columns
├── add_rate_limiting.rb       # Create rate limiting table
├── start.sh                   # Startup script
├── .env.example               # Environment variables template
├── README.md                  # This file
├── ADMIN_GUIDE.md            # Admin dashboard guide
├── EMAIL_SETUP.md            # Email configuration guide
└── FEATURES.md               # Dark mode & rate limiting docs
```

## Database Schema

**ideas** - Curated ideas for random generation
- `id`: Primary key
- `idea`: Idea text
- `created_at`: Timestamp

**user_submissions** - User-submitted ideas
- `id`: Primary key
- `idea`: Submitted idea text
- `ip_address`: Submitter's IP
- `user_agent`: Browser info
- `status`: 'pending', 'approved', or 'rejected'
- `rejection_reason`: Reason if rejected
- `profanity_flagged`: 1 if profanity detected, 0 otherwise
- `flagged_words`: List of profane words found
- `created_at`: Timestamp

**rate_limits** - Submission rate limiting
- `id`: Primary key
- `ip_address`: IP being tracked
- `attempt_time`: When the attempt was made
- `created_at`: Timestamp

## Security Notes

- Change default admin credentials
- Keep `.env` file secure (never commit it)
- Review submissions regularly
- IP addresses are logged for moderation

## Logging

- `submissions.log`: All submissions and admin actions
- Daily rotation enabled
- Includes timestamps, IPs, and action details

## Development

Built with:
- Ruby + Sinatra
- SQLite3
- Mail gem for notifications
- ERB templates
- Vanilla JavaScript

## License

Use for whatever stupid ideas you have!

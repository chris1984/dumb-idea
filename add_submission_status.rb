require 'sqlite3'

# Add status and rejection_reason columns to user_submissions table
db = SQLite3::Database.new('ideas.db')

begin
  db.execute <<-SQL
    ALTER TABLE user_submissions
    ADD COLUMN status TEXT DEFAULT 'pending';
  SQL
  puts "Added status column"
rescue SQLite3::SQLException => e
  puts "Status column may already exist: #{e.message}"
end

begin
  db.execute <<-SQL
    ALTER TABLE user_submissions
    ADD COLUMN rejection_reason TEXT;
  SQL
  puts "Added rejection_reason column"
rescue SQLite3::SQLException => e
  puts "Rejection_reason column may already exist: #{e.message}"
end

# Set default status for existing records
db.execute("UPDATE user_submissions SET status = 'pending' WHERE status IS NULL")

puts "Migration completed successfully!"

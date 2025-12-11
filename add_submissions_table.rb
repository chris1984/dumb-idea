require 'sqlite3'

# Add user_submissions table to track user-submitted ideas
db = SQLite3::Database.new('ideas.db')

db.execute <<-SQL
  CREATE TABLE IF NOT EXISTS user_submissions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    idea TEXT NOT NULL,
    ip_address TEXT,
    user_agent TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
  );
SQL

puts 'User submissions table created successfully!'

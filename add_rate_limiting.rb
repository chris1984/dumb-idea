require 'sqlite3'

# Add rate_limits table to track submission attempts by IP
db = SQLite3::Database.new('ideas.db')

db.execute <<-SQL
  CREATE TABLE IF NOT EXISTS rate_limits (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    ip_address TEXT NOT NULL,
    attempt_time DATETIME DEFAULT CURRENT_TIMESTAMP,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
  );
SQL

# Create index on ip_address for faster lookups
db.execute <<-SQL
  CREATE INDEX IF NOT EXISTS idx_rate_limits_ip
  ON rate_limits(ip_address);
SQL

# Create index on attempt_time for cleanup queries
db.execute <<-SQL
  CREATE INDEX IF NOT EXISTS idx_rate_limits_time
  ON rate_limits(attempt_time);
SQL

puts "Rate limiting table created successfully!"

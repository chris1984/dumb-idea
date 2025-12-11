require 'sqlite3'

# Create database and table
db = SQLite3::Database.new('ideas.db')

db.execute <<-SQL
  CREATE TABLE IF NOT EXISTS ideas (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    idea TEXT NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
  );
SQL

puts 'Database and table created successfully!'

require 'sqlite3'

# Add profanity_flagged column to user_submissions table
db = SQLite3::Database.new('ideas.db')

begin
  db.execute <<-SQL
    ALTER TABLE user_submissions
    ADD COLUMN profanity_flagged INTEGER DEFAULT 0;
  SQL
  puts "Added profanity_flagged column"
rescue SQLite3::SQLException => e
  puts "Profanity_flagged column may already exist: #{e.message}"
end

begin
  db.execute <<-SQL
    ALTER TABLE user_submissions
    ADD COLUMN flagged_words TEXT;
  SQL
  puts "Added flagged_words column"
rescue SQLite3::SQLException => e
  puts "Flagged_words column may already exist: #{e.message}"
end

puts "Migration completed successfully!"

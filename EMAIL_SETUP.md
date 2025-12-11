# Email Notification Setup

This app now sends email notifications when users submit ideas. Here's how to configure it:

## Quick Setup

1. Copy the example environment file:
   ```bash
   cp .env.example .env
   ```

2. Edit `.env` and fill in your email credentials

3. Set environment variables before starting the app:
   ```bash
   export $(cat .env | xargs)
   rackup -p 9292
   ```

## Email Provider Options

### Option 1: Gmail (Recommended for Testing)

1. Go to your Google Account settings
2. Enable 2-Factor Authentication if not already enabled
3. Generate an App Password at: https://myaccount.google.com/apppasswords
4. Use these settings in your `.env`:
   ```
   SMTP_ADDRESS=smtp.gmail.com
   SMTP_PORT=587
   SMTP_USERNAME=your-email@gmail.com
   SMTP_PASSWORD=your-app-password
   ADMIN_EMAIL=your-email@gmail.com
   ```

### Option 2: SendGrid

1. Sign up at https://sendgrid.com
2. Generate an API key
3. Use these settings:
   ```
   SMTP_ADDRESS=smtp.sendgrid.net
   SMTP_PORT=587
   SMTP_USERNAME=apikey
   SMTP_PASSWORD=your-sendgrid-api-key
   ADMIN_EMAIL=your-email@example.com
   ```

### Option 3: Mailgun

1. Sign up at https://mailgun.com
2. Get your SMTP credentials from the dashboard
3. Use these settings:
   ```
   SMTP_ADDRESS=smtp.mailgun.org
   SMTP_PORT=587
   SMTP_USERNAME=your-mailgun-smtp-username
   SMTP_PASSWORD=your-mailgun-smtp-password
   ADMIN_EMAIL=your-email@example.com
   ```

## What Gets Logged

Each submission is logged to `submissions.log` with:
- Submission ID
- Timestamp
- User's IP address
- The submitted idea

## What Gets Emailed

You'll receive an email for each submission containing:
- Submission ID
- Timestamp
- IP address
- User agent
- The full text of the submitted idea

## Troubleshooting

If emails aren't sending:
1. Check `submissions.log` for error messages
2. Verify your SMTP credentials are correct
3. Make sure environment variables are loaded
4. For Gmail, ensure you're using an App Password, not your regular password
5. Check your email provider's SMTP documentation

The app will still work even if email fails - submissions will be saved to the database and logged to the file.

## Security Notes

- Never commit your `.env` file to version control
- The `.env.example` file is safe to commit (it contains no real credentials)
- Submissions are logged with IP addresses for moderation purposes
- Character limit is 500 characters per submission
- Basic validation is performed on all submissions

# Admin Dashboard Guide

The admin dashboard allows you to manage user-submitted ideas with approval/rejection workflow.

## Accessing the Admin Dashboard

Navigate to: `http://localhost:9292/admin`

You'll be prompted for credentials:
- **Username**: Set via `ADMIN_USERNAME` in `.env` (default: `admin`)
- **Password**: Set via `ADMIN_PASSWORD` in `.env` (default: `changeme`)

**IMPORTANT**: Change the default credentials in your `.env` file!

## Dashboard Overview

The dashboard shows:

### Statistics
- **Pending**: Ideas awaiting review
- **Approved**: Ideas that were approved and added to the main pool
- **Rejected**: Ideas that were rejected with reasons
- **Total**: All submissions

### Filters
Click the filter buttons to view:
- **All**: All submissions
- **Pending**: Only pending submissions
- **Approved**: Only approved submissions
- **Rejected**: Only rejected submissions

## Managing Submissions

Each submission card displays:
- Submission ID and timestamp
- The submitted idea text
- IP address and user agent (for moderation)
- Current status
- Available actions

### Actions

**For Pending Submissions:**

1. **Approve & Add to Ideas**
   - Marks the submission as "approved"
   - Adds the idea to the main `ideas` table
   - The idea will now appear in the random idea generator
   - Logs the action

2. **Reject**
   - Opens a modal to enter a rejection reason
   - Marks the submission as "rejected"
   - Stores the reason for future reference
   - The idea will NOT be added to the main pool
   - Logs the action

**For All Submissions:**

3. **Delete**
   - Permanently removes the submission from the database
   - Cannot be undone
   - Logs the action

## Workflow

### Recommended Workflow:

1. **Review New Submissions**
   - Filter by "Pending" to see only new submissions
   - Read each idea carefully

2. **Moderate Content**
   - Check for inappropriate content
   - Check for spam or nonsensical submissions
   - Verify the idea fits the "stupid idea" theme

3. **Take Action**
   - **Good submissions**: Click "Approve & Add to Ideas"
   - **Inappropriate/spam**: Click "Reject" and provide a reason
   - **Clear violations**: Click "Delete"

4. **Track Patterns**
   - Review rejection reasons to identify common issues
   - Use IP addresses to identify repeat offenders
   - Monitor submission quality over time

## Security Features

- **HTTP Basic Authentication**: Password-protected access
- **Credentials via Environment Variables**: Keep credentials secure
- **IP Logging**: Track submission sources
- **Action Logging**: All actions logged to `submissions.log`

## Monitoring

All admin actions are logged to `submissions.log` with:
- Timestamp
- Action taken (approve/reject/delete)
- Submission ID
- For rejections: the reason provided

## Best Practices

1. **Change Default Credentials**
   - Never use the default `admin/changeme` in production
   - Use a strong password

2. **Regular Reviews**
   - Check pending submissions regularly
   - Don't let the queue grow too large

3. **Document Rejection Reasons**
   - Be specific when rejecting
   - Helps identify patterns
   - Examples: "Spam", "Inappropriate content", "Not a stupid idea"

4. **Backup Database**
   - Regularly backup `ideas.db`
   - Contains all submissions and main ideas

## Troubleshooting

**Can't log in:**
- Check `ADMIN_USERNAME` and `ADMIN_PASSWORD` in `.env`
- Ensure environment variables are loaded (use `./start.sh`)
- Verify you're using the correct credentials

**Actions not working:**
- Check browser console for errors
- Verify `submissions.log` for error messages
- Ensure database file has write permissions

**No submissions showing:**
- Users must submit ideas via the form on the homepage
- Check if `user_submissions` table exists in database

## Database Schema

The `user_submissions` table contains:
- `id`: Unique identifier
- `idea`: The submitted idea text
- `ip_address`: Submitter's IP address
- `user_agent`: Submitter's browser info
- `created_at`: Submission timestamp
- `status`: 'pending', 'approved', or 'rejected'
- `rejection_reason`: Reason for rejection (if applicable)

When an idea is approved, it's copied to the `ideas` table for use in the random generator.

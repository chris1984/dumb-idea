# Features Documentation

## Dark Mode

### Overview
Users can toggle between light and dark themes with a single click. The preference is saved and persists across sessions.

### Usage
- Click the theme toggle button in the top-right corner
- **Moon icon (🌙)**: Click to enable dark mode
- **Sun icon (☀️)**: Click to return to light mode
- Theme preference is saved in browser localStorage

### Implementation Details
- Uses CSS variables for easy theme switching
- Smooth transitions between themes (0.3s)
- All components respect the theme (buttons, forms, backgrounds)
- Preference persists across browser sessions

---

## Rate Limiting

### Overview
Prevents spam and abuse by limiting the number of idea submissions per IP address.

### Current Limits
- **Maximum submissions**: 3 per hour per IP address
- **Time window**: 1 hour (3600 seconds)
- **Automatic cleanup**: Old rate limit records are cleaned up automatically

### How It Works

**For Users:**
1. Users see remaining submissions below the submission form
2. Counter updates in real-time: "X submissions remaining this hour"
3. Warning when only 1 submission remains: "⚠️ 1 submission remaining this hour"
4. When limit is reached, submit button is disabled
5. Users see how long until they can submit again

**For Admins:**
- Rate limit violations are logged to `submissions.log`
- IP addresses are tracked for rate limiting
- Old records (> 1 hour) are automatically cleaned up

### Technical Details

**Database:**
- `rate_limits` table tracks submission attempts by IP
- Indexed on `ip_address` and `attempt_time` for fast lookups
- Automatic cleanup on each rate limit check

**API Endpoints:**
- `POST /api/submit-idea` - Checks rate limit before accepting submission
- `GET /api/rate-limit-status` - Returns current limit status for the IP

**Rate Limit Response (HTTP 429):**
```json
{
  "error": "You've submitted too many ideas. Please try again in X minutes.",
  "retry_after": 3600
}
```

**Status Response:**
```json
{
  "max_attempts": 3,
  "attempts_used": 1,
  "remaining": 2,
  "reset_in_seconds": 3421,
  "is_limited": false
}
```

### Configuration

Edit `app.rb` to change limits:

```ruby
RATE_LIMIT_MAX_ATTEMPTS = 3  # Max submissions allowed
RATE_LIMIT_WINDOW = 3600     # Time window in seconds (1 hour)
```

### Security Benefits
1. **Prevents spam**: Limits rapid-fire submissions
2. **Reduces moderation load**: Fewer junk submissions to review
3. **Fair usage**: Ensures everyone can participate
4. **DDoS mitigation**: Basic protection against abuse

### User Experience
- **Transparent**: Users always know their limit status
- **Helpful errors**: Clear messages about when they can try again
- **Non-intrusive**: Only visible when needed
- **Auto-updates**: Status refreshes after each submission

---

---

## Idea History (No Repeats)

### Overview
Tracks all ideas you've seen and ensures you never see the same idea twice in a session. Perfect for users who want fresh content every time.

### How It Works

**Automatic Tracking:**
- Every idea shown is saved to your browser's localStorage
- Both curated and template-generated ideas are tracked
- History persists across browser sessions
- Maximum 1000 ideas stored (to prevent storage issues)

**Smart Filtering:**
- When generating a new idea, the app checks your history
- Tries up to 50 times to find a template idea you haven't seen
- Tries up to 20 times to fetch a curated idea you haven't seen
- Falls back between curated and template if needed

**Visual Feedback:**
- "📊 X ideas seen" counter below the generate button
- Updates in real-time as you view more ideas
- "Reset History" button to start fresh

### User Interface

**History Counter:**
- Shows total number of unique ideas seen
- Located below the "Generate Stupid Idea" button
- Updates automatically with each new idea

**Reset History Button:**
- Clears all viewing history
- Requires confirmation to prevent accidental resets
- Allows you to re-see all ideas

**All Seen Message:**
- Appears when you've exhausted all available ideas
- Yellow warning box with clear instructions
- Prompts you to reset history to continue

### Technical Details

**Storage:**
```javascript
// Stored in localStorage as JSON array
{
  "ideaHistory": [
    "A bluetooth-enabled spatula that screams when you sneeze",
    "A dating app but exclusively for people who hate dating",
    // ... more ideas
  ]
}
```

**Performance:**
- Efficient string comparison for duplicate detection
- Circular buffer (keeps last 1000 ideas only)
- No server-side storage required
- Works offline

**Edge Cases Handled:**
1. All curated ideas seen → Falls back to templates
2. All template combinations seen → Shows helpful message
3. localStorage full → Trims to last 1000 ideas
4. Multiple browser tabs → Each tab has its own history

### Privacy

- History stored **locally** in your browser only
- Never sent to the server
- Cleared when you clear browser data
- No tracking or analytics

### Use Cases

**Perfect for:**
- Binge-watching ideas without repetition
- Finding new inspiration each visit
- Discovering all available ideas systematically
- Curating favorite ideas without duplicates

**Example Session:**
1. Generate 50 ideas → See 50 unique ideas
2. Come back tomorrow → Continue from where you left off
3. Eventually exhaust all ideas → Get notified
4. Reset and start fresh → See them all again

---

## Combined Benefits

**Dark Mode + Rate Limiting + Idea History:**
- Dark mode enhances usability for all time zones
- Rate limiting ensures the service remains available
- Idea history improves user experience with fresh content
- All three features work seamlessly together
- Professional, modern, thoughtful user experience

## Future Enhancements

Potential improvements:
- Export idea history as a text file
- Mark favorite ideas for later
- Filter history by curated vs template-generated
- Statistics: "You've seen X% of all ideas"
- Configurable rate limits via admin panel
- Different limits for authenticated users
- Per-user rate limits (if authentication is added)
- Rate limit statistics in admin dashboard

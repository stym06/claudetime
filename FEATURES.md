# ClaudeTime - Feature Ideas & Improvements

A brainstormed list of features and improvements for ClaudeTime, the macOS menu bar app that monitors Claude Code usage via OpenTelemetry.

---

## 1. Persistent Metrics / History

Metrics are currently in-memory only and lost on app restart. Adding persistence (e.g., SQLite or JSON file storage) would enable:

- Daily/weekly/monthly usage summaries
- Historical cost tracking and budgeting
- Session-over-session comparison

## 2. Cost Budgets & Alerts

Allow users to set a daily or monthly cost budget. When approaching or exceeding the threshold, show a macOS notification or a color change in the menu bar icon. Helps prevent unexpected spend.

## 3. Per-Project / Per-Workspace Tracking

Claude Code can be used across multiple repos. Tagging metrics by project directory (available in OTLP attributes) would allow per-project cost and token breakdowns in the dashboard.

## 4. CSV / JSON Export

A menu option to export current or historical metrics to CSV or JSON for use in spreadsheets, invoices, or external dashboards.

## 5. Configurable Server Port

The OTLP listener is hardcoded to `127.0.0.1:4318`. Making the port configurable (via preferences or a config file) would avoid conflicts with other OTLP-aware tools.

## 6. Keyboard Shortcut to Toggle Dashboard

Add a global hotkey (e.g., `Option+Cmd+C`) to quickly open/close the metrics dashboard without clicking the menu bar icon.

## 7. Dark/Light Mode Refinement

The dashboard uses a fixed gradient. Adapting colors more precisely to the system appearance (dark vs. light mode) would improve visual consistency.

## 8. Notification on Idle / Stale Data

If no metrics have been received for a configurable period (e.g., 5 minutes), show a subtle indicator or notification that Claude Code may have stopped, helping users notice disconnects early.

## 9. Multi-Window / Detachable Dashboard

Allow the dashboard to be popped out into a standalone resizable window (rather than constrained to the 320pt menu dropdown), useful for users who want it visible alongside their editor.

## 10. Rate Metrics (Tokens/Minute, Cost/Hour)

In addition to cumulative totals, show rate-based metrics like tokens per minute or cost per hour, giving a real-time sense of burn rate.

## 11. Session Timeline View

A timeline visualization showing when sessions started/ended and activity intensity over time, useful for reviewing a day's work patterns.

## 12. Launch at Login

Add a preference toggle to automatically start ClaudeTime at macOS login using `SMAppService` or a Launch Agent, so users don't have to manually start it each time.

## 13. Menu Bar Icon Customization

Let users choose between different menu bar display modes: icon only, token counts only, cost only, or combinations — to reduce menu bar clutter.

## 14. Sparkline Time Window Control

The sparkline buffer is fixed at 30 samples. Allowing users to switch between time windows (last 5 min, 30 min, 1 hour) would make the sparklines more informative.

## 15. Model Usage Breakdown Chart

A small pie or bar chart showing which models consumed what percentage of tokens and cost, useful when multiple models are in play.

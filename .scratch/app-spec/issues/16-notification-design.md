# Decide: release-notification design

Type: grilling
Status: open
Blocked by: 11

## Question

Given the [release-notifications research](../../docs/research/release-notifications.md), what is grand-line's new-release experience? Decide: whether to adopt the recommended shape (12 h server cron diffing the RSS into a `releases` table; clients check on launch; in-app "New" badge/list as the universal surface) and the cadence for both hops; where the badge/list lives in the immersive-carousel UI; which platforms get OS notifications and their opt-in story (Android background poll, best-effort iOS BGAppRefresh, while-running toasts on desktop — or fewer); and how notification preferences are stored (local, per the sync decision that settings don't sync).

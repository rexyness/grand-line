# Research: detecting and notifying new One Pace releases

Type: research
Status: open
Blocked by: 07, 09

## Question

Given the chosen content source and backend, how can the app detect new One Pace episodes and notify the user on each platform? Cover: what "new release" signal the chosen source exposes (feed, API delta, scrape diff); client-side polling vs a backend-assisted check (does the chosen sync backend offer cheap scheduled functions/push?); OS notification APIs from Flutter on Android, iOS (APNs constraints for a sideloaded app!), Windows, and Linux; and what cadence is respectful to One Pace's infrastructure.

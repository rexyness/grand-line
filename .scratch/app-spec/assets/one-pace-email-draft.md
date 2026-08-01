# Draft: courtesy email to the One Pace team

Asset of [Task: email the One Pace team](../issues/15-contact-one-pace-team.md).
To: onepaceproject@gmail.com — send from your own address. Subject suggestion below.

---

**Subject:** Heads-up: grand-line, an open-source fan app for watching One Pace

Hi One Pace team,

First — thank you for One Pace. I'm about to publish a free, open-source fan
project built on your work, and I wanted to give you a heads-up before it goes
public, and check a couple of things with you.

**What it is.** grand-line is a free, ad-free, open-source app (GPL-3.0, on
GitHub) for Windows, Linux, Android, and iOS that streams and downloads One
Pace episodes from the links you already publish. It hosts no video itself —
it plays the streams and torrents your project distributes. The app and README
make clear it's unofficial and unaffiliated, credit the One Pace team
prominently, and link onepace.net and your donation page both on the home
screen and in the About screen. It will never carry ads or charge for anything.

**How it touches your servers.** Individual installs never scrape your site.
A single small server-side job fetches your public releases RSS feed twice a
day on behalf of all users, so the whole user base costs you the same traffic
as one visitor. If you'd like that job to identify itself with an honest
User-Agent (e.g. `grand-line-bot`, with a contact URL), I'd be glad to set
that — currently your CDN requires a browser-like UA, which is why I'm asking.

**One permission question.** The app's browse screens are designed around your
official arc artwork. By default the app fetches those images at runtime from
your site (cached on-device so each user downloads them once) and ships none
of them in the repository. If you're comfortable with the artwork being
bundled in the app/repo instead, that would make the app fully offline from
first launch — but only with your explicit OK; otherwise runtime fetch it stays.

**Your call, always.** If any part of this — the app existing, the RSS
polling, the artwork, the name — doesn't sit right with you, tell me and I'll
change it or take it down. This exists to make watching One Pace nicer, not to
cause you problems.

Repo (goes public shortly): <link when public>

Thanks for everything you do,
<your name>

---

## Notes for the sender (not part of the email)

- Fill in the repo link and your name/sign-off before sending.
- The FAQ also points at their Discord — if no email reply after ~2 weeks, a
  polite Discord ping referencing the email is the follow-up path.
- On reply, record the outcome in the ticket: UA blessing (y/n), backdrop
  bundling (y/n), any objections — these update the release posture and the
  backdrop decision in [ticket 13](../issues/13-release-strategy.md).

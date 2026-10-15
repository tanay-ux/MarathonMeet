# Screen Exports

PNG renders of every MarathonMeet screen, exported at 2x from the browser prototype.

| File | Screen |
|------|--------|
| `01-home.png` | Role picker — "I'm Running" / "I'm Spectating" |
| `02-create-session.png` | Runner enters their name |
| `03-session-code.png` | Generated session code, ready to share |
| `04-runner-dashboard.png` | Runner tracking view with code, GPS, alert distance |
| `05-runner-proximity-alert.png` | Runner dashboard while a spectator is nearby |
| `06-join-session.png` | Spectator enters name + session code |
| `07-spectator-map.png` | Live map with collapsed detail sheet |
| `08-spectator-details.png` | Expanded sheet — distance, ETA, alert distance |
| `09-spectator-proximity-alert.png` | Spectator map while the runner is nearby |
| `10-settings.png` | Session and permission settings |
| `11-watch-tracking.png` | Apple Watch tracking face |
| `12-watch-alert.png` | Apple Watch proximity alert |

## Regenerating

These are build artifacts. Do not edit them by hand — change the prototype and re-export:

```bash
cd prototype
npm install
npm run export
```

Source: [`../../prototype`](../../prototype)

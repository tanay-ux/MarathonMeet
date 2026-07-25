# MarathonMeet

Track a marathon runner and get proximity alerts when you're close enough to cheer each other on. Built for **SF Marathon 2026** (July 26).

## Features

- **Runner mode** — shares GPS in the background for the full race
- **Spectator mode** — live map with runner location, distance, and ETA
- **Per-user proximity alerts** — each person sets their own alert distance
- **Push notifications** — time-sensitive alerts that mirror to Apple Watch
- **watchOS companion** — haptic alerts on the runner's wrist
- **GPX course overlay** — bundled SF Marathon route + import your own

## Requirements

- **Mac with Xcode 16+** (iOS apps must be built on macOS)
- **Apple Developer account** ($99/yr) for TestFlight and push notifications
- **Firebase project** (free tier is sufficient)
- **Node.js 20+** for Cloud Functions deployment

## Quick Start (on Mac)

### 1. Clone and generate Xcode project

```bash
cd ~/Projects/MarathonMeet
brew install xcodegen   # if not installed
xcodegen generate
open MarathonMeet.xcodeproj
```

### 2. Set up Firebase

1. Go to [Firebase Console](https://console.firebase.google.com/) → Create project **MarathonMeet**
2. Add an **iOS app** with bundle ID `com.marathonmeet.app`
3. Download `GoogleService-Info.plist` → save to `MarathonMeet/Resources/GoogleService-Info.plist`
4. Create **Firestore** database (production mode is fine with our rules)
5. Enable **Cloud Messaging**
6. **No Authentication required** — users enter a name only; each device gets a random local ID

> **Note:** Firestore rules are open for session-based access (no login). This is intentional for a private friend group gated by session codes. Don't publish the app publicly without tightening rules.

### 3. Configure APNs for push notifications

1. [Apple Developer](https://developer.apple.com/account/resources/authkeys/list) → Keys → create APNs key (.p8)
2. Firebase Console → Project Settings → Cloud Messaging → Upload APNs key
3. In Xcode → MarathonMeet target → Signing & Capabilities:
   - Set your **Team**
   - Enable **Push Notifications**
   - Enable **Background Modes** → Location updates + Remote notifications
   - Enable **Time Sensitive Notifications**

### 4. Deploy Cloud Functions

```bash
cd firebase
npm install -g firebase-tools
firebase login
cp .firebaserc.example .firebaserc
# Edit .firebaserc with your Firebase project ID

cd functions
npm install
npm run build
cd ..
firebase deploy --only functions,firestore:rules
```

### 5. Build and run

1. Open `MarathonMeet.xcodeproj` in Xcode
2. Set your Development Team under Signing
3. Connect an iPhone (simulator won't test background GPS or push)
4. Build & Run (⌘R)

### 6. TestFlight (race day distribution)

1. Archive the app (Product → Archive)
2. Distribute → App Store Connect → TestFlight
3. Add your friend as an internal tester
4. She installs on iPhone — Watch app installs automatically

## Race Day Checklist (July 26)

### Runner (your friend)
- [ ] Install app via TestFlight on iPhone + Apple Watch
- [ ] Open Watch app once to confirm it's active
- [ ] Charge phone and watch fully
- [ ] Before corral (~5:00 AM): open app → **I'm Running** → enter name → **Start Session**
- [ ] Share session code with spectators
- [ ] Grant **Always** location permission
- [ ] Set alert distance (default 500 m)
- [ ] Lock phone — alerts come to Watch

### Spectators (you)
- [ ] Install app via TestFlight
- [ ] **I'm Spectating** → enter session code + your name
- [ ] Grant location permission
- [ ] Set your alert distance (e.g. 200 m)
- [ ] Open map view — watch distance and ETA to runner

## How It Works

```
Runner iPhone  ──GPS every 15s──►  Firestore
Spectator iPhone ──GPS every 30s──►  Firestore
                                      │
                              Cloud Function
                              (proximity check)
                                      │
                              FCM Push (time-sensitive)
                                      │
                         ┌────────────┴────────────┐
                    Runner iPhone            Apple Watch
                    (notification)           (haptic alert)
```

Each person has their own `thresholdMeters`. When someone enters your threshold, **you** get notified — not the other way around.

## Import a Better Course GPX

The bundled `SF_Marathon_2026.gpx` is approximate. For race day accuracy:

1. Download the official GPX from [HelloDrifter](https://www.hellodrifter.com/events/san-francisco-marathon-2026?race_id=9260)
2. On spectator map, tap the map icon → import the GPX file

## Project Structure

```
MarathonMeet/
├── MarathonMeet/           # iOS app (SwiftUI)
├── MarathonMeetWatch/      # watchOS companion
├── firebase/functions/     # Proximity Cloud Function
├── project.yml             # XcodeGen config
└── README.md
```

## Troubleshooting

| Problem | Fix |
|---------|-----|
| No push notifications | Check APNs key in Firebase, run on real device, grant notification permission |
| Watch not alerting | Settings → Notifications → MarathonMeet → allow; open Watch app once |
| Runner location stops | Ensure "Always" location is granted; disable Low Power Mode |
| Session not found | Codes are case-insensitive; runner must start session first |
| Build fails on Windows | iOS builds require a Mac — this repo has all source; open on Mac |

## License

Private use for SF Marathon 2026.

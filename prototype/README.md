# MarathonMeet — Browser Prototype

A clickable, dependency-free prototype of the MarathonMeet iOS and watchOS interface.
It runs in any browser and doubles as the source for the PNG screen exports in
[`../design/screens`](../design/screens).

Use it to review flows and visuals without a Mac, Xcode, or a signed build.

## Run it

Open `index.html` directly, or serve it locally:

```bash
cd prototype
npm start          # http://localhost:4173
```

## What works

- Full navigation: home → create session → runner dashboard, and home → join → spectator map
- A simulated runner moving along the bundled SF Marathon course
- Live distance and ETA using the same haversine math as `LocationService`
- Proximity alerts that fire when the runner crosses your alert distance, including the Watch face
- Draggable bottom sheet (tap to expand/collapse) and working alert-distance sliders

The right-hand panel controls the simulation: pause movement, scrub the runner along the
course, change pace, or jump straight to the moment the runner approaches your spot.

## What is faked

No Firebase, GPS, push notifications, or WatchConnectivity. Positions are simulated and
nothing leaves the browser. The prototype mirrors the design system in
`MarathonMeet/Design/NeoBrutalism.swift`; it is not the app's source of truth.

## Export PNGs

```bash
npm install
npm run export
```

Renders every screen in headless Chromium at 2x and writes them to `../design/screens`.
Add or rename screens by editing the `PHONE_SCREENS` / `WATCH_SCREENS` lists in
`export-pngs.mjs`.

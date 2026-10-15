/* MarathonMeet browser prototype
 *
 * Mirrors the SwiftUI screens in MarathonMeet/Views using the same neo-brutalist
 * design tokens. No Firebase, GPS, or push — the runner is simulated along the
 * bundled SF Marathon course and distances use the app's haversine math.
 */

// Course from MarathonMeet/Resources/SF_Marathon_2026.gpx
const COURSE = [
  [37.7935, -122.393], [37.7958, -122.392], [37.7985, -122.39], [37.801, -122.387],
  [37.8035, -122.384], [37.806, -122.38], [37.8085, -122.375], [37.81, -122.37],
  [37.808, -122.365], [37.805, -122.36], [37.802, -122.355], [37.8, -122.35],
  [37.802, -122.345], [37.805, -122.34], [37.808, -122.335], [37.81, -122.33],
  [37.8085, -122.325], [37.806, -122.32], [37.803, -122.315], [37.8, -122.31],
  [37.797, -122.305], [37.794, -122.3], [37.77, -122.3], [37.768, -122.31],
  [37.766, -122.32], [37.764, -122.33], [37.762, -122.34], [37.76, -122.35],
  [37.758, -122.36], [37.756, -122.37], [37.754, -122.38], [37.752, -122.39],
  [37.75, -122.4], [37.752, -122.41], [37.755, -122.42], [37.758, -122.43],
  [37.762, -122.44], [37.766, -122.45], [37.77, -122.46], [37.774, -122.47],
  [37.778, -122.475], [37.782, -122.47], [37.786, -122.46], [37.79, -122.45],
  [37.792, -122.44], [37.793, -122.43], [37.792, -122.42], [37.791, -122.41],
  [37.79, -122.4], [37.791, -122.395], [37.7935, -122.393],
];

const SPECTATOR = [37.7588, -122.3596];
const OTHER_SPECTATOR = [37.7529, -122.4128];

const DEFAULTS = {
  runnerName: 'Sarah',
  spectatorName: 'Tanay',
  sessionCode: 'SF26AB',
  runnerThreshold: 500,
  spectatorThreshold: 200,
  progress: 0.34,
  paceMinPerKm: 6,
};

// ---------------------------------------------------------------- geo helpers

function haversineMeters(a, b) {
  const R = 6371000;
  const toRad = (d) => (d * Math.PI) / 180;
  const dLat = toRad(b[0] - a[0]);
  const dLon = toRad(b[1] - a[1]);
  const lat1 = toRad(a[0]);
  const lat2 = toRad(b[0]);
  const h = Math.sin(dLat / 2) ** 2 + Math.cos(lat1) * Math.cos(lat2) * Math.sin(dLon / 2) ** 2;
  return 2 * R * Math.asin(Math.sqrt(h));
}

const SEGMENTS = (() => {
  let total = 0;
  const cumulative = [0];
  for (let i = 1; i < COURSE.length; i += 1) {
    total += haversineMeters(COURSE[i - 1], COURSE[i]);
    cumulative.push(total);
  }
  return { cumulative, total };
})();

function pointAtProgress(progress) {
  const target = Math.max(0, Math.min(1, progress)) * SEGMENTS.total;
  for (let i = 1; i < COURSE.length; i += 1) {
    if (SEGMENTS.cumulative[i] >= target) {
      const segStart = SEGMENTS.cumulative[i - 1];
      const segLength = SEGMENTS.cumulative[i] - segStart || 1;
      const t = (target - segStart) / segLength;
      return [
        COURSE[i - 1][0] + (COURSE[i][0] - COURSE[i - 1][0]) * t,
        COURSE[i - 1][1] + (COURSE[i][1] - COURSE[i - 1][1]) * t,
      ];
    }
  }
  return COURSE[COURSE.length - 1];
}

/** Distance along the course to the point closest to the spectator. */
const MEETING_POINT_DISTANCE = (() => {
  let best = { distance: Infinity, along: 0 };
  COURSE.forEach((coord, index) => {
    const d = haversineMeters(coord, SPECTATOR);
    if (d < best.distance) best = { distance: d, along: SEGMENTS.cumulative[index] };
  });
  return best.along;
})();

function formatDistance(meters) {
  if (meters >= 1000) return `${(meters / 1000).toFixed(1)} km`;
  return `${Math.round(meters)} m`;
}

function formatEta(seconds) {
  if (seconds == null) return null;
  const minutes = Math.round(seconds / 60);
  if (minutes < 1) return '~< 1 min';
  if (minutes < 60) return `~${minutes} min`;
  return `~${Math.floor(minutes / 60)}h ${minutes % 60}m`;
}

// ------------------------------------------------------------------- app state

const state = {
  screen: 'home',
  runnerName: '',
  spectatorName: '',
  joinCode: '',
  sessionCode: null,
  runnerThreshold: DEFAULTS.runnerThreshold,
  spectatorThreshold: DEFAULTS.spectatorThreshold,
  progress: DEFAULTS.progress,
  paceMinPerKm: DEFAULTS.paceMinPerKm,
  sheetExpanded: false,
  simulating: true,
  alert: null,
  watchScreen: 'tracking',
  exportMode: null,
};

function runnerSpeedMps() {
  return 1000 / (state.paceMinPerKm * 60);
}

function snapshot() {
  const runner = pointAtProgress(state.progress);
  const straightLine = haversineMeters(runner, SPECTATOR);
  const along = state.progress * SEGMENTS.total;
  const remaining = MEETING_POINT_DISTANCE - along;
  const etaSeconds = remaining > 0 ? remaining / runnerSpeedMps() : null;
  return {
    runner,
    distanceMeters: straightLine,
    distanceText: formatDistance(straightLine),
    etaText: formatEta(etaSeconds),
    passed: remaining <= 0,
  };
}

// --------------------------------------------------------------------- icons

const ICONS = {
  runner: `<svg width="36" height="36" viewBox="0 0 36 36" aria-hidden="true">
    <rect x="4" y="26" width="28" height="6" rx="3" fill="var(--lime-bright)" stroke="#000" stroke-width="2"/>
    <rect x="6" y="14" width="3" height="10" rx="1.5" fill="#000" opacity="0.35"/>
    <rect x="10" y="11" width="3" height="14" rx="1.5" fill="#000" opacity="0.5"/>
    <rect x="14" y="8" width="3" height="18" rx="1.5" fill="#000" opacity="0.7"/>
    <circle cx="22" cy="10" r="4.5" fill="#000"/>
    <rect x="19" y="14" width="8" height="11" rx="3" fill="#000" transform="rotate(-10 23 19)"/>
    <rect x="18" y="22" width="3.5" height="11" rx="1.75" fill="#000" transform="rotate(35 19.75 27.5)"/>
    <rect x="23" y="22" width="3.5" height="13" rx="1.75" fill="#000" transform="rotate(-38 24.75 28.5)"/>
  </svg>`,
  spectator: `<svg width="36" height="36" viewBox="0 0 36 36" aria-hidden="true">
    <rect x="5" y="20" width="12" height="14" rx="3" fill="var(--sun-bright)" stroke="#000" stroke-width="2" transform="rotate(-6 11 27)"/>
    <rect x="8" y="10" width="12" height="12" rx="4" fill="var(--electric-bright)" stroke="#000" stroke-width="2.5"/>
    <rect x="22" y="10" width="12" height="12" rx="4" fill="var(--electric-bright)" stroke="#000" stroke-width="2.5"/>
    <rect x="19" y="14" width="4" height="4" rx="1" fill="#000"/>
    <circle cx="11" cy="13" r="2" fill="#fff" opacity="0.7"/>
    <circle cx="25" cy="13" r="2" fill="#fff" opacity="0.7"/>
    <circle cx="29" cy="6" r="6" fill="#000"/>
    <path d="M 27 6 C 27 4.8 28.5 4 29 5.2 C 29.5 4 31 4.8 31 6 C 31 7.6 29 9 29 9 C 29 9 27 7.6 27 6 Z" fill="var(--pink-soft)"/>
  </svg>`,
  pinDrop: `<svg width="26" height="26" viewBox="0 0 24 24" aria-hidden="true">
    <path d="M12 2c-3.9 0-7 3.1-7 7 0 5.2 7 13 7 13s7-7.8 7-13c0-3.9-3.1-7-7-7z" fill="#000"/>
    <circle cx="12" cy="9" r="2.6" fill="var(--lime-bright)"/>
  </svg>`,
  bell: `<svg width="26" height="26" viewBox="0 0 24 24" aria-hidden="true">
    <path d="M12 3a5 5 0 0 0-5 5v4l-2 3h14l-2-3V8a5 5 0 0 0-5-5z" fill="#000"/>
    <circle cx="12" cy="19" r="2" fill="#000"/>
  </svg>`,
  map: `<svg width="20" height="20" viewBox="0 0 24 24" aria-hidden="true">
    <path d="M9 4 3 6v14l6-2 6 2 6-2V4l-6 2-6-2z" fill="none" stroke="#000" stroke-width="2.4" stroke-linejoin="round"/>
    <path d="M9 4v14M15 6v14" stroke="#000" stroke-width="2.4"/>
  </svg>`,
  pinRunner: `<svg width="19" height="19" viewBox="0 0 24 24" aria-hidden="true">
    <circle cx="14" cy="4.4" r="2.6" fill="#000"/>
    <path d="M12.4 8.2 8.6 10.4l-1.4 4.2 2.3.8 1-3 2.2-1.1-1 4.2 3.4 4.6 1.9-1.4-2.6-3.7 1.4-5.2 2.7 2.1 2.5-.6-.5-2.2-3.6-1.1-4.5-.8z" fill="#000"/>
  </svg>`,
  pinMe: `<svg width="18" height="18" viewBox="0 0 24 24" aria-hidden="true">
    <circle cx="12" cy="12" r="5" fill="#000"/>
    <circle cx="12" cy="12" r="10" fill="none" stroke="#000" stroke-width="2.2"/>
  </svg>`,
  pinOther: `<svg width="18" height="18" viewBox="0 0 24 24" aria-hidden="true">
    <circle cx="12" cy="7.5" r="4" fill="#000"/>
    <path d="M4.5 21c0-4.1 3.4-7 7.5-7s7.5 2.9 7.5 7z" fill="#000"/>
  </svg>`,
  chevronUp: `<svg width="14" height="14" viewBox="0 0 24 24" aria-hidden="true">
    <path d="M5 15l7-7 7 7" fill="none" stroke="#000" stroke-width="3.4" stroke-linecap="round" stroke-linejoin="round"/>
  </svg>`,
  chevronDown: `<svg width="14" height="14" viewBox="0 0 24 24" aria-hidden="true">
    <path d="M5 9l7 7 7-7" fill="none" stroke="#000" stroke-width="3.4" stroke-linecap="round" stroke-linejoin="round"/>
  </svg>`,
  signal: `<svg width="56" height="14" viewBox="0 0 56 14" aria-hidden="true">
    <rect x="0" y="8" width="3" height="6" rx="1" fill="#000"/>
    <rect x="5" y="5.5" width="3" height="8.5" rx="1" fill="#000"/>
    <rect x="10" y="3" width="3" height="11" rx="1" fill="#000"/>
    <rect x="15" y="0.5" width="3" height="13.5" rx="1" fill="#000"/>
    <path d="M23 5.4a8 8 0 0 1 10 0" fill="none" stroke="#000" stroke-width="2"/>
    <path d="M25.6 8.6a4.4 4.4 0 0 1 4.8 0" fill="none" stroke="#000" stroke-width="2"/>
    <circle cx="28" cy="12" r="1.5" fill="#000"/>
    <rect x="39" y="2" width="14" height="10" rx="3" fill="none" stroke="#000" stroke-width="2"/>
    <rect x="41" y="4" width="9" height="6" rx="1.5" fill="#000"/>
    <rect x="54" y="5.5" width="2" height="3" rx="1" fill="#000"/>
  </svg>`,
};

// -------------------------------------------------------------------- helpers

const esc = (value) => String(value).replace(/[&<>"']/g, (c) => (
  { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]
));

function statusBar() {
  return `<div class="neo-status"><span>5:14</span><span class="status-icons">${ICONS.signal}</span></div>`;
}

function navBar(title, { back = null, right = null, left = null } = {}) {
  const leftSlot = back
    ? `<button data-action="back">‹ Back</button>`
    : (left || '');
  return `
    <div class="neo-nav">
      <div class="nav-side">${leftSlot}</div>
      <div class="nav-title">${esc(title)}</div>
      <div class="nav-side right">${right || ''}</div>
    </div>`;
}

function slider({ value, min = 100, max = 1000, step = 50, accent = 'coral', label = null, hint = null }) {
  const fraction = (value - min) / (max - min);
  const accentClass = accent === 'electric' ? 'electric' : '';
  return `
    <div class="slider">
      ${label ? `<p class="section-label ${accentClass}">${esc(label)}</p>` : ''}
      ${hint ? `<p class="slider-hint">${esc(hint)}</p>` : ''}
      <p class="slider-value">${value} m</p>
      <div class="slider-track">
        <div class="slider-rail"></div>
        <div class="slider-fill ${accentClass}" style="width: calc(${fraction} * (100% - 32px) + 16px);"></div>
        <div class="slider-thumb ${accentClass}" style="left: calc(${fraction} * (100% - 32px));"><i></i></div>
        <input type="range" min="${min}" max="${max}" step="${step}" value="${value}" data-action="threshold" />
      </div>
      <div class="slider-scale"><span>100 m</span><span>1 km</span></div>
    </div>`;
}

function alertBanner(alert) {
  return `
    <div class="neo-card pink-soft alert-banner">
      <div class="role-badge pink">${ICONS.bell}</div>
      <div>
        <strong>${esc(alert.name)} is nearby!</strong>
        <span>About ${Math.round(alert.distanceMeters)} m away — look up!</span>
      </div>
    </div>`;
}

// -------------------------------------------------------------------- screens

function homeScreen() {
  return `
    ${statusBar()}
    <div class="neo-body">
      <div class="hero">
        <div class="hero-mark">${ICONS.runner}</div>
        <h1 class="neo-title">MarathonMeet</h1>
        <p class="neo-sub">Know when you're close enough to cheer each other on.</p>
      </div>

      <div class="role-stack">
        <p class="section-label coral">Choose your role</p>
        <button class="role-card" data-action="goto" data-screen="create">
          <span class="role-badge coral">${ICONS.runner}</span>
          <span class="role-copy">
            <strong>I'm Running</strong>
            <span>Share your live location during the race</span>
          </span>
          <span class="role-arrow">→</span>
        </button>

        <button class="role-card" data-action="goto" data-screen="join">
          <span class="role-badge electric">${ICONS.spectator}</span>
          <span class="role-copy">
            <strong>I'm Spectating</strong>
            <span>Track the runner and get proximity alerts</span>
          </span>
          <span class="role-arrow">→</span>
        </button>
      </div>
    </div>`;
}

function createScreen() {
  const name = state.runnerName;
  const hasCode = Boolean(state.sessionCode);
  return `
    ${statusBar()}
    ${navBar('Start Running', { back: true })}
    <div class="neo-body">
      <div>
        <p class="neo-heading">Set up your race session</p>
        <p class="neo-sub" style="margin-top: 6px;">Spectators will use the code you generate to find you.</p>
      </div>

      <div class="neo-field">
        <label class="field-label" for="runner-name">Your name</label>
        <input id="runner-name" class="neo-input" placeholder="e.g. Sarah" value="${esc(name)}" data-action="runner-name" ${hasCode ? 'disabled' : ''} />
        <p class="neo-caption">Shown to spectators when you're nearby.</p>
      </div>

      <div class="block">
        <p class="section-label mint">Course</p>
        <div class="fact-row mint">
          <span class="fact-key">Event</span>
          <span class="fact-value">SF Marathon 2026</span>
        </div>
      </div>

      ${hasCode ? `
        <div class="block">
          <p class="section-label">Session code</p>
          <div class="neo-card neo-card-pad" style="display: flex; flex-direction: column; gap: 14px; align-items: stretch;">
            <p class="code-display">${esc(state.sessionCode)}</p>
            <p class="neo-caption" style="text-align: center;">Share this with spectators — it's how they join.</p>
            <button class="neo-btn secondary sun" type="button">Share code</button>
          </div>
        </div>
        <div class="form-actions">
          <button class="neo-btn lime primary" data-action="goto" data-screen="runner">Continue to dashboard</button>
        </div>
      ` : `
        <div class="form-actions">
          <button class="neo-btn primary" data-action="create-session" ${name.trim() ? '' : 'disabled'}>Start session</button>
        </div>
      `}
    </div>`;
}

function joinScreen() {
  const canJoin = state.spectatorName.trim() && state.joinCode.trim().length >= 4;
  return `
    ${statusBar()}
    ${navBar('Join as Spectator', { back: true })}
    <div class="neo-body">
      <div>
        <p class="neo-heading">Join a runner</p>
        <p class="neo-sub" style="margin-top: 6px;">Enter the 6-character code they shared with you.</p>
      </div>

      <div class="neo-field">
        <label class="field-label" for="spectator-name">Your name</label>
        <input id="spectator-name" class="neo-input" placeholder="e.g. Tanay" value="${esc(state.spectatorName)}" data-action="spectator-name" />
      </div>

      <div class="neo-field">
        <label class="field-label" for="join-code">Session code</label>
        <input id="join-code" class="neo-input" placeholder="SF26AB" value="${esc(state.joinCode)}" data-action="join-code" style="text-transform: uppercase; font-family: var(--font-mono); letter-spacing: 0.08em;" />
        <p class="neo-caption">Ask the runner for their code if you don't have it.</p>
      </div>

      <div class="form-actions">
        <button class="neo-btn electric primary" data-action="join-session" ${canJoin ? '' : 'disabled'}>Join session</button>
      </div>
    </div>`;
}

function runnerScreen(withAlert) {
  const alert = withAlert ? (state.alert || { name: DEFAULTS.spectatorName, distanceMeters: 180 }) : null;
  return `
    ${statusBar()}
    ${navBar('Running', { right: '<button data-action="goto" data-screen="settings">Settings</button>' })}
    <div class="neo-body tight">
      <div class="neo-card status-card">
        <span class="status-chip">Live</span>
        <h2 class="neo-heading">Sharing location</h2>
        <p class="neo-sub">Spectators can see you on the map. Your Watch will alert when someone is within range.</p>
      </div>

      ${alert ? alertBanner(alert) : ''}

      <div class="block">
        <p class="section-label">Session code</p>
        <div class="neo-card neo-card-pad" style="display: flex; flex-direction: column; gap: 12px;">
          <p class="code-display left">${esc(state.sessionCode || DEFAULTS.sessionCode)}</p>
          <button class="neo-btn secondary sun" type="button">Share with spectators</button>
        </div>
      </div>

      <div class="block">
        <p class="section-label coral">Alert distance</p>
        <div class="neo-card neo-card-pad">
          ${slider({
            value: state.runnerThreshold,
            accent: 'coral',
            hint: 'Notify me when a spectator is within this range',
          })}
        </div>
      </div>

      <div class="block">
        <p class="section-label mint">GPS</p>
        <div class="neo-card flat neo-card-pad" style="background: #f7f2e3;">
          <p class="gps-mono">${snapshot().runner.map((v) => v.toFixed(5)).join(', ')}</p>
        </div>
      </div>
    </div>`;
}

function mapLayer() {
  const snap = snapshot();
  return `
    <div class="map-stage" id="map-stage">
      <svg id="map-svg" preserveAspectRatio="none" aria-hidden="true"></svg>
      <div class="map-pin runner" id="pin-runner">
        <div class="pin-body">${ICONS.pinRunner}</div>
        <div class="pin-name">${esc(state.runnerName || DEFAULTS.runnerName)}</div>
      </div>
      <div class="map-pin me" id="pin-me">
        <div class="pin-body">${ICONS.pinMe}</div>
        <div class="pin-name">You</div>
      </div>
      <div class="map-pin other" id="pin-other">
        <div class="pin-body">${ICONS.pinOther}</div>
        <div class="pin-name">Priya</div>
      </div>
      <div class="map-overlay">
        <div>${state.alert ? alertBanner(state.alert) : ''}</div>
        ${state.sheetExpanded ? expandedSheet(snap) : collapsedSheet(snap)}
      </div>
    </div>`;
}

function collapsedSheet(snap) {
  return `
    <div class="sheet" data-action="toggle-sheet">
      <div class="sheet-handle"></div>
      <div class="sheet-peek">
        <div class="peek-name">
          <strong>${esc(state.runnerName || DEFAULTS.runnerName)}</strong>
          <span>to your location</span>
        </div>
        <div class="sheet-metric primary">
          <b>${snap.distanceText}</b>
          <small>Away</small>
        </div>
        <div class="sheet-metric">
          <b>${snap.etaText || '—'}</b>
          <small>ETA</small>
        </div>
        ${ICONS.chevronUp}
      </div>
    </div>`;
}

function expandedSheet(snap) {
  return `
    <div class="sheet" data-action="toggle-sheet">
      <div class="sheet-handle"></div>
      <div class="sheet-header">
        <span>DETAILS</span>
        ${ICONS.chevronDown}
      </div>

      <div>
        <p class="section-label electric">Distance</p>
        <p class="metric-caption">Runner to you</p>
        <p class="hero-value">${snap.distanceText}</p>
      </div>

      ${snap.etaText ? `
        <div class="eta-pill">
          <b>${snap.etaText}</b>
          <span>ETA</span>
        </div>
      ` : `<p class="neo-sub">Runner has passed your spot.</p>`}

      <hr class="neo-divider" />

      ${slider({
        value: state.spectatorThreshold,
        accent: 'electric',
        label: 'Alert distance',
        hint: 'Notify me when the runner is this close',
      })}
    </div>`;
}

function spectatorScreen() {
  return `
    ${statusBar()}
    ${navBar('SF Marathon 2026', {
      left: `<button aria-label="Import course">${ICONS.map}</button>`,
      right: '<button data-action="goto" data-screen="settings">Settings</button>',
    })}
    ${mapLayer()}`;
}

function settingsScreen() {
  return `
    ${statusBar()}
    ${navBar('Settings', { right: '<button data-action="back">Done</button>' })}
    <div class="neo-body">
      <div class="settings-group">
        <p class="section-label lavender">You</p>
        <div class="neo-card settings-rows">
          <div class="settings-row"><dt>Name</dt><dd>${esc(state.spectatorName || DEFAULTS.spectatorName)}</dd></div>
          <div class="settings-row"><dt>Role</dt><dd>Spectator</dd></div>
        </div>
      </div>

      <div class="settings-group">
        <p class="section-label">Session</p>
        <div class="neo-card settings-rows">
          <div class="settings-row"><dt>Code</dt><dd>${esc(state.sessionCode || DEFAULTS.sessionCode)}</dd></div>
          <div class="settings-row"><dt>Course</dt><dd>SF Marathon 2026</dd></div>
        </div>
      </div>

      <div class="settings-group">
        <p class="section-label mint">Permissions</p>
        <div class="neo-card settings-rows">
          <div class="settings-row"><dt>Location</dt><dd>While Using</dd></div>
          <div class="settings-row"><dt>Notifications</dt><dd>Allowed</dd></div>
        </div>
      </div>

      <div class="form-actions">
        <button class="neo-btn danger" data-action="leave">Leave session</button>
      </div>
    </div>`;
}

const SCREENS = {
  home: { label: 'Home', render: homeScreen },
  create: { label: 'Create session', render: createScreen },
  'create-code': { label: 'Session code', render: createScreen },
  runner: { label: 'Runner dashboard', render: () => runnerScreen(false) },
  'runner-alert': { label: 'Runner · alert', render: () => runnerScreen(true) },
  join: { label: 'Join session', render: joinScreen },
  spectator: { label: 'Spectator map', render: spectatorScreen },
  'spectator-expanded': { label: 'Spectator · details', render: spectatorScreen },
  'spectator-alert': { label: 'Spectator · alert', render: spectatorScreen },
  settings: { label: 'Settings', render: settingsScreen },
};

// ---------------------------------------------------------------- watch faces

function watchFace() {
  const snap = snapshot();
  if (state.watchScreen === 'alert') {
    const alert = state.alert || { name: DEFAULTS.spectatorName, distanceMeters: 180 };
    return `
      <div class="watch-content">
        <span class="status-chip alert">Alert</span>
        <p class="watch-name">${esc(alert.name)}</p>
        <p class="watch-shout">NEARBY</p>
        <p class="watch-meta">~${Math.round(alert.distanceMeters)} m</p>
      </div>`;
  }
  return `
    <div class="watch-content">
      <span class="status-chip">Live</span>
      <p class="watch-time">2:14:32</p>
      <p class="watch-meta">${state.runnerThreshold} m alert</p>
      <p class="watch-meta">${snap.distanceText} to ${esc(state.spectatorName || DEFAULTS.spectatorName)}</p>
    </div>`;
}

// -------------------------------------------------------------------- render

const screenEl = document.getElementById('screen');
const watchEl = document.getElementById('watch-screen');

function render() {
  const screen = SCREENS[state.screen] || SCREENS.home;
  screenEl.innerHTML = screen.render();
  watchEl.innerHTML = watchFace();
  layoutMap();
  renderPanel();
}

function layoutMap() {
  const stage = document.getElementById('map-stage');
  if (!stage) return;

  const width = stage.clientWidth || 390;
  const height = stage.clientHeight || 700;
  const pad = 34;

  const lats = COURSE.map((c) => c[0]);
  const lons = COURSE.map((c) => c[1]);
  const midLat = (Math.min(...lats) + Math.max(...lats)) / 2;
  const lonScale = Math.cos((midLat * Math.PI) / 180);

  const bounds = {
    minX: Math.min(...lons) * lonScale,
    maxX: Math.max(...lons) * lonScale,
    minY: Math.min(...lats),
    maxY: Math.max(...lats),
  };

  const spanX = bounds.maxX - bounds.minX || 1;
  const spanY = bounds.maxY - bounds.minY || 1;
  const scale = Math.min((width - pad * 2) / spanX, (height - pad * 2) / spanY);
  const offsetX = (width - spanX * scale) / 2;
  const offsetY = (height - spanY * scale) / 2;

  const project = ([lat, lon]) => ({
    x: offsetX + (lon * lonScale - bounds.minX) * scale,
    y: height - offsetY - (lat - bounds.minY) * scale,
  });

  const svg = document.getElementById('map-svg');
  svg.setAttribute('viewBox', `0 0 ${width} ${height}`);
  const path = COURSE
    .map((coord, index) => {
      const p = project(coord);
      return `${index === 0 ? 'M' : 'L'} ${p.x.toFixed(1)} ${p.y.toFixed(1)}`;
    })
    .join(' ');

  svg.innerHTML = `
    ${mapBackdrop(width, height)}
    <path d="${path}" fill="none" stroke="#0b5bd3" stroke-width="9" stroke-linejoin="round" stroke-linecap="round" opacity="0.25" />
    <path id="map-route" d="${path}" fill="none" stroke="var(--electric-bright)" stroke-width="5" stroke-linejoin="round" stroke-linecap="round" />`;

  const place = (id, coord) => {
    const el = document.getElementById(id);
    if (!el) return;
    const p = project(coord);
    el.style.left = `${p.x}px`;
    el.style.top = `${p.y}px`;
  };

  place('pin-runner', snapshot().runner);
  place('pin-me', SPECTATOR);
  place('pin-other', OTHER_SPECTATOR);
}

/** Stylised street grid so the prototype map reads as a map, not an empty field. */
function mapBackdrop(width, height) {
  const streets = [];
  for (let x = -height; x < width + height; x += 46) {
    streets.push(`<line x1="${x}" y1="0" x2="${x + height * 0.34}" y2="${height}" />`);
  }
  for (let y = 0; y < height; y += 58) {
    streets.push(`<line x1="0" y1="${y}" x2="${width}" y2="${y - width * 0.12}" />`);
  }

  return `
    <rect width="${width}" height="${height}" fill="#f3efe6" />
    <path d="M ${width * 0.62} 0 L ${width} 0 L ${width} ${height * 0.3}
             C ${width * 0.86} ${height * 0.26}, ${width * 0.74} ${height * 0.14}, ${width * 0.62} 0 Z"
          fill="#cfe6f7" />
    <path d="M 0 ${height * 0.86} L ${width * 0.3} ${height} L 0 ${height} Z" fill="#cfe6f7" />
    <rect x="${width * 0.06}" y="${height * 0.34}" width="${width * 0.26}" height="${height * 0.12}" rx="10" fill="#d8ead1" />
    <rect x="${width * 0.58}" y="${height * 0.56}" width="${width * 0.3}" height="${height * 0.1}" rx="10" fill="#d8ead1" />
    <g stroke="#e4ded0" stroke-width="2">${streets.join('')}</g>
    <g stroke="#ffffff" stroke-width="6" stroke-linecap="round">
      <line x1="0" y1="${height * 0.42}" x2="${width}" y2="${height * 0.36}" />
      <line x1="${width * 0.28}" y1="0" x2="${width * 0.44}" y2="${height}" />
    </g>`;
}

// --------------------------------------------------------------- interactions

document.addEventListener('click', (event) => {
  const target = event.target.closest('[data-action]');
  if (!target) return;
  const action = target.dataset.action;

  if (action === 'goto') {
    state.screen = target.dataset.screen;
    if (state.screen === 'spectator') state.sheetExpanded = false;
    render();
  } else if (action === 'back') {
    state.screen = state.sessionCode && state.screen === 'settings'
      ? (state.spectatorName ? 'spectator' : 'runner')
      : 'home';
    render();
  } else if (action === 'create-session') {
    state.sessionCode = DEFAULTS.sessionCode;
    render();
  } else if (action === 'join-session') {
    state.sessionCode = state.joinCode.toUpperCase();
    state.screen = 'spectator';
    render();
  } else if (action === 'toggle-sheet') {
    state.sheetExpanded = !state.sheetExpanded;
    render();
  } else if (action === 'leave') {
    Object.assign(state, {
      screen: 'home', sessionCode: null, runnerName: '', spectatorName: '', joinCode: '', alert: null,
    });
    render();
  }
});

document.addEventListener('input', (event) => {
  const target = event.target.closest('[data-action]');
  if (!target) return;
  const action = target.dataset.action;

  if (action === 'runner-name') {
    state.runnerName = target.value;
    updateDisabledButtons();
  } else if (action === 'spectator-name') {
    state.spectatorName = target.value;
    updateDisabledButtons();
  } else if (action === 'join-code') {
    state.joinCode = target.value.toUpperCase();
    updateDisabledButtons();
  } else if (action === 'threshold') {
    const value = Number(target.value);
    if (state.screen.startsWith('spectator')) state.spectatorThreshold = value;
    else state.runnerThreshold = value;
    render();
  }
});

function updateDisabledButtons() {
  const create = document.querySelector('[data-action="create-session"]');
  if (create) create.disabled = !state.runnerName.trim();
  const join = document.querySelector('[data-action="join-session"]');
  if (join) join.disabled = !(state.spectatorName.trim() && state.joinCode.trim().length >= 4);
  renderPanel();
}

window.addEventListener('resize', layoutMap);

// ------------------------------------------------------------------ simulation

function evaluateProximity() {
  const snap = snapshot();
  const isSpectatorView = state.screen.startsWith('spectator');
  const threshold = isSpectatorView ? state.spectatorThreshold : state.runnerThreshold;
  const otherName = isSpectatorView
    ? (state.runnerName || DEFAULTS.runnerName)
    : (state.spectatorName || DEFAULTS.spectatorName);

  if (snap.distanceMeters <= threshold) {
    state.alert = { name: otherName, distanceMeters: snap.distanceMeters };
    state.watchScreen = 'alert';
  } else if (snap.distanceMeters > threshold + 50) {
    state.alert = null;
    state.watchScreen = 'tracking';
  }
}

let lastTick = performance.now();

function tick(now) {
  const deltaSeconds = Math.min((now - lastTick) / 1000, 0.5);
  lastTick = now;

  if (state.simulating && !state.exportMode) {
    // Compress race time so the whole course plays out in a couple of minutes.
    const metersPerTick = runnerSpeedMps() * deltaSeconds * 40;
    state.progress = (state.progress + metersPerTick / SEGMENTS.total) % 1;
    evaluateProximity();

    const stage = document.getElementById('map-stage');
    if (stage) {
      layoutMap();
      refreshLiveText();
    } else if (state.screen.startsWith('runner')) {
      refreshLiveText();
    }
    renderPanel();
  }

  requestAnimationFrame(tick);
}

/** Update only the numbers that change every frame, so inputs keep focus. */
function refreshLiveText() {
  const snap = snapshot();
  const metrics = document.querySelectorAll('.sheet-metric b');
  if (metrics.length >= 2) {
    metrics[0].textContent = snap.distanceText;
    metrics[1].textContent = snap.etaText || '—';
  }
  const big = document.querySelector('.hero-value');
  if (big) big.textContent = snap.distanceText;
  const etaPill = document.querySelector('.eta-pill b');
  if (etaPill && snap.etaText) etaPill.textContent = snap.etaText;

  const banner = document.querySelector('.map-overlay > div');
  if (banner) banner.innerHTML = state.alert ? alertBanner(state.alert) : '';

  watchEl.innerHTML = watchFace();
}

// --------------------------------------------------------------- side panel

function renderPanel() {
  const buttons = document.getElementById('screen-buttons');
  if (!buttons) return;

  if (buttons.childElementCount === 0) {
    buttons.innerHTML = Object.entries(SCREENS)
      .map(([id, cfg]) => `<button data-screen-btn="${id}">${cfg.label}</button>`)
      .join('');
    buttons.addEventListener('click', (event) => {
      const btn = event.target.closest('[data-screen-btn]');
      if (!btn) return;
      applyScreenPreset(btn.dataset.screenBtn);
      render();
    });
  }

  buttons.querySelectorAll('[data-screen-btn]').forEach((btn) => {
    btn.setAttribute('aria-pressed', String(btn.dataset.screenBtn === state.screen));
  });

  const snap = snapshot();
  const readout = document.getElementById('state-readout');
  if (readout) {
    readout.innerHTML = `
      <dt>Distance</dt><dd>${snap.distanceText}</dd>
      <dt>ETA</dt><dd>${snap.etaText || '—'}</dd>
      <dt>Course done</dt><dd>${Math.round(state.progress * 100)}%</dd>
      <dt>Alert</dt><dd>${state.alert ? 'Firing' : 'Idle'}</dd>`;
  }

  const progressInput = document.getElementById('sim-progress');
  if (progressInput && document.activeElement !== progressInput) {
    progressInput.value = String(Math.round(state.progress * 100));
  }
}

function applyScreenPreset(id) {
  state.screen = id;
  state.sheetExpanded = id === 'spectator-expanded';

  if (id === 'create-code' || id === 'runner' || id === 'runner-alert') {
    state.sessionCode = state.sessionCode || DEFAULTS.sessionCode;
    state.runnerName = state.runnerName || DEFAULTS.runnerName;
  }
  if (id === 'create-code') state.screen = 'create';
  if (id.startsWith('spectator') || id === 'settings') {
    state.spectatorName = state.spectatorName || DEFAULTS.spectatorName;
    state.joinCode = state.joinCode || DEFAULTS.sessionCode;
    state.sessionCode = state.sessionCode || DEFAULTS.sessionCode;
  }
  if (id === 'runner-alert' || id === 'spectator-alert') {
    state.alert = { name: id === 'runner-alert' ? DEFAULTS.spectatorName : DEFAULTS.runnerName, distanceMeters: 180 };
    state.watchScreen = 'alert';
  }
}

function bindPanelControls() {
  const toggle = document.getElementById('sim-toggle');
  const progress = document.getElementById('sim-progress');
  const pace = document.getElementById('sim-pace');

  if (toggle) toggle.addEventListener('change', () => { state.simulating = toggle.checked; });
  if (progress) {
    progress.addEventListener('input', () => {
      state.progress = Number(progress.value) / 100;
      evaluateProximity();
      render();
    });
  }
  if (pace) pace.addEventListener('input', () => { state.paceMinPerKm = Number(pace.value); renderPanel(); });

  const approach = document.getElementById('sim-approach');
  if (approach) {
    approach.addEventListener('click', () => {
      state.progress = MEETING_POINT_DISTANCE / SEGMENTS.total - 0.004;
      evaluateProximity();
      render();
    });
  }

  const reset = document.getElementById('sim-reset');
  if (reset) {
    reset.addEventListener('click', () => {
      Object.assign(state, {
        progress: DEFAULTS.progress,
        alert: null,
        watchScreen: 'tracking',
        runnerThreshold: DEFAULTS.runnerThreshold,
        spectatorThreshold: DEFAULTS.spectatorThreshold,
      });
      render();
    });
  }

  const palette = document.getElementById('palette');
  if (palette) {
    palette.innerHTML = [
      ['Coral', 'coral'], ['Electric', 'electric-bright'], ['Lime', 'lime-bright'],
      ['Sun', 'sun'], ['Pink', 'pink-soft'], ['Mint', 'mint-soft'],
    ].map(([name, token]) => `<span class="wb-swatch"><i style="background: var(--${token})"></i>${name}</span>`).join('');
  }
}

// ------------------------------------------------------------------ export mode

function applyExportMode() {
  const params = new URLSearchParams(window.location.search);
  const exportTarget = params.get('export');
  if (!exportTarget) return;

  state.exportMode = exportTarget;
  state.simulating = false;
  document.body.classList.add('export', `export-${exportTarget === 'watch' ? 'watch' : 'phone'}`);

  const screen = params.get('screen');
  if (exportTarget === 'watch') {
    state.watchScreen = screen === 'watch-alert' ? 'alert' : 'tracking';
    state.alert = { name: DEFAULTS.spectatorName, distanceMeters: 180 };
  } else if (screen) {
    applyScreenPreset(screen);
  }

  // Deterministic values for screenshots.
  state.progress = params.get('screen')?.includes('alert')
    ? MEETING_POINT_DISTANCE / SEGMENTS.total - 0.0006
    : DEFAULTS.progress;

  if (screen === 'create-code') state.sessionCode = DEFAULTS.sessionCode;
  if (screen === 'create') { state.sessionCode = null; state.runnerName = 'Sarah'; }
  if (screen === 'join') { state.spectatorName = 'Tanay'; state.joinCode = DEFAULTS.sessionCode; }
}

// ------------------------------------------------------------------------ boot

applyExportMode();
bindPanelControls();
render();
requestAnimationFrame(tick);

// Signal readiness for the headless screenshot script.
requestAnimationFrame(() => {
  layoutMap();
  window.__protoReady = true;
  document.body.dataset.ready = 'true';
});

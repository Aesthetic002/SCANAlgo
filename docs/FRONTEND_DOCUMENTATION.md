# Frontend Documentation

## Overview

The web frontend provides an interactive visualization comparing two elevator scheduling algorithms (SCAN vs FCFS) in real-time. It consists of two pages:

1. **Landing Page** (`index.html`) — An informational page explaining the SCAN algorithm.
2. **Simulation Page** (`simulation.html`) — The interactive elevator comparison tool.

---

## File Structure

```
frontend/
├── index.html          # Landing page
├── simulation.html     # Simulation page
├── elevator.js         # Core elevator logic and WebSocket integration
├── landing.js          # Landing page animations and interactions
├── styles.css          # Simulation page styling
├── landing.css         # Landing page styling
└── vercel.json         # Vercel deployment configuration
```

---

## Landing Page (`index.html` + `landing.js` + `landing.css`)

### Sections

| Section       | Description                                                      |
| ------------- | ---------------------------------------------------------------- |
| **Hero**      | Animated title, stats (40% efficiency, 8 floors, Real-time), elevator demo |
| **Features**  | 6 cards: Optimized Path, Fair Scheduling, 40% Faster, Predictable, Energy Efficient, Industry Standard |
| **Comparison**| Side-by-side SCAN vs FCFS with visual path diagrams and stats    |
| **How It Works** | 4-step flow: Collect → Direction → Sweep → Reverse           |
| **CTA**       | "Launch Interactive Simulation" button                           |
| **Footer**    | Project info and links                                           |

### Navigation

A "tubelight" navbar with icons for Home, Features, Compare, How It Works, and a "Simulate" CTA button that links to `simulation.html`.

---

## Simulation Page (`simulation.html` + `elevator.js` + `styles.css`)

### UI Layout

```
┌──────────────────────────────────────────────────────────┐
│                    HEADER / TITLE                         │
├─────────────────┬────────────────────┬───────────────────┤
│   SCAN Elevator │  Request Buttons   │  FCFS Elevator    │
│   (8 floors)    │  [7][6][5][4]      │  (8 floors)       │
│   ┌─┐           │  [3][2][1][0]      │  ┌─┐              │
│   │█│ ← car     │                    │  │█│ ← car        │
│   └─┘           │  [Emergency]       │  └─┘              │
│                 │  [Reset] [Random]  │                   │
│  Stats Panel    │                    │  Stats Panel      │
│  - Floors: 12   │                    │  - Floors: 19     │
│  - Served: 4    │                    │  - Served: 4      │
│  - State: MOVE  │  Comparison Panel  │  - State: IDLE    │
│                 │  Total Floors Bar  │                   │
│                 │  SCAN Efficiency % │                   │
└─────────────────┴────────────────────┴───────────────────┘
```

---

## JavaScript Classes (`elevator.js`)

### Class Hierarchy

```
BaseElevator (abstract)
├── ScanElevator          # JS-only SCAN implementation
├── FcfsElevator          # JS-only FCFS implementation
└── RemoteScanElevator    # WebSocket → Verilog backend (with JS fallback)

ElevatorComparison        # Controller managing both elevators
```

### BaseElevator

The abstract base class that provides:

- **State Machine**: `IDLE → MOVE → ARRIVE → DOOR_OPEN → DOOR_WAIT → IDLE`
- **Properties**: `currentFloor`, `direction`, `pendingRequests`, `state`, `floorsTraversed`, `requestsServed`, `emergency`
- **DOM Management**: Creates and manages elevator shaft, car, floor indicators, stats panel
- **Core Methods**:
  - `addRequest(floor)` — Adds a floor request
  - `processNextState()` — Main state machine loop (called on a timer)
  - `getNextTarget()` — Abstract method (overridden by subclasses)
  - `updatePosition()` — Updates car CSS position
  - `updateFloorIndicators()` — Highlights pending request floors
  - `updateUI()` — Updates stats display (floors, served, state)

### ScanElevator

Extends `BaseElevator` with the SCAN algorithm:

```javascript
getNextTarget() {
    // 1. Filter requests in current direction
    // 2. Sort by proximity
    // 3. If none in current direction, reverse and check other direction
    // 4. Return nearest request in sweep order
}
```

### FcfsElevator

Extends `BaseElevator` with First-Come-First-Serve:

```javascript
getNextTarget() {
    // Simply return the first request in the queue (arrival order)
    return this.pendingRequests[0];
}
```

### RemoteScanElevator

Extends `BaseElevator` with WebSocket integration and automatic fallback:

**Connection Flow:**
1. Constructor calls `connect()`.
2. `connect()` creates WebSocket to `ws://localhost:8766`.
3. On success: starts step loop (`processNextState` → sends `step` commands).
4. On failure: increments `connectionAttempts`. After 2 failures → `activateFallback()`.

**Fallback Mode:**
When `this.fallbackMode === true`, all overridden methods delegate to `BaseElevator`:
- `addRequest()` → `super.addRequest()`
- `processNextState()` → `super.processNextState()` (uses built-in `getNextTarget()`)
- `setEmergency()` → `super.setEmergency()`

**Backend Mode:**
When connected to the backend:
- `addRequest(floor)` → sends `{ type: "request", floor }` via WebSocket
- `processNextState()` → sends `{ type: "step" }` via WebSocket
- `updateStateFromBackend(data)` → parses response, updates floor/state/stats

**Stats Tracking (Backend Mode):**
- `floorsTraversed` incremented by `Math.abs(currentFloor - prevFloor)` on each state update
- `requestsServed` incremented when `DOOR_OPEN` or `DOOR_WAIT` state is seen at a pending floor
- Request indicators cleared automatically when floor is served

### ElevatorComparison

Controller class that:
- Creates `RemoteScanElevator` (for SCAN) and `FcfsElevator` (for FCFS)
- Sets up shared floor request buttons (sends to both elevators)
- Manages Emergency and Reset buttons
- Updates the comparison bar chart periodically

---

## Styling

### Design System

| Property           | Value                                    |
| ------------------ | ---------------------------------------- |
| Primary Color      | `#3b82f6` (Blue)                         |
| SCAN Color         | Blue-Cyan gradient                       |
| FCFS Color         | Orange-Red gradient                      |
| Background         | `#0a0a0f` (Near-black)                   |
| Font               | Inter (Google Fonts)                     |
| Glass Effect       | `backdrop-filter: blur()` + transparency |
| Animations         | CSS keyframes + JS transitions           |

### Key CSS Features

- **Glassmorphism**: Cards and panels use `backdrop-filter: blur(12px)` with semi-transparent backgrounds.
- **Animated Background**: Floating gradient orbs with `@keyframes` animation.
- **Elevator Shaft**: CSS grid with floor indicators, animated car position via `transform: translateY()`.
- **Responsive**: Flexbox and media queries adapt to different screen sizes.

# Smart Elevator Controller — SCAN Scheduling Algorithm

**An Industry-Grade 8-Floor Elevator Controller with Verilog HDL, Interactive Web Simulation, and Real-Time Hardware-Software Integration**

---

## Table of Contents

1.  [Executive Summary](#executive-summary)
2.  [Project Overview](#project-overview)
3.  [Architecture & Design](#architecture--design)
4.  [SCAN Scheduling Algorithm](#scan-scheduling-algorithm)
5.  [Verilog Implementation](#verilog-implementation)
6.  [Web Frontend & Visualization](#web-frontend--visualization)
7.  [Verilog-to-Web Backend](#verilog-to-web-backend)
8.  [Safety Features](#safety-features)
9.  [Verification & Testing](#verification--testing)
10. [Deployment](#deployment)
11. [How to Run](#how-to-run)
12. [Project Structure](#project-structure)

---

## Executive Summary

This project implements an **industry-grade 8-floor smart elevator controller** using Verilog HDL. The design incorporates the **SCAN (Elevator) scheduling algorithm**, a hierarchical Finite State Machine (FSM), comprehensive safety features, and realistic timing models.

**Key Innovation**: The project features a **dual-mode architecture**:
- **Hardware Mode**: The Verilog RTL design (`smart_elevator.v`) is the source of truth for elevator logic. A Python WebSocket server bridges the Verilog simulation to a web browser, allowing the *real hardware logic* to drive the visualization in real-time.
- **Software Mode**: When the Verilog backend is unavailable (e.g., on a hosted deployment), the frontend gracefully falls back to a JavaScript implementation of the same SCAN algorithm.

---

## Project Overview

### Objectives
- Design a smart elevator controller for 8 floors (0–7)
- Implement the SCAN scheduling algorithm for efficient request handling
- Create a hierarchical FSM with safety priority
- Include realistic timing models for movement and door operations
- Implement comprehensive safety features (emergency, overload, obstruction)
- Develop a self-checking testbench for verification
- Build an interactive web visualization comparing SCAN vs FCFS
- Bridge Verilog simulation to the web via a Python WebSocket backend

### Specifications

| Parameter              | Specification                          |
| ---------------------- | -------------------------------------- |
| Number of Floors       | 8 (Floor 0 to Floor 7)                |
| Scheduling Algorithm   | SCAN (Elevator Algorithm)              |
| FSM Architecture       | Hierarchical with Safety Priority      |
| Clock Frequency        | 100 MHz (10ns period)                  |
| Floor Travel Time      | 50 clock cycles (500ns)                |
| Door Open Time         | 30 clock cycles (300ns)                |
| Door Wait Time         | 20 clock cycles (200ns)                |
| Web Frontend           | Vanilla HTML/CSS/JS                    |
| Backend Bridge         | Python 3 + `asyncio` + `websockets`   |
| Deployment             | Vercel (static frontend)               |

---

## Architecture & Design

### System Architecture

The project operates across three domains:

```
┌──────────────────────────────────────────────────────────────────┐
│                     SYSTEM ARCHITECTURE                          │
├──────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌─────────────────┐     WebSocket      ┌──────────────────┐   │
│  │   Web Frontend   │◄──────────────────►│  Python Backend  │   │
│  │   (Browser)      │   ws://8766        │  (server.py)     │   │
│  │                  │                    │                  │   │
│  │  - Landing Page  │                    │  - Compiles .v   │   │
│  │  - Simulation UI │                    │  - Runs vvp      │   │
│  │  - SCAN vs FCFS  │                    │  - JSON bridge   │   │
│  └─────────────────┘                    └────────┬─────────┘   │
│         │                                         │             │
│         │ Fallback (no backend)          stdin/stdout            │
│         ▼                                         ▼             │
│  ┌─────────────────┐                    ┌──────────────────┐   │
│  │ JS SCAN Logic   │                    │ Verilog Sim      │   │
│  │ (ScanElevator)  │                    │ (Icarus Verilog) │   │
│  │                 │                    │ smart_elevator.v │   │
│  └─────────────────┘                    │ tb_interactive.v │   │
│                                          └──────────────────┘   │
└──────────────────────────────────────────────────────────────────┘
```

### Verilog Block Diagram

```
┌─────────────────────────────────────────────────────┐
│           Smart Elevator Controller                 │
├─────────────────────────────────────────────────────┤
│                                                     │
│  ┌──────────────┐         ┌──────────────┐        │
│  │   Request    │         │   Safety     │        │
│  │   Latching   │────────►│   Priority   │        │
│  │   Logic      │         │   Handler    │        │
│  └──────────────┘         └──────┬───────┘        │
│         │                        │                 │
│         ▼                        ▼                 │
│  ┌──────────────────────────────────┐             │
│  │    Hierarchical FSM Controller    │             │
│  │  IDLE ─► MOVE ─► ARRIVE          │             │
│  │  DOOR_OPEN ─► DOOR_WAIT          │             │
│  │  EMERGENCY / OVERLOAD            │             │
│  └────────┬─────────────────┬───────┘             │
│           │                 │                      │
│           ▼                 ▼                      │
│  ┌──────────────┐   ┌──────────────┐             │
│  │ SCAN Algo    │   │   Timing     │             │
│  │ Direction    │   │   Control    │             │
│  │ Logic        │   │   Counters   │             │
│  └──────────────┘   └──────────────┘             │
│           │                 │                      │
│           ▼                 ▼                      │
│  ┌─────────────────────────────────┐              │
│  │      Output Control Logic       │              │
│  │  Motor  │  Door  │  Alarm       │              │
│  └─────────────────────────────────┘              │
└─────────────────────────────────────────────────────┘
```

### Input/Output Interface

**Inputs:**

| Signal        | Width | Description                              |
| ------------- | ----- | ---------------------------------------- |
| `clk`         | 1-bit | System clock (100 MHz)                   |
| `reset`       | 1-bit | Asynchronous reset (active high)         |
| `req[7:0]`    | 8-bit | Floor request buttons (one-hot encoded)  |
| `emergency`   | 1-bit | Emergency stop signal                    |
| `overload`    | 1-bit | Weight overload detector                 |
| `door_sensor` | 1-bit | Door obstruction sensor                  |

**Outputs:**

| Signal              | Width | Description                        |
| ------------------- | ----- | ---------------------------------- |
| `current_floor[2:0]`| 3-bit | Current floor number (0–7)         |
| `direction`         | 1-bit | Travel direction (1=UP, 0=DOWN)    |
| `motor_enable`      | 1-bit | Motor control signal               |
| `door_open`         | 1-bit | Door state indicator               |
| `alarm`             | 1-bit | Emergency/overload alarm           |

---

## SCAN Scheduling Algorithm

### Algorithm Overview

The SCAN algorithm (also called the **Elevator Algorithm**) is borrowed from disk scheduling. It operates on a simple principle:

> **"Continue in the current direction until no more requests exist in that direction, then reverse."**

### How It Works

1. **Collect Requests** — Multiple floor requests arrive from passengers.
2. **Choose Direction** — Elevator picks a direction (UP or DOWN) based on pending requests.
3. **Sweep & Serve** — Serves ALL requests in that direction.
4. **Reverse** — At the end, reverses direction and repeats.

### SCAN vs FCFS Comparison

| Metric                  | SCAN       | FCFS       |
| ----------------------- | ---------- | ---------- |
| Floors Traveled (example)| 7          | 19         |
| Direction Changes       | 1          | 3          |
| Efficiency              | ~40% better| Baseline   |
| Request Starvation      | None       | Possible   |
| Predictability          | High       | Low        |

### Verilog Implementation

The SCAN logic is implemented via two helper functions in `smart_elevator.v`:

- **`has_request_above(floor, requests)`** — Checks if any pending requests exist above the given floor.
- **`has_request_below(floor, requests)`** — Checks if any pending requests exist below the given floor.
- **`find_next_request(floor, dir, requests)`** — Finds the nearest request in the current direction.

---

## Verilog Implementation

### Module: `smart_elevator`

**File:** `smart_elevator.v` (353 lines)

The core RTL module implements:

- **Hierarchical 7-State FSM**: `IDLE → MOVE → ARRIVE → DOOR_OPEN → DOOR_WAIT` (normal flow), with `EMERGENCY` and `OVERLOAD` as priority interrupt states.
- **Request Latching**: Incoming `req[7:0]` signals are latched into `pending_requests[7:0]`, which persist until served.
- **SCAN Direction Logic**: Functions `has_request_above`, `has_request_below`, and `find_next_request` implement the sweep algorithm.
- **Timing Counters**: `travel_counter` and `door_timer` provide realistic timing for floor movement and door operations.
- **Safety Priority**: Emergency overrides ALL states. Overload pauses operation with door open. Obstruction restarts door timer.

### FSM State Transition Diagram

```
     RESET
       │
       ▼
     IDLE ◄──────────────────────┐
       │                         │
       │ (request pending)       │ (no more requests)
       ▼                         │
     MOVE ──────────────────►  ARRIVE
       ▲                         │
       │   (not target floor)    │ (target floor reached)
       │                         ▼
       │                     DOOR_OPEN
       │                         │
       │                         │ (timer expires)
       │                         ▼
       └──────────────────── DOOR_WAIT

  ┌─────────────────────────────────────┐
  │  EMERGENCY (interrupts ANY state)   │
  │  OVERLOAD  (pauses with door open)  │
  └─────────────────────────────────────┘
```

### Testbenches

1. **`tb_smart_elevator.v`** — Comprehensive self-checking testbench with 10 test scenarios.
2. **`backend/tb_interactive.v`** — Interactive testbench that reads commands from stdin and outputs state to stdout, enabling real-time control from the Python backend.

---

## Web Frontend & Visualization

### Landing Page (`frontend/index.html`)

A modern, animated landing page that explains the SCAN algorithm with:
- Hero section with animated elements and elevator demo
- Features grid (6 cards explaining SCAN advantages)
- Side-by-side SCAN vs FCFS comparison with visual path diagrams
- "How It Works" 4-step explainer
- Call-to-action linking to the interactive simulation

### Simulation Page (`frontend/simulation.html`)

An interactive side-by-side comparison of SCAN vs FCFS elevators:
- **8-floor elevator shafts** with animated car movement
- **Floor request buttons** (shared between both elevators)
- **Real-time statistics**: Floors Traveled, Requests Served, Current State
- **Comparison bar chart** showing efficiency difference
- **Emergency button** and **Reset** controls
- **Random request generator** for quick testing

### JavaScript Architecture

| Class                  | Purpose                                                     |
| ---------------------- | ----------------------------------------------------------- |
| `BaseElevator`         | Base class with common state machine, timers, UI updates    |
| `ScanElevator`         | JS implementation of SCAN algorithm (`getNextTarget`)       |
| `FcfsElevator`         | JS implementation of FCFS algorithm                         |
| `RemoteScanElevator`   | Connects to Verilog backend via WebSocket; falls back to JS |
| `ElevatorComparison`   | Controller class managing both elevators and shared UI      |

---

## Verilog-to-Web Backend

### How It Works

The Python backend (`backend/server.py`) bridges the Verilog simulation to the browser:

1. **Compile**: Runs `iverilog` to compile `smart_elevator.v` + `tb_interactive.v` into `sim.vvp`.
2. **Simulate**: Launches `vvp sim.vvp` as a subprocess with piped stdin/stdout.
3. **WebSocket Server**: Listens on `ws://0.0.0.0:8766` for browser connections.
4. **Message Loop**: Translates JSON WebSocket messages into Verilog testbench commands and vice versa.

### Communication Protocol

**Frontend → Backend (JSON over WebSocket):**

| Message Type | Payload                         | Effect                          |
| ------------ | ------------------------------- | ------------------------------- |
| `step`       | `{}`                            | Advances Verilog clock 10 cycles|
| `request`    | `{ floor: 0-7 }`               | Sets `req[floor]` = 1           |
| `reset`      | `{}`                            | Asserts `reset` signal          |
| `emergency`  | `{ value: true/false }`         | Toggles `emergency` input       |

**Backend → Frontend (JSON over WebSocket):**

| Field    | Type | Description                                |
| -------- | ---- | ------------------------------------------ |
| `STATE`  | int  | FSM state (0=IDLE, 1=MOVE, 3=DOOR_OPEN…)  |
| `FLOOR`  | int  | Current floor (0–7)                        |
| `DIR`    | int  | Direction (1=UP, 0=DOWN)                   |
| `MOTOR`  | int  | Motor enable                               |
| `DOOR`   | int  | Door open                                  |
| `ALARM`  | int  | Alarm active                               |

### Fallback Mechanism

When the backend is unavailable (e.g., on Vercel):
1. `RemoteScanElevator` attempts WebSocket connection.
2. After **2 failed attempts** (~4 seconds), it activates **fallback mode**.
3. In fallback mode, all methods delegate to `BaseElevator` + the built-in `getNextTarget()` SCAN logic.
4. The user sees no difference — both modes use the same SCAN algorithm.

---

## Safety Features

| Feature                | Priority | Behavior                                        |
| ---------------------- | -------- | ----------------------------------------------- |
| **Emergency Stop**     | Highest  | Immediately halts at current floor, opens doors, sounds alarm |
| **Overload Detection** | High     | Pauses operation, keeps doors open until resolved|
| **Door Obstruction**   | Medium   | Restarts door timer, prevents closing on obstacle|

All safety features are implemented in both the Verilog module and the JavaScript fallback.

---

## Verification & Testing

### Automated Testbench (`tb_smart_elevator.v`)

10 comprehensive test scenarios:

1. Reset & Initialization
2. Single Floor Request (Upward)
3. Multiple Upward Requests (SCAN order)
4. Direction Reversal
5. Mixed Requests (Complete SCAN cycle)
6. Emergency During Motion
7. Door Obstruction
8. Overload Detection
9. Current Floor Request
10. Stress Test (All Floors Simultaneously)

### Running Simulation

```bash
# Windows (PowerShell)
.\run_sim.ps1

# Windows (CMD)
run_sim.bat

# Linux/Mac
./run_sim.sh
```

### Expected Output

```
[INFO] Starting simulation...
[TEST 1] Reset & Initialization - PASS
[TEST 2] Single Floor Request - PASS
...
*** ALL TESTS PASSED! ***
```

---

## Deployment

### Vercel (Static Frontend)

The `frontend/` directory is deployed to Vercel as a static site.

- **Root Directory**: `frontend`
- **Configuration**: `frontend/vercel.json`
- **GitHub Repo**: [Aesthetic002/SCANAlgo](https://github.com/Aesthetic002/SCANAlgo)

On Vercel, the SCAN elevator runs in **JavaScript fallback mode** (no Verilog backend).

### Local (with Verilog Backend)

When running locally with `python backend/server.py`, the SCAN elevator is driven by the **real Verilog simulation** via WebSocket.

---

## How to Run

### Prerequisites

- **Icarus Verilog** (for Verilog simulation): [Download](http://bleyer.org/icarus/)
- **Python 3.8+** with `websockets` library: `pip install websockets`
- A modern web browser

### Quick Start

```bash
# 1. Start the Verilog backend
python backend/server.py

# 2. Open the frontend in a browser
# Navigate to frontend/index.html (landing page)
# Or frontend/simulation.html (simulation directly)

# 3. Click floor buttons and watch both elevators!
```

### Running Without Backend

Simply open `frontend/index.html` in a browser. The SCAN elevator will automatically fall back to JavaScript logic after ~4 seconds.

---

## Project Structure

```
ADLD_EL/
├── smart_elevator.v              # Core Verilog RTL module (353 lines)
├── tb_smart_elevator.v           # Self-checking testbench (10 scenarios)
├── README.md                     # This file — main project documentation
│
├── backend/
│   ├── server.py                 # Python WebSocket server (Verilog bridge)
│   └── tb_interactive.v          # Interactive testbench for real-time control
│
├── frontend/
│   ├── index.html                # Landing page
│   ├── simulation.html           # Interactive simulation page
│   ├── elevator.js               # Elevator logic (SCAN, FCFS, Remote)
│   ├── landing.js                # Landing page animations
│   ├── styles.css                # Simulation page styles
│   ├── landing.css               # Landing page styles
│   └── vercel.json               # Vercel deployment configuration
│
├── docs/                         # Detailed documentation
│   ├── README.md                 # Documentation index
│   ├── SYSTEM_ARCHITECTURE.md    # Architecture overview
│   ├── HARDWARE_DESIGN.md        # Verilog module details
│   ├── ALGORITHMS.md             # SCAN vs FCFS comparison
│   ├── FRONTEND_DOCUMENTATION.md # Web frontend details
│   ├── TESTING_AND_VERIFICATION.md # Test scenarios
│   ├── RUNNING_VERILOG_BACKEND.md  # Backend setup guide
│   └── VERILOG_TO_WEB_GUIDE.md   # Integration architecture
│
├── run_sim.ps1                   # Windows PowerShell simulation script
├── run_sim.bat                   # Windows CMD simulation script
├── run_sim.sh                    # Linux/Mac simulation script
│
├── VIVA_GUIDE.md                 # Viva Q&A preparation (60 questions)
├── Presentation.md               # Presentation slide content
├── QUICK_START.md                # Quick start reference
└── .gitignore
```

---

## References

1. A. S. Tanenbaum, "Modern Operating Systems," 4th ed., Pearson, 2014. (SCAN/Elevator Algorithm)
2. D. Thomas and P. Moorby, "The Verilog Hardware Description Language," Springer, 2002.
3. IEEE Standard 1364-2005, "IEEE Standard for Verilog Hardware Description Language."

---

*Built as an Advanced Digital Logic Design (ADLD) project — demonstrating the SCAN scheduling algorithm from algorithm to architecture.*

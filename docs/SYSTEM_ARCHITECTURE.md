# System Architecture

## Overview

The **Smart Elevator Controller** is a multi-domain system demonstrating advanced digital logic design and real-time hardware-software integration. The architecture spans three domains:

1. **Hardware Domain (Verilog RTL)** — The core elevator controller implemented in synthesizable Verilog HDL.
2. **Backend Domain (Python)** — A WebSocket server that bridges the Verilog simulation to the browser.
3. **Frontend Domain (Web)** — An interactive visualization and comparison tool built with HTML/CSS/JavaScript.

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                    USER'S BROWSER                           │
│                                                             │
│  ┌──────────────┐     ┌────────────────────────────────┐   │
│  │ Landing Page  │────►│ Simulation Page                │   │
│  │ index.html    │     │ simulation.html                │   │
│  │ landing.css   │     │ styles.css + elevator.js       │   │
│  │ landing.js    │     │                                │   │
│  └──────────────┘     │  ┌──────────┐  ┌──────────┐   │   │
│                        │  │ SCAN     │  │ FCFS     │   │   │
│                        │  │ Elevator │  │ Elevator │   │   │
│                        │  └────┬─────┘  └──────────┘   │   │
│                        └───────┼────────────────────────┘   │
│                                │                            │
│              WebSocket (ws://localhost:8766)                 │
│              OR JavaScript fallback                         │
└────────────────────────────────┼────────────────────────────┘
                                 │
┌────────────────────────────────┼────────────────────────────┐
│              PYTHON BACKEND (server.py)                     │
│                                │                            │
│  ┌────────────────┐   ┌───────┴────────┐                   │
│  │ WebSocket      │   │ JSON ↔ Command │                   │
│  │ Server         │──►│ Translator     │                   │
│  │ (asyncio)      │   │                │                   │
│  └────────────────┘   └───────┬────────┘                   │
│                               │ stdin/stdout               │
│                      ┌────────┴────────┐                   │
│                      │ vvp sim.vvp     │                   │
│                      │ (Icarus Verilog)│                   │
│                      └────────┬────────┘                   │
└───────────────────────────────┼─────────────────────────────┘
                                │
┌───────────────────────────────┼─────────────────────────────┐
│              VERILOG SIMULATION                             │
│                               │                             │
│  ┌────────────────────────────┴────────────────────────┐   │
│  │              tb_interactive.v                        │   │
│  │  Reads commands from stdin (R=Request, S=Step, etc.) │   │
│  │  Outputs STATE:X|FLOOR:Y|DIR:Z|... to stdout        │   │
│  └────────────────────────────┬────────────────────────┘   │
│                               │                             │
│  ┌────────────────────────────┴────────────────────────┐   │
│  │              smart_elevator.v                        │   │
│  │  Core FSM + SCAN algorithm + Safety logic           │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

## Data Flow

### Local Mode (with Backend)

1. User clicks a floor button in the browser.
2. `RemoteScanElevator` sends `{ type: "request", floor: X }` via WebSocket.
3. `server.py` receives the JSON message.
4. Python writes `RX` (Request command + floor digit) to `vvp`'s stdin.
5. On next `step` command, Python writes `S` to stdin.
6. `tb_interactive.v` runs 10 clock cycles and outputs `STATE:X|FLOOR:Y|...` to stdout.
7. Python reads stdout, parses the state, and sends it back as JSON over WebSocket.
8. `updateStateFromBackend()` updates the DOM — elevator position, stats, indicators.

### Deployed Mode (Vercel, no Backend)

1. `RemoteScanElevator` attempts WebSocket connection.
2. After 2 failed attempts, `activateFallback()` is called.
3. All methods now delegate to `BaseElevator` + `getNextTarget()` (JS SCAN logic).
4. The elevator operates identically using JavaScript instead of Verilog.

## Design Principles

- **Verilog is the Source of Truth**: The hardware design (`smart_elevator.v`) defines the correct elevator behavior. The JavaScript fallback mirrors this logic.
- **Clean Separation**: Each domain is independent. The frontend doesn't know or care if it's talking to Verilog or JavaScript.
- **Graceful Degradation**: The system works with or without the backend. No error messages or broken UI on Vercel.
- **Real-Time Bridge**: The WebSocket protocol is lightweight and low-latency, enabling smooth real-time visualization of the Verilog simulation.

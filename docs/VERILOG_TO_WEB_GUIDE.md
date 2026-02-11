# Verilog-to-Web Integration Guide

## Overview

This document explains the architecture that allows the Verilog HDL elevator controller to drive a real-time web visualization. The system uses a Python WebSocket server as a bridge between the Icarus Verilog simulation and the browser.

---

## Architecture

```
  Browser (JavaScript)           Python Backend              Verilog Simulation
  ────────────────────          ──────────────────          ─────────────────────
                                                            
  RemoteScanElevator             server.py                  tb_interactive.v
  │                              │                          │
  │ ──── JSON/WebSocket ──────►  │ ──── stdin ────────────► │
  │  { type: "step" }           │  "S"                     │  Run 10 clock cycles
  │  { type: "request",         │  "R5"                    │  Assert req[5] = 1
  │    floor: 5 }               │                          │
  │                              │                          │  $display("STATE:1|
  │ ◄──── JSON/WebSocket ─────  │ ◄──── stdout ──────────  │   FLOOR:3|DIR:1|...")
  │  { STATE: 1, FLOOR: 3,     │  Parse line              │
  │    DIR: 1, ... }            │                          │
  │                              │                          │
  │ updateStateFromBackend()    │                          │  smart_elevator.v
  │ → Updates DOM               │                          │  (FSM + SCAN logic)
```

---

## Communication Protocol

### Client → Server (WebSocket JSON)

#### Step Command
Advances the simulation by 10 clock cycles and returns the current state.
```json
{ "type": "step" }
```

#### Floor Request
Asserts a floor request signal in the Verilog simulation.
```json
{ "type": "request", "floor": 5 }
```

#### Reset
Asserts the reset signal, returning the elevator to floor 0.
```json
{ "type": "reset" }
```

#### Emergency Toggle
Toggles the emergency input signal.
```json
{ "type": "emergency", "value": true }
```

### Server → Client (WebSocket JSON)

After each `step` command, the server returns the current state:

```json
{
  "STATE": 1,
  "FLOOR": 3,
  "DIR": 1,
  "MOTOR": 1,
  "DOOR": 0,
  "ALARM": 0
}
```

**State Encoding:**

| Value | State       | Description                           |
| ----- | ----------- | ------------------------------------- |
| 0     | IDLE        | No pending requests                   |
| 1     | MOVE        | Traveling between floors              |
| 2     | ARRIVE      | Reached a floor, checking if target   |
| 3     | DOOR_OPEN   | Door open at target floor             |
| 4     | DOOR_WAIT   | Door waiting (after obstruction)      |
| 5     | EMERGENCY   | Emergency stop active                 |
| 6     | OVERLOAD    | Overload detected                     |

---

## Interactive Testbench (`tb_interactive.v`)

The testbench reads single-character commands from `$fgets` (stdin):

| Char | Command                  | Testbench Action                                          |
| ---- | ------------------------ | --------------------------------------------------------- |
| `S`  | Step                     | Run 10 `@(posedge clk)` cycles, output state via `$display` |
| `R`  | Request (followed by digit) | Read next char as floor number, assert `req[floor]` for 1 cycle with clock toggle |
| `X`  | Reset                    | Assert `reset` for 5 cycles                               |
| `E`  | Emergency (followed by 0/1) | Set `emergency` signal                                 |

### Output Format

```
STATE:%0d|FLOOR:%0d|DIR:%0d|MOTOR:%0d|DOOR:%0d|ALARM:%0d
```

The `%0d` format ensures no leading spaces in numeric output, which is critical for correct parsing.

---

## Python Backend (`server.py`)

### Key Classes

#### `VerilogSim`
Manages the Verilog simulation subprocess:
- `start()` — Launches `vvp sim.vvp` and waits for `READY`
- `write_command(char)` — Writes a character to simulation stdin
- `flush()` — Flushes the stdin buffer
- `read_state()` — Reads lines until a `STATE:...` line is found
- `parse_state(line)` — Splits `STATE:X|FLOOR:Y|...` into a Python dict

#### `echo(websocket)`
The WebSocket handler:
- Creates a new `VerilogSim` per client connection
- Translates JSON messages into testbench commands
- Sends parsed state back as JSON

#### `compile_verilog()`
- Auto-detects Icarus Verilog installation
- Runs `iverilog -o sim.vvp smart_elevator.v backend/tb_interactive.v`

---

## Fallback Mechanism

The `RemoteScanElevator` class handles the case where no backend is available:

```
Connection attempt 1 → WebSocket fails → wait 2s
Connection attempt 2 → WebSocket fails → activateFallback()
                                          │
                                          ▼
                                    fallbackMode = true
                                    All methods delegate to
                                    BaseElevator (JS SCAN logic)
```

This ensures the simulation works on:
- **Vercel** (static hosting, no backend)
- **GitHub Pages** (static hosting)
- **Any browser** opened directly from the file system

---

## Timing Considerations

Each `step` command runs **10 clock cycles** in the Verilog simulation. Key timing:

| Event              | Verilog Cycles | Steps Needed |
| ------------------ | -------------- | ------------ |
| Floor travel       | 50 cycles      | 5 steps      |
| Door open          | 30 cycles      | 3 steps      |
| Door wait          | 20 cycles      | 2 steps      |

The frontend sends step commands at:
- **100ms intervals** during MOVE state (smooth animation)
- **200ms intervals** during IDLE (lower CPU usage)

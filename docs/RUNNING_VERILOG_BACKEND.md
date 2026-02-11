# Running the Verilog Backend

This guide explains how to run the Python WebSocket backend that bridges the Verilog simulation to the web frontend.

---

## Prerequisites

### 1. Icarus Verilog

The backend needs `iverilog` (compiler) and `vvp` (runtime) to simulate the Verilog design.

**Windows Installation:**
- Download from [http://bleyer.org/icarus/](http://bleyer.org/icarus/)
- Install to `C:\iverilog` (default) or another location
- The backend auto-detects common paths: `C:\iverilog\bin`, `C:\Program Files\iverilog\bin`
- Alternatively, add the `bin` directory to your system PATH

**Linux/Mac:**
```bash
# Ubuntu/Debian
sudo apt install iverilog

# Mac (Homebrew)
brew install icarus-verilog
```

### 2. Python 3.8+

```bash
python --version  # Should be 3.8 or higher
```

### 3. websockets Library

```bash
pip install websockets
```

---

## Quick Start

```bash
# From the project root directory
python backend/server.py
```

**Expected output:**
```
Current Working Directory: D:\ADLD_EL
Found Icarus Verilog at: C:\iverilog\bin
Compiling Verilog with iverilog.exe...
Compilation successful.
Simulation started.
Sim Output: READY
Starting WebSocket server on ws://0.0.0.0:8766
```

Once the server is running:
1. Open `frontend/simulation.html` in a browser (or use a local HTTP server).
2. The SCAN elevator will connect to the backend automatically.
3. Console should show: `Connected to Verilog Backend`

---

## How It Works

### Startup Sequence

1. **Compile**: `iverilog -o sim.vvp smart_elevator.v backend/tb_interactive.v`
2. **Launch**: `vvp sim.vvp` as a subprocess with piped stdin/stdout
3. **Wait for READY**: The testbench prints `READY` when initialized
4. **Start WebSocket**: Listens on `ws://0.0.0.0:8766`

### Per-Client Flow

For each WebSocket client:
1. A new `VerilogSim` instance is created (fresh simulation)
2. The testbench is compiled and started
3. JSON commands are translated to testbench commands:
   - `step` → `S` (run 10 clock cycles, report state)
   - `request` → `R` + floor digit (assert request signal)
   - `reset` → `X` (assert reset)
   - `emergency` → `E` + `1`/`0` (toggle emergency)
4. State output `STATE:X|FLOOR:Y|DIR:Z|...` is parsed and sent back as JSON

---

## Troubleshooting

### "iverilog not found"

```
ERROR: iverilog.exe not found in PATH or standard locations.
```

**Fix:** Install Icarus Verilog and ensure the `bin` directory is accessible. The backend checks:
- `C:\iverilog\bin`
- `C:\Program Files\iverilog\bin`
- `C:\Program Files (x86)\iverilog\bin`
- The `IVERILOG_PATH` environment variable

### "websockets not installed"

```
Error: 'websockets' library not found.
```

**Fix:** `pip install websockets`

### Port 8766 already in use

Another instance of `server.py` may already be running.

**Fix (Windows):**
```powershell
taskkill /F /IM python.exe
python backend/server.py
```

### Frontend shows "Disconnected" / falls back to JS

- Check that `server.py` is running and shows `Starting WebSocket server on ws://0.0.0.0:8766`
- Check browser console for WebSocket errors
- Ensure the frontend is connecting to `ws://localhost:8766` (correct port)

---

## Configuration

| Setting          | Location             | Default          | Description                    |
| ---------------- | -------------------- | ---------------- | ------------------------------ |
| WebSocket Port   | `server.py` (PORT)   | `8766`           | WebSocket server port          |
| WebSocket Host   | `server.py` (HOST)   | `0.0.0.0`        | Listen on all interfaces       |
| Frontend WS URL  | `elevator.js`        | `ws://localhost:8766` | Client connection URL     |
| Ping Interval    | `server.py`          | `None` (disabled) | WebSocket keep-alive disabled |

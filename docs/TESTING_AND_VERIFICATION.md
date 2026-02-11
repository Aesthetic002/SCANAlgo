# Testing and Verification Documentation

## 1. Testbench Overview (`tb_smart_elevator.v`)

Verification is performed using a self-checking testbench (`tb_smart_elevator.v`) designed to comprehensively stress-test the hardware implementation.

### Test Environment
The testbench instantiates the Device Under Test (DUT), drives inputs, and monitors outputs against expected behavior. It simulates a 100MHz clock and includes helper tasks for common operations.

---

## 2. Test Scenarios

The verification suite includes 10 distinct test scenarios covering all aspects of the design:

| Test # | Description | Objective |
| :--- | :--- | :--- |
| **1** | **Reset & Initialization** | Verify all outputs clear to 0 on reset. |
| **2** | **Single Request (Up)** | Req Floor 3 from Floor 0. Verify movement and arrival. |
| **3** | **Multiple Requests (Up)** | Req 5, 7 while moving to 3. Verify sequential service (3->5->7). |
| **4** | **Reversal Logic** | Req Floor 1 while at 7. Verify direction change after serving 7. |
| **5** | **Mixed Requests** | Random requests (0, 7, 2, 6). Verify complex SCAN path. |
| **6** | **Emergency Stop** | Assert `emergency` while moving. Verify immediate stop. |
| **7** | **Door Obstruction** | Trigger `door_sensor` during `DOOR_WAIT`. Verify reopen. |
| **8** | **Overload** | Trigger `overload` at floor. Verify movement prevented. |
| **9** | **Refused Request** | Request current floor while busy. Verify queuing behavior. |
| **10** | **Stress Test** | Simultaneous requests on all floors. Verify all eventually served. |

---

## 3. Running Simulations

The project includes helper scripts for cross-platform simulation execution.

### Prerequisites
*   **Icarus Verilog**: For compilation and simulation (`iverilog`, `vvp`).
*   **GTKWave**: For waveform viewing.

### Command Line Execution

**Windows (PowerShell):**
```powershell
.\run_sim.ps1
```
*   Compiles `smart_elevator.v` + `tb_smart_elevator.v`.
*   Runs simulation executable.
*   Prints PASS/FAIL status for each test.
*   Opens GTKWave with `elevator_waveform.vcd`.

**Linux / macOS (Bash):**
```bash
chmod +x run_sim.sh
./run_sim.sh
```

### Manual Compilation
```bash
iverilog -o elevator_sim.vvp smart_elevator.v tb_smart_elevator.v
vvp elevator_sim.vvp
# To view results:
gtkwave elevator_waveform.vcd
```

---

## 4. Waveform Analysis

Using GTKWave, you can visualize internal signals to debug behavior.

### Critical Signals to Observe
1.  **`clk`**: Synchronization reference.
2.  **`state[3:0]`**: Observe FSM transitions (IDLE=0, MOVE=1, etc.).
3.  **`current_floor[2:0]`**: Tracks position.
4.  **`target_floor[2:0]`** (internal): Shows the SCAN algorithm's next decision.
5.  **`req[7:0]`**: Input requests.
6.  **`pending_requests[7:0]`** (internal): Shows latched requests waiting for service.
7.  **`direction`**: Watch for toggles (0->1 or 1->0) only when `state` is idle or reversing.

### Common Debug Patterns
*   **Stuck in `MOVE`**: Check `travel_counter` vs `FLOOR_TRAVEL_TIME`.
*   **Door won't close**: Check `door_sensor` or `door_timer`.
*   **Skipped Floor**: Check `find_next_request` logic or `pending_requests` bitmask.

---

## 5. Interactive Testbench (`backend/tb_interactive.v`)

In addition to the automated testbench, the project includes an **interactive testbench** used by the Python WebSocket backend for real-time control.

### Purpose
This testbench reads commands from `stdin` and outputs elevator state to `stdout`, enabling the browser to control the Verilog simulation in real-time.

### Commands

| Command | Input     | Description                                  |
| ------- | --------- | -------------------------------------------- |
| Step    | `S`       | Run 10 clock cycles, output current state    |
| Request | `R` + `N` | Assert `req[N]` for floor N (0–7)           |
| Reset   | `X`       | Assert `reset` for 5 cycles                  |
| Emergency | `E` + `0/1` | Toggle `emergency` input                  |

### State Output Format
```
STATE:%0d|FLOOR:%0d|DIR:%0d|MOTOR:%0d|DOOR:%0d|ALARM:%0d
```

### Key Implementation Details
- Requests are asserted with a clock toggle to ensure proper latching by the synchronous FSM.
- The `%0d` format prevents leading spaces in output, ensuring reliable parsing by the Python backend.
- The testbench prints `READY` after initialization, signaling to the backend that it can begin sending commands.


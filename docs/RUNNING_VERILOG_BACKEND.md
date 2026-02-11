# Running the Verilog Backend

You have successfully upgraded your project to drive the frontend visualization using the **Live Verilog Simulation** instead of JavaScript logic.

## Prerequisites
1.  **Python 3.7+** installed.
2.  **Icarus Verilog** installed and in your PATH (you already have this).
3.  **Python WebSockets Library**:
    ```bash
    pip install websockets
    ```

## How to Run

### 1. Start the Backend Server
Open a terminal in the project root (`d:\ADLD_EL`) and run:
```bash
python backend/server.py
```
*   This will compile your `smart_elevator.v` with the interactive testbench.
*   It will start a WebSocket server on `ws://localhost:8765`.
*   It will launch the `vvp` simulation process.

### 2. Launch the Frontend
Open `frontend/simulation.html` in your browser.
*   Check the browser console (F12). You should see: `"Connected to Verilog Backend"`.
*   The "SCAN" elevator is now controlled by your **Verilog Hardware Design**.
*   The "FCFS" elevator is still running on JavaScript for comparison.

## How it Works
1.  **Frontend**: Sends button clicks (e.g., "Request Floor 5") to the Python server via WebSocket.
2.  **Python Server**: Writes the command to the running Verilog simulation (`stdin`).
3.  **Verilog**:
    *   `tb_interactive.v` reads the command.
    *   Applies signal to `smart_elevator.v`.
    *   Steps the clock (10 cycles).
    *   Prints the new state (`STATE:MOVE|FLOOR:0...`).
4.  **Python Server**: Parses the state and sends it back to Frontend.
5.  **Frontend**: Updates the CSS/Animation to match the hardware state.

## Troubleshooting
*   **"Connection Refused"**: Ensure `server.py` is running.
*   **"ImportError: No module named websockets"**: Run `pip install websockets`.
*   **Compilation Failed**: Ensure `iverilog` is in your PATH. Check `backend/sim.vvp` creation.

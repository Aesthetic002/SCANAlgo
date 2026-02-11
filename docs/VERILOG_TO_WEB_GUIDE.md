# Guide: Running Verilog in the Web Browser

## Is it possible?
**YES.** It is absolutely possible to run your Verilog logic directly in a web browser and have it drive your frontend visualization. This allows your Verilog code to be the "single source of truth" instead of having to duplicate the logic in JavaScript.

However, browsers cannot understand Verilog natively. You need to bridge the gap using one of the following methods.

---

## Method 1: WebAssembly (The High-Performance Way)
This is the industry-standard approach for running complex simulations (like your SCAN algorithm) in the browser.

### The Pipeline
1.  **Verilog Code** (`smart_elevator.v`)
2.  **Verilator**: Compiles Verilog into C++ code.
3.  **Emscripten**: Compiles that C++ code into **WebAssembly (.wasm)**.
4.  **Browser**: Loads the `.wasm` file and runs it at near-native speed.

### Architecture
```mermaid
graph LR
    V[Verilog Code] -- Verilator --> C[C++ Model]
    C -- Emscripten --> W[WebAssembly (.wasm)]
    W -- Load --> B[Browser / JS]
    B -- Inputs --> W
    W -- Outputs --> B
    B -- Update UI --> D[DOM/Canvas]
```

### Implementation Steps
1.  **Install Tools**: You need `verilator` and `emscripten` installed on a Linux/WSL machine.
2.  **Create Wrapper**: Write a small C++ wrapper that exposes the simulator's input/output ports (clock, reset, requests, motor_enable) to JavaScript.
3.  **Compile**:
    ```bash
    # Step 1: Verilog -> C++
    verilator --cc smart_elevator.v --exe sim_main.cpp
    # Step 2: C++ -> Wasm
    emcc -O3 -Iobj_dir obj_dir/*.cpp sim_main.cpp -o elevator_sim.js -s WASM=1
    ```
4.  **Integrate**: Use the generated `elevator_sim.js` in your HTML.
    ```javascript
    const sim = await loadVerilogSim();
    sim.set_request(5); // Send input to Wasm
    sim.eval();         // Tick the clock
    const floor = sim.get_floor(); // Read output from Wasm
    updateElevatorUI(floor);
    ```

---

## Method 2: DigitalJS (The Visual Way)
**DigitalJS** is a library that visualizes the actual logic gates and wires in the browser. It is excellent for educational demos because users can "see" the electricity flowing through the circuit.

### The Pipeline
1.  **Verilog Code**
2.  **Yosys**: An open-source synthesis tool that converts Verilog into a JSON netlist.
3.  **DigitalJS**: A JavaScript library that reads the JSON and renders it.

### How to use it
1.  **Synthesize**:
    ```bash
    yosys -p "prep -top smart_elevator; write_json elevator.json" smart_elevator.v
    ```
2.  **Display**:
    ```html
    <script type="module">
        import { Circuit } from 'digitaljs';
        const response = await fetch('elevator.json');
        const circuitJson = await response.json();
        const circuit = new Circuit(circuitJson);
        circuit.displayOn(document.getElementById('paper'));
    </script>
    ```

### Pros & Cons
*   **Pros**: Shows the schematic (AND/OR gates, FSM state). Very cool for "Deep Dives".
*   **Cons**: Slower than WebAssembly. Might struggle with very complex timing.

---

## Method 3: Server-Side Simulation (The Easiest Integration)
If setting up C++ pipelines is too complex, you can run the simulation on a backend server (Python/Node).

1.  **Backend**: A simple Python script using `cocotb` or `verilator` wrapper.
2.  **Frontend**: Sends WebSocket messages (`{ "action": "request_floor", "floor": 5 }`).
3.  **Backend Response**: Runs the Verilog sim for a few cycles and returns the new state (`{ "current_floor": 2, "state": "MOVE" }`).
4.  **Frontend**: Just displays the data.

---

## Recommendation for Your Project
Since you already have a functional JavaScript simulation (`elevator.js`), the best "Showcase" upgrade would be **Method 2 (DigitalJS)**.
*   It allows you to display the **live hardware schematic** on your website.
*   Users can interact with the schematic (click wires to see values).
*   It proves your Verilog code is working without needing complex C++ compilation.

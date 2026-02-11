# Frontend Documentation (Web Simulation)

## 1. Project Structure

The project includes a comprehensive web-based simulation frontend located in the `frontend/` directory.

### Directory Layout
*   `index.html`: **Landing Page**. Introduction to the elevator concepts.
*   `simulation.html`: **Main Simulation Interface**. Interactive SCAN vs. FCFS demo.
*   `styles.css`: CSS styling for both pages, including animations.
*   `landing.css`: CSS specific to the landing page.
*   `elevator.js`: **Core Logic**. JavaScript classes implementing the simulation.
*   `landing.js`: Minimal scripts for the landing page interactions.

---

## 2. Simulation Logic (`elevator.js`)

The simulation is built using modern ES6+ JavaScript with a class-based architecture.

### Class: `BaseElevator`
This abstract class handles the fundamental elevator mechanics common to all scheduling types.
*   **Properties**: `currentFloor`, `targetFloor`, `direction`, `state` (IDLE, MOVE, etc.), `pendingRequests`.
*   **Methods**:
    *   `addRequest(floor)`: Adds a floor request to the queue.
    *   `processNextState()`: The main state machine loop handling transitions.
    *   `updatePosition()`: Updates the CSS `bottom` property to move the elevator div.
    *   `openDoor()` / `closeDoor()`: Toggles CSS classes for door animation.

### Class: `ScanElevator` (extends BaseElevator)
Implements the SCAN algorithm logic.
*   **Method**: `getNextTarget()` overrides base method.
    *   Separates requests into `inDirection` and `otherDirection`.
    *   Prioritizes `inDirection` (closest request first).
    *   Switches direction only if `inDirection` is empty.

### Class: `FcfsElevator` (extends BaseElevator)
Implements First-Come-First-Serve logic.
*   **Method**: `getNextTarget()` overrides base method.
    *   Simply returns `pendingRequests[0]`.

### Class: `ElevatorComparison`
Controller class managing the dual simulation.
*   **Purpose**: Runs both elevators simultaneously with shared inputs.
*   **Metrics**: Updates real-time stats (`floorsTraversed`, `requestsServed`) for both algorithms.
*   **UI Updates**: Manages the comparison bars and efficiency calculation (`+XX% Efficiency`).
*   **Input Handling**: Distributes user clicks to *both* elevator instances.

---

## 3. Visualization & CSS

### Animation
*   **Movement**: Uses CSS `transition` on the `bottom` property for smooth movement between floors.
*   **Doors**: Uses a `.door-open` class that triggers CSS changes (likely scaling or color change).
*   **Indicators**: Light up based on `pendingRequests` state.

### DOM Updates
The visualization is decoupled from the logic tick rate:
1.  **Logic Update**: Happens immediately on state change or timer expiry.
2.  **UI Loop**: Updates DOM elements (efficiency display, floor numbers) at a fixed rate (200ms) to prevent flickering.

---

## 4. Usage Guide

### Running the Simulation
1.  Open `frontend/index.html` in any modern web browser.
2.  Navigate to "Launch Simulation".
3.  Click floor buttons to add requests.
    *   Observe how the **SCAN** elevator optimizes the path.
    *   Observe how the **FCFS** elevator zig-zags inefficiently.
4.  Use the "Random" button to stress test both algorithms.
5.  Use "Emergency" to test safety override visualization.

# System Architecture

## Overview
The **Smart Elevator Controller** project is a multi-faceted system designed to demonstrate advanced digital logic design principles and algorithmic scheduling. The architecture is divided into two primary domains:

1.  **Hardware Domain (RTL)**: The core industry-grade design implemented in Verilog HDL, targeting FPGA synthesis and hardware simulation.
2.  **Software/Frontend Domain (Web)**: An interactive web-based simulation and visualization platform that allows users to understand the SCAN algorithm's efficiency compared to traditional methods.

These two domains exist in parallel:
*   The **Hardware** implementation is the "source of truth" for digital logic, timing, and safety/critical systems.
*   The **Frontend** implementation serves as a visualizer and educational tool to demonstrate the algorithmic behavior in a user-friendly manner.

---

## 1. Hardware Architecture (Verilog HDL)

The hardware architecture is designed around a **Hierarchical Finite State Machine (FSM)** that separates high-level safety logic from low-level operational logic.

### Block Diagram
```mermaid
graph TD
    subgraph "Inputs"
        CLK[Clock (100MHz)]
        RST[Reset]
        REQ[Floor Requests 0-7]
        SENSORS[Safety Sensors]
    end

    subgraph "Core Logic"
        RL[Request Latching]
        SCAN[SCAN Algorithm Logic]
        FSM[Hierarchical FSM]
    end

    subgraph "Outputs"
        MOTOR[Motor Control]
        DOOR[Door Control]
        ALARM[Safety Alarm]
        STATE[Status Indicators]
    end

    CLK --> FSM
    RST --> FSM
    REQ --> RL --> SCAN
    SENSORS --> FSM
    
    SCAN --> FSM
    FSM --> MOTOR
    FSM --> DOOR
    FSM --> ALARM
    FSM --> STATE
```

### Key Components
*   **Request Latching Module**: Asynchronously captures floor requests to ensure no button press is missed, even if the system is busy.
*   **Safety Priority Logic**: A combinatorial logic block that overrides normal operation when safety inputs (Emergency, Overload, Obstruction) are active.
*   **SCAN Direction Logic**: Implements the "Elevator Algorithm" to determine the optimal direction of travel based on current position and pending requests.
*   **Hierarchical FSM**:
    *   **Upper Layer**: Handles Safety (`EMERGENCY`, `OVERLOAD`).
    *   **Lower Layer**: Handles Operation (`IDLE`, `MOVE`, `DOOR_OPEN`, `DOOR_WAIT`).

---

## 2. Frontend Architecture (Web Simulation)

The frontend is a modern web application built with HTML5, CSS3, and Vanilla JavaScript. It implements an Object-Oriented simulation engine to visualize functionality.

### Class Structure
The JavaScript simulation is built on a modular class structure:

*   **`BaseElevator`**: Abstract base class defining common properties (current floor, direction, state) and methods (`move`, `openDoor`).
*   **`ScanElevator` (extends Base)**: Implements the specific `getNextTarget()` logic using the SCAN algorithm (same logic as hardware).
*   **`FcfsElevator` (extends Base)**: Implements First-Come-First-Served logic for comparison purposes.
*   **`ElevatorComparison`**: The main controller class that manages the DOM, event listeners, and runs the simulation loop.

### Visualization Pipeline
1.  **User Input**: Clicks on floor buttons request a floor.
2.  **State Update**: The JS engine adds the request to queues for both SCAN and FCFS elevators.
3.  **Simulation Loop**:
    *   Updates elevator positions.
    *   Manages timers (door open/close, travel time).
    *   Updates the DOS (Document Object Model) to reflect state changes (animations, lights).
4.  **Real-Time Comparison**: Calculates and displays efficiency metrics (floors traversed) to prove the superiority of the SCAN algorithm.

---

## 3. Data Flow & Logic Parity

While the implementation languages differ (Verilog vs. JavaScript), the **Algorithmic Logic** is identical.

| Feature | Hardware (Verilog) | Frontend (JS) |
| :--- | :--- | :--- |
| **State Machine** | `case(state)` statement | `switch(this.state)` inside `processNextState()` |
| **Direction Logic** | `find_next_request` function | `getNextTarget()` method |
| **Timing** | Clock cycle counters | `setTimeout` delays |
| **Concurrency** | Parallel hardware blocks | Async event loop |

### System Integrity
The system ensures that the visualization accurately represents the hardware's theoretical performance. The frontend serves as a "Digital Twin" behaviorally, even though it does not physically simulate the Verilog netlist.

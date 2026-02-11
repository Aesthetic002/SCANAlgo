# Documentation Index

Welcome to the comprehensive documentation for the **Smart Elevator Controller Project**.

## 1. Introduction
This documentation covers the entirety of the project, spanning from the core hardware logic (Verilog) to the interactive frontend simulation (JavaScript).

## 2. Documentation Map

### [System Architecture](./SYSTEM_ARCHITECTURE.md)
*   High-level overview of the dual-domain architecture (Hardware vs Software).
*   Block diagrams and data flow.
*   Explanation of the relationship between the Verilog implementation and the JS simulation.

### [Hardware Design](./HARDWARE_DESIGN.md)
*   **Core Logic**: Detailed breakdown of `smart_elevator.v`.
*   **FSM**: State machine diagrams and transition logic.
*   **Interface**: Pin definitions and signal descriptions.
*   **Timing**: Cycle-accurate timing parameters.
*   **Safety**: Emergency, Overload, and Obstruction logic.

### [Algorithms](./ALGORITHMS.md)
*   **SCAN vs FCFS**: Comparative analysis of scheduling algorithms.
*   **Logic**: Detailed pseudocode and explanation of the SCAN algorithm.
*   **Efficiency**: Why SCAN is the industry standard.

### [Frontend Documentation](./FRONTEND_DOCUMENTATION.md)
*   **Web Simulation**: Structure of the `frontend/` directory.
*   **JavaScript Classes**: Explanation of `BaseElevator` and its subclasses.
*   **Visualization**: How the DOM is updated to reflect elevator state.

### [Testing and Verification](./TESTING_AND_VERIFICATION.md)
*   **Testbench**: Overview of `tb_smart_elevator.v`.
*   **Scenarios**: Detailed list of test cases (Reset, Single, Multi, Safety).
*   **Execution**: How to run simulations on Windows/Linux.
*   **Waveforms**: Guide to analyzing simulation results with GTKWave.

### [Advanced Integration: Verilog on Web](./VERILOG_TO_WEB_GUIDE.md)
*   **WebAssembly**: How to compile Verilog to Wasm for browser execution.
*   **DigitalJS**: Visualizing the hardware schematic in the browser.
*   **Architectures**: Comparison of client-side vs server-side simulation strategies.

## 3. Quick Links
*   [Project README](../README.md): Main project entry point.
*   [Viva Guide](../VIVA_GUIDE.md): Q&A preparation for defense.
*   [Presentation](../Presentation.md): Slides content.

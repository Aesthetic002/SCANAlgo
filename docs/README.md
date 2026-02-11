# Documentation Index

Welcome to the documentation for the **Smart Elevator Controller Project**.

## Documentation Map

### [System Architecture](./SYSTEM_ARCHITECTURE.md)
- High-level overview of the three-domain architecture (Verilog ↔ Python ↔ Browser)
- Block diagrams and data flow
- Explanation of the hardware-software bridge

### [Hardware Design](./HARDWARE_DESIGN.md)
- Core Verilog module (`smart_elevator.v`) breakdown
- FSM state machine diagrams and transition logic
- Pin definitions and signal descriptions
- Cycle-accurate timing parameters
- Safety systems (Emergency, Overload, Obstruction)

### [Algorithms](./ALGORITHMS.md)
- SCAN vs FCFS comparative analysis
- Detailed pseudocode and explanation
- Efficiency metrics and benchmarks

### [Frontend Documentation](./FRONTEND_DOCUMENTATION.md)
- Web simulation architecture
- JavaScript classes (`BaseElevator`, `ScanElevator`, `RemoteScanElevator`, `FcfsElevator`)
- Landing page structure
- WebSocket communication and fallback logic

### [Testing and Verification](./TESTING_AND_VERIFICATION.md)
- Testbenches: `tb_smart_elevator.v` and `tb_interactive.v`
- 10 automated test scenarios
- How to run simulations on Windows/Linux

### [Running Verilog Backend](./RUNNING_VERILOG_BACKEND.md)
- Prerequisites (Icarus Verilog, Python, websockets)
- Step-by-step guide to run the backend
- Troubleshooting common issues

### [Verilog-to-Web Guide](./VERILOG_TO_WEB_GUIDE.md)
- How the Python WebSocket server bridges Verilog to the browser
- Communication protocol (JSON messages)
- Fallback mechanism for static deployment

## Quick Links
- [Project README](../README.md) — Main project entry point
- [GitHub Repository](https://github.com/Aesthetic002/SCANAlgo)
- [Viva Guide](../VIVA_GUIDE.md) — Q&A preparation
- [Presentation](../Presentation.md) — Slide content

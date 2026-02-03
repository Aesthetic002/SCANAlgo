# Smart Elevator Controller Project Report

**Ultra-Advanced Elevator Controller using SCAN Scheduling Algorithm**

---

## Table of Contents
1. [Executive Summary](#executive-summary)
2. [Project Overview](#project-overview)
3. [Architecture & Design](#architecture--design)
4. [SCAN Scheduling Algorithm](#scan-scheduling-algorithm)
5. [Implementation Details](#implementation-details)
6. [Safety Features](#safety-features)
7. [Verification & Testing](#verification--testing)
8. [Simulation Results](#simulation-results)
9. [Waveform Analysis](#waveform-analysis)
10. [Conclusion](#conclusion)

---

## Executive Summary

This project implements an **industry-grade 8-floor smart elevator controller** using Verilog HDL. The design incorporates the **SCAN (Elevator) scheduling algorithm**, hierarchical Finite State Machine (FSM) architecture, comprehensive safety features, and realistic timing models. The system operates in a pure software simulation environment using Icarus Verilog and GTKWave for verification.

**Key Innovation**: Unlike simple elevator designs, this controller implements intelligent request scheduling similar to disk scheduling algorithms, optimizing travel efficiency while maintaining safety-critical operation.

---

## Project Overview

### Objectives
- Design a smart elevator controller for 8 floors (0-7)
- Implement SCAN scheduling algorithm for efficient request handling
- Create hierarchical FSM with safety priority
- Include realistic timing models for movement and door operations
- Implement comprehensive safety features (emergency, overload, obstruction)
- Develop self-checking testbench for verification

### Specifications

| Parameter | Specification |
|-----------|--------------|
| Number of Floors | 8 (Floor 0 to Floor 7) |
| Scheduling Algorithm | SCAN (Elevator Algorithm) |
| FSM Architecture | Hierarchical with Safety Priority |
| Clock Frequency | 100 MHz (10ns period) |
| Floor Travel Time | 50 clock cycles (500ns) |
| Door Open Time | 30 clock cycles (300ns) |
| Door Wait Time | 20 clock cycles (200ns) |

---

## Architecture & Design

### Block Diagram

```
┌─────────────────────────────────────────────────────┐
│           Smart Elevator Controller                 │
├─────────────────────────────────────────────────────┤
│                                                     │
│  ┌──────────────┐         ┌──────────────┐        │
│  │   Request    │         │   Safety     │        │
│  │   Latching   │────────▶│   Priority   │        │
│  │   Logic      │         │   Handler    │        │
│  └──────────────┘         └──────┬───────┘        │
│         │                        │                 │
│         ▼                        ▼                 │
│  ┌──────────────────────────────────┐             │
│  │    Hierarchical FSM Controller    │             │
│  │  - IDLE      - EMERGENCY          │             │
│  │  - MOVE      - OVERLOAD           │             │
│  │  - ARRIVE    - DOOR_OPEN          │             │
│  │  - DOOR_WAIT                      │             │
│  └────────┬─────────────────┬────────┘             │
│           │                 │                       │
│           ▼                 ▼                       │
│  ┌──────────────┐   ┌──────────────┐              │
│  │ SCAN Algo    │   │   Timing     │              │
│  │ Direction    │   │   Control    │              │
│  │ Logic        │   │   Counters   │              │
│  └──────────────┘   └──────────────┘              │
│           │                 │                       │
│           ▼                 ▼                       │
│  ┌─────────────────────────────────┐               │
│  │      Output Control Logic       │               │
│  │  - Motor    - Door    - Alarm   │               │
│  └─────────────────────────────────┘               │
│                                                     │
└─────────────────────────────────────────────────────┘
```

### Input/Output Interface

**Inputs:**
- `clk` - System clock (100 MHz)
- `reset` - Asynchronous reset (active high)
- `req[7:0]` - Floor request buttons (one-hot encoded)
- `emergency` - Emergency stop signal
- `overload` - Weight overload detector
- `door_sensor` - Door obstruction sensor

**Outputs:**
- `current_floor[2:0]` - Current floor number (0-7)
- `direction` - Travel direction (1=UP, 0=DOWN)
- `motor_enable` - Motor control signal
- `door_open` - Door state indicator
- `alarm` - Emergency/overload alarm

---

## SCAN Scheduling Algorithm

### Algorithm Overview

The SCAN algorithm (also called the Elevator Algorithm) is borrowed from disk scheduling. It operates on a simple principle:

**"Continue in the current direction until no more requests exist in that direction, then reverse."**

### Key Principles

1. **Unidirectional Service**: Serve all requests in the current direction
2. **Direction Reversal**: Only reverse when no requests remain ahead
3. **Efficiency**: Minimizes total travel distance
4. **Fairness**: Prevents starvation (all requests eventually served)

### Algorithm Implementation

```verilog
// Pseudocode for SCAN Algorithm
if (direction == UP) {
    if (has_requests_above(current_floor)) {
        continue_upward();
    } else if (has_requests_below(current_floor)) {
        reverse_to_down();
    } else {
        go_idle();
    }
}
```

### Example Scenario

```
Initial State: Floor 0, Direction = UP
Requests: Floor 2, 5, 7, 3

Execution Order:
1. Floor 0 → Floor 2 (serve)
2. Floor 2 → Floor 3 (serve)
3. Floor 3 → Floor 5 (serve)
4. Floor 5 → Floor 7 (serve)
5. IDLE (no more requests upward)

If Floor 1 requested while at Floor 3:
- Continue to Floor 5, 7 first
- Then reverse and serve Floor 1
```

### Search Functions

```verilog
function has_request_above;
    input [2:0] floor;
    input [7:0] requests;
    integer i;
    begin
        has_request_above = 0;
        for (i = floor + 1; i < 8; i = i + 1)
            if (requests[i])
                has_request_above = 1;
    end
endfunction

function has_request_below;
    input [2:0] floor;
    input [7:0] requests;
    integer i;
    begin
        has_request_below = 0;
        for (i = 0; i < floor; i = i + 1)
            if (requests[i])
                has_request_below = 1;
    end
endfunction
```

---

## Implementation Details

### Hierarchical FSM

The controller uses a 7-state hierarchical FSM:

```
┌─────────────────────────────────────────┐
│         SAFETY PRIORITY LAYER           │
│  ┌──────────┐         ┌──────────┐     │
│  │EMERGENCY │         │ OVERLOAD │     │
│  └────┬─────┘         └────┬─────┘     │
│       │                    │            │
│       └────────┬───────────┘            │
└────────────────┼────────────────────────┘
                 ▼
┌─────────────────────────────────────────┐
│      NORMAL OPERATION LAYER             │
│                                         │
│  ┌──────┐    ┌──────┐    ┌────────┐   │
│  │ IDLE │───▶│ MOVE │───▶│ ARRIVE │   │
│  └───▲──┘    └──────┘    └───┬────┘   │
│      │                        │         │
│      │    ┌──────────┐  ┌─────▼─────┐ │
│      └────│DOOR_WAIT │◀─│ DOOR_OPEN │ │
│           └──────────┘  └───────────┘ │
└─────────────────────────────────────────┘
```

**State Descriptions:**

| State | Description | Entry Condition | Exit Condition |
|-------|-------------|----------------|----------------|
| **IDLE** | Waiting for requests | No pending requests | Request received |
| **MOVE** | Traveling to next floor | Target floor determined | Reached target floor |
| **ARRIVE** | Reached target floor | Travel timer expired | Check if stop needed |
| **DOOR_OPEN** | Door opening/open | At requested floor | Door timer expired |
| **DOOR_WAIT** | Waiting before closing | Door open timer done | No obstruction + timer |
| **EMERGENCY** | Emergency stop | Emergency signal | Emergency cleared |
| **OVERLOAD** | Overload condition | Overload signal | Overload cleared |

### Request Latching

Requests are latched to ensure no request is lost:

```verilog
always @(posedge clk or posedge reset) begin
    if (reset)
        pending_requests <= 8'b0;
    else begin
        // Set bit when request arrives
        pending_requests <= pending_requests | req;
        
        // Clear bit when floor is served
        if (state == DOOR_OPEN)
            pending_requests[current_floor] <= 1'b0;
    end
end
```

### Timing Control

**Floor Travel Timing:**
```verilog
// 50 clock cycles per floor
if (travel_counter >= FLOOR_TRAVEL_TIME) begin
    travel_counter <= 0;
    current_floor <= current_floor + (direction ? 1 : -1);
end
```

**Door Timing:**
```verilog
// Door stays open for 30 cycles
if (door_timer >= DOOR_OPEN_TIME)
    next_state <= DOOR_WAIT;
```

---

## Safety Features

### 1. Emergency Stop (Highest Priority)

**Behavior:**
- Immediately stops motor
- Activates alarm
- Ignores all other inputs
- Clears when emergency signal deasserted

**Implementation:**
```verilog
if (emergency) begin
    next_state = EMERGENCY;
    motor_enable = 0;
    alarm = 1;
end
```

### 2. Overload Detection

**Behavior:**
- Prevents movement when overloaded
- Keeps door open
- Activates alarm
- Clears when weight reduced

### 3. Door Obstruction

**Behavior:**
- Detects obstruction via door_sensor
- Reopens door if closing
- Resets door timer
- Prevents passenger injury

**Implementation:**
```verilog
DOOR_WAIT: begin
    if (door_sensor) begin
        next_state = DOOR_OPEN;  // Reopen door
        door_timer <= 0;         // Reset timer
    end
end
```

### Safety Priority Hierarchy

```
1. EMERGENCY (Highest)
   ↓
2. OVERLOAD
   ↓
3. DOOR OBSTRUCTION
   ↓
4. NORMAL OPERATION (Lowest)
```

---

## Verification & Testing

### Testbench Architecture

The self-checking testbench includes:

1. **Clock Generation** - 100 MHz system clock
2. **Reset Sequencing** - Proper initialization
3. **Test Helper Tasks** - Reusable test functions
4. **Automatic Checking** - Pass/fail verification
5. **State Monitoring** - Real-time state display
6. **VCD Dump** - Waveform generation

### Test Coverage

| Test # | Test Case | Purpose |
|--------|-----------|---------|
| 1 | Reset & Initialization | Verify proper startup |
| 2 | Single Floor Request | Basic upward movement |
| 3 | Multiple Upward Requests | SCAN algorithm (same direction) |
| 4 | Direction Reversal | SCAN reversal logic |
| 5 | Mixed Requests | Complete SCAN cycle |
| 6 | Emergency During Motion | Safety interrupt |
| 7 | Door Obstruction | Safety handling |
| 8 | Overload Detection | Weight safety |
| 9 | Current Floor Request | Edge case handling |
| 10 | Stress Test | Multiple simultaneous requests |

### Test Results Example

```
==============================================================================
   Smart Elevator Controller - Comprehensive Testbench
==============================================================================
Testing: SCAN Algorithm, Safety Features, Timing, Direction Reversal
==============================================================================

[PASS] Test 1: After reset, elevator at floor 0
[PASS] Test 2: After reset, all outputs inactive
[PASS] Test 3: Motor enabled when moving to floor 3
[PASS] Test 4: Elevator reached floor 3
...
==============================================================================
   Test Summary
==============================================================================
Total Tests: 25
Passed:      25
Failed:      0
==============================================================================

*** ALL TESTS PASSED! *** ✓
```

---

## Simulation Results

### How to Run Simulation

**Windows (PowerShell):**
```powershell
.\run_sim.ps1
```

**Linux/Mac:**
```bash
chmod +x run_sim.sh
./run_sim.sh
```

**Manual Compilation:**
```bash
iverilog -o elevator_sim smart_elevator.v tb_smart_elevator.v
vvp elevator_sim
gtkwave elevator_waveform.vcd
```

### Expected Output

```
====================================================================
  Smart Elevator Controller - Simulation Script (Windows)
====================================================================

[1/3] Compiling Verilog files...
✓ Compilation successful

[2/3] Running simulation...

--- TEST 1: Reset and Initialization ---
[PASS] Test 1: After reset, elevator at floor 0
[PASS] Test 2: After reset, all outputs inactive

--- TEST 2: Single Floor Request (Upward) ---
Requesting floor 3...
[10 ns] State: IDLE -> MOVE | Floor: 0 | Dir: UP | Motor: 1
[520 ns] State: MOVE -> ARRIVE | Floor: 1 | Dir: UP | Motor: 0
...

✓ Simulation completed

[3/3] Waveform generated: elevator_waveform.vcd
====================================================================
```

---

## Waveform Analysis

### Key Signals to Observe

**1. State Transitions**
- Observe FSM state changes
- Verify proper sequencing: IDLE → MOVE → ARRIVE → DOOR_OPEN → DOOR_WAIT

**2. SCAN Algorithm**
- Watch direction signal
- Verify direction reversal only after all requests served
- Confirm sequential floor service in same direction

**3. Timing**
- Floor travel: 50 clock cycles between floors
- Door open: 30 clock cycles
- Door wait: 20 clock cycles

**4. Safety Features**
- Emergency immediately stops motor
- Overload prevents movement
- Door obstruction reopens door

### GTKWave Tips

1. Add signals in this order for clarity:
   ```
   - clk
   - reset
   - req[7:0]
   - current_floor[2:0]
   - direction
   - state[3:0]
   - motor_enable
   - door_open
   - alarm
   ```

2. Use color coding:
   - Red: Safety signals (emergency, overload, alarm)
   - Green: Normal operation (motor_enable)
   - Blue: State signals

3. Add markers at state transitions

---

## Conclusion

### Project Achievements

✅ **SCAN Algorithm**: Successfully implemented efficient request scheduling  
✅ **Hierarchical FSM**: Clean separation of safety and normal operation  
✅ **Safety Features**: Emergency, overload, and obstruction handling  
✅ **Realistic Timing**: Accurate floor travel and door operation models  
✅ **Comprehensive Testing**: 10 test scenarios, 25+ individual checks  
✅ **Industry-Grade**: Production-quality RTL design patterns  

### Key Learnings

1. **Algorithmic Thinking in Hardware**: SCAN algorithm shows how software algorithms translate to hardware
2. **FSM Design**: Hierarchical states enable clean safety priority handling
3. **Verification**: Self-checking testbenches catch bugs early
4. **Timing**: Real-world systems need accurate timing models

### Real-World Applications

- **Building Elevators**: Actual elevator controllers use similar algorithms
- **Disk Scheduling**: SCAN is widely used in hard disk controllers
- **Resource Management**: Principles apply to any queued resource system
- **Safety-Critical Systems**: Priority-based FSM used in automotive, medical devices

### Future Enhancements

- [ ] Multi-elevator coordination
- [ ] Power optimization (sleep states)
- [ ] Predictive scheduling (AI/ML)
- [ ] FPGA implementation with physical I/O
- [ ] Energy regeneration during descent
- [ ] Advanced diagnostics and logging

---

## File Structure

```
ADLD_EL/
├── smart_elevator.v           # RTL design (main module)
├── tb_smart_elevator.v        # Self-checking testbench
├── run_sim.sh                 # Linux/Mac simulation script
├── run_sim.ps1                # Windows simulation script
├── README.md                  # This document
├── VIVA_GUIDE.md              # Viva preparation
└── Presentation.md            # PowerPoint content
```

---

## References

1. **SCAN Algorithm**: Denning, P. J. (1967). "Effects of scheduling on file memory operations"
2. **FSM Design**: Brown, S., Vranesic, Z. (2014). "Fundamentals of Digital Logic with Verilog Design"
3. **Verilog HDL**: Palnitkar, S. (2003). "Verilog HDL: A Guide to Digital Design and Synthesis"
4. **Safety-Critical Systems**: Storey, N. (1996). "Safety-Critical Computer Systems"

---

## Appendix A: Complete Code Listings

See separate files:
- `smart_elevator.v` - Main RTL design
- `tb_smart_elevator.v` - Testbench with all test cases

---

## Appendix B: Simulation Instructions

### Installing Icarus Verilog

**Windows:**
1. Download from: http://bleyer.org/icarus/
2. Run installer
3. Add to PATH

**Linux:**
```bash
sudo apt-get install iverilog gtkwave
```

**Mac:**
```bash
brew install icarus-verilog gtkwave
```

### Online Alternatives

If you cannot install locally:
- **EDA Playground**: https://www.edaplayground.com/
- **Icarus Verilog Online**: https://www.tutorialspoint.com/compile_verilog_online.php

---

**Project Completion Date**: January 18, 2026  
**Author**: Digital IC Design Team  
**Course**: Advanced Digital Logic Design  

---

*"This project demonstrates that hardware design is not just about gates and wires—it's about algorithms, architecture, and solving real-world problems with silicon."*

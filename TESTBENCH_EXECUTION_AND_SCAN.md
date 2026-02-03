# Testbench Execution & SCAN Algorithm — Detailed Explanation

Date: 2026-01-19

This document explains how `tb_smart_elevator.v` executes its tests (sequence, synchronization, self-checking) and exactly how the SCAN scheduling algorithm is implemented and used by the RTL (`smart_elevator.v`).

## 1. Testbench Overview

Files:
- `tb_smart_elevator.v` — self-checking testbench (drives inputs, checks outputs, generates VCD)
- `smart_elevator.v` — DUT (device under test)

Key testbench elements:
- Clock generator: `initial begin clk = 0; forever #5 clk = ~clk; end` produces a 100 MHz clock (10 ns period).
- Reset task: `reset_system()` asserts `reset` for a few cycles and initializes stimulus variables.
- Waveform dump: `$dumpfile("elevator_waveform.vcd"); $dumpvars(0, tb_smart_elevator);` produces the VCD used in EPWave/GTKWAVE.

### Synchronization primitives
- `@(posedge clk)` — primary synchronization primitive. Most tasks use `repeat` with `@(posedge clk)` to advance simulation by cycles.
- `wait_cycles(n)` — helper task that does `repeat(n) @(posedge clk)`.
- `wait_for_floor(target, max_cycles)` — polls `current_floor` each clock until target floor or timeout.
- `wait_for_door_close()` — loops while `door_open` is true to wait for door close.

### Self-checking mechanism
- `check_condition(condition, "message")` prints `[PASS]` or `[FAIL]` and increments counters (`pass_count`/`fail_count`).
- Tests call `check_condition` after appropriate synchronization to confirm DUT behavior.

### Test sequence model
- The `initial` block runs tests in order (Test 1 → Test 10). Each test:
  - Calls `reset_system()` to start from a known state (unless intentionally left running for continuity).
  - Applies stimuli using `request_floor(floor)` which pulses `req[floor]` for one clock.
  - Waits using `wait_cycles`, `wait_for_floor`, or `wait_for_door_close` to let the DUT respond.
  - Asserts expected outputs with `check_condition`.

## 2. How a Single Test Executes (example: Door Obstruction)
1. `reset_system()` clears signals and pending requests.
2. Test issues `request_floor(2)` — this pulses `req[2]` for one clock.
3. Testbench waits for `wait_for_floor(2, 5000)` which polls until `dut.current_floor == 2`.
4. When arrival is detected, `check_condition(door_open == 1, ...)` confirms door opening.
5. Testbench waits an appropriate number of cycles to target `DOOR_WAIT` (timing depends on `DOOR_OPEN_TIME`).
6. It asserts `door_sensor = 1` for a few cycles to simulate an obstruction.
7. After more waits, it calls `check_condition(door_open == 1, ...)` to verify door was reopened / kept open.

Notes:
- Precise timing matters: the test must assert `door_sensor` while DUT is in `DOOR_WAIT` (or within the small window the design observes it). The testbench uses clocks and `wait_cycles` to line this up.
- The VCD waveform helps verify exact signal alignment.

## 3. SCAN Scheduling Algorithm — Concept
- SCAN (a.k.a. elevator algorithm) serves requests in current travel direction until no more exist, then reverses.
- It reduces total travel and prevents starvation better than pure FIFO in multi-floor systems.

## 4. SCAN Implementation in `smart_elevator.v`
Key pieces:
- `pending_requests` (8-bit): latched OR of input `req` bits. Holds outstanding floor requests.
- `has_request_above(floor, requests)`: returns true if any request exists at indexes > floor.
- `has_request_below(floor, requests)`: returns true if any request exists at indexes < floor.
- `find_next_request(floor, direction, requests)`: scans upward (floor+1..7) or downward (floor-1..0) and returns the next floor index to visit.
- `direction` register: current travel direction (UP/DOWN). Updated in `IDLE`/`ARRIVE` states using `has_request_above`/`has_request_below`.

Typical decision flow:
1. On `IDLE` or `ARRIVE`, if there are pending requests and a request exists at `current_floor`, go to `DOOR_OPEN`.
2. If not, set `next_state = MOVE` and `target_floor = find_next_request(...)`.
3. `MOVE` increments `travel_counter`; when `travel_counter >= FLOOR_TRAVEL_TIME`, `current_floor` increments/decrements by 1 (depending on direction). `target_floor` is recalculated each time.
4. When `pending_requests` in current direction are exhausted, `has_request_above/below` will cause `direction` to flip on the next opportunity.

## 5. Example: SCAN Step-by-step
Suppose pending requests: floors {2,5,7} and `current_floor = 0`, `direction = UP`.
- `find_next_request(0, UP)` returns 2 → `target_floor = 2`.
- MOVE→ARRIVE as elevator steps floor-by-floor: 1 then 2.
- At arrival floor 2, `pending_requests[2]` cleared and door opens.
- After door cycles, `has_request_above(2)` true, so direction remains UP and `find_next_request(2,UP)` returns 5.
- Repeat until 7; after servicing 7 `has_request_above(7)` false but `has_request_below(7)` true, so direction flips to DOWN.

## 6. Where to Change Behavior
- Timing: change `FLOOR_TRAVEL_TIME`, `DOOR_OPEN_TIME`, `DOOR_WAIT_TIME` at top of `smart_elevator.v`.
- Request policy: `pending_requests` latching is simple OR-latch; you can change to edge-detected pulses if necessary.

## 7. Tips for Debugging/Test Development
- Always use `$dumpvars(0, tb_smart_elevator)` and EPWave/GTKWAVE to inspect `dut.*` signals.
- When tests fail, locate the CHECK print in console to see which test number and message failed.
- Use `wait_for_floor()` and `wait_for_door_close()` to make tests robust against timing variations.

## 8. References in Code
- Testbench tasks: `reset_system`, `wait_cycles`, `check_condition`, `request_floor`, `wait_for_floor`, `wait_for_door_close` in `tb_smart_elevator.v`.
- SCAN helpers: `has_request_above`, `has_request_below`, `find_next_request` in `smart_elevator.v`.

---

File created: `TESTBENCH_EXECUTION_AND_SCAN.md`


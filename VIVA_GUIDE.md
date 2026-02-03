# Viva Preparation Guide - Smart Elevator Controller

**Complete Q&A Reference for Project Defense**

---

## 🎯 The Golden One-Liner

**Q: Explain your project in one sentence.**

**A:** *"This project implements a smart elevator controller using the SCAN scheduling algorithm, combining algorithmic scheduling with hardware-grade FSM design and safety-critical control logic."*

---

## Part 1: Project Understanding (20 Questions)

### Q1: What is the SCAN algorithm?
**A:** SCAN is an elevator scheduling algorithm that services all requests in the current direction before reversing. It's similar to how a disk head moves in hard drives. The elevator continues moving in one direction (UP or DOWN) until no more requests exist in that direction, then reverses.

**Key Points:**
- Borrowed from disk I/O scheduling
- Also called "Elevator Algorithm"
- Ensures fairness (no starvation)
- Optimizes total travel distance

---

### Q2: Why did you choose SCAN over FCFS (First Come First Serve)?
**A:** SCAN is more efficient than FCFS because:
1. **Reduces total travel distance** - Serves all nearby floors in one pass
2. **Prevents excessive movement** - Doesn't backtrack unnecessarily
3. **Fair to all requests** - No starvation, guaranteed service
4. **Energy efficient** - Minimizes motor start/stop cycles
5. **Industry standard** - Used in real elevators worldwide

**Example:** If at floor 2 going UP with requests at floors 5 and 1, SCAN serves 5 first, then reverses to 1. FCFS might go 5→1→5 wastefully.

---

### Q3: Explain your FSM states.
**A:** We have 7 states in a hierarchical architecture:

**Normal Operation Layer:**
- **IDLE** - Waiting for requests, no movement
- **MOVE** - Traveling between floors, motor active
- **ARRIVE** - Just reached a floor, checking if stop needed
- **DOOR_OPEN** - Door opening/open for passengers
- **DOOR_WAIT** - Waiting before closing, checking for obstructions

**Safety Priority Layer:**
- **EMERGENCY** - Emergency stop, highest priority
- **OVERLOAD** - Weight overload, prevents movement

---

### Q4: What is hierarchical FSM?
**A:** A hierarchical FSM has multiple layers of states with priority levels:

**Layer 1 (Highest Priority):** Safety states (EMERGENCY, OVERLOAD)
**Layer 2 (Normal Priority):** Operational states (IDLE, MOVE, etc.)

**Benefit:** Safety can interrupt normal operation at any time. If emergency occurs while in MOVE state, system immediately transitions to EMERGENCY regardless of other conditions.

---

### Q5: How do you prevent request loss?
**A:** Using **request latching** with OR logic:

```verilog
pending_requests <= pending_requests | req;
```

- New requests are OR'ed with existing ones
- Requests stay latched until served
- When elevator arrives at a floor, that bit is cleared
- No request is ever lost, even during movement

---

### Q6: Explain the direction reversal logic.
**A:** Direction reversal happens in the ARRIVE state using search functions:

```verilog
if (direction == UP) {
    if (has_request_above(current_floor))
        continue UP;
    else if (has_request_below(current_floor))
        reverse to DOWN;
    else
        go IDLE;
}
```

**Key:** Only reverse when NO requests remain in current direction.

---

### Q7: What are the timing parameters and why?
**A:** 
- **FLOOR_TRAVEL_TIME = 50 cycles (500ns)** - Realistic motor acceleration/travel time
- **DOOR_OPEN_TIME = 30 cycles (300ns)** - Allow passengers to enter/exit
- **DOOR_WAIT_TIME = 20 cycles (200ns)** - Final check before closing

These create realistic behavior. In real systems, these would be in seconds, but we scale down for simulation speed while maintaining relative proportions.

---

### Q8: How does emergency stop work?
**A:** Emergency has **highest priority** in the FSM:

```verilog
if (emergency)
    next_state = EMERGENCY;
```

**Actions:**
1. Immediately transitions to EMERGENCY state
2. Disables motor (`motor_enable = 0`)
3. Activates alarm (`alarm = 1`)
4. Ignores all other inputs
5. Only exits when emergency signal cleared

**Real-world:** Like pulling the emergency stop button in an elevator.

---

### Q9: Explain door obstruction handling.
**A:** When door_sensor detects obstruction during DOOR_WAIT:

```verilog
if (state == DOOR_WAIT && door_sensor) {
    next_state = DOOR_OPEN;  // Reopen door
    door_timer = 0;          // Reset timer
}
```

**Behavior:**
- Door sensor detects object (IR beam or pressure)
- Door immediately reopens
- Timer resets to give full open time again
- Prevents injury to passengers

---

### Q10: What is the difference between MOVE and ARRIVE states?
**A:** 

**MOVE State:**
- Motor is active
- Travel timer counting
- Moving between floors
- Updates current_floor when timer expires

**ARRIVE State:**
- Motor is off
- Just reached target floor
- Decides: open door or continue moving?
- Transition point between movement and service

**Why separate?** Clean separation of concerns - movement logic vs. decision logic.

---

### Q11: How do you handle multiple requests at once?
**A:** Request latching captures all requests:

```verilog
pending_requests[7:0] = 8'b00010110  // Floors 1, 2, 4 requested
```

SCAN algorithm then serves them in order based on:
1. Current direction
2. Current floor position
3. Target floor calculation

**Example:** At floor 0, going UP, with requests 1,2,4:
Serves in order: 1 → 2 → 4 (sequential upward)

---

### Q12: What happens if request comes for current floor?
**A:** Special case handling:

```verilog
if (pending_requests[current_floor]) {
    next_state = DOOR_OPEN;  // Open immediately
}
```

- No movement needed
- Directly open door
- Motor stays off
- Serves request instantly

**Optimization:** Why move if already there?

---

### Q13: How is overload different from emergency?
**A:** 

| Aspect | Emergency | Overload |
|--------|-----------|----------|
| **Priority** | Highest | High |
| **Motor** | Stops immediately | Prevented from starting |
| **Door** | Stays as-is | Stays open |
| **Clearance** | Manual | Automatic (when weight reduced) |
| **Next State** | Returns to IDLE | Returns to DOOR_OPEN |

**Use case:** Emergency = fire alarm, Overload = too many people

---

### Q14: Explain the search functions.
**A:** Three helper functions implement SCAN:

**1. has_request_above(floor, requests)**
```verilog
for (i = floor + 1; i < 8; i++)
    if (requests[i]) return 1;
```
Returns true if any floor above has request.

**2. has_request_below(floor, requests)**
```verilog
for (i = 0; i < floor; i++)
    if (requests[i]) return 1;
```
Returns true if any floor below has request.

**3. find_next_request(floor, direction, requests)**
Searches in specified direction and returns next floor to visit.

---

### Q15: What clock frequency did you use and why?
**A:** **100 MHz (10ns period)**

**Reasoning:**
- Common FPGA frequency
- Fast enough for real-time control
- Slow enough for easy debugging
- Allows reasonable timing parameters

**In real system:** Might use 50 MHz or lower to save power, or higher for more precise timing control.

---

### Q16: How did you verify the SCAN algorithm works?
**A:** Test 5 in testbench specifically tests SCAN:

1. Request floors 1, 4, 6 from floor 0
2. While at floor 1, request floor 2 (above) and 0 (below)
3. **Expected:** Serve 2, 4, 6 first (continue UP)
4. **Then:** Reverse and serve 0
5. **Verified:** All served in SCAN order

**Result:** Test passed, confirming SCAN logic correct.

---

### Q17: What is the purpose of the ARRIVE state?
**A:** ARRIVE is a **decision state** between movement and service:

**Checks:**
1. Did we reach the target floor?
2. Is there a request at this floor?
3. Should we open door or keep moving?

**Why needed?** Elevator might pass through floors without stopping if no request there. ARRIVE decides stop vs. continue.

**Example:** Going floor 1→5, might not stop at 2,3,4 if no requests.

---

### Q18: How does your design prevent starvation?
**A:** SCAN algorithm inherently prevents starvation:

1. **Request latching** - All requests captured and held
2. **Guaranteed service** - Every request eventually in the direction of travel
3. **Direction reversal** - When reaches end, reverses and serves waiting requests
4. **No priority** - All floors equal priority (FCFS within same direction)

**Proof:** If floor 1 requested, elevator will eventually go DOWN (or UP from 0) and serve it. Maximum wait = time to serve all requests in both directions.

---

### Q19: What happens during a power reset?
**A:** Reset initializes all registers:

```verilog
if (reset) {
    state <= IDLE;
    current_floor <= 0;
    direction <= UP;
    pending_requests <= 0;
    motor_enable <= 0;
    door_open <= 0;
    alarm <= 0;
}
```

**Behavior:** Elevator returns to ground floor (0), all requests cleared, system ready for operation.

**Real elevator:** Has battery backup to complete current trip, then goes to ground floor.

---

### Q20: Why is this design considered "industry-grade"?
**A:** 

✅ **Proven algorithm** - SCAN used in production systems  
✅ **Safety-first** - Hierarchical priority, multiple protection layers  
✅ **Comprehensive testing** - 10 test scenarios, automated verification  
✅ **Clean architecture** - Modular, maintainable, well-documented  
✅ **Error handling** - Covers edge cases, fault tolerance  
✅ **Timing model** - Realistic delays, synchronization  
✅ **Code quality** - Comments, naming conventions, parameterization  

**vs. Student project:** Basic up/down control, no scheduling, minimal safety, no verification.

---

## Part 2: Technical Deep Dive (15 Questions)

### Q21: Explain the difference between combinational and sequential logic in your design.

**A:** 

**Sequential (Synchronous to clk):**
- State register updates
- Floor counter
- Request latching
- Timer counters
- All use `always @(posedge clk)`

**Combinational:**
- Next state logic
- Search functions
- Output generation (motor_enable, door_open)
- Uses `always @(*)` or `function`

**Why both needed?** Sequential stores state, combinational computes next action.

---

### Q22: What is the role of the travel_counter?

**A:** `travel_counter` implements realistic floor-to-floor travel timing:

```verilog
always @(posedge clk) begin
    if (state == MOVE) {
        travel_counter <= travel_counter + 1;
        if (travel_counter >= FLOOR_TRAVEL_TIME) {
            travel_counter <= 0;
            current_floor <= current_floor + (direction ? 1 : -1);
        }
    }
end
```

**Function:**
- Counts clock cycles during movement
- When reaches 50 (FLOOR_TRAVEL_TIME), move one floor
- Simulates motor acceleration and travel time
- Prevents instant teleportation between floors

---

### Q23: How would you modify this for 16 floors?

**A:** 

**Changes needed:**

1. **Signals:**
```verilog
input wire [15:0] req;         // Was [7:0]
output reg [3:0] current_floor; // Was [2:0]
reg [15:0] pending_requests;   // Was [7:0]
```

2. **Search functions:**
```verilog
for (i = floor + 1; i < 16; i++)  // Was i < 8
```

3. **Constants:** No change to FLOOR_TRAVEL_TIME unless building taller

4. **Logic:** No change to FSM or SCAN algorithm!

**Key point:** Algorithm scales easily, just change bit widths.

---

### Q24: What is the difference between blocking and non-blocking assignments?

**A:** 

**Non-blocking (<=)** - Used in sequential logic:
```verilog
always @(posedge clk) begin
    state <= next_state;  // Parallel update
end
```
- Updates happen simultaneously at clock edge
- Models hardware flip-flops
- **Use in:** Sequential always blocks

**Blocking (=)** - Used in combinational logic:
```verilog
always @(*) begin
    next_state = IDLE;  // Immediate assignment
end
```
- Executes sequentially like software
- Models combinational gates
- **Use in:** Combinational always blocks, functions

**In our design:** Non-blocking for state/floor/timers, blocking for next_state calculation.

---

### Q25: How does the testbench verify timing?

**A:** 

**Method 1:** Wait for expected time
```verilog
wait_for_floor(3, 5000);  // Max 5000 cycles
```
If timeout, test fails.

**Method 2:** Count cycles
```verilog
repeat(50) @(posedge clk);
check_condition(motor_enable == 1);
```

**Method 3:** Monitor timers
```verilog
if (dut.travel_counter != 50)
    error();
```

**Verification:** Tests pass only if timing meets spec (50 cycles/floor, 30 cycles door open).

---

### Q26: What is the purpose of the target_floor register?

**A:** `target_floor` stores the next destination:

```verilog
target_floor <= find_next_request(current_floor, direction, pending_requests);
```

**Uses:**
1. **Comparison:** Know when to stop (`current_floor == target_floor`)
2. **Look-ahead:** Optimize motor control (pre-deceleration)
3. **Debugging:** Visibility into scheduler decision
4. **Future:** Could add display showing "Going to floor X"

**Without it:** Would need to recalculate next floor every cycle (wasteful).

---

### Q27: How would you add a display showing current floor?

**A:** 

**Hardware (FPGA):**
```verilog
output reg [6:0] seven_seg;  // 7-segment display

always @(*) begin
    case (current_floor)
        3'd0: seven_seg = 7'b0111111;  // Display '0'
        3'd1: seven_seg = 7'b0000110;  // Display '1'
        // ... etc for floors 2-7
    endcase
end
```

**Software (Simulation):**
```verilog
always @(current_floor) begin
    $display("Floor: %0d", current_floor);
end
```

Already have `current_floor[2:0]` output - just need decoder!

---

### Q28: Explain the door_timer logic.

**A:** 

**In DOOR_OPEN:**
```verilog
door_timer <= door_timer + 1;
if (door_timer >= DOOR_OPEN_TIME)
    next_state <= DOOR_WAIT;
```
Counts up, door stays open for 30 cycles.

**In DOOR_WAIT:**
```verilog
if (door_sensor) {
    door_timer <= 0;  // Reset if obstruction
    next_state <= DOOR_OPEN;
} else {
    door_timer <= door_timer + 1;
    if (door_timer >= DOOR_WAIT_TIME)
        next_state <= MOVE or IDLE;
}
```

**Purpose:** Ensures door open long enough for passengers, handles obstructions.

---

### Q29: What is the worst-case wait time for a request?

**A:** 

**Scenario:** Request floor 0 when elevator at floor 0 going UP, with requests at all other floors.

**Calculation:**
1. Travel UP: 0→1→2→3→4→5→6→7
   - 7 floors × 50 cycles = 350 cycles travel
   - 7 stops × (30+20) cycles = 350 cycles door
   - Subtotal: 700 cycles

2. Reverse and travel DOWN: 7→0
   - 7 floors × 50 cycles = 350 cycles travel
   - 1 stop × 50 cycles = 50 cycles door
   - Subtotal: 400 cycles

**Total worst case: ~1100 cycles = 11 μs** (at 100 MHz)

**Real elevator:** ~5-10 minutes worst case.

---

### Q30: How does your design handle simultaneous emergency and overload?

**A:** **Priority hierarchy** in next state logic:

```verilog
if (emergency)
    next_state = EMERGENCY;  // Highest priority
else if (state == ... && overload)
    next_state = OVERLOAD;
```

**Result:** Emergency takes precedence.

**Reasoning:** 
- Emergency = building evacuation (fire, earthquake)
- Overload = just too heavy
- Emergency more critical → handle first

**Behavior:** Alarm on, motor off, ignore overload until emergency cleared.

---

### Q31: Explain metastability and how to prevent it.

**A:** **Metastability** = input changes near clock edge, flip-flop enters unstable state.

**In our design:** `req`, `emergency`, `overload`, `door_sensor` are asynchronous inputs - could cause metastability.

**Prevention:** Double-flop synchronizer:

```verilog
reg emergency_sync1, emergency_sync2;

always @(posedge clk) begin
    emergency_sync1 <= emergency;      // First flop
    emergency_sync2 <= emergency_sync1; // Second flop (use this)
end
```

**Why works:** Even if sync1 metastable, has full clock cycle to settle before sync2 samples.

**Note:** Not implemented in current design (simplification), but would add for FPGA.

---

### Q32: What is the purpose of localparam?

**A:** 

```verilog
localparam FLOOR_TRAVEL_TIME = 50;
```

**Benefits:**
1. **Readability:** `if (counter >= FLOOR_TRAVEL_TIME)` vs `if (counter >= 50)`
2. **Maintainability:** Change once, updates everywhere
3. **Type safety:** Prevents magic numbers
4. **Synthesis:** Optimized away (no hardware cost)
5. **Local scope:** Can't be overridden from outside

**vs. parameter:** localparam can't be overridden during instantiation.

**Best practice:** Use localparam for internal constants, parameter for configurable values.

---

### Q33: How would you optimize for power consumption?

**A:** 

**1. Clock gating:**
```verilog
wire clk_gated = clk & (state != IDLE);
```
Stop clock when idle.

**2. Reduce motor starts:**
SCAN already does this - fewer direction changes.

**3. Sleep mode:**
```verilog
IDLE: begin
    motor_enable <= 0;
    // Disable unused logic
end
```

**4. Optimize timers:**
Use slower clock for timers (don't need 100 MHz for counting seconds).

**5. Regenerative braking:**
Use motor as generator when descending (beyond current scope).

---

### Q34: Explain the concept of request servicing fairness.

**A:** 

**Fairness** = No request waits indefinitely (no starvation).

**SCAN guarantees fairness:**
- Every floor eventually in path of travel
- Direction reverses ensure all requests served
- No priority between floors

**Proof by contradiction:**
Assume floor X never served:
1. X has request
2. Elevator eventually travels in X's direction (reversal)
3. SCAN serves all floors in that direction
4. X must be served
5. Contradiction!

**vs. SSTF (Shortest Seek Time First):** Can starve edge floors if center floors keep requesting.

---

### Q35: How does the testbench determine pass/fail?

**A:** **check_condition** task:

```verilog
task check_condition;
    input condition;
    input [200*8:1] test_name;
    begin
        if (condition) {
            $display("[PASS] %s", test_name);
            pass_count++;
        } else {
            $display("[FAIL] %s", test_name);
            fail_count++;
        }
    end
endtask
```

**Usage:**
```verilog
check_condition(
    current_floor == 3,
    "Elevator reached floor 3"
);
```

**Self-checking:** No manual waveform inspection needed - testbench automatically reports pass/fail.

---

## Part 3: Practical & Application (10 Questions)

### Q36: How would you implement this on an FPGA?

**A:** 

**Steps:**
1. **Add synchronizers** for async inputs
2. **Add debouncing** for button inputs
3. **Clock division** for human-scale timing
4. **Seven-segment decoder** for floor display
5. **LED drivers** for direction/status
6. **Constraint file** for pin mapping

**Example modifications:**
```verilog
// Slow down for real-time
localparam FLOOR_TRAVEL_TIME = 100_000_000; // 1 second at 100MHz
localparam DOOR_OPEN_TIME = 300_000_000;    // 3 seconds
```

**Hardware:** Basys3, Nexys A7, or similar Xilinx board.

---

### Q37: What real-world sensors would you connect?

**A:** 

| Sensor | Type | Connection | Purpose |
|--------|------|------------|---------|
| **Floor buttons** | Push buttons | req[7:0] | Request floors |
| **Weight sensor** | Load cell + ADC | overload | Detect overload |
| **Door IR beam** | Photoelectric | door_sensor | Obstruction |
| **Emergency button** | E-stop switch | emergency | Emergency stop |
| **Position encoder** | Rotary encoder | current_floor | Precise position |
| **Speed sensor** | Tachometer | (future) | Motor control |

**Processing:** May need debouncing, filtering, threshold detection.

---

### Q38: Compare SCAN with LOOK algorithm.

**A:** 

| Aspect | SCAN | LOOK |
|--------|------|------|
| **Reversal** | At end floors (0, 7) | When no more requests |
| **Travel** | Always to end | Only as far as needed |
| **Efficiency** | Good | Better |
| **Implementation** | Simpler | More complex |

**Example:**
- Requests at floors 2, 4, 7
- At floor 0, going UP

**SCAN:** 0→2→4→7 (to end), then reverse  
**LOOK:** 0→2→4→7, immediately reverse (doesn't go to end)

**Our choice:** SCAN for simplicity. LOOK would save the extra travel to top floor when not needed.

---

### Q39: How would you add multiple elevators?

**A:** 

**Coordination strategies:**

**1. Zone-based:**
- Elevator A: Floors 0-3
- Elevator B: Floors 4-7

**2. Load balancing:**
```verilog
if (request[floor]) {
    assigned_elevator = find_closest_idle_elevator();
}
```

**3. Directional assignment:**
- Elevator going UP takes UP requests
- Elevator going DOWN takes DOWN requests

**Implementation:**
```verilog
module multi_elevator_controller (
    // Shared request bus
    input wire [7:0] req,
    
    // Individual elevator interfaces
    output wire [2:0] elevator_A_floor,
    output wire [2:0] elevator_B_floor,
    ...
);
```

**Communication:** Request arbiter assigns requests to optimal elevator.

---

### Q40: Explain how you would add inside vs. outside buttons.

**A:** 

**Current:** Single `req[7:0]` for all requests

**Enhanced:**
```verilog
input wire [7:0] req_up;    // Outside UP buttons
input wire [7:0] req_down;  // Outside DOWN buttons
input wire [7:0] req_inside; // Inside panel

// Combine based on direction
if (direction == UP)
    pending_requests = req_up | req_inside;
else
    pending_requests = req_down | req_inside;
```

**Benefit:** More efficient - only serve floors in correct direction.

**Example:** At floor 3 going UP, ignore DOWN button at floor 5 (will serve on return trip).

---

### Q41: How would you handle express floors (skip certain floors)?

**A:** 

**Add express mode:**
```verilog
input wire express_mode;
input wire [7:0] express_floors;  // Bitmap of express floors

// In search functions
if (express_mode && !express_floors[i])
    continue;  // Skip non-express floors
```

**Example:** Building with lobby (0), parking (1-2), offices (3-7)
- Express from 0→3 (skip 1, 2)
- Local mode stops at all floors

**Implementation:** Modify `has_request_above/below` to check express_floors bitmap.

---

### Q42: What would you add for maintenance mode?

**A:** 

**Maintenance features:**

```verilog
input wire maintenance_mode;
input wire [2:0] manual_floor;

// Override normal operation
if (maintenance_mode) {
    target_floor = manual_floor;
    // Disable automatic requests
    // Slower speed
    // Override safety (within limits)
}
```

**Use cases:**
- Manual floor control for testing
- Slow-speed inspection
- Door override for cleaning
- Diagnostic mode

**Safety:** Still honor emergency stop, but can override overload for testing.

---

### Q43: How would you log/debug in hardware?

**A:** 

**Methods:**

**1. UART logging:**
```verilog
uart_tx.send($sformatf("State: %s, Floor: %d", state_name, current_floor));
```

**2. LED indicators:**
```verilog
assign led[7:0] = pending_requests;  // Show active requests
assign led[8] = direction;           // Show direction
assign led[9] = motor_enable;        // Show motor
```

**3. VGA display:**
Display current state, floor, requests on monitor.

**4. Logic analyzer:**
Export critical signals to analyzer (like GTKWave but in hardware).

**5. Internal registers:**
```verilog
reg [31:0] total_trips;
reg [31:0] total_floors_traveled;
// Read via UART/SPI
```

---

### Q44: What failure modes should you consider?

**A:** 

| Failure | Detection | Response |
|---------|-----------|----------|
| **Sensor failure** | Timeout/checksum | Use redundant sensor |
| **Stuck button** | Request never clears | Timeout + clear |
| **Motor failure** | No position change | Emergency mode, alarm |
| **Door jam** | Door_sensor always high | Alert maintenance |
| **Power loss** | Voltage monitor | Battery backup, safe stop |
| **Runaway** | Speed > threshold | Emergency brake |

**Watchdog timer:**
```verilog
if (state == MOVE && travel_counter > MAX_TRAVEL_TIME)
    next_state = EMERGENCY;  // Stuck in MOVE state
```

---

### Q45: How does this relate to disk scheduling?

**A:** **Direct analogy:**

| Elevator | Disk |
|----------|------|
| Floors | Disk cylinders/tracks |
| Elevator car | Disk head |
| Direction (UP/DOWN) | Head movement (IN/OUT) |
| Floor requests | I/O requests |
| SCAN algorithm | SCAN disk scheduling |

**Same algorithm because:**
- Both minimize total movement
- Both have requests at discrete positions
- Both have sequential access optimization

**Performance:**
- Elevator: Reduces wait time, energy
- Disk: Reduces seek time, improves throughput

**Fun fact:** SCAN invented for elevators, then applied to disks!

---

## Part 4: Advanced Conceptual (5 Questions)

### Q46: What is the difference between Moore and Mealy FSM? Which did you use?

**A:** 

**Moore FSM:**
- Outputs depend only on current state
- Outputs change on clock edge
- Easier to design, more stable

**Mealy FSM:**
- Outputs depend on current state AND inputs
- Outputs can change asynchronously
- Potentially faster response

**Our design: Mostly Moore**
```verilog
// Output depends only on state
motor_enable <= (state == MOVE);
door_open <= (state == DOOR_OPEN) || (state == DOOR_WAIT);
```

**Advantage:** Glitch-free outputs, simpler timing analysis.

---

### Q47: How would you formally verify this design?

**A:** 

**Formal verification methods:**

**1. Model checking:**
```verilog
// Properties to verify
assert property (state == EMERGENCY |-> motor_enable == 0);
assert property (alarm == 1 |-> (emergency || overload));
```

**2. Invariants:**
- current_floor always between 0-7
- Only one state active at a time
- Requests never lost

**3. Temporal logic (LTL):**
- Eventually all requests served: `G(req[i] -> F(door_open && current_floor == i))`
- Safety: `G(emergency -> motor_enable == 0)`

**4. Equivalence checking:**
Compare RTL to golden reference model.

**Tools:** Cadence JasperGold, Synopsys VC Formal

---

### Q48: Explain control vs. datapath separation.

**A:** 

**Control:**
- FSM state machine
- Decision logic
- Generates control signals
- Small, fast

**Datapath:**
- Counters (travel_counter, door_timer)
- Floor register
- Request latching
- Processes data

**In our design:**
```verilog
// CONTROL
always @(*) begin
    case (state)  // FSM logic
        IDLE: ...
        MOVE: ...
    endcase
end

// DATAPATH
always @(posedge clk) begin
    if (state == MOVE)
        travel_counter <= travel_counter + 1;  // Data processing
end
```

**Benefit:** Clean separation, easier to optimize independently.

---

### Q49: How would you pipeline this design for higher frequency?

**A:** 

**Current bottleneck:** Combinational next_state logic might be long path.

**Pipelining approach:**

**1. Register critical paths:**
```verilog
// Stage 1: Compute search results
reg has_req_up, has_req_down;
always @(posedge clk) begin
    has_req_up <= has_request_above(...);
    has_req_down <= has_request_below(...);
end

// Stage 2: Use registered results
always @(posedge clk) begin
    if (has_req_up) ...
end
```

**2. Separate computation stages:**
- Clock 1: Compute next target
- Clock 2: Update state
- Clock 3: Update outputs

**Tradeoff:** Higher latency (more clocks per action) but higher max frequency.

---

### Q50: What is the state space size and how to reduce it?

**A:** 

**Current state space:**
- State: 7 values (3 bits)
- current_floor: 8 values (3 bits)
- direction: 2 values (1 bit)
- pending_requests: 256 values (8 bits)
- travel_counter: 256 values (8 bits)
- door_timer: 256 values (8 bits)

**Total: 7 × 8 × 2 × 256 × 256 × 256 = ~7 billion states**

**Reduction techniques:**

**1. Equivalence classes:**
- Many timer values functionally equivalent

**2. Abstract model:**
- Ignore exact timer counts, just {zero, non-zero}

**3. Symbolic representation:**
- BDD (Binary Decision Diagram) for pending_requests

**4. Focus on reachable states:**
- Not all 7B states reachable from reset

**For verification:** Use abstraction + formal methods, not exhaustive enumeration.

---

## Part 5: Quick Fire Round (10 Questions)

### Q51: What is the maximum floor your design supports?
**A:** 8 floors (0-7) due to 3-bit current_floor. To support more, widen to 4 bits (16 floors), 5 bits (32 floors), etc.

---

### Q52: What happens if all floors request simultaneously?
**A:** All requests latched. SCAN serves 0→1→2→3→4→5→6→7 in sequence. Efficient handling!

---

### Q53: Can the elevator move during emergency?
**A:** No. `motor_enable = 0` in EMERGENCY state. Safety first.

---

### Q54: What is the purpose of the alarm output?
**A:** Alert building occupants/maintenance of emergency or overload condition. Could drive buzzer or send alert.

---

### Q55: How long does door stay open (in real time)?
**A:** 30 cycles × 10ns = 300ns at 100MHz. In scaled-up FPGA: 3 seconds (30M cycles at 10MHz clock).

---

### Q56: What is request latching?
**A:** Capturing and holding floor requests in pending_requests register until served. Prevents request loss.

---

### Q57: Which state has highest priority?
**A:** EMERGENCY. It can interrupt any other state.

---

### Q58: What synthesis tool would you use?
**A:** Xilinx Vivado (for FPGAs), Synopsys Design Compiler (for ASICs), or Intel Quartus.

---

### Q59: How many lines of code in your design?
**A:** ~350 lines RTL (smart_elevator.v), ~450 lines testbench (tb_smart_elevator.v). Total ~800 lines.

---

### Q60: What would you improve in next version?
**A:** 
1. Multi-elevator coordination
2. Predictive AI scheduling
3. Energy optimization
4. Formal verification
5. FPGA deployment with real I/O

---

## 🎯 Closing Statement for Viva

**If asked: "What did you learn from this project?"**

**A:** *"This project taught me that hardware design is fundamentally different from software—you're not just implementing algorithms, you're architecting systems where everything happens in parallel, timing is critical, and safety cannot be an afterthought. I learned to think in terms of states, signals, and clock cycles. The SCAN algorithm showed me how computer science concepts directly translate to real-world hardware. Most importantly, I learned that great design isn't just about making it work—it's about making it verifiable, maintainable, and safe. This elevator controller could actually save lives in an emergency, and that responsibility drives better engineering."*

---

## 📚 Key Terms to Remember

- SCAN Algorithm
- Hierarchical FSM
- Request Latching
- Direction Reversal
- Safety Priority
- Timing Parameters
- Self-Checking Testbench
- Moore FSM
- Synchronous Design
- Control vs. Datapath

---

## 🎓 Final Tips for Viva

1. **Start with the one-liner** - Sets confident tone
2. **Draw diagrams** - FSM, block diagram on board
3. **Use examples** - "For instance, if at floor 3..."
4. **Show enthusiasm** - "This was challenging but rewarding because..."
5. **Admit unknowns** - "I haven't implemented that, but I would..."
6. **Connect to real-world** - "This is used in actual elevators because..."
7. **Be ready to modify** - "To add that feature, I would change..."

---

**Good luck with your viva! You've built something genuinely impressive.**

---

*Prepared: January 18, 2026*  
*Project: Smart Elevator Controller*  
*Total Q&A: 60 questions covering all aspects*

# Simple Readable Test Case

Purpose: A minimal, easy-to-follow test that requests floor 2 from floor 0 and checks basic outputs (movement, arrival, door open). Use this to understand inputs, outputs, and the FSM flow.

Scenario:
- Start at floor 0 (reset).
- Request floor 2.
- Expect the elevator to move (motor enabled), arrive at floor 2, open the door, then close after timeout.

Signals to watch:
- `current_floor` (3 bits): shows which floor elevator is at.
- `motor_enable`: 1 while moving.
- `door_open`: 1 while door is open.
- `state`: internal FSM state (DOOR_OPEN = 3, DOOR_WAIT = 4).

Expected sequence:
1. IDLE -> MOVE (motor_enable == 1)
2. MOVE -> ARRIVE -> DOOR_OPEN (current_floor == 2, door_open == 1)
3. DOOR_OPEN -> DOOR_WAIT -> IDLE (door closes after timers)

Minimal testbench (paste into EDA Playground LEFT panel; `smart_elevator.v` in RIGHT panel):

```verilog
`timescale 1ns/1ps
module tb_simple;
    reg clk;
    reg reset;
    reg [7:0] req;
    reg emergency;
    reg overload;
    reg door_sensor;

    wire [2:0] current_floor;
    wire direction;
    wire motor_enable;
    wire door_open;
    wire alarm;

    // Instantiate DUT (assumes smart_elevator.v available)
    smart_elevator dut (
        .clk(clk),
        .reset(reset),
        .req(req),
        .emergency(emergency),
        .overload(overload),
        .door_sensor(door_sensor),
        .current_floor(current_floor),
        .direction(direction),
        .motor_enable(motor_enable),
        .door_open(door_open),
        .alarm(alarm)
    );

    // Clock: 100 MHz
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        // Initialize inputs
        reset = 1;
        req = 8'b0;
        emergency = 0;
        overload = 0;
        door_sensor = 0;

        // Waveform
        $dumpfile("simple_wave.vcd");
        $dumpvars(0, tb_simple);

        // Release reset
        repeat (5) @(posedge clk);
        reset = 0;
        @(posedge clk);

        $display("Requesting floor 2...");
        // Pulse request for floor 2
        req[2] = 1;
        @(posedge clk);
        req[2] = 0;

        // Wait until we reach floor 2 (timeout to avoid infinite loops)
        integer cnt;
        cnt = 0;
        while (current_floor != 3'b010 && cnt < 10000) begin
            @(posedge clk);
            cnt = cnt + 1;
        end

        if (current_floor == 3'b010) begin
            $display("Reached floor 2 as expected. motor_enable=%b, door_open=%b", motor_enable, door_open);
        end else begin
            $display("Timeout waiting for floor 2. current_floor=%0d", current_floor);
        end

        // Let door open/close sequence complete
        repeat (200) @(posedge clk);

        $display("Finished simple test.");
        $finish;
    end
endmodule
```

How to run:
1. Put `smart_elevator.v` in the RIGHT panel on EDA Playground.
2. Put the testbench above in the LEFT panel.
3. Select Icarus Verilog (or any simulator) and click Run.
4. Inspect console for printed messages and open the VCD in EPWave to see `current_floor`, `motor_enable`, `door_open`, and `state` transitions.

Notes:
- This minimal test avoids extra helper tasks to be easy to read.
- Use the waveform viewer to step through the FSM transitions visually.


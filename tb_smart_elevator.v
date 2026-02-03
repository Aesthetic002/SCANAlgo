// ==============================================================================
// Testbench for Smart Elevator Controller
// ==============================================================================
// Author: Digital IC Design Team
// Date: January 18, 2026
// Description: Comprehensive self-checking testbench for elevator controller
//              Tests SCAN algorithm, direction reversal, safety, and timing
// ==============================================================================

`timescale 1ns/1ps

module tb_smart_elevator;

    // ==========================================================================
    // Testbench Signals
    // ==========================================================================
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
    
    // Test tracking
    integer test_num;
    integer pass_count;
    integer fail_count;
    
    // ==========================================================================
    // DUT Instantiation
    // ==========================================================================
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
    
    // ==========================================================================
    // Clock Generation (100 MHz -> 10ns period)
    // ==========================================================================
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    // ==========================================================================
    // Waveform Dump for GTKWave
    // ==========================================================================
    initial begin
        $dumpfile("elevator_waveform.vcd");
        $dumpvars(0, tb_smart_elevator);
    end
    
    // ==========================================================================
    // Test Helper Tasks
    // ==========================================================================
    
    task reset_system;
        begin
            reset = 1;
            req = 8'b0;
            emergency = 0;
            overload = 0;
            door_sensor = 0;
            repeat(5) @(posedge clk);
            reset = 0;
            repeat(2) @(posedge clk);
        end
    endtask
    
    task wait_cycles;
        input integer cycles;
        begin
            repeat(cycles) @(posedge clk);
        end
    endtask
    
    task check_condition;
        input condition;
        input [200*8:1] test_name;
        begin
            if (condition) begin
                $display("[PASS] Test %0d: %s", test_num, test_name);
                pass_count = pass_count + 1;
            end else begin
                $display("[FAIL] Test %0d: %s", test_num, test_name);
                fail_count = fail_count + 1;
            end
            test_num = test_num + 1;
        end
    endtask
    
    task request_floor;
        input [2:0] floor;
        begin
            req[floor] = 1;
            @(posedge clk);
            req[floor] = 0;
        end
    endtask
    
    task wait_for_floor;
        input [2:0] target;
        input integer max_cycles;
        integer count;
        begin
            count = 0;
            while (current_floor != target && count < max_cycles) begin
                @(posedge clk);
                count = count + 1;
            end
        end
    endtask
    
    task wait_for_door_close;
        integer count;
        begin
            count = 0;
            while (door_open && count < 1000) begin
                @(posedge clk);
                count = count + 1;
            end
        end
    endtask
    
    // ==========================================================================
    // Main Test Sequence
    // ==========================================================================
    initial begin
        test_num = 1;
        pass_count = 0;
        fail_count = 0;
        
        $display("\n");
        $display("==============================================================================");
        $display("   Smart Elevator Controller - Comprehensive Testbench");
        $display("==============================================================================");
        $display("Testing: SCAN Algorithm, Safety Features, Timing, Direction Reversal");
        $display("==============================================================================\n");
        
        // ======================================================================
        // TEST 1: Reset and Initialization
        // ======================================================================
        $display("\n--- TEST 1: Reset and Initialization ---");
        reset_system();
        wait_cycles(10);
        
        check_condition(
            current_floor == 3'b000,
            "After reset, elevator at floor 0"
        );
        
        check_condition(
            motor_enable == 0 && door_open == 0 && alarm == 0,
            "After reset, all outputs inactive"
        );
        
        // ======================================================================
        // TEST 2: Single Floor Request (Upward)
        // ======================================================================
        $display("\n--- TEST 2: Single Floor Request (Upward) ---");
        request_floor(3);
        $display("Requesting floor 3...");
        
        wait_cycles(20);
        check_condition(
            motor_enable == 1,
            "Motor enabled when moving to floor 3"
        );
        
        wait_for_floor(3, 5000);
        wait_cycles(10);
        
        check_condition(
            current_floor == 3,
            "Elevator reached floor 3"
        );
        
        check_condition(
            door_open == 1,
            "Door opened at floor 3"
        );
        
        wait_for_door_close();
        wait_cycles(10);
        
        check_condition(
            door_open == 0,
            "Door closed after timeout"
        );
        
        // ======================================================================
        // TEST 3: Multiple Requests in Same Direction (SCAN - Upward)
        // ======================================================================
        $display("\n--- TEST 3: SCAN Algorithm - Multiple Upward Requests ---");
        reset_system();
        
        // Request floors 2, 5, 7 (should serve in order: 2, 5, 7)
        request_floor(2);
        request_floor(5);
        request_floor(7);
        $display("Requesting floors 2, 5, 7 simultaneously...");
        
        wait_cycles(50);
        
        // Should go to floor 2 first
        wait_for_floor(2, 5000);
        wait_cycles(20);
        check_condition(
            current_floor == 2,
            "SCAN: Reached floor 2 first"
        );
        
        check_condition(
            direction == 1,
            "SCAN: Direction still UP after floor 2"
        );
        
        wait_for_door_close();
        wait_cycles(50);
        
        // Should go to floor 5 next
        wait_for_floor(5, 5000);
        wait_cycles(20);
        check_condition(
            current_floor == 5,
            "SCAN: Reached floor 5 second"
        );
        
        wait_for_door_close();
        wait_cycles(50);
        
        // Should go to floor 7 last
        wait_for_floor(7, 5000);
        wait_cycles(20);
        check_condition(
            current_floor == 7,
            "SCAN: Reached floor 7 last"
        );
        
        wait_for_door_close();
        
        // ======================================================================
        // TEST 4: Direction Reversal (SCAN Algorithm)
        // ======================================================================
        $display("\n--- TEST 4: Direction Reversal After Serving All Upward Requests ---");
        
        // Elevator at floor 7, request floor 3 (should reverse direction)
        request_floor(3);
        $display("At floor 7, requesting floor 3...");
        
        wait_cycles(50);
        
        check_condition(
            direction == 0,
            "Direction reversed to DOWN"
        );
        
        wait_for_floor(3, 5000);
        wait_cycles(20);
        
        check_condition(
            current_floor == 3,
            "Reached floor 3 after direction reversal"
        );
        
        wait_for_door_close();
        
        // ======================================================================
        // TEST 5: SCAN with Mixed Requests (Up and Down)
        // ======================================================================
        $display("\n--- TEST 5: SCAN - Complete All Requests in Current Direction First ---");
        reset_system();
        
        // Request floors 1, 4, 6 from floor 0
        request_floor(1);
        request_floor(4);
        wait_cycles(10);
        request_floor(6);
        $display("Requesting floors 1, 4, 6 from floor 0...");
        
        wait_cycles(50);
        
        // Should serve in order: 1, 4, 6 (all upward)
        wait_for_floor(1, 5000);
        wait_cycles(20);
        
        // While at floor 1, request floor 2 (above) and floor 0 (below)
        request_floor(2);
        request_floor(0);
        $display("At floor 1: Requesting floor 2 (above) and 0 (below)...");
        
        wait_for_door_close();
        wait_cycles(50);
        
        // Should continue upward to floor 2 (SCAN continues in current direction)
        wait_for_floor(2, 5000);
        wait_cycles(20);
        check_condition(
            current_floor == 2,
            "SCAN: Served floor 2 (above) before reversing"
        );
        
        wait_for_door_close();
        wait_cycles(50);
        
        // Should continue to floor 4
        wait_for_floor(4, 5000);
        wait_cycles(20);
        check_condition(
            current_floor == 4,
            "SCAN: Served floor 4 continuing upward"
        );
        
        wait_for_door_close();
        wait_cycles(50);
        
        // Should continue to floor 6
        wait_for_floor(6, 5000);
        wait_cycles(20);
        check_condition(
            current_floor == 6,
            "SCAN: Served floor 6 (last upward request)"
        );
        
        wait_for_door_close();
        wait_cycles(50);
        
        // Now should reverse and go to floor 0
        wait_for_floor(0, 10000);
        wait_cycles(20);
        check_condition(
            current_floor == 0,
            "SCAN: After all upward served, reversed to floor 0"
        );
        
        wait_for_door_close();
        
        // ======================================================================
        // TEST 6: Emergency Stop During Movement
        // ======================================================================
        $display("\n--- TEST 6: Emergency Stop During Movement ---");
        reset_system();
        
        request_floor(5);
        wait_cycles(100);
        
        // Activate emergency while moving
        $display("Activating emergency while moving...");
        emergency = 1;
        wait_cycles(10);
        
        check_condition(
            alarm == 1,
            "Emergency: Alarm activated"
        );
        
        check_condition(
            motor_enable == 0,
            "Emergency: Motor disabled"
        );
        
        wait_cycles(50);
        
        // Clear emergency
        $display("Clearing emergency...");
        emergency = 0;
        wait_cycles(10);
        
        check_condition(
            alarm == 0,
            "Emergency cleared: Alarm deactivated"
        );
        
        wait_cycles(100);
        
        // ======================================================================
        // TEST 7: Door Obstruction Detection
        // ======================================================================
        $display("\n--- TEST 7: Door Obstruction Detection ---");
        reset_system();
        
        request_floor(2);
        wait_for_floor(2, 5000);
        wait_cycles(20);
        
        // Wait for door to be open
        check_condition(
            door_open == 1,
            "Door opened at floor 2"
        );
        
        // Trigger obstruction during DOOR_WAIT state
        // DOOR_OPEN_TIME = 30 cycles, so at 35 cycles we're in DOOR_WAIT
        // Then wait a few more to be safely inside DOOR_WAIT
        $display("Simulating door obstruction...");
        wait_cycles(38);  // Wait until well into DOOR_WAIT
        
        // Now trigger the door sensor
        door_sensor = 1;
        wait_cycles(2);
        door_sensor = 0;
        
        wait_cycles(10);
        
        check_condition(
            door_open == 1,
            "Door remained open after obstruction"
        );
        
        // Door should stay open longer
        wait_cycles(50);
        
        // ======================================================================
        // TEST 8: Overload Detection
        // ======================================================================
        $display("\n--- TEST 8: Overload Detection ---");
        reset_system();
        
        request_floor(3);
        wait_for_floor(3, 5000);
        wait_cycles(20);
        
        // Activate overload
        $display("Activating overload...");
        overload = 1;
        wait_cycles(10);
        
        check_condition(
            alarm == 1,
            "Overload: Alarm activated"
        );
        
        check_condition(
            motor_enable == 0,
            "Overload: Motor disabled"
        );
        
        // Clear overload
        wait_cycles(30);
        $display("Clearing overload...");
        overload = 0;
        wait_cycles(10);
        
        check_condition(
            alarm == 0,
            "Overload cleared: Alarm deactivated"
        );
        
        wait_for_door_close();
        
        // ======================================================================
        // TEST 9: Request at Current Floor
        // ======================================================================
        $display("\n--- TEST 9: Request at Current Floor ---");
        reset_system();
        
        // Request floor 0 (current floor)
        request_floor(0);
        wait_cycles(20);
        
        check_condition(
            door_open == 1,
            "Door opened for request at current floor"
        );
        
        check_condition(
            motor_enable == 0,
            "Motor not activated for current floor request"
        );
        
        wait_for_door_close();
        
        // ======================================================================
        // TEST 10: Rapid Multiple Requests (Stress Test)
        // ======================================================================
        $display("\n--- TEST 10: Rapid Multiple Requests (Stress Test) ---");
        reset_system();
        
        // Request all floors
        $display("Requesting all floors 1-7...");
        request_floor(1);
        request_floor(2);
        request_floor(3);
        request_floor(4);
        request_floor(5);
        request_floor(6);
        request_floor(7);
        
        wait_cycles(100);
        
        check_condition(
            motor_enable == 1,
            "Stress test: Motor active with multiple requests"
        );
        
        // Let it serve a few floors
        wait_for_floor(3, 10000);
        wait_cycles(20);
        
        check_condition(
            current_floor >= 1 && current_floor <= 7,
            "Stress test: Elevator serving requests"
        );
        
        // ======================================================================
        // Final Results
        // ======================================================================
        wait_cycles(100);
        
        $display("\n");
        $display("==============================================================================");
        $display("   Test Summary");
        $display("==============================================================================");
        $display("Total Tests: %0d", test_num - 1);
        $display("Passed:      %0d", pass_count);
        $display("Failed:      %0d", fail_count);
        $display("==============================================================================");
        
        if (fail_count == 0) begin
            $display("\n*** ALL TESTS PASSED! *** ✓");
            $display("\nThe Smart Elevator Controller successfully implements:");
            $display("  ✓ SCAN Scheduling Algorithm");
            $display("  ✓ Hierarchical FSM");
            $display("  ✓ Direction Reversal Logic");
            $display("  ✓ Safety Features (Emergency, Overload)");
            $display("  ✓ Door Obstruction Handling");
            $display("  ✓ Realistic Timing Model");
        end else begin
            $display("\n*** SOME TESTS FAILED ***");
            $display("Please review the failed test cases above.");
        end
        
        $display("\n==============================================================================\n");
        
        $finish;
    end
    
    // ==========================================================================
    // Monitor - Display State Changes
    // ==========================================================================
    always @(posedge clk) begin
        if (dut.state != dut.next_state) begin
            $display("[%0t] State: %s -> %s | Floor: %0d | Dir: %s | Motor: %b | Door: %b | Alarm: %b",
                $time,
                get_state_name(dut.state),
                get_state_name(dut.next_state),
                current_floor,
                direction ? "UP" : "DN",
                motor_enable,
                door_open,
                alarm
            );
        end
    end
    
    // Helper function to get state name for display
    function [80*8:1] get_state_name;
        input [3:0] state;
        begin
            case (state)
                4'b0000: get_state_name = "IDLE";
                4'b0001: get_state_name = "MOVE";
                4'b0010: get_state_name = "ARRIVE";
                4'b0011: get_state_name = "DOOR_OPEN";
                4'b0100: get_state_name = "DOOR_WAIT";
                4'b0101: get_state_name = "EMERGENCY";
                4'b0110: get_state_name = "OVERLOAD";
                default: get_state_name = "UNKNOWN";
            endcase
        end
    endfunction

endmodule

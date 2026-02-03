// ==============================================================================
// Smart Elevator Controller with SCAN Scheduling Algorithm
// ==============================================================================
// Author: Digital IC Design Team
// Date: January 18, 2026
// Description: Industry-grade 8-floor elevator controller implementing SCAN
//              scheduling with hierarchical FSM, safety features, and timing
// ==============================================================================

module smart_elevator (
    // Clock and Reset
    input wire clk,
    input wire reset,
    
    // Floor Requests (8 floors: 0-7)
    input wire [7:0] req,
    
    // Safety Inputs
    input wire emergency,
    input wire overload,
    input wire door_sensor,
    
    // Outputs
    output reg [2:0] current_floor,
    output reg direction,           // 1 = UP, 0 = DOWN
    output reg motor_enable,
    output reg door_open,
    output reg alarm
);

    // ==========================================================================
    // FSM State Definitions (Hierarchical)
    // ==========================================================================
    localparam [3:0] IDLE        = 4'b0000,
                     MOVE        = 4'b0001,
                     ARRIVE      = 4'b0010,
                     DOOR_OPEN   = 4'b0011,
                     DOOR_WAIT   = 4'b0100,
                     EMERGENCY   = 4'b0101,
                     OVERLOAD    = 4'b0110;
    
    // Direction Constants
    localparam UP   = 1'b1;
    localparam DOWN = 1'b0;
    
    // Timing Parameters (in clock cycles)
    localparam FLOOR_TRAVEL_TIME = 50;   // Time to move one floor
    localparam DOOR_OPEN_TIME    = 30;   // Time door stays open
    localparam DOOR_WAIT_TIME    = 20;   // Additional wait after obstruction
    
    // ==========================================================================
    // Internal Registers
    // ==========================================================================
    reg [3:0] state, next_state;
    reg [7:0] pending_requests;          // Latched floor requests
    reg [7:0] travel_counter;            // Timer for floor movement
    reg [7:0] door_timer;                // Timer for door operations
    reg [2:0] target_floor;              // Next floor to visit
    reg door_obstruction_detected;
    
    // ==========================================================================
    // Helper Functions for SCAN Algorithm
    // ==========================================================================
    
    // Check if there are requests above current floor
    function has_request_above;
        input [2:0] floor;
        input [7:0] requests;
        integer i;
        begin
            has_request_above = 0;
            for (i = floor + 1; i < 8; i = i + 1) begin
                if (requests[i])
                    has_request_above = 1;
            end
        end
    endfunction
    
    // Check if there are requests below current floor
    function has_request_below;
        input [2:0] floor;
        input [7:0] requests;
        integer i;
        begin
            has_request_below = 0;
            for (i = 0; i < floor; i = i + 1) begin
                if (requests[i])
                    has_request_below = 1;
            end
        end
    endfunction
    
    // Find next request in current direction (SCAN logic)
    function [2:0] find_next_request;
        input [2:0] floor;
        input dir;
        input [7:0] requests;
        integer i;
        begin
            find_next_request = floor;
            
            if (dir == UP) begin
                // Search upward
                for (i = floor + 1; i < 8; i = i + 1) begin
                    if (requests[i]) begin
                        find_next_request = i[2:0];
                        i = 8; // Exit loop
                    end
                end
            end else begin
                // Search downward
                for (i = floor - 1; i >= 0; i = i - 1) begin
                    if (requests[i]) begin
                        find_next_request = i[2:0];
                        i = -1; // Exit loop
                    end
                end
            end
        end
    endfunction
    
    // ==========================================================================
    // Request Latching - Capture and hold floor requests
    // ==========================================================================
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            pending_requests <= 8'b0;
        end else begin
            // Latch new requests
            pending_requests <= pending_requests | req;
            
            // Clear request when we arrive at a floor and open door
            if (state == DOOR_OPEN) begin
                pending_requests[current_floor] <= 1'b0;
            end
        end
    end
    
    // ==========================================================================
    // FSM State Register
    // ==========================================================================
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end
    
    // ==========================================================================
    // FSM Next State Logic (Hierarchical with Safety Priority)
    // ==========================================================================
    always @(*) begin
        // Default: stay in current state
        next_state = state;
        
        // Safety Priority: Emergency takes highest priority
        if (emergency) begin
            next_state = EMERGENCY;
        end else begin
            case (state)
                IDLE: begin
                    if (pending_requests != 8'b0) begin
                        if (pending_requests[current_floor]) begin
                            // Request at current floor
                            next_state = DOOR_OPEN;
                        end else begin
                            // Need to move
                            next_state = MOVE;
                        end
                    end
                end
                
                MOVE: begin
                    if (overload) begin
                        next_state = OVERLOAD;
                    end else if (travel_counter >= FLOOR_TRAVEL_TIME) begin
                        next_state = ARRIVE;
                    end
                end
                
                ARRIVE: begin
                    if (current_floor == target_floor && pending_requests[current_floor]) begin
                        next_state = DOOR_OPEN;
                    end else if (pending_requests != 8'b0) begin
                        next_state = MOVE;
                    end else begin
                        next_state = IDLE;
                    end
                end
                
                DOOR_OPEN: begin
                    if (overload) begin
                        next_state = OVERLOAD;
                    end else if (door_timer >= DOOR_OPEN_TIME) begin
                        next_state = DOOR_WAIT;
                    end
                end
                
                DOOR_WAIT: begin
                    if (door_sensor) begin
                        // Obstruction detected, reopen door
                        next_state = DOOR_OPEN;
                    end else if (door_timer >= DOOR_WAIT_TIME) begin
                        if (pending_requests != 8'b0) begin
                            next_state = MOVE;
                        end else begin
                            next_state = IDLE;
                        end
                    end
                end
                
                EMERGENCY: begin
                    if (!emergency) begin
                        // Emergency cleared, return to idle
                        next_state = IDLE;
                    end
                end
                
                OVERLOAD: begin
                    if (!overload) begin
                        // Overload cleared, continue from door open
                        next_state = DOOR_OPEN;
                    end
                end
                
                default: next_state = IDLE;
            endcase
        end
    end
    
    // ==========================================================================
    // Direction Logic (SCAN Algorithm)
    // ==========================================================================
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            direction <= UP;
        end else begin
            case (state)
                IDLE, ARRIVE: begin
                    // Determine direction based on SCAN algorithm
                    if (direction == UP) begin
                        if (has_request_above(current_floor, pending_requests)) begin
                            direction <= UP;
                        end else if (has_request_below(current_floor, pending_requests)) begin
                            direction <= DOWN;
                        end
                    end else begin
                        if (has_request_below(current_floor, pending_requests)) begin
                            direction <= DOWN;
                        end else if (has_request_above(current_floor, pending_requests)) begin
                            direction <= UP;
                        end
                    end
                end
            endcase
        end
    end
    
    // ==========================================================================
    // Floor Movement Logic
    // ==========================================================================
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            current_floor <= 3'b000;
            travel_counter <= 8'b0;
            target_floor <= 3'b000;
        end else begin
            case (state)
                MOVE: begin
                    travel_counter <= travel_counter + 1;
                    
                    // Move one floor when timer expires
                    if (travel_counter >= FLOOR_TRAVEL_TIME) begin
                        travel_counter <= 8'b0;
                        
                        if (direction == UP && current_floor < 7) begin
                            current_floor <= current_floor + 1;
                        end else if (direction == DOWN && current_floor > 0) begin
                            current_floor <= current_floor - 1;
                        end
                    end
                    
                    // Update target floor based on SCAN
                    target_floor <= find_next_request(current_floor, direction, pending_requests);
                end
                
                ARRIVE, DOOR_OPEN, DOOR_WAIT: begin
                    travel_counter <= 8'b0;
                end
            endcase
        end
    end
    
    // ==========================================================================
    // Door Timer Logic
    // ==========================================================================
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            door_timer <= 8'b0;
            door_obstruction_detected <= 1'b0;
        end else begin
            case (state)
                DOOR_OPEN: begin
                    if (next_state == DOOR_WAIT) begin
                        // Reset timer when transitioning to DOOR_WAIT
                        door_timer <= 8'b0;
                    end else begin
                        door_timer <= door_timer + 1;
                    end
                    door_obstruction_detected <= 1'b0;
                end
                
                DOOR_WAIT: begin
                    if (door_sensor && !door_obstruction_detected) begin
                        // Obstruction detected, reset timer
                        door_timer <= 8'b0;
                        door_obstruction_detected <= 1'b1;
                    end else begin
                        door_timer <= door_timer + 1;
                    end
                end
                
                default: begin
                    door_timer <= 8'b0;
                    door_obstruction_detected <= 1'b0;
                end
            endcase
        end
    end
    
    // ==========================================================================
    // Output Control Logic
    // ==========================================================================
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            motor_enable <= 1'b0;
            door_open <= 1'b0;
            alarm <= 1'b0;
        end else begin
            // Motor Enable
            motor_enable <= (state == MOVE);
            
            // Door Open
            door_open <= (state == DOOR_OPEN) || (state == DOOR_WAIT);
            
            // Alarm
            alarm <= (state == EMERGENCY) || (state == OVERLOAD);
        end
    end

endmodule

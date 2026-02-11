`timescale 1ns / 1ps

module tb_interactive;

    // Inputs
    reg clk;
    reg reset;
    reg [7:0] req;
    reg emergency;
    reg overload;
    reg door_sensor;

    // Outputs
    wire [2:0] current_floor;
    wire direction;
    wire motor_enable;
    wire door_open;
    wire alarm;

    // Instantiate the Unit Under Test (UUT)
    smart_elevator uut (
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

    integer command;
    integer value;
    integer scan_res;

    initial begin
        // Initialize Inputs
        clk = 0;
        reset = 1;
        req = 0;
        emergency = 0;
        overload = 0;
        door_sensor = 0;

        // Reset pulse
        #10;
        reset = 0;
        
        $display("READY");
        $fflush();

        // Interactive Loop
        forever begin
            // Read command from STDIN (32'h8000_0000)
            command = $fgetc(32'h8000_0000);
            
            if (command != -1) begin
                if (command == "S") begin // Step (Run 10 cycles = 100ns)
                    // Run for 10 cycles to simulate time passing
                    repeat(10) begin
                        #5 clk = ~clk;
                        #5 clk = ~clk; 
                    end
                    
                    // Output current state as JSON-like string
                    $display("STATE:%0d|FLOOR:%0d|DIR:%0d|MOTOR:%0d|DOOR:%0d|ALARM:%0d", 
                        uut.state, current_floor, direction, motor_enable, door_open, alarm);
                    $fflush();
                end
                else if (command == "R") begin // Request Floor
                    // Expect next character to be the floor number (ascii - '0')
                    value = $fgetc(32'h8000_0000);
                    if (value >= "0" && value <= "7") begin
                        req[value - "0"] = 1;
                        // Clock the request in
                        #5 clk = ~clk;
                        #5 clk = ~clk;
                        req[value - "0"] = 0;
                        $display("ACK:REQUEST_%c", value);
                    end
                end
                else if (command == "E") begin // Emergency Toggle
                    value = $fgetc(32'h8000_0000); // 1 or 0
                    if (value == "1") emergency = 1;
                    else emergency = 0;
                    $display("ACK:EMERGENCY_%c", value);
                end
                 else if (command == "X") begin // Reset
                    reset = 1;
                    #10 reset = 0;
                    $display("ACK:RESET");
                end
                // Flush after every command to ensure Python sees it
                $fflush();
            end
            else begin
                #10; // Wait a bit if no input
            end
        end
    end
      
endmodule

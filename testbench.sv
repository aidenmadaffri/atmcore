module testbench;
    logic clk;
    logic reset;

    // Instantiate top module
    top dut (
        .clk(clk),
        .reset(reset)
    );

    // Clock generation
    initial clk = 0;
    always #5 clk <= ~clk; // 10 time units period

    initial begin
        // Apply reset
        reset = 1;
        #20; // Hold reset for 20 time units
        reset = 0;

        // Run simulation for some cycles
        #2000;

        $finish;
    end
endmodule

module dmem(
    input logic clk,
    input logic reset,
    input logic [15:0] addr,
    input logic [31:0] write_data,
    input logic [3:0] write_enable, // 4 bits, one per byte
    output logic [31:0] read_data
);

logic [31:0] memory [0:65535]; // 64KB data memory (16-bit addressable)

// Read data from memory
always_ff @(posedge clk) begin
    if (reset) begin
        read_data <= 32'b0;
    end else begin
        // Write-first: update memory, then read
        if (write_enable[0]) memory[addr][7:0]   <= write_data[7:0];
        if (write_enable[1]) memory[addr][15:8]  <= write_data[15:8];
        if (write_enable[2]) memory[addr][23:16] <= write_data[23:16];
        if (write_enable[3]) memory[addr][31:24] <= write_data[31:24];
        read_data <= (write_enable != 4'b0000) ? (
            {
                write_enable[3] ? write_data[31:24] : memory[addr][31:24],
                write_enable[2] ? write_data[23:16] : memory[addr][23:16],
                write_enable[1] ? write_data[15:8]  : memory[addr][15:8],
                write_enable[0] ? write_data[7:0]   : memory[addr][7:0]
            }
        ) : memory[addr];
    end
end

endmodule

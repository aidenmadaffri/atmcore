module imem (
    input clk,
    input reset,
    input logic [15:0] addr, 
    input logic stall,
    output logic [31:0] data
);

logic [31:0] memory [0:16383]; // 64KB instruction memory (16K instructions)

// Initialize instruction memory with some values
initial begin
    // Load some instructions into memory
    memory[0] = 32'h00200093; // ADDI x1, x0, 2
    memory[1] = 32'h00000013; // NOP
    memory[2] = 32'h00000013; // NOP
    memory[3] = 32'h00000013; // NOP
    memory[4] = 32'h00000013; // NOP
    memory[5] = 32'h00000013; // NOP
    memory[6] = 32'h00000013; // NOP
    memory[7] = 32'h00000013; // NOP
    memory[8] = 32'h00000013; // NOP
    memory[9] = 32'h00000013; // NOP
    memory[10] = 32'h00000013; // NOP
    memory[11] = 32'h00000013; // NOP
    memory[12] = 32'h00000013; // NOP
    // ... more instructions
end

always_ff @(posedge clk) begin
    if (reset) begin
        data <= 32'h00000013; // NOP
    end else if (!stall) begin
        data <= memory[addr[15:2]]; // Use addr[15:2] for word addressing
    end
end
endmodule

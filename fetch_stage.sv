
module fetch_stage (
    input logic clk,
    input logic reset,

    input logic branch_taken,
    input logic [15:0] target_pc,
    input logic fetch_stall,
    input logic decode_stall,

    output logic [15:0] decode_pc,
    output logic decode_valid,
    output logic [15:0] inst_addr
);

logic [15:0] pc;
assign inst_addr = pc; // Instruction address is the current PC

logic [15:0] npc;
logic fetch_valid;
// NPC and Valid Logic
always_comb begin
    if (branch_taken) begin
        npc = target_pc; // Branch taken, use target PC
        fetch_valid = 1'b0; // will be valid on the next cycle
    end
    else if (fetch_stall) begin
        npc = pc; // If stalled, keep the current PC
        fetch_valid = 1'b0; // Not valid if stalled
    end
    else if (decode_stall) begin
        npc = pc; // If decode is stalled, keep the current PC
        fetch_valid = 1'b0; // Not valid if decode is stalled --> doesn't matter
    end
    else begin
        npc = pc + 4; // Normal increment
        fetch_valid = 1'b1;
    end
end

always_ff @(posedge clk) begin
    if (reset) begin
        pc <= 16'h0;
        decode_valid <= 1'b0;
    end
    else begin
        pc <= npc;
        if (!decode_stall) begin
            decode_valid <= fetch_valid;
            decode_pc <= pc;
        end
    end
end
    
endmodule

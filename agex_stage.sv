`include "alu_ops.sv"
`include "constants.sv"


module agex_stage (
    input logic clk,

    input logic [15:0] agex_pc,
    input logic agex_valid,
    input logic [31:0] agex_rs1,
    input logic [31:0] agex_rs2,
    input logic [4:0] agex_drnum,
    input logic [31:0] agex_imm,
    input logic agex_reg_we,

    input logic [`INST_OP_WIDTH-1:0] agex_inst_op,
    input logic [`ALU_OP_WIDTH-1:0] agex_alu_op,
    input logic [`DATA_SIZE_WIDTH-1:0] agex_data_size, 
    input logic [`EXTEND_TYPE_WIDTH-1:0] agex_extend_type, 

    output logic [15:0] agex_addr,

    output logic mem_valid,
    output logic [4:0] mem_drnum,
    output logic [15:0] mem_addr,
    output logic [31:0] mem_alu_result,
    output logic mem_reg_we,

    output logic [`INST_OP_WIDTH-1:0] mem_inst_op,
    output logic [`DATA_SIZE_WIDTH-1:0] mem_data_size, 
    output logic [`EXTEND_TYPE_WIDTH-1:0] mem_extend_type
);
// Addr
always_comb begin
    logic [31:0] temp_addr; // Use 32-bit for calculations
    case (agex_inst_op)
        `INST_OP_LOAD: temp_addr = agex_rs1 + {{20{agex_imm[11]}}, agex_imm[11:0]};
        `INST_OP_STORE: temp_addr = agex_rs1 + {{20{agex_imm[11]}}, agex_imm[11:0]};
        `INST_OP_BRANCH: temp_addr = {16'd0, agex_pc} + {{19{agex_imm[11]}}, agex_imm[12:1], 1'd0};
        `INST_OP_JAL: temp_addr = {16'd0, agex_pc} + {{11{agex_imm[11]}}, agex_imm[20:1], 1'd0};
        `INST_OP_JALR: temp_addr = (agex_rs1 + {{20{agex_imm[11]}}, agex_imm[11:0]}) & ~1;
        default: temp_addr = 0;
    endcase
    agex_addr = temp_addr[15:0]; // Truncate to 16-bit
end


// Result
logic [31:0] alu_in1;
logic [31:0] alu_in2;
logic [31:0] alu_out;
logic [31:0] agex_alu_result;
alu result_alu (.in1(alu_in1), .in2(alu_in2), .out(alu_out), .op(agex_alu_op));
always_comb begin
    alu_in1 = agex_rs1;
    alu_in2 = agex_rs2;
    agex_alu_result = alu_out;
    if (agex_inst_op == `INST_OP_ALU_I) alu_in2 = {{20{agex_imm[11]}}, agex_imm[11:0]};
    if (agex_inst_op == `INST_OP_LUI) agex_alu_result = agex_imm;
    if (agex_inst_op == `INST_OP_AUIPC) begin
        alu_in1 = {16'd0, agex_pc};
        alu_in2 = agex_imm;
    end
    if (agex_inst_op == `INST_OP_JAL || agex_inst_op == `INST_OP_JALR) agex_alu_result = {16'd0, agex_pc} + 4;
    if (agex_inst_op == `INST_OP_STORE) agex_alu_result = agex_rs2;
end

always_ff @(posedge clk) begin
    mem_valid <= agex_valid;
    mem_drnum <= agex_drnum;
    mem_addr <= agex_addr;
    mem_alu_result <= agex_alu_result;
    mem_reg_we <= agex_valid && agex_reg_we;
    mem_inst_op <= agex_inst_op;
    mem_data_size <= agex_data_size;
    mem_extend_type <= agex_extend_type;
end
    
endmodule

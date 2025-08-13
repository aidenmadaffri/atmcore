`include "alu_ops.sv"
`include "constants.sv"

module top (
    input clk,
    input reset
);


logic [15:0] inst_addr;

logic [15:0] decode_pc;
logic decode_valid;
logic [31:0] decode_inst;
logic [4:0] decode_rs1_num; // is zero if unused by the instruction
logic [4:0] decode_rs2_num; // is zero if unused by the instruction
logic [31:0] decode_rs1_data;
logic [31:0] decode_rs2_data;
logic [`INST_OP_WIDTH-1:0] decode_inst_op;

logic [15:0] agex_pc;
logic agex_valid;
logic [31:0] agex_rs1;
logic [31:0] agex_rs2;
logic [4:0] agex_drnum;
logic [31:0] agex_imm;
logic agex_reg_we;
logic [`INST_OP_WIDTH-1:0] agex_inst_op;
logic [`ALU_OP_WIDTH-1:0] agex_alu_op;
logic [`DATA_SIZE_WIDTH-1:0] agex_data_size;
logic [`EXTEND_TYPE_WIDTH-1:0] agex_extend_type;
logic [15:0] agex_addr;

logic mem_valid;
logic [4:0] mem_drnum;
logic [15:0] mem_addr;
logic [31:0] mem_alu_result;
logic [31:0] dmem_read_data;
logic mem_reg_we;
logic [`INST_OP_WIDTH-1:0] mem_inst_op;
logic [`DATA_SIZE_WIDTH-1:0] mem_data_size;
logic [`EXTEND_TYPE_WIDTH-1:0] mem_extend_type;

logic [15:0] mem_target_pc;
logic [3:0] mem_dmem_we;
logic [31:0] mem_reg_data;
logic mem_branch_taken;

logic decode_stall;
logic fetch_stall;
assign decode_stall = (agex_valid && agex_reg_we && agex_drnum != 5'd0 && (agex_drnum == decode_rs1_num || agex_drnum == decode_rs2_num));
assign fetch_stall = (decode_valid && (decode_inst_op == `INST_OP_BRANCH || decode_inst_op == `INST_OP_JAL || decode_inst_op == `INST_OP_JALR)) ||
                        (agex_valid && (agex_inst_op == `INST_OP_BRANCH || agex_inst_op == `INST_OP_JAL || agex_inst_op == `INST_OP_JALR));
 

fetch_stage fetch_stage_inst (
    .clk(clk),
    .reset(reset),
    .branch_taken(mem_branch_taken),
    .target_pc(mem_target_pc),
    .fetch_stall(fetch_stall),
    .decode_stall(decode_stall),
    .decode_pc(decode_pc),
    .decode_valid(decode_valid),
    .inst_addr(inst_addr)
);

decode_stage decode_stage_inst (
    .clk(clk),
    .decode_stall(decode_stall),
    .decode_valid(decode_valid),
    .decode_pc(decode_pc),
    .decode_inst(decode_inst),
    .decode_rs1_data(decode_rs1_data),
    .decode_rs2_data(decode_rs2_data),
    .decode_rs1_num(decode_rs1_num),
    .decode_rs2_num(decode_rs2_num),
    .decode_inst_op(decode_inst_op),
    .agex_pc(agex_pc),
    .agex_valid(agex_valid),
    .agex_rs1(agex_rs1),
    .agex_rs2(agex_rs2),
    .agex_drnum(agex_drnum),
    .agex_imm(agex_imm),
    .agex_reg_we(agex_reg_we),
    .agex_inst_op(agex_inst_op),
    .agex_alu_op(agex_alu_op),
    .agex_data_size(agex_data_size),
    .agex_extend_type(agex_extend_type)
);

agex_stage agex_stage_inst (
    .clk(clk),
    .agex_pc(agex_pc),
    .agex_valid(agex_valid),
    .agex_rs1(agex_rs1),
    .agex_rs2(agex_rs2),
    .agex_drnum(agex_drnum),
    .agex_imm(agex_imm),
    .agex_reg_we(agex_reg_we),
    .agex_inst_op(agex_inst_op),
    .agex_alu_op(agex_alu_op),
    .agex_data_size(agex_data_size),
    .agex_extend_type(agex_extend_type),
    .agex_addr(agex_addr),
    .mem_valid(mem_valid),
    .mem_drnum(mem_drnum),
    .mem_addr(mem_addr),
    .mem_alu_result(mem_alu_result),
    .mem_reg_we(mem_reg_we),
    .mem_inst_op(mem_inst_op),
    .mem_data_size(mem_data_size),
    .mem_extend_type(mem_extend_type)
);

mem_stage mem_stage_inst (
    .clk(clk),
    .mem_valid(mem_valid),
    .mem_drnum(mem_drnum),
    .mem_addr(mem_addr),
    .mem_alu_result(mem_alu_result),
    .dmem_read_data(dmem_read_data),
    .mem_reg_we(mem_reg_we),
    .mem_inst_op(mem_inst_op),
    .mem_data_size(mem_data_size),
    .mem_extend_type(mem_extend_type),
    .mem_target_pc(mem_target_pc),
    .mem_dmem_we(mem_dmem_we),
    .mem_reg_data(mem_reg_data),
    .mem_branch_taken(mem_branch_taken)
);

register_file regfile (
    .clk(clk),
    .reset(reset),
    .read_reg1(decode_rs1_num),
    .read_reg2(decode_rs2_num),
    .read_data1(decode_rs1_data),
    .read_data2(decode_rs2_data),
    .write_reg(mem_drnum),
    .write_data(mem_reg_data),
    .write_enable(mem_reg_we)
);

imem imem_inst (
    .clk(clk),
    .reset(reset),
    .addr(inst_addr), // Use 16-bit address
    .stall(decode_stall),
    .data(decode_inst)
);

dmem dmem_inst (
    .clk(clk),
    .reset(reset),
    .addr(mem_addr),
    .write_data(mem_alu_result),
    .write_enable(mem_dmem_we),
    .read_data(dmem_read_data)
);

endmodule

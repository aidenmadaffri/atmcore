`include "alu_ops.sv"
`include "constants.sv"


module mem_stage (
    input logic clk,

    input logic mem_valid,
    input logic [4:0] mem_drnum,
    input logic [15:0] mem_addr,
    input logic [31:0] mem_alu_result,
    input logic [31:0] dmem_read_data,
    input logic mem_reg_we,

    input logic [`INST_OP_WIDTH-1:0] mem_inst_op,
    input logic [`DATA_SIZE_WIDTH-1:0] mem_data_size, 
    input logic [`EXTEND_TYPE_WIDTH-1:0] mem_extend_type, 

    output logic [15:0] mem_target_pc,
    output logic [3:0] mem_dmem_we,
    output logic [31:0] mem_reg_data,
    output logic mem_branch_taken
);
// Target PC
assign mem_target_pc = mem_addr;

assign mem_branch_taken = mem_valid && ((mem_inst_op == `INST_OP_BRANCH) && (mem_alu_result == 1)) || (mem_inst_op == `INST_OP_JAL) || (mem_inst_op == `INST_OP_JALR);

// Mem WE
assign mem_dmem_we[0] = mem_valid && (mem_inst_op == `INST_OP_STORE);
assign mem_dmem_we[1] = mem_valid && (mem_inst_op == `INST_OP_STORE) && (mem_data_size == `DATA_SIZE_HALF || mem_data_size == `DATA_SIZE_WORD);
assign mem_dmem_we[2] = mem_valid && (mem_inst_op == `INST_OP_STORE) && (mem_data_size == `DATA_SIZE_WORD);
assign mem_dmem_we[3] = mem_valid && (mem_inst_op == `INST_OP_STORE) && (mem_data_size == `DATA_SIZE_WORD);

// Reg Data
always_comb begin
    mem_reg_data = 0;
    case (mem_inst_op)
        `INST_OP_LOAD: begin
            if (mem_data_size == `DATA_SIZE_BYTE) begin
                if (mem_extend_type == `SIGN_EXTEND) mem_reg_data = {{24{dmem_read_data[7]}}, dmem_read_data[7:0]};
                else mem_reg_data = {24'd0, dmem_read_data[7:0]};
            end
            else if (mem_data_size == `DATA_SIZE_HALF) begin
                if (mem_extend_type == `SIGN_EXTEND) mem_reg_data = {{16{dmem_read_data[15]}}, dmem_read_data[15:0]};
                else mem_reg_data = {16'd0, dmem_read_data[15:0]};
            end
            else mem_reg_data = dmem_read_data;
        end
        default: mem_reg_data = mem_alu_result;
    endcase
end
    
endmodule

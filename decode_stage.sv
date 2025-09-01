`include "alu_ops.sv"
`include "constants.sv"


module decode_stage (
    input logic clk,

    input logic decode_stall,
    input logic decode_valid,
    input logic [15:0] decode_pc,
    input logic [31:0] decode_inst,

    input logic [31:0] decode_rs1_data,
    input logic [31:0] decode_rs2_data,

    output logic [4:0] decode_rs1_num,
    output logic [4:0] decode_rs2_num,

    output logic [`INST_OP_WIDTH-1:0] decode_inst_op,

    output logic [15:0] agex_pc,
    output logic agex_valid,
    output logic [31:0] agex_rs1,
    output logic [31:0] agex_rs2,
    output logic [4:0] agex_drnum,
    output logic [31:0] agex_imm,
    output logic agex_reg_we,

    output logic [`INST_OP_WIDTH-1:0] agex_inst_op,
    output logic [`ALU_OP_WIDTH-1:0] agex_alu_op,
    output logic [`DATA_SIZE_WIDTH-1:0] agex_data_size, 
    output logic [`EXTEND_TYPE_WIDTH-1:0] agex_extend_type
);


// Instruction Type
always_comb begin
    case (decode_inst[6:0])
        7'b0110011: decode_inst_op = `INST_OP_ALU_R;
        7'b0010011: decode_inst_op = `INST_OP_ALU_I;
        7'b0000011: decode_inst_op = `INST_OP_LOAD;
        7'b1100111: decode_inst_op = `INST_OP_JALR;
        7'b0100011: decode_inst_op = `INST_OP_STORE;
        7'b1100011: decode_inst_op = `INST_OP_BRANCH;
        7'b0110111: decode_inst_op = `INST_OP_LUI;
        7'b0010111: decode_inst_op = `INST_OP_AUIPC;
        7'b1101111: decode_inst_op = `INST_OP_JAL;
        default: decode_inst_op = `INST_OP_INVALID;
    endcase
end

// RS Nums (zero means unused)
assign decode_rs1_num = (decode_inst_op != `INST_OP_LUI && decode_inst_op != `INST_OP_AUIPC && decode_inst_op != `INST_OP_JAL) ? decode_inst[19:15] : 5'b0;
assign decode_rs2_num = (decode_inst_op == `INST_OP_ALU_R || decode_inst_op == `INST_OP_STORE) ? decode_inst[24:20] : 5'b0;

// Immediate Value
logic [31:0] decode_imm;
always_comb begin
    case (decode_inst_op)
        `INST_OP_STORE: decode_imm = {{20{decode_inst[31]}}, decode_inst[31:25], decode_inst[11:7]};
        `INST_OP_BRANCH: decode_imm = {{20{decode_inst[31]}}, decode_inst[7], decode_inst[30:25], decode_inst[11:8], 1'b0};
        `INST_OP_LUI: decode_imm = {decode_inst[31:12], 12'b0};
        `INST_OP_AUIPC: decode_imm = {decode_inst[31:12], 12'b0}; 
        `INST_OP_JAL: decode_imm = {{12{decode_inst[31]}}, decode_inst[19:12], decode_inst[20], decode_inst[30:21], 1'b0};
        default: decode_imm = {{20{decode_inst[31]}}, decode_inst[31:20]}; // I-type instructions
    endcase
end

// Func3 Decoding
logic [`ALU_OP_WIDTH-1:0] decode_alu_op;
logic [`DATA_SIZE_WIDTH-1:0] decode_data_size;
logic [`EXTEND_TYPE_WIDTH-1:0] decode_extend_type;
always_comb begin
    decode_alu_op = `ALU_OP_INVALID;
    decode_data_size = `DATA_SIZE_WORD;
    decode_extend_type = `ZERO_EXTEND;
    if (decode_inst_op == `INST_OP_BRANCH) begin
        case (decode_inst[14:12])
            3'b000: decode_alu_op = `ALU_OP_EQ;
            3'b001: decode_alu_op = `ALU_OP_NEQ;
            3'b100: decode_alu_op = `ALU_OP_SLT;
            3'b101: decode_alu_op = `ALU_OP_SLTU;
            3'b110: decode_alu_op = `ALU_OP_SGE;
            3'b111: decode_alu_op = `ALU_OP_SGEU;
            default: decode_alu_op = `ALU_OP_INVALID;
        endcase
    end
    else if (decode_inst_op == `INST_OP_ALU_R || decode_inst_op == `INST_OP_ALU_I) begin
        case (decode_inst[14:12])
            3'b000: decode_alu_op = ((decode_inst_op == `INST_OP_ALU_R && decode_inst[30]) ? `ALU_OP_SUB : `ALU_OP_ADD);
            3'b001: decode_alu_op = `ALU_OP_SLL;
            3'b010: decode_alu_op = `ALU_OP_SLT;
            3'b011: decode_alu_op = `ALU_OP_SLTU;
            3'b100: decode_alu_op = `ALU_OP_XOR;
            3'b101: decode_alu_op = (decode_inst[30] ? `ALU_OP_SRA : `ALU_OP_SRL);
            3'b110: decode_alu_op = `ALU_OP_OR;
            3'b111: decode_alu_op = `ALU_OP_AND;
            default: decode_alu_op = `ALU_OP_INVALID;
        endcase
    end
    else if (decode_inst_op == `INST_OP_LOAD) begin
        case (decode_inst[14:12])
            3'b000: begin // LB
                decode_data_size = `DATA_SIZE_BYTE;
                decode_extend_type = `SIGN_EXTEND;
            end
            3'b001: begin // LH
                decode_data_size = `DATA_SIZE_HALF;
                decode_extend_type = `SIGN_EXTEND;
            end
            3'b010: begin // LW
                decode_data_size = `DATA_SIZE_WORD;
                decode_extend_type = `ZERO_EXTEND;
            end
            3'b100: begin // LBU
                decode_data_size = `DATA_SIZE_BYTE;
                decode_extend_type = `ZERO_EXTEND;
            end
            3'b101: begin // LHU
                decode_data_size = `DATA_SIZE_HALF;
                decode_extend_type = `ZERO_EXTEND;
            end
            default: begin
                decode_data_size = `DATA_SIZE_WORD;
                decode_extend_type = `ZERO_EXTEND;
            end
        endcase
    end
    else if (decode_inst_op == `INST_OP_STORE) begin
        case (decode_inst[14:12])
            3'b000: decode_data_size = `DATA_SIZE_BYTE;
            3'b001: decode_data_size = `DATA_SIZE_HALF;
            3'b010: decode_data_size = `DATA_SIZE_WORD;
            default: decode_data_size = `DATA_SIZE_WORD;
        endcase
    end
end

always_ff @(posedge clk) begin
    agex_pc <= decode_pc;
    agex_valid <= decode_valid && !decode_stall;
    agex_rs1 <= decode_rs1_data;
    agex_rs2 <= decode_rs2_data;
    agex_drnum <= decode_inst[11:7];
    agex_inst_op <= decode_inst_op;
    agex_reg_we <= (decode_inst_op == `INST_OP_ALU_R || decode_inst_op == `INST_OP_ALU_I || 
                        decode_inst_op == `INST_OP_LOAD || decode_inst_op == `INST_OP_JALR || 
                        decode_inst_op == `INST_OP_JAL || decode_inst_op == `INST_OP_LUI || 
                        decode_inst_op == `INST_OP_AUIPC);
    agex_imm <= decode_imm;
    agex_alu_op <= decode_alu_op;
    agex_data_size <= decode_data_size;
    agex_extend_type <= decode_extend_type;
end
    
endmodule

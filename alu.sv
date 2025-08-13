`include "alu_ops.sv"

module alu (
    input logic [`ALU_OP_WIDTH-1:0] op,
    input logic [31:0] in1,
    input logic [31:0] in2,
    output logic [31:0] out
);

always_comb begin
    case (op)
        `ALU_OP_ADD:  out = in1 + in2;
        `ALU_OP_SLL:  out = in1 << in2[4:0];
        `ALU_OP_SLT:  out = {31'd0, $signed(in1) < $signed(in2)};
        `ALU_OP_SLTU: out = {31'd0, in1 < in2};
        `ALU_OP_XOR:  out = in1 ^ in2;
        `ALU_OP_SRL:  out = in1 >> in2[4:0];
        `ALU_OP_OR:   out = in1 | in2;
        `ALU_OP_AND:  out = in1 & in2;
        `ALU_OP_SUB:  out = in1 - in2;
        `ALU_OP_SRA:  out = $signed(in1) >>> in2[4:0];
        `ALU_OP_EQ:   out = {31'd0, in1 == in2};
        `ALU_OP_NEQ:  out = {31'd0, in1 != in2};
        `ALU_OP_SGE:  out = {31'd0, $signed(in1) >= $signed(in2)};
        `ALU_OP_SGEU: out = {31'd0, in1 >= in2};
        default: out =  0;
    endcase
end
    
endmodule

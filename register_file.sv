module register_file(
    input logic clk,
    input logic reset,
    input logic [4:0] read_reg1,
    input logic [4:0] read_reg2,
    output logic [31:0] read_data1,
    output logic [31:0] read_data2,
    input logic [4:0] write_reg,
    input logic [31:0] write_data,
    input logic write_enable
);
    logic [31:0] registers [31:0];

    always_ff @(posedge clk) begin
        if (reset) begin
            for (int i = 0; i < 32; i++) begin
                registers[i] <= 32'b0;
            end
        end else if (write_enable && write_reg != 0) begin
            registers[write_reg] <= write_data;
        end
    end
    

    logic [31:0] reg_data1;
    logic [31:0] reg_data2;
    always_comb begin
        reg_data1 = registers[read_reg1];
        reg_data2 = registers[read_reg2];

        if (read_reg1 == write_reg && write_enable) reg_data1 = write_data;
        else if (read_reg2 == write_reg && write_enable) reg_data2 = write_data;

        if (read_reg1 == 0) reg_data1 = 0;
        if (read_reg2 == 0) reg_data2 = 0;

        read_data1 = reg_data1;
        read_data2 = reg_data2;
    end

endmodule

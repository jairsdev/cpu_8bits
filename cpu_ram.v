module cpu_ram (
    input clk,
    input mem_enable,
    input [7:0] adress,
    input [7:0] din,
    output [7:0] dout_ram
);
    reg [7:0] ram [0:255];
    integer i;

    initial begin
        for (i = 0; i < 256; i = i + 1) begin
            ram[i] = 8'b0;
        end
        // vetores carregados para testes
        ram[8'h0a] = 2;
        ram[8'h0b] = 3;
        ram[8'h0c] = 4;
        ram[8'h0d] = 5;
        ram[8'h0e] = 6;

        ram[8'h80] = 1;
        ram[8'h81] = 2;
        ram[8'h82] = 3;
        ram[8'h83] = 4;
        ram[8'h84] = 5;
    end

    always @(posedge clk) begin
        if (mem_enable) begin
            ram[adress] <= din;
        end
    end
    
    assign dout_ram = ram[adress];
endmodule
module cpu_register_file (
    input clk,
    input reset,
    input we,
    input [7:0] wd, //c, acc ou dout da memoria ram
    input [2:0] wa,
    input [2:0] ra,
    input [2:0] rb,
    output [7:0] rda,
    output [7:0] rdb,
    output [7:0] out_acc,
    output [7:0] out_count
);
    reg [7:0] registers [0:4];
    integer i;

    always @(posedge clk) begin
        if (reset) begin
            for (i = 0; i < 5; i = i + 1) begin
                registers[i] <= 8'b0;
            end
        end else begin
            if (we) begin
                registers[wa] <= wd;
            end
        end
    end
    
    assign rda = registers[ra];
    assign rdb = registers[rb];
    assign out_acc = registers[3];
    assign out_count = registers[4];

endmodule
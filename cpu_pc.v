module cpu_pc (
    input clk,
    input reset,
    input jumper,
    input increment,
    input [7:0] jumper_d,
    output reg [7:0] mem_adress_out
);

    always @(posedge clk) begin
        if (reset) begin
            mem_adress_out <= 0;
        end else begin
            if (jumper) begin
                mem_adress_out <= jumper_d;
            end else if (increment) begin
                mem_adress_out <= mem_adress_out + 1;
            end
        end
    end
endmodule
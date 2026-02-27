module cpu_alu (
    input [7:0] a,
    input [7:0] b,
    input [3:0] ope,
    input Cin,
    output reg [7:0] result,
    output reg Z_flag,
    output reg C_flag
);
    reg Cout;

    //operações
    localparam ADD = 4'b0001;
    localparam SUB = 4'b0010;
    localparam AND = 4'b0011;
    localparam OR = 4'b0100;
    localparam ADC = 4'b0101;
    localparam XOR = 4'b0110;
    localparam SHL = 4'b0111;
    localparam SHR = 4'b1000;
    localparam NOTA = 4'b1001;
    localparam NOTB = 4'b1010;


    always @(*) begin
        case (ope)
            ADD : begin
                {Cout, result} = a + b;
            end

            SUB : begin
                {Cout, result} = a + (~b) + 1;
            end

            AND : begin
                result = a & b;
                Cout = 0;
            end

            OR : begin
                result = a | b;
                Cout = 0;
            end

            ADC : begin
                {Cout, result} = a + b + Cin;
            end

            XOR : begin
                result = a ^ b;
                Cout = 0;
            end

            SHL : begin
                result = a << 1;
                Cout = 0;
            end

            SHR : begin
                result = a >> 1;
                Cout = 0;
            end

            NOTA : begin
                result = ~a;
                Cout = 0;
            end

            NOTB : begin
                result = ~b;
                Cout = 0;
            end

            default: begin
                result = 0;
                Cout = 0;
            end
        endcase

        C_flag = Cout;
        Z_flag = {result == 0};
    end
    
endmodule
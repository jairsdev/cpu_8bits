module cpu_rom (
    input [7:0] adress,
    output [7:0] dout_rom
);
    reg [7:0] rom [0:255];

    initial begin
        $readmemh("add_carry.hex", rom);
    end
    
    assign dout_rom = rom[adress];
endmodule
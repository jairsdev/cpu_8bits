module cpu (
    input clk,
    input reset,
    output reg [7:0] ir,
    output reg [7:0] operand_reg,
    output reg [7:0] alu_out_reg,
    output reg Z_flag_reg,
    output reg C_flag_reg,
    output reg [7:0] sp
);
    wire Z_flag;
    wire C_flag;
    wire load_ir;
    wire load_rom;
    wire push;
    wire pop;
    wire jumper;
    wire increment;
    wire [3:0] ope;
    wire we;
    wire mem_enable;
    wire [1:0] reg_sel;
    wire [1:0] reg_write_source_sel;
    wire [1:0] ram_read_source_sel;
    wire [1:0] alu_input_sel;
    wire [1:0] adress_sel;
    wire [7:0] dout_rom;
    wire [7:0] dout_ram;
    wire [7:0] mem_adress_out;
    wire [7:0] rda;
    wire [7:0] rdb;
    wire [7:0] out_acc;
    wire [7:0] out_count;
    wire [7:0] wd;
    wire [7:0] result_alu;
    wire [7:0] a;
    wire [7:0] b;
    wire [2:0] wa;
    wire [2:0] ra;
    wire [2:0] rb;
    wire [7:0] din;
    wire [7:0] adress;
    wire [7:0] jumper_d;
    wire pc_sel;

    //endereços dos regs
    localparam A = 3'b001;
    localparam B = 3'b010;
    localparam ACC = 3'b011;
    localparam COUNT = 3'b100;

    cpu_cu cu(.clk(clk), .reset(reset), .ir(ir), .Z_flag(Z_flag_reg), .C_flag(C_flag_reg), .load_ir(load_ir), .load_rom(load_rom), .jumper(jumper),
    .increment(increment), .ope(ope), .we(we), .mem_enable(mem_enable), .reg_sel(reg_sel), .reg_write_source_sel(reg_write_source_sel),
    .ram_read_source_sel(ram_read_source_sel), .adress_sel(adress_sel), .alu_input_sel(alu_input_sel), .push(push), .pop(pop),
    .pc_sel(pc_sel));
    cpu_pc pc(.clk(clk), .reset(reset), .jumper(jumper), .increment(increment), .jumper_d(jumper_d), .mem_adress_out(mem_adress_out));
    cpu_rom rom(.adress(mem_adress_out), .dout_rom(dout_rom));
    cpu_register_file register_file(.clk(clk), .reset(reset), .we(we), .wd(wd), .wa(wa), .ra(ra), .rb(rb), .rda(rda), .rdb(rdb), .out_acc(out_acc), .out_count(out_count));
    cpu_ram ram(.clk(clk), .mem_enable(mem_enable), .adress(adress), .din(din), .dout_ram(dout_ram));
    cpu_alu alu(.a(a), .b(b), .Cin(C_flag_reg), .ope(ope), .result(result_alu), .C_flag(C_flag), .Z_flag(Z_flag));

    always @(posedge clk) begin
        if (reset) begin
            ir <= 0;
            sp <= 8'hff;
            alu_out_reg <= 0;
            Z_flag_reg <= 1;
            C_flag_reg <= 0;
        end else begin
            alu_out_reg <= result_alu;

            if (ope == 4'b0001 || ope == 4'b0010 || ope == 4'b0101) begin
                C_flag_reg <= C_flag;
                Z_flag_reg <= Z_flag;
            end

            if (load_ir) 
                ir <= dout_rom;
            
            if (load_rom) 
                operand_reg <= dout_rom;

            if (push == 1'b1)
                sp <= sp - 1;
            
            if (pop == 1'b1)
                sp <= sp + 1;
        end
    end

    assign ra = A;
    assign rb = B;

    assign a = (alu_input_sel == 2'b00) ? rda :
                (alu_input_sel == 2'b01) ? 1 :
                (alu_input_sel == 2'b10) ? out_acc :
                out_count;

    assign b = (alu_input_sel == 2'b00 || alu_input_sel == 2'b01) ? rdb :
                (alu_input_sel == 2'b10) ? rda :
                1;

    assign din = (ram_read_source_sel == 2'b00) ? rda :
                (ram_read_source_sel == 2'b01) ? rdb :
                (ram_read_source_sel == 2'b10) ? mem_adress_out :
                out_acc;

    assign wa = (reg_sel == 2'b00) ? A :
                (reg_sel == 2'b01) ? B :
                (reg_sel == 2'b10) ? ACC :
                COUNT;

    assign wd = (reg_write_source_sel == 2'b00) ? dout_ram :
                (reg_write_source_sel == 2'b01) ? operand_reg :
                (reg_write_source_sel == 2'b10) ? alu_out_reg :
                0;
    
    assign adress = (adress_sel == 2'b00) ? operand_reg :
                    (adress_sel == 2'b01) ? rdb :
                    sp;

    assign jumper_d = (pc_sel == 1'b0) ? operand_reg :
                        dout_ram;
    
endmodule
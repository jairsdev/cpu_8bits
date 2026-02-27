module cpu_cu (
    input clk,
    input reset,
    input [7:0] ir,
    input Z_flag, // indica se o resultado da alu é 0
    input C_flag, // overflow na operação de soma
    input [7:0] sp, // stack para sub rotinas
    output reg load_ir,
    output reg load_rom,
    output reg jumper,
    output reg increment,
    output reg [3:0] ope,
    output reg we,
    output reg mem_enable,
    output reg [1:0] reg_sel, // seletor de registrador
    output reg [1:0] reg_write_source_sel, // seletor do mux na entrada do banco de registradores
    output reg [1:0] ram_read_source_sel, // seletor do mux na entrada da memoria ram
    output reg [1:0] adress_sel, // seletor do endereço na ram (store, normal load or indirect load)
    output reg [1:0] alu_input_sel, // seleciona o valor de a e b na alu
    output reg push, // decrementa o sp para abrir espaço na pilha
    output reg pop, //incrementa o sp para retornar pro item anterior na pilha
    output reg pc_sel // seletor para a entrada no PC, caso seja necessario seleciona a saida na ram
);
    reg [4:0] state;
    wire [4:0] opcode;
    wire [2:0] reg_adress_ir;

    //estados
    localparam FETCH_OPCODE = 5'b00000; // busca a instrução na rom e carrega no registrador de instrução (ir)
    localparam DECODE = 5'b00001; // decodifica: usa os 5 primeiros bits como opcode e os 3 últimos como endereço de registrador
    localparam FETCH_OPERAND = 5'b00010; // para load, store e jump: busca o dado/endereço na rom usando o pc atual
    localparam EXECUTE_LD = 5'b00011; // carrega um valor da memória ram para um registrador
    localparam EXECUTE_ST = 5'b00100; // armazena o valor de um registrador na memória ram
    localparam EXECUTE_LDC = 5'b00101; // carrega uma constante (vinda da rom) diretamente em um registrador
    localparam EXECUTE_ADD = 5'b00110; // executa operação de soma
    localparam EXECUTE_JMP = 5'b00111; // altera o pc para o endereço alvo se a condição (z_flag) for satisfeita
    localparam EXECUTE_SUB = 5'b01000; // executa operação de subtração
    localparam EXECUTE_AND = 5'b01001; // executa operação lógica and (bit a bit)
    localparam EXECUTE_OR = 5'b01010; // executa operação lógica or (bit a bit)
    localparam EXECUTE_ADC = 5'b01011; // soma com carry (usado para criar números maiores que 8 bits, ex: 16 bits)
    localparam EXECUTE_XOR = 5'b01100; // executa operação lógica xor (ou exclusivo)
    localparam EXECUTE_SHL = 5'b01101; // shift left: desloca bits para a esquerda (multiplica por 2)
    localparam EXECUTE_SHR = 5'b01110; // shift right: desloca bits para a direita (divide por 2)
    localparam EXECUTE_NOT = 5'b01111; // inverte todos os bits (not) do registrador a ou b
    localparam EXECUTE_JC = 5'b10000; // pula para o endereço alvo se houver carry (c_flag for 1)
    localparam EXECUTE_PUSH = 5'b10001; // finaliza o call: atualiza o sp após salvar o pc
    localparam EXECUTE_POP = 5'b10010; // retorno: incrementa o stack pointer (sp) para buscar o endereço de volta
    localparam EXECUTE_LD_RET = 5'b10011; // carrega o endereço de retorno (lido da pilha) de volta para o pc
    localparam EXECUTE_CALL = 5'b10100; // chamada: salva o pc atual na pilha (ram no endereço sp) e prepara o pulo
    localparam EXECUTE_DJNZ = 5'b10101; // decrementa o contador e pula se o resultado não for zero (usado para loops)
    localparam HALTED = 5'b10110; // estado de parada total da cpu (trava a execução até o reset)
    localparam WRITE_BACK = 5'b10111; // escreve o resultado final da operação no registrador de destino

    //opcodes
    localparam OP_ADD = 5'b00001;
    localparam OP_SUB = 5'b00010;
    localparam OP_LD = 5'b00011;
    localparam OP_ST = 5'b00100;
    localparam OP_LDC = 5'b00101; 
    localparam OP_JMP = 5'b00110;
    localparam OP_AND = 5'b00111;
    localparam OP_OR = 5'b01000;
    localparam OP_JC = 5'b01001;
    localparam OP_ADC = 5'b01010;
    localparam OP_XOR = 5'b01011;
    localparam OP_NOT = 5'b01100;
    localparam OP_SHL = 5'b01101;
    localparam OP_SHR = 5'b01110;
    localparam OP_LD_IND = 5'b01111; // carrega ram[b] no reg a (pode ser utilizado para vetores)
    localparam OP_ST_IND = 5'b11000;
    localparam OP_INC_B = 5'b10000; // adiciona 1 no valor de reg b
    localparam OP_ADD_A = 5'b10001; // acumula o valor no reg a (pode ser utilizado para somar valores de um vetor)
    localparam OP_DJNZ = 5'b10010; // decrementa o contador e executa o jump se o resultado não for igual a 0 (pode ser utilizado para loops)
    localparam OP_CALL = 5'b10011;
    localparam OP_RET = 5'b10100;
    localparam OP_PUSH = 5'b10101;
    localparam OP_POP = 5'b10110;
    localparam OP_HALT = 5'b10111;

    //endereços dos regs
    localparam A = 3'b001;
    localparam B = 3'b010;
    localparam ACC = 3'b011;
    localparam COUNT = 3'b100;
    localparam SP = 3'b110;

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

    assign opcode = ir[7:3];
    assign reg_adress_ir = ir[2:0];

    always @(*) begin
        load_ir = 0;
        load_rom = 0;
        mem_enable = 0;
        we = 0;
        increment = 0;
        jumper = 0;
        reg_sel = 0;
        ope = 0;
        reg_write_source_sel = 0;
        ram_read_source_sel = 0;
        adress_sel = 0;
        alu_input_sel = 0;
        pc_sel = 0;
        pop = 0;
        push = 0;

        case (state)
            FETCH_OPCODE : begin
                load_rom = 1'b1;
                load_ir = 1'b1;
                increment = 1'b1;
            end

            FETCH_OPERAND : begin
                load_rom = 1'b1;
                increment = 1'b1;
            end

            EXECUTE_ADD : begin
                if (opcode == OP_ADD) begin
                    alu_input_sel = 2'b00; //rda e rdb
                end else if (opcode == OP_INC_B) begin
                    alu_input_sel = 2'b01; //rdb e 1
                end else begin
                    alu_input_sel = 2'b10; //acc e a
                end

                ope = ADD;
            end

            EXECUTE_SUB : begin
                if (opcode == OP_SUB) begin
                    alu_input_sel = 2'b00;
                end else begin // DJNZ
                    alu_input_sel = 2'b11; //count e 1
                end
                ope = SUB;
            end

            EXECUTE_AND : begin
                ope = AND;
            end

            EXECUTE_OR : begin
                ope = OR;
            end

            EXECUTE_ADC : begin
                ope = ADC;
            end

            EXECUTE_XOR : begin
                ope = XOR;
            end

            EXECUTE_NOT: begin
                if (reg_adress_ir == A) begin
                    ope = NOTA;
                end else if (reg_adress_ir == B) begin
                    ope = NOTB;
                end else begin
                    ope = 0;
                end
            end

            EXECUTE_SHL : begin
                ope = SHL;
            end

            EXECUTE_SHR : begin
                ope = SHR;
            end

            EXECUTE_LD : begin
                
            end

            EXECUTE_ST : begin
                if (reg_adress_ir == A) begin
                    ram_read_source_sel = 2'b00; // reg a para a entrada da ram
                end else if (reg_adress_ir == B) begin
                    ram_read_source_sel = 2'b01; // reg b
                end else if (reg_adress_ir == SP) begin
                    ram_read_source_sel = 2'b10; // PC
                end else if (reg_adress_ir == ACC) begin
                    ram_read_source_sel = 2'b11; // reg acc
                end

                if (opcode == OP_PUSH || reg_adress_ir == SP) begin
                    adress_sel = 2'b10; // SP
                end else if (opcode == OP_ST_IND) begin
                    adress_sel = 2'b01; // rdb
                end else begin
                    adress_sel = 2'b00; // direct load com o operador
                end

                mem_enable = 1'b1;
            end

            EXECUTE_LDC : begin
                
            end

            EXECUTE_JMP : begin
                pc_sel = 1'b0;
                if (Z_flag) begin
                    jumper = 1'b1;
                end else begin
                    jumper = 1'b0;
                end
            end

            EXECUTE_DJNZ : begin
                pc_sel = 1'b0;
                if (!Z_flag) begin
                    jumper = 1'b1;
                end else begin
                    jumper = 1'b0;
                end
            end

            EXECUTE_JC : begin
                pc_sel = 1'b0;
                if (C_flag) begin
                    jumper = 1'b1;
                end else begin
                    jumper = 1'b0;
                end
            end

            EXECUTE_CALL : begin
                pc_sel = 1'b0;
                jumper = 1'b1;
            end

            EXECUTE_PUSH : begin
                push = 1'b1;
            end

            EXECUTE_POP : begin
                pop = 1'b1;
            end

            EXECUTE_LD_RET : begin
                adress_sel = 2'b10;
                pc_sel = 1'b1;
                jumper = 1'b1;
            end

            WRITE_BACK : begin
                if (reg_adress_ir == A) begin
                    reg_sel = 2'b00; // reg a selecionado
                end else if (reg_adress_ir == B) begin
                    reg_sel = 2'b01; // reg b selecionado
                end else if (reg_adress_ir == ACC) begin
                    reg_sel = 2'b10; // reg acc selecionado
                end else if (reg_adress_ir == COUNT) begin
                    reg_sel = 2'b11; // reg count selecionado
                end
                
                if (opcode == OP_LD || opcode == OP_LD_IND) begin
                    reg_write_source_sel = 2'b00; // seleciona dout_ram
                    if (opcode == OP_LD) begin
                        adress_sel = 2'b00; 
                    end else begin
                        adress_sel = 2'b01; //indirect load com rdb
                    end
                end else if (opcode == OP_LDC) begin
                    reg_write_source_sel = 2'b01; // constante no dout_rom
                end else if (opcode == OP_POP) begin
                    reg_write_source_sel = 2'b00;
                    adress_sel = 2'b10;
                end else begin
                    reg_write_source_sel = 2'b10; // resultado da alu
                end

                we = 1'b1;
            end

            default : begin
                we = 1'b0;
            end
        endcase
    end

    always @(posedge clk) begin
        if (reset) begin
            state <= FETCH_OPCODE;
        end else begin
            case (state)
                FETCH_OPCODE : begin
                    state <= DECODE;
                end

                DECODE : begin
                    if (opcode == OP_LD || opcode == OP_ST || opcode == OP_JMP || opcode == OP_LDC || opcode == OP_JC || opcode == OP_CALL) begin
                        state <= FETCH_OPERAND;
                    end else if (opcode == OP_ADD || opcode == OP_INC_B || opcode == OP_ADD_A) begin
                        state <= EXECUTE_ADD;
                    end else if (opcode == OP_SUB || opcode == OP_DJNZ) begin
                        state <= EXECUTE_SUB;
                    end else if (opcode == OP_AND) begin
                        state <= EXECUTE_AND;
                    end else if (opcode == OP_OR) begin
                        state <= EXECUTE_OR;
                    end else if (opcode == OP_ADC) begin
                        state <= EXECUTE_ADC;
                    end else if (opcode == OP_XOR) begin
                        state <= EXECUTE_XOR;
                    end else if (opcode == OP_NOT) begin
                        state <= EXECUTE_NOT;
                    end else if (opcode == OP_SHL) begin
                        state <= EXECUTE_SHL;
                    end else if (opcode == OP_SHR) begin
                        state <= EXECUTE_SHR;
                    end else if (opcode == OP_LD_IND) begin
                        state <= EXECUTE_LD;
                    end else if (opcode == OP_ST_IND) begin
                        state <= EXECUTE_ST;
                    end else if (opcode == OP_RET || opcode == OP_POP) begin
                        state <= EXECUTE_POP;
                    end else if (opcode == OP_HALT) begin
                        state <= HALTED;
                    end else if (opcode == OP_PUSH) begin
                        state <= EXECUTE_ST;
                    end else begin
                        state <= FETCH_OPCODE;
                    end
                end

                FETCH_OPERAND : begin
                    if (opcode == OP_LD) begin
                        state <= EXECUTE_LD;
                    end else if (opcode == OP_ST || opcode == OP_CALL) begin
                        state <= EXECUTE_ST;
                    end else if (opcode == OP_LDC) begin
                        state <= EXECUTE_LDC;
                    end else if (opcode == OP_JMP) begin
                        state <= EXECUTE_JMP;
                    end else if (opcode == OP_JC) begin
                        state <=  EXECUTE_JC;
                    end else if (opcode == OP_DJNZ) begin
						state <= EXECUTE_DJNZ;
					end else begin
                        state <= FETCH_OPCODE;
                    end
                end

                EXECUTE_ADD : begin
                    state <= WRITE_BACK;
                end

                EXECUTE_SUB : begin
                    state <=  WRITE_BACK;
                end

                EXECUTE_AND : begin
                    state <= WRITE_BACK;
                end

                EXECUTE_OR : begin
                    state <= WRITE_BACK;
                end

                EXECUTE_ADC : begin
                    state <= WRITE_BACK;
                end

                EXECUTE_XOR : begin
                    state <=  WRITE_BACK;
                end

                EXECUTE_NOT : begin
                    state <= WRITE_BACK;
                end

                EXECUTE_SHL : begin
                    state <= WRITE_BACK;
                end

                EXECUTE_SHR : begin
                    state <= WRITE_BACK;
                end

                EXECUTE_LD : begin
                    state <= WRITE_BACK;
                end

                EXECUTE_LDC : begin
                    state <= WRITE_BACK;
                end

                EXECUTE_ST : begin
                    if (opcode == OP_ST || opcode == OP_ST_IND) begin
                        state <= FETCH_OPCODE;
                    end else begin
                        state <= EXECUTE_PUSH;
                    end
                end

                EXECUTE_JMP : begin
                    state <= FETCH_OPCODE;
                end

                EXECUTE_DJNZ : begin
                    state <= FETCH_OPCODE;
                end

                EXECUTE_JC : begin
                    state <= FETCH_OPCODE;
                end

                EXECUTE_PUSH : begin
                    if (opcode == OP_PUSH) begin
                        state <= FETCH_OPCODE;
                    end else begin
                        state <= EXECUTE_CALL;
                    end
                end

                EXECUTE_CALL : begin
                    state <= FETCH_OPCODE;
                end

                EXECUTE_POP : begin
                    if (opcode == OP_RET) begin
                        state <= EXECUTE_LD_RET;
                    end else begin
                        state <= WRITE_BACK;
                    end
                end

                EXECUTE_LD_RET : begin
                    state <= FETCH_OPCODE;
                end

                WRITE_BACK : begin
                    if (opcode == OP_DJNZ) begin
                        state <= FETCH_OPERAND;
                    end else begin
                        state <= FETCH_OPCODE;
                    end
                end

                HALTED: begin
                    state <= HALTED;
                end

                default : state <= FETCH_OPCODE;
            endcase
        end
    end
endmodule
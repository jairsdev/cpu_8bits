`timescale 1ns / 100ps
module tb_cpu;
    reg clk;
    reg reset;

    cpu utt(.clk(clk), .reset(reset));

    initial begin
        clk = 0;
        forever #6 clk = ~clk;
    end

    initial begin
        reset = 1;
        
        #30; 
        
        reset = 0;
        
        #2000; 
        
        $stop; 
    end
endmodule
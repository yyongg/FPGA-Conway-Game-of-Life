`timescale 10ns / 1ps
`include "top.sv"

module top_tb;

    logic clk = 0;
    logic _31b;

    // shorter reset period so the sim runs fast
    top #(.RESET_TICK_RATE(200)) u0 (
        .clk  (clk),
        ._31b (_31b)
    );

    // ~12 MHz clock
    always #4.16 clk = ~clk;

    initial begin
        $dumpfile("top.vcd");
        $dumpvars(0, top_tb);
        #50000000; // 0.5s
        $finish;
    end

endmodule

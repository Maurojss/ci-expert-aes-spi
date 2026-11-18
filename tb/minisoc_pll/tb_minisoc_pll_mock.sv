// tb_minisoc_pll_mock.sv
// Testbench modular do minisoc_pll_mock (Semana 5).
// Verifica: reset, enable/lock com latencia pseudoaleatoria reprodutivel (modelo em
// LFSR dentro do proprio TB), divisores /1 /2 /4 /8, queda de locked e bloqueio de
// sys_clk na reconfiguracao e no disable, enable curto demais e reproducao apos reset.
// Pode rodar isolado (STANDALONE = 1) ou instanciado em tb_minisoc_w05 (STANDALONE = 0).

`timescale 1ns/1ps

module tb_minisoc_pll_mock #(
    parameter bit STANDALONE = 1'b1
);

    localparam logic [15:0] SEED      = 16'hACE1;
    localparam int          LOCK_MIN  = 8;
    localparam int          LOCK_BITS = 5;
    localparam int          LOCK_MAX  = LOCK_MIN + (1 << LOCK_BITS) - 1;
    localparam int          WINDOW    = 64;     // ciclos de clk por medicao de frequencia

    logic       clk     = 1'b0;
    logic       rst_n   = 1'b0;
    logic       enable  = 1'b0;
    logic [1:0] div_sel = 2'b00;
    logic       sys_clk;
    logic       locked;

    always #5 clk = ~clk;

    minisoc_pll_mock #(
        .SEED      (SEED),
        .LOCK_MIN  (LOCK_MIN),
        .LOCK_BITS (LOCK_BITS)
    ) u_dut (
        .clk     (clk),
        .rst_n   (rst_n),
        .enable  (enable),
        .div_sel (div_sel),
        .sys_clk (sys_clk),
        .locked  (locked)
    );

    
endmodule

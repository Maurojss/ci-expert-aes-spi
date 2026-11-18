// tb_minisoc_spi_sys.sv
// Testbench modular de integracao da Semana 5: minisoc_spi (slave + CDC + regbank)
// ligado ao minisoc_pll_mock, acessado so pelos pinos SPI.
// Verifica: leitura de VERSION, escrita e leitura de todos os registradores RW pelo SPI,
// ordem das palavras nas saidas AES, status do AES vindo do stub, START como pulso
// unico, leitura em duas transacoes (incluindo o pedido encadeado) e o fluxo de
// habilitar o PLL, escolher PLL_DIV_SEL e esperar PLL_LOCKED (passos 8 e 9 do modelo
// de programacao) para os quatro divisores.
// SCLK_HALF_NS escolhe a frequencia do spi_sclk em relacao ao clk (periodo de 10 ns):
// 20 -> sclk 4x mais lento ; 5 -> sclk na mesma frequencia do clk.
// Pode rodar isolado (STANDALONE = 1) ou instanciado em tb_minisoc_w05 (STANDALONE = 0).

`timescale 1ns/1ps

module tb_minisoc_spi_sys #(
    parameter bit STANDALONE   = 1'b1,
    parameter int SCLK_HALF_NS = 20
);

    import minisoc_regs_pkg::*;

    // ---------------- sinais ----------------
    logic         clk      = 1'b0;
    logic         rst_n    = 1'b0;
    logic         spi_sclk = 1'b0;
    logic         spi_cs_n = 1'b1;
    logic         spi_mosi = 1'b0;
    logic         spi_miso;

    logic         pll_enable;
    logic [1:0]   pll_div_sel;
    logic         pll_locked;
    logic         sys_clk;
    logic         mem_sel_aes;

    logic [127:0] aes_key, aes_iv, aes_counter;
    logic [8:0]   aes_num_blocks;
    logic [2:0]   aes_mode;
    logic         aes_decrypt;
    logic         aes_start;

    logic         aes_busy = 1'b0, aes_done = 1'b0, aes_error = 1'b0;
    logic [8:0]   aes_blocks_done = 9'h0;

    always #5 clk = ~clk;

    minisoc_spi u_dut (
        .clk             (clk),
        .rst_n           (rst_n),
        .spi_sclk        (spi_sclk),
        .spi_cs_n        (spi_cs_n),
        .spi_mosi        (spi_mosi),
        .spi_miso        (spi_miso),
        .pll_enable      (pll_enable),
        .pll_div_sel     (pll_div_sel),
        .pll_locked      (pll_locked),
        .mem_sel_aes     (mem_sel_aes),
        .aes_key         (aes_key),
        .aes_iv          (aes_iv),
        .aes_counter     (aes_counter),
        .aes_num_blocks  (aes_num_blocks),
        .aes_mode        (aes_mode),
        .aes_decrypt     (aes_decrypt),
        .aes_start       (aes_start),
        .aes_busy        (aes_busy),
        .aes_done        (aes_done),
        .aes_error       (aes_error),
        .aes_blocks_done (aes_blocks_done)
    );

    minisoc_pll_mock u_pll (
        .clk     (clk),
        .rst_n   (rst_n),
        .enable  (pll_enable),
        .div_sel (pll_div_sel),
        .sys_clk (sys_clk),
        .locked  (pll_locked)
    );

    `include "minisoc_spi_bfm.svh"

    // ---------------- verificacao ----------------
    int checks = 0;
    int errors = 0;

    
endmodule

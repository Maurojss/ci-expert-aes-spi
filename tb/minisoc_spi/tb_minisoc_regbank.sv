// tb_minisoc_regbank.sv
// Testbench modular do minisoc_spi_regbank (Semana 5), acessando a reg-if direto
// (sem SPI). Verifica: valores de reset, VERSION, leitura/escrita de todos os
// registradores RW com mascara de bits, ordem das palavras de KEY/IV/COUNTER, RO e
// reservados ignorados, START como pulso unico (W1P), mapeamento de status e as
// saidas para PLL e AES.
// Pode rodar isolado (STANDALONE = 1) ou instanciado em tb_minisoc_w05 (STANDALONE = 0).

`timescale 1ns/1ps

module tb_minisoc_regbank #(
    parameter bit STANDALONE = 1'b1
);

    import minisoc_regs_pkg::*;

    logic         clk   = 1'b0;
    logic         rst_n = 1'b0;

    logic         req   = 1'b0;
    logic         we    = 1'b0;
    logic [6:0]   addr  = 7'h0;
    logic [31:0]  wdata = 32'h0;
    logic [31:0]  rdata;
    logic         rvalid;

    logic         pll_enable;
    logic [1:0]   pll_div_sel;
    logic         mem_sel_aes;
    logic         pll_locked = 1'b0;

    logic [127:0] aes_key, aes_iv, aes_counter;
    logic [8:0]   aes_num_blocks;
    logic [2:0]   aes_mode;
    logic         aes_decrypt;
    logic         aes_start;

    logic         aes_busy = 1'b0, aes_done = 1'b0, aes_error = 1'b0;
    logic [8:0]   aes_blocks_done = 9'h0;

    always #5 clk = ~clk;

    minisoc_spi_regbank u_dut (
        .clk             (clk),
        .rst_n           (rst_n),
        .req             (req),
        .we              (we),
        .addr            (addr),
        .wdata           (wdata),
        .rdata           (rdata),
        .rvalid          (rvalid),
        .pll_enable      (pll_enable),
        .pll_div_sel     (pll_div_sel),
        .mem_sel_aes     (mem_sel_aes),
        .pll_locked      (pll_locked),
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

    int checks = 0;
    int errors = 0;

    
endmodule

// tb_minisoc_spi_slave.sv
// Testbench modular do minisoc_spi_slave (Semana 5), dominio spi_sclk isolado.
// Um mestre SPI (minisoc_spi_bfm.svh) gera frames de 40 bits; `rd_data` e dirigido
// pelo TB no lugar do dominio clk.
// Verifica: commit de escrita e de leitura (hold + toggle), MISO na fase de dados,
// frame NOP sem requisicao, miso em 0 nas escritas, frame interrompido descartado,
// clocks extras depois do bit 40, e uma bateria de frames aleatorios.
// Pode rodar isolado (STANDALONE = 1) ou instanciado em tb_minisoc_w05 (STANDALONE = 0).

`timescale 1ns/1ps

module tb_minisoc_spi_slave #(
    parameter bit STANDALONE = 1'b1
);

    import minisoc_regs_pkg::*;

    localparam int SCLK_HALF_NS = 20;

    logic        rst_n    = 1'b0;
    logic        spi_sclk = 1'b0;
    logic        spi_cs_n = 1'b1;
    logic        spi_mosi = 1'b0;
    logic        spi_miso;
    logic [31:0] rd_data  = 32'h0;

    logic        req_tgl;
    logic        req_we;
    logic [6:0]  req_addr;
    logic [31:0] req_wdata;

    minisoc_spi_slave u_dut (
        .rst_n     (rst_n),
        .spi_sclk  (spi_sclk),
        .spi_cs_n  (spi_cs_n),
        .spi_mosi  (spi_mosi),
        .spi_miso  (spi_miso),
        .rd_data   (rd_data),
        .req_tgl   (req_tgl),
        .req_we    (req_we),
        .req_addr  (req_addr),
        .req_wdata (req_wdata)
    );

    `include "minisoc_spi_bfm.svh"

    int checks = 0;
    int errors = 0;

    
endmodule

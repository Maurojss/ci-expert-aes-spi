// minisoc_spi.sv
// Front-end SPI do MiniSoC: escravo SPI (dominio spi_sclk), travessia por toggle e
// banco de registradores (dominio clk).
//
//   spi_sclk domain                    |  clk domain
//   minisoc_spi_slave --req_tgl------> 2 FFs + deteccao de borda --req--> regbank
//         ^                            |                                     |
//         +----------- rd_data (hold, estavel) <------ rdata/rvalid --------+
//
// CDC (decisao M4): so o toggle passa por sincronizador. req_we/req_addr/req_wdata
// (hold do slave) e rd_data (hold deste modulo) sao multibit estaveis por construcao:
// o hold so e reescrito por um novo frame completo (>= 40 periodos de spi_sclk depois).
// Premissa de frequencia: o caminho toggle -> regbank -> rd_data leva ~6 ciclos de clk e
// precisa terminar antes do bit 8 do frame seguinte (>= 8 periodos de spi_sclk),
// ou seja, f_clk >= f_spi_sclk (ver docs/architecture/spi_regbank_pll_v1.0.md).

module minisoc_spi (
    input  logic         clk,
    input  logic         rst_n,

    // SPI IF
    input  logic         spi_sclk,
    input  logic         spi_cs_n,
    input  logic         spi_mosi,
    output logic         spi_miso,

    // PLL
    output logic         pll_enable,
    output logic [1:0]   pll_div_sel,
    input  logic         pll_locked,
    output logic         mem_sel_aes,

    // AES: configuracao
    output logic [127:0] aes_key,
    output logic [127:0] aes_iv,
    output logic [127:0] aes_counter,
    output logic [8:0]   aes_num_blocks,
    output logic [2:0]   aes_mode,
    output logic         aes_decrypt,
    output logic         aes_start,

    // AES: status (ja sincronizado em clk)
    input  logic         aes_busy,
    input  logic         aes_done,
    input  logic         aes_error,
    input  logic [8:0]   aes_blocks_done
);

    // ---------------- dominio spi_sclk ----------------
    logic        req_tgl;
    logic        req_we;
    logic [6:0]  req_addr;
    logic [31:0] req_wdata;
    logic [31:0] rd_hold;

    minisoc_spi_slave u_slave (
        .rst_n     (rst_n),
        .spi_sclk  (spi_sclk),
        .spi_cs_n  (spi_cs_n),
        .spi_mosi  (spi_mosi),
        .spi_miso  (spi_miso),
        .rd_data   (rd_hold),
        .req_tgl   (req_tgl),
        .req_we    (req_we),
        .req_addr  (req_addr),
        .req_wdata (req_wdata)
    );

    // ---------------- travessia spi_sclk -> clk ----------------
    logic [2:0] tgl_sync;      // [0],[1]: sincronizador ; [2]: deteccao de borda
    logic       req_pulse;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) tgl_sync <= 3'b000;
        else        tgl_sync <= {tgl_sync[1:0], req_tgl};
    end

    assign req_pulse = tgl_sync[2] ^ tgl_sync[1];

    // ---------------- dominio clk ----------------
    logic [31:0] rb_rdata;
    logic        rb_rvalid;

    minisoc_spi_regbank u_regbank (
        .clk             (clk),
        .rst_n           (rst_n),
        .req             (req_pulse),
        .we              (req_we),
        .addr            (req_addr),
        .wdata           (req_wdata),
        .rdata           (rb_rdata),
        .rvalid          (rb_rvalid),
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

    // Snapshot da leitura: valor lido no instante do pedido, estavel ate a proxima leitura
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)          rd_hold <= 32'h0;
        else if (rb_rvalid)  rd_hold <= rb_rdata;
    end

endmodule

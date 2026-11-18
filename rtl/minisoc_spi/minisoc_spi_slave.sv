// minisoc_spi_slave.sv
// Escravo SPI modo 0 (CPOL=0, CPHA=0), MSB primeiro, no dominio de spi_sclk.
//
// Frame de 40 bits: {RW, addr[6:0], data[31:0]}  (RW = 1 escrita, 0 leitura)
//   - mosi e amostrado na borda de subida de spi_sclk;
//   - miso muda na borda de descida.
//
// Recepcao: registrador de deslocamento + contador de bits, zerados por spi_cs_n alto
// (frame interrompido e descartado). Ao completar os 40 bits, o frame vai para
// registradores de HOLD e um bit TOGGLE (req_tgl) e invertido. O toggle e o unico
// sinal que atravessa para o dominio clk (via sincronizador de 2 FFs no minisoc_spi);
// o dado multibit esta estavel por construcao ate o proximo frame completo.
// Frame com addr = ADDR_NOP nao gera requisicao.
//
// Leitura em duas transacoes: o frame de leitura pede o registrador em `addr`; o
// valor chega depois a `rd_data` (dominio clk, estavel entre frames). Em QUALQUER
// frame de leitura, rd_data e deslocado pelo miso na fase de dados (bits 9 a 40).
// Logo, o frame seguinte (tipicamente com ADDR_NOP) devolve o valor pedido antes.

module minisoc_spi_slave
    import minisoc_regs_pkg::*;
(
    input  logic        rst_n,        // reset global, assincrono, ativo em baixo
    input  logic        spi_sclk,
    input  logic        spi_cs_n,
    input  logic        spi_mosi,
    output logic        spi_miso,

    input  logic [31:0] rd_data,      // dominio clk, estavel entre transacoes

    output logic        req_tgl,      // toggle: um frame valido recebido
    output logic        req_we,       // RW do frame (1 = escrita)
    output logic [6:0]  req_addr,
    output logic [31:0] req_wdata
);

    logic [38:0] sr;                  // o 40o bit entra direto do pino no commit
    logic [5:0]  bit_cnt;             // 0 a 40

    // ---------------------------------------------------------------
    // Recepcao: zerada por cs_n alto (reinicio de frame)
    // ---------------------------------------------------------------
    always_ff @(posedge spi_sclk or posedge spi_cs_n or negedge rst_n) begin
        if (!rst_n || spi_cs_n) begin
            sr      <= 39'h0;
            bit_cnt <= 6'd0;
        end else if (bit_cnt != 6'(SPI_FRAME_W)) begin
            sr      <= {sr[37:0], spi_mosi};
            bit_cnt <= bit_cnt + 6'd1;
        end
    end

    // ---------------------------------------------------------------
    // Hold e toggle: so rst_n zera. Commit no 40o bit (bit_cnt = 39).
    // ---------------------------------------------------------------
    always_ff @(posedge spi_sclk or negedge rst_n) begin
        if (!rst_n) begin
            req_tgl   <= 1'b0;
            req_we    <= 1'b0;
            req_addr  <= 7'h0;
            req_wdata <= 32'h0;
        end else if (bit_cnt == 6'(SPI_FRAME_W - 1)) begin   // so chega a 39 com cs_n baixo
            req_we    <= sr[38];
            req_addr  <= sr[37:31];
            req_wdata <= {sr[30:0], spi_mosi};
            if (sr[37:31] != ADDR_NOP)
                req_tgl <= ~req_tgl;
        end
    end

    // ---------------------------------------------------------------
    // MISO: carrega rd_data depois do byte de comando (bit_cnt = 8) e desloca a
    // cada borda de descida. Em escrita, miso fica em 0.
    // ---------------------------------------------------------------
    logic [31:0] miso_sr;
    logic        miso_q;

    always_ff @(negedge spi_sclk or posedge spi_cs_n or negedge rst_n) begin
        if (!rst_n || spi_cs_n) begin
            miso_sr <= 32'h0;
            miso_q  <= 1'b0;
        end else if (bit_cnt == 6'd8) begin
            if (!sr[7]) begin                       // frame de leitura
                miso_q  <= rd_data[31];
                miso_sr <= {rd_data[30:0], 1'b0};
            end
        end else if (bit_cnt > 6'd8 && bit_cnt < 6'(SPI_FRAME_W)) begin
            miso_q  <= miso_sr[31];
            miso_sr <= {miso_sr[30:0], 1'b0};
        end
    end

    assign spi_miso = miso_q;

endmodule

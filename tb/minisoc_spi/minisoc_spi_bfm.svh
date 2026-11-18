// minisoc_spi_bfm.svh
// Mestre SPI (modo 0, MSB primeiro) para os testbenches da Semana 5.
// Incluir DENTRO do modulo do testbench, depois de importar minisoc_regs_pkg::*.
// Requer no modulo hospedeiro:
//   logic spi_sclk, spi_cs_n, spi_mosi, spi_miso;
//   localparam int SCLK_HALF_NS   (meio periodo de spi_sclk, em ns)
//
// Temporizacao: mosi muda com sclk baixo; miso e amostrado logo antes da subida
// de sclk (o escravo atualiza miso na descida).

// Transfere nbits (<= 48) bits, MSB primeiro, a partir de tx[nbits-1]. rx recebe o
// que foi amostrado em miso, com o primeiro bit amostrado no bit mais significativo
// lido (os nbits mais recentes ficam em rx[nbits-1:0]).
task automatic spi_xfer(input logic [47:0] tx, input int nbits, output logic [47:0] rx);
    rx = 48'h0;
    spi_cs_n = 1'b0;
    #(SCLK_HALF_NS);
    for (int i = nbits - 1; i >= 0; i--) begin
        spi_mosi = tx[i];
        #(SCLK_HALF_NS);
        rx = {rx[46:0], spi_miso};
        spi_sclk = 1'b1;
        #(SCLK_HALF_NS);
        spi_sclk = 1'b0;
    end
    #(SCLK_HALF_NS);
    spi_cs_n = 1'b1;
    spi_mosi = 1'b0;
    #(2 * SCLK_HALF_NS);
endtask

// Escrita: um frame de 40 bits {1, addr, data}
task automatic spi_write32(input logic [6:0] a, input logic [31:0] d);
    logic [47:0] rx;
    spi_xfer({8'h00, 1'b1, a, d}, 40, rx);
endtask

// Leitura em duas transacoes: frame 1 pede `a`; frame 2 (endereco NOP) devolve o dado
task automatic spi_read32(input logic [6:0] a, output logic [31:0] d);
    logic [47:0] rx1, rx2;
    spi_xfer({8'h00, 1'b0, a, 32'h0}, 40, rx1);
    spi_xfer({8'h00, 1'b0, ADDR_NOP, 32'h0}, 40, rx2);
    d = rx2[31:0];
endtask

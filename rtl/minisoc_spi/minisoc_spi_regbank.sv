// minisoc_spi_regbank.sv
// Banco de registradores no dominio clk (sempre ligado).
//
// Interface de acesso (reg-if), um pulso de `req` por acesso:
//   req, we, addr[6:0], wdata[31:0]  ->  rdata[31:0], rvalid
// Escrita: efetivada na borda em que req=1 e we=1.
// Leitura: rdata e rvalid saem registrados, um ciclo depois do req (rvalid = pulso).
//
// Regras: escrita em registrador RO ou em endereco reservado e ignorada; leitura de
// endereco reservado devolve 0; bits reservados leem 0; START (AES_CONTROL[0]) e W1P:
// escrever 1 gera um pulso de um ciclo em aes_start e le 0.
// Os sinais aes_busy/done/error/blocks_done devem chegar JA SINCRONIZADOS em clk
// (a sincronizacao sys_clk -> clk fica no minisoc_top, Semana 7).

module minisoc_spi_regbank
    import minisoc_regs_pkg::*;
(
    input  logic         clk,
    input  logic         rst_n,

    // reg-if
    input  logic         req,
    input  logic         we,
    input  logic [6:0]   addr,
    input  logic [31:0]  wdata,
    output logic [31:0]  rdata,
    output logic         rvalid,

    // SYSTEM_CONTROL / SYSTEM_STATUS
    output logic         pll_enable,
    output logic [1:0]   pll_div_sel,
    output logic         mem_sel_aes,
    input  logic         pll_locked,

    // AES_CONTROL e configuracao (capturada pelo engine no START)
    output logic [127:0] aes_key,
    output logic [127:0] aes_iv,
    output logic [127:0] aes_counter,
    output logic [8:0]   aes_num_blocks,
    output logic [2:0]   aes_mode,
    output logic         aes_decrypt,
    output logic         aes_start,       // pulso de um ciclo de clk

    // AES_STATUS
    input  logic         aes_busy,
    input  logic         aes_done,
    input  logic         aes_error,
    input  logic [8:0]   aes_blocks_done
);

    logic wr;
    assign wr = req && we;

    // ---------------------------------------------------------------
    // Escrita
    // ---------------------------------------------------------------
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pll_enable     <= 1'b0;
            pll_div_sel    <= 2'b00;
            mem_sel_aes    <= 1'b0;
            aes_key        <= 128'h0;
            aes_iv         <= 128'h0;
            aes_counter    <= 128'h0;
            aes_num_blocks <= 9'h0;
            aes_mode       <= 3'h0;
            aes_decrypt    <= 1'b0;
            aes_start      <= 1'b0;
        end else begin
            aes_start <= 1'b0;                      // W1P
            if (wr) begin
                case (addr)
                    ADDR_SYS_CTRL: begin
                        pll_enable  <= wdata[SYSCTRL_PLL_EN];
                        pll_div_sel <= wdata[SYSCTRL_DIV_LSB +: 2];
                        mem_sel_aes <= wdata[SYSCTRL_MEM_SEL];
                    end
                    ADDR_AES_CTRL: begin
                        aes_decrypt <= wdata[AESCTRL_DECRYPT];
                        aes_mode    <= wdata[AESCTRL_MODE_LSB +: 3];
                        aes_start   <= wdata[AESCTRL_START];
                    end
                    ADDR_NUM_BLOCKS: aes_num_blocks <= wdata[8:0];
                    ADDR_KEY0: aes_key[127:96] <= wdata;
                    ADDR_KEY1: aes_key[95:64]  <= wdata;
                    ADDR_KEY2: aes_key[63:32]  <= wdata;
                    ADDR_KEY3: aes_key[31:0]   <= wdata;
                    ADDR_IV0:  aes_iv[127:96]  <= wdata;
                    ADDR_IV1:  aes_iv[95:64]   <= wdata;
                    ADDR_IV2:  aes_iv[63:32]   <= wdata;
                    ADDR_IV3:  aes_iv[31:0]    <= wdata;
                    ADDR_CTR0: aes_counter[127:96] <= wdata;
                    ADDR_CTR1: aes_counter[95:64]  <= wdata;
                    ADDR_CTR2: aes_counter[63:32]  <= wdata;
                    ADDR_CTR3: aes_counter[31:0]   <= wdata;
                    default: begin end                      // RO/reservado: ignorado
                endcase
            end
        end
    end

    // ---------------------------------------------------------------
    // Leitura
    // ---------------------------------------------------------------
    logic [31:0] rd_mux;

    always_comb begin
        rd_mux = 32'h0;
        case (addr)
            ADDR_VERSION:    rd_mux = VERSION_VALUE;
            ADDR_SYS_CTRL:   rd_mux = {28'h0, mem_sel_aes, pll_div_sel, pll_enable};
            ADDR_SYS_STATUS: rd_mux[SYSSTAT_PLL_LOCKED] = pll_locked;
            ADDR_AES_CTRL:   rd_mux = {27'h0, aes_mode, aes_decrypt, 1'b0};
            ADDR_AES_STATUS: begin
                rd_mux[AESSTAT_BUSY]  = aes_busy;
                rd_mux[AESSTAT_DONE]  = aes_done;
                rd_mux[AESSTAT_ERROR] = aes_error;
                rd_mux[AESSTAT_BLK_LSB +: 9] = aes_blocks_done;
            end
            ADDR_NUM_BLOCKS: rd_mux = {23'h0, aes_num_blocks};
            ADDR_KEY0: rd_mux = aes_key[127:96];
            ADDR_KEY1: rd_mux = aes_key[95:64];
            ADDR_KEY2: rd_mux = aes_key[63:32];
            ADDR_KEY3: rd_mux = aes_key[31:0];
            ADDR_IV0:  rd_mux = aes_iv[127:96];
            ADDR_IV1:  rd_mux = aes_iv[95:64];
            ADDR_IV2:  rd_mux = aes_iv[63:32];
            ADDR_IV3:  rd_mux = aes_iv[31:0];
            ADDR_CTR0: rd_mux = aes_counter[127:96];
            ADDR_CTR1: rd_mux = aes_counter[95:64];
            ADDR_CTR2: rd_mux = aes_counter[63:32];
            ADDR_CTR3: rd_mux = aes_counter[31:0];
            default:   rd_mux = 32'h0;
        endcase
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rdata  <= 32'h0;
            rvalid <= 1'b0;
        end else begin
            rvalid <= req && !we;
            if (req && !we)
                rdata <= rd_mux;
        end
    end

endmodule

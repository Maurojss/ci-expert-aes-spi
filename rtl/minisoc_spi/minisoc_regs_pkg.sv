// minisoc_regs_pkg.sv
// Constantes do front-end SPI e do banco de registradores (Semana 5).
//
// ATENCAO: o Block Guide (secoes 5, 6 e 9) nao esta em docs/spec. Os enderecos, os
// campos de bit e o formato do frame abaixo sao PREMISSAS de trabalho, listadas em
// docs/architecture/spi_regbank_pll_v1.0.md (tabela "Premissas a conferir").
// Tudo que depende do Block Guide fica concentrado AQUI: RTL e testbenches importam
// este pacote, entao corrigir um endereco ou um campo e uma edicao neste arquivo.
// (Mudancas de comportamento, e nao so de valor, exigem editar o RTL.)

package minisoc_regs_pkg;

    // ------------------------------------------------------------------
    // Frame SPI (modo 0, MSB primeiro): {RW, addr[6:0], data[31:0]} = 40 bits
    //   RW = 1 -> escrita ; RW = 0 -> leitura
    // ------------------------------------------------------------------
    localparam int          SPI_FRAME_W = 40;
    localparam int          SPI_ADDR_W  = 7;
    localparam logic [6:0]  ADDR_NOP    = 7'h3F;   // fase de retorno da leitura

    // ------------------------------------------------------------------
    // Enderecos (palavras de 32 bits)
    // ------------------------------------------------------------------
    localparam logic [6:0] ADDR_VERSION     = 7'h00;  // RO
    localparam logic [6:0] ADDR_SYS_CTRL    = 7'h01;  // RW  SYSTEM_CONTROL
    localparam logic [6:0] ADDR_SYS_STATUS  = 7'h02;  // RO  SYSTEM_STATUS
    localparam logic [6:0] ADDR_AES_CTRL    = 7'h03;  // RW  AES_CONTROL (START e W1P)
    localparam logic [6:0] ADDR_AES_STATUS  = 7'h04;  // RO  AES_STATUS
    localparam logic [6:0] ADDR_NUM_BLOCKS  = 7'h05;  // RW
    localparam logic [6:0] ADDR_KEY0        = 7'h08;  // RW  KEY[127:96]
    localparam logic [6:0] ADDR_KEY1        = 7'h09;  //     KEY[95:64]
    localparam logic [6:0] ADDR_KEY2        = 7'h0A;  //     KEY[63:32]
    localparam logic [6:0] ADDR_KEY3        = 7'h0B;  //     KEY[31:0]
    localparam logic [6:0] ADDR_IV0         = 7'h0C;  // RW  IV[127:96] ... IV3
    localparam logic [6:0] ADDR_IV1         = 7'h0D;
    localparam logic [6:0] ADDR_IV2         = 7'h0E;
    localparam logic [6:0] ADDR_IV3         = 7'h0F;
    localparam logic [6:0] ADDR_CTR0        = 7'h10;  // RW  COUNTER[127:96] ... COUNTER3
    localparam logic [6:0] ADDR_CTR1        = 7'h11;
    localparam logic [6:0] ADDR_CTR2        = 7'h12;
    localparam logic [6:0] ADDR_CTR3        = 7'h13;

    // ------------------------------------------------------------------
    // Valores e campos
    // ------------------------------------------------------------------
    localparam logic [31:0] VERSION_VALUE = 32'h0001_0000;  // v1.0.0

    // SYSTEM_CONTROL: [0] PLL_ENABLE, [2:1] PLL_DIV_SEL, [3] MEM_SEL_AES
    localparam int SYSCTRL_PLL_EN   = 0;
    localparam int SYSCTRL_DIV_LSB  = 1;      // PLL_DIV_SEL em [2:1]
    localparam int SYSCTRL_MEM_SEL  = 3;
    localparam logic [31:0] SYSCTRL_MASK = 32'h0000_000F;

    // PLL_DIV_SEL: 00 = /1, 01 = /2, 10 = /4, 11 = /8

    // SYSTEM_STATUS: [0] PLL_LOCKED
    localparam int SYSSTAT_PLL_LOCKED = 0;

    // AES_CONTROL: [0] START (W1P, le 0), [1] DECRYPT, [4:2] MODE
    localparam int AESCTRL_START    = 0;
    localparam int AESCTRL_DECRYPT  = 1;
    localparam int AESCTRL_MODE_LSB = 2;
    localparam logic [31:0] AESCTRL_RD_MASK = 32'h0000_001E;  // START nao e legivel

    // AES_STATUS: [0] BUSY, [1] DONE, [2] ERROR, [24:16] BLOCKS_DONE
    localparam int AESSTAT_BUSY     = 0;
    localparam int AESSTAT_DONE     = 1;
    localparam int AESSTAT_ERROR    = 2;
    localparam int AESSTAT_BLK_LSB  = 16;

    // NUM_BLOCKS: [8:0] (1 a 256)
    localparam logic [31:0] NUMBLK_MASK = 32'h0000_01FF;

    // MODE (AES_CONTROL[4:2]): ECB, CBC, PCBC, CFB, OFB, CTR (6 e 7 reservados)
    localparam logic [2:0] MODE_ECB  = 3'd0;
    localparam logic [2:0] MODE_CBC  = 3'd1;
    localparam logic [2:0] MODE_PCBC = 3'd2;
    localparam logic [2:0] MODE_CFB  = 3'd3;
    localparam logic [2:0] MODE_OFB  = 3'd4;
    localparam logic [2:0] MODE_CTR  = 3'd5;

endpackage

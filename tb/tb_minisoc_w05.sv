// tb_minisoc_w05.sv
// Testbench integrador (hierarquico) da Semana 5.
// Instancia os testbenches unitarios em hierarquias separadas (facilitando o debug de
// ondas no Verdi) e roda a bateria completa em sequencia:
//   1. u_tb_pll        -> minisoc_pll_mock
//   2. u_tb_regbank    -> minisoc_spi_regbank (reg-if direta)
//   3. u_tb_spi_slave  -> minisoc_spi_slave (dominio spi_sclk isolado)
//   4. u_tb_spi_sys    -> minisoc_spi + minisoc_pll_mock, spi_sclk 4x mais lento que clk
//   5. u_tb_spi_sys_eq -> idem, com spi_sclk na mesma frequencia do clk (pior caso de CDC)

`timescale 1ns/1ps

module tb_minisoc_w05;

    int pll_checks,  pll_errors;
    int rb_checks,   rb_errors;
    int sl_checks,   sl_errors;
    int sys_checks,  sys_errors;
    int eq_checks,   eq_errors;
    int total_checks, total_errors;

    // Instancias modulares dos testbenches (STANDALONE = 0)
    tb_minisoc_pll_mock   #(.STANDALONE(1'b0))                         u_tb_pll        ();
    tb_minisoc_regbank    #(.STANDALONE(1'b0))                         u_tb_regbank    ();
    tb_minisoc_spi_slave  #(.STANDALONE(1'b0))                         u_tb_spi_slave  ();
    tb_minisoc_spi_sys    #(.STANDALONE(1'b0), .SCLK_HALF_NS(20))      u_tb_spi_sys    ();
    tb_minisoc_spi_sys    #(.STANDALONE(1'b0), .SCLK_HALF_NS(5))       u_tb_spi_sys_eq ();

endmodule

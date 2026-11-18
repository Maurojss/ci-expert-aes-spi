# Semana 5 — SPI front-end, banco de registradores e PLL mock

## O que foi feito

- `minisoc_spi_slave` (`rtl/minisoc_spi/minisoc_spi_slave.sv`): escravo SPI modo 0, MSB primeiro, frame de 40 bits,
  no domínio de `spi_sclk`. Registrador de deslocamento e contador zerados por `spi_cs_n` alto, hold do frame
  e toggle `req_tgl` no 40º bit, `miso` carregado depois do byte de comando.
- `minisoc_spi_regbank` (`rtl/minisoc_spi/minisoc_spi_regbank.sv`): registradores `VERSION`, `SYSTEM_CONTROL`,
  `SYSTEM_STATUS`, `AES_CONTROL`, `AES_STATUS`, `NUM_BLOCKS`, `KEY0..3`, `IV0..3` e `COUNTER0..3` no domínio `clk`.
- `minisoc_spi` (`rtl/minisoc_spi/minisoc_spi.sv`): une o slave, o sincronizador de 2 FFs do toggle, o banco
  de registradores e o snapshot de leitura (`rd_hold`).
- `minisoc_regs_pkg` (`rtl/minisoc_spi/minisoc_regs_pkg.sv`): endereços, campos e formato do frame em um só lugar.
- `minisoc_pll_mock` (`rtl/minisoc_pll/minisoc_pll_mock.sv`): `enable`, `PLL_DIV_SEL` (/1, /2, /4, /8) e `locked`
  depois de um número pseudoaleatório (LFSR com `SEED`, reprodutível) de ciclos.
- **Testbenches modulares**, no mesmo padrão da Semana 4 (`STANDALONE`, `run_tests`, topo hierárquico):
  - `tb/minisoc_pll/tb_minisoc_pll_mock.sv`
  - `tb/minisoc_spi/tb_minisoc_regbank.sv`
  - `tb/minisoc_spi/tb_minisoc_spi_slave.sv`
  - `tb/minisoc_spi/tb_minisoc_spi_sys.sv` (integração pelos pinos SPI; parâmetro `SCLK_HALF_NS`)
  - `tb/tb_minisoc_w05.sv`: topo integrador com `u_tb_pll`, `u_tb_regbank`, `u_tb_spi_slave`, `u_tb_spi_sys` e
    `u_tb_spi_sys_eq`.
- `tb/minisoc_spi/minisoc_spi_bfm.svh`: mestre SPI compartilhado (`spi_xfer`, `spi_write32`, `spi_read32`).
- **Makefile reorganizado**: receitas reutilizáveis (`sim_cmd`, `pass_cmd`, `lint_cmd`), listas de fontes por
  semana, atalhos `w02` a `w05`, `help` gerado dos comentários `##` e alvos novos `sim_pll`, `sim_regbank`,
  `sim_spi_slave`, `sim_spi_sys`, `sim_spi` e `lint_spi`. Todos os alvos das semanas 1 a 4 mantêm o nome.
- Documento de projeto: `docs/architecture/spi_regbank_pll_v1.0.md`, com a tabela de premissas a conferir.

## Aviso: dependência do Block Guide

As seções 5, 6 e 9 do Block Guide não estavam disponíveis ao escrever o RTL. O backlog fixou os nomes dos
registradores, o modo SPI, o frame de 40 bits, a leitura em duas transações com NOP `0x3F` e os divisores do
PLL. **Endereços, campos de bit, o valor de `VERSION` e a codificação de `MODE` são premissas** (P1 a P15 no
documento de projeto). Estão todos em `minisoc_regs_pkg.sv`, e os testbenches usam o mesmo pacote.

## Testes e cobertura

| Testbench | Escopo | Checks |
| --- | --- | --- |
| `tb_minisoc_pll_mock` | Reset, latência de lock contra modelo do LFSR, 4 divisores, reconfiguração, disable, enable curto, reprodução | 40 |
| `tb_minisoc_regbank` | Reset, VERSION, 13 registradores RW com 4 padrões, valores únicos, ordem das palavras, RO e reservados, SYSTEM_CONTROL, status, START W1P | 224 |
| `tb_minisoc_spi_slave` | Escrita, leitura, NOP, frame de 39 e 8 bits, 46 clocks, 40 frames aleatórios, reset no meio do frame | 291 |
| `tb_minisoc_spi_sys` (`SCLK_HALF_NS = 20`) | Todos os registradores RW por SPI, leitura encadeada, status do AES, START, passos 8 e 9 com os 4 divisores | 135 |
| `tb_minisoc_spi_sys` (`SCLK_HALF_NS = 5`) | Mesma bateria com `spi_sclk` na frequência de `clk` | 135 |
| `tb_minisoc_w05` | Execução hierárquica integrada dos cinco acima | **825** |

## Resultados

### Conferência prévia (Verilator 5.020)

| Item | Resultado |
| --- | --- |
| Simulação de `tb_minisoc_w05` | `PASS: 825 checks da Semana 5 (pll + regbank + spi_slave + spi_sys integrados) passaram` |
| `tb_minisoc_spi_sys` com meio período de `spi_sclk` de 5, 20 e 100 ns (razões 1:1, 4:1 e 10:1 com `clk`) | PASS nas três |
| Lint com `-Wall` | Só avisos de parâmetro não usado no pacote (constantes de mapa de registradores) |
| Defeitos injetados (MISO carregado um bit tarde, `START` sem voltar a 0, divisor /4 errado, PLL sem reiniciar o lock na reconfiguração) | Os quatro foram detectados (33, 3, 1 e vários erros) |
| Alvos das semanas 1 a 4 pelo Makefile reorganizado | `PASS` com os mesmos números de antes (832, 84 e 57 checks) |

### Fluxo oficial (VCS X-2025.06-SP2)

Resultados obtidos via `make w05` no servidor:

| Alvo | Comando | Checks | Erros / Avisos | Tempo (s) | Status |
| --- | --- | --- | --- | --- | --- |
| `sim_spi` | VCS (`tb_minisoc_w05`) | 825 | 0 / 0 | 0.48 | PASS |
| `lint_spi` (`minisoc_spi_slave`) | VCS `+lint=all,noVCDE` | N/A | 0 / 0 | 1.59 | PASS |
| `lint_spi` (`minisoc_spi_regbank`) | VCS `+lint=all,noVCDE` | N/A | 0 / 0 | 1.55 | PASS |
| `lint_spi` (`minisoc_spi`) | VCS `+lint=all,noVCDE` | N/A | 0 / 0 | 1.65 | PASS |
| `lint_spi` (`minisoc_pll_mock`) | VCS `+lint=all,noVCDE` | N/A | 0 / 0 | 1.65 | PASS |

Logs versionados em `reports/sim_spi.rpt` e `reports/lint_spi.rpt` (após substituir o *null statement*
em `minisoc_spi_regbank.sv:96` por `default: begin end`, todos os quatro módulos encerraram sem avisos).

## Decisões e observações

- **Pacote único de registradores.** O Block Guide ainda não foi conferido, então endereços e campos ficam
  em `minisoc_regs_pkg`. Corrigir um valor é editar um arquivo; os TBs acompanham.
- **Leitura encadeada.** Todo frame de leitura devolve o snapshot da leitura anterior e já pede o próximo
  registrador. O NOP `0x3F` devolve sem pedir nada.
- **CDC por toggle e hold.** Só o toggle passa por sincronizador. A premissa de frequência é
  `f_clk ≥ f_spi_sclk`; o caso `f_spi_sclk = f_clk` está na simulação.
- **`spi_cs_n` só como reset assíncrono do contador.** Não é usado como dado na lógica síncrona, o que evita o
  aviso de sinal usado como assíncrono e síncrono.
- **PLL reprodutível.** A sequência de latências depende só de `SEED`, `LOCK_MIN` e `LOCK_BITS`, e o TB tem seu
  próprio modelo do LFSR para conferir cada latência.
- **Fora do escopo desta semana.** Sincronização `sys_clk` → `clk` de BUSY, DONE, ERROR e BLOCKS_DONE
  (código Gray) e release sincronizado do reset ficam para o `minisoc_top` (Semana 7).

## Dúvidas para o Block Guide

- Endereços e campos de bit dos registradores (seção 6) e valor de `VERSION`.
- `KEY`, `IV` e `COUNTER` são legíveis?
- Frame de leitura: o dado vem no segundo frame, com o NOP, como foi assumido? E o byte de comando tem
  `RW` no bit 39?
- Codificação de `MODE` e de `PLL_DIV_SEL`.
- Faixa e semente do número pseudoaleatório do PLL mock (como o verificador reproduz).
- `miso` com tri-state ou nível 0 fora da leitura.
- Escritas com `BUSY = 1` são ignoradas ou aceitas?

## Próximos passos

- Conferir e versionar `reports/sim_spi.rpt`, `reports/lint_spi.rpt`, `docs/reports/semana_05.md` e `docs/backlog.md`, aplicando a tag `w05-spi-pll-v1.0`.
- Ler as seções 5, 6 e 9 do Block Guide e fechar a tabela de premissas.
- **Semana 6 (entrega 27/11):** `minisoc_memory` e `minisoc_aes_top` (FSM, modos ECB, CBC e CTR), usando as
  saídas `aes_*` do banco de registradores.
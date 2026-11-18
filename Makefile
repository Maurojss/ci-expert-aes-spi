# ==========================================================================
# AES + SPI — Projeto RTL Design Track
# Makefile — Semanas 1 a 5 (VCS)
#
#   make help        lista os alvos
#   make regress     toda a regressao (simulacao e lint, semanas 1 a 5)
#   make w05         so a Semana 5 (sim_spi + lint_spi)
#
# Ferramentas: source /Tools/synopsys-scripts/snps.sh   (VCS no PATH)
# Sobrescreva na linha de comando, por exemplo: make sim_spi VCS=/caminho/vcs
# ==========================================================================

SHELL        := /bin/bash
.DEFAULT_GOAL := help

# ---------- diretorios ----------
ROOT_DIR     := $(CURDIR)
RTL_DIR      := $(ROOT_DIR)/rtl
TB_DIR       := $(ROOT_DIR)/tb
BUILD_DIR    := $(ROOT_DIR)/build
SIM_OUT      := $(BUILD_DIR)/sim
REPORT_DIR   := $(ROOT_DIR)/reports

AES_DIR      := $(RTL_DIR)/minisoc_aes
SPI_DIR      := $(RTL_DIR)/minisoc_spi
PLL_DIR      := $(RTL_DIR)/minisoc_pll
AES_TB_DIR   := $(TB_DIR)/minisoc_aes
SPI_TB_DIR   := $(TB_DIR)/minisoc_spi
PLL_TB_DIR   := $(TB_DIR)/minisoc_pll

# ---------- ferramentas e flags ----------
VCS          ?= vcs
VCS_COMP     := $(VCS) -full64 -sverilog -timescale=1ns/1ps
VCS_SIM      := $(VCS_COMP) -debug_access+all -kdb
VCS_LINT     := $(VCS_COMP) +lint=all,noVCDE

# ---------- Semana 1: exemplo minimo ----------
EXAMPLE_RTL  := $(RTL_DIR)/example/counter.sv
EXAMPLE_TB   := $(TB_DIR)/example/tb_counter.sv
EXAMPLE_TOP  := tb_counter

# ---------- Semana 2: S-box, SubBytes, ShiftRows ----------
AES_RTL      := $(addprefix $(AES_DIR)/minisoc_aes_, sbox.sv inv_sbox.sv sub_bytes.sv shift_rows.sv inv_sub_bytes.sv inv_shift_rows.sv)
AES_TOPS     := minisoc_aes_sub_bytes minisoc_aes_shift_rows minisoc_aes_inv_sub_bytes minisoc_aes_inv_shift_rows
AES_TB       := $(AES_TB_DIR)/tb_minisoc_aes_sub_shift.sv
AES_TB_TOP   := tb_minisoc_aes_sub_shift

# ---------- Semana 3: MixColumns, AddRoundKey, inversas ----------
ROUND_RTL    := $(AES_RTL) $(addprefix $(AES_DIR)/minisoc_aes_, mix_columns.sv inv_mix_columns.sv add_round_key.sv)
ROUND_TOPS   := minisoc_aes_mix_columns minisoc_aes_inv_mix_columns minisoc_aes_add_round_key
ROUND_TB     := $(AES_TB_DIR)/tb_minisoc_aes_round.sv
ROUND_TB_TOP := tb_minisoc_aes_round

# ---------- Semana 4: expansao de chave e datapath ----------
DP_RTL       := $(ROUND_RTL) $(addprefix $(AES_DIR)/minisoc_aes_, key_exp.sv dp.sv)
DP_TOPS      := minisoc_aes_key_exp minisoc_aes_dp
TB_KEY_EXP   := $(AES_TB_DIR)/tb_minisoc_aes_key_exp.sv
TB_DP        := $(AES_TB_DIR)/tb_minisoc_aes_dp.sv
TB_W04_TOP   := $(AES_TB_DIR)/tb_minisoc_aes_w04.sv

# ---------- Semana 5: SPI, banco de registradores e PLL mock ----------
# (o pacote minisoc_regs_pkg.sv precisa vir primeiro na lista)
SPI_RTL      := $(addprefix $(SPI_DIR)/, minisoc_regs_pkg.sv minisoc_spi_slave.sv minisoc_spi_regbank.sv minisoc_spi.sv)
PLL_RTL      := $(PLL_DIR)/minisoc_pll_mock.sv
W05_RTL      := $(SPI_RTL) $(PLL_RTL)
W05_TOPS     := minisoc_spi_slave minisoc_spi_regbank minisoc_spi minisoc_pll_mock
TB_PLL       := $(PLL_TB_DIR)/tb_minisoc_pll_mock.sv
TB_REGBANK   := $(SPI_TB_DIR)/tb_minisoc_regbank.sv
TB_SPI_SLAVE := $(SPI_TB_DIR)/tb_minisoc_spi_slave.sv
TB_SPI_SYS   := $(SPI_TB_DIR)/tb_minisoc_spi_sys.sv
TB_W05_TOP   := $(TB_DIR)/tb_minisoc_w05.sv
W05_TBS      := $(TB_PLL) $(TB_REGBANK) $(TB_SPI_SLAVE) $(TB_SPI_SYS) $(TB_W05_TOP)

# ==========================================================================
# Receitas reutilizaveis
#   sim_cmd   $(1)=tag $(2)=fontes $(3)=top $(4)=incdirs   compila e roda o VCS
#   pass_cmd  $(1)=tag                                      copia o log para reports/ e exige "PASS"
#   lint_cmd  $(1)=tag $(2)=fontes $(3)=tops                lint de cada top e copia para reports/
# ==========================================================================
define sim_cmd
	mkdir -p $(SIM_OUT)
	set -o pipefail; cd $(SIM_OUT) && \
	$(VCS_SIM) $(4) $(2) -top $(3) -o simv_$(1) | tee vcs_compile_$(1).log && \
	./simv_$(1) | tee sim_$(1).log
endef

define pass_cmd
	mkdir -p $(REPORT_DIR) && cp $(SIM_OUT)/sim_$(1).log $(REPORT_DIR)/sim_$(1).rpt
	@grep -q '^PASS' $(SIM_OUT)/sim_$(1).log || { echo "ERRO: testbench sem PASS (veja $(REPORT_DIR)/sim_$(1).rpt)"; exit 1; }
endef

define lint_cmd
	mkdir -p $(SIM_OUT)
	set -o pipefail; cd $(SIM_OUT) && rm -f lint_$(1).log && \
	for top in $(3); do \
		echo "=== lint: $$top ===" | tee -a lint_$(1).log; \
		$(VCS_LINT) $(2) -top $$top -o simv_lint_$$top | tee -a lint_$(1).log || exit 1; \
	done
	mkdir -p $(REPORT_DIR) && cp $(SIM_OUT)/lint_$(1).log $(REPORT_DIR)/lint_$(1).rpt
endef

.PHONY: help all regress clean \
        sim lint \
        sim_aes lint_aes sim_round lint_round \
        sim_key_exp sim_dp_unit sim_dp lint_dp \
        sim_pll sim_regbank sim_spi_slave sim_spi_sys sim_spi lint_spi \
        w02 w03 w04 w05

all: sim_spi                                        ## Atalho para sim_spi (semana corrente)

##@ Atalhos por semana
w02: sim_aes lint_aes                               ## Semana 2: S-box, SubBytes e ShiftRows (sim + lint)
w03: sim_round lint_round                           ## Semana 3: MixColumns, AddRoundKey e inversas (sim + lint)
w04: sim_dp lint_dp                                 ## Semana 4: expansao de chave e datapath (sim + lint)
w05: sim_spi lint_spi                               ## Semana 5: SPI, registradores e PLL mock (sim + lint)

regress: sim lint w02 w03 w04 w05                   ## Regressao completa, semanas 1 a 5

##@ Semana 1 - exemplo minimo
sim: $(SIM_OUT)                                     ## Compila e simula o exemplo minimo
	cd $(SIM_OUT) && \
	$(VCS_SIM) $(EXAMPLE_RTL) $(EXAMPLE_TB) -top $(EXAMPLE_TOP) -o simv | tee vcs_compile.log && \
	./simv | tee sim.log

lint: $(SIM_OUT)                                    ## Lint do exemplo minimo
	cd $(SIM_OUT) && \
	$(VCS_LINT) $(EXAMPLE_RTL) -top counter -o simv_lint | tee lint.log

##@ Semana 2
sim_aes: $(SIM_OUT)                                 ## TB de S-box, SubBytes e ShiftRows (FIPS-197)
	$(call sim_cmd,aes,$(AES_RTL) $(AES_TB),$(AES_TB_TOP),+incdir+$(AES_TB_DIR))
	$(call pass_cmd,aes)

lint_aes: $(SIM_OUT)                                ## Lint das transformacoes da Semana 2
	$(call lint_cmd,aes,$(AES_RTL),$(AES_TOPS))

##@ Semana 3
sim_round: $(SIM_OUT)                               ## TB de MixColumns, AddRoundKey e AES-128 completo
	$(call sim_cmd,round,$(ROUND_RTL) $(ROUND_TB),$(ROUND_TB_TOP),+incdir+$(AES_TB_DIR))
	$(call pass_cmd,round)

lint_round: $(SIM_OUT)                              ## Lint dos modulos da Semana 3
	$(call lint_cmd,round,$(ROUND_RTL),$(ROUND_TOPS))

##@ Semana 4
sim_key_exp: $(SIM_OUT)                             ## (unitario) TB da expansao de chave
	$(call sim_cmd,key_exp,$(DP_RTL) $(TB_KEY_EXP),tb_minisoc_aes_key_exp,+incdir+$(AES_TB_DIR))

sim_dp_unit: $(SIM_OUT)                             ## (unitario) TB do datapath
	$(call sim_cmd,dp_unit,$(DP_RTL) $(TB_DP),tb_minisoc_aes_dp,+incdir+$(AES_TB_DIR))

sim_dp: $(SIM_OUT)                                  ## TB integrador tb_minisoc_aes_w04 (key_exp + dp)
	$(call sim_cmd,dp,$(DP_RTL) $(TB_KEY_EXP) $(TB_DP) $(TB_W04_TOP),tb_minisoc_aes_w04,+incdir+$(AES_TB_DIR))
	$(call pass_cmd,dp)

lint_dp: $(SIM_OUT)                                 ## Lint de key_exp e dp
	$(call lint_cmd,dp,$(DP_RTL),$(DP_TOPS))

##@ Semana 5
sim_pll: $(SIM_OUT)                                 ## (unitario) TB do PLL mock
	$(call sim_cmd,pll,$(W05_RTL) $(TB_PLL),tb_minisoc_pll_mock,+incdir+$(SPI_TB_DIR))

sim_regbank: $(SIM_OUT)                             ## (unitario) TB do banco de registradores
	$(call sim_cmd,regbank,$(W05_RTL) $(TB_REGBANK),tb_minisoc_regbank,+incdir+$(SPI_TB_DIR))

sim_spi_slave: $(SIM_OUT)                           ## (unitario) TB do escravo SPI (dominio spi_sclk)
	$(call sim_cmd,spi_slave,$(W05_RTL) $(TB_SPI_SLAVE),tb_minisoc_spi_slave,+incdir+$(SPI_TB_DIR))

sim_spi_sys: $(SIM_OUT)                             ## (unitario) TB SPI + registradores + PLL pelos pinos SPI
	$(call sim_cmd,spi_sys,$(W05_RTL) $(TB_SPI_SYS),tb_minisoc_spi_sys,+incdir+$(SPI_TB_DIR))

sim_spi: $(SIM_OUT)                                 ## TB integrador tb_minisoc_w05 (pll + regbank + slave + sys)
	$(call sim_cmd,spi,$(W05_RTL) $(W05_TBS),tb_minisoc_w05,+incdir+$(SPI_TB_DIR))
	$(call pass_cmd,spi)

lint_spi: $(SIM_OUT)                                ## Lint de spi_slave, regbank, spi e pll_mock
	$(call lint_cmd,spi,$(W05_RTL),$(W05_TOPS))

##@ Utilitarios
$(SIM_OUT):
	mkdir -p $(SIM_OUT)

clean:                                              ## Remove artefatos gerados (build/)
	rm -rf $(BUILD_DIR) *.log simv* csrc ucli.key vc_hdrs.h DVEfiles verdiLog novas.*

help:                                               ## Lista os alvos
	@awk 'BEGIN {FS = ":.*## "} \
		/^##@/ {printf "\n%s\n", substr($$0, 5)} \
		/^[a-zA-Z_0-9-]+:.*## / {printf "  make %-14s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

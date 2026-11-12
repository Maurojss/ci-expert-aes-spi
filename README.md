# Acelerador AES com interface SPI e baixo consumo

Projeto hands-on da trilha RTL Design — CIExpert.

## Setup rápido

No servidor, clone o repositório, carregue as ferramentas Synopsys e rode a regressão completa:

```bash
git clone https://github.com/Maurojss/ci-expert-aes-spi.git
cd ci-expert-aes-spi
source /Tools/synopsys-scripts/snps.sh
make regress
```

O resultado esperado inclui `PASS: 57 checks da Semana 4 (key_exp + dp integrados) passaram`, além de todos os alvos anteriores com zero erros de simulação e lint.

A simulação mínima (`rtl/example/counter.sv`, alvo `make sim`) valida o fluxo básico do ambiente. Os blocos do acelerador AES-128 ficam em `rtl/minisoc_aes/` e os testbenches modulares em `tb/minisoc_aes/`.

Alvos disponíveis:

| Comando | O que faz |
| --- | --- |
| `make sim` | Compila e simula o exemplo mínimo (VCS) |
| `make lint` | Roda o lint do VCS (`+lint=all,noVCDE`) no exemplo mínimo |
| `make sim_aes` | Testbench de S-box, SubBytes e ShiftRows contra os vetores do FIPS-197 (VCS) |
| `make lint_aes` | Lint (`+lint=all,noVCDE`) de cada transformação do AES (VCS) |
| `make sim_round` | Testbench de MixColumns, AddRoundKey e AES-128 completo (cifra e decifra do FIPS-197) (VCS) |
| `make lint_round` | Lint (`+lint=all,noVCDE`) dos módulos da Semana 3 (VCS) |
| `make sim_key_exp` | Testbench unitário da expansão de chave AES-128 (`minisoc_aes_key_exp`, 33 checks) |
| `make sim_dp_unit` | Testbench unitário do datapath AES-128 (`minisoc_aes_dp`, 24 checks) |
| `make sim_dp` | Testbench hierárquico integrado da Semana 4 (`tb_minisoc_aes_w04`, 57 checks) |
| `make lint_dp` | Lint (`+lint=all,noVCDE`) de `minisoc_aes_key_exp` e `minisoc_aes_dp` (VCS) |
| `make regress` | Roda toda a regressão de simulação e lint das Semanas 1 a 4 |
| `make clean` | Remove os artefatos gerados (`build/`) |
| `make help` | Lista os alvos |

## Estrutura

```text
.
├── docs/
│   ├── spec/               # Block Guide do MiniSoC AES (fornecido)
│   ├── architecture/       # microarquitetura e arquitetura de energia
│   └── reports/            # relatórios semanais (semana_XX.md)
├── rtl/
│   ├── minisoc_aes/        # transformações do AES, expansão de chave, datapath e engine
│   ├── minisoc_mem/        # memória (Semana 6)
│   ├── minisoc_pll/        # PLL mock (Semana 5)
│   ├── minisoc_spi/        # SPI (Semana 5)
│   └── minisoc_top.sv      # top-level (Semana 7)
├── tb/                     # testbenches modulares e modelo de referência
├── reports/                # relatórios de simulação e lint (.rpt), versionados
├── formal/                 # scripts e relatórios do Formality
├── syn/                    # SDC, scripts e relatórios de síntese
├── upf/                    # arquivos UPF e relatórios
└── scripts/                # automação (gen_aes_vectors.py gera a S-box e os vetores do FIPS-197)
```

## Requisitos de ferramenta

- Synopsys VCS (simulação)
- Lint do VCS (`+lint=all,noVCDE`)

## Status

- [x] Semana 1 — ambiente mínimo executando (`make sim` e `make lint`); tag `w01-setup-v1.0`
- [x] Semana 2 — desafio S-box, SubBytes e ShiftRows (`make sim_aes` e `make lint_aes`); tag `w02-sbox-shiftrows-v1.0`
- [x] Semana 3 — microarquitetura, MixColumns, AddRoundKey e transformações inversas (`make sim_round` e `make lint_round`); tag `w03-round-v1.0`
- [x] Semana 4 — expansão de chave (`minisoc_aes_key_exp`), datapath iterativo (`minisoc_aes_dp`) e testbenches modulares (`make sim_dp` e `make lint_dp`, 57 checks PASS); tag `w04-datapath-v1.0`
- [ ] Semana 5 — interface SPI slave (Mode 0, frame 40 bits, CDC por toggle) e PLL mock

Backlog completo em [`docs/backlog.md`](docs/backlog.md).
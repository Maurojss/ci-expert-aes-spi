// minisoc_pll_mock.sv
// Modelo comportamental do PLL (NAO sintetizavel; caixa-preta na sintese e no Formality).
//
//   enable = 0           : locked = 0 e sys_clk bloqueado em 0
//   enable = 1           : locked sobe depois de N ciclos de clk (N pseudoaleatorio)
//   div_sel (/1,/2,/4,/8): sys_clk = clk dividido; mudar div_sel (ou desabilitar)
//                          derruba locked e bloqueia sys_clk ate um novo lock
//
// N = LOCK_MIN + (LFSR[LOCK_BITS-1:0]), com LFSR de 16 bits (Galois, 0xB400) iniciado
// em SEED no reset. O LFSR avanca 16 passos a cada novo lock, entao a sequencia de
// latencias e REPRODUTIVEL: o verificador parceiro obtem os mesmos N com o mesmo SEED.
//
// sys_clk passa por um latch transparente em clk baixo (habilitacao e divisor), para
// nao gerar pulso parcial ao ligar. Alinhado ao ultimo ciclo: o primeiro flanco de
// sys_clk ocorre 1 ciclo de clk DEPOIS de locked subir.

module minisoc_pll_mock #(
    parameter logic [15:0] SEED      = 16'hACE1,
    parameter int          LOCK_MIN  = 8,    // ciclos de clk
    parameter int          LOCK_BITS = 5     // N em [LOCK_MIN, LOCK_MIN + 2**LOCK_BITS - 1]
) (
    input  logic       clk,         // referencia (sempre ligado)
    input  logic       rst_n,       // assincrono, ativo em baixo
    input  logic       enable,
    input  logic [1:0] div_sel,     // 00=/1  01=/2  10=/4  11=/8
    output logic       sys_clk,
    output logic       locked
);

    typedef enum logic [1:0] {S_OFF, S_LOCKING, S_LOCKED} state_t;

    state_t      state;
    logic [1:0]  div_applied;
    logic [15:0] lfsr;
    logic [15:0] lock_cnt;
    logic [15:0] lock_tgt;

    function automatic logic [15:0] lfsr_adv(input logic [15:0] s);
        logic [15:0] v;
        v = s;
        for (int i = 0; i < 16; i++)
            v = {1'b0, v[15:1]} ^ (v[0] ? 16'hB400 : 16'h0000);
        return v;
    endfunction

    logic [15:0] lfsr_nxt;
    assign lfsr_nxt = lfsr_adv(lfsr);

    // ---------------- sequenciador de lock ----------------
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state       <= S_OFF;
            div_applied <= 2'b00;
            lfsr        <= SEED;
            lock_cnt    <= 16'h0;
            lock_tgt    <= 16'(LOCK_MIN);
        end else begin
            case (state)
                S_OFF: begin
                    if (enable) begin
                        div_applied <= div_sel;
                        lfsr        <= lfsr_nxt;
                        lock_tgt    <= 16'(LOCK_MIN) + 16'(lfsr_nxt[LOCK_BITS-1:0]);
                        lock_cnt    <= 16'h0;
                        state       <= S_LOCKING;
                    end
                end
                S_LOCKING: begin
                    if (!enable) begin
                        state <= S_OFF;
                    end else if (div_sel != div_applied) begin       // reinicia o lock
                        div_applied <= div_sel;
                        lfsr        <= lfsr_nxt;
                        lock_tgt    <= 16'(LOCK_MIN) + 16'(lfsr_nxt[LOCK_BITS-1:0]);
                        lock_cnt    <= 16'h0;
                    end else if (lock_cnt + 16'd1 >= lock_tgt) begin
                        state <= S_LOCKED;
                    end else begin
                        lock_cnt <= lock_cnt + 16'd1;
                    end
                end
                S_LOCKED: begin
                    if (!enable) begin
                        state <= S_OFF;
                    end else if (div_sel != div_applied) begin       // reconfiguracao
                        div_applied <= div_sel;
                        lfsr        <= lfsr_nxt;
                        lock_tgt    <= 16'(LOCK_MIN) + 16'(lfsr_nxt[LOCK_BITS-1:0]);
                        lock_cnt    <= 16'h0;
                        state       <= S_LOCKING;
                    end
                end
                default: state <= S_OFF;
            endcase
        end
    end

    assign locked = (state == S_LOCKED);

    // ---------------- divisor ----------------
    logic [2:0] div_cnt;
    logic       div_clk;
    logic [2:0] div_half;

    always_comb begin                                  // meio periodo em ciclos de clk
        case (div_applied)
            2'd1:    div_half = 3'd1;                  // /2
            2'd2:    div_half = 3'd2;                  // /4
            2'd3:    div_half = 3'd4;                  // /8
            default: div_half = 3'd1;                  // /1: divisor nao e usado
        endcase
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            div_cnt <= 3'd0;
            div_clk <= 1'b0;
        end else if (state != S_LOCKED) begin
            div_cnt <= 3'd0;
            div_clk <= 1'b0;
        end else if (div_cnt == div_half - 3'd1) begin
            div_cnt <= 3'd0;
            div_clk <= ~div_clk;
        end else begin
            div_cnt <= div_cnt + 3'd1;
        end
    end

    // ---------------- saida de clock ----------------
    logic       en_lat;
    logic [1:0] sel_lat;

    always_latch begin
        if (!clk) begin
            en_lat  = (state == S_LOCKED);
            sel_lat = div_applied;
        end
    end

    assign sys_clk = en_lat & ((sel_lat == 2'b00) ? clk : div_clk);

endmodule

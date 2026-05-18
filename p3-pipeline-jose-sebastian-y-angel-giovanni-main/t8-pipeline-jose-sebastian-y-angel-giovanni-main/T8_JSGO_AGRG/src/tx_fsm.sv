/*
 * company: ITESO
 * engineer: Alvaro Gutierrez Arce
 * module description:
 *      UART transmit finite state machine (pure controller).
 *      sequences frame transmission from idle to active,
 *      driving load, shift, and clear signals to the datapath.
 * date: 03-15-2026
 */

// =============================================================================
// tx_fsm.sv
// UART Transmit FSM — pure controller, no datapath.
//   Block 1: State register
//   Block 2: Next-state logic (combinational)
//   Block 3: Mealy outputs (combinational)
// =============================================================================

module tx_fsm (
    input  logic clk,
    input  logic rst_n,       // async active-low
    input  logic utrst,       // PWREMU_MGMT.UTRST (0=hold reset)
    input  logic bclk,        // single-cycle pulse (16x/13x rate)
    // Status inputs (from datapath)
    input  logic thr_pending,
    input  logic bit_done,
    input  logic last_bit,
    input  logic thre,
    // Control outputs
    output logic tsr_load,
    output logic tsr_shift,
    output logic tsr_clr,
    output logic tx_counting,
    // Status output
    output logic temt
);

    // -----------------------------------------------------------------
    // FSM states
    // -----------------------------------------------------------------
    typedef enum logic {
        TX_IDLE,
        TX_ACTIVE
    } tx_state_t;

    tx_state_t state, next_state;

    // -----------------------------------------------------------------
    // TEMT — combinational
    // -----------------------------------------------------------------
    assign temt = (state == TX_IDLE) & thre;

    // -----------------------------------------------------------------
    // Block 1 — State register
    // -----------------------------------------------------------------
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= TX_IDLE;
        else if (!utrst)
            state <= TX_IDLE;
        else
            state <= next_state;
    end

    // -----------------------------------------------------------------
    // Block 2 — Next-state logic
    // -----------------------------------------------------------------
    always_comb begin
        next_state = state;
        case (state)
            TX_IDLE:
                if (thr_pending & bclk)
                    next_state = TX_ACTIVE;
            TX_ACTIVE:
                if (bit_done & last_bit & !thr_pending)
                    next_state = TX_IDLE;
        endcase
    end

    // -----------------------------------------------------------------
    // Block 3 — Combinational outputs (Mealy)
    // -----------------------------------------------------------------
    always_comb begin
        tsr_load    = 1'b0;
        tsr_shift   = 1'b0;
        tsr_clr     = 1'b0;
        tx_counting = 1'b0;

        if (!rst_n) begin
            // No combinational control during hardware reset
        end else if (!utrst) begin
            tsr_clr = 1'b1;
        end else begin
            case (state)
                TX_IDLE: begin
                    if (thr_pending & bclk)
                        tsr_load = 1'b1;
                end
                TX_ACTIVE: begin
                    tx_counting = 1'b1;
                    if (bit_done) begin
                        if (last_bit) begin
                            if (thr_pending)
                                tsr_load = 1'b1;
                        end else begin
                            tsr_shift = 1'b1;
                        end
                    end
                end
            endcase
        end
    end

endmodule

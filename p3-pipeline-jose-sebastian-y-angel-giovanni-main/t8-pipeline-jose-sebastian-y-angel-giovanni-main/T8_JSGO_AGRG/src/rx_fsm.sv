/*
 * company: ITESO
 * engineer: Alvaro Gutierrez Arce
 * module description:
 *      UART receive finite state machine (pure controller).
 *      handles idle detection, start-bit validation at the
 *      midpoint, and data frame reception with shift control.
 * date: 03-22-2026
 */

// =============================================================================
// rx_fsm.sv
// UART Receive FSM — pure controller, no datapath.
//   Block 1: State register
//   Block 2: Next-state logic (combinational)
//   Block 3: Mealy outputs (combinational)
// =============================================================================

module rx_fsm (
    input  logic clk,
    input  logic rst_n,          // async active-low
    input  logic urrst,          // PWREMU_MGMT.URRST (0=hold reset)
    input  logic bclk,           // single-cycle pulse (16x/13x rate)
    // Status inputs (from datapath)
    input  logic rxd_falling,    // falling edge on synchronized rxd
    input  logic mid_bit,        // bclk_cnt == half_osm_max (qualified with bclk)
    input  logic rxd_sync,       // synchronized rxd value (for start validation)
    input  logic bit_done,       // full bit period elapsed
    input  logic last_bit,       // bit_idx == frame_len_r - 1
    input  logic rxd_idle,       // rxd_sync == 1 (line is idle)
    // Control outputs
    output logic rsr_shift,      // shift bit into SIPO
    output logic rsr_clr,        // clear SIPO
    output logic rx_counting,    // oversampling counter active
    output logic frame_done,     // single-cycle pulse: frame complete
    output logic start_validate  // in RX_START, counting to midpoint
);

    // -----------------------------------------------------------------
    // FSM states
    // -----------------------------------------------------------------
    typedef enum logic [1:0] {
        RX_IDLE,
        RX_START,
        RX_ACTIVE
    } rx_state_t;

    rx_state_t state, next_state;

    // -----------------------------------------------------------------
    // Block 1 — State register
    // -----------------------------------------------------------------
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= RX_IDLE;
        else if (!urrst)
            state <= RX_IDLE;
        else
            state <= next_state;
    end

    // -----------------------------------------------------------------
    // Block 2 — Next-state logic
    // -----------------------------------------------------------------
    always_comb begin
        next_state = state;
        case (state)
            RX_IDLE:
                if (rxd_falling & rxd_idle)
                    next_state = RX_START;
            RX_START:
                if (mid_bit & !rxd_sync)
                    next_state = RX_ACTIVE;
                else if (mid_bit & rxd_sync)
                    next_state = RX_IDLE;
            RX_ACTIVE:
                if (bit_done & last_bit)
                    next_state = RX_IDLE;
            default:
                next_state = RX_IDLE;
        endcase
    end

    // -----------------------------------------------------------------
    // Block 3 — Combinational outputs (Mealy)
    // -----------------------------------------------------------------
    always_comb begin
        rsr_shift      = 1'b0;
        rsr_clr        = 1'b0;
        rx_counting    = 1'b0;
        frame_done     = 1'b0;
        start_validate = 1'b0;

        if (!rst_n) begin
            // No combinational control during hardware reset
        end else if (!urrst) begin
            rsr_clr = 1'b1;
        end else begin
            case (state)
                RX_IDLE: begin
                    if (rxd_falling & rxd_idle)
                        rsr_clr = 1'b1;
                end
                RX_START: begin
                    rx_counting    = 1'b1;
                    start_validate = 1'b1;
                    if (mid_bit & rxd_sync)
                        rx_counting = 1'b0;
                end
                RX_ACTIVE: begin
                    rx_counting = 1'b1;
                    if (bit_done) begin
                        rsr_shift = 1'b1;
                        if (last_bit) begin
                            frame_done  = 1'b1;
                            rx_counting = 1'b0;
                        end
                    end
                end
                default: ;
            endcase
        end
    end

endmodule

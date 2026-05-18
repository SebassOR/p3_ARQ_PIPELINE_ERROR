/*
 * company: ITESO
 * engineer: Alvaro Gutierrez Arce
 * module description:
 *      UART transmit datapath and timing module. implements
 *      frame assembly, parity computation, oversampling
 *      counters, and THR capture and pending management.
 * date: 03-15-2026
 */

// =============================================================================
// tx_timing_and_control.sv
// UART Transmit timing, datapath, and frame assembly.
// Instantiates tx_fsm for the controller (state register + next-state + Mealy
// outputs). Retains all combinational logic (parity, frame assembly, frame
// length, oversampling constants) and the registered datapath (counters,
// latches, THR capture).
// =============================================================================

module tx_timing_and_control
    import uart_reg_pkg::*;
(
    input  logic        clk,
    input  logic        rst_n,      // async active-low
    input  logic        bclk,       // single-cycle pulse (16x/13x rate)
    input  var lcr_t    lcr,        // WLS, STB, PEN, EPS, SP, BC
    input  logic [7:0]  thr_data,   // from CPU bus (w_data[7:0])
    input  logic        thr_we,     // pulse when CPU writes THR
    input  logic        utrst,      // PWREMU_MGMT.UTRST (0=hold reset)
    input  logic        osm_sel,    // MDR.OSM_SEL (0=16x, 1=13x)
    // To shift register
    output logic [11:0] frame_data, // assembled frame for parallel load
    output logic        tsr_load,
    output logic        tsr_shift,
    output logic        tsr_clr,
    // Status outputs
    output logic        thre,       // LSR.THRE
    output logic        temt        // LSR.TEMT
);

    // -----------------------------------------------------------------
    // Internal registers
    // -----------------------------------------------------------------
    logic           thr_pending;
    logic [7:0]     thr_latch;      // captured THR data (for parity + frame assembly)
    logic [3:0]     bit_idx;        // current frame bit (0..frame_len_r-1)
    logic [3:0]     frame_len_r;    // registered frame length for active frame
    logic [4:0]     bclk_cnt;       // sub-bit tick counter (0..osm_max)
    logic           half_stop_r;    // registered 1.5-stop flag for active frame

    // Wires driven by FSM instance
    logic           tx_counting;

    // -----------------------------------------------------------------
    // Oversampling constants
    // -----------------------------------------------------------------
    logic [4:0] osm_max;
    assign osm_max = osm_sel ? 5'd12 : 5'd15;

    logic [4:0] half_osm_max;
    assign half_osm_max = osm_sel ? 5'd6 : 5'd7;

    // Terminal count for the current bit
    logic [4:0] cur_osm_max;
    assign cur_osm_max = (half_stop_r && bit_idx == frame_len_r - 4'd1)
                         ? half_osm_max : osm_max;

    logic bit_done;
    assign bit_done = bclk & (bclk_cnt == cur_osm_max);

    logic last_bit;
    assign last_bit = (bit_idx == frame_len_r - 4'd1);

    // -----------------------------------------------------------------
    // Parity computation (combinational)
    // -----------------------------------------------------------------
    logic raw_parity;
    always_comb begin
        case (lcr.WLS)
            2'b00: raw_parity = ^thr_latch[4:0];
            2'b01: raw_parity = ^thr_latch[5:0];
            2'b10: raw_parity = ^thr_latch[6:0];
            2'b11: raw_parity = ^thr_latch[7:0];
        endcase
    end

    logic parity_bit;
    always_comb begin
        if (lcr.SP)
            parity_bit = lcr.EPS ? 1'b0 : 1'b1;
        else if (lcr.EPS)
            parity_bit = raw_parity;
        else
            parity_bit = ~raw_parity;
    end

    // -----------------------------------------------------------------
    // Frame data assembly (combinational)
    // Bit 0 = start (0), bits [N:1] = data, optional parity, rest = 1 (stop/idle)
    // -----------------------------------------------------------------
    logic [3:0] num_data;
    assign num_data = {2'b00, lcr.WLS} + 4'd5;

    always_comb begin
        frame_data = 12'hFFF;           // default: all 1s (stop/idle fill)
        frame_data[0] = 1'b0;          // start bit

        // Data bits (LSB first)
        for (int i = 0; i < 8; i++) begin
            if (i < int'(num_data))
                frame_data[1 + i] = thr_latch[i];
        end

        // Parity bit (if enabled)
        if (lcr.PEN)
            frame_data[1 + int'(num_data)] = parity_bit;
    end

    // -----------------------------------------------------------------
    // Frame length (combinational, registered at load time)
    // -----------------------------------------------------------------
    logic [3:0] frame_len;
    logic       is_half_stop;

    assign is_half_stop = (lcr.WLS == 2'b00) & lcr.STB;

    always_comb begin
        frame_len = 4'd1                           // start
                  + num_data                        // data (5-8)
                  + {3'd0, lcr.PEN}                 // parity (0 or 1)
                  + {3'd0, lcr.STB} + 4'd1;         // stop (1 or 2)
    end

    // -----------------------------------------------------------------
    // FSM instance (controller)
    // -----------------------------------------------------------------
    tx_fsm u_fsm (
        .clk         (clk),
        .rst_n       (rst_n),
        .utrst       (utrst),
        .bclk        (bclk),
        .thr_pending (thr_pending),
        .bit_done    (bit_done),
        .last_bit    (last_bit),
        .thre        (thre),
        .tsr_load    (tsr_load),
        .tsr_shift   (tsr_shift),
        .tsr_clr     (tsr_clr),
        .tx_counting (tx_counting),
        .temt        (temt)
    );

    // -----------------------------------------------------------------
    // Registered datapath
    // -----------------------------------------------------------------
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            thr_pending <= 1'b0;
            thr_latch   <= 8'd0;
            bit_idx     <= 4'd0;
            frame_len_r <= 4'd0;
            bclk_cnt    <= 5'd0;
            half_stop_r <= 1'b0;
            thre        <= 1'b1;
        end else if (!utrst) begin
            thr_pending <= 1'b0;
            thr_latch   <= 8'd0;
            bit_idx     <= 4'd0;
            frame_len_r <= 4'd0;
            bclk_cnt    <= 5'd0;
            half_stop_r <= 1'b0;
            // thre not cleared — CPU-facing state
        end else begin
            // Control-signal driven datapath (no FSM state dependency)
            if (tsr_load) begin
                thr_pending <= 1'b0;
                thre        <= 1'b1;
                bit_idx     <= 4'd0;
                bclk_cnt    <= 5'd0;
                frame_len_r <= frame_len;
                half_stop_r <= is_half_stop;
            end else if (tsr_shift) begin
                bit_idx  <= bit_idx + 4'd1;
                bclk_cnt <= 5'd0;
            end else if (tx_counting & bclk) begin
                bclk_cnt <= (bclk_cnt == cur_osm_max) ? 5'd0 : bclk_cnt + 5'd1;
            end

            // THR pending + data capture — after datapath so last-write-wins
            if (thr_we) begin
                thr_pending <= 1'b1;
                thr_latch   <= thr_data;
                thre        <= 1'b0;
            end
        end
    end

endmodule

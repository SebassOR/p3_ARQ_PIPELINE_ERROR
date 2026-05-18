/*
 * company: ITESO
 * engineer: Alvaro Gutierrez Arce
 * module description:
 *      UART receive datapath and timing module. implements
 *      oversampling counters, frame disassembly, parity and
 *      framing error detection, and RX register file writes.
 * date: 03-22-2026
 */

// =============================================================================
// rx_timing_and_control.sv
// UART Receive timing, datapath, and frame disassembly.
// Instantiates rx_fsm for the controller. Retains all combinational logic
// (frame length, oversampling, edge detection) and the registered datapath
// (counters, LCR snapshot, frame disassembly on completion).
// =============================================================================

module rx_timing_and_control
    import uart_reg_pkg::*;
(
    input  logic        clk,
    input  logic        rst_n,
    input  logic        bclk,
    input  var lcr_t    lcr,
    input  logic        urrst,       // PWREMU_MGMT.URRST (0=hold reset)
    input  logic        osm_sel,     // MDR.OSM_SEL (0=16x, 1=13x)
    input  logic        rxd_sync,    // from 2-FF sync in uart.sv
    input  logic        lsr_dr,      // current DR flag (for overrun detection)
    // To/from SIPO register
    output logic        rsr_shift,
    output logic        rsr_clr,
    input  logic [11:0] rsr_data,    // SIPO parallel_out
    // To register file (HW write ports)
    output logic [7:0]  rbr_data,
    output logic        rbr_we,
    output logic        lsr_dr_set,
    output logic        lsr_oe_set,
    output logic        lsr_pe_set,
    output logic        lsr_fe_set,
    output logic        lsr_bi_set
);

    // -----------------------------------------------------------------
    // Internal registers
    // -----------------------------------------------------------------
    logic [3:0]  bit_idx;
    logic [3:0]  frame_len_r;
    logic [4:0]  bclk_cnt;
    logic        rxd_prev;
    logic        rxd_idle;

    // Registered LCR snapshot (latched at start-bit validation)
    logic [3:0]  num_data_r;
    logic        pen_r;
    logic [1:0]  wls_r;
    logic        eps_r;
    logic        sp_r;

    // Wires driven by FSM instance
    logic        rx_counting;
    logic        frame_done;
    logic        start_validate;

    // -----------------------------------------------------------------
    // Oversampling constants
    // -----------------------------------------------------------------
    logic [4:0] osm_max;
    assign osm_max = osm_sel ? 5'd12 : 5'd15;

    logic [4:0] half_osm_max;
    assign half_osm_max = osm_sel ? 5'd6 : 5'd7;

    // RX always samples 1 stop bit — no cur_osm_max needed
    logic bit_done;
    assign bit_done = bclk & (bclk_cnt == osm_max);

    logic last_bit;
    assign last_bit = (bit_idx == frame_len_r - 4'd1);

    logic mid_bit;
    assign mid_bit = (bclk_cnt == half_osm_max);

    // -----------------------------------------------------------------
    // Edge detection
    // -----------------------------------------------------------------
    logic rxd_falling;
    assign rxd_falling = rxd_prev & !rxd_sync;

    // -----------------------------------------------------------------
    // Frame length (combinational — RX always checks 1 stop bit)
    // -----------------------------------------------------------------
    logic [3:0] num_data;
    assign num_data = {2'b00, lcr.WLS} + 4'd5;

    logic [3:0] frame_len;
    assign frame_len = num_data + {3'd0, lcr.PEN} + 4'd1;

    // -----------------------------------------------------------------
    // FSM instance (controller)
    // -----------------------------------------------------------------
    rx_fsm u_fsm (
        .clk            (clk),
        .rst_n          (rst_n),
        .urrst          (urrst),
        .bclk           (bclk),
        .rxd_falling    (rxd_falling),
        .mid_bit        (mid_bit & bclk),
        .rxd_sync       (rxd_sync),
        .bit_done       (bit_done),
        .last_bit       (last_bit),
        .rxd_idle       (rxd_idle),
        .rsr_shift      (rsr_shift),
        .rsr_clr        (rsr_clr),
        .rx_counting    (rx_counting),
        .frame_done     (frame_done),
        .start_validate (start_validate)
    );

    // -----------------------------------------------------------------
    // Frame disassembly (combinational from registered snapshot)
    // -----------------------------------------------------------------
    logic [3:0] base;
    logic       parity_rcvd;
    logic       raw_parity;
    logic       expected_parity;
    logic       pe;
    logic       fe;
    logic       bi;
    logic       oe;

    always_comb begin
        base = 4'd12 - frame_len_r;

        // Data extraction
        rbr_data = 8'd0;
        for (int i = 0; i < 8; i++) begin
            if (i < int'(num_data_r))
                rbr_data[i] = rsr_data[int'(base) + i];
        end

        // Parity check
        parity_rcvd = rsr_data[int'(base) + int'(num_data_r)];
        case (wls_r)
            2'b00: raw_parity = ^rbr_data[4:0];
            2'b01: raw_parity = ^rbr_data[5:0];
            2'b10: raw_parity = ^rbr_data[6:0];
            2'b11: raw_parity = ^rbr_data[7:0];
        endcase

        if (sp_r)
            expected_parity = eps_r ? 1'b0 : 1'b1;
        else if (eps_r)
            expected_parity = raw_parity;
        else
            expected_parity = ~raw_parity;

        pe = pen_r & (parity_rcvd != expected_parity);

        // Stop bit check
        fe = !rsr_data[int'(base) + int'(num_data_r) + int'({3'd0, pen_r})];

        // Break detection: all bits (including stop) are zero
        bi = 1'b1;
        for (int i = 0; i < 12; i++) begin
            if (i >= int'(base) && i < int'(base) + int'(frame_len_r))
                if (rsr_data[i])
                    bi = 1'b0;
        end

        // Overrun: DR still set when new frame arrives
        oe = lsr_dr;
    end

    // -----------------------------------------------------------------
    // Registered datapath
    // -----------------------------------------------------------------
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bclk_cnt    <= 5'd0;
            bit_idx     <= 4'd0;
            frame_len_r <= 4'd0;
            rxd_prev    <= 1'b1;
            rxd_idle    <= 1'b1;
            num_data_r  <= 4'd0;
            pen_r       <= 1'b0;
            wls_r       <= 2'b00;
            eps_r       <= 1'b0;
            sp_r        <= 1'b0;
            rbr_we      <= 1'b0;
            lsr_dr_set  <= 1'b0;
            lsr_oe_set  <= 1'b0;
            lsr_pe_set  <= 1'b0;
            lsr_fe_set  <= 1'b0;
            lsr_bi_set  <= 1'b0;
        end else if (!urrst) begin
            bclk_cnt    <= 5'd0;
            bit_idx     <= 4'd0;
            frame_len_r <= 4'd0;
            rxd_prev    <= 1'b1;
            rxd_idle    <= 1'b1;
            num_data_r  <= 4'd0;
            pen_r       <= 1'b0;
            wls_r       <= 2'b00;
            eps_r       <= 1'b0;
            sp_r        <= 1'b0;
            rbr_we      <= 1'b0;
            lsr_dr_set  <= 1'b0;
            lsr_oe_set  <= 1'b0;
            lsr_pe_set  <= 1'b0;
            lsr_fe_set  <= 1'b0;
            lsr_bi_set  <= 1'b0;
        end else begin
            // Default: single-cycle pulses
            rbr_we     <= 1'b0;
            lsr_dr_set <= 1'b0;
            lsr_oe_set <= 1'b0;
            lsr_pe_set <= 1'b0;
            lsr_fe_set <= 1'b0;
            lsr_bi_set <= 1'b0;

            // Edge detect: always update
            rxd_prev <= rxd_sync;

            // rxd_idle tracking
            if (rxd_sync)
                rxd_idle <= 1'b1;
            if (rxd_falling)
                rxd_idle <= 1'b0;

            // Start-bit validated at midpoint
            if (start_validate & mid_bit & bclk & !rxd_sync) begin
                frame_len_r <= frame_len;
                num_data_r  <= num_data;
                pen_r       <= lcr.PEN;
                wls_r       <= lcr.WLS;
                eps_r       <= lcr.EPS;
                sp_r        <= lcr.SP;
                bit_idx     <= 4'd0;
                bclk_cnt    <= 5'd0;
            end
            // Bit sampling
            else if (rsr_shift) begin
                bit_idx  <= bit_idx + 4'd1;
                bclk_cnt <= 5'd0;
                if (frame_done) begin
                    rbr_we     <= 1'b1;
                    lsr_dr_set <= 1'b1;
                    lsr_pe_set <= pe;
                    lsr_fe_set <= fe;
                    lsr_bi_set <= bi;
                    lsr_oe_set <= oe;
                end
            end
            // Counting
            else if (rx_counting & bclk) begin
                bclk_cnt <= bclk_cnt + 5'd1;
            end
        end
    end

endmodule

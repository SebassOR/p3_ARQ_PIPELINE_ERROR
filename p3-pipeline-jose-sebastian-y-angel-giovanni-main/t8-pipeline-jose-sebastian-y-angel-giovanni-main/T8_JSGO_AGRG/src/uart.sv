/*
 * company: ITESO
 * engineer: Alvaro Gutierrez Arce
 * module description:
 *      TI KeyStone-style UART top module. integrates the baud
 *      generator, register file, TX/RX shift registers, and
 *      TX/RX timing and control submodules.
 * date: 03-15-2026
 */

// =============================================================================
// uart.sv
// TI KeyStone UART Top Module
// Wires register file to baud generator. Divisor is read directly from
// {DLH, DLL}; baud generator is gated by UTRST so the programmer must
// disable TX before reconfiguring divisor/LCR.
// =============================================================================

module uart
    import uart_reg_pkg::*;
(
    input  logic                  clk,
    input  logic                  rst_n,
    input  logic                  we,
    input  logic                  re,
    input  logic [5:0]            addr,
    input  logic [31:0]           w_data,
    output logic [31:0]           r_data,
    output logic                  uart_txd,
    input  logic                  uart_rxd
);

    // -----------------------------------------------------------------
    // Internal signals
    // -----------------------------------------------------------------
    uart_addr_t  addr_e;
    assign addr_e = uart_addr_t'(addr);

    uart_regs_t  regs;

    logic        bclk;              // baud clock pulse (internal)
    logic        thr_we;            // THR write detect
    logic        tx_thre;           // from uart_tx → LSR.THRE
    logic        tx_temt;           // from uart_tx → LSR.TEMT

    // RX path signals
    logic        rxd_meta, rxd_sync;
    logic        rsr_shift_w, rsr_clr_w;
    logic [11:0] rsr_data_w;
    logic [7:0]  rbr_data_w;
    logic        rbr_we_w;
    logic        lsr_dr_set_w, lsr_oe_set_w, lsr_pe_set_w, lsr_fe_set_w, lsr_bi_set_w;

    // -----------------------------------------------------------------
    // Register file instance
    // -----------------------------------------------------------------
    uart_reg_file u_reg_file (
        .clk            (clk),
        .rst_n          (rst_n),
        .we             (we),
        .re             (re),
        .w_addr         (addr_e),
        .w_data         (w_data),
        .r_addr         (addr_e),
        .r_data         (r_data),
        .regs           (regs),
        .lsr_thre_hw    (tx_thre),
        .lsr_temt_hw    (tx_temt),
        .rbr_data_hw    (rbr_data_w),
        .rbr_we_hw      (rbr_we_w),
        .lsr_dr_set_hw  (lsr_dr_set_w),
        .lsr_oe_set_hw  (lsr_oe_set_w),
        .lsr_pe_set_hw  (lsr_pe_set_w),
        .lsr_fe_set_hw  (lsr_fe_set_w),
        .lsr_bi_set_hw  (lsr_bi_set_w)
    );

    // -----------------------------------------------------------------
    // Baud generator instance
    // Gated by UTRST and divisor!=0 to stop counter during configuration
    // -----------------------------------------------------------------
    logic baud_en;
    assign baud_en = ({regs.DLH.DLH, regs.DLL.DLL} != 16'd0)
                   & (regs.PWREMU_MGMT.UTRST | regs.PWREMU_MGMT.URRST);

    baud_generator #(
        .WIDTH(16)
    ) u_baud_gen (
        .clk          (clk),
        .rst_n        (rst_n),
        .clr          (~baud_en),
        .en           (baud_en),
        .divisorValue ({regs.DLH.DLH, regs.DLL.DLL}),
        .bclk         (bclk)
    );

    // -----------------------------------------------------------------
    // THR write detection (combinational)
    // -----------------------------------------------------------------
    assign thr_we = we & (addr_e == ADDR_RBR_THR);

    // -----------------------------------------------------------------
    // Shift register ↔ control interconnect
    // -----------------------------------------------------------------
    logic        serial_out_w;
    logic [11:0] frame_data_w;
    logic        tsr_load_w;
    logic        tsr_shift_w;
    logic        tsr_clr_w;

    // -----------------------------------------------------------------
    // TX shift register instance
    // -----------------------------------------------------------------
    piso_register #(
        .WIDTH          (12),
        .RESET_VALUE    (12'hfff),
        .SHIFT_PAD      (1'b1)
    ) u_transmitter_shift_register (
        .clk        (clk),
        .rst_n      (rst_n),
        .clr        (tsr_clr_w),
        .load       (tsr_load_w),
        .enable     (tsr_shift_w),
        .data       (frame_data_w),
        .serial_out (serial_out_w)
    );

    // -----------------------------------------------------------------
    // TX timing and control instance
    // -----------------------------------------------------------------
    tx_timing_and_control u_transmitter_timing_and_control (
        .clk        (clk),
        .rst_n      (rst_n),
        .bclk       (bclk),
        .lcr        (regs.LCR),
        .thr_data   (w_data[7:0]),          // direct from bus (not regs.THR.DATA)
        .thr_we     (thr_we),
        .utrst      (regs.PWREMU_MGMT.UTRST),
        .osm_sel    (regs.MDR.OSM_SEL),
        .frame_data (frame_data_w),
        .tsr_load   (tsr_load_w),
        .tsr_shift  (tsr_shift_w),
        .tsr_clr    (tsr_clr_w),
        .thre       (tx_thre),
        .temt       (tx_temt)
    );

    // -----------------------------------------------------------------
    // uart_txd — combinational from shift register with break override
    // -----------------------------------------------------------------
    assign uart_txd = regs.LCR.BC ? 1'b0 : serial_out_w;

    // -----------------------------------------------------------------
    // 2-FF synchronizer for uart_rxd (metastability protection)
    // -----------------------------------------------------------------
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rxd_meta <= 1'b1;
            rxd_sync <= 1'b1;
        end else begin
            rxd_meta <= uart_rxd;
            rxd_sync <= rxd_meta;
        end
    end

    // -----------------------------------------------------------------
    // RX shift register instance (SIPO)
    // -----------------------------------------------------------------
    sipo_register #(
        .WIDTH       (12),
        .RESET_VALUE (12'hFFF)
    ) u_receiver_shift_register (
        .clk          (clk),
        .rst_n        (rst_n),
        .clr          (rsr_clr_w),
        .enable       (rsr_shift_w),
        .serial_in    (rxd_sync),
        .parallel_out (rsr_data_w)
    );

    // -----------------------------------------------------------------
    // RX timing and control instance
    // -----------------------------------------------------------------
    rx_timing_and_control u_receiver_timing_and_control (
        .clk        (clk),
        .rst_n      (rst_n),
        .bclk       (bclk),
        .lcr        (regs.LCR),
        .urrst      (regs.PWREMU_MGMT.URRST),
        .osm_sel    (regs.MDR.OSM_SEL),
        .rxd_sync   (rxd_sync),
        .lsr_dr     (regs.LSR.DR),
        .rsr_shift  (rsr_shift_w),
        .rsr_clr    (rsr_clr_w),
        .rsr_data   (rsr_data_w),
        .rbr_data   (rbr_data_w),
        .rbr_we     (rbr_we_w),
        .lsr_dr_set (lsr_dr_set_w),
        .lsr_oe_set (lsr_oe_set_w),
        .lsr_pe_set (lsr_pe_set_w),
        .lsr_fe_set (lsr_fe_set_w),
        .lsr_bi_set (lsr_bi_set_w)
    );

endmodule

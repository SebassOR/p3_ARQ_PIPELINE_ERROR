/*
 * company: ITESO
 * engineer: Alvaro Gutierrez Arce
 * module description:
 *      TI KeyStone UART memory-mapped register file. provides
 *      CPU read/write interface with address decode, hardware
 *      write ports for the RX path, and clear-on-read behavior.
 * date: 03-15-2026
 */

// =============================================================================
// uart_reg_file.sv
// TI KeyStone UART MMIO Register File
// CPU-facing write/read interface with address decode.
// Combinational `regs` output consumed by all UART sub-modules.
// Reset: asynchronous active-low (rst_n).
// =============================================================================

module uart_reg_file
    import uart_reg_pkg::*;
(
    input  logic                  clk,
    input  logic                  rst_n,      // async active-low reset
    input  logic                  we,
    input  logic                  re,         // read enable (CPU read strobe)
    input  uart_addr_t            w_addr,     // byte address (enum)
    input  logic [31:0]           w_data,
    input  uart_addr_t            r_addr,
    input  logic                  lsr_thre_hw,
    input  logic                  lsr_temt_hw,
    // RX HW write ports
    input  logic [7:0]            rbr_data_hw,
    input  logic                  rbr_we_hw,
    input  logic                  lsr_dr_set_hw,
    input  logic                  lsr_oe_set_hw,
    input  logic                  lsr_pe_set_hw,
    input  logic                  lsr_fe_set_hw,
    input  logic                  lsr_bi_set_hw,
    output logic [31:0]           r_data,
    output uart_regs_t            regs        // combinational
);

    // -------------------------------------------------------------------------
    // Register index constants
    // -------------------------------------------------------------------------
    localparam int NUM_REGS = 16;

    localparam int REG_RBR    = 0;
    localparam int REG_THR    = 1;
    localparam int REG_IER    = 2;
    localparam int REG_IIR    = 3;
    localparam int REG_FCR    = 4;
    localparam int REG_LCR    = 5;
    localparam int REG_MCR    = 6;
    localparam int REG_LSR    = 7;
    localparam int REG_MSR    = 8;
    localparam int REG_SCR    = 9;
    localparam int REG_DLL    = 10;
    localparam int REG_DLH    = 11;
    localparam int REG_REVID1 = 12;
    localparam int REG_REVID2 = 13;
    localparam int REG_PWREMU = 14;
    localparam int REG_MDR    = 15;

    // -------------------------------------------------------------------------
    // Reset values
    // -------------------------------------------------------------------------
    localparam logic [31:0] REG_RST_VAL[NUM_REGS] = '{
        32'h00000000,  // RBR
        32'h00000000,  // THR
        32'h00000000,  // IER
        32'h00000001,  // IIR  (IPEND=1 = no interrupt pending)
        32'h00000000,  // FCR
        32'h00000000,  // LCR
        32'h00000000,  // MCR
        32'h00000060,  // LSR  (TEMT=1, THRE=1)
        32'h00000000,  // MSR
        32'h00000000,  // SCR
        32'h00000000,  // DLL
        32'h00000000,  // DLH
        32'h11020002,  // REVID1 (constant from spec)
        32'h00000000,  // REVID2
        32'h00001FFE,  // PWREMU_MGMT (bits [12:1] reserved=1)
        32'h00000000   // MDR
    };

    // -------------------------------------------------------------------------
    // Internal register storage
    // -------------------------------------------------------------------------
    logic [31:0] reg_array[NUM_REGS];

    // -------------------------------------------------------------------------
    // Read-event signals (for clear-on-read behavior)
    // -------------------------------------------------------------------------
    logic rbr_rd;
    assign rbr_rd = re & (r_addr == ADDR_RBR_THR);   // clears DR, PE, FE, BI

    logic lsr_rd;
    assign lsr_rd = re & (r_addr == ADDR_LSR);        // clears OE

    // -------------------------------------------------------------------------
    // Write logic — synchronous, async active-low reset
    // -------------------------------------------------------------------------
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (int i = 0; i < NUM_REGS; i++) begin
                reg_array[i] <= REG_RST_VAL[i];
            end
        end else begin
            // Read-only registers: hold at reset value (no HW write ports yet)
            reg_array[REG_IIR]    <= REG_RST_VAL[REG_IIR];
            reg_array[REG_MSR]    <= REG_RST_VAL[REG_MSR];
            reg_array[REG_REVID1] <= REG_RST_VAL[REG_REVID1];
            reg_array[REG_REVID2] <= REG_RST_VAL[REG_REVID2];

            // RBR — HW write from RX path
            if (rbr_we_hw)
                reg_array[REG_RBR][7:0] <= rbr_data_hw;

            // LSR — per-bit control with HW set and read-clear
            reg_array[REG_LSR][31:8] <= 24'd0;
            reg_array[REG_LSR][7]    <= 1'b0;              // RXFIFOE (deferred)
            reg_array[REG_LSR][6]    <= lsr_temt_hw;        // TEMT
            reg_array[REG_LSR][5]    <= lsr_thre_hw;        // THRE
            // RX error/status bits: HW set wins over read-clear
            reg_array[REG_LSR][4] <= lsr_bi_set_hw ? 1'b1 : (rbr_rd ? 1'b0 : reg_array[REG_LSR][4]);
            reg_array[REG_LSR][3] <= lsr_fe_set_hw ? 1'b1 : (rbr_rd ? 1'b0 : reg_array[REG_LSR][3]);
            reg_array[REG_LSR][2] <= lsr_pe_set_hw ? 1'b1 : (rbr_rd ? 1'b0 : reg_array[REG_LSR][2]);
            reg_array[REG_LSR][1] <= lsr_oe_set_hw ? 1'b1 : (lsr_rd ? 1'b0 : reg_array[REG_LSR][1]);
            reg_array[REG_LSR][0] <= lsr_dr_set_hw ? 1'b1 : (rbr_rd ? 1'b0 : reg_array[REG_LSR][0]);

            if (we) begin
                case (w_addr)
                    ADDR_RBR_THR:       reg_array[REG_THR]    <= w_data;
                    ADDR_IER:           reg_array[REG_IER]    <= w_data;
                    ADDR_IIR_FCR:       reg_array[REG_FCR]    <= w_data;
                    ADDR_LCR:           reg_array[REG_LCR]    <= w_data;
                    ADDR_MCR:           reg_array[REG_MCR]    <= w_data;
                    ADDR_SCR:           reg_array[REG_SCR]    <= w_data;
                    ADDR_DLL:           reg_array[REG_DLL]    <= w_data;
                    ADDR_DLH:           reg_array[REG_DLH]    <= w_data;
                    ADDR_PWREMU_MGMT:   reg_array[REG_PWREMU] <= w_data;
                    ADDR_MDR:           reg_array[REG_MDR]    <= w_data;
                    default:            ;
                endcase
            end
        end
    end

    // -------------------------------------------------------------------------
    // Read logic — combinational
    // -------------------------------------------------------------------------
    always_comb begin
        case (r_addr)
            ADDR_RBR_THR:       r_data = reg_array[REG_RBR];
            ADDR_IER:           r_data = reg_array[REG_IER];
            ADDR_IIR_FCR:       r_data = reg_array[REG_IIR]; // always IIR on read
            ADDR_LCR:           r_data = reg_array[REG_LCR];
            ADDR_MCR:           r_data = reg_array[REG_MCR];
            ADDR_LSR:           r_data = reg_array[REG_LSR];
            ADDR_MSR:           r_data = reg_array[REG_MSR];
            ADDR_SCR:           r_data = reg_array[REG_SCR];
            ADDR_DLL:           r_data = reg_array[REG_DLL];
            ADDR_DLH:           r_data = reg_array[REG_DLH];
            ADDR_REVID1:        r_data = reg_array[REG_REVID1];
            ADDR_REVID2:        r_data = reg_array[REG_REVID2];
            ADDR_PWREMU_MGMT:   r_data = reg_array[REG_PWREMU];
            ADDR_MDR:           r_data = reg_array[REG_MDR];
            default:            r_data = 32'h0;
        endcase
    end

    // -------------------------------------------------------------------------
    // Combinational regs output — struct fields from reg_array
    // -------------------------------------------------------------------------
    always_comb begin
        regs.RBR          = rbr_t'(reg_array[REG_RBR]);
        regs.THR          = thr_t'(reg_array[REG_THR]);
        regs.IER          = ier_t'(reg_array[REG_IER]);
        regs.IIR          = iir_t'(reg_array[REG_IIR]);
        regs.FCR          = fcr_t'(reg_array[REG_FCR]);
        regs.LCR          = lcr_t'(reg_array[REG_LCR]);
        regs.MCR          = mcr_t'(reg_array[REG_MCR]);
        regs.LSR          = lsr_t'(reg_array[REG_LSR]);
        regs.MSR          = msr_t'(reg_array[REG_MSR]);
        regs.SCR          = scr_t'(reg_array[REG_SCR]);
        regs.DLL          = dll_t'(reg_array[REG_DLL]);
        regs.DLH          = dlh_t'(reg_array[REG_DLH]);
        regs.REVID1       = revid1_t'(reg_array[REG_REVID1]);
        regs.REVID2       = revid2_t'(reg_array[REG_REVID2]);
        regs.PWREMU_MGMT  = pwremu_mgmt_t'(reg_array[REG_PWREMU]);
        regs.MDR          = mdr_t'(reg_array[REG_MDR]);
    end

endmodule

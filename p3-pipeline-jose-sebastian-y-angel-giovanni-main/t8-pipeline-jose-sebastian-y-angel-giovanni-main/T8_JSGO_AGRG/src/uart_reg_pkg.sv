/*
 * company: ITESO
 * engineer: Alvaro Gutierrez Arce
 * module description:
 *      SystemVerilog package defining all TI KeyStone UART
 *      register structs, the full register map type, and the
 *      MMIO byte-address enumeration for waveform readability.
 * date: 03-15-2026
 */

// =============================================================================
// uart_reg_pkg.sv
// TI KeyStone UART register definitions package
// All structs are 32-bit packed. Field order: LSB → MSB within each struct.
// =============================================================================

package uart_reg_pkg;

    // -------------------------------------------------------------------------
    // RBR – Receiver Buffer Register (offset 0x00, read-only)
    // -------------------------------------------------------------------------
    typedef struct packed {
        logic [23:0] reserved;
        logic [7:0]  DATA;
    } rbr_t;

    // -------------------------------------------------------------------------
    // THR – Transmitter Holding Register (offset 0x00, write-only)
    // -------------------------------------------------------------------------
    typedef struct packed {
        logic [23:0] reserved;
        logic [7:0]  DATA;
    } thr_t;

    // -------------------------------------------------------------------------
    // IER – Interrupt Enable Register (offset 0x04)
    // -------------------------------------------------------------------------
    typedef struct packed {
        logic [27:0] reserved;
        logic        EDSSI;   // Enable Modem Status Interrupt
        logic        ELSI;    // Enable Receiver Line Status Interrupt
        logic        ETBEI;   // Enable Transmitter Holding Register Empty Interrupt
        logic        ERBI;    // Enable Received Data Available Interrupt
    } ier_t;

    // -------------------------------------------------------------------------
    // IIR – Interrupt Identification Register (offset 0x08, read-only)
    // -------------------------------------------------------------------------
    typedef struct packed {
        logic [23:0] reserved;
        logic [1:0]  FIFOEN;  // FIFO Enable status [7:6]
        logic [1:0]  reserved2; // [5:4]
        logic [2:0]  INTID;   // Interrupt ID [3:1]
        logic        IPEND;   // Interrupt Pending (0=pending, 1=none)
    } iir_t;

    // -------------------------------------------------------------------------
    // FCR – FIFO Control Register (offset 0x08, write-only)
    // -------------------------------------------------------------------------
    typedef struct packed {
        logic [23:0] reserved;
        logic [1:0]  RXFIFTL; // RX FIFO Trigger Level [7:6]
        logic [1:0]  reserved2; // [5:4]
        logic        DMAMODE1; // DMA Mode Select
        logic        TXCLR;   // TX FIFO Clear
        logic        RXCLR;   // RX FIFO Clear
        logic        FIFOEN;  // FIFO Enable
    } fcr_t;

    // -------------------------------------------------------------------------
    // LCR – Line Control Register (offset 0x0C)
    // -------------------------------------------------------------------------
    typedef struct packed {
        logic [23:0] reserved;
        logic        _reserved7; // bit 7 reserved (was DLAB)
        logic        BC;      // Break Control
        logic        SP;      // Stick Parity
        logic        EPS;     // Even Parity Select
        logic        PEN;     // Parity Enable
        logic        STB;     // Number of Stop Bits
        logic [1:0]  WLS;     // Word Length Select
    } lcr_t;

    // -------------------------------------------------------------------------
    // MCR – Modem Control Register (offset 0x10)
    // -------------------------------------------------------------------------
    typedef struct packed {
        logic [25:0] reserved;
        logic        AFE;     // Auto Flow Control Enable
        logic        LOOP;    // Loop Back Mode
        logic        OUT2;    // User Output 2
        logic        OUT1;    // User Output 1
        logic        RTS;     // Request To Send
        logic        reserved2; // bit 0 reserved
    } mcr_t;

    // -------------------------------------------------------------------------
    // LSR – Line Status Register (offset 0x14, read-only)
    // -------------------------------------------------------------------------
    typedef struct packed {
        logic [23:0] reserved;
        logic        RXFIFOE; // RX FIFO Error
        logic        TEMT;    // Transmitter Empty
        logic        THRE;    // Transmitter Holding Register Empty
        logic        BI;      // Break Interrupt
        logic        FE;      // Framing Error
        logic        PE;      // Parity Error
        logic        OE;      // Overrun Error
        logic        DR;      // Data Ready
    } lsr_t;

    // -------------------------------------------------------------------------
    // MSR – Modem Status Register (offset 0x18, read-only)
    // -------------------------------------------------------------------------
    typedef struct packed {
        logic [23:0] reserved;
        logic        CD;      // Carrier Detect
        logic        RI;      // Ring Indicator
        logic        DSR;     // Data Set Ready
        logic        CTS;     // Clear To Send
        logic        DCD;     // Delta Carrier Detect
        logic        TERI;    // Trailing Edge Ring Indicator
        logic        DDSR;    // Delta Data Set Ready
        logic        DCTS;    // Delta Clear To Send
    } msr_t;

    // -------------------------------------------------------------------------
    // SCR – Scratch Register (offset 0x1C)
    // -------------------------------------------------------------------------
    typedef struct packed {
        logic [23:0] reserved;
        logic [7:0]  SCR;
    } scr_t;

    // -------------------------------------------------------------------------
    // DLL – Divisor LSB Latch (offset 0x20)
    // -------------------------------------------------------------------------
    typedef struct packed {
        logic [23:0] reserved;
        logic [7:0]  DLL;
    } dll_t;

    // -------------------------------------------------------------------------
    // DLH – Divisor MSB Latch (offset 0x24)
    // -------------------------------------------------------------------------
    typedef struct packed {
        logic [23:0] reserved;
        logic [7:0]  DLH;
    } dlh_t;

    // -------------------------------------------------------------------------
    // REVID1 – Revision ID 1 (offset 0x28, read-only constant)
    // -------------------------------------------------------------------------
    typedef struct packed {
        logic [31:0] REVID1;  // Full 32-bit revision constant
    } revid1_t;

    // -------------------------------------------------------------------------
    // REVID2 – Revision ID 2 (offset 0x2C, read-only constant)
    // -------------------------------------------------------------------------
    typedef struct packed {
        logic [23:0] reserved;
        logic [7:0]  REVID2;
    } revid2_t;

    // -------------------------------------------------------------------------
    // PWREMU_MGMT – Power and Emulation Management (offset 0x30)
    // -------------------------------------------------------------------------
    typedef struct packed {
        logic [16:0] reserved2; // [31:15]
        logic        UTRST;    // UART Transmitter Reset (bit 14)
        logic        URRST;    // UART Receiver Reset (bit 13)
        logic [11:0] reserved1; // [12:1]
        logic        FREE;     // Free-Running Mode (bit 0)
    } pwremu_mgmt_t;

    // -------------------------------------------------------------------------
    // MDR – Mode Definition Register (offset 0x34)
    // -------------------------------------------------------------------------
    typedef struct packed {
        logic [30:0] reserved;
        logic        OSM_SEL;  // Over-Sampling Mode Select
    } mdr_t;

    // =========================================================================
    // uart_regs_t – Full UART memory map struct (packed, MSB→LSB = high→low addr)
    // =========================================================================
    typedef struct packed {
        mdr_t           MDR;          // offset 0x34
        pwremu_mgmt_t   PWREMU_MGMT;  // offset 0x30
        revid2_t        REVID2;       // offset 0x2C
        revid1_t        REVID1;       // offset 0x28
        dlh_t           DLH;          // offset 0x24
        dll_t           DLL;          // offset 0x20
        scr_t           SCR;          // offset 0x1C
        msr_t           MSR;          // offset 0x18
        lsr_t           LSR;          // offset 0x14
        mcr_t           MCR;          // offset 0x10
        lcr_t           LCR;          // offset 0x0C
        fcr_t           FCR;          // offset 0x08 (write side)
        iir_t           IIR;          // offset 0x08 (read side)
        ier_t           IER;          // offset 0x04
        thr_t           THR;          // offset 0x00 write
        rbr_t           RBR;          // offset 0x00 read
    } uart_regs_t;

    // =========================================================================
    // uart_addr_t – Byte-address enum for waveform readability
    // =========================================================================
    typedef enum logic [5:0] {
        ADDR_RBR_THR        = 6'h00,   // RBR(r)/THR(w)
        ADDR_IER            = 6'h04,   // IER(r/w)
        ADDR_IIR_FCR        = 6'h08,   // IIR(r) / FCR(w)
        ADDR_LCR            = 6'h0C,
        ADDR_MCR            = 6'h10,
        ADDR_LSR            = 6'h14,
        ADDR_MSR            = 6'h18,
        ADDR_SCR            = 6'h1C,
        ADDR_DLL            = 6'h20,
        ADDR_DLH            = 6'h24,
        ADDR_REVID1         = 6'h28,
        ADDR_REVID2         = 6'h2C,
        ADDR_PWREMU_MGMT    = 6'h30,
        ADDR_MDR            = 6'h34
    } uart_addr_t;

endpackage

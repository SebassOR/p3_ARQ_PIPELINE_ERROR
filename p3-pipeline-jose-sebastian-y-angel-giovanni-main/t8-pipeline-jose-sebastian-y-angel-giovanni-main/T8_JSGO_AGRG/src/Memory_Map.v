/******************************************************************
* Author:
* José Sebastián González Ortega
* Angel Giovanni Reynoso González
* email:
*  joses.gonzalez@iteso.mx
*	angel.reynoso@iteso.mx
* Date:
*	16/05/2026
******************************************************************/
module Memory_Map
(
    input          clk,
    input          reset,
    input  [31:0]  addr_i,
    input  [31:0]  write_data_i,
    input          mem_write_i,
    input          mem_read_i,
    input  [8:0]   gpio_port_in,
    output [31:0]  read_data_o,
    output [8:0]   gpio_port_out,
    output         rs232_tx
);

// Rango de direcciones UART (TI KeyStone): 0x10013000 - 0x10013034
localparam UART_BASE = 32'h10013000;
localparam UART_END  = 32'h10013034;

// Wires de interconexión
wire [31:0] ram_read_w;
wire [31:0] gpio_read_w;
wire [31:0] uart_read_w;
wire        gpio_sel_w;
wire        uart_sel_w;
wire        ram_we_w;

// Instancia de Memoria de Datos (RAM)
Data_Memory #(.MEMORY_DEPTH(1024)) DATA_RAM
(
    .clk         (clk),
    .Mem_Write_i (ram_we_w),
    .Mem_Read_i  (mem_read_i),
    .Address_i   (addr_i),
    .Write_Data_i(write_data_i),
    .Read_Data_o (ram_read_w)
);

// Instancia de GPIO (Switches y LEDs)
GPIO GPIO_INST
(
    .clk          (clk),
    .addr_i       (addr_i),
    .write_data_i (write_data_i),
    .mem_write_i  (mem_write_i),
    .gpio_port_in (gpio_port_in),
    .gpio_port_out(gpio_port_out),
    .gpio_sel_o   (gpio_sel_w),
    .read_data_o  (gpio_read_w)
);


uart UART_INST
(
    .clk      (clk),
    .rst_n    (reset),
    .we       (mem_write_i & uart_sel_w),
    .re       (mem_read_i  & uart_sel_w),
    .addr     (addr_i[7:2] << 2),
    .w_data   (write_data_i),
    .r_data   (uart_read_w),
    .uart_txd (rs232_tx),
    .uart_rxd (1'b1)
);


assign uart_sel_w = (addr_i[31:12] == 20'h10013) && (addr_i[7:2] <= 6'h0D);


assign ram_we_w = mem_write_i & ~gpio_sel_w & ~uart_sel_w;

assign read_data_o = gpio_sel_w ? gpio_read_w :
                     uart_sel_w ? uart_read_w :
                                  ram_read_w;

endmodule

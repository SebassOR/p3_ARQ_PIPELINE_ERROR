/******************************************************************
* Author:
* José Sebastián González Ortega
* Angel Giovanni Reynoso González
* email:
*  joses.gonzalez@iteso.mx
*	angel.reynoso@iteso.mx
* Date:
*	26/04/2026
******************************************************************/

module GPIO
(
    input        clk,
    input [31:0] addr_i,
    input [31:0] write_data_i,
    input        mem_write_i,
    input [8:0]  gpio_port_in,
    output [8:0] gpio_port_out,
    output       gpio_sel_o,      
    output [31:0] read_data_o
);
localparam GPIO_IN_ADDR  = 32'h10011020;
localparam GPIO_OUT_ADDR = 32'h10011024;

reg [8:0] gpio_reg;

// Escritura en registro de salida
always @(posedge clk) begin
    if (mem_write_i && addr_i == GPIO_OUT_ADDR)
        gpio_reg <= write_data_i[8:0];
end

// Lectura: responde solo cuando la dirección le pertenece
assign read_data_o  = (addr_i == GPIO_IN_ADDR)  ? {23'b0, gpio_port_in} :
                      (addr_i == GPIO_OUT_ADDR)  ? {23'b0, gpio_reg}     :
                                                    32'b0;

// Señal de selección: avisa al Memory_Map que esta dirección es GPIO
assign gpio_sel_o   = (addr_i == GPIO_OUT_ADDR) || (addr_i == GPIO_IN_ADDR);

assign gpio_port_out = gpio_reg;

endmodule
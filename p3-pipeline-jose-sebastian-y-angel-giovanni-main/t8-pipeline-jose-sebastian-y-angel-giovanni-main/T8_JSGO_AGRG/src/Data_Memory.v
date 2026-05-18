/******************************************************************
* Description
*	This is the data memory for the RISC-V processor
*	1.0
* Author:
*	Dr. José Luis Pizano Escalante
* email:
*	luispizano@iteso.mx
* Date:
*	16/08/2021
******************************************************************/

module Data_Memory 
#(  
    parameter DATA_WIDTH = 32,
    parameter MEMORY_DEPTH = 1024
)
(
    input clk,
    input Mem_Write_i,
    input Mem_Read_i,
    input  [DATA_WIDTH-1:0] Write_Data_i,
    input  [DATA_WIDTH-1:0] Address_i,

    output [DATA_WIDTH-1:0] Read_Data_o
);
    
    wire [9:0] real_address; 
    assign real_address = Address_i[11:2];
    
    reg [DATA_WIDTH-1:0] ram[MEMORY_DEPTH-1:0];
    wire [DATA_WIDTH-1:0] read_data_aux;

    // INICIALIZAR RAM EN 0 PARA EVITAR VALORES X
    integer i;
    initial begin
        for (i = 0; i < MEMORY_DEPTH; i = i + 1)
            ram[i] = 32'h00000000;
    end

    always @ (posedge clk) begin
        if (Mem_Write_i)
            ram[real_address] <= Write_Data_i;
    end
    
    assign read_data_aux = ram[real_address];
    assign Read_Data_o = { DATA_WIDTH { Mem_Read_i } } & read_data_aux;

endmodule
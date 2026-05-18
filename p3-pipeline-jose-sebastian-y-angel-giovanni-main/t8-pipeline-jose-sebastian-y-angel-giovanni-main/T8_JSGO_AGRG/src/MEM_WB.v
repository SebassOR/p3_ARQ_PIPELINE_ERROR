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
module MEM_WB (
    input clk,
    input reset,
	 //info
    input [31:0] read_data_in,    
    input [31:0] ALU_result_in,    
    input [31:0] pc_plus_4_in,     
    input [4:0]  Rd_addr_in,   
	
	 //Control WB
    input reg_write_in,
    input mem_to_reg_in,
    input jal_in,

    //SALIDAS
    output reg [31:0] read_data_out,
    output reg [31:0] ALU_result_out,
    output reg [31:0] pc_plus_4_out,
    output reg [4:0]  Rd_addr_out,

    //Control WB
    output reg reg_write_out,
    output reg mem_to_reg_out,
    output reg jal_out

);	 

 always @(posedge clk or negedge reset) begin
        if (reset == 1'b0) begin
            read_data_out   <= 32'b0;
            ALU_result_out  <= 32'b0;
            pc_plus_4_out   <= 32'b0;
            Rd_addr_out     <= 5'b0;

            reg_write_out   <= 1'b0;
            mem_to_reg_out  <= 1'b0;
            jal_out         <= 1'b0;
        end else begin
            read_data_out   <= read_data_in;
            ALU_result_out  <= ALU_result_in;
            pc_plus_4_out   <= pc_plus_4_in;
            Rd_addr_out     <= Rd_addr_in;

            reg_write_out   <= reg_write_in;
            mem_to_reg_out  <= mem_to_reg_in;
            jal_out         <= jal_in;
        end
    end
endmodule
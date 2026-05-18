/******************************************************************
* Author:
* José Sebastián González Ortega
* Angel Giovanni Reynoso González
* email:
*  joses.gonzalez@iteso.mx
*	angel.reynoso@iteso.mx
* Date:
*	10/05/2026
******************************************************************/

module Forwarding_Unit (

	input[4:0] Rs1_addr_EX_i,
	input[4:0] Rs2_addr_EX_i,
	
	input[4:0] Rd_addr_MEM_i,
	input      reg_write_MEM_i,
	
	input[4:0] Rd_addr_WB_i,
	input      reg_write_WB_i,
	
	output reg [1:0] Forward_A_o,
	output reg [1:0] Forward_B_o

);


always @(*) begin 
	//forward para a o rs1
	if (reg_write_MEM_i && (Rd_addr_MEM_i != 5'b0)&& (Rd_addr_MEM_i == Rs1_addr_EX_i))
		Forward_A_o = 2'b10;
	else if (reg_write_WB_i && (Rd_addr_WB_i != 5'b0)&& (Rd_addr_WB_i == Rs1_addr_EX_i))
		Forward_A_o = 2'b01;
	else 
		Forward_A_o = 2'b00;
			
	//forward para b o rs2
	
		if (reg_write_MEM_i && (Rd_addr_MEM_i != 5'b0)&& (Rd_addr_MEM_i == Rs2_addr_EX_i))
		Forward_B_o = 2'b10;
	else if (reg_write_WB_i && (Rd_addr_WB_i != 5'b0)&& (Rd_addr_WB_i == Rs2_addr_EX_i))
		Forward_B_o = 2'b01;
	else 
		Forward_B_o = 2'b00;
	
end 

endmodule
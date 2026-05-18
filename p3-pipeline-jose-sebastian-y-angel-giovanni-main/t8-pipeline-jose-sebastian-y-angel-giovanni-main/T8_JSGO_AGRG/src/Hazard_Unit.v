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
module Hazard_Unit(
		input[4:0] Rs1_addr_ID_i,
		input[4:0] Rs2_addr_ID_i,

		input[4:0] Rd_addr_EX_i,
		input      mem_read_EX_i,
		
		output reg PC_write_o,
		output reg IF_ID_write,
		output reg control_mux_o

);


always@(*) begin
	if(mem_read_EX_i && ((Rd_addr_EX_i == Rs1_addr_ID_i) || (Rd_addr_EX_i == Rs2_addr_ID_i)))
	begin
		PC_write_o    =  1'b0;
		IF_ID_write   =  1'b0;
		control_mux_o =  1'b1;
	end
	else begin 
		PC_write_o    =  1'b1;
		IF_ID_write   =  1'b1;
		control_mux_o =  1'b0;
	end
end

endmodule
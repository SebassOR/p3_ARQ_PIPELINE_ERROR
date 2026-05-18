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
module Program_Memory
#
(
	parameter MEMORY_DEPTH = 128,
	parameter DATA_WIDTH = 32
)
(
	input [(DATA_WIDTH-1):0] Address_i,
	output reg [(DATA_WIDTH-1):0] Instruction_o
);
wire [(DATA_WIDTH-1):0] real_address;

assign real_address = {2'b0, Address_i[8:2]};

	// Declare the ROM variable
	reg [DATA_WIDTH-1:0] rom[MEMORY_DEPTH-1:0];

	initial
	begin
		$readmemh("../assembly_code/Factorial.dat", rom);
	end

	always @ (*)
	begin
		Instruction_o = rom[real_address];
	end

endmodule

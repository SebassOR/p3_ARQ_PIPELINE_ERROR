
/******************************************************************
* Description
*	This module performs a sign extension operation that is need with
*	in instruction like andi and constructs the immediate constant.
* Version:
*	1.0
* Author:
*	Dr. José Luis Pizano Escalante
* email:
*	luispizano@iteso.mx
* Date:
*	16/08/2021
******************************************************************/
module Immediate_Unit
(   
	input [6:0] op_i,
	input [31:0]  Instruction_bus_i,
	
   output reg [31:0] Immediate_o
);



always @(op_i or Instruction_bus_i) begin
    if(op_i == 7'h13)           // I-Type ADDI
        Immediate_o = {{20{Instruction_bus_i[31]}}, Instruction_bus_i[31:20]};
    else if(op_i == 7'h67)      // JALR I-Type
        Immediate_o = {{20{Instruction_bus_i[31]}}, Instruction_bus_i[31:20]};
    else if(op_i == 7'h63)      // B-Type
        Immediate_o = {{20{Instruction_bus_i[31]}},
                        Instruction_bus_i[7],
                        Instruction_bus_i[30:25],
                        Instruction_bus_i[11:8],
                        1'b0};
    else if(op_i == 7'h17 || op_i == 7'h37) // U-Type
        Immediate_o = {Instruction_bus_i[31:12], 12'b0};
    else if(op_i == 7'h23) // S-Type
        Immediate_o = {{20{Instruction_bus_i[31]}},
                    Instruction_bus_i[31:25],  //imm[11:5]
                    Instruction_bus_i[11:7]};  //imm[4:0]
    else if(op_i == 7'h6F)      // J-Type JAL ← nuevo
        Immediate_o = {{12{Instruction_bus_i[31]}},
                        Instruction_bus_i[19:12],
                        Instruction_bus_i[20],
                        Instruction_bus_i[30:21],
                        1'b0};
    else if(op_i == 7'h03)      // I-Type LW
        Immediate_o = {{20{Instruction_bus_i[31]}}, Instruction_bus_i[31:20]};
    else
        Immediate_o = 32'b0;
end


endmodule 

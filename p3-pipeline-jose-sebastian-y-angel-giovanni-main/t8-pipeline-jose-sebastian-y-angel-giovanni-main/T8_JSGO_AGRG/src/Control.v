/******************************************************************
* Description
*	This is control unit for the RISC-V Microprocessor. The control unit is 
*	in charge of generation of the control signals. Its only input 
*	corresponds to opcode from the instruction bus.
*	1.0
* Author:
*	Dr. José Luis Pizano Escalante
* email:
*	luispizano@iteso.mx
* Date:
*	16/08/2021
******************************************************************/
module Control
(
	input [6:0]OP_i,
	
	
	output Branch_o,
	output JAL_o,
	output JALR_o,
	output Mem_Read_o,
	output Mem_to_Reg_o,
	output Mem_Write_o,
	output ALU_Src_o,
	output Reg_Write_o,
	output AUIPC_o,
	output [2:0]ALU_Op_o
);

//declaracion de opcode para cada tipo
localparam R_Type			=  7'h33; // 0110011
localparam I_Type_LOGIC	    =  7'h13; // 0010011
localparam I_Type_MEM       =  7'h03; // 0000011  PARA MEM TO REG 
localparam B_Type   		=  7'h63; // 1100011  PARA BRANCH
localparam U_Type_aui 	    =  7'h17; // 0001011  PARA AUIPC
localparam U_Type_lui 	= 	7'h37; // 0110111 PARA LUI
localparam S_Type			=  7'h23; // 0100011  PARA STORE
localparam J_Type			=  7'h6F; // 1101111  PARA JAL jtype
localparam I_Type_JALR      =  7'h67; // 1100111  PARA JALR

reg [11:0] control_values;

always @(OP_i) begin
    case(OP_i) //                    11_10_9_8_7_6_5_4_3_2_1_0
        R_Type:      control_values   = 12'b000001000010;

        I_Type_LOGIC:control_values   = 12'b000001001000;
        I_Type_MEM:  control_values   = 12'b000011101100;

        B_Type:      control_values   = 12'b000100000101;

        U_Type_aui:  control_values   = 12'b001001001110;
		U_Type_lui: control_values    = 12'b000001001011; 

        S_Type:      control_values   = 12'b000000011111;

        J_Type:     control_values    = 12'b010001000001; 
		
        I_Type_JALR: control_values   = 12'b100001001000;
        default:     control_values   = 12'b000000000000;
    endcase
end

//expansion de nuevas señales de control para jalr, jal y auipc
assign JALR_o = control_values[11];

assign JAL_o = control_values[10];

assign AUIPC_o = control_values[9]; 

//organizacion original
assign Branch_o = control_values[8]; 

assign Mem_to_Reg_o = control_values[7];

assign Reg_Write_o = control_values[6];

assign Mem_Read_o = control_values[5];

assign Mem_Write_o = control_values[4];

assign ALU_Src_o = control_values[3];

assign ALU_Op_o = control_values[2:0];	

endmodule

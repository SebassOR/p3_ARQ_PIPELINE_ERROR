
/******************************************************************
* Description
*	This is the control unit for the ALU. It receves a signal called 
*	ALUOp from the control unit and signals called funct7 and funct3  from
*	the instruction bus.
* Version:
*	1.0
* Author:
*	Dr. José Luis Pizano Escalante
* email:
*	luispizano@iteso.mx
* Date:
*	16/08/2021
******************************************************************/

module ALU_Control
(
	input [1:0] funct7_i, 
	input [2:0] ALU_Op_i,
	input [2:0] funct3_i,
	output [3:0] ALU_Operation_o

);

reg [3:0] alu_control_values;
wire [6:0] selector;

//los separamos para tener mejor visibilidad
localparam R_Type_ADD  = 8'b00_010_000; //GIO 1
localparam R_Type_SUB  = 8'b10_010_000; //GIO 1
localparam R_Type_XOR  = 8'b00_010_100; //GIO 1
localparam R_Type_OR   = 8'b00_010_110; //GIO 1
localparam R_Type_AND  = 8'b00_010_111; //GIO 1
localparam R_Type_MUL  = 8'b01_010_000; //GIO P3

localparam I_Type_ADDI = 8'bxx_000_000; //Sebas 1
localparam I_Type_XORI = 8'bxx_000_100; //GIO 1
localparam I_Type_ORI  = 8'bxx_000_110; // FUNC3 = 0x6 GIO 1
localparam I_Type_ANDI = 8'bxx_000_111; //GIO 1
localparam I_Type_LW   = 8'bxx_100_010; //Sebas
localparam I_Type_SLLI = 8'b00_000_001; //Sebas      PARA CUANDO FNC 3 SEA 001 1


localparam U_Type_LUI  = 8'bxx_011_xxx; //GIO 1
localparam U_Type_AUIPC= 8'bxx_110_xxx; //Sebas  El tipo U no tiene funct7 ni funct 3 así que las ignoramos 1  

localparam S_Type_SW   = 8'bxx_111_010; //Sebas   El SW no tiene funct7 pero si funct 3 

localparam B_Type_BNE  = 8'bxx_101_001; //Sebas
localparam R_Type_SLL  = 8'b00_010_001; //Sebas 1
localparam R_Type_SRL  = 8'b00_010_101; //Sebas
localparam B_Type_BEQ  = 8'bxx_101_000; //Sebas
localparam J_Type_JAL  = 8'bxx_001_xxx; //Sebas  JAL NO TIENE NI FNC3 NI FNC7 POR ESO LAS X  

localparam B_Type_BGE  = 8'bxx_101_101; //Sebas


assign selector = {funct7_i, ALU_Op_i, funct3_i};


always@(selector) begin
    casex(selector)
        U_Type_AUIPC: alu_control_values = 4'b0000; // suma normal
		  U_Type_LUI:   alu_control_values = 4'b1001; //LUI
        J_Type_JAL:   alu_control_values = 4'b0000; //JAL

        R_Type_ADD:   alu_control_values = 4'b0000;
        R_Type_SRL:   alu_control_values = 4'b0100; //SRL
        R_Type_SLL:   alu_control_values = 4'b1010; //SLL
        R_Type_SUB:   alu_control_values = 4'b0001; //SUB
        R_Type_OR:	  alu_control_values = 4'b0011; //or
        R_Type_XOR:	  alu_control_values = 4'b1000; //XOR
        R_Type_AND:	  alu_control_values = 4'b0010;
		  R_Type_MUL:   alu_control_values  = 4'b1111;

        I_Type_ADDI:  alu_control_values = 4'b0000; 
        I_Type_SLLI:  alu_control_values = 4'b0101; //SLLI
        I_Type_LW:    alu_control_values = 4'b0000; //lw
        //I_Type_JALR:  alu_control_values = 4'b0000; //jalr
        I_Type_XORI:  alu_control_values = 4'b1000; //XORI
        I_Type_ORI:   alu_control_values = 4'b0011; //ORI
        I_Type_ANDI:  alu_control_values = 4'b0010; //ANDI

        S_Type_SW:    alu_control_values = 4'b0000;

	//B Type	  
        B_Type_BNE:   alu_control_values = 4'b0110;
        B_Type_BEQ:   alu_control_values = 4'b1011; 
        B_Type_BGE:   alu_control_values = 4'b1100;
        
        

        default:      alu_control_values = 4'b0000;
    endcase
end

assign ALU_Operation_o = alu_control_values;

endmodule
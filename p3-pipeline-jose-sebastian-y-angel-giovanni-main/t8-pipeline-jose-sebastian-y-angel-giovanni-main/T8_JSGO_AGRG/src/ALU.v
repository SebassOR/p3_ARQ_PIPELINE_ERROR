/******************************************************************
* Description
*	This is an 32-bit arithetic logic unit that can execute the next set of operations:
*		add

* This ALU is written by using behavioral description.
* Version:
*	1.0
* Author:
*	Dr. José Luis Pizano Escalante
* email:
*	luispizano@iteso.mx
* Date:
*	16/08/2021
******************************************************************/

module ALU (
    input  [3:0]        ALU_Operation_i,
    input  signed [31:0] A_i,
    input  signed [31:0] B_i,
    output reg           Zero_o,
    output reg  [31:0]  ALU_Result_o
);

//los acomodamos para tener orden en la lectura, pero no es necesario que estén en este orden específico
localparam ADD  = 4'b0000;
//localparam SW   = 4'b0000;  utiliza el mismo código que el ADD para calcular la dirección de memoria, pero no es una operación aritmética en sí misma, por lo que no se define como una operación separada en la ALU.
//localparam LW   = 4'b0000; USA ADD
//localparam AUIPC= 4'b0000; lo manejamos como suma y en el immediato ya se hace el 12 bits
//localparam JAL  = 4'b0000; NO USA LA ALU
//localparam JALR = 4'b0000; USA EL ADD RS1 + IMM

localparam SUB  = 4'b0001;
localparam AND  = 4'b0010;
localparam OR   = 4'b0011;
localparam SRL  = 4'b0100;
localparam SLLI = 4'b0101;
localparam BNE  = 4'b0110;
localparam SW   = 4'b0111;
localparam XOR  = 4'b1000;
localparam LUI  = 4'b1001;
localparam SLL  = 4'b1010;
localparam BEQ  = 4'b1011;
localparam BGE  = 4'b1100;
localparam MUL  = 4'b1111;

always @(*) begin
    
    ALU_Result_o = 32'd0;
    Zero_o       = 1'b0;

//LOS SEPARAMOS POR ETIQUETAS PARA TENER MEJOR VISIBILIDAD
    case (ALU_Operation_i)
    //TIPO R
        ADD:   ALU_Result_o = A_i + B_i;
        SUB:   ALU_Result_o = A_i - B_i;
        OR:    ALU_Result_o = A_i | B_i;
        XOR:   ALU_Result_o = A_i ^ B_i;
        AND:   ALU_Result_o = A_i & B_i;

        SRL:   ALU_Result_o = A_i >> B_i[4:0];
        SLL:   ALU_Result_o = A_i << B_i[4:0];
        
		  MUL:   ALU_Result_o = A_i * B_i;

    //TIPO B
        BNE: begin
            ALU_Result_o = A_i - B_i;
            Zero_o = (A_i == B_i) ? 1'b1 : 1'b0; // ← igual que SUB normal
        end

        BEQ: begin
            ALU_Result_o = A_i - B_i;   
            Zero_o       = (A_i == B_i) ? 1'b1 : 1'b0; //branch if equal
        end
        
        BGE: begin 
            ALU_Result_o = A_i - B_i;
            Zero_o       = (A_i >= B_i) ? 1'b1 : 1'b0; //branch if greater or equal
        end

    //TIPO I
        SLLI:  ALU_Result_o = A_i << B_i[4:0];
    //TIPO U
        LUI: ALU_Result_o = B_i;

        default: ALU_Result_o = 32'd0;
    endcase
end

endmodule
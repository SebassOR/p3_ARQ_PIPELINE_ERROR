
/******************************************************************
* Description
*	This is the implementation of a UART TX with the following parameters
*  Baud Rate 9600
*  Non-Parity
*  1 stop bit

* Version:
*	1.0
* Author:
*	Dr. José Luis Pizano Escalante
* email:
*	luispizano@iteso.mx
* Date:
*	06/04/2025
******************************************************************/


module uart_transmitter(
	input logic clock,
	input logic reset,
	input logic start,
	input logic [7:0]data,
	output logic ready,
	output logic rs232_tx
);

localparam BAUD_RATE_CONST = 520;

enum {IDLE, LOAD_DATA, LOAD_SHIFT_REGISTER, START_BIT, SEND_DATA, STOP_BIT, TX_FINISH } state;


logic sm_cnt_enable_r;
logic sm_shift_r;
logic[1:0]sm_mux_r;

logic sm_load_data_r;
logic sm_load_shift_register_r;

logic load, shift;

logic [7 : 0] shift_register_reg;

wire [7:0] Parallel_Input;


logic [2:0] counter_reg;
logic MaxValue_Bit;
logic [7:0] data_input;
logic sm_counter_flag_i;
logic Mux_Output_o;


logic clk_uart;
logic tick;



reg [9 : 0] counter_clk;

/*********************************************************************************************/

	always_ff @(posedge clock or negedge reset) begin
		if (reset == 1'b0)
			counter_clk <= 0;
		else begin
			if(counter_clk == BAUD_RATE_CONST)
				counter_clk <= 1'b0;
			else
				counter_clk <= counter_clk + 1'b1;
						

		end
	end


always_comb
	if(counter_clk == BAUD_RATE_CONST)
		tick = 1;
	else
		tick = 0;


		
always_ff@(posedge clock or negedge reset)
begin

	if(reset == 1'b0) begin 
			clk_uart <= 0;
	end
	else begin
		if(tick)
			clk_uart <= !clk_uart;
		end
end//end always		






assign sm_counter_flag_i = MaxValue_Bit;


always_ff @(negedge reset or posedge clk_uart) begin
	if(reset==0)
		data_input <= 0;
	else	
		if(sm_load_data_r == 1)
			data_input <= data;
end



always_ff @(posedge clk_uart, negedge reset) begin

	if(reset == 1'b0)
			state <= IDLE;
	else 
		case(state)
			
			IDLE:
				if(start == 1'b1)
					state <= LOAD_DATA;
				else
					state <= IDLE;		
			LOAD_DATA:
					state <= LOAD_SHIFT_REGISTER;
			LOAD_SHIFT_REGISTER:
					state <= START_BIT;	
			START_BIT:
					state <= SEND_DATA;	
			SEND_DATA:
				if(sm_counter_flag_i == 0)
					state <= SEND_DATA;
				else
					state <= STOP_BIT;
			STOP_BIT:
					state <= TX_FINISH;	
			TX_FINISH:
				if(start == 1'b1)
					state <= TX_FINISH;
				else
					state <= IDLE;		
						
			default:
					state <= IDLE;

			endcase
end//end always
/*------------------------------------------------------------------------------------------*/
/*Asignación de salidas,proceso combintorio*/
always_comb begin
	 case(state)
		IDLE: 
			begin
			sm_cnt_enable_r = 0;
			sm_shift_r = 0;
			sm_mux_r = 0;
			ready = 1;
			sm_load_data_r = 0;
			sm_load_shift_register_r = 0;
		
			end
		LOAD_DATA: 
			begin
			sm_cnt_enable_r = 0;
			sm_shift_r = 0;
			sm_mux_r = 0;
			ready = 0;
			sm_load_data_r = 1;
			sm_load_shift_register_r = 0;

			end	
		LOAD_SHIFT_REGISTER: 
			begin
			sm_cnt_enable_r = 0;
			sm_shift_r = 0;
			sm_mux_r = 0;
		   ready = 0;
			sm_load_data_r = 0;
			sm_load_shift_register_r = 1;

			end			
		START_BIT: 
			begin
			sm_cnt_enable_r = 0;
			sm_shift_r = 0;
			sm_mux_r = 1;
			ready = 0;
			sm_load_data_r = 0;
			sm_load_shift_register_r = 0;

			end
		SEND_DATA: 
			begin
			sm_cnt_enable_r = 1;
			sm_shift_r = 1;
			sm_mux_r = 2;
			ready = 0;
			sm_load_data_r = 0;
			sm_load_shift_register_r = 0;
	
			end
		STOP_BIT: 
			begin
			sm_cnt_enable_r = 0;
			sm_shift_r = 0;
			sm_mux_r = 0;
			ready = 0;
			sm_load_data_r = 0;	
			sm_load_shift_register_r = 0;		

			end
		TX_FINISH: 
			begin
			sm_cnt_enable_r = 0;
			sm_shift_r = 0;
			sm_mux_r = 0;
			ready = 0;
			sm_load_data_r = 0;
			sm_load_shift_register_r = 0;

			end			
	default: 		
			begin
			sm_cnt_enable_r = 0;
			sm_shift_r = 0;
			sm_mux_r = 0;

			sm_load_data_r = 0;
			sm_load_shift_register_r = 0;

			end

	endcase
end

// Asingnación de salidas





	always@(posedge clk_uart or negedge reset) begin
		if (reset == 1'b0)
			counter_reg <= 0;
		else begin
				if(sm_cnt_enable_r == 1'b1) begin
					if(counter_reg == 7)
						counter_reg <= 1'b0;
					else
						counter_reg <= counter_reg + 1'b1;
						
				end
		end
	end


always@(counter_reg)
	if(counter_reg == 7)
		MaxValue_Bit = 1;
	else
		MaxValue_Bit = 0;





assign load= sm_load_shift_register_r;
assign shift = sm_shift_r;

always@(posedge clk_uart, negedge reset) begin
	
	if(reset == 1'b0)
		shift_register_reg <= 0;
	else
		case ({load, shift})
			2'b01:
				shift_register_reg <= {1'b0, shift_register_reg[7 : 1]};
			2'b10:
				shift_register_reg <= data_input;
			default:
				shift_register_reg <= shift_register_reg;
		endcase
end



always_comb begin
		case(sm_mux_r)
		0:	Mux_Output_o = 1'b1;
		1: Mux_Output_o = 1'b0;
		2: Mux_Output_o = shift_register_reg[0];
		default: Mux_Output_o = 1'b0; 
		endcase
	end

	
assign rs232_tx = Mux_Output_o;	

endmodule
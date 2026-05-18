/*
 * company: ITESO
 * engineer: Alvaro Gutierrez Arce
 * module description:
 *      generic serial-in parallel-out (SIPO) shift register.
 *      shifts right when enable is asserted, with serial_in
 *      entering at the MSB. synchronous clear forces the register
 *      to RESET_VALUE. priority: rst_n > clr > enable.
 * date: 11-02-2025
 */

module sipo_register #(
    parameter WIDTH       = 8,
    parameter RESET_VALUE = {WIDTH{1'b0}}
) (
    input  logic             clk,
    input  logic             rst_n,        // asynchronous reset, active-low
    input  logic             clr,          // synchronous clear: forces register to RESET_VALUE
    input  logic             enable,       // shift right: register <= {serial_in, register[WIDTH-1:1]}
    input  logic             serial_in,
    output logic [WIDTH-1:0] parallel_out
);

    logic [WIDTH-1:0] shift_reg;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_reg <= RESET_VALUE;
        end else if (clr) begin
            shift_reg <= RESET_VALUE;
        end else if (enable) begin
            shift_reg <= {serial_in, shift_reg[WIDTH-1:1]};
        end
    end

    assign parallel_out = shift_reg;

endmodule

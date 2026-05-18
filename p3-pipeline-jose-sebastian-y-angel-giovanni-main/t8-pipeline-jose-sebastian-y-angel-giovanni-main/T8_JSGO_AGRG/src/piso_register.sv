/*
 * company: ITESO
 * engineer: Alvaro Gutierrez Arce
 * module description:
 *      generic parallel-in serial-out (PISO) shift register.
 *      loads parallel data when load is asserted, shifts right
 *      when enable is asserted. the pad bit (SHIFT_PAD) fills
 *      the vacated MSB on each shift. serial output is the LSB.
 * date: 11-02-2025
 */

module piso_register #(
    parameter WIDTH       = 8,                  // register width
    parameter RESET_VALUE = {WIDTH{1'b0}},      // value on reset / clear
    parameter SHIFT_PAD   = 1'b0                // bit shifted into MSB on each shift
) (
    input  logic             clk,
    input  logic             rst_n,             // asynchronous reset, active-low
    input  logic             clr,               // synchronous clear: forces register to RESET_VALUE
    input  logic             load,              // parallel load: register <= data
    input  logic             enable,            // shift right: register <= {SHIFT_PAD, register[WIDTH-1:1]}
    input  logic [WIDTH-1:0] data,              // parallel data in
    output logic             serial_out         // LSB of the shift register
);

    logic [WIDTH-1:0] shift_reg;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_reg <= RESET_VALUE;
        end else if (clr) begin
            shift_reg <= RESET_VALUE;
        end else if (load) begin
            shift_reg <= data;
        end else if (enable) begin
            shift_reg <= {SHIFT_PAD, shift_reg[WIDTH-1:1]};
        end
    end

    assign serial_out = shift_reg[0];

endmodule

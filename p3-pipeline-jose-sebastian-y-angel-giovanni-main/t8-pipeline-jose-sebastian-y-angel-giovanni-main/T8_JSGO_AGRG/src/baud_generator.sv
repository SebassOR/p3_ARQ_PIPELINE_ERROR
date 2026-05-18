/*
 * company: ITESO
 * engineer: Alvaro Gutierrez Arce
 * module description:
 *      configurable baud rate generator with programmable
 *      divisor. outputs a single-cycle bclk pulse every
 *      divisorValue clock cycles when enabled.
 * date: 03-15-2026
 */

module baud_generator #(
    parameter WIDTH = 16
) (
    input  logic               clk,
    input  logic               rst_n,        // asynchronous active-low reset
    input  logic               clr,          // synchronous clear: resets counter to 0
    input  logic               en,           // enable: counting only when asserted
    input  logic [WIDTH-1:0]   divisorValue, // bclk period in clk cycles
    output logic               bclk          // single-cycle pulse every divisorValue clocks
);

    logic [WIDTH-1:0] cnt;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt <= '0;
        end else if (clr) begin
            cnt <= '0;
        end else if (en) begin
            if (cnt == (divisorValue - 1)) begin
                cnt <= '0;
            end else begin
                cnt <= cnt + 1'b1;
            end
        end
    end

    assign bclk = en & (cnt == '0);

endmodule

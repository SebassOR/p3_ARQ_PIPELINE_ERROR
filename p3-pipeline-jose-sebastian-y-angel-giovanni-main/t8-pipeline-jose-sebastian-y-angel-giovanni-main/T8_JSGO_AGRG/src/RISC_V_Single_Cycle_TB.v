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
module RISC_V_Single_Cycle_TB;

reg         clk_tb = 0;
reg  [9:0] gpio_port_in_tb;
wire [10:0] gpio_port_out_tb;
wire        rs232_tx_tb;

RISC_V_Single_Cycle DUV (
    .clk          (clk_tb),
    .gpio_port_in (gpio_port_in_tb),
    .gpio_port_out(gpio_port_out_tb),
    .rs232_tx     (rs232_tx_tb)
);

initial forever #2 clk_tb = !clk_tb;

initial begin
    $dumpfile("tb.vcd");
    $dumpvars(0, RISC_V_Single_Cycle_TB);
end

initial begin
    gpio_port_in_tb = 10'b00_0000_0000;
    #100;

    gpio_port_in_tb = 10'b10_0000_0000;
    #100;

    #500;

    gpio_port_in_tb = 10'b10_0000_0101;
    #200;

    gpio_port_in_tb = 10'b10_1000_0101;
    #3000000;

    gpio_port_in_tb = 10'b10_0000_0101;
    #500;

    $finish;
end

endmodule

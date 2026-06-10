`timescale 1ns/1ps

module cpu_axi_tb;

reg clk;
reg reset;

cpu_axi_top dut(
    .clk(clk),
    .reset(reset)
);

initial begin
    clk = 0;
    forever #5 clk = ~clk;
end

initial begin
    reset = 1;
    #20;
    reset = 0;
end

always @(posedge clk)
begin
    $display(
    "TX_START=%b BUSY=%b TXDATA=%h",
    dut.uart.tx_start,
    dut.uart.busy,
    dut.uart.tx_data_reg
    );
end
initial begin
    #200000;
    $finish;
end

endmodule
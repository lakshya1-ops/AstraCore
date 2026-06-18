module axi_decoder(
    input[31:0] addr,

    output dmem_sel,
    output uart_sel,
    output timer_sel,
    output gpio_sel,
    output accel_sel
);

// DMEM : 0x00000000 - 0x00000FFF
assign dmem_sel = (addr >= 32'h00000000)&&(addr <= 32'h00000FFF);

// UART : 0x10000000 - 0x100000FF
assign uart_sel = (addr >= 32'h10000000)&&(addr <= 32'h100000FF);

// TIMER : 0x10000100 - 0x100001FF
assign timer_sel = (addr >= 32'h10000100)&&(addr <= 32'h100001FF);

// GPIO : 0x10000200 - 0x100002FF
assign gpio_sel = (addr >= 32'h10000200)&&(addr <= 32'h100002FF);

// ACCELERATOR : 0x10000300 - 0x100003FF
assign accel_sel = (addr >= 32'h10000300) && (addr <= 32'h100003FF);

endmodule
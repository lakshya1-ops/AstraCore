`ifndef AXI_DEFS_VH //If AXI_DEFS_VH has NOT been defined already
`define AXI_DEFS_VH' //AXI_DEFS_VH = defined

// AXI-Lite Parameters

`define AXI_ADDR_WIDTH 32
`define AXI_DATA_WIDTH 32

//AXI response

`define RESP_OKAY   2'b00
`define RESP_EXOKAY 2'b01
`define RESP_SLVERR 2'b10
`define RESP_DECERR 2'b11

`endif
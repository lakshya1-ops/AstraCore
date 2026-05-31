//connect axi_master and axi_slave
module astracore_soc_top;
reg clk;
reg reset;
reg mem_mem_read;
reg mem_mem_write;
reg [31:0] mem_addr;
reg [31:0] mem_wdata;
wire [31:0] mem_rdata;
wire axi_busy;
wire [31:0] AWADDR;
wire AWVALID;
wire AWREADY;
wire [31:0] WDATA;
wire WVALID;
wire WREADY;
wire [1:0] BRESP;
wire BVALID;
wire BREADY;
wire [31:0] ARADDR;
wire ARVALID;
wire ARREADY;
wire [31:0] RDATA;
wire [1:0] RRESP;
wire RVALID;
wire RREADY;

axi_lite_master_cpu master(
    .clk(clk),
    .reset(reset),

    .mem_mem_read(mem_mem_read),
    .mem_mem_write(mem_mem_write),
    .mem_addr(mem_addr),
    .mem_wdata(mem_wdata),

    .mem_rdata(mem_rdata),
    .axi_busy(axi_busy),

    .AWADDR(AWADDR),
    .AWVALID(AWVALID),
    .AWREADY(AWREADY),

    .WDATA(WDATA),
    .WVALID(WVALID),
    .WREADY(WREADY),

    .BRESP(BRESP),
    .BVALID(BVALID),
    .BREADY(BREADY),

    .ARADDR(ARADDR),
    .ARVALID(ARVALID),
    .ARREADY(ARREADY),

    .RDATA(RDATA),
    .RRESP(RRESP),
    .RVALID(RVALID),
    .RREADY(RREADY)
);
axi_dmem_slave slave(
    .clk(clk),
    .reset(reset),

    .AWADDR(AWADDR),
    .AWVALID(AWVALID),
    .AWREADY(AWREADY),

    .WDATA(WDATA),
    .WVALID(WVALID),
    .WREADY(WREADY),

    .BRESP(BRESP),
    .BVALID(BVALID),
    .BREADY(BREADY),

    .ARADDR(ARADDR),
    .ARVALID(ARVALID),
    .ARREADY(ARREADY),

    .RDATA(RDATA),
    .RRESP(RRESP),
    .RVALID(RVALID),
    .RREADY(RREADY)
);
endmodule
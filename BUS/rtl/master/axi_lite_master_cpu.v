`include "axi_defs.vh"

module axi_lite_master_cpu(
    input clk,
    input reset,

    // CPU memory interface
    input mem_mem_read,
    input mem_mem_write,
    input [`AXI_ADDR_WIDTH-1:0] mem_addr,
    input [`AXI_DATA_WIDTH-1:0] mem_wdata,

    output reg [`AXI_DATA_WIDTH-1:0] mem_rdata,
    output reg axi_busy,

    output reg mem_read_done,
    output reg mem_write_done,

    // Write address channel
    output reg [`AXI_ADDR_WIDTH-1:0] AWADDR,
    output reg AWVALID,
    input AWREADY,

    // Write data channel
    output reg [`AXI_DATA_WIDTH-1:0] WDATA,
    output reg WVALID,
    input WREADY,

    // Write response channel
    input [1:0] BRESP,
    input BVALID,
    output reg BREADY,

    // Read address channel
    output reg [`AXI_ADDR_WIDTH-1:0] ARADDR,
    output reg ARVALID,
    input ARREADY,

    // Read data channel
    input [`AXI_DATA_WIDTH-1:0] RDATA,
    input [1:0] RRESP,
    input RVALID,
    output reg RREADY
);

localparam IDLE            = 3'd0;
localparam READ_ADDR       = 3'd1;
localparam READ_WAIT       = 3'd2;
localparam WRITE_ADDR_DATA = 3'd3;
localparam WRITE_WAIT      = 3'd4;
localparam WAIT_REQ_DROP   = 3'd5;

reg [2:0] state;
reg [2:0] next_state;

reg [`AXI_ADDR_WIDTH-1:0] req_addr;
reg [`AXI_DATA_WIDTH-1:0] req_wdata;

always @(posedge clk or posedge reset)
begin
    if(reset)
    begin
        state <= IDLE;
        req_addr <= {`AXI_ADDR_WIDTH{1'b0}};
        req_wdata <= {`AXI_DATA_WIDTH{1'b0}};
        mem_rdata <= {`AXI_DATA_WIDTH{1'b0}};
        mem_read_done <= 1'b0;
        mem_write_done <= 1'b0;
    end
    else
    begin
        state <= next_state;

        mem_read_done <= 1'b0;
        mem_write_done <= 1'b0;

        if(state == IDLE && mem_mem_read)
        begin
            req_addr <= mem_addr;
        end

        if(state == IDLE && mem_mem_write)
        begin
            req_addr <= mem_addr;
            req_wdata <= mem_wdata;
        end

        if(state == READ_WAIT && RVALID)
        begin
            mem_rdata <= RDATA;
            mem_read_done <= 1'b1;
        end

        if(state == WRITE_WAIT && BVALID)
        begin
            mem_write_done <= 1'b1;
        end
    end
end

always @(*)
begin
    next_state = state;

    case(state)
        IDLE:
        begin
            if(mem_mem_read)
                next_state = READ_ADDR;
            else if(mem_mem_write)
                next_state = WRITE_ADDR_DATA;
        end

        READ_ADDR:
        begin
            if(ARREADY)
                next_state = READ_WAIT;
        end

        READ_WAIT:
        begin
            if(RVALID)
                next_state = WAIT_REQ_DROP;
        end

        WRITE_ADDR_DATA:
        begin
            if(AWREADY && WREADY)
                next_state = WRITE_WAIT;
        end

        WRITE_WAIT:
        begin
            if(BVALID)
                next_state = WAIT_REQ_DROP;
        end

        WAIT_REQ_DROP:
        begin
            if(!mem_mem_read && !mem_mem_write)
                next_state = IDLE;
        end

        default:
        begin
            next_state = IDLE;
        end
    endcase
end

always @(*)
begin
    axi_busy = 1'b0;

    ARVALID = 1'b0;
    AWVALID = 1'b0;
    WVALID  = 1'b0;
    RREADY  = 1'b0;
    BREADY  = 1'b0;

    ARADDR = req_addr;
    AWADDR = req_addr;
    WDATA  = req_wdata;

    case(state)
        IDLE:
        begin
            axi_busy = 1'b0;
        end

        READ_ADDR:
        begin
            axi_busy = 1'b1;
            ARVALID = 1'b1;
        end

        READ_WAIT:
        begin
            axi_busy = 1'b1;
            RREADY = 1'b1;
        end

        WRITE_ADDR_DATA:
        begin
            axi_busy = 1'b1;
            AWVALID = 1'b1;
            WVALID = 1'b1;
        end

        WRITE_WAIT:
        begin
            axi_busy = 1'b1;
            BREADY = 1'b1;
        end

        WAIT_REQ_DROP:
        begin
            axi_busy = 1'b0;
        end

        default:
        begin
            axi_busy = 1'b0;
        end
    endcase
end

endmodule
`include "axi_defs.vh"
module axi_lite_master_cpu(
    input clk,
    input reset,

    //cpu mem interface
    input mem_mem_read,//cpu wants to load
    input mem_mem_write,//cpu wants to store
    input [`AXI_ADDR_WIDTH-1:0] mem_addr,//it will be connected to mem_alu_result and hence addr will arrive here
    input [`AXI_DATA_WIDTH-1:0] mem_wdata,// it will be connected to mem_rs2_data and hence it will be having the store data

    output reg [`AXI_DATA_WIDTH-1:0] mem_rdata,//stores data that is to be read from slave
    output reg axi_busy,//shows busy state of axi

    //all the above things are transmitted throught diffrent channels mentioned below:-

    //write address channel
    output reg [`AXI_ADDR_WIDTH-1:0] AWADDR,//sends address on where to write data for eg during SW
    output reg AWVALID,
    input AWREADY,
    // WRITE DATA CHANNEL
    output reg [`AXI_DATA_WIDTH-1:0] WDATA,// what is the data that is needed to be written 
    output reg WVALID,
    input WREADY,

    // WRITE RESPONSE CHANNEL
    input [1:0] BRESP,//tells that the writing is done
    input BVALID,
    output reg BREADY,

    // READ ADDRESS CHANNEL
    output reg [`AXI_ADDR_WIDTH-1:0] ARADDR,
    output reg ARVALID,
    input ARREADY,//transaction happens only when ARVALID && ARREADY

    // READ DATA CHANNEL
    input [`AXI_DATA_WIDTH-1:0] RDATA,
    input [1:0] RRESP,
    input RVALID,
    output reg RREADY
);
// FSM STATES
//tells axi "what am i currently waiting for"
//eg:- state = READ_ADDR; means I am trying to send ARADDR.Waiting for ARREADY.
localparam IDLE            = 3'd0;//waits for new read/write req
localparam READ_ADDR       = 3'd1;//waits for ARREADY
localparam READ_WAIT       = 3'd2;//waits for RVALID
localparam WRITE_ADDR_DATA = 3'd3;//waits for AWREADY and WREADY
localparam WRITE_WAIT      = 3'd4;//waits for BVALID

reg [2:0] state;
reg [2:0] next_state;

always @(posedge clk or posedge reset)
begin
    if(reset)
    begin
        state <= IDLE;
        mem_rdata <= {`AXI_DATA_WIDTH{1'b0}};
    end
    else
    begin
        state <= next_state;
        if(state == READ_WAIT && RVALID)
            mem_rdata <= RDATA;
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
                    next_state = IDLE;
            end
        WRITE_ADDR_DATA:
            begin
                if(AWREADY && WREADY)
                    next_state = WRITE_WAIT;
            end
        WRITE_WAIT:
            begin
                if(BVALID)
                    next_state = IDLE;
            end
        default:
            next_state = IDLE;
    endcase
end

always @(*)
begin
    // defaults
    axi_busy = 1'b0;
    ARVALID = 1'b0;
    AWVALID = 1'b0;
    WVALID  = 1'b0;
    RREADY  = 1'b0;
    BREADY  = 1'b0;
    ARADDR  = mem_addr;
    AWADDR  = mem_addr;
    WDATA   = mem_wdata;
    case(state)
        IDLE:
        begin
            axi_busy = 1'b0;
        end
        READ_ADDR:
        begin
            axi_busy = 1'b1;
            ARVALID  = 1'b1;
        end
        READ_WAIT:
        begin
            axi_busy = 1'b1;
            RREADY   = 1'b1;
        end
        WRITE_ADDR_DATA:
        begin
            axi_busy = 1'b1;
            AWVALID  = 1'b1;
            WVALID   = 1'b1;
        end
        WRITE_WAIT:
        begin
            axi_busy = 1'b1;
            BREADY   = 1'b1;
        end
    endcase
end

endmodule
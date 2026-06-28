`include "axi_defs.vh"

module axi_dmem_slave(
    input clk,
    input reset,

    //all output of master is input for slave and vice versa

    // WRITE ADDRESS CHANNEL
    input [`AXI_ADDR_WIDTH-1:0] AWADDR,
    input AWVALID,
    output AWREADY,
    // WRITE DATA CHANNEL
    input [`AXI_DATA_WIDTH-1:0] WDATA,
    input WVALID,
    output WREADY,
    // WRITE RESPONSE CHANNEL
    output reg [1:0] BRESP,
    output reg BVALID,
    input BREADY,
    // READ ADDRESS CHANNEL
    input [`AXI_ADDR_WIDTH-1:0] ARADDR,
    input ARVALID,
    output ARREADY,
    // READ DATA CHANNEL
    output reg [`AXI_DATA_WIDTH-1:0] RDATA,
    output reg [1:0] RRESP,
    output reg RVALID,
    input RREADY

);

reg [`AXI_DATA_WIDTH-1:0] memory [0:255];//nothing but dmem, common for all soc
//now 8 bitss=1 byte, therefore each mem adrress contains 4byte

//write path
//always ready to acccept  write
assign AWREADY = 1'b1;
assign WREADY  = 1'b1;


//delay
reg [1:0] read_delay_cnt;
reg [31:0] pending_read_addr;
reg [1:0] write_delay_cnt;


always @(posedge clk or posedge reset)
begin
    if(reset)
    begin
        BVALID <= 1'b0;
        BRESP  <= `RESP_OKAY;
        write_delay_cnt <= 2'd0;
    end
    else
    begin
        // accept new write only if no write is already pending
        if(AWVALID && WVALID &&
           (write_delay_cnt == 0) &&
           !BVALID)
        begin
            memory[AWADDR[9:2]] <= WDATA;
            write_delay_cnt <= 2'd3;
        end

        // countdown latency
        else if(write_delay_cnt != 0)
        begin
            write_delay_cnt <= write_delay_cnt - 1'b1;

            if(write_delay_cnt == 2'd1)
            begin
                BVALID <= 1'b1;
                BRESP  <= `RESP_OKAY;
            end
        end

        // response handshake completed
        else if(BVALID && BREADY)
        begin
            BVALID <= 1'b0;
        end
    end
end
//readpath
//always ready to accept
   assign ARREADY = 1'b1;

always @(posedge clk or posedge reset)
begin
    if(reset)
    begin
        RVALID <= 1'b0;
        RRESP  <= `RESP_OKAY;
        RDATA  <= 32'b0;

        read_delay_cnt   <= 2'd0;
        pending_read_addr <= 32'd0;
    end
    else
    begin
        if(ARVALID && read_delay_cnt == 0 && !RVALID)
        begin
            pending_read_addr <= ARADDR;
            read_delay_cnt <= 2'd3;
        end
        else if(read_delay_cnt != 0)
        begin
            read_delay_cnt <= read_delay_cnt - 1'b1;
            if(read_delay_cnt == 1)
            begin
                RDATA  <= memory[pending_read_addr[9:2]];
                RVALID <= 1'b1;
                RRESP  <= `RESP_OKAY;
            end
        end
        else if(RVALID && RREADY)
        begin
            RVALID <= 1'b0;
        end
    end
end
endmodule
`include "axi_defs.vh"

module axi_uart_slave(
    input clk,
    input reset,

    // WRITE ADDRESS CHANNEL here master says it want to write and slave tells if ready 
    input [`AXI_ADDR_WIDTH-1:0] AWADDR,
    input AWVALID,
    output AWREADY,

    // WRITE DATA CHANNEL here master gives data to slave to write
    input [`AXI_DATA_WIDTH-1:0] WDATA,
    input WVALID,
    output WREADY,

    // WRITE RESPONSE CHANNEL slave tells master that writing is complete
    output reg [1:0] BRESP,
    output reg BVALID,
    input BREADY,

    // READ ADDRESS CHANNEL here master tells that he want to read
    input [`AXI_ADDR_WIDTH-1:0] ARADDR,
    input ARVALID,
    output ARREADY,

    // READ DATA CHANNEL by this slave give master the data it want to read
    output reg [`AXI_DATA_WIDTH-1:0] RDATA,
    output reg [1:0] RRESP,
    output reg RVALID,
    input RREADY
);

assign AWREADY = 1'b1;
assign WREADY  = 1'b1;
assign ARREADY = 1'b1;

// UART registers
reg [31:0] tx_data_reg;
reg [31:0] status_reg;
//initiating uart_tx inside it 
reg tx_start;
wire tx;
wire busy;
uart_tx transmitter(
    .clk(clk),
    .reset(reset),
    .tx_data(tx_data_reg[7:0]),
    .tx_start(tx_start),
    .tx(tx),
    .busy(busy)
);

// Write response path
always @(posedge clk or posedge reset)
begin
    if(reset)
    begin
        BVALID <= 1'b0;
        BRESP  <= `RESP_OKAY;
        tx_start <= 1'b0;
        tx_data_reg <= 32'd0;
        status_reg  <= 32'd0;
    end
    else
    begin
        tx_start <= 1'b0;
        if(AWVALID && WVALID && !BVALID)
                begin
                    case(AWADDR[3:0])
                    4'h0:begin
                           tx_data_reg <= WDATA;
                           tx_start    <= 1'b1;
                        end
                    4'h4:
                        status_reg <= WDATA;
                    default:    ;
                    endcase 

                    BVALID <= 1'b1;
                    BRESP  <= `RESP_OKAY;
                end
    else if(BVALID && BREADY)
        begin
            BVALID <= 1'b0;
        end
    end
end

// Read response path
always @(posedge clk or posedge reset)
begin
    if(reset)
    begin
        RVALID <= 1'b0;
        RRESP  <= `RESP_OKAY;
        RDATA  <= 32'd0;
    end
    else
    begin
        if(ARVALID)
        begin
            RVALID <= 1'b1;
            RRESP  <= `RESP_OKAY;

            case(ARADDR[3:0])

                4'h0:
                    RDATA <= tx_data_reg;

                4'h4:
                    RDATA <= status_reg;

                default:
                    RDATA <= 32'd0;

            endcase
        end
        else if(RVALID && RREADY)
        begin
            RVALID <= 1'b0;
        end
    end
end

endmodule
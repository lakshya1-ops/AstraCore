`include "axi_defs.vh"

module axi_timer_slave(
    input clk,
    input reset,

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
    input RREADY,

    output timer_irq
);

assign AWREADY = 1'b1;
assign WREADY  = 1'b1;
assign ARREADY = 1'b1;

// Register map:
// 0x00 CTRL    bit0=enable, bit1=irq_enable, bit2=clear_count
// 0x04 COUNT   current timer count
// 0x08 COMPARE compare value
// 0x0C STATUS  bit0=match, write 1 to clear

reg timer_enable;
reg irq_enable;//interrut generator
reg [31:0] count_reg;//increase every clock
reg [31:0] compare_reg;//expected idead value of counter
reg status_match; //=1 if comapre=count

assign timer_irq = irq_enable && status_match;

// Timer counter
always @(posedge clk or posedge reset)
begin
    if(reset)
    begin
        count_reg <= 32'd0;
        status_match <= 1'b0;
    end
    else
    begin
        if(timer_enable)
        begin
            count_reg <= count_reg + 1'b1;

            if(count_reg == compare_reg)
                status_match <= 1'b1;
        end
    end
end

// AXI write path
always @(posedge clk or posedge reset)
begin
    if(reset)
    begin
        BVALID <= 1'b0;
        BRESP <= `RESP_OKAY;

        timer_enable <= 1'b0;
        irq_enable <= 1'b0;
        compare_reg <= 32'd0;
    end
    else
    begin
        if(AWVALID && WVALID && !BVALID)
        begin
            case(AWADDR[3:0])
                4'h0:
                begin
                    timer_enable <= WDATA[0];
                    irq_enable <= WDATA[1];

                    if(WDATA[2])
                    begin
                        count_reg <= 32'd0;
                        status_match <= 1'b0;
                    end
                end

                4'h4:
                begin
                    count_reg <= WDATA;
                end

                4'h8:
                begin
                    compare_reg <= WDATA;
                end

                4'hC:
                begin
                    if(WDATA[0])
                        status_match <= 1'b0;
                end

                default:
                begin
                end
            endcase

            BVALID <= 1'b1;
            BRESP <= `RESP_OKAY;
        end
        else if(BVALID && BREADY)
        begin
            BVALID <= 1'b0;
        end
    end
end

// AXI read path
always @(posedge clk or posedge reset)
begin
    if(reset)
    begin
        RVALID <= 1'b0;
        RRESP <= `RESP_OKAY;
        RDATA <= 32'd0;
    end
    else
    begin
        if(ARVALID && !RVALID)
        begin
            RVALID <= 1'b1;
            RRESP <= `RESP_OKAY;

            case(ARADDR[3:0])
                4'h0:
                    RDATA <= {29'd0, 1'b0, irq_enable, timer_enable};

                4'h4:
                    RDATA <= count_reg;

                4'h8:
                    RDATA <= compare_reg;

                4'hC:
                    RDATA <= {31'd0, status_match};

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
`include "axi_defs.vh"

module axi_timer_slave(
    input clk,
    input reset,

    input [`AXI_ADDR_WIDTH-1:0] AWADDR,
    input AWVALID,
    output AWREADY,

    input [`AXI_DATA_WIDTH-1:0] WDATA,
    input WVALID,
    output WREADY,

    output reg [1:0] BRESP,
    output reg BVALID,
    input BREADY,

    input [`AXI_ADDR_WIDTH-1:0] ARADDR,
    input ARVALID,
    output ARREADY,

    output reg [`AXI_DATA_WIDTH-1:0] RDATA,
    output reg [1:0] RRESP,
    output reg RVALID,
    input RREADY,

    output timer_irq
);

assign AWREADY = 1'b1;
assign WREADY  = 1'b1;
assign ARREADY = 1'b1;

reg timer_enable;
reg irq_enable;
reg [31:0] count_reg;
reg [31:0] compare_reg;
reg status_match;

assign timer_irq = irq_enable && status_match;

// Combined always block — fixes multiple driver conflict
always @(posedge clk or posedge reset) begin
    if(reset) begin
        count_reg    <= 32'd0;
        status_match <= 1'b0;
        timer_enable <= 1'b0;
        irq_enable   <= 1'b0;
        compare_reg  <= 32'd0;
        BVALID       <= 1'b0;
        BRESP        <= `RESP_OKAY;
    end
    else begin
        // AXI write path
        if(AWVALID && WVALID && !BVALID) begin
            case(AWADDR[3:0])
                4'h0: begin
                    timer_enable <= WDATA[0];
                    irq_enable   <= WDATA[1];
                    if(WDATA[2]) begin
                        count_reg    <= 32'd0;
                        status_match <= 1'b0;
                    end
                end
                4'h4: count_reg    <= WDATA;
                4'h8: compare_reg  <= WDATA;
                4'hC: if(WDATA[0]) status_match <= 1'b0;
                default: ;
            endcase
            BVALID <= 1'b1;
            BRESP  <= `RESP_OKAY;
        end
        else if(BVALID && BREADY) begin
            BVALID <= 1'b0;
        end
        else begin
            // Timer counter — only runs when no AXI write
            if(timer_enable) begin
                count_reg <= count_reg + 1'b1;
                if(count_reg == compare_reg)
                    status_match <= 1'b1;
            end
        end
    end
end

// AXI read path
always @(posedge clk or posedge reset) begin
    if(reset) begin
        RVALID <= 1'b0;
        RRESP  <= `RESP_OKAY;
        RDATA  <= 32'd0;
    end
    else begin
        if(ARVALID && !RVALID) begin
            RVALID <= 1'b1;
            RRESP  <= `RESP_OKAY;
            case(ARADDR[3:0])
                4'h0: RDATA <= {29'd0, 1'b0, irq_enable, timer_enable};
                4'h4: RDATA <= count_reg;
                4'h8: RDATA <= compare_reg;
                4'hC: RDATA <= {31'd0, status_match};
                default: RDATA <= 32'd0;
            endcase
        end
        else if(RVALID && RREADY) begin
            RVALID <= 1'b0;
        end
    end
end

endmodule

//=============================================================================
// axi_accel_slave.v
// AstraCore Matrix Accelerator — AXI-Lite Slave
// Author : Lakshya Chowdhury
// Project: AstraCore RISC-V SoC
//
// Matches axi_uart_slave.v style exactly.
// Read path fully combinational — no stale data, no address race.
//=============================================================================

`include "axi_defs.vh"
`include "accelerator_pkg.vh"

module axi_accel_slave #(
    parameter MATRIX_DIM = `MATRIX_DIM,
    parameter DATA_WIDTH = `DATA_WIDTH,
    parameter ACC_WIDTH  = `ACC_WIDTH
)(
    input           clk,
    input           rst,

    // AXI-lite slave ports
    input  [31:0]   AWADDR,
    input           AWVALID,
    output          AWREADY,

    input  [31:0]   WDATA,
    input           WVALID,
    output          WREADY,

    output reg [1:0]  BRESP,
    output reg        BVALID,
    input             BREADY,

    input  [31:0]   ARADDR,
    input           ARVALID,
    output          ARREADY,

    output reg [31:0] RDATA,
    output reg        RVALID,
    input             RREADY,
    output reg [1:0]  RRESP,

    // Register bank ports
    output reg          reg_wr_en,
    output reg [7:0]    reg_wr_addr,
    output reg [31:0]   reg_wr_data,
    output [7:0]        reg_rd_addr,    // FIX 1: wire not reg
    input  [31:0]       reg_rd_data,

    // Matrix buffer CPU write port
    output reg          cpu_wr_en,
    output reg          cpu_sel_a,
    output reg [`BUF_ADDR_WIDTH-1:0] cpu_wr_addr,
    output reg [DATA_WIDTH-1:0]      cpu_wr_data,

    // Matrix buffer CPU read port
    output [`BUF_ADDR_WIDTH-1:0]     cpu_rd_addr,    // FIX 3: wire not reg
    input  [ACC_WIDTH-1:0]           cpu_rd_data
);

    //-------------------------------------------------------------------------
    // ALWAYS READY
    //-------------------------------------------------------------------------
    assign AWREADY = 1'b1;
    assign WREADY  = 1'b1;
    assign ARREADY = 1'b1;

    //-------------------------------------------------------------------------
    // ADDRESS OFFSETS
    //-------------------------------------------------------------------------
    wire [7:0] wr_offset = AWADDR[7:0];
    wire [7:0] rd_offset = ARADDR[7:0];

    //-------------------------------------------------------------------------
    // FIX 1 + 3 — READ ADDRESSES ARE CONTINUOUS ASSIGNMENTS
    // reg_rd_addr and cpu_rd_addr are wires driven directly from ARADDR
    // No clock — no race — always current
    //-------------------------------------------------------------------------
    assign reg_rd_addr = ARADDR[7:0];                          // FIX 1

    assign cpu_rd_addr = (ARADDR[7:0] - `REG_C_BASE) >> 2;    // FIX 3

    //-------------------------------------------------------------------------
    // WRITE LOGIC
    // BVALID held until BREADY handshake
    //-------------------------------------------------------------------------
    always @(posedge clk) begin
        if(rst) begin
            reg_wr_en   <= 1'b0;
            reg_wr_addr <= 8'h0;
            reg_wr_data <= 32'h0;
            cpu_wr_en   <= 1'b0;
            cpu_sel_a   <= 1'b0;
            cpu_wr_addr <= 0;
            cpu_wr_data <= 0;
            BVALID      <= 1'b0;
            BRESP       <= `AXI_RESP_OKAY;
        end
        else begin
            // default deassert strobes
            reg_wr_en <= 1'b0;
            cpu_wr_en <= 1'b0;

            // hold BVALID until handshake
            if(BVALID && BREADY)
                BVALID <= 1'b0;

            if(AWVALID && WVALID && !BVALID) begin
                BVALID <= 1'b1;
                BRESP  <= `AXI_RESP_OKAY;

                if(wr_offset == `REG_CONTROL ||
                   wr_offset == `REG_DIM) begin
                    reg_wr_en   <= 1'b1;
                    reg_wr_addr <= wr_offset;
                    reg_wr_data <= WDATA;
                end

                else if(wr_offset >= `REG_A_BASE &&
                        wr_offset <  `REG_A_BASE +
                                     (MATRIX_DIM * MATRIX_DIM * 4)) begin
                    cpu_wr_en   <= 1'b1;
                    cpu_sel_a   <= 1'b1;
                    cpu_wr_addr <= (wr_offset - `REG_A_BASE) >> 2;
                    cpu_wr_data <= WDATA[DATA_WIDTH-1:0];
                end

                else if(wr_offset >= `REG_B_BASE &&
                        wr_offset <  `REG_B_BASE +
                                     (MATRIX_DIM * MATRIX_DIM * 4)) begin
                    cpu_wr_en   <= 1'b1;
                    cpu_sel_a   <= 1'b0;
                    cpu_wr_addr <= (wr_offset - `REG_B_BASE) >> 2;
                    cpu_wr_data <= WDATA[DATA_WIDTH-1:0];
                end

                else begin
                    BRESP <= `AXI_RESP_SLVERR;
                end
            end
        end
    end

    //-------------------------------------------------------------------------
    // READ LOGIC
    // RVALID held until RREADY handshake
    // reg_rd_addr and cpu_rd_addr are wires — always current (FIX 2+4)
    // RDATA captured from combinational regbank/buffer output
    //-------------------------------------------------------------------------
    always @(posedge clk) begin
        if(rst) begin
            RVALID <= 1'b0;
            RDATA  <= 32'h0;
            RRESP  <= `AXI_RESP_OKAY;
            // FIX 5: no reg_rd_addr or cpu_rd_addr reset — they are wires
        end
        else begin
            // hold RVALID until handshake
            if(RVALID && RREADY)
                RVALID <= 1'b0;

            if(ARVALID && !RVALID) begin
                RVALID <= 1'b1;
                RRESP  <= `AXI_RESP_OKAY;

                if(rd_offset == `REG_CONTROL ||
                   rd_offset == `REG_STATUS  ||
                   rd_offset == `REG_DIM) begin
                    // FIX 2: no reg_rd_addr assignment — it's a wire
                    // reg_rd_data already valid because reg_rd_addr
                    // is combinationally driven from ARADDR
                    RDATA <= reg_rd_data;
                end

                else if(rd_offset >= `REG_C_BASE &&
                        rd_offset <  `REG_C_BASE +
                                     (MATRIX_DIM * MATRIX_DIM * 4)) begin
                    // FIX 4: no cpu_rd_addr assignment — it's a wire
                    // cpu_rd_data already valid because cpu_rd_addr
                    // is combinationally driven from ARADDR
                    RDATA <= cpu_rd_data;
                end

                else begin
                    RDATA <= 32'hDEADBEEF;
                    RRESP <= `AXI_RESP_SLVERR;
                end
            end
        end
    end

endmodule
module uart_tx(
    input clk,
    input reset,

    input [7:0] tx_data,
    input tx_start,

    output reg tx,
    output reg busy
);

// FSM states
localparam IDLE  = 2'd0;
localparam START = 2'd1;
localparam DATA  = 2'd2;
localparam STOP  = 2'd3;

reg [1:0] state;
reg [2:0] bit_cnt;
reg [7:0] shift_reg;

always @(posedge clk or posedge reset)
begin
    if(reset)
    begin
        state   <= IDLE;
        bit_cnt <= 3'd0;
        shift_reg <= 8'd0;
        tx      <= 1'b1;
        busy    <= 1'b0;
    end
    else
    begin
        case(state)
            IDLE:
            begin
                tx   <= 1'b1;
                busy <= 1'b0;
                if(tx_start)
                    begin
                        shift_reg <= tx_data;
                        bit_cnt   <= 3'd0;
                        state <= START;
                        busy  <= 1'b1;
                    end
            end
            START:
            begin
                tx <= 1'b0;
                state <= DATA;
            end
            DATA:
                begin
                    tx <= shift_reg[0];
                    shift_reg <= shift_reg >> 1;
                    if(bit_cnt == 3'd7)
                    begin
                        state <= STOP;
                    end
                    else
                    begin
                        bit_cnt <= bit_cnt + 1'b1;
                    end
                end
            STOP:
                begin
                    tx   <= 1'b1;
                    busy <= 1'b0;
                    state <= IDLE;
                end
        endcase
    end
end
endmodule
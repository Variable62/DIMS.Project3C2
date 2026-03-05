//----------------------------------------//
// Filename     : data_sender.v
// Description  : Send Data To ESP32
// Company      : KMITL
// Project      : Impedance Analyzer
//----------------------------------------//
// Version      : 1.0
// Date         : 6 March 2026
// Author       : Adisorn Sommart
// Remark       : New Creation
//----------------------------------------//
module data_sender (
    input wire CLK48MHz,
    input wire RESETn,
    input wire start,  
    input wire [18:0] CountPhase,  
    input wire ACK,  

    output reg Req,  
    output reg [3:0] CountOut  
);
  parameter IDLE = 3'd0, DataReady = 3'd1, WaitAck = 3'd2, WaitNext = 3'd3;

  reg [ 2:0] state;
  reg [ 2:0] nibble_cnt;
  reg [19:0] data_latch;
  reg [ 1:0] rAck_sync;

  always @(posedge CLK48MHz) rAck_sync <= {rAck_sync[0], ACK};
  wire wAck = rAck_sync[1];

  always @(posedge CLK48MHz or negedge RESETn) begin
    if (!RESETn) begin
      state <= IDLE;
      Req <= 0;
      nibble_cnt <= 0;
    end else begin

      case (state)

        IDLE: begin
          Req <= 0;
          if (start) begin
            data_latch <= {1'b0, CountPhase}; 
            nibble_cnt <= 0;
            state <= DataReady;
          end
        end

        DataReady: begin
          case (nibble_cnt)
            0: CountOut <= data_latch[3:0];
            1: CountOut <= data_latch[7:4];
            2: CountOut <= data_latch[11:8];
            3: CountOut <= data_latch[15:12];
            4:CountOut <= data_latch[19:16]; 
            default: CountOut <= 4'd0;
          endcase
          Req   <= 1;
          state <= WaitAck;
        end

        WaitAck: begin
          if (wAck) begin 
            Req   <= 0;
            state <= WaitNext;
          end
        end

        WaitNext: begin
          if (!wAck) begin
            if (nibble_cnt == 4) 
              state <= IDLE;
            else begin
              nibble_cnt <= nibble_cnt + 1;
              state <= DataReady;
            end
          end
        end
        default: state <= IDLE;

      endcase

    end

  end

endmodule

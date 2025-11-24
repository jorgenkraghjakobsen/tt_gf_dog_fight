/*
 * TMDS Encoder for DVI/HDMI
 * Encodes 8-bit video data into 10-bit TMDS symbols
 * Based on DVI 1.0 specification
 */

`default_nettype none

module tmds_encoder(
  input wire clk,
  input wire [7:0] data,
  input wire [1:0] control,
  input wire video_data_enable,
  output reg [9:0] tmds_out
);

  // Count ones in a byte
  function [3:0] count_ones;
    input [7:0] data;
    integer i;
    begin
      count_ones = 0;
      for (i = 0; i < 8; i = i + 1)
        count_ones = count_ones + data[i];
    end
  endfunction

  // Stage 1: XOR or XNOR encoding
  wire [8:0] q_m;
  wire [3:0] num_ones = count_ones(data);

  assign q_m[0] = data[0];
  assign q_m[1] = (num_ones > 4 || (num_ones == 4 && !data[0])) ?
                  q_m[0] ~^ data[1] : q_m[0] ^ data[1];
  assign q_m[2] = (num_ones > 4 || (num_ones == 4 && !data[0])) ?
                  q_m[1] ~^ data[2] : q_m[1] ^ data[2];
  assign q_m[3] = (num_ones > 4 || (num_ones == 4 && !data[0])) ?
                  q_m[2] ~^ data[3] : q_m[2] ^ data[3];
  assign q_m[4] = (num_ones > 4 || (num_ones == 4 && !data[0])) ?
                  q_m[3] ~^ data[4] : q_m[3] ^ data[4];
  assign q_m[5] = (num_ones > 4 || (num_ones == 4 && !data[0])) ?
                  q_m[4] ~^ data[5] : q_m[4] ^ data[5];
  assign q_m[6] = (num_ones > 4 || (num_ones == 4 && !data[0])) ?
                  q_m[5] ~^ data[6] : q_m[5] ^ data[6];
  assign q_m[7] = (num_ones > 4 || (num_ones == 4 && !data[0])) ?
                  q_m[6] ~^ data[7] : q_m[6] ^ data[7];
  assign q_m[8] = (num_ones > 4 || (num_ones == 4 && !data[0])) ? 1'b0 : 1'b1;

  // Stage 2: DC balancing
  reg signed [4:0] dc_bias = 0;
  wire [3:0] num_ones_qm = count_ones(q_m[7:0]);
  wire [3:0] num_zeros_qm = 8 - num_ones_qm;

  always @(posedge clk) begin
    if (!video_data_enable) begin
      // Control period
      case (control)
        2'b00: tmds_out <= 10'b1101010100;
        2'b01: tmds_out <= 10'b0010101011;
        2'b10: tmds_out <= 10'b0101010100;
        2'b11: tmds_out <= 10'b1010101011;
      endcase
      dc_bias <= 0;
    end else begin
      // Video data period
      if (dc_bias == 0 || num_ones_qm == 4) begin
        if (q_m[8]) begin
          tmds_out <= {2'b01, q_m[7:0]};
          dc_bias <= dc_bias + num_ones_qm - num_zeros_qm;
        end else begin
          tmds_out <= {2'b10, ~q_m[7:0]};
          dc_bias <= dc_bias + num_zeros_qm - num_ones_qm;
        end
      end else begin
        if ((dc_bias[4] && (num_ones_qm > 4)) || (!dc_bias[4] && (num_zeros_qm > 4))) begin
          tmds_out <= {1'b1, q_m[8], ~q_m[7:0]};
          dc_bias <= dc_bias + {q_m[8], 1'b0} + num_zeros_qm - num_ones_qm;
        end else begin
          tmds_out <= {1'b0, q_m[8], q_m[7:0]};
          dc_bias <= dc_bias - {~q_m[8], 1'b0} + num_ones_qm - num_zeros_qm;
        end
      end
    end
  end

endmodule

`default_nettype wire

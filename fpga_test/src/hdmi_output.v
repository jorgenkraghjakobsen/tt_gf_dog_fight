`default_nettype none

// HDMI Output Wrapper Module
// This module is ONLY used for FPGA testing
// It converts simple VGA signals to HDMI differential outputs
// Students don't need to understand this - it's FPGA infrastructure!

module hdmi_output(
    input wire clk_pixel,        // 25.175 MHz pixel clock
    input wire clk_5x,           // 125.875 MHz TMDS clock (5x pixel clock)
    input wire rst_n,            // Active-low reset

    // Simple VGA inputs (from pattern generator)
    input wire hsync,
    input wire vsync,
    input wire [1:0] red,
    input wire [1:0] green,
    input wire [1:0] blue,
    input wire video_active,

    // HDMI differential outputs
    output wire tmds_clk_p,
    output wire tmds_clk_n,
    output wire [2:0] tmds_d_p,
    output wire [2:0] tmds_d_n
);

    // Expand 2-bit color to 8-bit for TMDS encoder
    wire [7:0] red_8bit   = {red, red, red, red};
    wire [7:0] green_8bit = {green, green, green, green};
    wire [7:0] blue_8bit  = {blue, blue, blue, blue};

    // VGA sync to TMDS control signals (active high for encoder)
    wire hsync_pulse = !hsync;  // Convert active-low to active-high
    wire vsync_pulse = !vsync;

    // TMDS encoded outputs
    wire [9:0] red_tmds, green_tmds, blue_tmds;

    // TMDS Encoders - convert 8-bit RGB + sync to 10-bit TMDS
    tmds_encoder enc_red (
        .clk(clk_pixel),
        .data(red_8bit),
        .control(2'b00),
        .video_data_enable(video_active),
        .tmds_out(red_tmds)
    );

    tmds_encoder enc_green (
        .clk(clk_pixel),
        .data(green_8bit),
        .control(2'b00),
        .video_data_enable(video_active),
        .tmds_out(green_tmds)
    );

    tmds_encoder enc_blue (
        .clk(clk_pixel),
        .data(blue_8bit),
        .control({vsync_pulse, hsync_pulse}),
        .video_data_enable(video_active),
        .tmds_out(blue_tmds)
    );

    // Serialized TMDS data
    wire [2:0] tmds_data;
    wire tmds_clock;

    // OSER10 Serializers - convert 10-bit parallel to high-speed serial
    OSER10 #(.GSREN("false"), .LSREN("true")) ser_red (
        .Q(tmds_data[2]),
        .D0(red_tmds[0]), .D1(red_tmds[1]), .D2(red_tmds[2]), .D3(red_tmds[3]), .D4(red_tmds[4]),
        .D5(red_tmds[5]), .D6(red_tmds[6]), .D7(red_tmds[7]), .D8(red_tmds[8]), .D9(red_tmds[9]),
        .PCLK(clk_pixel),
        .FCLK(clk_5x),
        .RESET(1'b0)
    );

    OSER10 #(.GSREN("false"), .LSREN("true")) ser_green (
        .Q(tmds_data[1]),
        .D0(green_tmds[0]), .D1(green_tmds[1]), .D2(green_tmds[2]), .D3(green_tmds[3]), .D4(green_tmds[4]),
        .D5(green_tmds[5]), .D6(green_tmds[6]), .D7(green_tmds[7]), .D8(green_tmds[8]), .D9(green_tmds[9]),
        .PCLK(clk_pixel),
        .FCLK(clk_5x),
        .RESET(1'b0)
    );

    OSER10 #(.GSREN("false"), .LSREN("true")) ser_blue (
        .Q(tmds_data[0]),
        .D0(blue_tmds[0]), .D1(blue_tmds[1]), .D2(blue_tmds[2]), .D3(blue_tmds[3]), .D4(blue_tmds[4]),
        .D5(blue_tmds[5]), .D6(blue_tmds[6]), .D7(blue_tmds[7]), .D8(blue_tmds[8]), .D9(blue_tmds[9]),
        .PCLK(clk_pixel),
        .FCLK(clk_5x),
        .RESET(1'b0)
    );

    OSER10 #(.GSREN("false"), .LSREN("true")) ser_clock (
        .Q(tmds_clock),
        .D0(1'b0), .D1(1'b0), .D2(1'b0), .D3(1'b0), .D4(1'b0),
        .D5(1'b1), .D6(1'b1), .D7(1'b1), .D8(1'b1), .D9(1'b1),
        .PCLK(clk_pixel),
        .FCLK(clk_5x),
        .RESET(1'b0)
    );

    // Differential output buffers
    ELVDS_OBUF tmds_buf_clk (.I(tmds_clock), .O(tmds_clk_p), .OB(tmds_clk_n));
    ELVDS_OBUF tmds_buf_d0 (.I(tmds_data[0]), .O(tmds_d_p[0]), .OB(tmds_d_n[0]));
    ELVDS_OBUF tmds_buf_d1 (.I(tmds_data[1]), .O(tmds_d_p[1]), .OB(tmds_d_n[1]));
    ELVDS_OBUF tmds_buf_d2 (.I(tmds_data[2]), .O(tmds_d_p[2]), .OB(tmds_d_n[2]));

endmodule

`default_nettype wire

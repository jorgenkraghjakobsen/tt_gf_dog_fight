`default_nettype none

// FPGA wrapper for dogbattle using proven working clock architecture
// Based on fpga_top_test which successfully displays on monitor

module fpga_top(
    input wire clk,              // 27 MHz onboard clock
    input wire btn_s1,           // Button S1 (reset)
    input wire btn_s2,           // Button S2 (unused)

    // HDMI outputs
    output wire tmds_clk_p,
    output wire tmds_clk_n,
    output wire [2:0] tmds_d_p,
    output wire [2:0] tmds_d_n,

    // Debug outputs
    output wire led0,            // LED0 shows PLL lock status
    output wire led1
);

    // Generate 25 MHz pixel clock and 125 MHz TMDS clock
    wire clk_pixel;
    wire clk_5x;
    wire pll_lock;

    // Single PLL: 27 MHz → 126 MHz, then divide by 5 for pixel clock
    // Using exact same PLL config as working tt-vga-sjsu-bouncing project
    Gowin_rPLL_125_working pll_inst (
        .clkin(clk),
        .clkout(clk_5x),
        .lock(pll_lock)
    );

    // Divide by 5: 126 MHz → 25.2 MHz pixel clock
    reg [2:0] div_count = 0;
    reg clk_pixel_reg = 0;

    always @(posedge clk_5x) begin
        if (div_count == 4) begin
            div_count <= 0;
        end else begin
            div_count <= div_count + 1;
        end
        clk_pixel_reg <= (div_count < 2);
    end

    assign clk_pixel = clk_pixel_reg;

    // Reset synchronization
    wire rst_n = pll_lock & btn_s1;

    // VGA 640x480@60Hz timing (standard VESA)
    // Pixel clock: 25.175 MHz (we have ~25.2 MHz, 0.1% error)
    reg [9:0] hcount = 0;
    reg [9:0] vcount = 0;

    localparam H_VISIBLE = 640;
    localparam H_FRONT = 16;
    localparam H_SYNC = 96;
    localparam H_BACK = 48;
    localparam H_TOTAL = 800;

    localparam V_VISIBLE = 480;
    localparam V_FRONT = 10;
    localparam V_SYNC = 2;
    localparam V_BACK = 33;
    localparam V_TOTAL = 525;

    reg hsync_reg, vsync_reg;
    reg video_active_reg;
    reg [1:0] red_reg, green_reg, blue_reg;

    always @(posedge clk_pixel) begin
        if (!rst_n) begin
            hcount <= 0;
            vcount <= 0;
            hsync_reg <= 1'b1;
            vsync_reg <= 1'b1;
            video_active_reg <= 1'b0;
        end else begin
            // Horizontal counter
            if (hcount == H_TOTAL - 1) begin
                hcount <= 0;
                if (vcount == V_TOTAL - 1)
                    vcount <= 0;
                else
                    vcount <= vcount + 1;
            end else begin
                hcount <= hcount + 1;
            end

            // Sync signals (active low)
            hsync_reg <= !((hcount >= H_VISIBLE + H_FRONT) &&
                          (hcount < H_VISIBLE + H_FRONT + H_SYNC));
            vsync_reg <= !((vcount >= V_VISIBLE + V_FRONT) &&
                          (vcount < V_VISIBLE + V_FRONT + V_SYNC));

            // Video active
            video_active_reg <= (hcount < H_VISIBLE) && (vcount < V_VISIBLE);

            // Simple color bars pattern
            if (video_active_reg) begin
                if (hcount < 80) begin
                    // White
                    red_reg <= 2'b11;
                    green_reg <= 2'b11;
                    blue_reg <= 2'b11;
                end else if (hcount < 160) begin
                    // Yellow
                    red_reg <= 2'b11;
                    green_reg <= 2'b11;
                    blue_reg <= 2'b00;
                end else if (hcount < 240) begin
                    // Cyan
                    red_reg <= 2'b00;
                    green_reg <= 2'b11;
                    blue_reg <= 2'b11;
                end else if (hcount < 320) begin
                    // Green
                    red_reg <= 2'b00;
                    green_reg <= 2'b11;
                    blue_reg <= 2'b00;
                end else if (hcount < 400) begin
                    // Magenta
                    red_reg <= 2'b11;
                    green_reg <= 2'b00;
                    blue_reg <= 2'b11;
                end else if (hcount < 480) begin
                    // Red
                    red_reg <= 2'b11;
                    green_reg <= 2'b00;
                    blue_reg <= 2'b00;
                end else if (hcount < 560) begin
                    // Blue
                    red_reg <= 2'b00;
                    green_reg <= 2'b00;
                    blue_reg <= 2'b11;
                end else begin
                    // Black
                    red_reg <= 2'b00;
                    green_reg <= 2'b00;
                    blue_reg <= 2'b00;
                end
            end else begin
                red_reg <= 2'b00;
                green_reg <= 2'b00;
                blue_reg <= 2'b00;
            end
        end
    end

    // HDMI output
    hdmi_output hdmi (
        .clk_pixel(clk_pixel),
        .clk_5x(clk_5x),
        .rst_n(rst_n),
        .hsync(hsync_reg),
        .vsync(vsync_reg),
        .red(red_reg),
        .green(green_reg),
        .blue(blue_reg),
        .video_active(video_active_reg),
        .tmds_clk_p(tmds_clk_p),
        .tmds_clk_n(tmds_clk_n),
        .tmds_d_p(tmds_d_p),
        .tmds_d_n(tmds_d_n)
    );

    // LED shows PLL lock - OFF when locked
    assign led0 = ~pll_lock;
    assign led1 = ~btn_s2;

endmodule

`default_nettype wire

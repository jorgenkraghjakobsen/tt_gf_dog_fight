`default_nettype none

// FPGA Top for Dogbattle - uses working test pattern architecture
// Just replaces color bar generation with dogbattle instantiation

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

    // Dogbattle instantiation - uses 25.2 MHz pixel clock directly
    wire [2:0] vga_r_dog, vga_g_dog;
    wire [1:0] vga_b_dog;
    wire vga_hs_dog, vga_vs_dog, vga_active_dog;

    dogbattle_top_25mhz dogbattle_inst (
        .clk25(clk_pixel),
        .rst_n(rst_n),
        .vga_hs(vga_hs_dog),
        .vga_vs(vga_vs_dog),
        .vga_r(vga_r_dog),
        .vga_g(vga_g_dog),
        .vga_b(vga_b_dog),
        .vga_active(vga_active_dog)
    );

    // Register outputs for HDMI encoder
    reg hsync_reg, vsync_reg;
    reg video_active_reg;
    reg [1:0] red_reg, green_reg, blue_reg;

    always @(posedge clk_pixel) begin
        // Just pass through dogbattle signals
        hsync_reg <= vga_hs_dog;
        vsync_reg <= vga_vs_dog;
        red_reg <= {vga_r_dog[2:1]};    // Take top 2 bits
        green_reg <= {vga_g_dog[2:1]};  // Take top 2 bits
        blue_reg <= vga_b_dog;          // Already 2 bits
        video_active_reg <= vga_active_dog;  // Use actual active signal from dogbattle
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

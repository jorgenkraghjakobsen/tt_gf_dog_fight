// Gowin rPLL module for 125 MHz generation (for HDMI serialization)
// Input: 27 MHz -> Output: 125 MHz (close to 5x 25.175 MHz = 125.875 MHz)

module Gowin_rPLL_125 (
    input clkin,
    output clkout,
    output lock
);

// PLL configuration for Tang Nano 9K
// FCLKIN = 27 MHz → 125.875 MHz output (for HDMI TMDS serialization)
// This is 5× 25.175 MHz (exact VGA pixel clock frequency)
// Formula: FCLKOUT = FCLKIN * (FBDIV_SEL+1) / (IDIV_SEL+1) / (ODIV_SEL+1)
// VCO Formula (per gowin_pack): VCO = FCLKIN * (FBDIV_SEL+1) * ODIV_SEL / (IDIV_SEL+1)
// Note: gowin_pack uses ODIV_SEL (not +1) in VCO calculation!
// VCO must be in range 400-1200 MHz
//
// Target: 125.875 MHz (5 × 25.175 MHz)
// 27 MHz doesn't divide evenly to 25.175 MHz, so we get as close as possible
//
// Try: IDIV=5 (÷6), FBDIV=55 (×56), ODIV=1 (÷2)
// FCLKOUT = 27 * 56 / 6 / 2 = 126 MHz (0.1% error, acceptable)
// VCO = 27 * 56 * 1 / 6 = 252 MHz (too low!)
//
// Try: IDIV=1 (÷2), FBDIV=27 (×28), ODIV=2 (÷3)
// FCLKOUT = 27 * 28 / 2 / 3 = 126 MHz
// VCO = 27 * 28 * 2 / 2 = 756 MHz (good!)

rPLL #(
    .FCLKIN("27"),
    .DEVICE("GW1NR-9C"),
    .DYN_IDIV_SEL("false"),
    .IDIV_SEL(1),           // Divide by 2 (IDIV_SEL+1)
    .DYN_FBDIV_SEL("false"),
    .FBDIV_SEL(27),         // Multiply by 28 (FBDIV_SEL+1)
    .DYN_ODIV_SEL("false"),
    .ODIV_SEL(2),           // Divide by 3 (ODIV_SEL+1), VCO uses ODIV_SEL=2
    .PSDA_SEL("0000"),
    .DYN_DA_EN("false"),
    .DUTYDA_SEL("1000"),
    .CLKOUT_FT_DIR(1'b1),
    .CLKOUTP_FT_DIR(1'b1),
    .CLKOUT_DLY_STEP(0),
    .CLKOUTP_DLY_STEP(0),
    .CLKFB_SEL("internal"),
    .CLKOUT_BYPASS("false"),
    .CLKOUTP_BYPASS("false"),
    .CLKOUTD_BYPASS("false"),
    .DYN_SDIV_SEL(2),
    .CLKOUTD_SRC("CLKOUT"),
    .CLKOUTD3_SRC("CLKOUT")
) rpll_inst (
    .CLKOUT(clkout),
    .LOCK(lock),
    .CLKOUTP(),
    .CLKOUTD(),
    .CLKOUTD3(),
    .RESET(1'b0),
    .RESET_P(1'b0),
    .CLKIN(clkin),
    .CLKFB(1'b0),
    .FBDSEL(6'b0),
    .IDSEL(6'b0),
    .ODSEL(6'b0),
    .PSDA(4'b0),
    .DUTYDA(4'b0),
    .FDLY(4'b0)
);

endmodule

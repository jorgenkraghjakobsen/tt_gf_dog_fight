// Gowin rPLL (Phase-Locked Loop) module wrapper
// This needs to be configured via Gowin IP Core Generator
// Target: 27 MHz input -> 125.875 MHz output (5x 25.175 MHz)

module Gowin_rPLL_125_working (
    input clkin,
    output clkout,
    output lock
);

// PLL configuration for Tang Nano 9K
// FCLKIN = 27 MHz → 125 MHz output (close to 5x 25.175 MHz)
// Need VCO in range 400-1200 MHz
// Config: 27 * 25 / 6 = 112.5 MHz... trying different approach
// Formula: 27 * (24+1) / (5+1) / 2 = 27 * 25 / 6 / 2 = 56.25 MHz × 2 = 112.5 (no good)
// Try: 27 * (46+1) / (9+1) = 27 * 47 / 10 = 126.9 MHz (close to 126)
// Actually, keep 126 MHz - 0.2% error should be acceptable for HDMI

rPLL #(
    .FCLKIN("27"),
    .DEVICE("GW1NR-9C"),
    .DYN_IDIV_SEL("false"),
    .IDIV_SEL(2),           // Divide by 3 (IDIV_SEL+1)
    .DYN_FBDIV_SEL("false"),
    .FBDIV_SEL(13),         // Multiply by 14 (FBDIV_SEL+1)
    .DYN_ODIV_SEL("false"),
    .ODIV_SEL(4),           // ODIV=5 → VCO = 126*5 = 630 MHz
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

// Gowin rPLL module for 50 MHz generation
// Input: 27 MHz -> Output: 50 MHz

module Gowin_rPLL_50 (
    input clkin,
    output clkout,
    output lock
);

// PLL configuration for Tang Nano 9K
// FCLKIN = 27 MHz → 50 MHz output
// Formula: FCLKOUT = FCLKIN * (FBDIV_SEL+1) / (IDIV_SEL+1) / (ODIV_SEL+1)
// VCO Formula (per gowin_pack): VCO = FCLKIN * (FBDIV_SEL+1) * ODIV_SEL / (IDIV_SEL+1)
// Note: gowin_pack uses ODIV_SEL (not +1) in VCO calculation!
// VCO must be in range 400-1200 MHz
//
// Target: 50 MHz (close is fine, 48.6-50.625 MHz works)
// Try: IDIV=0 (÷1), FBDIV=17 (×18), ODIV=9 (÷10)
// FCLKOUT = 27 * 18 / 1 / 10 = 48.6 MHz (close!)
// VCO = 27 * 18 * 9 / 1 = 4374 MHz (too high!)
//
// Try: IDIV=4 (÷5), FBDIV=35 (×36), ODIV=3 (÷4)
// FCLKOUT = 27 * 36 / 5 / 4 = 48.6 MHz (close!)
// VCO = 27 * 36 * 3 / 5 = 583.2 MHz (good!)

rPLL #(
    .FCLKIN("27"),
    .DEVICE("GW1NR-9C"),
    .DYN_IDIV_SEL("false"),
    .IDIV_SEL(4),           // Divide by 5 (IDIV_SEL+1)
    .DYN_FBDIV_SEL("false"),
    .FBDIV_SEL(35),         // Multiply by 36 (FBDIV_SEL+1)
    .DYN_ODIV_SEL("false"),
    .ODIV_SEL(3),           // Divide by 4 (ODIV_SEL+1), VCO uses ODIV_SEL=3
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

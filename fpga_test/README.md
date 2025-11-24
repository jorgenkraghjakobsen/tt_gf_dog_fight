# Dog Battle FPGA Test Platform

This directory contains an FPGA test platform for the TinyTapeout Dog Battle design (`dogbattle_top_v8.v`) using the **Tang Nano 9K** FPGA board and the **open-source toolchain**.

## Overview

The test platform wraps your TinyTapeout design in FPGA-specific infrastructure to enable testing on real hardware with HDMI output.

### Architecture

```
┌─────────────────────────────────────────────────┐
│ fpga_top.v (FPGA wrapper)                       │
│                                                  │
│  ┌──────────────┐                               │
│  │ PLL: 27→50MHz│  ─────┐                       │
│  └──────────────┘       │                       │
│                         ▼                        │
│  ┌─────────────────────────────────────┐        │
│  │  dogbattle_top_v8.v                 │        │
│  │  (Your TinyTapeout Design)          │        │
│  │  - Takes 50 MHz clock               │        │
│  │  - Generates 25 MHz pixel clock     │        │
│  │  - Outputs VGA signals (3:3:2 RGB)  │        │
│  └─────────────────────────────────────┘        │
│                         │                        │
│                         ▼                        │
│  ┌──────────────┐  ┌─────────────────┐          │
│  │PLL: 27→125MHz│→ │  hdmi_output.v  │          │
│  └──────────────┘  │  (TMDS encoder) │→ HDMI    │
│                    └─────────────────┘          │
└─────────────────────────────────────────────────┘
```

## Directory Structure

```
fpga_test/
├── Makefile              # Build system for open-source toolchain
├── README.md            # This file
├── src/
│   ├── fpga_top.v       # Top-level FPGA wrapper
│   ├── tangnano9k.cst   # Pin constraints for Tang Nano 9K
│   ├── hdmi_output.v    # HDMI/TMDS encoder (from reference)
│   ├── tmds_encoder.v   # TMDS encoding logic
│   ├── gowin_rpll_50.v  # PLL: 27 MHz → 50 MHz
│   └── gowin_rpll_125.v # PLL: 27 MHz → 125 MHz (for HDMI)
└── obj/                 # Build outputs (created automatically)
```

## Hardware Requirements

- **Tang Nano 9K** FPGA board
- HDMI monitor
- USB cable for programming

## Software Requirements

Open-source FPGA toolchain:
- `yosys` - Synthesis
- `nextpnr-himbaechel` (or `nextpnr-gowin`) - Place and route
- `gowin_pack` - Bitstream generation
- `openFPGALoader` - Programming

## Building and Running

### Build the bitstream

```bash
cd fpga_test
make build
```

This runs the complete build flow:
1. **Synthesis** (Yosys) - Converts Verilog to netlist
2. **Place & Route** (nextpnr) - Maps design to FPGA resources
3. **Pack** (gowin_pack) - Generates bitstream

### Load to FPGA (temporary)

```bash
make load
```

Loads the bitstream to SRAM. This is fast but lost on power cycle. Good for testing.

### Flash to FPGA (persistent)

```bash
make flash
```

Writes the bitstream to flash memory. Persists across power cycles.

## Build Targets

- `make build` - Complete build (synth + pnr + pack)
- `make synth` - Synthesis only
- `make pnr` - Place and route only
- `make pack` - Pack bitstream only
- `make load` - Load to SRAM (temporary)
- `make flash` - Flash to memory (persistent)
- `make clean` - Remove build artifacts
- `make test` - Show configuration
- `make help` - Show detailed help

## Clock Configuration

The design uses two PLLs:

1. **50 MHz PLL** - For the game logic
   - Input: 27 MHz (Tang Nano 9K onboard clock)
   - Output: 50 MHz (expected by `dogbattle_top_v8`)
   - The dogbattle core divides this to 25 MHz internally

2. **125 MHz PLL** - For HDMI serialization
   - Input: 27 MHz
   - Output: ~126 MHz (5× pixel clock for TMDS)
   - Used for serializing 10-bit TMDS symbols

## Pin Assignments

See `src/tangnano9k.cst` for complete pin mapping:

- **Clock**: Pin 52 (27 MHz onboard)
- **Buttons**: Pins 3, 4 (S1=reset, S2=unused)
- **LEDs**: Pins 10, 11 (LED0=PLL lock indicator)
- **HDMI**: Pins 68-75 (4 TMDS differential pairs)

## Troubleshooting

### USB Device Not Found

If `openFPGALoader` can't find the device, check/modify `USB_DEVICE` in the Makefile:

```makefile
USB_DEVICE = /dev/ttyUSB0  # or /dev/ttyUSB1, etc.
```

Find your device with:
```bash
ls /dev/ttyUSB*
```

### No HDMI Output

1. Check LED0 - should be **ON** when PLLs are locked
2. Try a different HDMI cable or monitor
3. Some monitors are picky about sync timing - the design uses standard 640x480@60Hz

### Build Errors

Make sure all source files are present:
```bash
make test  # Shows all source files and configuration
```

The build requires both FPGA sources (in `fpga_test/src/`) and TinyTapeout sources (in `../src/`).

## Design Notes

### What's Different from Pure ASIC?

The TinyTapeout design (`dogbattle_top_v8.v`) is **unchanged**. The FPGA wrapper adds:

1. **Clock generation** - PLLs to generate 50 MHz from 27 MHz
2. **HDMI encoding** - Converts simple VGA to HDMI differential signals
3. **Reset handling** - Synchronizes reset to PLL lock

### Color Depth

The dogbattle core outputs:
- 3 bits red
- 3 bits green
- 2 bits blue

The HDMI encoder takes the top 2 bits of R/G and both bits of B, expanding to 8 bits for TMDS encoding.

### Testing Your Changes

After modifying the TinyTapeout source files in `../src/`, just rebuild:

```bash
make clean
make build
make load
```

The Makefile automatically includes your design files.

## Reference

This test platform is based on the working VGA/HDMI demo from:
`/home/jakobsen/work/asic/workspace/tt10/tt-vga-sjsu-bouncing/fpga_vga_demo/`

## Next Steps

1. Build and test the current design
2. Verify the 4-dog battle animation on HDMI monitor
3. Modify the game logic in `../src/game_core_v8.v`
4. Rebuild and test your changes
5. When satisfied, the TinyTapeout design is ready for submission!

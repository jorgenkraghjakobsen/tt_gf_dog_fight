# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a **Tiny Tapeout** (TinyTapeout Game First) project implementing a VGA-based "Dog Battle" game engine on silicon. The design targets the **GF180MCU** PDK and outputs to a VGA display with animated "dogs" (colored boxes) that bounce around with physics simulation.

- **Target Platform**: Tiny Tapeout shuttle (ASIC submission)
- **PDK**: GF180MCU (gf180mcuD)
- **Clock**: 50 MHz input, internally divided to 25 MHz for VGA timing
- **Output**: 640x480 VGA @ 60Hz (3-bit R, 3-bit G, 2-bit B + sync signals)
- **Top Module**: `tt_um_SophusAndreassen_dogbattle`

### Current Working Demo Status

**Verified Working:** Single sprite (square box) animates horizontally across the screen.

The current implementation in `game_core_v8.v` features:
- **1 active dog (Dog 0)** with simplified physics
- **Starting position:** x=100, y=100 (near center-left)
- **Initial velocity:** velx=512, vely=384 (fixed-point 8.8 format)
- **Movement:** Box moves from mid-screen position toward right border
- **Friction:** 98% velocity retention per frame (multiplier: 251/256)
- **Boundary behavior:** Stops at right border (velocity halves on collision)
- **Dogs 1-3:** Inactive (position at 0,0, zero velocity)

This minimal implementation successfully demonstrates:
- Clock division (50 MHz → 25 MHz) working correctly
- VGA timing generation and sync signals
- Frame-synchronized updates via `frame_tick`
- Procedural dog sprite rendering (see DOG_RENDERING.md)
- Background gradient
- Fixed-point arithmetic for smooth animation

## Building and Testing

### RTL Simulation (cocotb)

```bash
cd test
make -B              # Run RTL simulation with Icarus Verilog
make -B FST=         # Generate VCD format instead of FST
```

View waveforms:
```bash
gtkwave tb.fst tb.gtkw    # GTKWave
surfer tb.fst             # Surfer
```

### Gate-Level Simulation

After hardening the design, copy the gate-level netlist:
```bash
cp ../runs/wokwi/results/final/verilog/gl/tt_um_SophusAndreassen_dogbattle.v test/gate_level_netlist.v
cd test
make -B GATES=yes
```

### FPGA Testing (Tang Nano 9K)

The `fpga_test/` directory contains a complete FPGA test platform with HDMI output:

```bash
cd fpga_test
make build    # Synthesize, place & route, generate bitstream
make load     # Load to SRAM (temporary, for testing)
make flash    # Flash to memory (persistent)
make clean    # Remove build artifacts
```

Requirements: `yosys`, `nextpnr-himbaechel`, `gowin_pack`, `openFPGALoader`

### GitHub Actions

The repository includes workflows for:
- **GDS generation**: `.github/workflows/gds.yaml` (builds ASIC using LibreLane)
- **Test**: `.github/workflows/test.yaml` (runs cocotb tests)
- **FPGA**: `.github/workflows/fpga.yaml` (builds FPGA bitstream)
- **Docs**: `.github/workflows/docs.yaml` (publishes documentation)

## Architecture

### Module Hierarchy

```
tt_um_SophusAndreassen_dogbattle (project.v)
└── dogbattle_top_v8 (dogbattle_top_v8.v)
    ├── vga_timing (vga_timing.v)
    └── game_core_v8 (game_core_v8.v)
```

### Key Modules

1. **project.v** - Tiny Tapeout wrapper
   - Maps Tiny Tapeout I/O pins to VGA signals
   - Top module for ASIC submission
   - Pin mapping follows Tiny Tapeout VGA PMOD spec

2. **dogbattle_top_v8.v** - Game top level
   - Clock divider: 50 MHz → 25 MHz pixel clock
   - Instantiates VGA timing generator and game core
   - **Procedural dog rendering**: Each dog rendered with body, head, legs, ears, eyes, and tail (see DOG_RENDERING.md)
   - Dogs include outline shading and black eyes for visual depth
   - Configurable N dogs (currently 4 active, supports up to 4)

3. **game_core_v8.v** - Physics engine
   - Dog position and velocity management
   - Friction simulation (98% velocity retention per frame)
   - Wall collision detection and elastic bouncing
   - Updates at 60 FPS (triggered by `frame_tick`)
   - Currently implements 1 active dog with simplified physics

4. **vga_timing.v** - VGA signal generator
   - Generates hsync, vsync, active region
   - Outputs pixel coordinates (x, y)
   - Frame tick signal for game updates

### Data Flow

```
50 MHz clk → Clock Divider (/2) → 25 MHz pixel clock
                                 ↓
                            VGA Timing Generator
                                 ↓
                            frame_tick (60 Hz)
                                 ↓
                            Game Core (physics)
                                 ↓
                      Dog positions/velocities
                                 ↓
                            Pixel Renderer
                                 ↓
                         VGA RGB + sync outputs
```

### Physics Implementation

The game core uses **fixed-point arithmetic** for smooth animation:
- Velocities stored as signed 10-bit values with 8-bit fractional part
- Position updates: `pos = pos + (vel >>> 8)` (arithmetic right shift)
- Friction: `vel = (vel * 251) >>> 8` (~98% retention)
- Collision: `vel = -(vel >>> 1)` (50% energy loss on wall bounce)

### Pin Configuration

Outputs mapped to Tiny Tapeout VGA PMOD (uo_out[7:0]):
```
uo[7] = hsync
uo[6] = B[0]
uo[5] = G[0]
uo[4] = R[0]
uo[3] = vsync
uo[2] = B[1]
uo[1] = G[1]
uo[0] = R[1]
```

No inputs currently used (game runs autonomously).

## Working Reference Example

**Location:** `/home/jakobsen/work/asic/workspace/tt10/tt-vga-sjsu-bouncing`

This is a proven-working Tiny Tapeout VGA project used as a reference when debugging issues. Key differences from the current project:

### Reference Implementation Details

1. **Clock Input:** 25.175 MHz directly (no clock division required)
   - Specified in info.yaml as `clock_hz: 25175000`
   - Runs VGA timing generator directly on input clock

2. **VGA Timing Generator:** Uses `hvsync_generator.v`
   - Standard 640x480 timing with counters `hpos`, `vpos`
   - Active-low sync signals (inverted internally)
   - Simple, proven implementation

3. **Frame Updates:** Uses `x == 0 && y == 0` condition
   - Position updates in bouncing animation at frame boundaries
   - Frame counter increments at same condition

4. **Pin Mapping:** Identical TinyVGA PMOD layout
   - `{hsync, B[0], G[0], R[0], vsync, B[1], G[1], R[1]}`
   - Both projects use this standard mapping

### Comparison with Dog Battle Project

| Aspect | Reference (SJSU) | Dog Battle (This Project) |
|--------|------------------|---------------------------|
| Clock Input | 25.175 MHz | 50 MHz |
| Clock Division | None | Div-by-2 to 25 MHz |
| VGA Timing | hvsync_generator.v | vga_timing.v |
| Complexity | Bitmap + patterns | Physics engine + rendering |
| Frame Sync | x==0 && y==0 | frame_tick pulse |
| Animation | Simple velocity | Fixed-point physics |

### When to Use the Reference

Consult the reference project when:
- Debugging VGA timing issues (check against hvsync_generator.v)
- Verifying pin mappings (both use same PMOD layout)
- Testing if clock division is causing problems
- Comparing frame update logic
- Validating synthesis results

The reference's CLAUDE.md and source provide proven patterns for VGA generation on Tiny Tapeout.

## Important Files

### Configuration
- **info.yaml** - Tiny Tapeout project metadata and pin assignments
  - Update `source_files` when adding/removing Verilog files
  - Keep `PROJECT_SOURCES` in `test/Makefile` synchronized
  - Clock set to 50 MHz (unlike reference's 25.175 MHz)

### Source Files (src/)
- All source files listed in `info.yaml` must exist in `src/`
- Current sources: project.v, dogbattle_top_v8.v, game_core_v8.v, vga_timing.v

### Test Files (test/)
- **test.py** - Cocotb testbench
- **tb.v** - Verilog testbench wrapper
- **Makefile** - Test build configuration

### FPGA Files (fpga_test/)
- Platform for testing on Tang Nano 9K with HDMI output
- Includes PLLs, HDMI encoder, pin constraints
- Design files remain unchanged; wrapper adds clock generation and HDMI

## Development Notes

### Modifying the Game

To change physics or add features:
1. Edit `src/game_core_v8.v` or `src/dogbattle_top_v8.v`
2. Run RTL simulation: `cd test && make -B`
3. Optional: Test on FPGA: `cd fpga_test && make build load`
4. Commit changes

### Synchronization Requirements

When modifying source files:
1. Update `source_files` in `info.yaml`
2. Update `PROJECT_SOURCES` in `test/Makefile`
3. Both must list the same files in the same order

### Fixed-Point Math Conventions

The codebase uses custom fixed-point representation:
- Velocity: Signed 10-bit with implicit 8-bit fractional part (8.8 format)
- To apply velocity: `pos = pos + (vel >>> 8)`
- Maintain this convention when adding physics calculations

### Synthesis Constraints

The design must fit in a **1x1 Tiny Tapeout tile** (~340x160 µm):
- Minimize logic complexity
- Avoid floating point operations
- Use fixed-point arithmetic
- Keep register count low
- Current implementation uses simplified 1-dog physics to meet area constraints

### VGA Timing

Standard 640x480 @ 60Hz:
- Pixel clock: 25 MHz
- Frame rate: 60 Hz (frame_tick signal)
- Active region: 640x480 pixels
- See `vga_timing.v` for complete timing parameters

## Current Implementation vs. Original Vision

### Working Now (v8 - Minimal)
- **game_core_v8.v**: 1 active dog with basic physics
- Successfully demonstrates the core rendering pipeline
- Friction and boundary collision working
- Sprite stops at right edge as expected

### Original Design Goals
The docs/info.md describes the full vision:
- 4 dogs with independent physics
- Inter-dog collision detection
- Hit counters tracking collisions
- Elastic collisions with momentum conservation
- All dogs bouncing continuously

### Evolution Path
To expand from current minimal demo to full game:

1. **Enable all 4 dogs** - Currently dogs 1-3 are at position (0,0) with zero velocity
   - Set initial positions spread across screen
   - Set non-zero initial velocities for each

2. **Fix boundary bouncing** - Current implementation halves velocity and stops
   - Should negate velocity: `velx <= -velx` (not `-(velx >>> 1)`)
   - Maintain energy for continuous bouncing

3. **Add dog-to-dog collision detection** - Currently only wall collisions
   - Check distance between all dog pairs
   - Implement elastic collision response
   - Update hit counters

4. **Tune friction** - Current 98% may be too aggressive
   - Consider reducing to preserve more energy
   - Or remove entirely for perpetual motion

The minimal working demo validates the architecture. Expanding to full physics is incremental.

## Testing Strategy

1. **Unit-level**: Test individual modules in simulation
2. **RTL simulation**: Verify game logic and VGA output timing
3. **FPGA verification**: Visual confirmation on real hardware with HDMI
4. **Gate-level simulation**: Post-synthesis functional verification
5. **GDS workflow**: Automated via GitHub Actions

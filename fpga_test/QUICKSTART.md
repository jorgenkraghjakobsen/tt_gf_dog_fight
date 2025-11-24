# Quick Start Guide

## 1. Connect Hardware

1. Connect Tang Nano 9K to computer via USB
2. Connect HDMI cable from Tang Nano 9K to monitor
3. Power on the board

## 2. Build

```bash
cd fpga_test
make build
```

Expected output:
```
==> Generating Yosys command script...
==> Synthesizing with Yosys...
    Synthesis complete: obj/dogbattle_fpga.json
==> Place and Route with nextpnr-himbaechel...
    PnR complete: obj/dogbattle_fpga_pnr.json
==> Packing bitstream...
    Bitstream ready: obj/dogbattle_fpga.fs
```

Build time: ~30-60 seconds

## 3. Load to FPGA

```bash
make load
```

This loads to SRAM (temporary, fast for testing).

**OR** for persistent flash:

```bash
make flash
```

## 4. View Output

Your HDMI monitor should now show:
- **4 colored boxes** (dogs) bouncing around the screen
- Boxes collide and interact with each other
- **Red bars** above each box show hit counters
- Animated background gradient

## 5. Debug

- **LED0** (onboard) - Should be **ON** when PLLs are locked
  - If OFF or blinking: PLL not locked (check build)

- **No HDMI signal?**
  - Try different HDMI cable
  - Try different monitor/TV
  - Check LED0 is ON
  - Monitor must support 640x480@60Hz

## 6. Modify and Test

Edit your TinyTapeout design:
```bash
cd ../src
# Edit game_core_v8.v or dogbattle_top_v8.v
cd ../fpga_test
make clean
make build
make load
```

Changes appear immediately on the monitor!

## Common Issues

**Error: Cannot find /dev/ttyUSB1**
- Check connection: `ls /dev/ttyUSB*`
- Edit Makefile, change `USB_DEVICE` to match your device

**Synthesis errors**
- Run `make test` to verify all source files exist
- Check that `../src/` contains your TinyTapeout design files

**Build takes forever**
- First build is slow, subsequent builds are faster
- Use `make synth` to test synthesis only (faster)

## Build Targets Summary

- `make build` - Full build (synth + pnr + pack)
- `make load` - Quick load to SRAM (lost on power cycle)
- `make flash` - Write to flash (persistent)
- `make clean` - Clean build artifacts
- `make test` - Verify configuration

## Next Steps

- Tweak game parameters in `../src/game_core_v8.v`
- Add more dogs (currently 4, supports up to 8)
- Modify collision behavior
- Change colors and box sizes
- Test and iterate rapidly!

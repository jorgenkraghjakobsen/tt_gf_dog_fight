# Makefile for Dog Battle FPGA Demo on Tang Nano 9K
# Uses open-source toolchain: Yosys + nextpnr-himbaechel + gowin_pack

BOARD 		= tangnano9k
FAMILY		= GW1N-9C
DEVICE		= GW1NR-LV9QN88PC6/I5

PROJ		= dogbattle_fpga
TOP_MODULE	= fpga_top

# Workspace and directory structure
MAKEFILE_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
WS		= $(abspath $(MAKEFILE_DIR)/..)
OBJ 		= $(MAKEFILE_DIR)/obj

SRC_DIR 	= $(MAKEFILE_DIR)/src
SRC_INC 	= $(SRC_DIR)

# FPGA-specific source files
FPGA_SRC_LIST = \
	fpga_top.v \
	hdmi_output.v \
	tmds_encoder.v \
	gowin_rpll_125_working.v \
	dogbattle_top_25mhz.v

# TinyTapeout design files (from ../src)
TT_SRC_DIR = $(WS)/src
TT_SRC_LIST = \
	game_core_v8.v \
	vga_timing.v

# Combine all source files
FPGA_SRC = $(addprefix $(SRC_DIR)/, $(FPGA_SRC_LIST))
TT_SRC = $(addprefix $(TT_SRC_DIR)/, $(TT_SRC_LIST))
SRC = $(FPGA_SRC) $(TT_SRC)

# Constraint file
CST_FILE = $(SRC_DIR)/$(BOARD).cst

# Output files
JSON = $(OBJ)/$(PROJ).json
PNR_JSON = $(OBJ)/$(PROJ)_pnr.json
BITSTREAM = $(OBJ)/$(PROJ).fs
YOSYS_CMD = $(OBJ)/yosys.cmd

# USB device for openFPGALoader (change if needed)
USB_DEVICE = /dev/ttyUSB1

.PHONY: all clean synth pnr pack load flash build help test src

all: build

# Create obj directory
$(OBJ):
	@mkdir -p $@

# Synthesis with Yosys (using command script for better control)
synth: $(JSON)

$(JSON): $(SRC) | $(OBJ)
	@echo "==> Generating Yosys command script..."
	@echo "#Yosys build script for Dog Battle FPGA Demo" > $(YOSYS_CMD)
	@echo "verilog_defaults -add -I $(SRC_INC)" >> $(YOSYS_CMD)
	@echo "read_verilog $(SRC)" >> $(YOSYS_CMD)
	@echo "synth_gowin -top $(TOP_MODULE) -json $(JSON)" >> $(YOSYS_CMD)
	@echo "==> Synthesizing with Yosys..."
	yosys -s $(YOSYS_CMD)
	@echo "    Synthesis complete: $(JSON)"

# Place and Route with nextpnr-himbaechel
pnr: $(PNR_JSON)

$(PNR_JSON): $(JSON) $(CST_FILE)
	@echo "==> Place and Route with nextpnr-himbaechel..."
	LD_LIBRARY_PATH=$(HOME)/.pyenv/versions/3.9.19/lib:$(LD_LIBRARY_PATH) \
	nextpnr-himbaechel --freq 25.0 --json $(JSON) --write $(PNR_JSON) \
		--device $(DEVICE) --vopt family=$(FAMILY) --vopt cst=$(CST_FILE)
	@echo "    PnR complete: $(PNR_JSON)"

# Pack bitstream
pack: $(BITSTREAM)

$(BITSTREAM): $(PNR_JSON)
	@echo "==> Packing bitstream..."
	PYTHONBREAKPOINT=0 gowin_pack -d $(FAMILY) -o $(BITSTREAM) $(PNR_JSON)
	@echo "    Bitstream ready: $(BITSTREAM)"

# Complete build process
build: $(BITSTREAM)

# Load bitstream to SRAM (temporary, lost on power cycle)
load: $(BITSTREAM)
	@echo "==> Loading bitstream to FPGA SRAM..."
	openFPGALoader -d $(USB_DEVICE) -b $(BOARD) $(BITSTREAM)

# Flash bitstream to FLASH (persistent)
flash: $(BITSTREAM)
	@echo "==> Flashing bitstream to FPGA FLASH..."
	openFPGALoader -d $(USB_DEVICE) -b $(BOARD) -f $(BITSTREAM)

# Clean build artifacts
clean:
	@echo "==> Cleaning build artifacts..."
	rm -rf $(OBJ)

# Test target - show source files and configuration
test:
	@echo "Project: $(PROJ)"
	@echo "Top module: $(TOP_MODULE)"
	@echo "Device: $(DEVICE)"
	@echo "Family: $(FAMILY)"
	@echo "Board: $(BOARD)"
	@echo ""
	@echo "FPGA Source files:"
	@for src in $(FPGA_SRC); do echo "  $$src"; done
	@echo ""
	@echo "TinyTapeout Source files:"
	@for src in $(TT_SRC); do echo "  $$src"; done
	@echo ""
	@echo "Constraint file: $(CST_FILE)"
	@echo "USB Device: $(USB_DEVICE)"

# Show source files
src:
	@echo "All Source files:"
	@for src in $(SRC); do echo "  $$src"; done

# Help
help:
	@echo "Dog Battle FPGA Demo - Tang Nano 9K Build System"
	@echo "Tests TinyTapeout dogbattle_top_v8 design on real hardware"
	@echo ""
	@echo "Targets:"
	@echo "  all      - Build complete bitstream (default, same as 'build')"
	@echo "  build    - Complete build: synth + pnr + pack"
	@echo "  synth    - Run synthesis only (Yosys)"
	@echo "  pnr      - Run place and route (nextpnr-himbaechel)"
	@echo "  pack     - Pack bitstream (gowin_pack)"
	@echo "  load     - Load bitstream to SRAM (temporary, lost on power cycle)"
	@echo "  flash    - Flash bitstream to FLASH (persistent)"
	@echo "  clean    - Remove build artifacts"
	@echo "  test     - Show configuration and source files"
	@echo "  src      - List source files"
	@echo "  help     - Show this help"
	@echo ""
	@echo "Requirements:"
	@echo "  - yosys"
	@echo "  - nextpnr-himbaechel (or nextpnr-gowin)"
	@echo "  - gowin_pack"
	@echo "  - openFPGALoader"
	@echo ""
	@echo "Configuration:"
	@echo "  USB_DEVICE = $(USB_DEVICE) (change if needed)"
	@echo "  Game runs at 50 MHz, VGA outputs at 25 MHz"

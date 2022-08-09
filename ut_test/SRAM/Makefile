BUILD_DIR = build
TARGET := ${BUILD_DIR}/sram.out
WAVE := ${BUILD_DIR}/sram.vcd	#config in tb.sv

com:
	iverilog -g2005-sv sram_tb.sv sram.sv S011HD1P_X32Y2D128_BW.sv -o ${TARGET}

run:com
	vvp ${TARGET}

wave:com run
	gtkwave ${WAVE}
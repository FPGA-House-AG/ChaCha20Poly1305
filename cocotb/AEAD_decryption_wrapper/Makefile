# Copyright 2020, The Regents of the University of California.
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
#    1. Redistributions of source code must retain the above copyright notice,
#       this list of conditions and the following disclaimer.
#
#    2. Redistributions in binary form must reproduce the above copyright notice,
#       this list of conditions and the following disclaimer in the documentation
#       and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE REGENTS OF THE UNIVERSITY OF CALIFORNIA ''AS
# IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE REGENTS OF THE UNIVERSITY OF CALIFORNIA OR
# CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
# EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT
# OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING
# IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY
# OF SUCH DAMAGE.
#
# The views and conclusions contained in the software and documentation are those
# of the authors and should not be interpreted as representing official policies,
# either expressed or implied, of The Regents of the University of California.

TOPLEVEL_LANG ?= vhdl
SIM ?= ghdl
WAVES ?= 1

COCOTB_HDL_TIMEUNIT = 1ns
COCOTB_HDL_TIMEPRECISION = 1ps

DUT      = AEAD_decryption_wrapper
TOPLEVEL = $(DUT)
MODULE   = test_$(DUT)
DUTDIR   = ../../src

ifeq ($(TOPLEVEL_LANG), verilog)
VERILOG_SOURCES += $(DUTDIR)/$(DUT).v
else ifeq ($(TOPLEVEL_LANG), vhdl)
#VHDL_SOURCES += $(DUTDIR)/$(DUT).vhd
#VHDL_SOURCES += $(DUTDIR)/AEAD_ChaCha_Poly.vhd
#VHDL_SOURCES += $(DUTDIR)/AEAD_decryption.vhd
#VHDL_SOURCES += $(DUTDIR)/AEAD_decryption_top.vhd
VHDL_SOURCES += $(DUTDIR)/*.vhd

TOPLEVEL = $(shell echo $(DUT) | tr A-Z a-z)
endif

# module parameters
export PARAM_DATA_WIDTH ?= 32
export PARAM_KEEP_WIDTH ?= $(shell expr $(PARAM_DATA_WIDTH) / 8 )

ifeq ($(TOPLEVEL_LANG), verilog)
	ifeq ($(SIM), icarus)
		PLUSARGS += -fst

		COMPILE_ARGS += -P $(TOPLEVEL).DATA_WIDTH=$(PARAM_DATA_WIDTH)
		COMPILE_ARGS += -P $(TOPLEVEL).KEEP_WIDTH=$(PARAM_KEEP_WIDTH)

		ifeq ($(WAVES), 1)
			VERILOG_SOURCES += iverilog_dump.v
			COMPILE_ARGS += -s iverilog_dump
		endif
	else ifeq ($(SIM), verilator)
		COMPILE_ARGS += -Wno-SELRANGE -Wno-WIDTH

		COMPILE_ARGS += -GDATA_WIDTH=$(PARAM_DATA_WIDTH)
		COMPILE_ARGS += -GKEEP_WIDTH=$(PARAM_KEEP_WIDTH)

		ifeq ($(WAVES), 1)
			COMPILE_ARGS += --trace-fst
		endif
	endif
else ifeq ($(TOPLEVEL_LANG), vhdl)
    # ifneq ($(filter $(SIM),ghdl questa modelsim riviera activehdl),)
    #     # ghdl, questa, and aldec all use SIM_ARGS with '-g' for setting generics
    #     SIM_ARGS += -gDATA_WIDTH=$(DATA_WIDTH) -gA_ROWS=$(A_ROWS) -gB_COLUMNS=$(B_COLUMNS) -gA_COLUMNS_B_ROWS=$(A_COLUMNS_B_ROWS)
    # else ifneq ($(filter $(SIM),ius xcelium),)
    #     SIM_ARGS += -generic "matrix_multiplier:DATA_WIDTH=>$(DATA_WIDTH)" -generic "matrix_multiplier:A_ROWS=>$(A_ROWS)" -generic "matrix_multiplier:B_COLUMNS=>$(B_COLUMNS)" -generic "matrix_multiplier:A_COLUMNS_B_ROWS=>$(A_COLUMNS_B_ROWS)"
    # endif

    ifeq ($(SIM), ghdl)
        EXTRA_ARGS += --std=08
        SIM_ARGS += --backtrace-severity=warning --assert-level=none --ieee-asserts=disable

		ifeq ($(WAVES), 1)
			#SIM_ARGS += --wave=wave.ghw
			# faster:
			SIM_ARGS += --fst=wave.fst
		endif

    else ifneq ($(filter $(SIM),questa modelsim riviera activehdl),)
        COMPILE_ARGS += -2008
    endif
else
    $(error A valid value (verilog or vhdl) was not provided for TOPLEVEL_LANG=$(TOPLEVEL_LANG))
endif

include $(shell cocotb-config --makefiles)/Makefile.sim

iverilog_dump.v:
	echo 'module iverilog_dump();' > $@
	echo 'initial begin' >> $@
	echo '    $$dumpfile("$(TOPLEVEL).fst");' >> $@
	echo '    $$dumpvars(0, $(TOPLEVEL));' >> $@
	echo 'end' >> $@
	echo 'endmodule' >> $@

clean::
	@rm -rf iverilog_dump.v
	@rm -rf dump.fst $(TOPLEVEL).fst
	@rm -rf __pycache__
	@rm -rf results.xml

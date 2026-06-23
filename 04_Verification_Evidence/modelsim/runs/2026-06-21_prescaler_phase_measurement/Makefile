# Makefile — Icarus Verilog reproducible recipe (free-tool path)
# Layer 4 white-box evidence: prescaler_phase_measurement (Hook A / A2)
#
# `make phase` reproduces the Hook A phase measurement (idiom A) and the VCD.
# `make duty`  reproduces the 4-idiom duty table (A/B/C/D).
# Adjust CORE/IMEM paths to your checkout.

CORE  ?= ../../../../03_Sample_Implementations/ptsg_core_verilog/ptsg_core.v
IMEM  ?= ../../../../03_Sample_Implementations/ai_friendly_vendor_wrappers/ptsg_imem.v
SUITE ?= ../../../conformance_suite/prescaler_phase_measurement
IV     = iverilog -g2012

.PHONY: phase duty clean
phase:
	$(IV) -o sim_phase tb_prescaler_phase.v $(CORE) $(IMEM)
	cp $(SUITE)/program_A.hex program.hex
	vvp sim_phase            # [ENTRY]/[1stTICK]/[EDGE] per window; writes waveform.vcd

duty:
	$(IV) -DPROGFILE='"$(SUITE)/program_A.hex"' -DVCDFILE='"wave_A.vcd"' -o sim_A tb_duty.v $(CORE) $(IMEM); vvp sim_A
	$(IV) -DPROGFILE='"$(SUITE)/program_B.hex"' -DVCDFILE='"wave_B.vcd"' -o sim_B tb_duty.v $(CORE) $(IMEM); vvp sim_B
	$(IV) -DPROGFILE='"$(SUITE)/program_C.hex"' -DVCDFILE='"wave_C.vcd"' -o sim_C tb_duty.v $(CORE) $(IMEM); vvp sim_C
	$(IV) -DPROGFILE='"$(SUITE)/program_D.hex"' -DVCDFILE='"wave_D.vcd"' -o sim_D tb_duty.v $(CORE) $(IMEM); vvp sim_D

clean:
	rm -f sim_phase sim_A sim_B sim_C sim_D *.vcd program.hex

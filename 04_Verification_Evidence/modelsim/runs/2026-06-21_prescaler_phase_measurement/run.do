# ============================================================================
#  run.do — ModelSim reproducible recipe / ModelSim 再現レシピ
#  Layer 4 white-box evidence: prescaler_phase_measurement (Hook A / A2)
# ----------------------------------------------------------------------------
#  This is the PRIMARY artifact of a ModelSim run (per Layer 4 capacity policy):
#  the VCD is regenerated on demand from this recipe and the Core sources, and
#  is not normally committed (a small representative waveform.vcd.gz is kept).
#
#  本ファイルが ModelSim 実行の主成果物（Layer 4 容量ポリシー）。VCD は本レシピと
#  コアソースから随時再生成され、通常コミットしない（代表 waveform.vcd.gz のみ保持）。
#
#  Sources expected (adjust paths to your checkout):
#    ptsg_core.v   — RH001..RH008 reflected (DUT)
#    ptsg_imem.v   — v2 (VENDOR/EDGE/RD_LAT parameters)
#    tb_prescaler_phase.v — this directory (white-box phase TB, idiom A)
#    tb_duty.v            — this directory (4-idiom duty runner)
#    program_{A,B,C,D}.hex — ../../conformance_suite/prescaler_phase_measurement/
# ============================================================================

set CORE   "../../../../03_Sample_Implementations/ptsg_core_verilog/ptsg_core.v"
set IMEM   "../../../../03_Sample_Implementations/ai_friendly_vendor_wrappers/ptsg_imem.v"
set SUITE  "../../../conformance_suite/prescaler_phase_measurement"

vlib work
vlog -sv $CORE $IMEM tb_prescaler_phase.v tb_duty.v

# --- Hook A phase measurement (idiom A) -------------------------------------
# The TB defparams ptsg_imem to the SIM branch (VENDOR=SIM, EDGE=NEG, RD_LAT=1)
# and loads program.hex (idiom A). Run long enough for several blink periods.
vsim -c -do "run -all; quit -f" \
     -g/tb_prescaler_phase/PRESCALE=5 \
     tb_prescaler_phase
# -> prints [ENTRY]/[1stTICK]/[EDGE] per wait window; writes waveform.vcd

# --- 4-idiom duty sweep (A/B/C/D) -------------------------------------------
# Re-run tb_duty four times, one per program, to reproduce the duty table.
foreach tag {A B C D} {
    vsim -c -do "run -all; quit -f" \
         -gPROGFILE="$SUITE/program_$tag.hex" \
         -gVCDFILE="wave_$tag.vcd" \
         tb_duty
}

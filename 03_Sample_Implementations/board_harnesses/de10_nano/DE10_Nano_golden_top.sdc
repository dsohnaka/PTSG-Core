#**************************************************************
# DE10_Nano_golden_top.sdc -- PTSG-Core timing constraints
# (based on the Terasic-generated template; extended for 100 MHz
#  operation of the PTSG-Core, RH029)
#
# This one file serves BOTH harness tops:
#   * DE10_Nano_golden_top   -- ptsg_core on FPGA_CLK1_50 (50 MHz direct)
#   * DE10_Nano_ptsg100_top  -- ptsg_core on a PLL output (50 -> 100 MHz);
#     derive_pll_clocks below creates and constrains the 100 MHz clock
#     automatically from the altera_pll instance, so no explicit
#     create_generated_clock is needed here.
#
# ---- Why there is no special constraint for the imem path -----------
# The instruction memory (ptsg_imem, VENDOR="M10K", EDGE="NEG") is
# clocked on the FALLING edge of the core clock. TimeQuest therefore
# automatically analyzes two genuine half-period paths:
#     core regs (posedge) -> M10K address port (negedge)   : T/2
#     M10K q output (negedge) -> core regs (posedge)       : T/2
# At 100 MHz that is 5 ns each way, and this is the DESIGN'S EXPECTED
# CRITICAL PATH (see the harness README "Known state"). Do NOT relax it
# with set_multicycle_path: the FSM really does consume the fetched
# word on the very next rising edge -- the half-cycle budget is
# functional, not pessimism. If setup fails at 100 MHz on this device
# (5CSEBA6U23I7, -7 speed grade), the legitimate remedies are RTL-side
# (the EDGE="POS" + fetch-stage migration path described in the
# ptsg_imem README) or a faster speed grade -- not SDC waivers.
#**************************************************************

#**************************************************************
# Create Clock
#**************************************************************

create_clock -name {FPGA_CLK1_50} -period 20.000 [get_ports FPGA_CLK1_50]
create_clock -name {FPGA_CLK2_50} -period 20.000 [get_ports FPGA_CLK2_50]
create_clock -name {FPGA_CLK3_50} -period 20.000 [get_ports FPGA_CLK3_50]

# JTAG TCK (USB-Blaster II). Constrains the ISMCE program-swap port, the
# In-System Sources & Probes reset source, and SignalTap -- the whole
# zero-re-synthesis loop lives in this domain. 40 ns = 25 MHz (an upper
# bound for USB-Blaster II's 24 MHz maximum).
create_clock -name {altera_reserved_tck} -period 40.000 [get_ports altera_reserved_tck]

# --- Alternative for a board with a true external 100 MHz input ------
# On the DE10-nano the 100 MHz clock is PLL-generated (see above), so
# this stays commented. Porting to a board that FEEDS a 100 MHz pin
# directly: uncomment and rename the port, and remove the PLL from the
# top.
# create_clock -name {CLK_100} -period 10.000 [get_ports CLK_100]

#**************************************************************
# Create Generated Clock
#**************************************************************
derive_pll_clocks

#**************************************************************
# Set Clock Latency
#**************************************************************



#**************************************************************
# Set Clock Uncertainty
#**************************************************************
derive_clock_uncertainty

#**************************************************************
# Set Input Delay
#**************************************************************

set_input_delay -clock altera_reserved_tck -clock_fall 3.000 [get_ports altera_reserved_tdi]
set_input_delay -clock altera_reserved_tck -clock_fall 3.000 [get_ports altera_reserved_tms]

#**************************************************************
# Set Output Delay
#**************************************************************

set_output_delay -clock altera_reserved_tck 3.000 [get_ports altera_reserved_tdo]

#**************************************************************
# Set Clock Groups
#**************************************************************

# The JTAG domain (ISMCE writes into the M10K's second port, the
# Sources & Probes reset bit, SignalTap capture) is asynchronous to the
# system/PLL clocks. The reset crossing is additionally 2-FF
# synchronized in the 100 MHz top; ISMCE/SignalTap handshakes are
# handled inside the Intel megafunctions.
set_clock_groups -asynchronous -group [get_clocks {altera_reserved_tck}]

#**************************************************************
# Set False Path
#**************************************************************

# Human/static I/O: push-buttons, slide switches, LEDs. The PTSG
# timing_signals drive the LEDs -- observation only; on-chip timing of
# timing_signals is register-to-register and fully covered by the
# clock constraints above.
set_false_path -from [get_ports {KEY[*]}]
set_false_path -from [get_ports {SW[*]}]
set_false_path -to   [get_ports {LED[*]}]

#**************************************************************
# Set Multicycle Path
#**************************************************************

# (deliberately none -- see the header note on the imem half-cycle path)

#**************************************************************
# Set Maximum Delay
#**************************************************************



#**************************************************************
# Set Minimum Delay
#**************************************************************



#**************************************************************
# Set Input Transition
#**************************************************************



#**************************************************************
# Set Load
#**************************************************************

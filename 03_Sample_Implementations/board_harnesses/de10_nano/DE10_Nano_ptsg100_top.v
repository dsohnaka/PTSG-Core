// ============================================================================
//  DE10_Nano_ptsg100_top.v -- 100 MHz harness variant for the PTSG-Core
//  License: MIT (Layer 3 sample). Port list identical to the Terasic golden
//  top; only the PTSG wiring differs from DE10_Nano_golden_top.v:
//
//    * An on-chip PLL multiplies FPGA_CLK1_50 (50 MHz) to clk100 (100 MHz) --
//      the DE10-nano has no 100 MHz oscillator, so the PLL is the clock
//      source. derive_pll_clocks in the .sdc constrains clk100 automatically.
//    * ptsg_core runs entirely on clk100. The reset from the JTAG-driven
//      In-System Source (TCK domain) is 2-FF synchronized into clk100 and
//      held asserted until the PLL reports lock, so the core never runs on
//      an unstable clock.
//    * PRESCALE is doubled relative to the 50 MHz build. The PTSG time axis
//      is the TICK grid, not the raw clock: doubling the clock without
//      doubling PRESCALE would run every existing program twice as fast.
//      With PRESCALE also doubled, the tick period (and therefore every
//      Stay/duty/loop duration in wall-clock terms) is unchanged -- programs
//      written for the 50 MHz build behave identically here.
//
//  To use: set TOP_LEVEL_ENTITY to DE10_Nano_ptsg100_top in the .qsf (a
//  commented line is provided there). The shared .sdc covers both tops.
// ============================================================================

module DE10_Nano_ptsg100_top(

      ///////// ADC /////////
      output             ADC_CONVST,
      output             ADC_SCK,
      output             ADC_SDI,
      input              ADC_SDO,

      ///////// ARDUINO /////////
      inout       [15:0] ARDUINO_IO,
      inout              ARDUINO_RESET_N,

      ///////// FPGA /////////
      input              FPGA_CLK1_50,
      input              FPGA_CLK2_50,
      input              FPGA_CLK3_50,

      ///////// GPIO /////////
      inout       [35:0] GPIO_0,
      inout       [35:0] GPIO_1,

      ///////// HDMI /////////
      inout              HDMI_I2C_SCL,
      inout              HDMI_I2C_SDA,
      inout              HDMI_I2S,
      inout              HDMI_LRCLK,
      inout              HDMI_MCLK,
      inout              HDMI_SCLK,
      output             HDMI_TX_CLK,
      output      [23:0] HDMI_TX_D,
      output             HDMI_TX_DE,
      output             HDMI_TX_HS,
      input              HDMI_TX_INT,
      output             HDMI_TX_VS,

      ///////// KEY /////////
      input       [1:0]  KEY,

      ///////// LED /////////
      output      [7:0]  LED,

      ///////// SW /////////
      input       [3:0]  SW
);


//=======================================================
//  REG/WIRE declarations
//=======================================================

////////////////////////	PLL: 50 MHz -> 100 MHz	////////////////////
	wire			clk100;
	wire			pll_locked;

////////////////////////	ptsg_core	////////////////////
	wire	[15:0]	sig;
	wire			core_error;    // error_flag (C3-F24) -> JTAG probe below
	// 2-FF synchronizer: JTAG-source reset -> clk100. Power-up value 11:
	// the core is held in reset from configuration until the synchronizer
	// flushes AND the PLL locks, whichever is later.
	reg		[1:0]	rst_sync = 2'b11;
	wire			rst100;

////////////////////////	probe/source	////////////////////
	wire	[7:0]	probe;
	wire	[7:0]	sub;



//=======================================================
//  Structural coding
//=======================================================

	assign	LED[7:0] = sig[7:0];

	// JTAG probe payload (review PR#4): the LEDs already show sig[7:0], so
	// the probe carries what is otherwise invisible -- PLL lock and the
	// Core's runaway-error flag (C3-F24; doubles as a diagnostic trigger).
	assign	probe = {6'b0, core_error, pll_locked};



////////////////////////	PLL: 50 MHz -> 100 MHz	////////////////////
//  Direct altera_pll instantiation (Cyclone V), integer x2, direct mode --
//  the same primitive a generated IP wrapper contains. derive_pll_clocks in
//  the .sdc creates the 100 MHz generated clock from this automatically.

	altera_pll #(
		.fractional_vco_multiplier ("false"),
		.reference_clock_frequency ("50.0 MHz"),
		.operation_mode            ("direct"),
		.number_of_clocks          (1),
		.output_clock_frequency0   ("100.000000 MHz"),
		.phase_shift0              ("0 ps"),
		.duty_cycle0               (50),
		.pll_type                  ("General"),
		.pll_subtype               ("General")
	) pll_100 (
		.refclk   (FPGA_CLK1_50),
		.rst      (1'b0),
		.outclk   (clk100),
		.locked   (pll_locked),
		.fboutclk ( ),
		.fbclk    (1'b0)
	);



////////////////////////	reset conditioning	////////////////////
//  sub[0] comes from the In-System Sources & Probes instance (JTAG TCK
//  domain). At 100 MHz the crossing deserves a 2-FF synchronizer, and the
//  core is additionally held in reset until the PLL locks. ptsg_core's rst
//  is synchronous active-high (C5-V1/V3), so a synchronized level is all
//  that is required -- the JTAG UI holds it across many clocks anyway.

	always @(posedge clk100) begin
		rst_sync <= {rst_sync[0], sub[0]};
	end
	assign rst100 = rst_sync[1] | ~pll_locked;



////////////////////////	ptsg_core	////////////////////
//  PRESCALE 100000 = 2x the 50 MHz build's 50000: the tick period stays
//  1 ms, so every program written for the 50 MHz harness keeps its
//  wall-clock timing unchanged (the PTSG time axis is the tick grid).

//  Unused external buses are tied off explicitly (review PR#4): inputs are
//  driven to their inactive levels instead of left floating, so simulation
//  never propagates X into the FSM and the synthesis report stays clean.
//  ext_op_ready is tied HIGH ("external logic always ready" -- the neutral
//  level the testbenches use; the Core never stalls on it either way,
//  C3-T4). A Formation replaces these tie-offs with real connections.

	ptsg_core	#(
		.PRESCALE (100000)
	) ptsg_core1 (
		.clk            (clk100)	,      // System clock 100 MHz   (Sec.5.3)
		.rst            (rst100)	,      // Synchronous, active-high (Sec.5.3, C5-V1/V3)
		.condition      (1'b0)		,
		.timing_signals (sig)		,
		.ext_op_ready   (1'b1)		,
		.stack_rdata    (41'd0)		,
		.stack_ack      (1'b0)		,
		.insert_req     (1'b0)		,
		.insert_target  (12'd0)		,
		.indirect_data  (12'd0)		,
		.indirect_ready (1'b0)		,
		.error_flag     (core_error)       // C3-F24 flag -> JTAG probe

	);



////////////////////////	probe/source	////////////////////
	altsource_probe #(
	    .source_width             (8),          // Source (input) width
	    .probe_width              (8)           // Probe (output) width
	)
	probeIP
	(
		.probe 			(probe),
		.source 		(sub)

	);



////////////////////////////////////////////////////////////////


endmodule

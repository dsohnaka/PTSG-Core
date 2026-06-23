// ============================================================================
//  tb_prescaler_phase.v — Layer 4 conformance TB for Hook A (A2 hypothesis)
//  プリスケーラ位相測定 — Hook A / A2 仮説の白箱検証テストベンチ
// ----------------------------------------------------------------------------
//  Drives the RH008 ptsg_core with the 5-word blinky stimulus at PRESCALE=5,
//  VENDOR=SIM, EDGE=NEG, RD_LAT=1 (the silicon-equivalent memory contract).
//  Captures the signals expected.md asks for and writes a VCD. Additionally,
//  it instruments the S_RUN->S_WAIT entry to print, per wait window:
//    * the prescaler phase (presc_cnt) AT the entry clock
//    * the clock distance from entry to the first stay tick
//    * the measured high/low interval width
//  so the A2 prediction (phase-dependent 1..PRESCALE first-tick delay) can be
//  judged by value, not by eye.
//
//  NOTE on the DUT memory: ptsg_core instantiates ptsg_imem with defaults
//  (VENDOR="M10K"). Icarus has no altsyncram, so we defparam the instance to
//  the SIM branch and feed program.hex through INIT_FILE_HEX. The EDGE/RD_LAT
//  contract is preserved (NEG / 1), matching the silicon path.
// ============================================================================
`timescale 1ns/1ps
module tb_prescaler_phase;

    localparam integer PRESCALE = 5;

    reg clk = 1'b0;
    reg rst = 1'b1;
    reg condition = 1'b0;   // unused by this program (no Branch); held low

    // ---- core outputs we observe ------------------------------------------
    wire [11:0] state_number;
    wire [15:0] timing_signals;
    wire [11:0] stay_counter;
    wire        stay_cnt_match;
    wire [11:0] loop_counter;
    wire        loop_cnt_match;
    wire [31:0] prescaler_counter;
    wire        prescaler_match;

    // ---- unused core I/O (tie off) ----------------------------------------
    wire        ext_op_valid;
    wire [3:0]  ext_op_subopcode;
    wire [7:0]  ext_op_sub_operand;
    wire [15:0] ext_op_data;
    wire        stack_push_req, stack_pop_req;
    wire [36:0] stack_wdata;
    wire        insert_ack;
    wire        indirect_req;
    wire [1:0]  indirect_purpose;

    // ---- DUT ---------------------------------------------------------------
    ptsg_core #(
        .PRESCALE   (PRESCALE),
        .IMEM_DEPTH (256),
        .INIT_FILE  ("")        // we init the imem via the wrapper, not core's $readmemh
    ) dut (
        .clk(clk), .rst(rst), .condition(condition),
        .state_number(state_number),
        .timing_signals(timing_signals),
        .ext_op_valid(ext_op_valid),
        .ext_op_subopcode(ext_op_subopcode),
        .ext_op_sub_operand(ext_op_sub_operand),
        .ext_op_data(ext_op_data),
        .ext_op_ready(1'b0),
        .stack_push_req(stack_push_req),
        .stack_pop_req(stack_pop_req),
        .stack_wdata(stack_wdata),
        .stack_rdata(37'd0),
        .stack_ack(1'b0),
        .insert_req(1'b0),
        .insert_target(12'd0),
        .insert_ack(insert_ack),
        .loop_counter(loop_counter),
        .loop_cnt_match(loop_cnt_match),
        .stay_counter(stay_counter),
        .stay_cnt_match(stay_cnt_match),
        .prescaler_counter(prescaler_counter),
        .prescaler_match(prescaler_match),
        .indirect_req(indirect_req),
        .indirect_purpose(indirect_purpose),
        .indirect_data(12'd0),
        .indirect_ready(1'b0)
    );

    // ---- switch the core's imem instance to the SIM branch + load program --
    defparam dut.ptsg_imem.VENDOR        = "SIM";
    defparam dut.ptsg_imem.EDGE          = "NEG";
    defparam dut.ptsg_imem.RD_LAT        = 1;
    defparam dut.ptsg_imem.INIT_FILE_HEX = "program.hex";

    // ---- clock: 20 ns period (50 MHz, matching the board) -----------------
    always #10 clk = ~clk;

    // ---- reset release -----------------------------------------------------
    initial begin
        rst = 1'b1;
        repeat (4) @(posedge clk);
        @(negedge clk);
        rst = 1'b0;
    end

    // ---- VCD ---------------------------------------------------------------
    initial begin
        $dumpfile("waveform.vcd");
        $dumpvars(0, tb_prescaler_phase);
    end

    // ========================================================================
    //  Instrumentation: measure per-wait-window phase and first-tick delay
    // ========================================================================
    // Mirror the DUT's internal fsm and presc_cnt by hierarchical reference.
    // (White-box: Layer 4 ModelSim-style visibility.)
    wire [2:0]  fsm_w        = dut.fsm;
    wire [31:0] presc_cnt_w  = dut.presc_cnt;
    wire        presc_tick_w = dut.presc_tick;

    localparam [2:0] S_RUN = 3'd0, S_WAIT = 3'd1;

    reg [2:0]  fsm_prev;
    integer    clk_count;
    integer    entry_clk;
    integer    entry_phase;
    reg        awaiting_first_tick;
    integer    win_idx;

    // interval (high/low) width measurement via timing_signals[0]
    reg        ts0_prev;
    integer    last_edge_clk;

    initial begin
        fsm_prev            = S_RUN;
        clk_count           = 0;
        awaiting_first_tick = 1'b0;
        win_idx             = 0;
        ts0_prev            = 1'b0;
        last_edge_clk       = 0;
        entry_clk           = 0;
        entry_phase         = 0;
    end

    always @(posedge clk) begin
        if (!rst) begin
            clk_count = clk_count + 1;

            // ---- detect S_RUN -> S_WAIT entry --------------------------------
            if (fsm_prev != S_WAIT && fsm_w == S_WAIT) begin
                entry_clk           = clk_count;
                entry_phase         = presc_cnt_w;  // phase AT entry (the key value)
                awaiting_first_tick = 1'b1;
                win_idx             = win_idx + 1;
                $display("[ENTRY  ] win=%0d  clk=%0d  presc_cnt@entry=%0d  state=%0d",
                         win_idx, clk_count, presc_cnt_w, state_number);
            end

            // ---- first stay tick after entry --------------------------------
            // In S_WAIT the stay tick fires when presc_tick is high.
            if (awaiting_first_tick && fsm_w == S_WAIT && presc_tick_w) begin
                $display("[1stTICK] win=%0d  clk=%0d  delay_from_entry=%0d  (predict PRESCALE-phase=%0d)",
                         win_idx, clk_count, clk_count - entry_clk, PRESCALE - entry_phase);
                awaiting_first_tick = 1'b0;
            end

            // ---- high/low interval width via timing_signals[0] ---------------
            if (timing_signals[0] !== ts0_prev) begin
                $display("[EDGE   ] clk=%0d  timing_signals[0]: %b -> %b   width_of_prev_level=%0d clk",
                         clk_count, ts0_prev, timing_signals[0], clk_count - last_edge_clk);
                last_edge_clk = clk_count;
                ts0_prev      = timing_signals[0];
            end

            fsm_prev = fsm_w;
        end
    end

    // ---- run long enough for several blink periods, then stop -------------
    initial begin
        // 4 reset clocks + plenty for ~6 high/low half-periods at ~25 clk each
        repeat (4 + 400) @(posedge clk);
        $display("==== simulation end (clk_count=%0d) ====", clk_count);
        $finish;
    end

endmodule

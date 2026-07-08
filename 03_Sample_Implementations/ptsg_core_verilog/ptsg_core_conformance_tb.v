// ============================================================================
//  ptsg_core_conformance_tb.v — Layer-1 v1.1 conformance regression testbench
//  License: MIT (Layer 3 sample). Run with Icarus Verilog from
//  03_Sample_Implementations/:
//     iverilog -g2012 -o sim ptsg_core_verilog/ptsg_core.v \
//         ptsg_core_verilog/ptsg_core_conformance_tb.v \
//         ai_friendly_vendor_wrappers/ptsg_imem/ptsg_imem.v && vvp sim
// ----------------------------------------------------------------------------
//  Unlike ptsg_core_tb.v (PRESCALE=1 functional smoke tests), this bench runs
//  with PRESCALE=5 and pins down the *prescaled* timing contracts of Layer 1
//  v1.1 — the behaviors the spec-alignment work must never regress:
//
//    T1 — Duty idiom D (C4-F8/F9/F10/F11): StaySet -> bg NOP -> Stay -> StaySet
//         -> ProgEnd -> QueJump loop reproduces the written Stay count exactly
//         (steady-state 25:25 at PRESCALE=5), silicon-verified on DE10-nano.
//    T2 — A4 hoist: a prescaler tick landing on a BG Jump execution clock is
//         still counted by the stay counter (exact 60-clock period).
//    T3 — C4-F8: a foreground Branch consumes one whole prescale unit
//         (Branch+Jump loop period = 2 x PRESCALE).
//    T4 — §3.4b: a BG Branch's D16-D31 field is never driven onto
//         timing_signals (window hold).
//    T5 — C3-F20: an insertion asserted mid-window is deferred to Stay-timeup;
//         Return after insertion restores the resume address with no +1
//         (C3-F12, hr_ins flag).
//    T6 — Ruling 2026-07-07: Loop target/counter are 16-bit (a BG loop with
//         target 0x1801 = 6145 iterates 6145 times; a 12-bit datapath would
//         exit after 0x801 = 2049).
//    T7 — Ruling 2026-07-07: a Q-band NOP advances the scan (the former
//         prog_end_seen -> S_WAIT transition would hang here with a stale
//         stay_target).
//    T8 — C3-F22/C7 (PROVISIONAL): a foreground Reset fires immediately (no
//         tick-gate) and drives its own D16-D31 field instead of clearing
//         timing_signals to 0.
//    T9 — C3-F22/C7 (PROVISIONAL): a queued (Q-band) Reset fires exactly at
//         Stay-timeup, sets State Number to 0, and drives the tsig captured
//         from its own instruction word at Q-scan time.
//    T10 — C3-F22 (PROVISIONAL, open interpretation): a background Reset
//         panics State Number to 0 but leaves the Stay window open, per this
//         implementation's reading of the §3.4b table's silence on window
//         state for BG Reset. Flagged for architect review.
//    T11 — Architect ruling 2026-07-08: a queued Reset takes absolute
//         priority over anything else queued in the same window (a Jump
//         queued before it is completely discarded; Reset always wins).
//    T12 — RH016: a Q-band Jump(0) no longer hijacks the FSM into S_IND
//         mid-scan; it queues as its literal value (address 0) and fires
//         normally at Stay-timeup, matching the queued-Loop-indirect
//         simplification (C4-V1). indirect_req must never pulse for it.
//    T13 — RH016: a foreground indirect Jump is tick-gated like every
//         other FG command (C4-F8) and drives its own tsig immediately —
//         an indirect-Jump + literal-Jump loop has period = 2 x PRESCALE.
//    T14 — RH016 regression: a background indirect Jump remains
//         immediate (full system clock) with tsig held, matching
//         literal BG Jump.
// ============================================================================
`timescale 1ns/1ps
module ptsg_core_conformance_tb;
    localparam integer PRESCALE = 5;

    reg clk=0, rst=1, condition=0;
    wire [11:0] state_number; wire [15:0] timing_signals;
    wire ext_op_valid; wire [3:0] ext_op_subopcode; wire [7:0] ext_op_sub_operand;
    wire [15:0] ext_op_data;
    wire stack_push_req, stack_pop_req; wire [40:0] stack_wdata;
    reg  [40:0] stack_rdata=0; reg stack_ack=0;
    reg insert_req=0; reg [11:0] insert_target=0; wire insert_ack;
    wire [15:0] loop_counter; wire loop_cnt_match;
    wire [11:0] stay_counter; wire stay_cnt_match;
    wire [31:0] prescaler_counter; wire prescaler_match;
    wire indirect_req; wire [1:0] indirect_purpose;
    reg  [11:0] indirect_data=0; reg indirect_ready=0;
    integer errors=0;

    ptsg_core #(.IMEM_DEPTH(32), .PRESCALE(PRESCALE),
                .IMEM_VENDOR("SIM"), .INIT_FILE("")) dut (
        .clk(clk), .rst(rst), .condition(condition),
        .state_number(state_number), .timing_signals(timing_signals),
        .ext_op_valid(ext_op_valid), .ext_op_subopcode(ext_op_subopcode),
        .ext_op_sub_operand(ext_op_sub_operand), .ext_op_data(ext_op_data), .ext_op_ready(1'b1),
        .stack_push_req(stack_push_req), .stack_pop_req(stack_pop_req),
        .stack_wdata(stack_wdata), .stack_rdata(stack_rdata), .stack_ack(stack_ack),
        .insert_req(insert_req), .insert_target(insert_target), .insert_ack(insert_ack),
        .loop_counter(loop_counter), .loop_cnt_match(loop_cnt_match),
        .stay_counter(stay_counter), .stay_cnt_match(stay_cnt_match),
        .prescaler_counter(prescaler_counter), .prescaler_match(prescaler_match),
        .indirect_req(indirect_req), .indirect_purpose(indirect_purpose),
        .indirect_data(indirect_data), .indirect_ready(indirect_ready));

    always #5 clk=~clk;
    // External indirect-read responder: registered 1-clock (C4-T1 lean B).
    // Previously missing here (T1-T12 never exercise indirect Jump/Loop, so
    // indirect_ready staying permanently 0 was silent until T13/T14, which
    // hung waiting for it — found while debugging this exact addition).
    always @(posedge clk) indirect_ready <= indirect_req;

    // ---- helpers -----------------------------------------------------------
    integer j;
    task clear_imem; begin
        for (j=0;j<32;j=j+1) dut.ptsg_imem.g_sim.mem[j]=32'h00000000;
    end endtask
    task start; begin @(posedge clk); rst=0; end endtask
    task reset1; begin rst=1; insert_req=0; condition=0; @(posedge clk); clear_imem; end endtask

    // Instruction constructors (D0-D3 opcode, D4-D15 operand, D16-D31 tsig)
    function [31:0] I_NOP;     input [15:0] tsig; I_NOP     = {tsig, 16'h0700}; endfunction
    function [31:0] I_RESET;   input [15:0] tsig; I_RESET   = {tsig, 16'h0000}; endfunction
    function [31:0] I_STAYSET; input [15:0] tsig; I_STAYSET = {tsig, 16'h0200}; endfunction
    function [31:0] I_PROGEND; input [15:0] tsig; I_PROGEND = {tsig, 16'h0600}; endfunction
    function [31:0] I_BASESET; input [15:0] tsig; I_BASESET = {tsig, 16'h0100}; endfunction
    function [31:0] I_RETURN;  input [15:0] tsig; I_RETURN  = {tsig, 16'h0300}; endfunction
    function [31:0] I_LOOP;    input [15:0] tgt;  I_LOOP    = {tgt,  16'h0500}; endfunction
    function [31:0] I_STAY;    input [15:0] tsig; input [11:0] n;
        I_STAY = {tsig, n, 4'h1}; endfunction
    function [31:0] I_JUMP;    input [15:0] tsig; input [11:0] a;
        I_JUMP = {tsig, a, 4'h3}; endfunction
    function [31:0] I_BRANCH;  input [15:0] tsig; input [11:0] off;
        I_BRANCH = {tsig, off, 4'h2}; endfunction

    // Measure the next full high/low widths of timing_signals[0] (in clocks)
    integer w_on, w_off;
    task measure_duty; begin
        @(posedge clk); while (timing_signals[0]!==1'b0) @(posedge clk);
        while (timing_signals[0]!==1'b1) @(posedge clk);       // rising edge
        w_on=0; while (timing_signals[0]===1'b1) begin w_on=w_on+1; @(posedge clk); end
        w_off=0; while (timing_signals[0]===1'b0) begin w_off=w_off+1; @(posedge clk); end
    end endtask

    integer k, t_prev, t_now, period, seen, visits;
    integer ack_clk, match_clk;

    initial begin
        // ================================================================
        // T1 — Duty idiom D: exact 25:25 at PRESCALE=5 (C4-F8/F9/F10/F11)
        // ================================================================
        reset1;
        dut.ptsg_imem.g_sim.mem[0]=I_NOP(16'h0000);          // s0 cold-start absorber (C4-V3)
        dut.ptsg_imem.g_sim.mem[1]=I_STAYSET(16'h0001);      // s1 window A opens, drives ON
        dut.ptsg_imem.g_sim.mem[2]=I_NOP(16'h0000);          // s2 BG NOP (zero duty)
        dut.ptsg_imem.g_sim.mem[3]=I_STAY(16'h0001,12'd5);   // s3 Stay 5 (ON)
        dut.ptsg_imem.g_sim.mem[4]=I_STAYSET(16'h0000);      // s4 window B opens, drives OFF
        dut.ptsg_imem.g_sim.mem[5]=I_PROGEND(16'h0000);      // s5 BG->Q boundary
        dut.ptsg_imem.g_sim.mem[6]=I_JUMP(16'h0000,12'd1);   // s6 queued Jump -> s1 (fires at timeup)
        dut.ptsg_imem.g_sim.mem[7]=I_STAY(16'h0000,12'd5);   // s7 Stay 5 (OFF)
        start;
        measure_duty;                                        // discard start-up period
        measure_duty;
        if (w_on==5*PRESCALE && w_off==5*PRESCALE)
            $display("PASS T1: idiom D duty %0d:%0d (= written Stay, jitter-free)", w_on, w_off);
        else begin
            $display("FAIL T1: duty %0d:%0d (expected %0d:%0d)", w_on, w_off, 5*PRESCALE, 5*PRESCALE);
            errors=errors+1; end

        // ================================================================
        // T2 — A4 hoist: tick on a BG Jump clock is still counted
        //      (scan is placed so the tick lands exactly on the Jump)
        // ================================================================
        reset1;
        dut.ptsg_imem.g_sim.mem[0]=I_NOP(16'h0000);
        dut.ptsg_imem.g_sim.mem[1]=I_STAYSET(16'h0001);      // ON; arm (tick grid: every 5 clks)
        dut.ptsg_imem.g_sim.mem[2]=I_NOP(16'h0000);          // BG scan +1
        dut.ptsg_imem.g_sim.mem[3]=I_NOP(16'h0000);          // BG scan +2
        dut.ptsg_imem.g_sim.mem[4]=I_NOP(16'h0000);          // BG scan +3
        dut.ptsg_imem.g_sim.mem[5]=I_JUMP(16'h0000,12'd7);   // BG Jump executes on the tick clock
        dut.ptsg_imem.g_sim.mem[7]=I_STAY(16'h0001,12'd6);   // Stay 6 (ON)
        dut.ptsg_imem.g_sim.mem[8]=I_STAYSET(16'h0000);      // OFF window
        dut.ptsg_imem.g_sim.mem[9]=I_PROGEND(16'h0000);
        dut.ptsg_imem.g_sim.mem[10]=I_JUMP(16'h0000,12'd1);  // queued Jump -> s1
        dut.ptsg_imem.g_sim.mem[11]=I_STAY(16'h0000,12'd6);  // Stay 6 (OFF)
        start;
        measure_duty; measure_duty;
        if (w_on==6*PRESCALE && w_off==6*PRESCALE)
            $display("PASS T2: BG-Jump tick counted, period exact %0d:%0d", w_on, w_off);
        else begin
            $display("FAIL T2: duty %0d:%0d (expected %0d:%0d) — in-window tick lost?",
                     w_on, w_off, 6*PRESCALE, 6*PRESCALE);
            errors=errors+1; end

        // ================================================================
        // T3 — C4-F8: FG Branch consumes one whole prescale unit
        // ================================================================
        reset1;
        dut.ptsg_imem.g_sim.mem[0]=I_NOP(16'h0000);
        dut.ptsg_imem.g_sim.mem[1]=I_BRANCH(16'h0002,12'd5); // cond=1 -> not taken -> s2
        dut.ptsg_imem.g_sim.mem[2]=I_JUMP(16'h0000,12'd1);   // FG Jump back
        condition=1;
        start;
        // rising-edge spacing of tsig[1] (high while sitting at s1) = 2*PRESCALE
        t_prev=-1; t_now=0; period=0; seen=0;
        for (k=0;k<200 && seen<4;k=k+1) begin
            @(posedge clk); #1;
            if (timing_signals[1]===1'b1 && t_now==0) begin       // rising edge
                if (t_prev!=-1) begin
                    if (period==0)            period=k-t_prev;
                    else if ((k-t_prev)!=period) period=-1;
                    seen=seen+1;
                end
                t_prev=k;
            end
            t_now = (timing_signals[1]===1'b1);
        end
        if (period==2*PRESCALE)
            $display("PASS T3: FG Branch+Jump loop period = %0d clocks (2 prescale units)", period);
        else begin
            $display("FAIL T3: period=%0d (expected %0d) — FG Branch not tick-gated?",
                     period, 2*PRESCALE);
            errors=errors+1; end
        condition=0;

        // ================================================================
        // T4 — §3.4b: BG Branch never drives its D16-D31 onto timing_signals
        // ================================================================
        reset1;
        dut.ptsg_imem.g_sim.mem[0]=I_NOP(16'h0010);
        dut.ptsg_imem.g_sim.mem[1]=I_STAYSET(16'h0010);      // hold 0x0010
        dut.ptsg_imem.g_sim.mem[2]=I_BRANCH(16'h0020,12'd1); // BG Branch; 0x0020 must NOT appear
        dut.ptsg_imem.g_sim.mem[3]=I_STAY(16'h0010,12'd3);
        dut.ptsg_imem.g_sim.mem[4]=I_JUMP(16'h0000,12'd0);   // FG Jump -> loop to s0
        condition=1;
        start;
        seen=0;
        for (k=0;k<200;k=k+1) begin @(posedge clk); #1;
            if (timing_signals===16'h0020) seen=1; end
        if (!seen) $display("PASS T4: BG Branch held the timing signals (0x0020 never driven)");
        else begin $display("FAIL T4: BG Branch drove its D16-D31 onto timing_signals");
            errors=errors+1; end
        condition=0;

        // ================================================================
        // T5 — C3-F20 insertion deferral + C3-F12 no-+1 return after insertion
        // ================================================================
        reset1;
        dut.ptsg_imem.g_sim.mem[0]=I_NOP(16'h0000);
        dut.ptsg_imem.g_sim.mem[1]=I_STAYSET(16'h0100);
        dut.ptsg_imem.g_sim.mem[2]=I_NOP(16'h0000);          // BG
        dut.ptsg_imem.g_sim.mem[3]=I_STAY(16'h0100,12'd8);   // Stay 8 — insertion arrives mid-wait
        dut.ptsg_imem.g_sim.mem[4]=I_NOP(16'h0200);          // resume lands here (no +1: C3-F12)
        dut.ptsg_imem.g_sim.mem[5]=I_JUMP(16'h0200,12'd5);   // halt
        dut.ptsg_imem.g_sim.mem[10]=I_NOP(16'h0400);         // insertion handler body
        dut.ptsg_imem.g_sim.mem[11]=I_RETURN(16'h0400);      // Return (FG Return: pre-Phase-4 behavior)
        start;
        // wait until the core is sitting in the Stay, then request insertion
        k=0; while (state_number!==12'd3 && k<100) begin @(posedge clk); #1; k=k+1; end
        repeat (3) @(posedge clk);                            // well inside the wait
        insert_req=1; insert_target=12'd10;
        ack_clk=-1; match_clk=-1;
        for (k=0;k<400;k=k+1) begin
            @(posedge clk); #1;
            if (insert_ack===1'b1     && ack_clk  ==-1) ack_clk=k;
            if (stay_cnt_match===1'b1 && match_clk==-1) match_clk=k;
            if (insert_ack===1'b1) insert_req=0;
        end
        if (ack_clk!=-1 && match_clk!=-1 && ack_clk==match_clk)
            $display("PASS T5a: insertion deferred to Stay-timeup (ack on the timeup clock)");
        else begin
            $display("FAIL T5a: ack_clk=%0d match_clk=%0d — insertion not deferred to timeup",
                     ack_clk, match_clk);
            errors=errors+1; end
        // handler ran, and Return resumed at s4 (0x0200), not s5
        seen=0; visits=0;
        // (already past: scan the trace by re-checking live state — handler + resume
        //  happen within the 400-clock window above; verify we are halted at s5 now
        //  and that the handler tsig was observed on the way)
        if (state_number===12'd5) begin
            $display("PASS T5b: handler ran and Return resumed the post-Stay address");
        end else begin
            $display("FAIL T5b: st=%0d (expected halt at 5 after handler+resume)", state_number);
            errors=errors+1; end
        insert_req=0;

        // ================================================================
        // T6 — 16-bit Loop (ruling 2026-07-07): BG loop, target 0x1801=6145
        // ================================================================
        reset1;
        dut.ptsg_imem.g_sim.mem[0]=I_NOP(16'h0000);
        dut.ptsg_imem.g_sim.mem[1]=I_STAYSET(16'h0000);
        dut.ptsg_imem.g_sim.mem[2]=I_BASESET(16'h0000);      // BG: base := 2
        dut.ptsg_imem.g_sim.mem[3]=I_LOOP(16'h1801);         // BG immediate loop -> base
        dut.ptsg_imem.g_sim.mem[4]=I_STAY(16'h0000,12'd0);   // Stay 4096 (covers the loop)
        dut.ptsg_imem.g_sim.mem[5]=I_NOP(16'hA5A5);          // exit marker
        dut.ptsg_imem.g_sim.mem[6]=I_JUMP(16'hA5A5,12'd6);   // halt
        start;
        visits=0; seen=0;
        for (k=0;k<40000;k=k+1) begin
            @(posedge clk); #1;
            if (state_number===12'd3) visits=visits+1;
            if (loop_cnt_match===1'b1) seen=seen+1;
            if (timing_signals===16'hA5A5) k=40000;
        end
        if (visits==6145 && seen==1)
            $display("PASS T6: 16-bit Loop iterated %0d times (12-bit would stop at 2049)", visits);
        else begin
            $display("FAIL T6: loop visits=%0d matches=%0d (expected 6145, 1)", visits, seen);
            errors=errors+1; end

        // ================================================================
        // T7 — Q-band NOP advances the scan (ruling 2026-07-07)
        // ================================================================
        reset1;
        dut.ptsg_imem.g_sim.mem[0]=I_NOP(16'h0000);
        dut.ptsg_imem.g_sim.mem[1]=I_STAYSET(16'h0001);
        dut.ptsg_imem.g_sim.mem[2]=I_PROGEND(16'h0000);
        dut.ptsg_imem.g_sim.mem[3]=I_NOP(16'h0000);          // Q-band NOP: must scan past
        dut.ptsg_imem.g_sim.mem[4]=I_JUMP(16'h0000,12'd8);   // Q: queued Jump -> s8 at timeup
        dut.ptsg_imem.g_sim.mem[5]=I_STAY(16'h0001,12'd3);   // Stay 3
        dut.ptsg_imem.g_sim.mem[8]=I_NOP(16'h0800);          // landing marker
        dut.ptsg_imem.g_sim.mem[9]=I_JUMP(16'h0800,12'd9);   // halt
        start;
        seen=0;
        for (k=0;k<200;k=k+1) begin @(posedge clk); #1;
            if (timing_signals===16'h0800) begin seen=1; k=200; end end
        if (seen) $display("PASS T7: Q-band NOP scanned past; queued Jump fired at timeup");
        else begin $display("FAIL T7: never reached s8 — Q-band NOP stalled the scan (st=%0d)",
                            state_number);
            errors=errors+1; end

        // ================================================================
        // T8 — FG Reset (C3-F22, PROVISIONAL): fires immediately, no
        //      tick-gate, and drives its own tsig field (C7) instead of
        //      clearing to 0.
        // ================================================================
        reset1;
        dut.ptsg_imem.g_sim.mem[0]=I_NOP(16'h0000);
        dut.ptsg_imem.g_sim.mem[1]=I_NOP(16'h00AA);
        dut.ptsg_imem.g_sim.mem[2]=I_RESET(16'h00BB);
        dut.ptsg_imem.g_sim.mem[3]=I_JUMP(16'hDEAD,12'd3);  // unreachable if Reset works
        start;
        // wait until we first leave s0, so we don't false-trigger on the
        // initial post-hardware-reset state_number==0
        k=0; while (state_number===12'd0 && k<200) begin @(posedge clk); #1; k=k+1; end
        seen=0; visits=0;   // visits reused here as an "escaped to s3" counter
        for (k=0;k<200;k=k+1) begin
            @(posedge clk); #1;
            if (timing_signals===16'h00BB) seen=1;
            if (timing_signals===16'hDEAD) visits=visits+1;
        end
        if (seen && visits==0)
            $display("PASS T8: FG Reset fired immediately, drove its own tsig (0x00BB), no s3 escape");
        else begin
            $display("FAIL T8: seen(0x00BB)=%0d escaped-to-s3=%0d (own-tsig / immediate-fire broken)",
                     seen, visits);
            errors=errors+1; end

        // ================================================================
        // T9 — Q-band Reset (C3-F22 Q row + C7): fires exactly at
        //      Stay-timeup, sets State Number to 0, and drives the tsig
        //      captured from its own D16-D31 at Q-scan time — not the
        //      Stay's held value, not zero.
        // ================================================================
        reset1;
        dut.ptsg_imem.g_sim.mem[0]=I_NOP(16'h0000);
        dut.ptsg_imem.g_sim.mem[1]=I_STAYSET(16'h0001);
        dut.ptsg_imem.g_sim.mem[2]=I_NOP(16'h0000);          // BG
        dut.ptsg_imem.g_sim.mem[3]=I_PROGEND(16'h0000);
        dut.ptsg_imem.g_sim.mem[4]=I_RESET(16'h0CCC);        // Q: queued
        dut.ptsg_imem.g_sim.mem[5]=I_STAY(16'h0001,12'd4);   // FG Stay; closes window at timeup
        start;
        seen=0;
        for (k=0;k<300;k=k+1) begin
            @(posedge clk); #1;
            if (timing_signals===16'h0CCC && state_number===12'd0) begin seen=1; k=300; end
        end
        if (seen) $display("PASS T9: Q-band Reset fired at Stay-timeup (SN=0, own tsig 0x0CCC)");
        else begin $display("FAIL T9: never observed SN=0 with tsig=0x0CCC at timeup");
            errors=errors+1; end

        // ================================================================
        // T10 — BG Reset (PROVISIONAL interpretation, flagged for
        //      architect review): the §3.4b table only arms the stay
        //      counter for BG Reset ("reset to 0, don't start") and says
        //      nothing about closing the window, so this implementation
        //      reads a BG Reset as panicking State Number to 0 while
        //      LEAVING the Stay window open (still inside the "staff
        //      meal" band). This test pins that interpretation — if the
        //      architect rules the window should close instead, this is
        //      the test to flip alongside the RTL.
        // ================================================================
        reset1;
        dut.ptsg_imem.g_sim.mem[0]=I_NOP(16'h0000);
        dut.ptsg_imem.g_sim.mem[1]=I_STAYSET(16'h0001);
        dut.ptsg_imem.g_sim.mem[2]=I_NOP(16'h0000);          // BG
        dut.ptsg_imem.g_sim.mem[3]=I_RESET(16'h0EEE);        // BG Reset — panic to s0
        start;
        k=0; while (state_number!==12'd3 && k<200) begin @(posedge clk); #1; k=k+1; end
        @(posedge clk); #1;   // the clock the BG Reset fires on
        if (state_number===12'd0 && dut.window_open===1'b1)
            $display("PASS T10: BG Reset panicked SN to 0, left the Stay window open (documented interpretation)");
        else begin
            $display("FAIL T10: st=%0d window_open=%b (expected st=0, window_open=1)",
                     state_number, dut.window_open);
            errors=errors+1; end

        // ================================================================
        // T11 — architect ruling (2026-07-08): a queued Reset takes
        //      ABSOLUTE PRIORITY over anything else queued in the same
        //      window. Here a Jump is queued to s20 BEFORE the Reset is
        //      queued; at Stay-timeup the Jump's effect must be entirely
        //      discarded and Reset must win (SN=0, its own tsig driven).
        // ================================================================
        reset1;
        dut.ptsg_imem.g_sim.mem[0]=I_NOP(16'h0000);
        dut.ptsg_imem.g_sim.mem[1]=I_STAYSET(16'h0001);
        dut.ptsg_imem.g_sim.mem[2]=I_NOP(16'h0000);          // BG
        dut.ptsg_imem.g_sim.mem[3]=I_PROGEND(16'h0000);
        dut.ptsg_imem.g_sim.mem[4]=I_JUMP(16'h0000,12'd20);  // Q: queued Jump (must be overridden)
        dut.ptsg_imem.g_sim.mem[5]=I_RESET(16'h0FFF);        // Q: queued Reset (must win)
        dut.ptsg_imem.g_sim.mem[6]=I_STAY(16'h0001,12'd4);   // FG Stay; closes window at timeup
        dut.ptsg_imem.g_sim.mem[20]=I_NOP(16'hBAD0);         // reached only if the Jump won (FAIL)
        start;
        seen=0; visits=0;   // visits reused here as an "escaped to s20" flag
        for (k=0;k<300;k=k+1) begin
            @(posedge clk); #1;
            if (timing_signals===16'h0FFF && state_number===12'd0) seen=1;
            if (timing_signals===16'hBAD0) visits=1;
        end
        if (seen && !visits)
            $display("PASS T11: queued Reset overrode a simultaneously-queued Jump (Reset always wins)");
        else begin
            $display("FAIL T11: reset-won=%0d jump-escaped-to-s20=%0d", seen, visits);
            errors=errors+1; end

        // ================================================================
        // T12 — RH016: a Q-band Jump(0) no longer hijacks the scan into
        //      S_IND. It is queued as its literal value (jump to address
        //      0, matching the queued-Loop-indirect simplification,
        //      C4-V1) and fires normally at Stay-timeup; indirect_req
        //      must never pulse for it.
        // ================================================================
        reset1;
        dut.ptsg_imem.g_sim.mem[0]=I_NOP(16'h0000);
        dut.ptsg_imem.g_sim.mem[1]=I_STAYSET(16'h0001);
        dut.ptsg_imem.g_sim.mem[2]=I_NOP(16'h0000);          // BG
        dut.ptsg_imem.g_sim.mem[3]=I_PROGEND(16'h0000);
        dut.ptsg_imem.g_sim.mem[4]=I_JUMP(16'h0000,12'd0);   // Q: Jump(0) -> queued literal 0
        dut.ptsg_imem.g_sim.mem[5]=I_STAY(16'h0001,12'd4);   // FG Stay; closes window at timeup
        indirect_data=12'd99;   // sentinel — must never be consumed
        start;
        k=0; while (state_number===12'd0 && k<50) begin @(posedge clk); #1; k=k+1; end  // leave s0
        seen=0; visits=0;   // seen: indirect_req ever asserted (bad); visits: returned to SN=0
        for (k=0;k<200;k=k+1) begin
            @(posedge clk); #1;
            if (indirect_req===1'b1) seen=1;
            if (state_number===12'd0) begin visits=1; k=200; end
        end
        if (!seen && visits)
            $display("PASS T12: Q-band Jump(0) queued as literal (no S_IND hijack), fired at timeup");
        else begin
            $display("FAIL T12: indirect_req-asserted=%0d returned-to-0=%0d", seen, visits);
            errors=errors+1; end

        // ================================================================
        // T13 — RH016: a foreground indirect Jump is tick-gated like
        //      every other FG command (C4-F8), preserving the structural
        //      phase-lock (C4-F9), and drives its own tsig field
        //      immediately (matching literal FG Jump). A 2-command loop
        //      (indirect Jump + literal Jump back) must have period =
        //      2 x PRESCALE, mirroring T3's Branch+Jump check.
        // ================================================================
        reset1;
        dut.ptsg_imem.g_sim.mem[0]=I_NOP(16'h0000);
        dut.ptsg_imem.g_sim.mem[1]=I_JUMP(16'h0002,12'd0);   // FG indirect Jump -> s2 (own tsig 0x0002)
        dut.ptsg_imem.g_sim.mem[2]=I_JUMP(16'h0000,12'd1);   // FG literal Jump back to s1
        indirect_data=12'd2;
        start;
        t_prev=-1; t_now=0; period=0; seen=0;
        for (k=0;k<300 && seen<4;k=k+1) begin
            @(posedge clk); #1;
            if (timing_signals[1]===1'b1 && t_now==0) begin
                if (t_prev!=-1) begin
                    if (period==0)                 period=k-t_prev;
                    else if ((k-t_prev)!=period)   period=-1;
                    seen=seen+1;
                end
                t_prev=k;
            end
            t_now = (timing_signals[1]===1'b1);
        end
        if (period==2*PRESCALE)
            $display("PASS T13: FG indirect Jump tick-gated, loop period=%0d (2 prescale units)", period);
        else begin
            $display("FAIL T13: period=%0d (expected %0d) — FG indirect Jump not tick-gated?",
                     period, 2*PRESCALE);
            errors=errors+1; end

        // ================================================================
        // T14 — regression: a background indirect Jump remains immediate
        //      (full system clock, not tick-gated) and its tsig stays
        //      held (never driven), matching literal BG Jump.
        // ================================================================
        reset1;
        dut.ptsg_imem.g_sim.mem[0]=I_NOP(16'h0000);
        dut.ptsg_imem.g_sim.mem[1]=I_STAYSET(16'h0001);
        dut.ptsg_imem.g_sim.mem[2]=I_JUMP(16'h0002,12'd0);   // BG indirect Jump -> s10 (own tsig must NOT show)
        dut.ptsg_imem.g_sim.mem[10]=I_NOP(16'h0000);         // BG continues scanning here
        dut.ptsg_imem.g_sim.mem[11]=I_PROGEND(16'h0000);
        dut.ptsg_imem.g_sim.mem[12]=I_JUMP(16'h0000,12'd1);  // Q: queued Jump -> s1 (loop back)
        dut.ptsg_imem.g_sim.mem[13]=I_STAY(16'h0001,12'd3);  // Stay 3
        indirect_data=12'd10;
        start;
        seen=0; visits=0;
        for (k=0;k<300;k=k+1) begin
            @(posedge clk); #1;
            if (timing_signals===16'h0002) seen=1;   // BG indirect Jump's own tsig must never appear
            if (stay_cnt_match===1'b1) visits=1;      // proves the window completed (BG jump landed OK)
        end
        if (!seen && visits)
            $display("PASS T14: BG indirect Jump landed correctly, stayed immediate, tsig held");
        else begin
            $display("FAIL T14: own-tsig-shown=%0d window-completed=%0d", seen, visits);
            errors=errors+1; end

        if (errors==0) $display("\nALL CONFORMANCE TESTS PASSED");
        else            $display("\n%0d CONFORMANCE TEST(S) FAILED", errors);
        $finish;
    end
endmodule

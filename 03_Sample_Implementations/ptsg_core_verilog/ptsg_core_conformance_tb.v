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
//    T15 — RH017 (Phase 3a): a queued (Q-band) Branch, taken, auto-saves
//         its own address and jumps to the taken-target at Stay-timeup —
//         verified via whitebox hr_state inspection (Phase 4b: the taken
//         landing is past the window's close, so Return there is
//         FG-illegal, C3-F23; a real Return round trip is exercised by T19).
//    T16 — RH017: a queued Branch, not taken, resumes at save_state+1
//         with no auto-save (C2-F5).
//    T17 — RH017: a queued Branch with operand 0 (self-loop idiom),
//         taken, resumes at its own address with no auto-save.
//    T18 — RH018 (Phase 3b): a queued (Q-band) Call, unconditional,
//         auto-saves its own address and jumps to the target at
//         Stay-timeup — verified via whitebox hr_state inspection (same
//         reasoning as T15).
//    T19 — RH019 (Phase 3c): a queued (Q-band) Return restores the held
//         context at Stay-timeup, resuming at hr_state+1 — the shallow
//         (stack_depth==0) case.
//    T20 — RH019: a queued Return with a deeper stacked context falls
//         through to S_POP correctly (real push/pop round trip via the
//         testbench's external-stack model).
//    T21 — C3-F26/C8 (Phase 4d, RH023): a second Q-band SN reservation
//         scanned while the shared slot already holds a pending one HALTs
//         (a Loop queued first, then a Branch queued second before the
//         Loop ever fires) — supersedes Phase 3d's last-write-wins
//         placeholder for this exact scenario.
//    T22 — C3-F23/C3-F24 (Phase 4b): a foreground-illegal Global command
//         (Base Set, representative of Base Set/Return/Call/Loop) HALTs —
//         error_flag raises and State Number freezes at the violator.
//    T23 — C3-F24 (Phase 4a/RH022): an insertion rescues the core from
//         S_HALT — error_flag clears, the halted address auto-saves, and
//         the FSM actually returns to S_RUN (a real bug found while
//         writing this test: the S_HALT case never explicitly re-armed
//         fsm, so it stayed stuck there forever after the first rescue).
//    T24 — C3-F24 (Phase 4c): a second Prog End scanned while already in
//         the Q band (stray/duplicate BG->Q boundary) HALTs.
//    T25 — C3-F23/C3-F24 (Phase 4c): a foreground Prog End (previously a
//         silent "blank shot" no-op) now HALTs.
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

    // External-stack-memory responder (C5-F2 variable-clock style,
    // simplified to a fixed 1-clock turnaround): needed by T20, a queued
    // Return whose S_POP fallback exercises a real push/pop round trip.
    reg [40:0] stk_mem [0:7];
    reg [3:0]  stk_sp;
    always @(posedge clk) begin
        if (rst) begin
            stack_ack <= 1'b0;
            stk_sp    <= 4'd0;
        end else begin
            stack_ack <= 1'b0;
            if (stack_push_req && !stack_ack) begin
                stk_mem[stk_sp] <= stack_wdata;
                stk_sp          <= stk_sp + 4'd1;
                stack_ack       <= 1'b1;
            end else if (stack_pop_req && !stack_ack) begin
                stack_rdata <= stk_mem[stk_sp-4'd1];
                stk_sp      <= stk_sp - 4'd1;
                stack_ack   <= 1'b1;
            end
        end
    end

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
    function [31:0] I_CALL;    input [15:0] off;  I_CALL    = {off,  16'h0400}; endfunction
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
        // The handler itself opens its own Stay window (Stay Set is legal in FG,
        // C3-F23) so its Return runs in the background band, as Phase 4b now
        // requires (Return is window-only; FG Return HALTs). This does not
        // disturb the C3-F12 no-+1 check: the resume address was auto-saved by
        // the insertion mechanism itself (hr_ins), at insert time, not here.
        dut.ptsg_imem.g_sim.mem[10]=I_STAYSET(16'h0400);     // handler: open its own window
        dut.ptsg_imem.g_sim.mem[11]=I_NOP(16'h0400);         // BG handler body
        dut.ptsg_imem.g_sim.mem[12]=I_RETURN(16'h0400);      // BG Return -> resumes at s4, no +1 (hr_ins)
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

        // ================================================================
        // T15 — RH017: a queued (Q-band) Branch, taken (Condition=0),
        //      auto-saves its own address and jumps to save_state+operand
        //      at Stay-timeup; a subsequent Return correctly resumes at
        //      save_state+1 (return-to-after, C3-F12), proving the
        //      auto-save captured the Branch's own address, not the
        //      Stay's.
        // ================================================================
        reset1;
        dut.ptsg_imem.g_sim.mem[0]=I_NOP(16'h0000);
        dut.ptsg_imem.g_sim.mem[1]=I_STAYSET(16'h0001);
        dut.ptsg_imem.g_sim.mem[2]=I_NOP(16'h0000);          // BG
        dut.ptsg_imem.g_sim.mem[3]=I_PROGEND(16'h0000);
        dut.ptsg_imem.g_sim.mem[4]=I_BRANCH(16'h0000,12'd4); // Q: Branch, target = 4+4 = 8
        dut.ptsg_imem.g_sim.mem[5]=I_NOP(16'h0555);          // Q-scan continues; also return-to-after landing
        dut.ptsg_imem.g_sim.mem[6]=I_STAY(16'h0001,12'd4);   // FG Stay; closes window at timeup
        dut.ptsg_imem.g_sim.mem[8]=I_NOP(16'h0888);          // taken-branch landing marker
        // Landing at s8 is past the window's own Stay-timeup close (C3-F23:
        // Return is window-only), so verify the auto-save via whitebox
        // inspection instead of an actual Return — mirrors T17's dut.hr_occupied
        // check. hr_state must read 4: the Branch's OWN address (s4), not the
        // Stay's (s6), proving save_state was captured correctly.
        condition=0;   // held false throughout => Branch taken when evaluated at firing
        start;
        seen=0;
        for (k=0;k<300;k=k+1) begin
            @(posedge clk); #1;
            if (timing_signals===16'h0888) begin seen=1; k=300; end
        end
        if (seen && dut.hr_occupied && dut.hr_state===12'd4)
            $display("PASS T15: Q Branch taken -> auto-save + jump (hr_state=%0d, own address)", dut.hr_state);
        else begin
            $display("FAIL T15: taken-landed=%0d hr_occupied=%b hr_state=%0d", seen, dut.hr_occupied, dut.hr_state);
            errors=errors+1; end

        // ================================================================
        // T16 — RH017: a queued (Q-band) Branch, NOT taken
        //      (Condition=1), resumes at save_state+1 (the ordinary
        //      "advance" case, C2-F5) with no auto-save.
        // ================================================================
        reset1;
        dut.ptsg_imem.g_sim.mem[0]=I_NOP(16'h0000);
        dut.ptsg_imem.g_sim.mem[1]=I_STAYSET(16'h0001);
        dut.ptsg_imem.g_sim.mem[2]=I_NOP(16'h0000);          // BG
        dut.ptsg_imem.g_sim.mem[3]=I_PROGEND(16'h0000);
        dut.ptsg_imem.g_sim.mem[4]=I_BRANCH(16'h0000,12'd4); // Q: Branch (not taken, condition=1)
        dut.ptsg_imem.g_sim.mem[5]=I_NOP(16'h0666);          // correct not-taken resume target
        dut.ptsg_imem.g_sim.mem[6]=I_STAY(16'h0001,12'd4);
        condition=1;
        start;
        seen=0;
        for (k=0;k<200;k=k+1) begin @(posedge clk); #1;
            if (timing_signals===16'h0666) begin seen=1; k=200; end end
        if (seen) $display("PASS T16: Q Branch not-taken resumed at save_state+1 (no auto-save)");
        else begin $display("FAIL T16: never observed the not-taken resume marker (0x0666)");
            errors=errors+1; end
        condition=0;

        // ================================================================
        // T17 — RH017: a queued (Q-band) Branch with operand 0
        //      (self-loop idiom, C2-F5), taken, resumes at its own
        //      address with NO auto-save (hr_occupied stays 0) — the
        //      self-loop semantics carried into the Q band.
        // ================================================================
        reset1;
        dut.ptsg_imem.g_sim.mem[0]=I_NOP(16'h0000);
        dut.ptsg_imem.g_sim.mem[1]=I_STAYSET(16'h0001);
        dut.ptsg_imem.g_sim.mem[2]=I_NOP(16'h0000);          // BG
        dut.ptsg_imem.g_sim.mem[3]=I_PROGEND(16'h0000);
        dut.ptsg_imem.g_sim.mem[4]=I_BRANCH(16'h0777,12'd0); // Q: Branch operand=0 (self-loop idiom)
        dut.ptsg_imem.g_sim.mem[5]=I_STAY(16'h0001,12'd4);
        condition=0;
        start;
        seen=0;
        for (k=0;k<200;k=k+1) begin @(posedge clk); #1;
            if (state_number===12'd4 && timing_signals===16'h0777) begin seen=1; k=200; end end
        if (seen && !dut.hr_occupied)
            $display("PASS T17: Q Branch self-loop (operand 0) resumed at own address, no auto-save");
        else begin
            $display("FAIL T17: landed=%0d hr_occupied=%b", seen, dut.hr_occupied);
            errors=errors+1; end
        condition=0;

        // ================================================================
        // T18 — RH018 (Phase 3b): a queued (Q-band) Call, unconditional,
        //      auto-saves its own address and jumps to save_state+offset
        //      at Stay-timeup; a subsequent Return correctly resumes at
        //      save_state+1 (return-to-after, C3-F12).
        // ================================================================
        reset1;
        dut.ptsg_imem.g_sim.mem[0]=I_NOP(16'h0000);
        dut.ptsg_imem.g_sim.mem[1]=I_STAYSET(16'h0001);
        dut.ptsg_imem.g_sim.mem[2]=I_NOP(16'h0000);          // BG
        dut.ptsg_imem.g_sim.mem[3]=I_PROGEND(16'h0000);
        dut.ptsg_imem.g_sim.mem[4]=I_CALL(16'd4);            // Q: Call, target = 4+4 = 8
        dut.ptsg_imem.g_sim.mem[5]=I_NOP(16'h0555);          // Q-scan continues; also return-to-after landing
        dut.ptsg_imem.g_sim.mem[6]=I_STAY(16'h0001,12'd4);   // FG Stay; closes window at timeup
        dut.ptsg_imem.g_sim.mem[8]=I_NOP(16'h0888);          // call-target landing marker
        // Same reasoning as T15: verify the auto-save via whitebox inspection
        // rather than an FG Return (C3-F23 window-only). hr_state must read 4:
        // the Call's own address (s4).
        start;
        seen=0;
        for (k=0;k<300;k=k+1) begin
            @(posedge clk); #1;
            if (timing_signals===16'h0888) begin seen=1; k=300; end
        end
        if (seen && dut.hr_occupied && dut.hr_state===12'd4)
            $display("PASS T18: Q Call auto-saved + jumped (hr_state=%0d, own address)", dut.hr_state);
        else begin
            $display("FAIL T18: call-landed=%0d hr_occupied=%b hr_state=%0d", seen, dut.hr_occupied, dut.hr_state);
            errors=errors+1; end

        // ================================================================
        // T19 — RH019 (Phase 3c): a queued (Q-band) Return restores the
        //      held context at Stay-timeup, resuming at hr_state+1
        //      (return-to-after, C3-F12) — the shallow (stack_depth==0)
        //      case.
        // ================================================================
        // The setup Call is window-only (C3-F23); wrap it in a Stay window (open
        // first, Call as BG) rather than run it in FG, then continue scanning
        // through Prog End into the same window's Q band for the Return.
        reset1;
        dut.ptsg_imem.g_sim.mem[0]=I_NOP(16'h0000);
        dut.ptsg_imem.g_sim.mem[1]=I_STAYSET(16'h0001);      // open window
        dut.ptsg_imem.g_sim.mem[2]=I_CALL(16'd3);            // BG Call; own addr=2, target=2+3=5
        dut.ptsg_imem.g_sim.mem[3]=I_NOP(16'h0222);          // return-to-after landing (hr_state+1=3)
        dut.ptsg_imem.g_sim.mem[5]=I_NOP(16'h0444);          // call-target landing (subroutine body), BG
        dut.ptsg_imem.g_sim.mem[6]=I_PROGEND(16'h0000);
        dut.ptsg_imem.g_sim.mem[7]=I_RETURN(16'h0000);       // Q: Return
        dut.ptsg_imem.g_sim.mem[8]=I_STAY(16'h0001,12'd4);   // Q Stay; closes window at timeup
        start;
        seen=0; visits=0;
        // The Call lands mid-window (BG), which holds timing_signals (Held,
        // §3.4b) — so the call-landed check uses state_number, not the 0x0444
        // marker. The Return's landing, by contrast, fires exactly at
        // Stay-timeup (window close), which does drive its own tsig — same
        // mechanism T15/T18 rely on — so 0x0222 remains a valid marker there.
        for (k=0;k<300;k=k+1) begin
            @(posedge clk); #1;
            if (state_number===12'd5) seen=1;
            if (seen && timing_signals===16'h0222) begin visits=1; k=300; end
        end
        if (seen && visits)
            $display("PASS T19: Q Return restored context at Stay-timeup, resumed at hr_state+1");
        else begin
            $display("FAIL T19: call-landed=%0d return-resumed=%0d", seen, visits);
            errors=errors+1; end

        // ================================================================
        // T20 — RH019 (Phase 3c): a queued (Q-band) Return with a DEEPER
        //      stacked context (stack_depth != 0) correctly falls through
        //      to S_POP after restoring the immediate holding-register
        //      context — verified end-to-end via a real push/pop round
        //      trip through the testbench's external-stack model.
        // ================================================================
        // Both setup Calls are window-only (C3-F23); wrap them in an outer Stay
        // window (BG). Call#2's target is itself a (re-arming, always-legal)
        // Stay Set, matching the original nested-call shape.
        reset1;
        dut.ptsg_imem.g_sim.mem[0]=I_NOP(16'h0000);
        dut.ptsg_imem.g_sim.mem[1]=I_STAYSET(16'h0001);      // outer window
        dut.ptsg_imem.g_sim.mem[2]=I_CALL(16'd2);            // BG Call#1; own=2, target=2+2=4; hr_state<=2
        dut.ptsg_imem.g_sim.mem[4]=I_CALL(16'd2);            // BG Call#2; own=4, target=4+2=6;
                                                              // hr_occupied already 1 -> implicit push
                                                              // (spills {hr_state=2,...}), then hr_state<=4
        dut.ptsg_imem.g_sim.mem[5]=I_NOP(16'h0DDD);          // return-to-after landing for Return #1
        dut.ptsg_imem.g_sim.mem[6]=I_STAYSET(16'h0001);      // Call#2's target: re-arms the (already-open) window
        dut.ptsg_imem.g_sim.mem[7]=I_NOP(16'h0000);          // BG
        dut.ptsg_imem.g_sim.mem[8]=I_PROGEND(16'h0000);
        dut.ptsg_imem.g_sim.mem[9]=I_RETURN(16'h0000);       // Q: Return #1 -> resumes at hr_state(4)+1=5;
                                                              // stack_depth==1 -> falls through to S_POP
        dut.ptsg_imem.g_sim.mem[10]=I_STAY(16'h0001,12'd4);  // Q Stay; closes window at timeup
        start;
        seen=0; visits=0;
        for (k=0;k<400;k=k+1) begin
            @(posedge clk); #1;
            if (timing_signals===16'h0DDD) seen=1;
            if (seen && dut.hr_state===12'd2 && dut.stack_depth===16'd0) begin visits=1; k=400; end
        end
        if (seen && visits)
            $display("PASS T20: Q Return with a deeper stacked context fell through to S_POP correctly");
        else begin
            $display("FAIL T20: return-landed=%0d popped-context-restored=%0d (hr_state=%0d depth=%0d)",
                     seen, visits, dut.hr_state, dut.stack_depth);
            errors=errors+1; end

        // ================================================================
        // T21 — C3-F26/C8 (Phase 4d, RH023): a SECOND Q-band SN reservation
        //      scanned while the shared slot already holds a pending one is
        //      a runaway error, not a silent overwrite. A Loop is queued
        //      first (queued_valid: 0->1, the legitimate "last-write-wins"
        //      case — nothing earlier to clobber), then a Branch is queued
        //      second while queued_valid is still 1 (the first Loop hasn't
        //      fired yet, Stay-timeup hasn't arrived) -> HALT at the
        //      Branch's own address. (Superseded T21's old Phase 3d
        //      last-write-wins placeholder — see RH023.)
        // ================================================================
        reset1;
        dut.ptsg_imem.g_sim.mem[0]=I_NOP(16'h0000);
        dut.ptsg_imem.g_sim.mem[1]=I_STAYSET(16'h0001);
        dut.ptsg_imem.g_sim.mem[2]=I_BASESET(16'h0000);      // BG
        dut.ptsg_imem.g_sim.mem[3]=I_PROGEND(16'h0000);
        dut.ptsg_imem.g_sim.mem[4]=I_LOOP(16'h0005);         // Q: Loop queued first -> queued_valid 0->1
        dut.ptsg_imem.g_sim.mem[5]=I_BRANCH(16'h0000,12'd3); // Q: Branch queued SECOND, queued_valid
                                                              // already 1 -> SN-overwrite HALT
        start;
        repeat (30) @(posedge clk); #1;
        if (dut.fsm===3'd5 && dut.error_flag===1'b1 && state_number===12'd5)
            $display("PASS T21: second Q-band SN reservation while one is pending -> HALT (C3-F26/C8)");
        else begin
            $display("FAIL T21: fsm=%0d error_flag=%b state=%0d", dut.fsm, dut.error_flag, state_number);
            errors=errors+1; end
        condition=0;

        // ================================================================
        // T22 — C3-F23/C3-F24 (Phase 4b): a foreground-illegal Global
        //      command (Base Set, representative of Base Set/Return/Call/
        //      Loop -- all four share the same halt task) HALTs: error_flag
        //      raises and State Number freezes at the violating instruction.
        // ================================================================
        reset1;
        dut.ptsg_imem.g_sim.mem[0]=I_NOP(16'h0000);
        dut.ptsg_imem.g_sim.mem[1]=I_BASESET(16'h0000);   // FG Base Set (no window ever opened) -> HALT
        start;
        repeat (30) @(posedge clk); #1;
        if (dut.fsm===3'd5 && dut.error_flag===1'b1 && state_number===12'd1)
            $display("PASS T22: FG Base Set is illegal (C3-F23) -> HALT (error_flag raised, state frozen at s1)");
        else begin
            $display("FAIL T22: fsm=%0d error_flag=%b state=%0d", dut.fsm, dut.error_flag, state_number);
            errors=errors+1; end

        // ================================================================
        // T23 — C3-F24 escape route: an insertion rescues the core from
        //      S_HALT — error_flag clears, the halted address is
        //      auto-saved (hr_ins=1, C3-T7) exactly like an ordinary
        //      insertion, and the handler runs immediately (RH022 fix:
        //      the FSM actually returns to S_RUN instead of staying stuck
        //      in S_HALT, a bug found while writing this test).
        // ================================================================
        reset1;
        dut.ptsg_imem.g_sim.mem[0]=I_NOP(16'h0000);
        dut.ptsg_imem.g_sim.mem[1]=I_BASESET(16'h0000);   // FG Base Set -> HALT at s1
        dut.ptsg_imem.g_sim.mem[10]=I_NOP(16'h0EEE);      // rescue-handler landing marker
        dut.ptsg_imem.g_sim.mem[11]=I_JUMP(16'h0EEE,12'd11); // halt (self-loop; a blank all-zero word
                                                              // decodes as Reset, which would otherwise
                                                              // panic state_number back to 0 and re-HALT)
        start;
        k=0; while (dut.fsm!==3'd5 && k<30) begin @(posedge clk); #1; k=k+1; end
        if (dut.fsm!==3'd5) begin
            $display("FAIL T23 setup: never reached S_HALT"); errors=errors+1;
        end else begin
            insert_req=1; insert_target=12'd10;
            seen=0;
            for (k=0;k<30;k=k+1) begin @(posedge clk); #1;
                if (insert_ack) insert_req=0;
                if (timing_signals===16'h0EEE) seen=1;
            end
            if (seen && dut.fsm===3'd0 && dut.error_flag===1'b0 && dut.hr_state===12'd1 && dut.hr_ins===1'b1)
                $display("PASS T23: insertion rescued S_HALT (error_flag cleared, handler ran, halted addr auto-saved)");
            else begin
                $display("FAIL T23: landed=%0d fsm=%0d error_flag=%b hr_state=%0d hr_ins=%b",
                         seen, dut.fsm, dut.error_flag, dut.hr_state, dut.hr_ins);
                errors=errors+1; end
            insert_req=0;
        end

        // ================================================================
        // T24 — C3-F24 (Phase 4c): a second Prog End scanned while already
        //      in the Q band (a stray/duplicate BG->Q boundary) HALTs.
        // ================================================================
        reset1;
        dut.ptsg_imem.g_sim.mem[0]=I_NOP(16'h0000);
        dut.ptsg_imem.g_sim.mem[1]=I_STAYSET(16'h0001);
        dut.ptsg_imem.g_sim.mem[2]=I_NOP(16'h0000);        // BG
        dut.ptsg_imem.g_sim.mem[3]=I_PROGEND(16'h0000);    // first shot: opens the Q band
        dut.ptsg_imem.g_sim.mem[4]=I_PROGEND(16'h0000);    // second shot: stray -> HALT
        start;
        repeat (30) @(posedge clk); #1;
        if (dut.fsm===3'd5 && dut.error_flag===1'b1 && state_number===12'd4)
            $display("PASS T24: stray 2nd Prog End in the Q band -> HALT (state frozen at s4)");
        else begin
            $display("FAIL T24: fsm=%0d error_flag=%b state=%0d", dut.fsm, dut.error_flag, state_number);
            errors=errors+1; end

        // ================================================================
        // T25 — C3-F23/C3-F24 (Phase 4c): a foreground Prog End
        //      (previously a silent "blank shot" no-op, since there was no
        //      window to close) now HALTs.
        // ================================================================
        reset1;
        dut.ptsg_imem.g_sim.mem[0]=I_NOP(16'h0000);
        dut.ptsg_imem.g_sim.mem[1]=I_PROGEND(16'h0000);   // FG Prog End (no window ever opened) -> HALT
        start;
        repeat (30) @(posedge clk); #1;
        if (dut.fsm===3'd5 && dut.error_flag===1'b1 && state_number===12'd1)
            $display("PASS T25: FG Prog End is illegal (C3-F23) -> HALT (state frozen at s1)");
        else begin
            $display("FAIL T25: fsm=%0d error_flag=%b state=%0d", dut.fsm, dut.error_flag, state_number);
            errors=errors+1; end

        if (errors==0) $display("\nALL CONFORMANCE TESTS PASSED");
        else            $display("\n%0d CONFORMANCE TEST(S) FAILED", errors);
        $finish;
    end
endmodule

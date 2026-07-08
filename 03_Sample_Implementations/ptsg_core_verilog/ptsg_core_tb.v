// ============================================================================
//  ptsg_core_tb.v — Self-checking testbench for the PTSG-Core top layer
//  License: MIT (Layer 3 sample). Run with Icarus Verilog:
//     iverilog -g2012 -o sim ptsg_core.v ptsg_core_tb.v && vvp sim
// ----------------------------------------------------------------------------
//  Exercises the canonical PTSG patterns against the reference implementation:
//    A — LED blink loop (Stay + Jump)
//    B — counted Loop (Base Set + Loop, up-count to a target, auto-clear) —
//        runs in the background band inside a Stay window, since Base
//        Set/Loop are window-only (C3-F23, Phase 4b HALTs them in FG)
//    C — Branch wait-for-Condition (Branch operand 0 self-loop)
//    D — Sub-sequence Call + Return (auto-save / return-to-after) — also
//        runs in the background band for the same reason (C3-F23)
//    E — indirect Jump (Jump operand 0 + indirect-read bus)
//    F — RH028 minimal bare Stays at PRESCALE=1 (Stay-1 = one clock like
//        NOP; Stay-2 loop period exactly the written sum)
//    G — RH028 windowed exactness at PRESCALE=1 (idiom-D duty = written
//        5:5; a scan-overrun windowed Stay-1 fires at the earliest tick
//        instead of running away)
// ============================================================================
`timescale 1ns/1ps
module ptsg_core_tb;
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
    integer errors=0, toggles=0, k; reg last_led;
    reg loop_matched, seen5, seen3;
    integer t_prev, period, seenc;   // Test F/G (RH028) period measurement

    ptsg_core #(.IMEM_DEPTH(32), .PRESCALE(1),
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
    // External indirect-read responder: registered 1-clock (C4-T1 lean B)
    always @(posedge clk) indirect_ready <= indirect_req;

    task reset1; begin rst=1; @(posedge clk); end endtask

    initial begin
        // ---------------- Test A: blink ----------------
        reset1;
        dut.ptsg_imem.g_sim.mem[0]=32'h00010700; dut.ptsg_imem.g_sim.mem[1]=32'h00010021;   // NOP on ; Stay2 (hold on)
        dut.ptsg_imem.g_sim.mem[2]=32'h00000700; dut.ptsg_imem.g_sim.mem[3]=32'h00000021;   // NOP off; Stay2 (hold off)
        dut.ptsg_imem.g_sim.mem[4]=32'h00000013;                             // Jump 1
        @(posedge clk); rst=0; #1; last_led=timing_signals[0];
        for (k=0;k<60;k=k+1) begin @(posedge clk); #1;
            if (timing_signals[0]!==last_led) toggles=toggles+1; last_led=timing_signals[0]; end
        if (toggles>=4) $display("PASS A: blink toggled %0d times",toggles);
        else begin $display("FAIL A: toggles=%0d",toggles); errors=errors+1; end

        // ---------------- Test B: counted Loop ----------------
        // Base Set/Loop are window-only (C3-F23 FG-Global exclusion); this
        // runs them in the background band, inside a Stay window opened by
        // Stay Set. In-window commands hold timing_signals (Held, per
        // §3.4b), so loop_cnt_match — not a tsig marker — is the correct
        // signal to observe the loop's exit (C3-F18).
        reset1;
        dut.ptsg_imem.g_sim.mem[0]=32'h00000700;   // NOP
        dut.ptsg_imem.g_sim.mem[1]=32'h00000200;   // Stay Set (opens the window)
        dut.ptsg_imem.g_sim.mem[2]=32'h00000100;   // Base Set (BG)
        dut.ptsg_imem.g_sim.mem[3]=32'h00000700;   // body NOP (BG)
        dut.ptsg_imem.g_sim.mem[4]=32'h00030500;   // Loop target=3 (BG; D16-D31=3)
        dut.ptsg_imem.g_sim.mem[5]=32'h00000053;   // Jump 5 self (BG; stays inside the still-open window)
        @(posedge clk); rst=0;
        loop_matched=0;
        for (k=0;k<200;k=k+1) begin @(posedge clk); #1;
            if (loop_cnt_match) loop_matched=1; end
        if (loop_matched) $display("PASS B: loop exited, loop_counter=%0d",loop_counter);
        else begin $display("FAIL B: st=%0d",state_number); errors=errors+1; end

        // ---------------- Test C: Branch wait ----------------
        reset1;
        dut.ptsg_imem.g_sim.mem[0]=32'h00000002;   // Branch operand 0 (self-loop)
        dut.ptsg_imem.g_sim.mem[1]=32'h00FF0013;   // Jump 1 self, tsig=0x00FF held
        @(posedge clk); rst=0; condition=0;
        repeat (5) @(posedge clk); #1;
        if (state_number!==12'd0) begin $display("FAIL C: not waiting (st=%0d)",state_number); errors=errors+1; end
        condition=1; repeat (3) @(posedge clk); #1;
        if (timing_signals===16'h00FF) $display("PASS C: branch advanced on condition");
        else begin $display("FAIL C: tsig=%h st=%0d",timing_signals,state_number); errors=errors+1; end
        condition=0;

        // ---------------- Test D: Call + Return ----------------
        // Call/Return are window-only (C3-F23); this runs them in the
        // background band. Since BG Call/Return also hold timing_signals
        // (not driven), verification checks state_number directly rather
        // than a tsig marker.
        reset1;
        dut.ptsg_imem.g_sim.mem[0]=32'h00000700;   // NOP
        dut.ptsg_imem.g_sim.mem[1]=32'h00000200;   // Stay Set (opens the window)
        dut.ptsg_imem.g_sim.mem[2]=32'h00030400;   // Call offset 3 -> 5 (save 2) (BG)
        dut.ptsg_imem.g_sim.mem[3]=32'h00000700;   // return-to-after lands here (BG)
        dut.ptsg_imem.g_sim.mem[4]=32'h00000043;   // Jump 4 self (BG; stays put after the return)
        dut.ptsg_imem.g_sim.mem[5]=32'h00000700;   // subroutine body (BG)
        dut.ptsg_imem.g_sim.mem[6]=32'h00000300;   // Return (BG)
        @(posedge clk); rst=0;
        seen5=0; seen3=0;
        for (k=0;k<50;k=k+1) begin @(posedge clk); #1;
            if (state_number===12'd5) seen5=1;
            if (seen5 && state_number===12'd3) seen3=1;
        end
        if (seen3) $display("PASS D: call/return reached return-to-after (st=%0d)",state_number);
        else begin $display("FAIL D: seen5=%0d seen3=%0d st=%0d",seen5,seen3,state_number); errors=errors+1; end

        // ---------------- Test E: indirect Jump ----------------
        reset1;
        dut.ptsg_imem.g_sim.mem[0]=32'h00000700;   // NOP
        dut.ptsg_imem.g_sim.mem[1]=32'h00000003;   // Jump operand 0 => indirect
        dut.ptsg_imem.g_sim.mem[2]=32'h00000033;   // (skipped)
        dut.ptsg_imem.g_sim.mem[7]=32'hBEEF0700;   // target tsig=0xBEEF
        dut.ptsg_imem.g_sim.mem[8]=32'h00000083;   // Jump 8 halt
        indirect_data=12'd7;
        @(posedge clk); rst=0;
        begin: wE for (k=0;k<50;k=k+1) begin @(posedge clk); #1;
            if (timing_signals===16'hBEEF) disable wE; end end
        if (timing_signals===16'hBEEF) $display("PASS E: indirect jump landed at 7");
        else begin $display("FAIL E: tsig=%h st=%0d",timing_signals,state_number); errors=errors+1; end

        // ---------------- Test F: minimal bare Stays (RH028) ----------------
        // At PRESCALE=1 every clock is a tick, so a Stay's execute clock always
        // coincides with one — that tick must count, and for Stay-1 it IS the
        // deadline: timeup happens on the execute clock itself, making bare
        // Stay-1 consume exactly one clock like FG NOP. Loop period of
        // NOP + Stay-1 + Jump must be exactly 3 clocks; with Stay-2, exactly 4.
        reset1;
        dut.ptsg_imem.g_sim.mem[0]=32'h00000700;   // NOP (state 0; loop lives at 1-3)
        dut.ptsg_imem.g_sim.mem[1]=32'h00010700;   // NOP, tsig=0x0001 (period marker)
        dut.ptsg_imem.g_sim.mem[2]=32'h00020011;   // bare Stay-1, tsig=0x0002
        dut.ptsg_imem.g_sim.mem[3]=32'h00040013;   // Jump 1, tsig=0x0004
        @(posedge clk); rst=0;
        t_prev=-1; period=0; seenc=0;
        for (k=0;k<60 && seenc<5;k=k+1) begin @(posedge clk); #1;
            if (state_number===12'd1) begin
                if (t_prev!=-1) begin
                    if (period==0) period=k-t_prev;
                    else if ((k-t_prev)!=period) period=-1;
                    seenc=seenc+1; end
                t_prev=k; end end
        if (period==3) $display("PASS F1: bare Stay-1 loop period = 3 (Stay-1 = one clock, like NOP)");
        else begin $display("FAIL F1: period=%0d (expected exactly 3)", period); errors=errors+1; end
        reset1;
        dut.ptsg_imem.g_sim.mem[0]=32'h00000700;
        dut.ptsg_imem.g_sim.mem[1]=32'h00010700;   // period marker
        dut.ptsg_imem.g_sim.mem[2]=32'h00020021;   // bare Stay-2
        dut.ptsg_imem.g_sim.mem[3]=32'h00040013;   // Jump 1
        @(posedge clk); rst=0;
        t_prev=-1; period=0; seenc=0;
        for (k=0;k<60 && seenc<5;k=k+1) begin @(posedge clk); #1;
            if (state_number===12'd1) begin
                if (t_prev!=-1) begin
                    if (period==0) period=k-t_prev;
                    else if ((k-t_prev)!=period) period=-1;
                    seenc=seenc+1; end
                t_prev=k; end end
        if (period==4) $display("PASS F2: bare Stay-2 loop period = 4 (exact written value)");
        else begin $display("FAIL F2: period=%0d (expected exactly 4)", period); errors=errors+1; end

        // ---------------- Test G: windowed exactness (RH028) ----------------
        // G1: idiom-D duty at PRESCALE=1 must equal the written Stay value
        // exactly — the FG Stay Set's coincident tick counts as tick #1 of the
        // new window. G2: a windowed Stay-1 right after Stay Set, whose deadline
        // passes during the 2-clock scan pipeline, must fire at the earliest
        // S_WAIT tick instead of running away through a 2^13-count wrap.
        reset1;
        dut.ptsg_imem.g_sim.mem[0]=32'h00000700;   // NOP
        dut.ptsg_imem.g_sim.mem[1]=32'h00010200;   // Stay Set (ON window), tsig=0x0001
        dut.ptsg_imem.g_sim.mem[2]=32'h00000700;   // BG NOP
        dut.ptsg_imem.g_sim.mem[3]=32'h00010051;   // Stay-5 (ON)
        dut.ptsg_imem.g_sim.mem[4]=32'h00000200;   // Stay Set (OFF window)
        dut.ptsg_imem.g_sim.mem[5]=32'h00000600;   // Prog End
        dut.ptsg_imem.g_sim.mem[6]=32'h00000013;   // queued Jump -> 1
        dut.ptsg_imem.g_sim.mem[7]=32'h00000051;   // Stay-5 (OFF)
        dut.ptsg_imem.g_sim.mem[8]=32'h00000700;   // (clear Test E leftovers on the scan path)
        @(posedge clk); rst=0;
        repeat (30) @(posedge clk);
        while (timing_signals[0]!==1'b0) @(posedge clk);
        while (timing_signals[0]!==1'b1) @(posedge clk);
        t_prev=0; while (timing_signals[0]===1'b1) begin t_prev=t_prev+1; @(posedge clk); end
        period=0; while (timing_signals[0]===1'b0 && period<50) begin period=period+1; @(posedge clk); end
        if (t_prev==5 && period==5)
            $display("PASS G1: idiom-D duty at PRESCALE=1 = 5:5 (written value, coincident tick counted)");
        else begin $display("FAIL G1: duty %0d:%0d (expected 5:5)", t_prev, period); errors=errors+1; end
        reset1;
        dut.ptsg_imem.g_sim.mem[0]=32'h00000700;   // NOP
        dut.ptsg_imem.g_sim.mem[1]=32'h00000200;   // Stay Set
        dut.ptsg_imem.g_sim.mem[2]=32'h00000011;   // windowed Stay-1 (deadline passes mid-scan)
        dut.ptsg_imem.g_sim.mem[3]=32'h01000700;   // resume marker tsig=0x0100
        dut.ptsg_imem.g_sim.mem[4]=32'h01000043;   // Jump 4 halt
        @(posedge clk); rst=0;
        seenc=0;
        for (k=0;k<40;k=k+1) begin @(posedge clk); #1;
            if (timing_signals===16'h0100) begin seenc=1; k=40; end end
        if (seenc) $display("PASS G2: windowed Stay-1 fired at earliest tick (no 2^13 runaway)");
        else begin $display("FAIL G2: windowed Stay-1 never resumed (st=%0d, stay_cnt=%0d)",
                            state_number, dut.stay_cnt); errors=errors+1; end

        if (errors==0) $display("\nALL TESTS PASSED");
        else            $display("\n%0d TEST(S) FAILED",errors);
        $finish;
    end
endmodule

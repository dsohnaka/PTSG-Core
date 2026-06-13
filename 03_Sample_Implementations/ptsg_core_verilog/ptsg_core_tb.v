// ============================================================================
//  ptsg_core_tb.v — Self-checking testbench for the PTSG-Core top layer
//  License: MIT (Layer 3 sample). Run with Icarus Verilog:
//     iverilog -g2012 -o sim ptsg_core.v ptsg_core_tb.v && vvp sim
// ----------------------------------------------------------------------------
//  Exercises the canonical PTSG patterns against the reference implementation:
//    A — LED blink loop (Stay + Jump)
//    B — counted Loop (Base Set + Loop, up-count to a target, auto-clear)
//    C — Branch wait-for-Condition (Branch operand 0 self-loop)
//    D — Sub-sequence Call + Return (auto-save / return-to-after)
//    E — indirect Jump (Jump operand 0 + indirect-read bus)
// ============================================================================
`timescale 1ns/1ps
module ptsg_core_tb;
    reg clk=0, rst=1, condition=0;
    wire [11:0] state_number; wire [15:0] timing_signals;
    wire ext_op_valid; wire [3:0] ext_op_subopcode; wire [7:0] ext_op_sub_operand;
    wire [15:0] ext_op_data;
    wire stack_push_req, stack_pop_req; wire [36:0] stack_wdata;
    reg  [36:0] stack_rdata=0; reg stack_ack=0;
    reg insert_req=0; reg [11:0] insert_target=0; wire insert_ack;
    wire [11:0] loop_counter; wire loop_cnt_match;
    wire [11:0] stay_counter; wire stay_cnt_match;
    wire [31:0] prescaler_counter; wire prescaler_match;
    wire indirect_req; wire [1:0] indirect_purpose;
    reg  [11:0] indirect_data=0; reg indirect_ready=0;
    integer errors=0, toggles=0, k; reg last_led;

    ptsg_core #(.IMEM_DEPTH(32), .PRESCALE(1)) dut (
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
        dut.imem[0]=32'h00010700; dut.imem[1]=32'h00010021;   // NOP on ; Stay2 (hold on)
        dut.imem[2]=32'h00000700; dut.imem[3]=32'h00000021;   // NOP off; Stay2 (hold off)
        dut.imem[4]=32'h00000013;                             // Jump 1
        @(posedge clk); rst=0; #1; last_led=timing_signals[0];
        for (k=0;k<60;k=k+1) begin @(posedge clk); #1;
            if (timing_signals[0]!==last_led) toggles=toggles+1; last_led=timing_signals[0]; end
        if (toggles>=4) $display("PASS A: blink toggled %0d times",toggles);
        else begin $display("FAIL A: toggles=%0d",toggles); errors=errors+1; end

        // ---------------- Test B: counted Loop ----------------
        reset1;
        dut.imem[0]=32'h00000700;   // NOP
        dut.imem[1]=32'h00000100;   // Base Set
        dut.imem[2]=32'h00000700;   // body NOP
        dut.imem[3]=32'h00030500;   // Loop target=3 (D16-D31=3)
        dut.imem[4]=32'hAAAA0700;   // exit marker tsig=0xAAAA
        dut.imem[5]=32'h00000053;   // Jump 5 halt
        @(posedge clk); rst=0;
        begin: wB for (k=0;k<200;k=k+1) begin @(posedge clk); #1;
            if (timing_signals==16'hAAAA) disable wB; end end
        if (timing_signals==16'hAAAA) $display("PASS B: loop exited, loop_counter=%0d",loop_counter);
        else begin $display("FAIL B: st=%0d",state_number); errors=errors+1; end

        // ---------------- Test C: Branch wait ----------------
        reset1;
        dut.imem[0]=32'h00000002;   // Branch operand 0 (self-loop)
        dut.imem[1]=32'h00FF0013;   // Jump 1 self, tsig=0x00FF held
        @(posedge clk); rst=0; condition=0;
        repeat (5) @(posedge clk); #1;
        if (state_number!==12'd0) begin $display("FAIL C: not waiting (st=%0d)",state_number); errors=errors+1; end
        condition=1; repeat (3) @(posedge clk); #1;
        if (timing_signals===16'h00FF) $display("PASS C: branch advanced on condition");
        else begin $display("FAIL C: tsig=%h st=%0d",timing_signals,state_number); errors=errors+1; end
        condition=0;

        // ---------------- Test D: Call + Return ----------------
        reset1;
        dut.imem[0]=32'h00000700;   // NOP
        dut.imem[1]=32'h00030400;   // Call offset 3 -> 4 (save 1)
        dut.imem[2]=32'h12340700;   // return-to-after lands here (tsig=0x1234)
        dut.imem[3]=32'h00000033;   // Jump 3 halt
        dut.imem[4]=32'h56780700;   // subroutine body (tsig=0x5678)
        dut.imem[5]=32'h00000300;   // Return
        @(posedge clk); rst=0;
        begin: wD for (k=0;k<50;k=k+1) begin @(posedge clk); #1;
            if (timing_signals===16'h1234) disable wD; end end
        if (timing_signals===16'h1234) $display("PASS D: call/return reached return-to-after (st=%0d)",state_number);
        else begin $display("FAIL D: tsig=%h st=%0d",timing_signals,state_number); errors=errors+1; end

        // ---------------- Test E: indirect Jump ----------------
        reset1;
        dut.imem[0]=32'h00000700;   // NOP
        dut.imem[1]=32'h00000003;   // Jump operand 0 => indirect
        dut.imem[2]=32'h00000033;   // (skipped)
        dut.imem[7]=32'hBEEF0700;   // target tsig=0xBEEF
        dut.imem[8]=32'h00000083;   // Jump 8 halt
        indirect_data=12'd7;
        @(posedge clk); rst=0;
        begin: wE for (k=0;k<50;k=k+1) begin @(posedge clk); #1;
            if (timing_signals===16'hBEEF) disable wE; end end
        if (timing_signals===16'hBEEF) $display("PASS E: indirect jump landed at 7");
        else begin $display("FAIL E: tsig=%h st=%0d",timing_signals,state_number); errors=errors+1; end

        if (errors==0) $display("\nALL TESTS PASSED");
        else            $display("\n%0d TEST(S) FAILED",errors);
        $finish;
    end
endmodule

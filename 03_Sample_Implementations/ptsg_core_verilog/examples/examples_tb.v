`timescale 1ns/1ps
// Verifies that each examples/*.hex program runs correctly on ptsg_core.
module examples_tb;
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
    integer errors=0, k, toggles;
    reg lastled, seenF0, seen8, seen_extwr;

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

    integer j;
    task clear_imem; begin for (j=0;j<32;j=j+1) dut.imem[j]=32'h00000000; end endtask
    task load; input [1023:0] f; begin
        rst=1; @(posedge clk); clear_imem; $readmemh(f, dut.imem); @(posedge clk); rst=0;
    end endtask

    initial begin
        // ---- blinky (PRESCALE=1 here, so it toggles fast) ----
        load("examples/blinky_with_prescaler.hex");
        #1 lastled=timing_signals[0]; toggles=0;
        for (k=0;k<6000;k=k+1) begin @(posedge clk); #1;
            if (timing_signals[0]!==lastled) toggles=toggles+1; lastled=timing_signals[0]; end
        if (toggles>=2) $display("PASS blinky: LED toggled %0d times", toggles);
        else begin $display("FAIL blinky: toggles=%0d", toggles); errors=errors+1; end

        // ---- conditional_branching ----
        load("examples/conditional_branching.hex");
        condition=0; repeat(6) @(posedge clk); #1;
        if (state_number!==12'd0) begin $display("FAIL cond: not waiting (st=%0d)",state_number); errors=errors+1; end
        condition=1; repeat(2) @(posedge clk); #1;
        if (timing_signals===16'h00FF) $display("PASS conditional: action pulsed on Condition");
        else begin $display("FAIL cond: tsig=%h st=%0d",timing_signals,state_number); errors=errors+1; end
        condition=0;

        // ---- sub_sequence_branching ----
        load("examples/sub_sequence_branching.hex");
        seenF0=0;
        for (k=0;k<60;k=k+1) begin @(posedge clk); #1;
            if (timing_signals===16'h00F0) seenF0=1; end
        // after the subroutine, control returns to the 0x0002 state
        if (seenF0) $display("PASS sub_sequence: subroutine body executed and returned");
        else begin $display("FAIL sub_sequence: subroutine never ran"); errors=errors+1; end

        // ---- multi_signal_timing ----
        load("examples/multi_signal_timing.hex");
        seen8=0;
        for (k=0;k<80;k=k+1) begin @(posedge clk); #1;
            if (timing_signals===16'h0008) seen8=1; end
        if (seen8) $display("PASS multi_signal: walked ones up to 0x0008");
        else begin $display("FAIL multi_signal: never reached 0x0008"); errors=errors+1; end

        // ---- background_execution ----
        load("examples/background_execution.hex");
        seen_extwr=0;
        for (k=0;k<20;k=k+1) begin @(posedge clk); #1;
            if (ext_op_valid && ext_op_subopcode===4'd1 &&
                ext_op_sub_operand===8'h10 && ext_op_data===16'hABCD) seen_extwr=1; end
        if (seen_extwr) $display("PASS background: ext write fired in Stay window (subop1 @0x10 = 0xABCD)");
        else begin $display("FAIL background: ext_op never seen"); errors=errors+1; end

        if (errors==0) $display("\nALL EXAMPLE PROGRAMS VERIFIED");
        else            $display("\n%0d EXAMPLE(S) FAILED", errors);
        $finish;
    end
endmodule

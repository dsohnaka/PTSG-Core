`timescale 1ns/1ps
module tb_duty;
    localparam integer PRESCALE = 5;
    reg clk=0, rst=1, condition=0;
    wire [11:0] state_number; wire [15:0] timing_signals;
    wire [11:0] stay_counter; wire stay_cnt_match;
    wire [11:0] loop_counter; wire loop_cnt_match;
    wire [31:0] prescaler_counter; wire prescaler_match;
    wire ext_op_valid; wire [3:0] ext_op_subopcode; wire [7:0] ext_op_sub_operand; wire [15:0] ext_op_data;
    wire stack_push_req, stack_pop_req; wire [36:0] stack_wdata; wire insert_ack;
    wire indirect_req; wire [1:0] indirect_purpose;

    ptsg_core #(.PRESCALE(PRESCALE), .IMEM_DEPTH(256), .INIT_FILE("")) dut (
        .clk(clk),.rst(rst),.condition(condition),
        .state_number(state_number),.timing_signals(timing_signals),
        .ext_op_valid(ext_op_valid),.ext_op_subopcode(ext_op_subopcode),
        .ext_op_sub_operand(ext_op_sub_operand),.ext_op_data(ext_op_data),.ext_op_ready(1'b0),
        .stack_push_req(stack_push_req),.stack_pop_req(stack_pop_req),
        .stack_wdata(stack_wdata),.stack_rdata(37'd0),.stack_ack(1'b0),
        .insert_req(1'b0),.insert_target(12'd0),.insert_ack(insert_ack),
        .loop_counter(loop_counter),.loop_cnt_match(loop_cnt_match),
        .stay_counter(stay_counter),.stay_cnt_match(stay_cnt_match),
        .prescaler_counter(prescaler_counter),.prescaler_match(prescaler_match),
        .indirect_req(indirect_req),.indirect_purpose(indirect_purpose),
        .indirect_data(12'd0),.indirect_ready(1'b0)
    );
    defparam dut.ptsg_imem.VENDOR="SIM";
    defparam dut.ptsg_imem.EDGE="NEG";
    defparam dut.ptsg_imem.RD_LAT=1;
    defparam dut.ptsg_imem.INIT_FILE_HEX=`PROGFILE;

    always #10 clk=~clk;
    initial begin rst=1; repeat(4)@(posedge clk); @(negedge clk); rst=0; end
    initial begin $dumpfile(`VCDFILE); $dumpvars(0,tb_duty); end

    // measure ts0 (D16) run-lengths in clocks, steady portion
    integer clk_count=0; reg t0p; integer last=0; integer printed=0;
    initial t0p=0;
    always @(posedge clk) if(!rst) begin
        clk_count=clk_count+1;
        if (timing_signals[0]!==t0p) begin
            if (clk_count>40 && printed<12) begin
                $display("  ts0=%b held for %0d clk   (just changed to %b at clk %0d, state=%0d, D17=%b)",
                         t0p, clk_count-last, timing_signals[0], clk_count, state_number, timing_signals[1]);
                printed=printed+1;
            end
            last=clk_count; t0p=timing_signals[0];
        end
    end
    initial begin repeat(4+300)@(posedge clk); $display("  ---- end ----"); $finish; end
endmodule

// tb_align.v (v3, definitive) — samples rdata EXACTLY the way the core's FSM
// consumes it: registered at posedge, compared against the state the FSM was
// in at that same edge. This is the FSM's-eye view, free of testbench #delay
// artifacts.
//   EDGE="NEG": FSM-visible instr == mem[state it was in]  (correct alignment)
//   EDGE="POS" RD_LAT=1: FSM-visible instr == mem[one-older state] (the
//                        stale-by-one that SignalTap captured on the DE10-nano)
`timescale 1ns/1ps
module tb_align;
    localparam DATA_W=32, DEPTH=64, ADDR_W=12;
    reg clk=0; always #5 clk=~clk;
    integer errors=0;
    reg [7:0] cyc=0;

    // Registered address driven like state_num (NBA at posedge), with jumps.
    reg  [ADDR_W-1:0] addr=0;
    wire [ADDR_W-1:0] next_addr = (cyc==8'd9)  ? 12'd1  :
                                  (cyc==8'd19) ? 12'd47 :
                                  ((addr+1) % DEPTH);
    always @(posedge clk) begin addr <= next_addr; cyc <= cyc+1; end

    wire [DATA_W-1:0] q_neg, q_pos;
    ptsg_imem #(.ADDR_W(ADDR_W),.DATA_W(DATA_W),.DEPTH(DEPTH),
                .RD_LAT(1),.EDGE("NEG"),.VENDOR("SIM")) dneg (.clk(clk),.addr(addr),.rdata(q_neg));
    ptsg_imem #(.ADDR_W(ADDR_W),.DATA_W(DATA_W),.DEPTH(DEPTH),
                .RD_LAT(1),.EDGE("POS"),.VENDOR("SIM")) dpos (.clk(clk),.addr(addr),.rdata(q_pos));

    // --- FSM's-eye sampling: capture instr and the state it was paired with -
    reg [DATA_W-1:0] seen_neg, seen_pos;
    reg [ADDR_W-1:0] used_addr, used_addr_q;
    always @(posedge clk) begin
        seen_neg    <= q_neg;     // what an FSM decoding at this edge consumed
        seen_pos    <= q_pos;
        used_addr   <= addr;      // the state the FSM was in at this edge
        used_addr_q <= used_addr; // one older
    end

    function [DATA_W-1:0] pat; input [ADDR_W-1:0] k; pat = 32'hC000_0000 + k; endfunction
    integer i; initial begin
        for (i=0;i<DEPTH;i=i+1) begin dneg.g_sim.mem[i]=pat(i); dpos.g_sim.mem[i]=pat(i); end
        repeat(3) @(posedge clk);
        repeat(30) begin
            @(posedge clk); #1;
            if (seen_neg !== pat(used_addr)) begin
                $display("FAIL NEG: FSM@state %0d consumed %h, exp %h",used_addr,seen_neg,pat(used_addr)); errors=errors+1; end
            if (seen_pos !== pat(used_addr_q)) begin
                $display("FAIL POS: FSM@state %0d consumed %h, exp stale mem[%0d]=%h",used_addr,seen_pos,used_addr_q,pat(used_addr_q)); errors=errors+1; end
        end
        if (errors==0) $display("\nALIGN CHECKS PASSED (FSM's-eye view):\n  EDGE=NEG : FSM consumes mem[its own state] -> legacy single-phase FSM correct, unmodified\n  EDGE=POS : FSM consumes mem[one-older state] -> exactly the stale-by-one captured by SignalTap");
        else $display("\n%0d ALIGN CHECK(S) FAILED", errors);
        $finish;
    end
endmodule

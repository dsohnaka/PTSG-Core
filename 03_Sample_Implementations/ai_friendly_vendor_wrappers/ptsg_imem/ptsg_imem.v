// ============================================================================
//  ptsg_imem.v — PTSG-Core Instruction-Memory Wrapper (vendor-abstracted)  v2
//  PTSGコア 命令メモリ・ラッパー(ベンダ抽象化) v2 — EDGE パラメータ追加
//  License: MIT (Layer 3 sample implementation)
// ----------------------------------------------------------------------------
//  ===== TIMING CONTRACT / タイミング契約 =====================================
//
//  EDGE = "POS" (registered read, latency RD_LAT posedges):
//    * addr is sampled on the RISING edge; rdata valid RD_LAT rising edges later.
//    * The consuming FSM needs a fetch stage (2-phase or pipelined).
//    アドレスは立ち上がりで取込、rdata は RD_LAT クロック後に有効。FSM 側に
//    フェッチ段(2相/パイプライン)が必要。
//
//  EDGE = "NEG" (half-cycle read; REQUIRES RD_LAT == 1):
//    * addr (stable since the last rising edge) is captured at the FALLING edge;
//      rdata is valid BEFORE the next rising edge.
//    * From the posedge-FSM's viewpoint this behaves like a combinational read
//      (effective latency 0): at every rising edge, rdata == mem[current addr].
//      The legacy single-phase FSM therefore needs NO modification.
//    * COST: the path  M10K(negedge) -> q -> decode -> FSM regs(posedge)  is a
//      HALF-CYCLE path. At 50 MHz (10 ns half-period) this is comfortable on
//      Cyclone V (M10K Tco ~2.4 ns); practical ceiling is roughly 80-120 MHz.
//      For higher clocks, switch to EDGE="POS" + a fetch stage.
//    アドレス(直前の立ち上がり以降安定)を立ち下がりで取込、次の立ち上がり前に
//    rdata 有効。posedge FSM から見れば組み合わせ読みと等価(実効レイテンシ0)で、
//    既存の単相 FSM は無改修。代償は半サイクルパス(50 MHz では余裕、実用上限
//    およそ 80-120 MHz)。高クロック化時は EDGE="POS"+フェッチ段へ移行のこと。
//
//  *** BOTH branches (SIM / M10K) obey the SAME EDGE and RD_LAT. ***
//  *** SIM / M10K 両ブランチは同一の EDGE と RD_LAT に従う。 ***
//  A SIM model that read combinationally while hardware read on negedge would
//  re-create the sim/synth mismatch INSIDE the wrapper. The SIM branch below
//  therefore registers on the SAME edge the silicon does.
//  SIM が組み合わせ読みで実機が negedge 読みなら、ミスマッチをラッパー内に再生産
//  してしまう。ゆえに SIM ブランチもシリコンと同じエッジで取り込む。
//
//  In-System Memory Content Editor: enabled in the M10K branch via
//  lpm_hint "ENABLE_RUNTIME_MOD=YES, INSTANCE_NAME=PTSG" (architect-verified
//  on DE10-nano, 2026-06-10).
// ============================================================================

module ptsg_imem #(
    parameter integer ADDR_W        = 12,
    parameter integer DATA_W        = 32,
    parameter integer DEPTH         = 256,
    parameter integer RD_LAT        = 1,      // >= 1; must be 1 when EDGE="NEG"
    parameter         EDGE          = "NEG",  // "POS" | "NEG"
    parameter         VENDOR        = "M10K",  // "SIM" | "M10K"
    parameter         INIT_FILE_HEX = "",
    parameter         INIT_FILE_MIF = ""
)(
    input  wire                clk,
    input  wire [ADDR_W-1:0]   addr,
    output wire [DATA_W-1:0]   rdata
);
    localparam integer AW = (DEPTH <= 1) ? 1 : $clog2(DEPTH);
    wire [AW-1:0] a = addr[AW-1:0];

    // Memory clock: NEG inverts. On Cyclone V the inversion is absorbed into
    // the M10K clock input (no extra logic, no extra skew).
    wire mem_clk = (EDGE == "NEG") ? ~clk : clk;

    generate
    if (VENDOR == "SIM") begin : g_sim
        // (* ramstyle = "M10K, no_rw_check" *)
        reg [DATA_W-1:0] mem [0:DEPTH-1];
        integer i;
        initial begin
            for (i = 0; i < DEPTH; i = i + 1) mem[i] = {DATA_W{1'b0}};
            if (INIT_FILE_HEX != "") $readmemh(INIT_FILE_HEX, mem);
            if (RD_LAT < 1) begin
                $display("** ptsg_imem ERROR: RD_LAT must be >= 1."); $finish; end
            if (EDGE == "NEG" && RD_LAT != 1) begin
                $display("** ptsg_imem ERROR: EDGE=NEG requires RD_LAT==1."); $finish; end
        end
        reg [DATA_W-1:0] rd_pipe [0:RD_LAT-1];
        integer s;
        always @(posedge mem_clk) begin          // = negedge clk when EDGE="NEG"
            rd_pipe[0] <= mem[a];
            for (s = 1; s < RD_LAT; s = s + 1) rd_pipe[s] <= rd_pipe[s-1];
        end
        assign rdata = rd_pipe[RD_LAT-1];
    end
    else begin : g_m10k
        altsyncram #(
            .operation_mode          ("ROM"),
            .width_a                 (DATA_W),
            .widthad_a               (AW),
            .numwords_a              (DEPTH),
            .outdata_reg_a           ((RD_LAT >= 2) ? "CLOCK0" : "UNREGISTERED"),
            .address_aclr_a          ("NONE"),
            .outdata_aclr_a          ("NONE"),
            .init_file               (INIT_FILE_MIF),
            .lpm_hint                ("ENABLE_RUNTIME_MOD=YES,INSTANCE_NAME=PTSG"),
            .intended_device_family  ("Cyclone V"),
            .ram_block_type          ("M10K"),
            .lpm_type                ("altsyncram")
        ) u_rom (
            .clock0    (mem_clk),                 // ~clk when EDGE="NEG"
            .address_a (a),
            .q_a       (rdata)
        );
    end
    endgenerate
endmodule

// ============================================================================
//  PTSG-Core — Reference Top-Level Verilog Implementation
//  PTSG (Programmable Timing Sequence Generator) Core
//  PTSGコア — リファレンス・トップ層 Verilog 実装
// ----------------------------------------------------------------------------
//  License : MIT (Layer 3 sample implementation; see 03_Sample_Implementations/README.md)
//
//  This module is the *top layer* of the PTSG-Core: a single synthesizable
//  module that ties together the instruction memory, the instruction decoder,
//  the four opcodes (Global / Stay / Branch / Jump), the eight internal-control
//  sub-opcodes, the Stay-window / background-execution machinery, the prescaler,
//  the stay / loop / prescaler counters with their match flags, the internal
//  information-holding register with implicit external-stack nesting, and the
//  external interface buses (operation, stack, insertion, indirect-read).
//
//  このモジュールは PTSG コアの*トップ層*である: 命令メモリ、命令デコーダ、
//  4 オペコード(Global/Stay/Branch/Jump)、8 個の内部制御サブオペコード、
//  Stay ウィンドウ／裏実行機構、プリスケーラ、ステイ／ループ／プリスケーラ
//  カウンタと一致フラグ、暗黙的外部スタック入れ子を伴う内部情報保持レジスタ、
//  そして外部インターフェースバス(演算／スタック／挿入／間接読み)を結びつける
//  単一の合成可能モジュールである。
//
//  Specification basis (Layer 1):
//    Chapter 1 — Scope and Design Philosophy
//    Chapter 2 — Memory Layout and Opcode Set (v1.1)
//    Chapter 3 — Sub-Opcode Architecture and Background Execution (v1.1)
//    Chapter 4 — Indirect Addressing and Prescaler (v1.0)
//    Chapter 5 — External Logic Interface (v1.0)
//
//  This is ONE possible implementation, not THE implementation. It resolves the
//  open Ties of Layer 1 according to the contributor's documented leans:
//
//    C5-V1 reset polarity ......... active-high
//    C5-V2 clock edge ............. rising edge
//    C5-V3 reset .................. synchronous
//    C5-V5 state_number ........... registered
//    C3-T1 timing-signal hold ..... Stay state's D16-D31 during the wait (lean A);
//                                   Stay-Set state's D16-D31 during the background band
//    C3-T2 queued op order ........ FIFO (only one queued op slot is implemented)
//    C3-T4 min-stay violation ..... Core proceeds (no stall on ext_op_ready)
//    C3-T6 stack push/pop ......... implicit (Core auto-pushes/pops, with stall)
//    C3-T7 insertion flag bit ..... Core carries the "saved-by-insertion" flag
//    C3-F20 insertion timing ...... deferred to Stay-timeup inside a Stay window
//    C4-T1 indirect handshake ..... Core stalls until indirect_ready (covers B and C)
//    C4-T2 prescaler config ....... compile-time fixed (PRESCALE parameter)
//    C4-T4 Stay Set role .......... clear/sync only — the stay counter ticks only
//                                   during the wait, so background-band length adds
//                                   no jitter to the wait duration (lean B)
//
//  Deliberate simplifications (documented; faithful to the canonical patterns):
//    * The queued band (after Prog End) implements a single queued operation slot
//      and supports the canonical queued Loop. Other internal-mode commands placed
//      after Prog End execute immediately (the dominant pattern queues one Loop).
//    * The indirect-read for a *queued* (post-Prog-End) Loop is not performed; a
//      queued Loop uses its literal D16-D31 target (0 => zero iterations, C4-V1).
//    * Base Set keeps a single-level base (it sets the base and advances). The
//      Loop body re-enters the Base Set state every iteration, so Base Set is
//      idempotent and does not spill the previous base to the external stack;
//      nested-loop base-stacking is therefore not provided here. (Branch / Call /
//      Insertion auto-save and the external stack nesting ARE implemented.)
//    * Instruction memory is modelled with single-cycle (asynchronous) read for
//      clarity. On Cyclone V this would map to a registered M10K block; the FSM
//      can be pipelined accordingly without changing the externally-visible
//      contract (the 1-clock-per-opcode Convention C2-T4).
// ============================================================================
// REVISION HISTORY(RH)
// 001 2026-06-14 22:06 Arch. Ohnaka  Add : This defines the execution of NOP as a Que command, background command, and foreground command.
// 002 2026-06-14 22:06 Arch. Ohnaka  Add : Since the stay counter may have already started counting due to StaySet,
//                                          in that case, if it's a prescaler tick, the stay counter needs to be incremented.
// 003 2026-06-14 22:06 Arch. Ohnaka  Del : The stay counter may have already started counting in StaySet, so it should not be cleared here.
// 004 2026-06-14 22:06 Arch. Ohnaka  Add : Since the stay counter may have already started counting due to StaySet, in that case,
//                                          if it's a prescaler tick, the stay counter needs to be incremented.
// 005 2026-06-15 21:07 Arch. Ohnaka  Add : When the Stay window is open, even if a global command is running,
//                                          the Stay counter needs to be incremented when the prescaler expires.
// 006 2026-06-15 21:07 Arch. Ohnaka  Add : This defines the execution of JUMP as a Que command, background command, and foreground command.
// 007 2026-06-15 21:07 Arch. Ohnaka  Add : Opcode for Foreground commands can also be queued.
// 008 2026-06-15 21:07 Arch. Ohnaka  Add : When queuing the JUMP command
// 009 2026-07-07       Claude Code   Mod : Loop operand/counter width is 16 bits (full D16-D31 extended
//                                          operand, architect ruling 2026-07-07). loop_cnt / hr_loop /
//                                          queued_target / loop_counter output / STACK_W widened via LOOP_W.
//
// ============================================================================

module ptsg_core #(
    // ---- Geometry -----------------------------------------------------------
    parameter integer ADDR_W      = 12,           // State-number / address width (Fixed by Core)
    parameter integer DATA_W      = 32,           // Instruction word width        (Fixed by Core)
    parameter integer TSIG_W      = 16,           // Timing-signal bus width        (Fixed by Core)
    parameter integer CNT_W       = 12,           // Stay counter width (12-bit operand D4-D15)
    parameter integer LOOP_W      = 16,           // Loop counter/target width — full D16-D31
                                                  // extended operand (architect ruling 2026-07-07;
                                                  // supersedes the 12-bit C3-V2 reading)
    parameter integer IMEM_DEPTH  = 256,          // Instruction-memory depth (<= 4096)
    // ---- Prescaler (C4-T2 option A: compile-time fixed) ---------------------
    parameter integer PRESCALE    = 5,            // System-clock divider for the time axis (>=1)
    parameter integer PRESC_W     = 32,           // Prescaler counter width
    // ---- External stack data layout ----------------------------------------
    //   {ins_flag, base[11:0], loop[15:0], state[11:0]} = 1 + 12 + 16 + 12 = 41
    parameter integer STACK_W     = 1 + ADDR_W + LOOP_W + ADDR_W,
    // ---- Instruction-memory initialisation (simulation: hex; Quartus: .mif) -
    parameter         INIT_FILE     = "blinky_with_prescaler.hex",  // $readmemh file (SIM branch), or "" for none
    parameter         INIT_FILE_MIF = "",           // .mif file (M10K branch), or "" for none
    // ---- Instruction-memory vendor branch (ptsg_imem wrapper) ---------------
    //   "M10K" : Cyclone V altsyncram + ISMCE (INSTANCE_NAME=PTSG) — synthesis
    //   "SIM"  : behavioural array — simulation (iverilog etc.)
    parameter         IMEM_VENDOR   = "M10K",
    parameter         IMEM_EDGE     = "NEG"         // "NEG" = half-cycle read, FSM needs no fetch stage
) (
    // ---- Mandatory pins (Chapter 5 §5.2) ------------------------------------
    input  wire                 clk,              // System clock           (§5.3)
    input  wire                 rst,              // Synchronous, active-high (§5.3, C5-V1/V3)
    input  wire                 condition,        // 1-bit Condition input  (§5.4)
    output wire [ADDR_W-1:0]    state_number,     // Current State Number   (§5.6, registered C5-V5)
    output reg  [TSIG_W-1:0]    timing_signals,   // 16 timing signals      (§5.5)

    // ---- External-operation bus (§5.7) --------------------------------------
    output wire                 ext_op_valid,
    output wire [3:0]           ext_op_subopcode,
    output wire [7:0]           ext_op_sub_operand,
    output wire [TSIG_W-1:0]    ext_op_data,
    input  wire                 ext_op_ready,     // Captured but not stalled on (C3-T4 lean A)

    // ---- External-stack bus (§5.8) — split bidirectional bus for synthesis --
    output reg                  stack_push_req,
    output reg                  stack_pop_req,
    output wire [STACK_W-1:0]   stack_wdata,      // Core -> External (push)
    input  wire [STACK_W-1:0]   stack_rdata,      // External -> Core (pop)
    input  wire                 stack_ack,

    // ---- Insertion bus (§5.9) -----------------------------------------------
    input  wire                 insert_req,
    input  wire [ADDR_W-1:0]    insert_target,
    output reg                  insert_ack,

    // ---- Loop-counter and match flags (§5.10) -------------------------------
    output wire [LOOP_W-1:0]    loop_counter,
    output reg                  loop_cnt_match,
    output wire [CNT_W-1:0]     stay_counter,
    output reg                  stay_cnt_match,
    output wire [PRESC_W-1:0]   prescaler_counter,
    output wire                 prescaler_match,

    // ---- Indirect-read bus (§5.11) ------------------------------------------
    output wire                 indirect_req,
    output wire [1:0]           indirect_purpose, // 00 = Jump, 01 = Loop target
    input  wire [ADDR_W-1:0]    indirect_data,
    input  wire                 indirect_ready
);

    // ========================================================================
    //  Opcode / sub-opcode constants (Chapter 2)
    // ========================================================================
    localparam [3:0] OP_GLOBAL = 4'd0;
    localparam [3:0] OP_STAY   = 4'd1;
    localparam [3:0] OP_BRANCH = 4'd2;
    localparam [3:0] OP_JUMP   = 4'd3;

    localparam [7:0] SUB_RESET    = 8'd0;   // Reset
    localparam [7:0] SUB_BASESET  = 8'd1;   // Base Set
    localparam [7:0] SUB_STAYSET  = 8'd2;   // Stay Set
    localparam [7:0] SUB_RETURN   = 8'd3;   // Return
    localparam [7:0] SUB_CALL     = 8'd4;   // Sub-sequence Call
    localparam [7:0] SUB_LOOP     = 8'd5;   // Loop
    localparam [7:0] SUB_PROGEND  = 8'd6;   // Prog End (v1.1, tentative)
    localparam [7:0] SUB_NOP      = 8'd7;   // NOP

    // ========================================================================
    //  Instruction memory — vendor-abstracted wrapper (ptsg_imem, EDGE="NEG").
    //  From this posedge FSM's viewpoint the NEG half-cycle read behaves like a
    //  combinational read (effective latency 0): at every rising edge,
    //  instr == mem[state_num]. See ptsg_imem.v for the timing contract.
    //  The wrapper instance is declared below, after the fetch wires.
    // ========================================================================

    // ========================================================================
    //  Core control registers
    // ========================================================================
    reg [ADDR_W-1:0]  state_num;        // Program counter (the live State Number)
    reg [LOOP_W-1:0]  loop_cnt;         // Single primary loop counter (C3-F16), up-count
    reg [ADDR_W-1:0]  base_addr;        // Loop base address (Base Set)

    // Internal information-holding register (depth-1, C3-F10) ----------------
    reg [ADDR_W-1:0]  hr_state;
    reg [LOOP_W-1:0]  hr_loop;
    reg [ADDR_W-1:0]  hr_base;
    reg               hr_ins;           // "saved by insertion" flag (C3-T7 lean A)
    reg               hr_occupied;
    reg [15:0]        stack_depth;      // # of contexts spilled to external stack

    // Stay window / background-execution state -------------------------------
    reg               window_open;      // Set by Stay Set, cleared at Stay-timeup
    reg               prog_end_seen;    // Set by Prog End inside an open window

    // Single queued-operation slot (queued band, C3-T2 FIFO depth-1) ---------
    reg               queued_valid;
    reg [7:0]         queued_subop;
    reg [3:0]         queued_opcode;    // Add: Opcode for Foreground commands can also be queued. - RH 007 Arch. Ohnaka (2026-06-15 21:07)
    reg [LOOP_W-1:0]  queued_target;

    // Stay-counter (13-bit internal: 0..4096) --------------------------------
    reg [CNT_W:0]     stay_cnt;
    reg [CNT_W:0]     stay_target;

    // Prescaler (free-running) -----------------------------------------------
    reg [PRESC_W-1:0] presc_cnt;
    wire              presc_tick = (presc_cnt == (PRESCALE-1));

    // Indirect-read latch ----------------------------------------------------
    reg               ind_is_loop;      // 0 = indirect Jump, 1 = indirect Loop target

    // FSM --------------------------------------------------------------------
    localparam [2:0] S_RUN  = 3'd0,
                     S_WAIT = 3'd1,
                     S_IND  = 3'd2,
                     S_PUSH = 3'd3,
                     S_POP  = 3'd4;
    reg [2:0] fsm;

    // Pending context for a stalled (PUSH) auto-save -------------------------
    reg [ADDR_W-1:0]  pend_state;       // return address to store
    reg [LOOP_W-1:0]  pend_loop;
    reg [ADDR_W-1:0]  pend_base;
    reg               pend_ins;
    reg [ADDR_W-1:0]  pend_target;      // where to jump once the save completes
    reg               pend_is_insert;   // pulse insert_ack on completion

    // ========================================================================
    //  Instruction fetch and field decode (Chapter 2 §2.2)
    //  ptsg_imem EDGE="NEG": effectively combinational for this posedge FSM.
    // ========================================================================
    wire [DATA_W-1:0]	instr;
    ptsg_imem #(
    	.ADDR_W        (ADDR_W),
    	.DATA_W        (DATA_W),
    	.DEPTH         (IMEM_DEPTH),
    	.RD_LAT        (1),
    	.EDGE          (IMEM_EDGE),
    	.VENDOR        (IMEM_VENDOR),
    	.INIT_FILE_HEX (INIT_FILE),
    	.INIT_FILE_MIF (INIT_FILE_MIF)
    ) ptsg_imem (
    	.clk	(clk),
    	.addr	(state_num),
    	.rdata	(instr)
    );

    wire [3:0]        opcode  = instr[3:0];        // D0-D3
    wire [11:0]       operand = instr[15:4];       // D4-D15
    wire [15:0]       tsig    = instr[31:16];      // D16-D31 (timing signals)
    wire [3:0]        g_mode  = instr[7:4];        // D4-D7  (Global mode / ext sub-op)
    wire [7:0]        g_subop = instr[15:8];       // D8-D15 (internal sub-op selector)
    wire [15:0]       g_ext   = instr[31:16];      // D16-D31 (extended operand / data)

    wire is_global          = (opcode == OP_GLOBAL);
    wire is_internal_global = is_global && (g_mode == 4'd0);
    wire is_external_global = is_global && (g_mode != 4'd0);

    // True while a Loop encountered here belongs to the queued band ----------
    wire in_queued_band = window_open && prog_end_seen;

    // An indirect read is required this RUN clock when:
    //   * Jump with operand 0, or
    //   * an immediate/foreground Loop whose D16-D31 target field is 0.
    wire need_ind_jump = (opcode == OP_JUMP) && (operand == 12'd0);
    wire need_ind_loop = is_internal_global && (g_subop == SUB_LOOP) &&
                         (g_ext == 16'd0) && !in_queued_band;
    wire need_indirect = (fsm == S_RUN) && !insert_pending &&
                         (need_ind_jump || need_ind_loop);

    // Honour an insertion request at the next safe moment in RUN (between
    // instructions). Inside a Stay window it is deferred to timeup (C3-F20).
    wire insert_pending = (fsm == S_RUN) && insert_req && !hr_occupied;

    // ========================================================================
    //  Combinational external-bus outputs
    // ========================================================================
    // state_num is itself the State Number register; presenting it directly keeps
    // the output in step with the executing state (C5-V5) with no extra latency.
    assign state_number       = state_num;
    assign ext_op_valid       = (fsm == S_RUN) && is_external_global && !insert_pending;
    assign ext_op_subopcode   = g_mode;
    assign ext_op_sub_operand  = g_subop;
    assign ext_op_data        = g_ext;

    assign indirect_req       = need_indirect;
    assign indirect_purpose   = need_ind_jump ? 2'b00 : 2'b01;

    assign stack_wdata        = {hr_ins, hr_base, hr_loop, hr_state};

    assign loop_counter       = loop_cnt;
    assign stay_counter       = stay_cnt[CNT_W-1:0];
    assign prescaler_counter  = presc_cnt;
    assign prescaler_match    = presc_tick;

    // ========================================================================
    //  Resolved Stay duration: literal-zero-as-escape => 4096 (C2-F3)
    // ========================================================================
    wire [CNT_W:0] stay_dur = (operand == 12'd0) ? (1'b1 << CNT_W) : {1'b0, operand};

    // Loop "increment-then-compare" helper (combinational) -------------------
    //   target == 0           -> exit immediately, 0 iterations (C4-V1)
    //   loop_cnt+1 >= target  -> exit, auto-clear, emit match (C3-F17/F18)
    //   else                  -> continue, jump to base_addr
    function automatic [0:0] loop_exits;
        input [LOOP_W-1:0] cur;
        input [LOOP_W-1:0] target;
        begin
            loop_exits = (target == 0) || ((cur + 1'b1) >= target);
        end
    endfunction

    // ========================================================================
    //  Main synchronous process
    // ========================================================================
    integer i;
    // Post-Stay resume address at timeup. Combinational (driven from the live
    // registers) so it has no extra clock of latency: a queued Loop that has not
    // yet reached its target redirects the resume to the base address, otherwise
    // execution advances past the Stay state.
    wire [ADDR_W-1:0] resume_addr =
        (queued_valid && (queued_subop == SUB_LOOP) &&
         !loop_exits(loop_cnt, queued_target)) ? base_addr :
        // =============================================================================//
        // REVISION HISTORY  008                                                        //
        // 2026-06-15 21:07 Arch. Ohnaka  Add : When queuing the JUMP command           //
        // =============================================================================//
        (queued_valid && (queued_opcode == OP_JUMP)) ? queued_target :                  //
        // =============================================================================//
        (state_num + 1'b1);

    always @(posedge clk) begin
        if (rst) begin
            // -------- Synchronous reset (C5-V3); also the Reset sub-op target -
            state_num       <= {ADDR_W{1'b0}};
            timing_signals  <= {TSIG_W{1'b0}};
            loop_cnt        <= {LOOP_W{1'b0}};
            base_addr       <= {ADDR_W{1'b0}};
            hr_state        <= {ADDR_W{1'b0}};
            hr_loop         <= {LOOP_W{1'b0}};
            hr_base         <= {ADDR_W{1'b0}};
            hr_ins          <= 1'b0;
            hr_occupied     <= 1'b0;
            stack_depth     <= 16'd0;
            window_open     <= 1'b0;
            prog_end_seen   <= 1'b0;
            queued_valid    <= 1'b0;
            queued_subop    <= 8'd0;
            queued_target   <= {LOOP_W{1'b0}};
            stay_cnt        <= {(CNT_W+1){1'b0}};
            stay_target     <= {(CNT_W+1){1'b0}};
            presc_cnt       <= {PRESC_W{1'b0}};
            ind_is_loop     <= 1'b0;
            fsm             <= S_RUN;
            stack_push_req  <= 1'b0;
            stack_pop_req   <= 1'b0;
            insert_ack      <= 1'b0;
            loop_cnt_match  <= 1'b0;
            stay_cnt_match  <= 1'b0;
            pend_is_insert  <= 1'b0;
        end else begin
            // -------- Default (one-clock) pulse de-assertions ----------------
            stack_push_req <= 1'b0;
            stack_pop_req  <= 1'b0;
            insert_ack     <= 1'b0;
            loop_cnt_match <= 1'b0;
            stay_cnt_match <= 1'b0;

            // Free-running prescaler ----------------------------------------
            presc_cnt <= presc_tick ? {PRESC_W{1'b0}} : (presc_cnt + 1'b1);

            case (fsm)
            // ================================================================
            //  S_RUN — fetch and execute one state per clock
            // ================================================================
            S_RUN: begin
                if (insert_pending) begin
                    // ---- Honour insertion (between instructions) -----------
                    //  Save the instruction we were about to execute (no +1 on
                    //  return, C3-F12) and jump to the inserted address.
                    hr_state    <= state_num;
                    hr_loop     <= loop_cnt;
                    hr_base     <= base_addr;
                    hr_ins      <= 1'b1;
                    hr_occupied <= 1'b1;
                    state_num   <= insert_target;
                    insert_ack  <= 1'b1;
                end
                else if (need_indirect) begin
                    // ---- Begin an indirect read; stall in S_IND ------------
                    ind_is_loop <= need_ind_loop;
                    fsm         <= S_IND;
                    // state_num held; indirect_req pulsed combinationally now.
                end
                else begin
                    case (opcode)
                    // --------------------------------------------------------
                    //  Global (opcode 0)
                    // --------------------------------------------------------
                    OP_GLOBAL: begin
                        if (is_internal_global) begin
                            case (g_subop)
                            SUB_RESET: begin
                                // Force State Number to 0; clear counters/holding.
                                state_num      <= {ADDR_W{1'b0}};
                                loop_cnt       <= {LOOP_W{1'b0}};
                                base_addr      <= {ADDR_W{1'b0}};
                                hr_occupied    <= 1'b0;
                                stack_depth    <= 16'd0;
                                window_open    <= 1'b0;
                                prog_end_seen  <= 1'b0;
                                queued_valid   <= 1'b0;
                                timing_signals <= {TSIG_W{1'b0}};
                            end
                            SUB_BASESET: begin
                                // Mark the current address as the Loop base and
                                // advance. The base address is where Loop jumps
                                // back to, so a loop re-enters this state every
                                // iteration; Base Set is therefore idempotent and
                                // must NOT auto-save (that would push a context per
                                // iteration). This reference keeps a single-level
                                // base — nested-loop base-stacking (spilling the
                                // previous base to the external stack) is omitted.
                                base_addr <= state_num;
                                state_num <= state_num + 1'b1;
                            end
                            SUB_STAYSET: begin
                                // Open the window; clear/arm the stay counter
                                // (C4-T4 lean B: ticking happens only in S_WAIT).
                                window_open    <= 1'b1;
                                prog_end_seen  <= 1'b0;
                                queued_valid   <= 1'b0;
                                stay_cnt       <= {(CNT_W+1){1'b0}};
                                timing_signals <= tsig;   // held during the band
                                state_num      <= state_num + 1'b1;
                            end
                            SUB_RETURN: begin
                                // Restore the held context.
                                state_num <= hr_ins ? hr_state : (hr_state + 1'b1);
                                loop_cnt  <= hr_loop;
                                base_addr <= hr_base;
                                if (stack_depth != 16'd0) begin
                                    // A deeper context is on the external stack.
                                    stack_pop_req <= 1'b1;
                                    fsm           <= S_POP;
                                end else begin
                                    hr_occupied <= 1'b0;
                                end
                            end
                            SUB_CALL: begin
                                // Unconditional call: auto-save the call address
                                // (Return restores saved+1, the return-to-after
                                // convention C3-F12) then jump by the 12-bit
                                // offset in the extended operand (D16-D31).
                                save_or_set(state_num,
                                            1'b0,
                                            state_num + g_ext[ADDR_W-1:0]);
                            end
                            SUB_LOOP: begin
                                if (in_queued_band) begin
                                    // Defer to Stay-timeup (queued band).
                                    queued_valid  <= 1'b1;
                                    queued_subop  <= SUB_LOOP;
                                    queued_target <= g_ext[LOOP_W-1:0];
                                    state_num     <= state_num + 1'b1;
                                end else begin
                                    // Immediate / foreground Loop (literal target;
                                    // indirect target handled via S_IND above).
                                    if (loop_exits(loop_cnt, g_ext[LOOP_W-1:0])) begin
                                        loop_cnt       <= {LOOP_W{1'b0}};
                                        loop_cnt_match <= 1'b1;
                                        state_num      <= state_num + 1'b1;
                                    end else begin
                                        loop_cnt  <= loop_cnt + 1'b1;
                                        state_num <= base_addr;
                                    end
                                end
                            end
                            SUB_PROGEND: begin
                                // Close the immediate band (blank shot if no window).
                                if (window_open) prog_end_seen <= 1'b1;
                                state_num <= state_num + 1'b1;
                            end
                            default: begin
                                // NOP (sub-op 7) and reserved 8-255: present tsig.
                                // =============================================================================//
                                // REVISION HISTORY 001                                                         //
                                // 2026-06-14 22:06 Arch. Ohnaka  Add :This defines the execution of NOP        //
                                //      as a Que command, background command, and foreground command.           //
                                // =============================================================================//
                                if (prog_end_seen) begin                     // as Que command (after Prog End) //
                                    fsm            <= S_WAIT;                                                   //
                                end                                                                             //
                                else if (window_open) begin       // as background command (inside Stay window) //  
                                    state_num      <= state_num + 1'b1;                                         //
                                end                                                                             //
                                else begin                       // as foreground command (outside Stay window) //
                                    timing_signals <= tsig;                                                     //
                                    if (presc_tick) begin      // Advance only on prescaler tick (C4-T4 lean B) //
                                        state_num      <= state_num + 1'b1;      // Advance to next instruction //
                                    end                                                                         //
                                end                                                                             //
                                // =============================================================================//
                            end
                            endcase
                        end else begin
                            // External-mode Global: ext_op_valid pulsed this clock;
                            // D16-D31 is operand data, so timing_signals is held.
                            state_num <= state_num + 1'b1;
                        end
                        // =============================================================================//
                        // REVISION HISTORY  005                                                        //
                        // 2026-06-15 21:07 Arch. Ohnaka  Add : When the Stay window is open,           //
                        //      even if a global command is running, the Stay counter needs             //
                        //      to be incremented when the prescaler expires.                           //
                        // =============================================================================//
                        if ( window_open && presc_tick ) begin                                          //
                            stay_cnt <= stay_cnt + 1'b1;                                                //
                        end                                                                             //
                        // =============================================================================//
                    end
                    // --------------------------------------------------------
                    //  Stay (opcode 1) — enter the wait
                    // --------------------------------------------------------
                    OP_STAY: begin
                        //stay_cnt       <= {(CNT_W+1){1'b0}};  // Del : The stay counter may have already started counting in StaySet, so it should not be cleared here. - RH 003 Arch. Ohnaka (2026-06-14 22:06)
                        stay_target    <= stay_dur;
                        timing_signals <= tsig;        // held value during wait (C3-T1 A)
                        fsm            <= S_WAIT;
                        // =============================================================================//
                        // REVISION HISTORY  004                                                        //
                        // 2026-06-14  Arch. Ohnaka  Add : Since the stay counter may have              //
                        //      already started counting due to StaySet, in that case,                  //
                        //      if it's a prescaler tick, the stay counter needs to be incremented.     //
                        // =============================================================================//
                        if ( window_open && presc_tick ) begin                                          //
                            stay_cnt <= stay_cnt + 1'b1;                                                //
                        end                                                                             //
                        // =============================================================================//
                    end
                    // --------------------------------------------------------
                    //  Branch (opcode 2) — conditional state transition
                    // --------------------------------------------------------
                    OP_BRANCH: begin
                        timing_signals <= tsig;
                        if (condition) begin
                            // Condition true => no branch (C2-F5)
                            state_num <= state_num + 1'b1;
                        end else if (operand == 12'd0) begin
                            // Self-loop / wait-for-Condition (no auto-save)
                            state_num <= state_num;
                        end else begin
                            // Branch taken => auto-save the branch address
                            // (Return restores saved+1), jump forward.
                            save_or_set(state_num, 1'b0,
                                        state_num + operand);
                        end
                    end
                    // --------------------------------------------------------
                    //  Jump (opcode 3) — unconditional (operand 0 = indirect,
                    //  handled by need_indirect above)
                    // --------------------------------------------------------
                    OP_JUMP: begin
                        // =============================================================================//
                        // REVISION HISTORY  006                                                        //
                        // 2026-06-15  Arch. Ohnaka  Add :This defines the execution of JUMP            //
                        //      as a Que command, background command, and foreground command.           //
                        // =============================================================================//
                        if (in_queued_band) begin  // After Prog End inside Stay window: queue a Jump   // (immediate target).
                            queued_valid  <= 1'b1;                                                      //
                            queued_opcode <= OP_JUMP;                                                   //
                            queued_target <= operand;                                                   //
                            state_num     <= state_num + 1'b1;                                          //
                        end                                                                             //    
                        else if (window_open) begin  // Inside Stay window: treat as background command // (immediate target).
                            state_num      <= operand;  // Advance to the target immediately,           // but do NOT present tsig (C3-T1 B). 
                        end                                                                             //
                        else begin  // Outside Stay window: treat as foreground command                 // (immediate target).
                            timing_signals <= tsig;  // Present tsig immediately (C3-T1 A),             // but advance to the target only on the next prescaler tick (C4-T4 lean B).
                            if (presc_tick) begin  // Advance to the target on the next prescaler tick  // (C4-T4 lean B)
                                state_num      <= operand;     // absolute target                       //
                            end                                                                         //   
                        end                                                                             //
                        // =============================================================================//                           
                    end
                    // --------------------------------------------------------
                    //  Reserved opcodes 4-F: treated as NOP (advance)
                    // --------------------------------------------------------
                    default: begin
                        timing_signals <= tsig;
                        state_num      <= state_num + 1'b1;
                    end
                    endcase
                end
            end

            // ================================================================
            //  S_WAIT — sit at the Stay state, tick the (prescaled) counter
            // ================================================================
            S_WAIT: begin
                if (presc_tick) begin
                    if (stay_cnt == (stay_target - 1'b1)) begin
                        // ---- Stay-timeup -----------------------------------
                        stay_cnt_match <= 1'b1;
                        stay_cnt       <= {(CNT_W+1){1'b0}};  // Add : Clear stay counter and match flag; close the window. - RH 002 Arch. Ohnaka (2026-06-14 22:06)
                        window_open    <= 1'b0;
                        prog_end_seen  <= 1'b0;
                        queued_valid   <= 1'b0;
                        fsm            <= S_RUN;

                        // Apply a queued Loop's counter update. The resume target
                        // itself is computed by the combinational resume_addr wire.
                        if (queued_valid && (queued_subop == SUB_LOOP)) begin
                            if (loop_exits(loop_cnt, queued_target)) begin
                                loop_cnt       <= {LOOP_W{1'b0}};
                                loop_cnt_match <= 1'b1;
                            end else begin
                                loop_cnt    <= loop_cnt + 1'b1;
                            end
                        end

                        // Deferred insertion (C3-F20). Honour only when the
                        // holding register is free (else the request is held).
                        if (insert_req && !hr_occupied) begin
                            hr_state    <= resume_addr;
                            hr_loop     <= loop_cnt;
                            hr_base     <= base_addr;
                            hr_ins      <= 1'b1;
                            hr_occupied <= 1'b1;
                            state_num   <= insert_target;
                            insert_ack  <= 1'b1;
                        end else begin
                            state_num   <= resume_addr;
                        end
                    end else begin
                        stay_cnt <= stay_cnt + 1'b1;
                    end
                end
            end

            // ================================================================
            //  S_IND — wait for the external indirect-read result
            // ================================================================
            S_IND: begin
                if (indirect_ready) begin
                    fsm <= S_RUN;
                    if (ind_is_loop) begin
                        if (loop_exits(loop_cnt, {{(LOOP_W-ADDR_W){1'b0}}, indirect_data})) begin
                            loop_cnt       <= {LOOP_W{1'b0}};
                            loop_cnt_match <= 1'b1;
                            state_num      <= state_num + 1'b1;
                        end else begin
                            loop_cnt  <= loop_cnt + 1'b1;
                            state_num <= base_addr;
                        end
                    end else begin
                        state_num <= indirect_data;  // indirect Jump target
                    end
                end
            end

            // ================================================================
            //  S_PUSH — spill the occupied holding register to external stack,
            //           then store the pending new context (auto-save nesting)
            // ================================================================
            S_PUSH: begin
                stack_push_req <= 1'b1;             // hold request until ack
                if (stack_ack) begin
                    stack_push_req <= 1'b0;
                    hr_state    <= pend_state;
                    hr_loop     <= pend_loop;
                    hr_base     <= pend_base;
                    hr_ins      <= pend_ins;
                    hr_occupied <= 1'b1;
                    stack_depth <= stack_depth + 16'd1;
                    state_num   <= pend_target;
                    if (pend_is_insert) insert_ack <= 1'b1;
                    fsm         <= S_RUN;
                end
            end

            // ================================================================
            //  S_POP — refill the holding register from the external stack
            // ================================================================
            S_POP: begin
                stack_pop_req <= 1'b1;
                if (stack_ack) begin
                    stack_pop_req <= 1'b0;
                    {hr_ins, hr_base, hr_loop, hr_state} <= stack_rdata;
                    hr_occupied   <= 1'b1;
                    stack_depth   <= stack_depth - 16'd1;
                    fsm           <= S_RUN;
                end
            end

            default: fsm <= S_RUN;
            endcase
        end
    end

    // ========================================================================
    //  Auto-save helper (task): save the current context (or spill to stack if
    //  the holding register is already occupied) and set the jump target.
    //
    //   save_state : the return address to record (return-to-after = addr+1)
    //   ins        : the "saved-by-insertion" flag (C3-T7)
    //   target     : where execution continues immediately after the save
    // ========================================================================
    task save_or_set;
        input [ADDR_W-1:0] save_state;
        input              ins;
        input [ADDR_W-1:0] target;
        begin
            if (hr_occupied) begin
                // Spill the existing context first (implicit push, C3-T6 lean A).
                pend_state     <= save_state;
                pend_loop      <= loop_cnt;
                pend_base      <= base_addr;
                pend_ins       <= ins;
                pend_target    <= target;
                pend_is_insert <= 1'b0;
                stack_push_req <= 1'b1;
                fsm            <= S_PUSH;
            end else begin
                hr_state    <= save_state;
                hr_loop     <= loop_cnt;
                hr_base     <= base_addr;
                hr_ins      <= ins;
                hr_occupied <= 1'b1;
                state_num   <= target;
            end
        end
    endtask

endmodule

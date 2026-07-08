# PTSG-Core — Reference Verilog (Top Layer) / リファレンス Verilog（トップ層）

> **License: MIT** (Layer 3 sample implementation — illustrative, not normative).
> One possible implementation of the PTSG Core, not *the* implementation.
>
> **ライセンス：MIT**（第3層サンプル実装——例示的であり規範的ではない）。
> PTSGコアの一つの可能な実装であり、*唯一の*実装ではない。

This directory contains a single synthesizable **top-level** Verilog module that
realises the PTSG-Core specification (Layer 1, Chapters 1–5) and a self-checking
testbench.

本ディレクトリは、PTSGコア仕様（第1層、第1〜5章）を実現する単一の合成可能な
**トップ層** Verilog モジュールと、自己チェックテストベンチを含む。

| File | Purpose |
|---|---|
| `ptsg_core.v` | The PTSG-Core top-level module (decoder, 4 opcodes, 8 internal sub-opcodes, Stay-window/background execution, prescaler, counters + match flags, holding register + external-stack nesting, external buses). Instruction memory lives in the `ptsg_imem` wrapper (`../ai_friendly_vendor_wrappers/ptsg_imem/`). |
| `ptsg_core_tb.v` | Self-checking functional testbench, PRESCALE=1 (blink, counted Loop, Branch wait, Call/Return, indirect Jump). |
| `ptsg_core_conformance_tb.v` | Layer-1 v1.1 **conformance regression** testbench, PRESCALE=5 (duty idiom D 25:25, in-window On-Tick counting, FG prescaling of Branch, BG timing-signal hold, C3-F20 insertion deferral, 16-bit Loop, Q-band NOP, FG/Q/BG Reset banding, queued-Reset priority, indirect-Jump banding, queued-Branch taken/not-taken/self-loop, queued-Call, queued-Return shallow/S_POP, Q-slot SN-overwrite HALT, FG-illegal Global HALT, S_HALT insertion rescue, stray/FG Prog End HALT, unpaired Base Set<->Loop HALT (BG and Q), Stay Start State register + queued-Base-Set self-loop, BG/Q Stay Set re-kick tick-gating/tsig-hold/counter-continuation). Run this after any change to `ptsg_core.v`. |
| `examples/` | Instruction-list examples (`.hex` for simulation, `.mif` for Quartus) plus their own testbench and README. |

## Quick start / クイックスタート

```sh
# Icarus Verilog (https://steveicarus.github.io/iverilog/) — from this directory:
iverilog -g2012 -o sim ptsg_core.v ptsg_core_tb.v \
    ../ai_friendly_vendor_wrappers/ptsg_imem/ptsg_imem.v
vvp sim
# Expected:
#   PASS A..E, ALL TESTS PASSED

# Conformance regression (prescaled timing contracts, PRESCALE=5):
iverilog -g2012 -o simc ptsg_core.v ptsg_core_conformance_tb.v \
    ../ai_friendly_vendor_wrappers/ptsg_imem/ptsg_imem.v
vvp simc
# Expected: PASS T1..T31, ALL CONFORMANCE TESTS PASSED
```

Simulation requires `IMEM_VENDOR="SIM"` on the `ptsg_core` instance (the default
`"M10K"` targets Cyclone V `altsyncram` + the In-System Memory Content Editor).

For Quartus / Cyclone V, instantiate `ptsg_core` and initialise the instruction
memory with a `.mif` (set the `INIT_FILE` parameter for simulation `$readmemh`,
or use the In-System Memory Content Editor to reprogram via JTAG without
re-synthesis — the workflow PTSG is designed around).

## Instruction word (Chapter 2 §2.2) / 命令語

```
 31                              16 15                  4  3      0
 ┌────────────────────────────────────┬────────────────────┬─────────┐
 │       Timing Signals (D16–D31)     │   Operand (D4–D15) │ Opcode  │
 └────────────────────────────────────┴────────────────────┴─────────┘
```

Opcodes: `0` Global, `1` Stay, `2` Branch, `3` Jump (4–F reserved).
Global internal sub-opcodes (D4–D7 = 0, selector in D8–D15):
`0` Reset, `1` Base Set, `2` Stay Set, `3` Return, `4` Sub-sequence Call,
`5` Loop, `6` Prog End, `7` NOP. Global external sub-opcodes use D4–D7 = 1–F
and drive the external-operation bus (assignments are Formation-specific).

## Parameters / パラメータ

| Parameter | Default | Meaning |
|---|---|---|
| `ADDR_W` | 12 | State-number / address width (Fixed by Core) |
| `DATA_W` | 32 | Instruction word width (Fixed by Core) |
| `TSIG_W` | 16 | Timing-signal bus width (Fixed by Core) |
| `CNT_W` | 12 | Stay counter width (12-bit operand D4–D15) |
| `LOOP_W` | 16 | Loop counter/target width — full D16–D31 extended operand (architect ruling 2026-07-07; supersedes the 12-bit C3-V2 reading) |
| `IMEM_DEPTH` | 256 | Instruction-memory depth (≤ 4096) |
| `PRESCALE` | 5 | System-clock divider for the time axis (C4-T2 option A, compile-time fixed) |
| `PRESC_W` | 32 | Prescaler counter width |
| `INIT_FILE` | `"blinky_with_prescaler.hex"` | `$readmemh` init file (SIM branch) |
| `INIT_FILE_MIF` | `""` | `.mif` init file (M10K branch) |
| `IMEM_VENDOR` | `"M10K"` | Instruction-memory branch: `"M10K"` (Cyclone V + ISMCE) or `"SIM"` |
| `IMEM_EDGE` | `"NEG"` | Half-cycle imem read — effectively combinational for the posedge FSM |

## Tie resolutions in this implementation / 本実装での Tie 解決

The Layer 1 specification leaves a number of decisions open as **Ties**. This
reference resolves them according to the contributor's documented leans:

本リファレンスは、仕様が開いたままにする **Tie** を、貢献者の文書化された傾向に
従って解決する：

| Tie | Choice |
|---|---|
| C5-V1 reset polarity | active-high |
| C5-V2 clock edge | rising edge |
| C5-V3 reset | synchronous |
| C5-V5 `state_number` | registered |
| C3-T1 timing-signal hold | Stay state's D16–D31 during the wait (lean A) |
| C3-T2 queued-op order | FIFO (single queued slot implemented) |
| C3-T4 min-stay violation | Core proceeds (no stall on `ext_op_ready`) |
| C3-T6 stack push/pop | implicit (Core auto-pushes/pops, with stall) |
| C3-T7 insertion flag | Core carries the "saved-by-insertion" bit |
| C3-F20 insertion timing | deferred to Stay-timeup inside a Stay window |
| C4-T1 indirect handshake | Core stalls until `indirect_ready` |
| C4-T2 prescaler config | compile-time fixed (`PRESCALE`) |
| C4-F10 Stay Set role (was Tie C4-T4) | clear/sync-only; the counter counts prescaler ticks On-Tick from Stay Set through the window (RH003/004/005 + A4 hoist RH011) |
| C3-F22 Reset bands (PROVISIONAL) | FG/BG fire immediately, no tick-gate. **Open interpretation, flagged for architect review:** a BG Reset panics State Number to 0 but leaves the Stay window open — the §3.4b table only arms the stay counter for BG Reset and is silent on window state (RH014, conformance test T10). |
| Queued Reset priority (architect ruling 2026-07-08) | A queued Reset is reserved independently of the shared Loop/Jump queue slot and wins with absolute priority at Stay-timeup — any queued Loop/Jump/insertion is discarded and Reset performs a fully destructive clear (RH015, conformance test T11). |
| Stay Set band-split (Phase 6, PROVISIONAL) | FG re-kicks fresh (drives tsig, resets the stay counter, immediate). BG re-kicks an already-open window (holds tsig, resets the counter, but is now tick-gated — waits for the next prescaler tick, like FG Branch/Jump/Reset). Q re-kicks too (holds tsig, does NOT reset the counter — it simply continues On-Tick — and advances immediately, full clock). `window_open`/`prog_end_seen`/`queued_valid`/`base_pending`/`q_base_pending` re-arm identically in all three bands, matching the pre-Phase-6 behavior the table is silent on (RH026, conformance tests T30/T31). |

## Error HALT / エラーHALT（C3-F23, C3-F24）

The Core traps a defined class of illegal-instruction conditions instead of
running them: **C3-F23** (the FG-Global exclusion principle) says only
Reset, Stay Set and NOP are legal as foreground (outside-a-window) Global
commands — Base Set, Return, Sub-sequence Call, Loop and Prog End are
window-only. This implementation detects the FG-illegal case for Base Set,
Return, Call, Loop and Prog End, a stray/duplicate Prog End scanned while
already in the Q band, (C3-F26/C8) a second Q-band State-Number reservation
(Loop/Jump/Branch/Call/Return) scanned while an earlier one is still
pending, and (C3-F24) an unpaired Base Set<->Loop across bands in both
directions: a BG Base Set that a BG Loop never actually exits before the
window reaches Prog End, and a Q Base Set with no Q Loop ever reserved to
consume it before Stay-timeup — and enters a dedicated
**`S_HALT`** state per **C3-F24**: State Number holds at the violating
instruction, the registered `error_flag` output is raised, and the FSM
stays there — the same capture a SignalTap trigger would want — until
either a hardware reset or an `insert_req` rescues the core (insertion
clears `error_flag` and jumps via the normal auto-save path, so a
supervising Formation can log the fault and resume at a known-good handler
address). A rescue handler that itself ends in a Return must open its own
Stay window first (Stay Set is always FG-legal) — Return remains
window-only even when reached via an insertion.

コアは、命令として実行する代わりに罠にかける、定義済みの違法命令クラスを持つ。
**C3-F23**（FG-Global排他原則）は、フォアグラウンド（窓外）のGlobalコマンドとして
合法なのは Reset・Stay Set・NOP のみであり、Base Set・Return・サブシーケンスCall・
Loop・Prog End はウィンドウ限定であると規定する。本実装は Base Set・Return・Call・
Loop・Prog End についてFG違法条件を検出し、Q帯域内で既にProg Endを一度消費した後の
迷子・重複Prog Endを検出し、（C3-F26/C8）先に予約されたQ帯域 State Number
予約（Loop/Jump/Branch/Call/Return）がまだ発火していないうちに二つ目の予約が
来た場合を検出し、さらに（C3-F24）帯域を跨いで対にならない Base Set↔Loop を
両方向で検出する——BG の Base Set が対応する BG Loop によって一度も抜けられない
まま窓が Prog End に至った場合、および Que の Base Set にそれを消費する Que の
Loop が Stay-timeup までに一度も予約されなかった場合——うえで、**C3-F24** に従って
専用の
**`S_HALT`** ステートに入る：State Numberは違反命令で保持され、レジスタ化された
`error_flag` 出力が立ち、ハードウェアリセットか `insert_req` がコアを救出する
までFSMはそこに留まる（挿入は `error_flag` をクリアし、通常の自動保存経路で
ジャンプするため、監督Formationは障害を記録し既知の正常なハンドラアドレスから
再開できる）。Returnで終わる救出ハンドラは、自身のStay窓を先に開く必要がある
（Stay SetはFGでも常に合法）——挿入経由で到達した場合でも、Returnはウィンドウ
限定のままである。

| RTL name | Kind | Meaning |
|---|---|---|
| `error_flag` | output, registered | Raised on entering `S_HALT`; held until insertion or hardware reset (C3-F24) |
| `S_HALT` (fsm=5) | internal state | Runaway-error trap; State Number frozen at the violating instruction |

## Stay Start State register / Stay Start Stateレジスタ（C3-F25, PROVISIONAL）

A small register giving the time axis its own notion of "here": a **foreground**
Stay Set writes its own State Number to `stay_start_state`; a BG/Q Stay Set
(one that re-arms a window already open — e.g. as a Call or Loop target) does
not touch it. The value is valid only within that same Stay cycle: if a
**queued** Base Set executes before the next Stay Set, it loads
`base_addr := stay_start_state` (the time-axis origin) instead of the BG Base
Set's `base_addr := current State Number` (the space-axis origin) — so a
queued Loop that has not yet exited jumps back to the *window's own Stay Set*,
re-running the whole Stay period, not just resuming a scan position. This is
the "single-period self-loop" pattern (`StaySet → ProgEnd → BaseSet(Q) →
Loop(Q) → Stay`): Stay's 12-bit operand × Loop's 16-bit operand gives 2^28
clocks of exact, prescaler-free timing in five instructions. If no queued
Base Set ever runs, the next Stay Set simply overwrites `stay_start_state`.
Reset value 0; no Core-level external visibility (a Formation may copy it to
a general register to expose it).

時間軸に固有の「ここ」を与える小さなレジスタ：**前景**の Stay Set が自身の State
Number を `stay_start_state` に書き込む；BG/Q の Stay Set（Call や Loop の標的として
既に開いている窓を再アームするもの）はこれに触れない。値はその Stay サイクル内
でのみ有効：次の Stay Set より前に **Que** の Base Set が実行されれば、BG Base Set の
`base_addr := 現 State Number`（空間軸起点）ではなく `base_addr := stay_start_state`
（時間軸起点）をロードする——結果、まだ抜けていない Que の Loop はスキャン位置
ではなく**窓自身の Stay Set** へ戻り、Stay 期間全体を再実行する。これが「単一期間
自己ループ」パターン（`StaySet → ProgEnd → BaseSet(Q) → Loop(Q) → Stay`）：Stay の
12bit オペランド × Loop の 16bit オペランドで、命令五語のままプリスケーラなしの
2^28 クロックの精密タイミングが得られる。Que の Base Set が一度も実行されなければ
次の Stay Set が単に `stay_start_state` を上書きする。リセット値 0；Core レベルの
外部可視性なし（Formation は汎用レジスタへコピーして可視化できる）。

| RTL name | Kind | Meaning |
|---|---|---|
| `stay_start_state` | internal register | Set by a FG Stay Set only; consumed by a queued Base Set (C3-F25) |
| `q_base_pending` | internal register | Set by a Q Base Set; cleared once a Q Loop is reserved; HALTs at Stay-timeup if still 1 (Q half of the Base Set<->Loop pairing check, C3-F24) |

**Open memo (architect, 2026-07-08) / 備忘録（アーキテクト、2026-07-08）:** the
`q_base_pending` HALT condition above is this implementer's best-effort
substitute for spec prose ("a queued Base Set whose Loop lies in the BG
window") that could not be pinned down with confidence — BG is always
chronologically earlier than Q within one window, so how that literal
condition arises is unclear. More broadly, Q-execution Loop semantics —
nested Q Loops in particular — are genuinely undecided at the spec level
(multiple open design questions), and are deliberately **deferred**: this
whole area is planned follow-up work once the current "33-item" conformance
alignment this PR belongs to is complete. Treat the current HALT condition
as provisional, not a confirmed reading, until that follow-up lands.

**備忘録（アーキテクト、2026-07-08）:** 上記の `q_base_pending` HALT 条件は、
「Que の Base Set の Loop が BG ウィンドウ内にある」という仕様文言を確信を
持って特定できなかったための、実装者による最善の代替である——一つの窓の中で
BG は Q より時系列的に必ず先に来るため、その文言通りの状況がどう発生し得るのか
不明である。より広く言えば、Que 実行の Loop 意味論——特に入れ子の Que Loop——は
仕様レベルでもまだ本当に未決定であり（複数の未解決の設計課題がある）、意図的に
**先送り**されている：この領域全体は、本PRが属する「33枠」の適合作業が完了した
後の宿題として計画されている。その宿題が着地するまで、現在のHALT条件は確定した
読みではなく仮のものとして扱うこと。

## Deliberate simplifications / 意図的な簡略化

This is a readable reference, not a fully-elaborated production core. The
following are faithful to the canonical patterns but simplified:

- **Queued band (after Prog End)** implements a single queued-operation slot
  shared by the canonical queued **Loop**, **Jump**, **Branch** (Phase 3a —
  taken auto-saves + jumps, with the operand-0 self-loop idiom correctly
  exempted per C2-F5, not-taken, Condition evaluated live at Stay-timeup per
  §3.4b's Branch Q row), **Call** (Phase 3b — unconditional, plain auto-save
  + jump at Stay-timeup), and **Return** (Phase 3c — restores the live
  holding-register context at Stay-timeup, including the S_POP fallback for
  a deeper stacked context). **Reset** is queued separately (its own
  independent reservation, not sharing this slot) and wins with absolute
  priority at Stay-timeup over whatever the slot holds. Per C3-F26/C8, the
  FIRST SN reservation in a fresh window's Q band always succeeds
  (last-write-wins into an empty slot), but a SECOND SN reservation (Loop/
  Jump/Branch/Call/Return) scanned while one is already pending HALTs
  instead of silently overwriting it (Phase 4d).
- **Indirect read for a queued Loop or Jump** is not performed; a queued Loop
  uses its literal D16–D31 target (`0` ⇒ zero iterations, C4-V1), and a queued
  Jump(0) is treated the same way — queued as the literal address 0, not
  resolved indirectly (RH016; fixes a bug where a Q-band Jump(0) used to
  hijack the FSM into the indirect-read state mid-scan instead of deferring
  to Stay-timeup like every other queued command).
- **Base Set** keeps a single-level base (sets the base and advances). Because a
  loop re-enters the Base Set state each iteration, Base Set is idempotent and
  does not spill the previous base to the external stack; nested-loop
  base-stacking is therefore not provided. (Branch / Call / Insertion auto-save
  and external-stack nesting **are** implemented.) A BG Base Set must be paired
  with a BG Loop that actually exits before the window's Prog End, and a Q
  Base Set must be paired with a Q Loop reserved before Stay-timeup, or either
  HALTs (C3-F24, Phase 4e/5). Q Base Set loads `Base := Stay Start State`
  (C3-F25) rather than the BG case's `Base := current State Number` — see the
  Stay Start State section above.
- **Instruction memory** is the `ptsg_imem` wrapper with `EDGE="NEG"` (half-cycle
  read): from this posedge FSM's viewpoint it behaves like a combinational read,
  so the single-phase FSM needs no fetch stage. Foreground commands advance on
  the prescaler tick (C4-F8), in-window background commands at full clock (C4-F3).
- The **external-stack `stack_data`** bidirectional bus of Chapter 5 is split
  into uni-directional `stack_wdata` / `stack_rdata` for clean synthesis; a
  Formation may tie them to a single `inout` if preferred.

## Regeneration note / 再生成についての注

Per Open Prompt: reading Layers 1 & 2 and re-implementing the Core from scratch
yields **your own** independent work, not a derivative of this sample. Use this
file for comparison, not as a fork starting point.

Open Prompt に従う：第1・2層を読み、コアをゼロから再実装したものは、このサンプルの
派生物ではなく**あなた自身の**独立した著作物である。本ファイルはフォークの起点では
なく比較のために用いること。

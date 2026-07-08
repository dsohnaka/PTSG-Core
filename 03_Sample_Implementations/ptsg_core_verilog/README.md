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
| `ptsg_core_conformance_tb.v` | Layer-1 v1.1 **conformance regression** testbench, PRESCALE=5 (duty idiom D 25:25, in-window On-Tick counting, FG prescaling of Branch, BG timing-signal hold, C3-F20 insertion deferral, 16-bit Loop, Q-band NOP, FG/Q/BG Reset banding, queued-Reset priority, indirect-Jump banding). Run this after any change to `ptsg_core.v`. |
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
# Expected: PASS T1..T14, ALL CONFORMANCE TESTS PASSED
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

## Deliberate simplifications / 意図的な簡略化

This is a readable reference, not a fully-elaborated production core. The
following are faithful to the canonical patterns but simplified:

- **Queued band (after Prog End)** implements a single queued-operation slot and
  supports the canonical queued **Loop** and **Jump**. **Reset** is queued
  separately (its own independent reservation, not sharing this slot) and wins
  with absolute priority at Stay-timeup over whatever the slot holds. Other
  internal-mode commands placed after Prog End execute immediately (documented
  deviation; generalizing the shared slot to all commands, with SN-overwrite
  HALT, is Phase 3 / C8 work).
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
  and external-stack nesting **are** implemented.)
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

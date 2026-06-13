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
| `ptsg_core.v` | The PTSG-Core top-level module (instruction memory, decoder, 4 opcodes, 8 internal sub-opcodes, Stay-window/background execution, prescaler, counters + match flags, holding register + external-stack nesting, external buses). |
| `ptsg_core_tb.v` | Self-checking testbench (blink, counted Loop, Branch wait, Call/Return, indirect Jump). |
| `examples/` | Instruction-list examples (`.hex` for simulation, `.mif` for Quartus) plus their own testbench and README. |

## Quick start / クイックスタート

```sh
# Icarus Verilog (https://steveicarus.github.io/iverilog/)
iverilog -g2012 -o sim ptsg_core.v ptsg_core_tb.v
vvp sim
# Expected:
#   PASS A: blink toggled ...
#   PASS B: loop exited, loop_counter=0
#   PASS C: branch advanced on condition
#   PASS D: call/return reached return-to-after ...
#   PASS E: indirect jump landed at 7
#   ALL TESTS PASSED
```

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
| `CNT_W` | 12 | Stay / loop counter width (C3-V2) |
| `IMEM_DEPTH` | 256 | Instruction-memory depth (≤ 4096) |
| `PRESCALE` | 1 | System-clock divider for the time axis (C4-T2 option A, compile-time fixed) |
| `PRESC_W` | 32 | Prescaler counter width |
| `INIT_FILE` | `""` | `$readmemh` init file (simulation) |

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
| C4-T4 Stay Set role | clear/sync only — stay counter ticks only during the wait (jitter-free, lean B) |

## Deliberate simplifications / 意図的な簡略化

This is a readable reference, not a fully-elaborated production core. The
following are faithful to the canonical patterns but simplified:

- **Queued band (after Prog End)** implements a single queued-operation slot and
  supports the canonical queued **Loop**. Other internal-mode commands placed
  after Prog End execute immediately.
- **Indirect read for a queued Loop** is not performed; a queued Loop uses its
  literal D16–D31 target (`0` ⇒ zero iterations, C4-V1).
- **Base Set** keeps a single-level base (sets the base and advances). Because a
  loop re-enters the Base Set state each iteration, Base Set is idempotent and
  does not spill the previous base to the external stack; nested-loop
  base-stacking is therefore not provided. (Branch / Call / Insertion auto-save
  and external-stack nesting **are** implemented.)
- **Instruction memory** uses a single-cycle (asynchronous) read model for
  clarity. On Cyclone V this maps to a registered M10K block; the fetch stage can
  be pipelined without changing the externally-visible contract (the
  1-clock-per-opcode Convention C2-T4).
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

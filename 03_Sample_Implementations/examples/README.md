# PTSG-Core — Instruction List Examples / 命令列の例

> **License: MIT** (Layer 3 sample). Illustrative reference programs for the
> reference Verilog core in the parent directory.
>
> **ライセンス：MIT**（第3層サンプル）。親ディレクトリのリファレンス Verilog
> コア用の、例示的なリファレンスプログラム。

Each program is provided in two forms with identical content:

| Form | Use |
|---|---|
| `*.hex` | Simulation — load with `$readmemh` (the testbench and the core's `INIT_FILE` parameter both use this). |
| `*.mif` | Quartus — Memory Initialization File for the instruction BRAM; also reprogrammable in-system over JTAG with the In-System Memory Content Editor (no re-synthesis). |

Run all examples through the core:

```sh
iverilog -g2012 -o exsim ../ptsg_core.v examples_tb.v && vvp exsim
# => ALL EXAMPLE PROGRAMS VERIFIED
```

## Instruction-word encoding recap (Chapter 2 §2.2)

```
 31                              16 15                  4  3      0
 ┌────────────────────────────────────┬────────────────────┬─────────┐
 │       Timing Signals (D16–D31)     │   Operand (D4–D15) │ Opcode  │
 └────────────────────────────────────┴────────────────────┴─────────┘
```

`word = (timing_signals << 16) | (operand << 4) | opcode`

| Opcode | Encoding helper |
|---|---|
| Stay N | `(tsig<<16) | (N<<4) | 1` (N = 0 ⇒ 4096 ticks) |
| Branch off | `(tsig<<16) | (off<<4) | 2` (off = 0 ⇒ self-loop) |
| Jump addr | `(tsig<<16) | (addr<<4) | 3` (addr = 0 ⇒ indirect) |
| Global internal sub-op S | `(ext<<16) | (S<<8) | 0` (D4–D7 = 0; ext = D16–D31) |
| Global external sub-op M | `(data<<16) | (subop8<<8) | (M<<4) | 0` (M = 1–15) |

Internal sub-ops S: `0` Reset, `1` Base Set, `2` Stay Set, `3` Return,
`4` Sub-sequence Call, `5` Loop, `6` Prog End, `7` NOP.

## The programs / 各プログラム

### `blinky_with_prescaler` — the "graduated from counter-Lチカ" example
NOP-on → Stay → NOP-off → Stay → Jump back. With `PRESCALE = 50000` on a 50 MHz
clock, `Stay 500` gives ~0.5 s half-periods. The whole blinker is five
instructions and every quantity (state number, stay counter, timing signals) is
externally observable — the pedagogical point of Chapter 1 §1.8.

### `conditional_branching` — wait-for-Condition
`Branch 0` self-loops until the external `condition` input is true (the canonical
"wait for ready" idiom, C2-F5), pulses a timing signal, then `Reset`s to wait
again. Drive `condition` from external logic indexed by `state_number`.

### `sub_sequence_branching` — Call / Return
`Sub-sequence Call` (offset in D16–D31) jumps to a subroutine and auto-saves the
return context; `Return` restores it to the instruction *after* the call
(return-to-after, C3-F12).

### `multi_signal_timing` — coordinated timing signals
Four `Stay` states each present a different `timing_signals` value, producing a
walking-ones pattern held for the stay duration — multiple coordinated outputs
within one linear sequence (no FSM mesh).

### `background_execution` — a Global runs during a Stay
`Stay Set` opens a Stay window; the following external-mode Global is
background-executed (drives the external-operation bus for one clock) while the
subsequent `Stay` provides the hold time. External sub-opcode 1 is the
cross-Formation "external register write" convention (Chapter 2 §2.7); its
concrete meaning is defined by a Formation, so on the bare Core this example only
exercises the bus signalling.

## A note on Formations / フォーメーションについての注

`background_execution` uses an *external* sub-opcode whose meaning is
Formation-specific. The other four programs use only Core opcodes and run
identically on any Formation. This is the Core-Formation separation in practice:
the instruction *vocabulary* is invariant; the external-operation *meanings* are
supplied per Formation.

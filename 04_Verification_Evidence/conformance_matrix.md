# PTSG-Core Conformance Matrix / 適合マトリクス

> The front door of Layer 4. Every Layer 1 decision (Fixed / Convention / Tie) mapped to its
> verification state. This table makes both **what is verified** and **what is not** visible
> at a glance.
>
> Layer 4 の玄関口。すべての Layer 1 決定(Fixed / Convention / Tie)をその検証状態に対応づける。
> 本表は**何が検証済みか**と**何が未検証か**の両方を一目で可視にする。

**Last updated / 最終更新:** 2026-06-12 (Layer 4 opened) / (Layer 4 開設)

## Legend / 凡例

| State | Meaning |
|---|---|
| ⬜ **untested** | No evidence yet / まだ証拠なし |
| 🟡 **sim** | Passed in simulation (ModelSim/Icarus), not yet on silicon / シミュレーション通過、実機未 |
| 🟢 **silicon** | Passed on real hardware / 実機通過 |
| 🔴 **anomaly** | Evidence revealed a discrepancy; under investigation / 不一致が判明、調査中 |
| ◽ **n/a** | Not separately testable (structural/definitional) / 個別検証対象外(構造的/定義的) |

Each non-blank state links to the evidence entry that earned it (path under
`modelsim/runs/` or `signaltap/`).

各空白でない状態は、それをもたらしたエビデンス項目(`modelsim/runs/` または `signaltap/` 配下の
パス)にリンクする。

---

## Verification priority queue / 検証優先キュー

Derived from the 2026-06-02 audit coverage holes and the Layer 2 resumption hooks. Worked
top to bottom; #1 first to establish silicon trust, #2 as a quick win to settle the workflow.

2026-06-02 監査のカバレッジ穴と Layer 2 再開フックから導出。上から順に着手;#1 を最初に
(実機の信頼を確立)、#2 を勝ち戦として(ワークフローを固める)。

| # | Target | Source | Primary tool | conformance_suite entry |
|---|---|---|---|---|
| 1 | Prescaler phase jitter / プリスケーラ位相ジッタ | Hook A (2026-06-11) | SignalTap | `prescaler_phase_measurement/` |
| 2 | Match flags (loop/stay/prescaler) / 一致フラグ | Audit hole #4 | ModelSim | `match_flag_assertions/` *(planned)* |
| 3 | External-stack two-level nesting / 外部スタック二段ネスト | Audit hole #2 | ModelSim | `nested_call_two_levels/` *(planned)* |
| 4 | Prog End queued band / Prog End キュー帯域 | Audit hole #1 | both | `prog_end_queued_band/` *(planned)* |
| 5 | Base Set idempotency / Base Set 冪等性 | Build Log #5 (CC self-flag) | both | `base_set_idempotency_probe/` *(planned)* |
| 6 | Insertion mechanism / 挿入機構 | Audit hole #3 | ModelSim | `insertion_during_long_stay/` *(planned)* |

---

## Chapter 2 — Memory Layout & Opcode Set / メモリレイアウト・オペコードセット

| ID | Decision (abbrev.) | State | Evidence |
|---|---|---|---|
| C2-F1..F7 | Instruction word, 4 opcodes, operand fields | 🟡 sim | blinky/conditional/multi_signal exercise these (Build Log #5 TB) |
| C2-F3 | Stay literal-zero-as-escape = 4096 | ⬜ | (not yet exercised: no program uses Stay 0) |
| C2-F5 | Branch operand-0 = self-loop / wait | 🟡 sim | conditional_branching |
| C2-F8/F11 | Global dual structure + D16–D31 extended operand | 🟡 sim | sub_sequence (Call offset via D16–D31) |
| C2-F12 | Sub-sequence Call reach 4095 (v1.1 fix) | ⬜ | (only small offsets exercised) |
| C2-F13 | Loop up-count semantics (v1.1) | ⬜ | **queued for #2/#4** — count not yet asserted |
| C2-T3 → C5-T1 | Glitch-free transitions | ⬜ | (pin-level; needs targeted capture) |
| C2-T4 | 1-clock-per-opcode latency | 🟢 silicon | **affirmed indirectly**: aligned fetch confirms 1-clock advance (Build Log #6) |

## Chapter 3 — Sub-Opcode & Background Execution / サブオペコード・裏実行

| ID | Decision (abbrev.) | State | Evidence |
|---|---|---|---|
| C3-F2/F3/F4 | Prog End scheduling model (v1.1 revised) | 🔴 anomaly | **queued band implements Loop only** (audit + Build Log #6); silicon impact untested → #4 |
| C3-F11 | Base Set auto-save | 🔴 anomaly | idempotency ambiguity surfaced by Claude Code → #5 |
| C3-F12 | Return-to-after (+1) vs Insertion (+0) | 🟡 sim | Call/Return TB; insertion path untested → #6 |
| C3-F16 | Single primary loop counter (v1.1) | ⬜ | → #2/#3 |
| C3-F17 | Up-count + auto-clear (v1.1) | ⬜ | → #2 |
| C3-F18 | Match flags 1-clock pulse (v1.1) | ⬜ | → #2 |
| C3-F19 | Prog End command (v1.1) | ⬜ | → #4 |
| C3-F20 | Insertion deferred to Stay-timeup (was C3-T8) | ⬜ | → #6 |
| External-stack nesting (S_PUSH/S_POP) | RTL path | ⬜ | **large untested RTL region** → #3 |

## Chapter 4 — Indirect Addressing & Prescaler / 間接アドレッシング・プリスケーラ

| ID | Decision (abbrev.) | State | Evidence |
|---|---|---|---|
| C4-F1 | Prescaler necessity | 🟢 silicon | blinky runs at PRESCALE=50000 on DE10-nano |
| C4-F2 | Loop not prescaled | ⬜ | → #2 (alongside match flags) |
| C4-F5 | Indirect Jump (operand 0) | 🟡 sim | indirect-Jump TB (Build Log #5) |
| C4-F6 | Indirect Loop target (D16–D31=0) | ⬜ | (note: queued-band indirect not supported — see ptsg_imem/audit) |
| C4-T2 | Prescaler config (compile-time fixed chosen) | 🟢 silicon | PRESCALE param fixed at synthesis, working |
| C4-T3 | Prescale edge / phase | 🔴 anomaly | **Hook A**: free-running phase jitter suspected → #1 |
| C4-T4 | Stay Set role (clear/sync-only, lean B) | 🟡 sim | implemented as lean B in RTL; silicon alignment OK, jitter dimension → #1 |

## Chapter 5 — External Logic Interface / 外部ロジックインターフェース

| ID | Decision (abbrev.) | State | Evidence |
|---|---|---|---|
| C5-V1 | Active-high reset | 🟢 silicon | golden_top reset via Sources&Probes works |
| C5-V2 | Rising-edge clock | 🟢 silicon | core runs at FPGA_CLK1_50 |
| C5-V5 | state_number registered | 🟢 silicon | SignalTap shows registered state_num (Build Log #6) |
| C5-F1 | Synchronizer = Formation responsibility | ◽ n/a | (definitional; no on-board async Condition source yet) |
| C5-F2 | Stack bus variable-clock handshake | ⬜ | → #3 |
| Memory read contract (RD_LAT≥1, EDGE) | Layer-3/Layer-1 | 🟢 silicon | **the headline result**: EDGE="NEG" alignment verified (Build Log #6); pending Layer-1 write-back (C2-T4 / §5.13) |

---

## Open anomalies / 未解決の異常

| Anomaly | First seen | Status | Routing |
|---|---|---|---|
| Queued band implements Loop only (C3-F2 partial) | Audit 2026-06-02 | confirmed in source | → #4 to characterize on silicon; then Layer 1 decision: complete impl vs formalize the simplification |
| Base Set auto-save idempotency undefined (C3-F11) | Build Log #5 | spec ambiguity | → #5; candidate for Ch3 v1.2 |
| Aligned-fetch residual anomaly (prescaler phase) | Build Log #6 | under measurement | → #1 (Hook A); candidate for C4-T3 phase resolution |

---

## Layer 1 write-back queue / Layer 1 書き戻しキュー

Verification outcomes that should feed back into the specification:

検証結果のうち仕様書に書き戻すべきもの:

- **Memory timing model** (RD_LAT≥1; EDGE="NEG" half-cycle alignment as current Convention with its frequency ceiling; EDGE="POS"+fetch-stage high-clock alternative) → **C2-T4 and Chapter 5 §5.13**. *(Silicon-confirmed; ready to draft.)*
- **Prescaler phase** (free-running vs wait-aligned) → **C4-T3 phase dimension**, pending #1.
- **Base Set idempotency** (A/B/C alternatives) → **C3-F11 / Chapter 3 v1.2**, pending #5.
- **Queued-band scope** (Loop-only vs all internal ops) → **C3-F2 / Chapter 3 v1.2**, pending #4.

# Layer 1 v1.1 Write-Back — Change-Set & Verilog Handoff
# Layer 1 v1.1 書き戻し — 変更指示書と Verilog ハンドオフ

> **Purpose.** This document accompanies the Layer 1 v1.1 chapter edits. It is the change-set a
> human or an AI implementer (e.g. Claude Code) reads to bring `ptsg_core.v` into conformance with
> the updated specification. For each change it gives: the decision ID, the chapter/section, the
> source (Layer 2 trace + Layer 4 evidence), and the **RTL implication**.
>
> **目的。** 本書は Layer 1 v1.1 章編集に付随する。人間または AI 実装者（例: Claude Code）が
> `ptsg_core.v` を更新仕様に適合させるために読む変更指示書である。各変更について、決定 ID、
> 章／節、出典（Layer 2 トレース＋ Layer 4 エビデンス）、そして **RTL 含意**を与える。
>
> **License: CC0 1.0 Universal.** / **ライセンス: CC0 1.0 Universal。**

---

## How to read this for the Verilog revision / Verilog 改修のための読み方

Most of these changes **codify behavior the architect already implemented** in `ptsg_core.v`
revisions RH001–RH008 (2026-06-14/15) and which Layer 4 then verified on silicon. For those, the
implementer's task is **conformance verification**, not new logic: confirm the RTL matches the
now-explicit spec. A smaller set is marked **PROVISIONAL (仮確定)** — the Reset-command band model —
and **does** require RTL work and is not yet silicon-verified.

これら変更の大半は、アーキテクトが `ptsg_core.v` 改訂 RH001–RH008（2026-06-14/15）で**既に実装した
挙動を成文化**したもので、Layer 4 がその後シリコンで検証した。それらについて実装者の務めは新規ロジック
でなく**適合検証**である: RTL が今や明示的な仕様と一致することを確認せよ。より小さな集合が
**PROVISIONAL（仮確定）**——Reset コマンド帯域モデル——と記され、これは RTL 作業を要し、まだシリコン未検証である。

---

## A. Already implemented in RH001–RH008 — verify conformance / RH001–RH008 で実装済み — 適合検証

### A1 — C4-F8: Foreground commands are prescaled / 前景コマンドはプリスケールド実行

- **Chapter / 章:** Ch4 § 4.8, § 4.8a, table § 4.12; supersedes Ch2 C2-T4.
- **Spec now says / 仕様の現記述:** a foreground command (NOP, Jump, Branch taken, control-flow Globals) advances on the next prescaler tick, consuming one whole prescale unit — not one system clock.
- **Source / 出典:** Layer 2 `2026-06-22_ptsg-prescaler-phase-resolution`; Layer 4 `prescaler_phase_measurement` (silicon-confirmed).
- **RTL implication / RTL 含意:** RH001/006 already gate foreground `state_num` advance on `presc_tick`. **Verify** the foreground advance path advances only on `presc_tick` for NOP/Jump/Branch-taken/control-flow Globals, and that in-window background advance remains full-clock (C4-F3). No change expected if RH001–008 is the committed RTL.

### A2 — C4-F9: Free-running prescaler, structurally phase-locked / 自由走行プリスケーラ、構造的位相ロック

- **Chapter / 章:** Ch4 § 4.8a, table § 4.12; cross-ref Ch5 § 5.12.
- **Spec now says / 仕様の現記述:** the prescaler counter is reset only by the global hardware reset — never on wait entry. Because C4-F8 makes every loop an integer multiple of the prescale period, the prescaler re-enters every wait at the same phase; no phase-dependent jitter; no per-wait alignment hardware.
- **Source / 出典:** same parent trace; Layer 4 (white-box `presc_cnt`@entry constant across 13 windows + silicon agreement). Resolves audit hypothesis A2 (rejected).
- **RTL implication / RTL 含意:** the prescaler is free-running (`presc_cnt <= presc_tick ? 0 : presc_cnt+1`, no reset on `S_WAIT` entry). **Verify** there is no `presc_cnt` clear on wait entry anywhere. No change expected.

### A3 — C4-F10: Stay Set = clear/sync-only (was Tie C4-T4 / C3-T11) / Stay Set = クリア／同期のみ

- **Chapter / 章:** Ch4 § 4.9, table § 4.12; Ch3 § 3.2 revised; Ch3 table C3-T11→C4-F10.
- **Spec now says / 仕様の現記述:** Stay Set arms the stay counter (resets to 0, opens the window) but counting begins at **Prog End** (or the Stay instruction if no Prog End), making the wait independent of background-program length (jitter-free).
- **Source / 出典:** Layer 2 `2026-06-22_ptsg-duty-idioms`; Layer 4 idiom D (silicon, internal registers `window_open`/`prog_end_seen`/`queued_valid`).
- **RTL implication / RTL 含意:** RH002/003/004/005 implement the carry-through (no `stay_cnt<=0` clear in `OP_STAY`; `stay_cnt` increments from the window). **Verify** Stay Set arms-without-starting and that counting begins at Prog End/Stay. No change expected.

> **Note:** A1–A3 should already pass conformance against the committed RH001–RH008 RTL. If any does
> not, that is a finding to report, not a silent fix. / A1–A3 はコミット済み RH001–RH008 RTL に対して
> 既に適合するはず。適合しなければ、それは黙って直すのでなく報告すべき所見である。

---

## B. New conventions — no Core RTL change / 新慣習 — Core RTL 変更なし

### B1 — C4-V3: State-0 NOP cold-start convention / state-0 NOP 冷態起動慣習

- **Chapter / 章:** Ch4 § 4.8a, table § 4.12.
- **What it is / 内容:** place a foreground NOP at state 0 to absorb the one-time cold-start prescaler-phase indeterminacy; from state 1 every Stay is exact. Use NOP, not Stay 1 (protects Stay's exactness guarantee). Optionally raise a timing_signal to mark the startup region.
- **Source / 出典:** Layer 2 `2026-06-22_ptsg-state0-nop-triple-role`.
- **RTL implication / RTL 含意:** **none** — state 0 is not special-cased in hardware (reset merely enters at address 0). This is a programming convention for instruction-list authors and Formation designers.

---

## C. PROVISIONAL (仮確定) — Reset command; requires RTL work / Reset コマンド; RTL 作業を要する

> These items are **not yet silicon-verified** and **do** require RTL changes. Treat as a design
> task, not a conformance check. Reasoning: Layer 2 `2026-06-23_ptsg-reset-command-bands`.
>
> これらは**まだシリコン未検証**で、RTL 改変を**要する**。適合検査でなく設計タスクとして扱え。

### C1 — C3-F21: No-prescaler-reset principle / 非プリスケーラ・リセット原則

- **Chapter / 章:** Ch3 § 3.4a; Ch2 § 2.8 Reset row; Ch5 § 5.12.
- **Spec now says / 仕様の現記述:** the program-issued Reset command (Global internal sub-op 0) resets State Number and the stay/loop counters but **does NOT reset the prescaler**. Reason: a slave PTSG must have no influence over the externally-driven time-base.
- **RTL implication / RTL 含意:** in the Global/Reset sub-opcode handler, **ensure `presc_cnt` is never cleared**. Audit every reset path: only the global hardware reset (`rst`) may clear `presc_cnt`; the Reset *command* must not. If the current RTL's Reset command clears the prescaler, **remove that** (Core path). This is the single most important RTL guarantee for master/slave synchronizability.

### C2 — C3-F22: Reset execution bands / Reset 実行帯域

- **Chapter / 章:** Ch3 § 3.4a.
- **Spec now says / 仕様の現記述:** Reset is selectable across foreground (immediate; the following state-0 NOP aligns; Reset+NOP sharing one timing_signals value = one prescale period), background ("staff meal", indeterminate, emergencies), and queued (effectively prescaled, fires at Stay-timeup).
- **RTL implication / RTL 含意:** route the Global/Reset sub-opcode through the existing foreground/background/queued band machinery (C3-F2 — band selected by position relative to Prog End). Foreground Reset executes immediately (no wait-for-tick); the queued Reset fires at Stay-timeup via the existing queued-op mechanism. Identify the band-dispatch point for internal-mode sub-ops and confirm Reset is dispatched there like the other internal sub-ops.

### C3 — C3-V4: Formation opt-in for prescaler-resetting Reset / プリスケーラをリセットする Reset の Formation opt-in

- **Chapter / 章:** Ch3 § 3.4a.
- **Spec now says / 仕様の現記述:** the Core forbids prescaler reset; a Formation MAY opt in where genuinely needed, accepting loss of external synchronizability. A slave configuration must structurally never be able to.
- **RTL implication / RTL 含意:** **optional / Formation-level.** If implemented, provide a clearly-bounded opt-in (e.g. a `parameter` or a distinct external register/sub-operand) that enables a prescaler-resetting Reset, designed so a standalone PTSG can use it but a slave configuration structurally cannot trigger it. Do not enable by default. Out of scope for the Core unless explicitly requested.

---

## D. Clarification / correction (no RTL) / 明確化・訂正（RTL なし）

### D1 — C4-T3 scope corrected (remains a Tie) / C4-T3 射程の訂正（Tie のまま）

- **Chapter / 章:** Ch4 § 4.9, § 4.12; Ch3 table C3-T10→C4-T3.
- **What changed / 変更点:** C4-T3 concerns **only** the leading-vs-trailing **edge** of a queued firing within the prescale period. It is **still an open Tie**. An earlier conformance-matrix note wrongly conflated it with the prescaler *phase* question (which is resolved by C4-F9). The spec now keeps the two distinct.
- **RTL implication / RTL 含意:** **none yet** — C4-T3 remains open. The current RTL's match-flag edge behavior is whatever RH001–008 does; do not treat the edge as normatively fixed until C4-T3 is resolved.

---

## E. Summary table / まとめ表

| ID | Chapter | Status | Source | RTL action |
|---|---|---|---|---|
| **C4-F8** | Ch4 §4.8/4.8a | Fixed (v1.1) | phase trace + L4 | verify (RH001/006) |
| **C4-F9** | Ch4 §4.8a | Fixed (v1.1) | phase trace + L4 | verify (free-running, no wait-entry reset) |
| **C4-F10** | Ch4 §4.9 | Fixed (v1.1, was C4-T4) | duty trace + L4 idiom D | verify (RH002–005) |
| **C4-V3** | Ch4 §4.8a | Convention (v1.1) | state-0 trace | none (programming convention) |
| **C2-T4** | Ch2 | Resolved → C4-F8 | phase trace | (see C4-F8) |
| **C3-F21** | Ch3 §3.4a | **Fixed (仮確定)** | reset trace | **ensure Reset never clears `presc_cnt`** |
| **C3-F22** | Ch3 §3.4a | **Fixed (仮確定)** | reset trace | route Reset through band machinery |
| **C3-V4** | Ch3 §3.4a | **Convention (仮確定)** | reset trace | optional Formation opt-in |
| **C4-T3** | Ch4 §4.9 | **Tie (still open)** | — | none (do not fix the edge yet) |

---

## F. Suggested order for the Verilog implementer / Verilog 実装者への推奨順序

1. **Conformance pass (A1–A3):** confirm the committed RTL implements foreground-prescaling, the
   free-running no-wait-entry-reset prescaler, and Stay-Set clear/sync-only. Report any deviation.
2. **C3-F21 guarantee:** audit all `presc_cnt` reset paths; ensure the Reset *command* never clears it.
3. **C3-F22:** route the Reset command through the foreground/background/queued band dispatch.
4. **C3-V4:** only if requested — add a bounded Formation-level opt-in for a prescaler-resetting Reset.
5. Leave **C4-T3** (queued-firing edge) as-is; it is an open Tie.

1. **適合パス（A1–A3）:** コミット済み RTL が前景プリスケールド化・待機突入非リセットの自由走行
   プリスケーラ・Stay Set クリア／同期のみを実装することを確認。逸脱は報告せよ。
2. **C3-F21 保証:** すべての `presc_cnt` リセット経路を監査；Reset *コマンド*が決してそれをクリアしないこと。
3. **C3-F22:** Reset コマンドを前景／背景／Que 帯域ディスパッチに通す。
4. **C3-V4:** 要請があれば——プリスケーラをリセットする Reset の境界付き Formation opt-in を追加。
5. **C4-T3**（キュー発火の縁）はそのまま——未決 Tie である。

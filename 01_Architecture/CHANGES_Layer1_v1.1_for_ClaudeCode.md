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

> **Organizing principle — the Trailing-Edge Doctrine (Chapter 1 § 1.4a, new in v1.1).** Most A-group
> items are *derivations* of one principle: all state is determined by the **trailing edge** of every
> boundary, so the leading edge is settled; this recurses to the clock (EDGE=NEG). For the Verilog
> implementer this means a single sanity lens: **every determination should land on a trailing edge;
> the only leading-edge-placed commands are foreground StaySet and Reset** (and those depend on the
> preceding command ending on a prescaler tick). Reasoning: Layer 2 `2026-06-24_ptsg-trailing-edge-doctrine`.
>
> **統べる原則——後縁主義（第1章 § 1.4a、v1.1 新規）。** A 群の大半は一つの原則の*派生*である: 全状態は
> あらゆる境界の**後縁**で確定し、前縁は静定する；これはクロック（EDGE=NEG）まで再帰する。Verilog 実装者には
> これは単一の健全性レンズを意味する: **あらゆる確定は後縁に乗るべき;前縁に置かれる命令は前景 StaySet と
> Reset のみ**（それらは直前のコマンドがプリスケーラティックで終わることに依存する）。

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
- **Spec now says (wording corrected 2026-07) / 仕様の現記述（2026-07 訂正）:** Stay Set arms the stay counter (resets to 0, opens the window) **and the counter counts prescaler ticks from Stay Set onward (On-Tick), through the window; the Stay instruction never clears it** (RH003/004/005). Stay-timeup = the Nth tick after Stay Set on the free-running grid — independent of the background-program's clock-length (jitter-free). *(An earlier text mis-stated "counting begins at Prog End" — corrected per the as-built RTL.)*
- **Source / 出典:** Layer 2 `2026-06-22_ptsg-duty-idioms`; Layer 4 idiom D (silicon, internal registers `window_open`/`prog_end_seen`/`queued_valid`).
- **RTL implication / RTL 含意:** RH002/003/004/005 implement the carry-through (no `stay_cnt<=0` clear in `OP_STAY`; `stay_cnt` increments from the window). **Verify** Stay Set arms-without-starting and that counting begins at Prog End/Stay. No change expected.

### A4 — Window tick-increment on every in-window path / 窓内全経路での tick インクリメント

- **Chapter / 章:** Ch3 § 3.2 (corrected), § 3.4b normative table (BG rows: "Continue counting … when On-Tick").
- **Spec now says / 仕様の現記述:** while the window is open, the stay counter increments on **every** prescaler tick, regardless of which in-window command is executing — including BG Branch and BG Jump.
- **RTL implication / RTL 含意:** RH005's `window_open && presc_tick` increment appears on the Global-execution and OP_STAY paths. **Verify** (white-box) that `stay_cnt` also ticks during BG Branch/Jump execution; if any in-window path lacks it, **hoist the increment to a single unconditional `window_open && presc_tick` rule** outside the opcode case. Report whether the hoist changes any verified timing.

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

### C4 — BG/Q Stay Set (re-kick) / BG/Q の Stay Set（re-kick）

- **Chapter / 章:** Ch3 § 3.4b normative table (Stay Set BG/Q rows).
- **Spec now says / 仕様の現記述:** a **BG** Stay Set re-arms the running count mid-window ("Continue counting **with reset**"), tick-synchronized (SN advances on the tick) — the variable-length-Stay re-kick. A **Q** Stay Set is registered during the scan (semantics of its firing to be exercised in verification).
- **RTL implication / RTL 含意:** **not yet implemented** (architect-confirmed). Add the BG re-kick path (stay_cnt reset + tick-synchronized advance inside the window) and define/implement the queued Stay Set behavior.

### C5 — Error HALT machinery / Error HALT 機構

- **Chapter / 章:** Ch3 § 3.4b (C3-F23/F24); Ch2 § 2.8 band-legality note.
- **Spec now says / 仕様の現記述:** FG Base Set/Return/Call/Loop/Prog End → HALT; stray Prog End (outside a window; second in the Q band) → HALT; queued SN-overwrite → HALT (C8); unpaired Base Set↔Loop across bands → HALT. SN holds at the violating instruction; an **error-flag output port** is raised (SignalTap + insertion trigger). Exit: hardware reset (ISMCE live patch / insertion as repair paths).
- **RTL implication / RTL 含意:** add an **S_HALT** state, the trap decodes above, the Base Set↔Loop band-pairing tracking, and the error-flag output. Keep the flag registered (trailing-edge discipline). Consider (do not yet implement) a DEBUG_CHECKS parameter for the costlier checks.

### C6 — Stay Start State register (same-cycle hand-off) / Stay Start Stateレジスタ（同一サイクル引き渡し）

- **Chapter / 章:** Ch3 § 3.4b (C3-F25; lifetime corrected 2026-07).
- **Spec now says / 仕様の現記述:** FG Stay Set writes its own State Number to **stay_start_state**, valid only within that same Stay cycle. **A queued Base Set executing in that cycle loads Base := stay_start_state**, discharging it (BG Base Set keeps Base := current SN); if no Base Set occurs, the next Stay Set overwrites it. Reset 0; Core-invisible. *(Not stacked, not cross-Stay: carrying a target across many Stay periods to a distant Loop, including nesting, remains the Base register's own existing role — an earlier text conflated the two; corrected.)*
- **RTL implication / RTL 含意:** add the register **as a plain register — no stack entry**; write in SUB_STAYSET (FG path); **mux the SUB_BASESET base source by band**. No change needed to the existing context-save/restore (holding-register) stack — confirm this in review (verification-queue #3 is unaffected). Scaled 2^28 self-loop conformance item recommended (e.g. Loop-4 × Stay-8).

### C7 — Reset: queued firing + own-tsig drive / Reset: Que発火＋自tsig駆動

- **Chapter / 章:** Ch3 § 3.4a, § 3.4b table (Reset rows).
- **Spec now says / 仕様の現記述:** a Q-band Reset is **registered at encounter and fires at Stay-timeup** (SN → 0 at firing), per C3-F22. In all bands Reset **drives its own timing_signals field** (enables a "Reset reserved" notification signal; a program not wanting an indeterminate output sets it equal to the Stay's value).
- **RTL implication / RTL 含意:** current RTL executes Reset immediately and **clears timing_signals to 0** — change to (a) route Q-band Reset through the reservation register, firing at timeup; (b) drive `timing_signals <= tsig` (the instruction's own field) instead of clearing.

### C8 — Queue: last-write-wins + SN-overwrite HALT / Que: 後勝ち＋SN上書きHALT

- **Chapter / 章:** Ch3 § 3.4b (C3-F26; Tie C3-T15 open).
- **Spec now says / 仕様の現記述:** single reservation register, last-write-wins; overwriting a queued **State-Number** reservation → HALT + error flag. Nested multi-booking (two Base Sets/Loops) is an open Tie — do **not** implement queue depth >1.
- **RTL implication / RTL 含意:** add overwrite detection on the SN-reservation register (a second SN-class reservation while `queued_valid` holds an SN-class entry → trap to S_HALT). Non-SN reservations may simply replace.

## D. Clarification / correction (no RTL) / 明確化・訂正（RTL なし）

### D1 — C4-F11: Queued firing at the trailing edge (was Tie C4-T3) / キュー発火は後縁（旧 Tie C4-T3）

- **Chapter / 章:** Ch1 § 1.4a; Ch4 § 4.9, § 4.12; Ch3 table C3-T10→C4-F11; Ch5 § 5.10.
- **Spec now says / 仕様の現記述:** a queued operation (and the `stay_cnt_match` pulse) fires at the **trailing edge** of the prescale period — the moment the count completes — by the Trailing-Edge Doctrine. The earlier leading-edge-flag hybrid is superseded; a sustained external strobe is a Formation concern derived from the trailing-edge pulse. (The separate prescaler *phase* question is resolved by C4-F9 — an earlier conformance-matrix note conflated the two.)
- **Source / 出典:** Layer 2 `2026-06-24_ptsg-trailing-edge-doctrine`.
- **RTL implication / RTL 含意:** **verify** that queued-operation firing and `stay_cnt_match` occur on the trailing edge of the prescale period (count-completion), not the leading edge. RH001–008's trailing-edge conversions likely already satisfy this; if any queued firing or match pulse is on a leading edge, change it to the trailing edge. Do **not** add a leading-edge defining action.

---

## E. Summary table / まとめ表

| ID | Chapter | Status | Source | RTL action |
|---|---|---|---|---|
| **C4-F8** | Ch4 §4.8/4.8a | Fixed (v1.1) | phase trace + L4 | verify (RH001/006) |
| **C4-F9** | Ch4 §4.8a | Fixed (v1.1) | phase trace + L4 | verify (free-running, no wait-entry reset) |
| **C4-F10** | Ch4 §4.9 | Fixed (v1.1, was C4-T4) | duty trace + L4 idiom D | verify (RH002–005) |
| **C4-V3** | Ch4 §4.8a | Convention (v1.1) | state-0 trace | none (programming convention) |
| **C1-D13** | Ch1 §1.4a | Principle (v1.1) | trailing-edge doctrine | organizing lens: all determination on trailing edge |
| **C2-T4** | Ch2 | Resolved → C4-F8 | phase trace | (see C4-F8) |
| **C3-F21** | Ch3 §3.4a | **Fixed (仮確定)** | reset trace | **ensure Reset never clears `presc_cnt`** |
| **C3-F22** | Ch3 §3.4a | **Fixed (仮確定)** | reset trace | route Reset through band machinery |
| **C3-V4** | Ch3 §3.4a | **Convention (仮確定)** | reset trace | optional Formation opt-in |
| **C3-F23** | Ch3 §3.4b | **Fixed (仮確定)** | table trace | trap FG Base Set/Return/Call/Loop/ProgEnd |
| **C3-F24** | Ch3 §3.4b | **Fixed (仮確定)** | table trace | S_HALT + error flag + pairing checks |
| **C3-F25** | Ch3 §3.4b | **Fixed (仮確定, lifetime corrected 2026-07)** | register trace | stay_start_state (same-cycle, no stack) + Base mux |
| **C3-F26** | Ch3 §3.4b | **Fixed (仮確定)** | register trace | SN-overwrite detect → HALT; last-write-wins |
| **C3-T15** | Ch3 §3.4b | **Tie (open)** | register trace | none (keep queue depth = 1) |
| **C4 (item)** | Ch3 §3.4b | **仮確定** | table | BG Stay Set re-kick; Q Stay Set |
| **A4 (item)** | Ch3 §3.2/3.4b | verify | table trace | window tick on BG Branch/Jump paths |
| **C4-F11** | Ch1 §1.4a / Ch4 §4.9 | Fixed (v1.1, was C4-T3) | trailing-edge doctrine | verify queued firing + match pulse are trailing-edge |

---

## F. Suggested order for the Verilog implementer / Verilog 実装者への推奨順序

1. **Conformance pass (A1–A4):** confirm the committed RTL implements foreground-prescaling, the
   free-running no-wait-entry-reset prescaler, Stay-Set On-Tick counting (corrected C4-F10), and the
   window tick-increment on every in-window path (A4 — hoist if any path lacks it). Report deviations.
2. **C3-F21 guarantee:** audit all `presc_cnt` reset paths; ensure the Reset *command* never clears it.
3. **C3-F22:** route the Reset command through the foreground/background/queued band dispatch.
4. **C3-V4:** only if requested — add a bounded Formation-level opt-in for a prescaler-resetting Reset.
5. **C4-F11** (was C4-T3): verify queued firing and the match pulse are on the **trailing edge** (count-completion); correct any leading-edge firing. Use the Trailing-Edge Doctrine as the global sanity lens.
6. **C5 HALT machinery:** S_HALT, traps (FG-illegal Globals; stray Prog End; unpaired Base Set↔Loop), error-flag port.
7. **C6 Stay Start State register:** register (same-cycle hand-off, no stack change) + queued-Base-Set mux; scaled 2^28 conformance item.
8. **C7 Reset revisions:** queued firing at timeup; drive own tsig (stop clearing to 0).
9. **C8 queue rules:** last-write-wins; SN-overwrite → HALT. Keep queue depth = 1 (Tie C3-T15 open).
10. **C4 BG/Q Stay Set:** implement the re-kick (BG) and define/implement queued Stay Set.

1. **適合パス（A1–A3）:** コミット済み RTL が前景プリスケールド化・待機突入非リセットの自由走行
   プリスケーラ・Stay Set クリア／同期のみを実装することを確認。逸脱は報告せよ。
2. **C3-F21 保証:** すべての `presc_cnt` リセット経路を監査；Reset *コマンド*が決してそれをクリアしないこと。
3. **C3-F22:** Reset コマンドを前景／背景／Que 帯域ディスパッチに通す。
4. **C3-V4:** 要請があれば——プリスケーラをリセットする Reset の境界付き Formation opt-in を追加。
5. **C4-F11**（旧 C4-T3）: キュー発火と一致パルスが**後縁**（カウント完了）にあることを検証し、前縁発火があれば修正。後縁主義を全体の健全性レンズとして用いよ。
6. **C5 HALT 機構:** S_HALT・トラップ群（FG 違法 Global;迷子 Prog End;不対 Base Set↔Loop）・エラーフラグポート。
7. **C6 Stay Start State レジスタ:** レジスタ（同一サイクル引き渡し、スタック変更なし）＋Que Base Set のマルチプレクサ;縮小 2^28 適合項目。
8. **C7 Reset 改訂:** timeup での Que 発火;自 tsig 駆動（0 クリアをやめる）。
9. **C8 Que 規則:** 後勝ち;SN 上書き → HALT。キュー深度は 1 のまま（Tie C3-T15 未決）。
10. **C4 BG/Q Stay Set:** re-kick（BG）の実装と Que Stay Set の定義・実装。

# PTSG — The Free-Running Fruits, Reclaimed (RH029/RH030): One-Clock Tick, Raw-Tick Export, and the Prescaler as Pure Time-Base
# PTSG — フリーランの果実の回収（RH029/RH030）: 1 クロック叩き、生ティック外部化、そして純粋な時間基準としてのプリスケーラ

## Trace Metadata / 軌跡メタデータ

| Field | Value |
|---|---|
| **Date / 日付** | 2026-08-27 |
| **Participants / 参加者** | Tsuneo Ohnaka (大中庸生, FPGA Architect, 40+ years; sole design authority — supplied the governing premise and RH029/RH030 themselves); Claude (Anthropic, Claude Fable 5, amanuensis / 祐筆 — RTL read-back, Layer 1/2 reconciliation, this archive) |
| **Topic / トピック** | The forward link reserved on 2026-06-23 ("the free-running prescaler's other fruits — Fmax via a one-clock-registered tick, master/slave sync via an externalized raw tick — Build Log #9 and a future trace") was implemented in RTL as RH029 (externally settable prescaler, `prescaler_value` pin, parameter fallback) and RH030 (registered one-clock `presc_tick`; `prescaler_match` = raw pre-register tick) **before** the trace or the spec text existed. This trace reclaims the link: it records the governing premise, reads the RTL back into Layer 1 vocabulary, and lists — as negative data — what the RTL does and does not yet provide. / 2026-06-23 に留保した前方リンクが、trace も仕様文もないまま RH029/RH030 として RTL に先行実装された。本 trace はそのリンクを回収する: 前提を記録し、RTL を Layer 1 の語彙へ読み戻し、RTL が提供するもの／まだ提供しないものを負のデータとして列挙する。 |
| **Status / 状態** | **PROVISIONAL (仮確定)** — reconciliation trace. RTL RH029/RH030 present in `ptsg_core.v`; header registration and Layer 1 write-back proposed here; several RTL items left OPEN for the architect's ruling; multi-LLM review before normative codification. / **仮確定**——辻褄合わせ trace。RTL は存在、ヘッダ登録と Layer 1 反映を本書で提案、RTL 上の未決事項はアーキテクト裁定待ち、規範化前に複数 LLM レビュー。 |
| **Original language / 原言語** | Japanese (with English technical terminology) / 日本語（英語技術用語を交える） |
| **License / ライセンス** | CC0 1.0 Universal (Public Domain) |
| **Rests on / 依拠** | `2026-06-22_ptsg-prescaler-phase-resolution` (free-running is deliberate, C4-F9); `2026-06-23_ptsg-reset-command-bands` (no-prescaler-reset C3-F21; **Hook E** is the link reclaimed here); `2026-07-08_ptsg-p1-tick-collision` (RH028 `>=` discipline, the anchor RH030 must not disturb). / 位相決着; Reset 帯域（Hook E を回収）; P=1 tick 衝突（RH030 が崩してはならないアンカー）。 |
| **Closes / 回収** | Hook E of `2026-06-23_ptsg-reset-command-bands`; the "Forthcoming (Chapter 6 / Build Log #9)" note in Chapter 5 § 5.12. / Reset 帯域 trace の Hook E; 第5章 § 5.12 の「近刊」注記。 |

---

## Reading Notes / 読解上の注

Three consequences were promised from one decision — accept a free-running prescaler — and one of
them (Reset must not touch it, C3-F21) was recorded at once. The other two were reserved. They have
since been built: RH029 lets a Formation set the divide ratio from outside; RH030 re-times the
internal tick through one register and hands the *raw* tick to the outside. What was missing was
the sentence that makes both legitimate. The architect supplied it in this session:

> **the prescaler counter value is, in principle, not for external use; the prescaler's only job is to
> generate the base frequency.**

Once the counter is not an interface, the tick may be re-timed freely (Fmax), and the only thing
worth exporting is the tick itself (sync). Everything below follows from that sentence. The trace
also does what the negative-data discipline requires: it names the third occurrence of "the
artifact was ahead of the narration", and lists the places where the RTL, the session record, and
the spec still disagree.

一つの判断——フリーランプリスケーラの受容——から三つの帰結が約束され、一つ（Reset は触れない、C3-F21）は即座に
記録された。残る二つは留保された。それらはその後、作られた: RH029 は Formation が分周比を外から設定できるように
し、RH030 は内部ティックを一段のレジスタで叩き直し、*生*のティックを外へ渡す。欠けていたのは、その両方を正当化する
一文である。アーキテクトが本セッションで与えた:

> **プリスケーラカウンタ値は原則として外部利用しない。プリスケーラは基礎周波数の生成だけを担う。**

カウンタがインターフェースでないなら、ティックは自由に叩き直せる（Fmax）し、外へ出す価値があるのはティックそのもの
だけになる（同期）。以下はすべてこの一文から導かれる。本 trace はまた負のデータ規律の求めに従い、「artifact が narration
に先行した」三度目の事例を名指しし、RTL・セッション記録・仕様がなお食い違う箇所を列挙する。

**What the RTL actually says (RH029/RH030, `ptsg_core.v`) / RTL の実態:**

```
input  tri0 [PRESC_W-1:0] prescaler_value;                                   // RH029
output wire [PRESC_W-1:0] prescaler_output;                                  // RH029 (declared, undriven)
reg  [PRESC_W-1:0] presc_valueM;                                             // = prescaler_value - 1, registered
wire presc_tickP = (presc_cnt == ((prescaler_value == 0) ? (PRESCALE-1) : presc_valueM));   // raw tick
reg  presc_tick;  presc_tick <= presc_tickP;                                 // RH030: registered, one clock
presc_cnt <= presc_tickP ? 0 : presc_cnt + 1;                                // RH030: rollover on raw tick
assign prescaler_match = presc_tickP;                                        // raw tick exported
```

---

## Decision Points / 決定点

### DP-1 — What the prescaler *is* / プリスケーラとは何か
- **Alternative A — an observable counter.** `prescaler_counter` is a first-class output; Formations may read the running value; its timing relative to the tick is part of the interface.
- **Alternative B — a pure base-frequency generator.** The counter is internal; only the tick has meaning outside; `prescaler_counter` is a diagnostic/optional output with no timing contract.
- **Chosen: B** (architect's premise, this session).
- **Rationale:** With B, the internal tick may be re-timed (registered) without breaking any external contract, and the sync problem reduces to "share the tick". With A, RH030's one-clock re-timing would silently change an interface. B is also what C3-F21 already assumed: a time-base a program cannot touch is not a counter a program reads. Chapter 5 § 5.10 already lists `prescaler_counter` as optional; this decision gives that optionality its reason.

### DP-2 — Fmax: register the internal tick (RH030) / 内部ティックの 1 クロック叩き
- **Alternative A — combinational `presc_tick`.** The FSM's every `if (presc_tick)` sees the 16-bit comparator plus the value mux on its path.
- **Alternative B — registered `presc_tick` (one-clock pulse).** The comparator is cut at a flip-flop; the FSM sees a clean FF output.
- **Chosen: B (RH030).**
- **Rationale:** All in-core consumers use `presc_tick` uniformly, so the whole tick grid shifts by exactly one clock and every interval (Stay, FG command, phase-lock C4-F9) is preserved. Cost: +1 clock latency from counter terminal to core action, +2 FFs. Not "cancelling" comparator delay — moving it behind a register boundary; the counter rollover (`presc_cnt <= presc_tickP ? 0 : …`) keeps a short local comparator loop, acceptable. **Regression anchor:** RH028's terminal-value pattern (stay_cnt terminal = target − 1) and the `>=` deadline must be re-confirmed under the shifted grid (Hook A).

### DP-3 — Sync: export the *raw* tick / 生ティックの外部化
- **Alternative A — export the registered tick** (same edge the core acts on).
- **Alternative B — export the raw pre-register tick** (`prescaler_match = presc_tickP`).
- **Alternative C — export both.**
- **Chosen (RTL as built): B**, matching the 2026-06-23 wording "externalized raw (pre-register) tick".
- **Rationale:** A slave that receives the raw tick and registers it once has a tick *coincident with the master's internal tick* — the one-register delay is reproduced identically on both sides. Exporting the registered tick would leave the slave one clock behind unless it bypasses its own register. **Consequence to codify:** `prescaler_match` leads the core's internal tick by exactly one clock; `prescaler_match` carries comparator delay (it is combinational) and is therefore a *timing-analysed* output, not a glitch-free strobe — Formation must register it (C follows for free if a Formation needs both).

### DP-4 — What "slave" means in RH029 vs. in the reservation / RH029 の「スレーブ」と留保の「スレーブ」
- **Alternative A — period-sharing slave.** All cores get the same `prescaler_value` and one hardware reset; C3-F21 keeps them phase-locked forever. No tick input port. *This is what RH029/RH030 provide.*
- **Alternative B — tick-following slave.** A core accepts an external tick in place of its own comparator (a `tick_in`/bypass port); the master's `prescaler_match` drives it. *Not implemented.*
- **Alternative C — both**, selectable at instantiation.
- **Chosen: OPEN (Tie candidate for Chapter 6).** RH029/RH030 realise A; the 2026-06-23 rationale ("a slave follows an externally-supplied tick") describes B.
- **Rationale:** A already yields deterministic, identical tick latency across cores (DP-2) and is enough for same-clock, same-reset compositions on one FPGA. B is needed only across clock domains or resets, and adds a Core port — a Core-Formation-separation question the architect must rule on. Recorded here so the reservation's promise and the RTL's delivery are not confused.

### DP-5 — Which C4-T2 form RH029 actually is / RH029 は C4-T2 のどの案か
- **(A) compile-time fixed** — parameter only, no pin (the RTL header still says this).
- **(B) runtime-configurable** — per Chapter 5 § 5.12: a Core-internal register written over the external-operation bus, *no new pins* (the RTL tag says "option B").
- **As built (call it B′): pin-level value input.** `prescaler_value` is a tri0 input; 0 (or unconnected) falls back to the `PRESCALE` parameter; the Formation decides whether the pin is a constant or a register. Chapter 5 § 5.2's table already lists a `prescaler_value` input (there mislabelled under option A).
- **Chosen: OPEN — recommend recording B′ as the reference implementation's form and updating § 5.2/§ 5.12 accordingly.** C4-T2 stays a Tie; only the contributor's lean and the reference form change.
- **Rationale:** B′ preserves Core minimalism (no bus decode in the Core, no sub-opcode reserved), keeps (A) as the zero-cost default via the fallback, and pushes the "register or constant" question to the Formation — the discipline-preserving extension pattern.

### DP-6 — Negative data: where RTL, record, and spec still disagree / 負のデータ
Recorded; item 1 ruled in-session, items 2–6 are the architect's call:
1. **`==` vs `>=` in `presc_tickP` — RULED (architect, 2026-08-27): stays `==`.** The 2026-07-25 session record said "`>=` comparator protection"; that record was wrong, the file is right. Rationale: a prescaler comparator that runs past its terminal is a *fatal* fault by concept; a loud 2^16-wrap that cannot be missed is preferred to a quiet, slightly-short period that hides the error (fail-loud). This is a deliberate asymmetry with RH028, where `>=` on the *stay* counter serves the minimal-timing idiom ("as fast as possible"); the time-base gets no such grace.
2. **Zero-check timing.** `prescaler_value == 0` is tested on the raw input (combinational) while `presc_valueM` is one clock behind; a 0↔non-0 transition yields one clock of mismatched compare target.
3. **`prescaler_output`** is declared (RH029) and never driven.
4. **Reset hygiene.** `presc_tick` and `presc_valueM` live in an always block without `rst`; one clock of X in simulation (the RH014 `queued_opcode` pattern).
5. **Narration lag.** Header RH list ends at 028; Tie-lean line still reads "C4-T2 … compile-time fixed"; L579's tag reads RH030 with RH029's description; L635 (`presc_valueM <= prescaler_value - 1`) is RH029 content under an RH030-only comment; L458 "-cycle pulse" typo. Third instance of "the artifact was ahead of the narration".
6. **Live-write semantics undefined.** When does a new `prescaler_value` take effect — next compare (as built), or a barline-style boundary? The stay counter has the barline rule; the prescaler has none yet.

---

## Themes / テーマ

**T1 — One decision, three fruits.** No-prescaler-reset (C3-F21), the registered tick (Fmax), and the raw-tick export (sync) are not three features; they are one commitment — the prescaler is a sovereign time-base — seen from three sides. The premise "the counter value is not for external use" is the hinge that makes the last two free.

**T2 — Period-sharing is not tick-following.** RH029 gives every core the same period and, with a common reset, the same phase; it does not let a core *follow* another's tick. Both are "master/slave"; only one is built. Naming the difference is what keeps Chapter 6 honest.

**T3 — The artifact ahead of the narration, again.** The RTL delivered the reserved fruits before the trace existed; the header, the Tie lean, and one tag lagged. The discipline is unchanged: read the RTL back into the record, mark the gaps, do not let the record pretend it led.

---

## Resumption Hooks / 再開フック

### Hook A — Silicon confirmation under the shifted grid / ずれたグリッドでの実機確認
**Description:** RH030 shifts every tick by one clock. RH028's anchors (bare Stay-1@P=1 = 1 clock; stay_cnt terminal = target − 1; `>=` earliest firing) and the silicon anchors (T1 25:25, T2 30:30, T32) must hold unchanged.
**Starting question:** Live Session #1 Scene 5 (P=1, 5:4 anomaly) is the first silicon test of RH028 on the RH030 RTL. Re-run T1/T2/T32/T34 and the P=1 functional tests on the RH030 RTL; SignalTap one `prescaler_match` → `presc_tick` → `stay_cnt` sequence at P=6250 and at P=1. Does `prescaler_match` lead `presc_tick` by exactly one clock in silicon?

### Hook B — Chapter 6: the tick-following slave / 第6章: ティック追従スレーブ
**Description:** DP-4's alternative B (a tick-input/bypass port) is the unbuilt half of the reservation.
**Starting question:** Is a tick input a Core port or a Formation wrapper around `prescaler_value`/reset? If a Core port: what does a slave's own `presc_cnt` do (free-run and ignore, or track)? Does a slave's Reset need special handling (the 2026-06-23 Hook E question)?

### Hook C — RTL hygiene ruling / RTL 衛生の裁定
**Description:** DP-6 items 2–4 each need a yes/no from the architect (item 1 ruled: `==` stays). **Deferred by the architect (2026-08-27)** to a batched Layer 2 review at the next Layer 4 checkpoint, together with the defects and open items the architect has already found during Live Session #1 verification; the source stays untouched until then.
**Starting question:** Move the zero-check onto the registered path? Define or delete `prescaler_output`? Add `rst` to `presc_tick`/`presc_valueM`?

### Hook D — Where the narrative lives / 叙述の置き場
**Description:** The 2026-06-23 reservation named Build Log #9; Build Logs have since reached #12 and the free-running-fruits narrative did not appear under #9.
**Starting question:** Retarget the reservation to a new Build Log (#13?) and correct the pointers in Chapter 5 § 5.12 and the Reset-bands trace, or leave a redirect note?

### Hook E — Layer 1 write-back adoption / Layer 1 反映の採択
**Description:** The companion delta document (`CHANGES_Layer1_free-running-fruits_RH029-030.md`) drafts Chapter 4/5 text.
**Starting question:** After multi-LLM review: which items become Fixed (registered internal tick; raw-tick export; counter-not-an-interface) and which stay Convention/Tie (B′ form; live-write semantics; tick-following slave)?

---

## Key Outputs for the Repository / リポジトリへの主要出力

- **PREMISE (architect):** the prescaler counter value is not, in principle, for external use; the prescaler generates the base frequency only. `prescaler_counter` is diagnostic/optional with no timing contract.
- **RH030 read-back:** internal `presc_tick` is a one-clock registered pulse; the whole tick grid shifts by one clock uniformly; Fmax benefit = comparator behind a register boundary (not "cancelled"); regression anchors unchanged pending Hook A.
- **RH030 read-back:** `prescaler_match` = raw pre-register tick, leading the internal tick by exactly one clock; combinational, must be registered by the consumer; this is the "externalized raw tick" of the 2026-06-23 reservation.
- **RH029 read-back:** `prescaler_value` is a pin-level, tri0 input; 0/unconnected = `PRESCALE` parameter fallback; `presc_valueM = value − 1` registered off the compare path. Form = **B′ (pin-level value)**, neither pure (A) nor Chapter 5's bus-register (B). C4-T2 remains a Tie.
- **Sync as delivered = period-sharing** (same `prescaler_value` + common hardware reset + C3-F21); **tick-following slave = not built**, reserved for Chapter 6 (DP-4, Hook B).
- **RULED (architect):** `presc_tickP` stays `==` — fail-loud; time-base overrun is fatal; deliberate asymmetry with RH028's `>=`.
- **OPEN (architect):** zero-check timing; undriven `prescaler_output`; missing `rst` on `presc_tick`/`presc_valueM`; live-write semantics.
- **Narration corrections (architect-approved as canonical):** RH029/RH030 header entries; C4-T2 lean line; L579 tag; L458 typo; two RH tags (RH030 `presc_tick`, RH029 `presc_valueM`) inside the tick always block (`03_Sample_Implementations/…/RH029-030_header_patch.md`).
- **Closes:** Hook E of `2026-06-23_ptsg-reset-command-bands`; Chapter 5 § 5.12 "Forthcoming" note (rewritten in the delta document).
- **Status:** PROVISIONAL; multi-LLM review before Layer 1 codification.

---

## End of Trace / 軌跡の末尾

A metronome does not show you its gears. It gives you the beat, and the beat is all it promises.
Once the prescaler was allowed to be only that — a beat, not a number to be read — two things became
free at once: the beat could be handed through one more register on its way inside, costing a clock
and buying speed; and the beat could be handed *outside*, raw, so that another core might take it
in and, through its own single register, land on the same instant. The gears stay hidden; the beat
is shared. What remains to decide is whether a second metronome may listen, or must only be wound
to the same setting and started at the same moment.

メトロノームは歯車を見せない。拍を与える、それだけを約束する。プリスケーラがそれだけのもの——読み取る数ではなく拍——
であることを許された瞬間、二つのことが同時に自由になった: 拍を内側へ渡す途中でレジスタを一段くぐらせ、1 クロックを
払って速度を買うこと;そして拍を*外へ*、生のまま渡し、別のコアがそれを受け取って自身の一段のレジスタを通し、同じ瞬間に
着地すること。歯車は隠れたまま、拍は共有される。残る決めごとは、二台目のメトロノームが*聴く*ことを許されるのか、それとも
同じ目盛りに合わせて同じ瞬間に始動させるだけなのか、である。

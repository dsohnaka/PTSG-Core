# PTSG — Stay Length from the Formation: the RH029 Pattern Applied to Stay (`stay_value`), Read at Execute, Zero Escaping Twice
# PTSG — Formation から Stay 長を: RH029 パターンの Stay への適用（`stay_value`）、実行時の一回読み、二度逃げるゼロ

## Trace Metadata / 軌跡メタデータ

| Field | Value |
|---|---|
| **Date / 日付** | 2026-09-26 |
| **Participants / 参加者** | Tsuneo Ohnaka (大中庸生, FPGA Architect, 40+ years; sole design authority — stated the WPMS requirement and the directive); Claude (Anthropic, Claude Opus 5.5, amanuensis / 祐筆 — RTL read-back, design-space recording, Layer 1 delta, handoff) |
| **Topic / トピック** | WPMS forms wave packets of arbitrary length and sets packet length = Stay length, so the PTSG_WPMS_Formation must hand the Core a Stay length from a register. The architect directed that the Stay receive exactly the treatment RH029 gave the prescaler: a pin-level value that, when silent (zero), defers to the Core's own value (IND-reverse). Read against the RTL, the directive lands on a single substitution point (`stay_dur`), which the Core already latches at the Stay's execute clock: the pin is read once per Stay, a Stay in progress cannot be stretched or cut, and the live-write question the prescaler left open does not arise. Two consequences differ from the prescaler and are recorded: the register RH029 placed ahead of its comparator would, for a Stay, become a one-clock lookahead that breaks the simplest Formation idiom (`len_lut[state_number]`) — a Tie with a lean; and RH029's as-built zero test must not be copied, since a one-clock slip would cost a Stay its whole length (an 8192-tick runaway). The operand-first reading (IND) — the architect's own S_IND-abolition formula and the Stay case of the 2026-05-13 decision 8 — is recorded as the standing alternative, and the literal-zero-plus-2^W-sentinel pattern, now seen a third time, is proposed as Layer 1 grammar. / WPMS は任意長の波束を形成し、パケット長＝Stay 長とする。ゆえに PTSG_WPMS_Formation はレジスタから Stay 長をコアへ渡す必要がある。アーキテクトの指示は、RH029 がプリスケーラに施したのと同じ扱いを Stay に施すこと——黙っている（ゼロの）ときはコア自身の値に委ねるピンレベル値（IND 逆パターン）。RTL に照らすと、この指示は単一の置換点 `stay_dur` に着地し、コアはそれを既に Stay の実行クロックでラッチしている: ピンは Stay ごとに一度だけ読まれ、進行中の Stay は伸ばされも切られもせず、プリスケーラで未決に残った稼働中書換えの問いは Stay では生じない。プリスケーラと異なる帰結が二つあり記録する: RH029 が比較器の前に置いたレジスタは、Stay では最も素直な Formation 定石（`len_lut[state_number]`）を壊す 1 クロックの先読みになる——傾向つきの Tie;そして RH029 の現行ゼロ判定を写してはならない——1 クロックのずれが Stay 全体の長さを奪う（8192 tick の暴走）。オペランド優先の読み（IND）——アーキテクト自身の S_IND 廃止式であり、2026-05-13 決定 8 の Stay 版——を常設の代替案として記録し、三度目の出現となった「直値ゼロ＋2^W 番兵」を Layer 1 の文法として提案する。 |
| **Status / 状態** | PROVISIONAL (仮確定) — design trace. Mechanism and precedence per architect directive; sampling path (Tie C4-T5) and pin width (Tie C5-T2) await the PTSG_WPMS_Formation office's answers (Hook A); RTL unchanged (frozen at RH030 during Layer 4); multi-LLM review before normative codification. / 仮確定——設計 trace。機構と優先順はアーキテクト指示による;サンプリング経路（Tie C4-T5）とピン幅（Tie C5-T2）は PTSG_WPMS_Formation 事務所の回答待ち（Hook A）;RTL は未変更（Layer 4 中は RH030 で凍結）;規範化前に複数 LLM レビュー。 |
| **Original language / 原言語** | Japanese (with English technical terminology) / 日本語（英語技術用語を交える） |
| **License / ライセンス** | CC0 1.0 Universal (Public Domain) |
| **Rests on / Serves** | Rests on: 2026-08-27_ptsg-free-running-fruits (RH029 form B′; Hook C questions); 2026-07-08_ptsg-p1-tick-collision (RH028 >=); 2026-05-13_ptsg-strategic-positioning (decision 8: literal-zero double escape); prior office session 'PTSG-Core project and Hackaday profile' (mid-July 2026: the S_IND-abolition formula; 2026-07-16: IND-reverse for the prescaler). Serves: the PTSG_WPMS_Formation office (handoff 2026-09-26). / 依拠: フリーランの果実（B′、Hook C）;P=1 tick 衝突（RH028）;戦略的位置づけ 決定 8;前事務所（S_IND 廃止式、プリスケーラの IND 逆パターン）。供する先: PTSG_WPMS_Formation 事務所。 |

---

## Reading Notes / 読解上の注

WPMS forms wave packets of arbitrary length, and its specification sets **packet length = Stay length**. The PTSG_WPMS_Formation therefore has to hand the Core a Stay length from a register. The architect's directive: give the Stay exactly the treatment RH029 gave the prescaler — a pin-level value that, when silent (zero), defers to the Core's own value.

Reading that directive against the RTL produced three findings. **First**, the Core already latches a Stay's duration when the Stay executes, so the pin is read once per Stay and a packet in progress can never be stretched or cut — the live-write question the prescaler left open does not arise. **Second**, the register RH029 placed ahead of its comparator would, for a Stay, become a one-clock lookahead that breaks the simplest Formation idiom (`len_lut[state_number]`); whether to keep it is recorded as a Tie with a lean. **Third**, RH029's as-built zero test (on the raw pin, beside a registered value) must not be copied: a one-clock slip that costs the prescaler one comparison would cost a Stay its whole length — an 8192-tick runaway of exactly the kind RH028 retired.

The form has a lineage. On 2026-05-13 the strategic positioning chose "literal 0 → external register; register 0 → the maximum" for loop count, Stay length and Jump target (decision 8); Layer 1 later kept it for Jump and Loop and narrowed Stay 0 to 4096. In mid-July the architect wrote both readings of the idiom: the S_IND-abolition formula (operand first) and, on 2026-07-16, the prescaler's IND-reverse (external first). This trace applies the second to the Stay, records the first as the alternative, and proposes that the pattern — now seen three times — be written down as grammar. *(Numbering note: the external prescaler value is RH029; the registered tick and raw-tick export are RH030.)*

WPMS は任意長の波束を形成し、その仕様は **パケット長＝Stay 長** と定める。ゆえに PTSG_WPMS_Formation はレジスタから Stay 長をコアへ渡さねばならない。アーキテクトの指示: RH029 がプリスケーラに施したのとまったく同じ扱いを Stay に——黙している（ゼロの）ときはコア自身の値に委ねるピンレベル値。

この指示を RTL に照らして、三つの所見が得られた。**第一に**、コアは Stay の長さを実行時に既にラッチしている。ゆえにピンは Stay ごとに一度だけ読まれ、進行中のパケットは伸ばされも切られもしない——プリスケーラで未決に残った稼働中書換えの問いは生じない。**第二に**、RH029 が比較器の前に置いたレジスタは、Stay では 1 クロックの先読みとなり、最も素直な Formation 定石（`len_lut[state_number]`）を壊す;残すか否かは傾向つきの Tie として記録する。**第三に**、RH029 の現行ゼロ判定（生ピンでの判定＋登録済みの値）を写してはならない: プリスケーラなら比較一回分で済む 1 クロックのずれが、Stay では長さ全体を奪う——RH028 が退役させたのと同種の 8192 tick 暴走。

この形には系譜がある。2026-05-13 の戦略的位置づけは、ループ回数・Stay 長・Jump 先について「直値 0 → 外部レジスタ;レジスタ 0 → 最大値」を選んだ（決定 8）;Layer 1 はのちに Jump と Loop にこれを残し、Stay 0 は 4096 に絞った。7 月中旬、アーキテクトはこのイディオムの両方の読みを書いた: S_IND 廃止式（オペランド優先）と、7 月 16 日のプリスケーラの IND 逆パターン（外部優先）。本 trace は後者を Stay に適用し、前者を代替案として記録し、三度現れたこの型を文法として書き留めることを提案する。*（番号の注: プリスケーラの外部値化は RH029、登録ティックと生ティック外部化は RH030。）*

**Where the change lands / 変更の着地点:**

```verilog
// today (RH030) — the single substitution point
wire [CNT_W:0] stay_dur = (operand == 12'd0) ? (1'b1 << CNT_W) : {1'b0, operand};   // C2-F3
//   consumed only in OP_STAY:  bare same-clock timeup  (stay_cnt >= stay_dur - 1'b1)
//                              and the latch           stay_target <= stay_dur;
//   S_WAIT compares the latched stay_target — never stay_dur.

// proposed (C4-T5 lean B: read in the execute clock) — IND-reverse; one sample, two uses
input  tri0 [CNT_W-1:0] stay_value;                                   // 0 / unconnected => as written
wire   [CNT_W:0] stay_dur_lit = (operand == 12'd0) ? (1'b1 << CNT_W) : {1'b0, operand};   // C2-F3
wire   [CNT_W:0] stay_dur     = (stay_value != {CNT_W{1'b0}}) ? {1'b0, stay_value} : stay_dur_lit;
```

---

## Decision Points / 決定点

### DP-1 — Mechanism — how does a Formation give the Core a Stay length?
- **A — pin-level `stay_value`, the RH029 pattern.** An optional tri0 input read by the Stay; zero defers to the Core's own value. No handshake, no encoding change, no Core register or decode.
- **B — indirect-read bus with a new purpose code (2'b10 = Stay duration).** Reuses § 4.5, but a handshake stall (S_IND) would sit inside a timed interval; a trigger encoding is needed and Stay(0) is already C2-F3's 4096; and S_IND itself is a v1.2 abolition candidate, which the architect has described as likely harbouring a future bomb.
- **C — external-operation bus writes a Core-internal Stay register.** Bus decode and a reserved sub-opcode inside the Core — the same reasons the bus-register form of C4-T2 yielded to B′.
- **D — a new opcode (Stay-External).** Contradicts the standing discipline that new requirements never add Core opcodes; spends one of the 12 reserved opcodes on one Formation's need.
- **E — the Formation rewrites Stay operands in instruction memory.** Program-as-data, quantized by the barline rule, per-state by nature; but it exposes an imem write port (today ISMCE/JTAG only) and couples the Formation to the instruction encoding.
- **Chosen:** A (architect directive, 2026-09-26).
- **Rationale:** Nothing stalls inside a timed interval, the ISA is untouched, and the Core gains only a pin and a multiplexer; the Formation decides whether the pin is a constant, a register or a table. Tied 0 or left unconnected (tri0), every existing Formation and program behaves bit-identically to RH030. 'Where the Core extends, the Formation pays' (Chapter 4).

### DP-2 — Precedence — does the pin speak first (IND-reverse) or the operand (IND)?
- **A — external-first (IND-reverse).** D = pin ≠ 0 ? pin : (operand ≠ 0 ? operand : 4096). Every Stay consults the pin. The RH029 form, in the architect's words of 2026-07-16: external value if non-zero, the internal constant if zero, the sentinel if both are zero.
- **B — operand-first (IND).** D = operand ≠ 0 ? operand : (pin ≠ 0 ? pin : 4096). Only Stay(0) consults the pin; literal Stays never change. This is the architect's own S_IND-abolition formula (mid-July 2026) and the Stay case of 2026-05-13 decision 8 ('literal 0 → external register; register 0 → the maximum'), which Layer 1 later narrowed to 'Stay 0 = 4096 only'.
- **Chosen:** A — architect directive ('exactly the method used for the prescaler'), PROVISIONAL. B is recorded as the standing alternative.
- **Rationale:** A is the RH029 pattern verbatim and leaves C2-F3 and the § 4.2 classification of Stay(0) untouched: a silent pin leaves every program's written counts in force. With the execute-clock read of DP-4, A also yields per-state selectivity through the Formation — a table keyed by state_number returns 0 ('as written') for fixed Stays — so B's main advantage, program-marked selectivity, is recoverable at the Formation level. Cost of A, recorded: while the pin speaks, a program's written Stay counts are not authoritative; the Formation's table is, and a program written for a Stay-timing Formation should say so in its header (C5-V8 note). B would keep the program text authoritative (Stay(0) visibly asks the world) at the price of reclassifying Stay(0) from arithmetic shortcut to indirect mode and of making 4096 unreachable literally while the pin speaks; no program exercises C2-F3 yet, so B would break nothing today. Revisit only if the WPMS program model makes B materially simpler (Hook A).

### DP-3 — Read point — is the pin compared live during the wait, or read once when the Stay executes?
- **A — live.** As the prescaler pin is: every clock of the wait compares against the pin as it stands.
- **B — once, at the Stay's execute clock.** The value is latched into stay_target and holds for the whole Stay.
- **Chosen:** B — structural rather than preferred: the Core already latches the duration at execute (OP_STAY: `stay_target <= stay_dur`), so substituting the source at `stay_dur` inherits the latch.
- **Rationale:** Packet determinism: a Stay in progress is never stretched or cut by a pin change; the next Stay obeys. The live-write question left OPEN for the prescaler (2026-08-27 trace, DP-6 item 6) cannot arise for Stay — this is the barline rule applied to a pin. Windowed Stays are read when the Stay instruction executes, after the Stay Set and any in-window clocks, not at the Stay Set; if the window has already counted past the new terminal, RH028's `>=` fires on the first tick in S_WAIT.

### DP-4 — Sampling path — registered one clock ahead (RH029-literal), or read in the execute clock?
- **A — registered.** `stay_valueR <= stay_value` every clock; a Stay uses the pin as it stood in the clock before its execute (one-clock lookahead). The zero test must use the same registered sample.
- **B — read in the execute clock.** The pin feeds `stay_dur` combinationally and is latched at the end of the execute clock; the zero test and the value are one sample by construction.
- **Chosen:** OPEN — Tie C4-T5 (proposed); contributor's lean B.
- **Rationale:** RH029's register exists because the prescaler comparison runs every clock: taking the −1 off a continuously used path pays. For Stay the latch already keeps the pin off the S_WAIT comparator; the pin's only combinational consumer is the same-clock bare-timeup check, which already carries `stay_dur − 1` for the operand today. B enables the natural Formation idiom `stay_value = len_lut[state_number]` (state_number is the state being executed, C5-V5) with no lookahead and under any control flow; A makes that idiom need next-state knowledge, available only in straight-line programs. A's advantage is timing isolation of the Formation's path, decisive only if a Formation cannot meet a same-clock path at the Core's Fmax. Negative data, a predicted failure avoided by design: copying RH029-as-built — a zero test on the raw pin beside a registered value — would, when the pin turns 0→N at the edge that opens the execute clock, latch duration 0; `stay_target − 1` wraps to 0x1FFF and the Stay runs 8192 ticks, the very class RH028 retired (reproduced in an Icarus pre-check of patched copies, 2026-09-26: 8192 clocks at P = 1, while both correct forms pass). Whichever path: one sample, two uses (C5-F4). If A, the sampling register is a pure input pipeline and should carry no reset: a reset to 0 would force one 'as written' clock after reset release.

### DP-5 — Pin width — CNT_W (12) or CNT_W+1 (13)?
- **A — CNT_W = 12.** Pin values 1–4095; 4096 is reached by a silent pin plus Stay(0).
- **B — CNT_W+1 = 13.** Pin values 1–8191, using the stay counter's existing 13th bit at no counter cost.
- **Chosen:** OPEN pending the WPMS range answer (Hook A) — Tie C5-T2 (proposed); contributor's lean A.
- **Rationale:** The house grammar (T2) is 'a field of width W; zero escapes; the 2^W sentinel held by a W+1-bit counter': the prescaler pin is PRESC_W bits and both-zero means 2^PRESC_W (65536 at the default 16); a 12-bit Stay pin keeps both-zero meaning 4096, still the maximum. B gives the pin values beyond the sentinel, so 'both zero' would no longer mean 'the most'. Range is the prescaler's job (Chapter 2 § 2.4, C4-F1): the pin supplies a count, not a range. B remains available if WPMS needs more than 4096 ticks at a P it cannot raise.

### DP-6 — Compare discipline — do Formation-supplied durations inherit the stay counter's `>=`, or take the time-base's `==`?
- **A — inherit `>=` (RH028).** An already-passed deadline fires on the first tick in S_WAIT, the earliest realizable moment.
- **B — fail-loud `==` for Formation-supplied values.** A value below the elapsed count would wrap through 2^13.
- **Chosen:** A.
- **Rationale:** The pin changes where a Stay's number comes from, not what a Stay is. The fail-loud ruling of 2026-08-27 concerns the sovereign time-base, whose overrun is conceptually fatal; a Stay is a program duration where 'as fast as possible' is a legitimate idiom, and a windowed Stay handed a value shorter than its elapsed count should degrade to the earliest timeup, not wrap 8192. The asymmetry stands exactly as ruled: `==` for the time-base, `>=` for every Stay whatever its source.

---

## Themes / テーマ

**T1 — Same method, different object.** The prescaler is read every clock; a Stay is read once. The three RH029 moves — a tri0 pin, zero deferring to the Core's own value, the pin kept off the hot path — all transfer, but the latch at execute changes their weight: the live-write question vanishes; the register that protected the prescaler's comparator becomes a lookahead the Formation would pay for; and a one-clock zero-test slip that costs the prescaler one comparison would cost a Stay its whole length.

**T2 — Zero escapes: a grammar at its third occurrence.** C2-F3 (operand 0 → 4096); RH029 (pin 0 → PRESCALE, both 0 → 65536; architect, 2026-07-16); the S_IND-abolition formula (operand 0 → external, both 0 → 13'd4096; mid-July 2026); and now stay_value (pin 0 → operand, both 0 → 4096). Two readings — IND, operand first; IND-reverse, external first — and one sentinel rule: 2^W, held by a W+1-bit counter. The prior office observed that a form seen twice is grammar; at three it earns a Layer 1 entry (proposed C4-V4).

**T3 — Selectivity belongs to the Formation.** A global pin plus a table keyed by state_number gives per-state lengths while the Core stays a pin and a multiplexer. No opcode, no encoding change, no Core register file — the Core–Formation discipline holds again, and the program's written count remains the fallback whenever the table says nothing.

---

## Resumption Hooks / 再開フック

### Hook A — The WPMS program model — questions for the PTSG_WPMS_Formation office
**Description:** DP-4 and DP-5 turn on how WPMS will drive the pin, and DP-2 is confirmed or reopened by it. (1) One Formation-timed length per program, or one per packet? (2) Fixed-length Stays mixed with Formation-timed ones? (3) Driver: a constant register, `len_lut[state_number]`, or a sequencer on `stay_cnt_match`? (4) Longest Stay needed, in ticks, at the intended P (≤ 4095?). (5) Clock domain of the length source (C5-F1).
**Starting question:** Sketch one WPMS program — packet Stays and control states — and the table that would drive `stay_value` for it: does every Formation-timed Stay find its length from `state_number` alone?

### Hook B — RTL at the Layer 4 checkpoint
**Description:** The source stays frozen at RH030 during Live Session #1. The stay_value change is folded into the batched Hook C review and receives its RH number then. Regression: with the pin tied 0 the Core must be bit-identical to RH030 (T1/T2/T32/T34, the P=1 set, the Scene 4 seams). New tests SV-0…SV-7 are listed in the reference sketch, including Stay(0) with a silent pin — the first exercise of C2-F3. An Icarus pre-check of patched copies (`stay_value_sim_check/`) already reproduces all of them except the windowed SV-5; the checkpoint run on the real source is still owed.
**Starting question:** Which DP-4 path — and does a test built to catch the 8192-tick runaway fail on the anti-pattern and pass on the chosen form?

### Hook C — The grammar entry and the S_IND abolition
**Description:** T2 proposes Convention C4-V4 (literal zero + 2^W sentinel, read IND or IND-reverse). The v1.2 S_IND abolition would apply the IND reading combinationally to Jump and Loop, where the 13'd4096 sentinel lands on an address that does not exist.
**Starting question:** Write IND and IND-reverse as one Convention now, or at v1.2? For Jump, should the both-zero sentinel route to the Error-HALT vector (C3-F24), as the prior office suggested?

### Hook D — Silicon demonstration (Layer 4)
**Description:** Scene-4 style, with an ISSP probe on stay_value: blinky with the pin at 0 (as written) → pin N (every Stay Formation-timed) → pin changed mid-Stay (the next Stay obeys; the VCD shows the read at execute) → a two-entry table keyed by state_number (independent on/off lengths: per-state selectivity on camera).
**Starting question:** Which program and which trigger make the execute-clock read visible in a single VCD?

### Hook E — Hook C interplay — inputs, not rulings
**Description:** 'One sample, two uses' and 'a pure input pipeline carries no reset' arose here for Stay; the corresponding questions remain open for the prescaler (2026-08-27 trace, Hook C: zero-check timing; rst on presc_tick/presc_valueM).
**Starting question:** At the batched review: should the prescaler's zero test move onto the registered sample, and is presc_valueM's missing rst a defect or, by the same argument, correct?

### Hook F — Layer 1 write-back adoption
**Description:** The companion delta CHANGES_Layer1_stay-value_2026-09-26.md drafts Chapter 2 § 2.4, Chapter 4 (§ 4.2, new § 4.7a, § 4.10–4.12) and Chapter 5 (§ 5.2, § 5.10, new § 5.12a, § 5.15–5.16).
**Starting question:** After multi-LLM review: which items become Fixed (C4-F15–F17, C5-F4), which Convention (C4-V4, C5-V8), and which remain Tie (C4-T5, C5-T2)?

---

## Key Outputs for the Repository / リポジトリへの主要出力

- DIRECTIVE (architect, 2026-09-26): WPMS forms arbitrary-length packets with packet length = Stay length; the Core gains a Formation-supplied Stay duration by the RH029 method.
- `stay_value`: optional tri0 input; IND-reverse precedence — pin ≠ 0 → pin; pin = 0 → operand; operand 0 → 4096 (C2-F3). Tied 0 or unconnected: bit-identical to RH030.
- Read once per Stay, at its execute clock, and held (latched in stay_target) for the whole Stay; a pin change affects later Stays only. Windowed Stays are read when the Stay instruction executes, not at the Stay Set.
- Compare: RH028 `>=` inherited; the time-base keeps `==` (fail-loud) — the asymmetry stands as ruled.
- Tie C4-T5 (sampling path): registered one clock ahead vs read in the execute clock — lean: execute clock (enables `len_lut[state_number]`). Rule C5-F4: one sample, two uses. Anti-pattern documented: raw zero test + registered value → 8192-tick runaway (reproduced in the Icarus pre-check, SV-4/SV-7).
- Tie C5-T2 (pin width): CNT_W vs CNT_W+1 — lean CNT_W (both-zero stays the maximum; range is the prescaler's job).
- Formation idioms: a constant register (every Stay); `len_lut[state_number]` (per-state, 0 = as written; add `loop_counter` to the key for per-iteration lengths); a sequencer on `stay_cnt_match` (double buffer: at each pulse, present the length for the Stay after next).
- Unchanged: C2-F3 with a silent pin, C3-F20/F21, C4-F8–F11, phase lock (durations remain whole ticks). A Stay lasts D × P clocks; at P = 1, Stay-N lasts N clocks (RH028).
- Grammar: literal zero + 2^W sentinel, read IND or IND-reverse — proposed Convention C4-V4 (third occurrence).
- Alternatives recorded: indirect-read bus, external-operation register, new opcode, instruction-memory rewrite (DP-1); operand-first IND precedence (DP-2) — the architect's own mid-July formula and 2026-05-13 decision 8.
- Artifacts: Layer 1 delta `01_Architecture/CHANGES_Layer1_stay-value_2026-09-26.md`; reference sketch `03_Sample_Implementations/ptsg_core_verilog/stay_value_reference_sketch.md` (not applied — source frozen at RH030) with its Icarus pre-check kit `stay_value_sim_check/` (PASS); handoff `HANDOFF_to_PTSG_WPMS_Formation_2026-09-26.md`.
- Status: PROVISIONAL; the PTSG_WPMS_Formation office's Hook A answers settle DP-4/DP-5; multi-LLM review before codification.

---

## End of Trace / 軌跡の末尾

The score still says how long each note is. Now the conductor may say 'this long instead' — but only as the note begins, never in its middle. A note already sounding is neither stretched nor cut; the next one obeys. When the conductor is silent — zero — the note is played as written; and where the score itself is silent — zero — it lasts as long as a bar can hold. A packet is a note; its length, now, is the Formation's to give.

楽譜は今も各音の長さを記している。いま指揮者は『代わりにこの長さで』と告げられるようになった——ただし音の立ち上がりにだけ、音の途中では決して。鳴り始めた音は伸ばされも切られもせず、従うのは次の音である。指揮者が黙していれば——ゼロ——音は書かれたとおりに奏され、楽譜そのものが黙していれば——ゼロ——音は一小節が抱えうる限り長く続く。パケットは一つの音であり、その長さは、いまや Formation が与えるものとなった。

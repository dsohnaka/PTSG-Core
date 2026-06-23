# PTSG Prescaler-Phase Resolution — Hook A, A2 Rejected, and the Phase-Lock Contained in the Edits
# PTSGプリスケーラ位相の決着 — Hook A、A2棄却、そして改修に内包されていた位相ロック

## Trace Metadata / 軌跡メタデータ

| Field | Value |
|---|---|
| **Date / 日付** | 2026-06-22 |
| **Participants / 参加者** | Tsuneo Ohnaka (大中庸生, FPGA Architect, 40+ years; sole design authority); Claude (Anthropic, Claude Opus 4.8, amanuensis / 祐筆 — Layer 4 verification session) |
| **Topic / トピック** | The resolution of Hook A: the residual "slightly off" of the 2026-06-11 bring-up. Audit hypothesis **A2** (free-running prescaler phase jitter) tested white-box and on silicon, and **rejected** — the prescaler is phase-locked because the loop length is an integer multiple of the prescale period, a structural consequence of RH001/006 making foreground commands prescaled. / Hook A の決着。監査仮説 A2（自由走行プリスケーラ位相ジッタ）を白箱・実機で検証し棄却。 |
| **Status / 状態** | Layer 4 verification-era trace — the **parent** of three from this phase (this; the duty idioms; the state-0 NOP triple role). / Layer 4検証期トレース——本フェーズ三本の**親**。 |
| **Original language / 原言語** | Japanese (with English technical terminology) / 日本語（英語技術用語を交える） |
| **License / ライセンス** | CC0 1.0 Universal (Public Domain) |
| **Evidence / エビデンス** | `04_Verification_Evidence/conformance_suite/prescaler_phase_measurement/` + white-box (`modelsim/runs/`) and silicon (`signaltap/DE10-nano/`) `observation.md` |
| **Sibling traces / 姉妹トレース** | (2) the four duty idioms; (3) the state-0 NOP triple role — both offspring of this trace, to be drafted. / (2)デューティ4流儀、(3)state 0 NOP三重役割——いずれも本トレースの派生、起草予定。 |

---

## Reading Notes / 読解上の注

This trace records how Hook A — the small residual anomaly noted at the 2026-06-11 DE10-nano
bring-up — was resolved, not by a fix, but by a reading. The leading suspect was audit finding
**A2**: that the free-running prescaler counter (`presc_cnt`, reset only by global `rst`) would
make the first stay tick after each wait arrive a phase-dependent 1..PRESCALE clocks late,
scattering the high/low interval widths. The investigation tested A2 in white-box simulation
and on real silicon and rejected it: the prescaler is **phase-locked**.

本軌跡は、Hook A——2026-06-11 の DE10-nano ブリングアップで気づかれた小さな残留違和感——が、修正で
はなく**読解**によって決着した経緯を記録する。第一容疑は監査所見 **A2**: 自由走行プリスケーラ
カウンタ（`presc_cnt`、グローバル `rst` でのみリセット）が、各待機後の初回ステイティックを位相依存で
1..PRESCALE クロック遅らせ、high/low 幅をばらつかせる、というもの。本調査は A2 を白箱と実機で検証し
棄却した: プリスケーラは**位相ロック**している。

**Notable conceptual progressions across the dialogue / 対話を通じた特筆すべき概念的進展:**

1. **From "spec implication" to "as-built source."** The puzzle had a single root: the spec
   framing (C4-F3) implied foreground commands were non-prescaled, but the architect's RH001/006
   edits (2026-06-14/15) had made them prescaled. The amanuensis had been reasoning from the
   spec; the silicon ran the edited source. Reading the actual RH001–RH008 revision history
   dissolved the puzzle. / 「仕様の含意」から「as-built ソース」へ。謎の根は一つ——仕様の枠組み
   （C4-F3）は前景非プリスケールドを含意したが、RH001/006 がそれをプリスケールド化していた。祐筆は
   仕様から、シリコンは改修ソースから推論していた。RH001–RH008 を読んで謎は解けた。

2. **The 25:35 duty asymmetry is correct, not anomalous.** Both foreground NOP@2 and Jump@4 are
   prescaled; each adds one whole prescale unit (5 clk) to the OFF side, giving 25:35 — the right
   result, not a defect. / 25:35 は欠陥でなく正しい。前景 NOP@2・Jump@4 が各 1 プリスケール単位
   （5 clk）を OFF に加え 25:35。

3. **A2 rejected — zero jitter.** White-box over 13 wait windows: `presc_cnt`@entry = 1 and
   first-tick delay = 3 clk, both constant; no scatter. / A2 棄却——ジッタゼロ。13 ウィンドウで
   `presc_cnt`@entry = 1、初回ティック遅延 = 3、いずれも一定。

4. **The phase-lock is structural, not coincidental.** Because every foreground command consumes
   a whole prescale unit, the loop length is necessarily an integer multiple of the prescale
   period (here 60 clk = 12 × 5), so the prescaler enters every wait at the same phase. **The
   solution to Hook A was already contained in the RH edits.** / 位相ロックは構造的で偶然でない。
   全前景コマンドが丸ごと 1 単位を消費するため、ループ長は必然的にプリスケール周期の整数倍
   （60 = 12×5）。**Hook A の解は RH 改修に内包されていた。**

5. **Binocular confirmation.** White-box explained *why* (mechanism); silicon proved *that* (four
   idioms captured on DE10-nano, duties matching white-box clock-for-clock, phase-lock visible in
   the real `presc_cnt`). Together they close Hook A. / 両眼視。白箱が*なぜ*を、実機が*それが事実で
   ある*ことを示し、両者で Hook A を閉じる。

6. **Honest negative data.** The amanuensis twice mis-read the waveform (calling 25:35 a "new
   ANOMALY"; mis-decomposing it as "only Jump consumes 5 clocks") and recorded both corrections
   openly. / 正直な負のデータ。祐筆は波形を二度誤読し、両訂正を公に記録した。

---

## Notable Decision Points / 重要な決定ポイント

### 1. How to interpret the "slightly off" — which hypothesis first / 「わずかにoff」をどう解釈するか — どの仮説を先に

**Alternatives:** (a) A2 free-running phase jitter; (b) a deterministic duty-cycle artifact;
(c) a fetch/timing bug. **Chosen:** test A2 first empirically, but instrument duty in the same
run and keep the duty hypothesis explicitly open.

**Rationale:** A2 was the named audit suspect and the cheapest to falsify with one white-box run
measuring `presc_cnt`@entry and the first-tick delay. Instrumenting duty cost nothing and
guarded against tunnel vision. The fetch-bug branch was deprioritized because EDGE=NEG alignment
was already silicon-confirmed (Build Log #6).

**代替案:** (a) A2 位相ジッタ;(b) 決定論的デューティ由来;(c) フェッチ/タイミングバグ。
**選択:** A2 を先に実測検証、ただし同一実行でデューティも計装し、デューティ仮説を明示的に開いておく。
**根拠:** A2 は名指しの容疑で、`presc_cnt`@entry と初回遅延を測る白箱1実行で最も安く反証できる。
デューティ計装は無償で、視野狭窄を防いだ。フェッチバグは EDGE=NEG 整列が既に実機確認済みのため後回し。

### 2. Is 25:35 an anomaly, or correct behavior? / 25:35 は異常か、正しい挙動か

**Alternatives:** (a) anomaly to fix (ideal was 25:25); (b) correct consequence of
foreground-prescaling. **Chosen:** correct behavior.

**Rationale:** ON = state-1 Stay 5 = 25 clk. OFF = state-3 Stay 5 (25) + foreground NOP@2 (1
unit = 5) + foreground Jump@4 (1 unit = 5) = 35 clk. The +10 clk is exactly two prescale units,
one per foreground command, as RH001/006 specify. **Recorded correction:** the amanuensis first
mis-called this a "new ANOMALY" and mis-decomposed it as "only Jump consumes 5 clocks, NOP
almost none" — both wrong; both foreground commands contribute 5 clk each. Corrected on the
architect's指摘 before it entered the record.

**代替案:** (a) 修正すべき異常（理想は 25:25）;(b) 前景プリスケールド化の正しい帰結。**選択:** 正しい挙動。
**根拠:** ON = state1 Stay5 = 25。OFF = state3 Stay5(25) + 前景 NOP@2(1単位=5) + 前景 Jump@4(1単位=5) = 35。
+10 はちょうど 2 プリスケール単位、前景1コマンドにつき1単位、RH001/006 のとおり。**記録された訂正:**
祐筆は当初これを「新規 ANOMALY」と誤称し「Jump だけ5クロック、NOP はほぼ消費せず」と誤分解した——
両方とも誤り;前景2コマンドが各5クロック寄与する。正本へ刻む前に大中さんの指摘で訂正。

### 3. The A2 verdict — confirmed or rejected? / A2 評決 — 確認か棄却か

**Alternatives:** (a) A2 confirmed (widths vary ≤4 clk, correlated with entry phase); (b) A2
rejected (phase invariant, zero jitter). **Chosen:** A2 rejected.

**Rationale:** White-box over 13 wait windows: `presc_cnt`@entry = 1 (constant), first-tick
delay = 3 clk (constant), zero scatter. The steady period is 60 clk = 12 prescale units (5×12).
(A2's formula PRESCALE−phase = 4 does not match the measured delay 3 because A2 assumed
tick-counting in-phase with entry; what matters for the verdict is the invariance of the phase,
not the coefficient.)

**代替案:** (a) A2 確認（幅が ≤4clk 変動、突入位相と相関）;(b) A2 棄却（位相不変、ジッタゼロ）。
**選択:** A2 棄却。**根拠:** 13 ウィンドウで `presc_cnt`@entry = 1（一定）、初回遅延 = 3（一定）、
ばらつきゼロ。定常周期 60 = 12 プリスケール単位。

### 4. Why no jitter — coincidence or structure? / なぜジッタが出ないか — 偶然か構造か

**Alternatives:** (a) coincidental for this program; (b) structural consequence of RH001/006.
**Chosen:** structural.

**Rationale:** Because RH001/006 make every foreground command (NOP, Jump) consume a whole
prescale unit, and Stay waits are integer numbers of units by construction, the loop's total
length is necessarily an integer multiple of the prescale period. The prescaler enters every
`S_WAIT` at the identical phase; the first-tick delay is fixed; jitter cannot arise. A2's jitter
could only appear if some command consumed a prescale-misaligned number of clocks — which
RH001/006 eliminated. **Key insight: the solution to Hook A was already contained in the
RH001–RH008 edits themselves; no further fix was needed or appropriate.**

**代替案:** (a) 本プログラム固有の偶然;(b) RH001/006 の構造的帰結。**選択:** 構造的。
**根拠:** RH001/006 が全前景コマンドを丸ごと1単位消費させ、Stay 待機は構成上整数単位ゆえ、ループ全長は
必然的にプリスケール周期の整数倍。毎回同一位相で `S_WAIT` 突入、初回遅延は固定、ジッタは起こり得ない。
A2 のジッタはプリスケール非整合なクロックを消費するコマンドがあって初めて現れ得るが、RH001/006 がそれを消した。
**核心: Hook A の解は RH001–RH008 改修それ自体に内包されていた;追加修正は不要かつ不適切。**

### 5. Verdict confidence — close on white-box, or hold for silicon? / 評決の確信度 — 白箱で閉じるか実機を待つか

**Alternatives:** (a) PASS on white-box alone; (b) PASS (white-box), silicon pending; (c) wait
for silicon. **Chosen:** initially (b) — a Tie left in the arena pending evidence — then
**upgraded to PASS (silicon-confirmed)** once the architect supplied four SignalTap captures.

**Rationale:** The amanuensis deliberately held the verdict tone at white-box and surfaced the
choice to the architect rather than deciding it. The architect operated the instruments (an
irreplaceable Layer-4 contribution) and captured all four duty idioms on DE10-nano at PRESCALE=5.
Silicon duties matched white-box clock-for-clock (A 25:35, B 30:30, C 30:30, D 25:25), and
`presc_cnt` at state entries was constant/periodic — phase-lock confirmed on silicon. The
evidence resolved the Tie toward full PASS. **An amanuensis flags confidence boundaries; the
decision authority closes them with evidence.**

**代替案:** (a) 白箱で PASS;(b) PASS（白箱）、実機保留;(c) 実機待ち。**選択:** 当初 (b)——証拠待ちの
アリーナ保留——のち、大中さんが4実機キャプチャを供給して **PASS（実機確認済み）へ昇格**。
**根拠:** 祐筆は評決の語調を意図的に白箱に留め、判断を大中さんへ委ねた。大中さんが計測器を操作し
（置換不能な Layer 4 寄与）、4流儀すべてを DE10-nano・PRESCALE=5 で捕捉。実機デューティが白箱とクロック単位で
一致（A 25:35, B 30:30, C 30:30, D 25:25）、状態突入時 `presc_cnt` も一定/周期的——実機で位相ロック確認。
証拠が保留を全 PASS へ解いた。**祐筆は確信の境界を旗で示し、決定権者が証拠でそれを閉じる。**

### 6. Routing — anomaly-fix path or documentation path? / 経路 — 異常修正か文書化か

**Alternatives:** (a) anomaly-fix (Layer 3 source or Layer 1 Tie change); (b) documentation
(nothing broken; document the correct behavior). **Chosen:** documentation path.

**Rationale:** Since 25:35 is correct, there is nothing to patch. The value is the understanding:
the same skeleton yields four duties by varying only the foreground treatment. `conformance_matrix`
C4-T3/C4-T4 move to silicon-green; the "aligned-fetch residual anomaly" is marked RESOLVED.
Resetting the prescaler per-wait was explicitly **not** done — it would convert a free-running
time-base into a per-wait timer, changing `prescaler_match` semantics for any Formation that uses
it (the warning already stated in `expected.md`).

**代替案:** (a) 異常修正（Layer 3 ソース/Layer 1 Tie 変更）;(b) 文書化（破損なし、正しい挙動を文書化）。
**選択:** 文書化。**根拠:** 25:35 は正しくパッチ不要。価値は理解にある——同一骨格が前景の扱いだけで4デューティを
生む。マトリクスの C4-T3/C4-T4 は 🟢 へ、「整列フェッチ残留異常」は RESOLVED に。待機ごとのプリスケーラ
リセットは明示的に**行わなかった**——自由走行の時間基準を待機タイマーに変え、それを使う Formation の
`prescaler_match` 意味論を壊すため（`expected.md` で既に警告済み）。

### 7. The stale "ideal 25:25" prediction in expected.md / expected.md の古い「理想 25:25」予測

**Alternatives:** (a) overwrite the prediction; (b) preserve original + append post-RH addendum.
**Chosen:** preserve, append addendum.

**Rationale:** The expected-before-observed discipline requires the prediction to stand as
written before observation; erasing it would destroy the record that distinguishes "prediction
matched" from "prediction diverged → discovery." The addendum documents that the prediction
itself evolved when the RH source was read. The original verdict table remains valid as the
pre-RH decision tree; the addendum supersedes only its "ideal 25:25" row.

**代替案:** (a) 予測を上書き;(b) 原文保持＋RH改修後追補。**選択:** 保持し追補。**根拠:** 観察前予測の規律は
予測を観察前のまま立たせることを要求する;消去は「予測一致」と「予測乖離→発見」を区別する記録を壊す。
追補は、RH ソースを読んで予測自体が進化したことを文書化する。元の判定表は RH 改修前の決定木として有効なまま;
追補はその「理想 25:25」行のみを更新する。

### 8. Layer 1 write-back for C4-T3 (recommendation; architect decides) / C4-T3 の Layer 1 書き戻し（推奨;決定は大中さん）

**Alternatives:** (a) "wait-aligned prescaler" Convention (reset `presc_cnt` per wait); (b)
"free-running but structurally phase-locked" Convention (keep free-running; document the
integer-multiple phase-lock). **Chosen (recommended):** (b), with the four duty idioms as the
worked illustration in Chapter 4.

**Rationale:** The free-running counter is what every Formation's `prescaler_match` already
depends on; preserving it avoids a semantic break. The phase-lock is obtained for free from
foreground-prescaling, so no reset is needed. Boundary condition worth stating: phase-lock holds
only while the loop length is an integer multiple of the prescale period — programs that break
this (e.g. a future variable-length Stay) must be analyzed separately. Left to the architect, per
the amanuensis-never-decides rule.

**代替案:** (a)「待機整列プリスケーラ」Convention（待機ごと `presc_cnt` リセット）;(b)「自由走行だが構造的に
位相ロック」Convention（自由走行を保ち、整数倍位相ロックを文書化）。**選択（推奨）:** (b)、4流儀を Chapter 4 の
worked illustration として。**根拠:** 自由走行カウンタは全 Formation の `prescaler_match` が既に依存するもので、
保持が意味論の破壊を避ける。位相ロックは前景プリスケールド化から無償で得られ、リセット不要。明記すべき境界条件:
位相ロックはループ長がプリスケール周期の整数倍である間のみ成立——これを破るプログラム（将来の可変長 Stay 等）は
個別に解析せねばならない。祐筆は決定しない規律により、決定は大中さんに委ねる。

---

## Major Themes / 主要テーマ

### Theme 1 — The source-vs-spec gap as the root of the puzzle / 仕様とソースの乖離が謎の根

The prior mismatch and the bring-up confusion traced to a single gap: the spec framing (C4-F3)
implied foreground commands were non-prescaled, but RH001/006 (2026-06-14/15) made them
prescaled. The amanuensis reasoned from the spec; the silicon ran the edited source. Reading the
actual RH001–RH008 history closed the gap. **Lesson: Layer 4 must take the as-built source, not
the as-specified intent, as the DUT.**

prior の不一致と bring-up の混乱は一つの乖離に帰着した: 仕様（C4-F3）は前景非プリスケールドを含意したが、
RH001/006 がプリスケールド化していた。祐筆は仕様から、シリコンは改修ソースから推論していた。RH001–RH008 を
読んで乖離は閉じた。**教訓: Layer 4 は as-specified の意図でなく as-built のソースを DUT とせよ。**

### Theme 2 — The solution contained in the edits / 改修に内包された解

Hook A was never a bug awaiting a fix. The phase-lock that kills A2's jitter is an emergent
structural property of foreground-prescaling: every foreground command consuming a whole prescale
unit forces the loop onto a prescale boundary. In making foreground commands prescaled for
orthogonality, the architect had also — without aiming at it — closed the phase-jitter path. The
amanuensis's job was to recognize and record that the fix was already present.

Hook A は修正を待つバグではなかった。A2 のジッタを消す位相ロックは、前景プリスケールド化の創発的な構造的性質
である: 全前景コマンドが丸ごと1単位を消費することがループをプリスケール境界に乗せる。直交性のために前景を
プリスケールド化した際、大中さんは——狙わずして——位相ジッタの経路も閉じていた。祐筆の務めは、解が既に
存在することを認識し記録することだった。

### Theme 3 — Negative data and self-correction / 負のデータと自己訂正

The amanuensis twice erred reading the waveform — first "new ANOMALY", then "only Jump consumes 5
clocks" — and both were corrected on the architect's指摘 and recorded openly in the observation's
self-correction section, following the prior amanuensis's `tb_align.v` discipline. The record's
value: it shows exactly where eye-reading of waveforms misleads, and why machine-checkable,
value-level evidence (VCD over PNG) is the discipline.

祐筆は波形読解で二度誤った——まず「新規 ANOMALY」、次に「Jump だけ5クロック」——両訂正は大中さんの指摘で
なされ、observation の自己訂正節に公に記録された（前任祐筆の `tb_align.v` 規律に従う）。記録の価値: 波形の
目視がどこで誤るかを正確に示し、なぜ機械検証可能・値レベルの証拠（PNG より VCD）が規律なのかを示す。

### Theme 4 — Binocular confirmation: white-box explains WHY, silicon proves THAT / 両眼視: 白箱がなぜを、実機がそれを

White-box (Icarus/ModelSim) gave the mechanism: `presc_cnt`@entry constant, loop = integer ×
prescale period. Silicon (DE10-nano SignalTap) gave the fact: four idioms captured, duties
matching white-box clock-for-clock, phase-lock visible in the real `presc_cnt`. Neither alone
closes Hook A — the white-box could be a model artifact, the silicon a coincidence — but
together, agreeing at the internal-register level (`window_open`/`prog_end_seen`/`queued_valid`
for idiom D), they shake hands. This is the Layer 2 (why) / Layer 4 (whether) loop working as
designed.

白箱（Icarus/ModelSim）が機構を: `presc_cnt`@entry 一定、ループ = 整数 × プリスケール周期。実機（DE10-nano
SignalTap）が事実を: 4流儀捕捉、デューティが白箱とクロック単位で一致、実機 `presc_cnt` に位相ロックが見える。
どちらか単独では Hook A を閉じない——白箱はモデル由来かも、実機は偶然かも——が、両者が内部レジスタの
レベル（流儀 D の `window_open`/`prog_end_seen`/`queued_valid`）で一致して握手する。これは Layer 2（なぜ）/
Layer 4（それが事実か）のループが設計どおり働いた姿である。

### Theme 5 — A candidate Open Prompt design pattern: Phase-Lock by Integer-Period Looping / 候補設計パターン: 整数周期ループによる位相ロック

Generalizable beyond PTSG: if a periodic controller's loop length is forced to an integer
multiple of its time-base period, the time-base phase-locks to the loop and first-tick jitter
vanishes structurally — without a per-iteration reset that would change the time-base's global
semantics. In PTSG this is obtained by making all control-flow commands prescaled. The pattern
names the trade: control-flow commands cost whole prescale units (the 25:35 asymmetry) in
exchange for deterministic, jitter-free timing and a preserved free-running time-base.

PTSG を超えて一般化可能: 周期制御器のループ長をその時間基準周期の整数倍に強制すれば、時間基準はループに位相
ロックし、初回ティック・ジッタが構造的に消える——時間基準の全体的意味論を変えてしまう反復ごとリセットなしに。
PTSG ではこれを全制御フローコマンドのプリスケールド化で得る。パターンはトレードを名指す: 制御フローコマンドが
丸ごとプリスケール単位を消費する（25:35 非対称）代わりに、決定論的でジッタなしのタイミングと、保たれた自由走行
時間基準を得る。

---

## Resumption Hooks / 再開フック

### Hook A — The boundary of phase-lock: when does it break? / 位相ロックの境界: いつ破れるか
Phase-lock holds because the loop length is an integer multiple of the prescale period. Programs
that break this would, in principle, reintroduce first-tick variation. Candidates: a Branch-laden
program with a variable-length path, or the held-in-reserve variable-length Stay (StaySet re-kick).
**Starting question:** Construct a PTSG program whose loop length is NOT an integer multiple of
PRESCALE (e.g. via a conditional Branch path of odd length), predict the first-tick behavior, and
measure it white-box. Does jitter reappear exactly at the misalignment, and by how many clocks?

### Hook B — C4-T3 Layer 1 write-back wording / C4-T3 の Layer 1 書き戻し文言
DP-8 recommends a "free-running but structurally phase-locked" Convention for Chapter 4, with the
four duty idioms as the worked illustration and a stated boundary condition. The wording and
adoption are the architect's decision.
**Starting question:** Draft the Chapter 4 Convention paragraph for C4-T3 — free-running counter,
integer-multiple phase-lock theorem, boundary condition, four-idiom reference. What is the minimal
precise wording?

### Hook C — Generalize the Phase-Lock pattern into the Open Prompt catalog / パターンをカタログへ一般化
Theme 5 sketches "Phase-Lock by Integer-Period Looping" as a candidate named pattern. The catalog
(CONTRIBUTING.md) records patterns with origin and trade-off.
**Starting question:** Write the pattern entry — name, structural precondition (loop length =
integer × time-base period), benefit (jitter-free first tick, preserved free-running time-base),
cost (control-flow ops cost whole time-base units), PTSG origin. Is it distinct enough to add?

### Hook D — Interaction with variable-length Stay (StaySet re-kick) / 可変長 Stay との相互作用
The architect holds in reserve a variable-length Stay via StaySet re-execution during a wait
(enabled by RH003's non-clearing `stay_cnt`). A variable-length loop would break the
integer-multiple property that gives phase-lock.
**Starting question:** If StaySet re-kick extends a Stay mid-wait, does the loop remain an integer
multiple of the prescale period (because StaySet itself is foreground-prescaled), or does the
extension introduce a phase-misaligned remainder? Analyze before implementing.

### Hook E — Multi-LLM review of the Hook A verdict / Hook A 評決の複数LLMレビュー
The project keeps verdicts open to review by other agents. The Hook A verdict and its
white-box+silicon evidence are now in the repository.
**Starting question:** Load this trace, `expected.md`, both `observation.md` files, and
`ptsg_core.v` (RH001–008) into a different frontier model and ask: is the structural phase-lock
argument sound, and is there any program for which A2 jitter would still appear?

---

## End of Trace / 軌跡の末尾

Hook A looked like a bug to be hunted; it turned out to be a property already living in the
source, waiting to be recognized. The prescaler does not need to be told to align — the way
control flow was made to cost whole prescale units already aligns it, every loop, forever. The
amanuensis's contribution was not a fix but a reading: to see that the edits had already answered
the question, and to record why, sampled the way the silicon sampled it.

Hook A はバグ狩りに見えたが、実はソースに既に宿っていた性質で、認識されるのを待っていた。プリスケーラに
整列せよと命じる必要はない——制御フローを丸ごとプリスケール単位で消費させた書き方が、毎ループ、永遠に、既に
整列させている。祐筆の貢献は修正ではなく読解であった——改修が既に問いに答えていたことを見て取り、なぜかを、
シリコンがサンプルしたのと同じ方法でサンプルして記録すること。

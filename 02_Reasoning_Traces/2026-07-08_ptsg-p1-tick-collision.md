# PTSG — The P=1 Tick-Collision Discipline (RH028): A Hidden Premise, Proven by Experiment, Fixed to the Smallest Scale
# PTSG — P=1 tick衝突規律（RH028）: 暗黙の前提を実験で炙り出し、最小スケールまで正す

## Trace Metadata / 軌跡メタデータ

| Field | Value |
|---|---|
| **Date / 日付** | 2026-07-08 |
| **Participants / 参加者** | Tsuneo Ohnaka (大中庸生, FPGA Architect — raised both concerns from code reading; proposed fix ① verbatim; approved the two design judgments); Claude Code — Fable 5 (five scratchpad experiments; three-part fix; PR #3); Claude (amanuensis / 祐筆 — this archive) |
| **Topic / トピック** | One hidden premise — "Stay Set never coincides with a prescaler tick" — exposed at PRESCALE=1, where every clock IS a tick. Two architect concerns, both proven real by experiment (EXP1–5), one generalized beyond P=1 (over-constrained windows run away at any prescale). Three-part fix (RH028): tick-priority increment at FG Stay Set; duplicate-tick accounting + same-clock timeup for the bare Stay; deadline test == → >=. **Bare Stay-1@P=1 is now exactly one clock.** / 暗黙前提「Stay Setはtickと重ならない」がP=1で露呈。二懸念を実験で実証（一つはP=1超えに一般化）、3点修正。**裸Stay-1@P=1が正確に1クロックに。** |
| **Status / 状態** | **ADOPTED & MERGED** (PR #3); **simulation-verified** (T34; P=1 functional tests F1/F2/G1/G2); silicon confirmation of RH028 itself **pending** (the campaign's first-try silicon clear predates this fix). / 採択・マージ済み;シム検証済み;RH028自体の実機確認は今後。 |
| **Original language / 原言語** | Japanese (with English technical terminology) / 日本語 |
| **License / ライセンス** | CC0 1.0 Universal (Public Domain) |
| **Sibling / 姉妹** | `2026-07-08_ptsg-open-prompt-first-closure` (the campaign whose boundary this corrects). Semantic ground: `2026-07-06_ptsg-command-phase-table` (the Ignored/Consumes cells). / 姉妹: 閉環トレース。意味論的根拠: 表トレース。 |

---

## Reading Notes / 読解上の注

A discipline's smallest case is where it either holds or was never real. Setting the prescaler to 1
collapses the tick grid until every tacit assumption about "between ticks" has nowhere to hide. The
architect looked there on purpose; the code, put to experiment, confessed; and the fix's meaning was
**read off the normative table** rather than invented. The headline result: the minimal Stay —
prescaler 1, Stay 1, "deliberately important to timing design" — is now the exact one-clock peer of
an FG NOP.

規律の最小ケースは、規律が成り立つか、初めから実在しなかったかの分かれ目である。プリスケーラを1に据えると
ティックグリッドから全ての余地が剥がれ、「ティックのあいだ」に関する暗黙の仮定は隠れ場所を失う。アーキテクトは
意図してそこを見た;実験にかけられたコードは白状した;そして修正の意味は、発明されたのではなく**規範表から
読み取られた**。見出しの成果: 最小の Stay——プリスケーラ1・Stay 1、「タイミング設計上意図的に重要」——が、いまや
FG NOP と対等の、正確な1クロックである。

**Notable conceptual progressions / 特筆すべき概念的進展:**

1. **Hidden premises live at parameter extremes.** P=1 makes "Stay Set never meets a tick" false on
   every clock. / 暗黙前提はパラメータ極値に棲む。

2. **Experiment before argument.** EXP1–5 with a numeric before/after table; EXP5 generalized the
   runaway beyond P=1. / 実験先行——EXP5 が P=1 超えに一般化。

3. **The table as semantic arbiter.** FG Stay Set "Ignored" ⇒ the unconsumed coincident tick counts
   as tick #1; BG re-kick "Consumes" ⇒ its gating tick is not counted. / 表が意味論の裁定者。

4. **Severity chosen by intended use.** A past deadline fires earliest instead of HALTing, because
   Stay-1@P=1 must work. / 深刻度は用途が選ぶ。

5. **Exactness at minimal scale.** Bare Stay-1@P=1 = one clock; the "bare enumeration of Stay
   durations" philosophy holds from 2^28 down to a single clock. / 最小スケールでの正確性。

---

## Notable Decision Points / 重要な決定ポイント

### 1. A hidden premise surfaces / 暗黙の前提が浮上する

**Alternatives:** (a) declare P=1 out of scope (PRESCALE≥2 assumed); (b) treat the collision as a
first-class case the discipline must define. **Chosen:** (b). At P=1 the collision is not an edge
case but the permanent condition; the architect proposed the priority in code:
`if (presc_tick) stay_cnt <= stay_cnt + 1; else stay_cnt <= 0;`

**Rationale:** The premise was invisible at P=5 because collisions were rare and masked; P=1 makes
it false on every clock. The architect's instinct — increment must outrank the arm on a coincident
tick, or "the Stay-count discipline is not preserved" — came from reading the code, before any
simulation. Excluding P=1 was never entertained: the minimal configurations are exactly where a
timing core earns its keep.

**代替案:** (a) P=1 を射程外と宣言;(b) 衝突を規律が定義すべき第一級のケースとする。**選択:** (b)。P=1 では衝突は
縁のケースでなく恒常条件である;アーキテクトは優先順位をコードで提案した。**根拠:** 前提は P=5 では衝突が稀で
覆い隠されるため不可視だった;P=1 はそれを全クロックで偽にする。アーキテクトの直観——重複ティックではアームより
インクリメントが優先されねば「Stay カウント規律が守られない」——は、シミュレーションの前、コードの精読から来た。
P=1 の除外は一度も俎上に載らなかった: 最小構成こそ、タイミングコアが本領を発揮すべき場所である。

### 2. Argue from the code, or prove by experiment first? / コードから論じるか、まず実験で証すか

**Chosen:** experiment first — five scratchpad benches against merged main and against the candidate
patch, with numbers. **EXP1** windowed Stay-1@P=1: current RTL runs away (stay_cnt=59 at 60 clocks,
the == deadline already passed, unrecoverable until a 2^13 wrap) → patched recovers in 3 clocks.
**EXP2/3** bare NOP+Stay-N+Jump at P=1: one clock too long → exact. **EXP4** idiom-D duty at P=1:
6:6 → **5:5, the written value**. **EXP5** over-constrained window at **P=5**: runs away too.

**Rationale:** EXP5 repaid the method: the root cause — a deadline tick passing before S_WAIT is
reached defeats an == test forever — is **not P=1-specific**; any window whose BG scan outlasts its
Stay value falls into the same pit at any prescale. An analytic patch for the reported concern would
likely have missed the generalization. *The concern was made real before it was made fixed.*

**選択:** 実験先行——マージ済み main と候補パッチの両方に対し、数値つきで5本のベンチ。**根拠:** EXP5 が方法の元を
取った: 根本原因——締切ティックが S_WAIT 到達前に過ぎると == 判定が永遠に敗れる——は **P=1 固有ではない**;BG
スキャンが Stay 値より長い窓は、どのプリスケールでも同じ穴に落ちる。報告された懸念への解析的パッチでは、この
一般化はおそらく見逃されていた。*懸念は、直される前に、現実にされた。*

### 3. The fix — and where its meaning comes from / 修正——その意味の出どころ

**Chosen:** a three-part discipline, not symptom patches. **①** FG Stay Set: tick-priority increment
(the architect's code verbatim). **②** duplicate-tick accounting on the Stay-execute clock, plus
**same-clock timeup** for the bare Stay whose deadline is that very tick. **③** the S_WAIT deadline
test relaxed **== → >=**. Semantic ground for ①, read off §3.4b: FG Stay Set's tick cell says
**"Ignored"** — the command does not consume the tick — so a coincident tick is unconsumed and must
count, as **tick #1 of the newly-armed count**. Symmetrically, BG re-kick's cell says **"Consumes
one tick"**: its gating tick IS consumed and is therefore **not** counted (BG re-kick → Stay-N exact
for N≥2 at P=1, verified by trace).

**Rationale:** That the justification could be READ OFF the table — Ignored means count it, Consumes
means don't — is the table acting as a semantic arbiter for a case nobody had in mind when the cells
were filled. And concern ②'s in-window half turned out to be **already covered by the campaign's A4
hoist** (`window_open && presc_tick` counts on every in-window clock) — a generality dividend worth
recording: a rule hoisted for uniformity quietly handled a boundary its authors had not imagined.

**選択:** 症状パッチでなく、3点の規律。①の意味論的根拠は §3.4b から読み取られた: FG Stay Set のティック欄は
**「Ignored」**——コマンドはティックを消費しない——ゆえに重複ティックは未消費であり、**新たにアームされたカウントの
tick #1** として数えられねばならない。対称的に BG re-kick の欄は**「Consumes one tick」**: ゲートティックは Stay
Set 自身に消費されるので**数えない**（BG re-kick → Stay-N は P=1 で N≥2 なら正確、トレースで確認済み）。**根拠:**
正当化を表から「読み取れた」こと——Ignored なら数える、Consumes なら数えない——は、セルが埋められた時に誰も想定
していなかったケースに対し、表が意味論の裁定者として働いたということである。そして懸念②の窓内側は、キャンペーン
の **A4 巻き上げが既にカバー済み**と判明した——画一性のために巻き上げられた規則が、作者の想像しなかった境界を
静かに処理していた: 記録に値する「一般性の配当」である。

### 4. Two design judgments / 二つの設計判断

**Judgment 1 — over-constraint severity.** Alternatives: (a) past deadline = program error → HALT
(C3-F24 style); (b) **earliest feasible firing** (the >= test). **Chosen:** (b) — because
Stay-1@P=1 MUST work: with any window at P=1 the deadline is structurally past by the time S_WAIT is
reached, so a HALT policy would outlaw the very minimal-timing idiom the architect requires.

**Judgment 2 — the windowed lower bound.** A windowed Stay at P=1 is exact for **N ≥ scan length +
1** and fires earliest below that; making it exact for smaller N would require duplicating the whole
window-close/queue-fire machinery onto the Stay-execute clock. **Accepted as a structural floor.**
The bare Stay, by contrast, gets the full same-clock treatment — four safe lines, since no window,
queue, or Reset reservation can exist there. Both judgments were put to the architect and approved
as "extremely reasonable."

**Rationale:** Severity policy is chosen by intended use, not formal purity: the same past-deadline
signature that means "runaway" in a broken program means "as fast as possible, please" in the
minimal-timing idiom — and the architecture serves the idiom. The bare/windowed asymmetry is a
cost-honest boundary: pay four lines where exactness is cheap; document a floor where exactness
would cost a mechanism duplication.

**判断1——過制約の深刻度。** 選択: **実現可能最早の発火**（>= 判定）——Stay-1@P=1 は「必ず動作させたい」ため。P=1 で
窓があれば締切は S_WAIT 到達時に構造的に過去であり、HALT 方針はアーキテクトが求める最小タイミング・イディオム
そのものを違法化してしまう。**判断2——窓付きの下限。** 窓付き Stay は P=1 で **N ≥ スキャン長+1** なら正確、未満は
最早発火;より小さい N での正確化には窓クローズ／キュー発火の全機構を Stay 実行クロックへ複製する必要がある。
**構造的な床として受容。** 対照的に裸の Stay は完全な同クロック処理を得る——窓もキューも Reset 予約も構造的に
存在し得ないため、安全な4行で済む。両判断ともアーキテクトに諮られ「極めて妥当」と承認された。**根拠:** 深刻度の
方針は形式的純粋さでなく用途が選ぶ: 壊れたプログラムでは「暴走」を意味する同じ「締切超過」の徴候が、最小
タイミング・イディオムでは「できるだけ早く頼む」を意味する——そしてアーキテクチャはイディオムに仕える。裸／
窓付きの非対称は費用に正直な境界である: 正確さが安い場所では4行を払い、機構複製を要する場所では床を文書化する。

### 5. What was achieved — the philosophy at minimal scale / 達成されたもの——最小スケールの哲学

**Chosen:** exactness, not approximation. After RH028: **bare Stay-1@P=1 = exactly one clock** (the
peer of an FG NOP); NOP+Stay-2+Jump = exactly 4 clocks; idiom-D duty at P=1 = exactly the written
5:5.

**Rationale:** "The foreground is a bare enumeration of Stay durations" was the FG-exclusion
principle's promise; RH028 makes it hold at the scale where it is hardest and most valuable — single
clocks. This is the communication/video-synchronization-grade rigor the trailing-edge doctrine was
written for, now proven at the degenerate grid where boundary and clock coincide. Regression: all
silicon-verified anchors (T1 25:25, T2 30:30, T32 self-loop) unchanged, since == and >= are
equivalent for exact programs; Test A's blink rising 15→19 is the honest fingerprint of bare Stays
becoming exactly as long as written. **Status:** sim-verified (T34; F1/F2/G1/G2); RH028's own
silicon confirmation is pending — the campaign's first-try clear predates this fix.

**選択:** 近似でなく正確性。RH028 後: **裸 Stay-1@P=1 = 正確に1クロック**（FG NOP の対等物）;NOP+Stay-2+Jump =
正確に4クロック;流儀 D の P=1 デューティ = 書いたとおりの 5:5。**根拠:** 「前景は Stay 持続時間の裸の羅列」は
FG 排除原則の約束だった;RH028 はその約束を、最も難しく最も価値ある尺度——単一クロック——で成立させる。これは
後縁主義がそのために書かれた通信・ビデオ同期グレードの厳格性であり、境界とクロックが一致する退化グリッドで
証明された。回帰: 実機検証済みアンカー（T1 25:25、T2 30:30、T32 自己ループ）は不変（正確なプログラムでは == と
>= は同値）;Test A の点滅が 15→19 に増えたのは、裸 Stay が書いたとおりの長さになったことの正直な指紋である。
**状態:** シム検証済み（T34;F1/F2/G1/G2）;RH028 自体の実機確認は今後——実機一発クリアは本修正に先行する。

---

## Major Themes / 主要テーマ

### Theme 1 — Hidden premises live at parameter extremes / 暗黙前提はパラメータ極値に棲む
"Stay Set never meets a tick" was written nowhere — it existed only as the absence of a defined
priority, invisible at P=5, false on every clock at P=1. Parameter extremes are premise detectors: a
timing architecture is not verified until its degenerate configurations have been made to speak.

「Stay Set はティックと重ならない」はどこにも書かれていなかった——それは定義された優先順位の不在としてのみ
存在し、P=5 では不可視、P=1 では全クロックで偽だった。パラメータ極値は前提の検出器である: タイミング・
アーキテクチャは、その退化構成に口を割らせるまで、検証されたことにならない。

### Theme 2 — Make it real before making it fixed / 直す前に、現実にする
Five experiments turned two worries into five numbers — and one generalization (EXP5). The
experimental posture converted a reported symptom into a theorem about the deadline test itself, and
left behind reusable benches that now guard the boundary forever.

5本の実験が二つの心配を五つの数値に変えた——そして一つの一般化（EXP5）に。実験の構えは、報告された症状を締切
判定そのものについての定理へ変換し、その境界を永久に見張る再利用可能なベンチを遺した。

### Theme 3 — The table as semantic arbiter / 意味論の裁定者としての表
The fix's justification was not invented; it was read off the table: Ignored ⇒ count the coincident
tick; Consumes ⇒ don't. Cells filled months earlier, for other reasons, adjudicated a boundary their
author had not imagined. This is what an exhaustive normative artifact is FOR: it answers questions
that were not asked when it was written.

修正の正当化は発明されず、表から読み取られた: Ignored ⇒ 重複ティックを数える;Consumes ⇒ 数えない。数ヶ月前に、
別の理由で埋められたセルが、作者の想像しなかった境界を裁いた。網羅的な規範成果物とはこのためにある: それは、
書かれた時に発されなかった問いに答える。

### Theme 4 — Severity is chosen by intended use / 深刻度は用途が選ぶ
The same signature — a deadline already past — could mean "runaway, HALT" or "fire as early as
feasible". Earliest-firing won because the minimal-timing idiom is a first-class requirement. This
calibrates the error philosophy: HALT is for violations whose consequences chain invisibly; a past
deadline in a wait is local and self-announcing, best served by graceful earliest service.

同じ徴候——既に過ぎた締切——は「暴走、HALT」も「実現可能な最早で発火」も意味し得た。最早発火が勝ったのは、最小
タイミング・イディオムが第一級の要件だからである。これは誤り哲学を較正する: HALT は帰結が不可視に連鎖する違反の
ためのもの;待機中の締切超過は局所的で自己申告的であり、優雅な最早サービスが最善である。

### Theme 5 — Exactness down to one clock / 1クロックまでの正確性
After RH028, the smallest program at the smallest prescale keeps its promise: Stay-1 is one clock;
the duty written is the duty produced. The philosophy holds from 2^28 self-loops down to a single
clock — and the one honest regression (a blinky blinking more) measures how much slack the hidden
premise had been costing.

RH028 の後、最小プリスケールにおける最小のプログラムが約束を守る: Stay-1 は1クロック;書いたデューティが出る
デューティである。哲学は 2^28 の自己ループから単一クロックまで成り立つ——そして唯一の正直な回帰（点滅が増えた
ブリンキー）は、暗黙前提が課していた弛みの大きさの測定値である。

---

## Resumption Hooks / 再開フック

### Hook A — Silicon confirmation of RH028 / RH028の実機確認
**Starting question:** Add a P=1 program to the DE10-nano menu (bare NOP+Stay-1+Jump;
over-constrained-window recovery) and SignalTap the stay_cnt/presc_tick collision clocks. Does
silicon match EXP1–4's patched columns?

### Hook B — Write the tick-collision discipline into §3.4b / Chapter 4 / tick衝突規律の仕様書き戻し
**Starting question:** Draft the Layer 1 deltas: per-band tick-coincidence semantics (the
Ignored/Consumes symmetry), the bare-vs-windowed exactness statement, the >= earliest-firing rule
(with the rejected HALT alternative recorded).

### Hook C — Conformance-matrix entries for the boundary / 境界の適合マトリクス項目
**Starting question:** Add T34 and the P=1 functional tests (F1/F2/G1/G2) with EXP provenance,
marked sim-verified pending silicon. Which verification-queue items do they extend?

### Hook D — Document the windowed lower bound for programmers / 窓付き下限のプログラマ向け文書化
**Starting question:** Where does the floor (exact for N ≥ scan length + 1 at P=1) belong — §3.4b
notes, Chapter 4, or a programming-idioms appendix — and what is the worked example (StaySet→Stay-N:
exact for N≥3)?

---

## End of Trace / 軌跡の末尾

Every discipline has a smallest case, and the smallest case is where it either holds or was never
real. The prescaler set to one strips the grid of all its room: every clock is a tick, every arm
collides, every tacit "between" disappears. The architect looked there on purpose — because a timing
core that cannot say what one clock means has not yet said anything — and the code, put to
experiment, confessed. Now the confession is a rule read off a table, a four-line exactness, and a
wait that ends the moment it should even when it was asked too late. Stay-1 is one clock. The
smallest sentence in the language finally means exactly what it says.

どの規律にも最小のケースがあり、最小のケースこそ、規律が成り立つか、初めから実在しなかったかの分かれ目である。
プリスケーラを1に据えるとグリッドから全ての余地が剥がれる: 全クロックがティックであり、全アームが衝突し、暗黙の
「あいだ」がすべて消える。アーキテクトは意図してそこを見た——1クロックの意味を言えないタイミングコアは、まだ
何も言っていないからだ——そして実験にかけられたコードは、白状した。いまやその自白は、表から読み取られた規則と
なり、四行の正確さとなり、頼むのが遅すぎた時でさえ然るべき瞬間に終わる待機となった。Stay-1 は1クロックである。
この言語の最小の文が、ついに書いてあるとおりのことを意味する。

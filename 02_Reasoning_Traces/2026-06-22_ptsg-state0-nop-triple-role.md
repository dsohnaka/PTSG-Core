# PTSG State-0 NOP — The Triple Role: Foreground Execution, Isolation Container, and External Marker
# PTSG state 0 の NOP — 三重役割：前景実行・隔離容器・外部標示マーカー

## Trace Metadata / 軌跡メタデータ

| Field | Value |
|---|---|
| **Date / 日付** | 2026-06-22 |
| **Participants / 参加者** | Tsuneo Ohnaka (大中庸生, FPGA Architect, 40+ years; sole design authority); Claude (Anthropic, Claude Opus 4.8, amanuensis / 祐筆 — Layer 4 verification session) |
| **Topic / トピック** | The recognition that state 0's foreground NOP plays a threefold role. At cold start the free-running prescaler's phase is indeterminate, so the first state has indeterminate length. State 0's NOP (1) is always foreground-executed, (2) is an isolation container that absorbs the cold-start indeterminacy into one disposable state, and (3) can emit a timing_signal to externally mark that region. / state 0 の前景 NOP が三重の役割を担うという認識。冷態起動時はプリスケーラ位相が不定で最初の状態の長さが不定;NOP は (1)前景実行、(2)隔離容器、(3)外部標示。 |
| **Status / 状態** | Layer 4 verification-era trace — **offspring 2 of 2** of the prescaler-phase-resolution parent; the most principled and far-reaching of the three. / Layer 4検証期トレース——親「位相決着」の**派生2/2**、三本中最も原理的。 |
| **Original language / 原言語** | Japanese (with English technical terminology) / 日本語（英語技術用語を交える） |
| **License / ライセンス** | CC0 1.0 Universal (Public Domain) |
| **Evidence / エビデンス** | The first-ON = 30 clk (vs steady 25) observation in the white-box and silicon `observation.md` of `prescaler_phase_measurement/` |
| **Parent / sibling / 親・姉妹** | Parent: `2026-06-22_ptsg-prescaler-phase-resolution`. Sibling: `2026-06-22_ptsg-duty-idioms` (shares the timing_signals external-marker gesture). / 親:位相決着。姉妹:デューティ4流儀。 |

---

## Reading Notes / 読解上の注

The parent trace measured the naive blinky's first ON at 30 clk against a steady 25. This trace
reads that extra 5 clk backward and recognizes what state 0 had quietly been doing all along.
Because the prescaler is free-running (now a deliberate, confirmed property), its phase at the
instant reset releases is unknowable; the first state must wait an indeterminate 1..PRESCALE
clocks. State 0's foreground NOP **contains** that irreducible indeterminacy — and it does three
jobs at once.

親トレースは素朴blinkyの初回 ON を定常 25 に対し 30 clk と測った。本トレースはその余分の 5 clk を逆から読み、
state 0 が静かに担ってきた役割を認識する。プリスケーラは自由走行（いまや意図的で確定した性質）ゆえ、リセットが
手を離す瞬間の位相は知り得ず、最初の状態は不定の 1..PRESCALE クロックを待つ。state 0 の前景 NOP はその還元
不能な不定性を**封じ込め**——同時に三つの仕事をする。

**Notable conceptual progressions across the dialogue / 対話を通じた特筆すべき概念的進展:**

1. **Indeterminacy is physical, not a bug.** The free-running prescaler's cold-start phase is
   genuinely unknowable; the first state's length is genuinely indeterminate. The question is
   where to put it, not how to remove it. / 不定性は物理であってバグでない。問いは「どこへ置くか」。

2. **Role 1 — foreground execution.** State 0 is entered at reset and runs in the foreground,
   prescaled. / 役割1——前景実行。

3. **Role 2 — isolation container.** By spending a disposable NOP at state 0, the cold-start phase
   is absorbed before any Stay runs; from state 1 every Stay is exact (phase-locked, parent
   trace). / 役割2——隔離容器。state 1 以降の Stay を綺麗に保つ。

4. **Role 3 — external marker.** State 0's NOP can raise a timing_signal to flag the indeterminate
   region, so external logic can discard or gate it. / 役割3——外部標示。不定区間を旗で示す。

5. **NOP, not Stay 1.** A Stay must mean exactly N units; letting the first Stay be indeterminate
   would break Stay's contract. The NOP, which promises nothing, takes the dirty job. / Stay 1 で
   なく NOP。Stay の約束を汚さぬため。

6. **Post-hoc recognition.** The role was not designed up front; the 30-vs-25 measurement revealed
   it. Layer 4 taught Layer 2 a role the design had implicitly relied on. / 事後的認識。測定が役割を
   明らかにした。

---

## Notable Decision Points / 重要な決定ポイント

### 1. What is the cold-start indeterminacy — a bug, or a fact to contain? / 冷態不定性は — バグか、封じ込めるべき事実か

**Alternatives:** (a) a timing bug to fix; (b) an irreducible physical fact to be contained.
**Chosen:** an irreducible fact to be contained.

**Rationale:** Because the prescaler is free-running (parent trace: a deliberate, confirmed
property), its phase when reset releases is not knowable in advance. The first state must wait an
indeterminate 1..PRESCALE clocks for the first tick — the cost of a free-running time-base, not a
sequencing defect. The design question is "where do we put it," not "how do we remove it."
**Measured:** first ON = 30 clk vs steady 25; the extra 5 (one prescale period, worst case) is
exactly the cold-start absorption.

**代替案:** (a) 修正すべきタイミングバグ;(b) 封じ込めるべき還元不能な物理的事実。**選択:** 封じ込めるべき事実。
**根拠:** プリスケーラは自由走行（親トレース:意図的で確定した性質）ゆえ、リセット解放時の位相は事前に知り得ない。
最初の状態は初回ティックまで不定の 1..PRESCALE クロックを待つ——自由走行時間基準のコストで、シーケンスの欠陥でない。
問いは「どこへ置くか」。**測定:** 初回 ON = 30 clk 対 定常 25;余分の 5（最悪 1 プリスケール周期）が冷態吸収。

### 2. Where to absorb the indeterminacy? / 不定性をどこで吸収するか

**Alternatives:** (a) smeared across normal operation (the first real Stay absorbs it); (b)
isolated into a dedicated first state (state 0). **Chosen:** isolated into state 0's foreground
NOP.

**Rationale:** If the first real Stay absorbed the cold-start phase, that Stay's duration would be
wrong by up to one prescale period on the first iteration — contaminating the first useful output.
Spending a foreground NOP at state 0 first consumes the indeterminacy before any Stay runs; from
state 1 the prescaler is phase-locked and every Stay is exact. **Trade-off:** one state and up to
one prescale period of startup latency, paid once, for a clean time-base from the first real
instruction. This is the isolation-container move: concentrate the uncertainty in one disposable
place rather than letting it diffuse.

**代替案:** (a) 通常動作に滲ませる（最初の実 Stay が吸収）;(b) 専用の最初の状態（state 0）へ隔離。
**選択:** state 0 の前景 NOP へ隔離。**根拠:** 最初の実 Stay が冷態位相を吸収すると、その Stay の長さは初回反復で
最大 1 プリスケール周期ずれ、最初の有用な出力を汚染する。state 0 で前景 NOP を先に費やせば、いかなる Stay よりも
前に不定性が消費され、state 1 からプリスケーラは位相ロックし全 Stay が正確。**トレードオフ:** 1 状態と最大 1
プリスケール周期の起動レイテンシを一度払い、最初の実命令から綺麗な時間基準を得る。これが隔離容器の手:
不定性を拡散させず一つの使い捨ての場所に集約する。

### 3. Why a NOP and not a Stay 1? / なぜ Stay 1 でなく NOP か

**Alternatives:** (a) Stay 1; (b) foreground NOP. **Chosen:** foreground NOP.

**Rationale:** A Stay is a deterministic-time primitive by definition: "Stay N" must mean exactly
N prescale units. If the very first Stay had indeterminate length (because it absorbs the
cold-start phase), it would break the Stay invariant on its first instance — staining the banner
of the one primitive whose entire meaning is determinacy. A foreground NOP carries no such
promise: it advances on the next prescale tick, and its indeterminate first-instance length
violates no contract. The NOP absorbs the uncertainty **without dirtying Stay's guarantee.**
(Architect's metaphor: the oxidized trim is fine as staff meal / まかない, but you do not serve it
as the headline cut.)

**代替案:** (a) Stay 1;(b) 前景 NOP。**選択:** 前景 NOP。**根拠:** Stay は定義上、決定的時間のプリミティブ:
「Stay N」はちょうど N プリスケール単位を意味せねばならない。最初の Stay が（冷態位相を吸収して）不定長になれば、
その初回インスタンスで Stay 不変量を破る——意味の全てが決定性であるただ一つのプリミティブの看板を汚す。前景 NOP は
そのような約束を持たない: 次のプリスケールティックで進むだけで、初回インスタンスの不定長は何の契約も破らない。
NOP は **Stay の保証を汚さずに**不確実性を吸収する。（大中さんの比喩: 酸化した端はまかないには上等だが、看板の品としては
出さない。）

### 4. Hide the region, or mark it externally? / 区間を隠すか、外部標示するか

**Alternatives:** (a) hidden (emit no signal); (b) externally marked (state 0's NOP emits a
timing_signal). **Chosen:** externally marked (optional but recommended).

**Rationale:** The indeterminacy cannot be removed, but it can be made legible. If state 0's NOP
raises a marker bit, external logic (or a downstream Formation) can recognize "this is the startup
region" and gate or discard outputs during it — converting an invisible hazard into a handled
signal. This is the **third role**, and the same gesture as idiom C's D17 boundary flag (sibling
trace): when a cycle has special status, externalize that status to the timing_signals plane
rather than hiding it. **Trade-off:** costs one timing_signals bit during state 0; free otherwise.

**代替案:** (a) 隠す（信号を出さない）;(b) 外部標示（state 0 の NOP が timing_signal を出す）。
**選択:** 外部標示（任意だが推奨）。**根拠:** 不定性は除去できないが可読にできる。state 0 の NOP がマーカービットを
立てれば、外部ロジック（や下流の Formation）は「これは起動区間」と認識し、その間の出力をゲートまたは破棄できる——
不可視の危険を扱える信号に変える。これが**第三の役割**で、流儀C の D17 境界旗と同じ仕草（姉妹トレース）:
サイクルに特別な地位がある時、隠さず timing_signals 面へ外部化する。**トレードオフ:** state 0 の間 timing_signals を
1 ビット使う;それ以外は無償。

### 5. Hardware special-case, or ordinary state by convention? / ハードウェア特例か、慣習による通常状態か

**Alternatives:** (a) hardware special-case (logic treats address 0 specially at reset); (b)
ordinary state, special only by convention. **Chosen:** ordinary state, special only by
convention.

**Rationale:** Reset enters at address 0 (already true); nothing else about state 0 is privileged
in silicon. Its triple role is achieved entirely by what the programmer writes there (a foreground
NOP, optionally marker-tagged). This keeps the Core minimal — no init-mode opcode, no reset-vector
logic beyond the entry address — consistent with "complexity outward, core minimal" and resolving
requirements through existing primitives. The programmer remains free to use state 0 for real work
**if** they understand its indeterminate nature (the "oxidized end" is usable, just not as a
deterministic Stay).

**代替案:** (a) ハードウェア特例（リセット時にアドレス 0 を特別扱い）;(b) 通常状態、慣習のみで特別。
**選択:** 通常状態、慣習のみで特別。**根拠:** リセットはアドレス 0 に入る（既にそう）;それ以外に state 0 が
シリコンで特権を持つことはない。三重役割は、そこにプログラマが書くもの（前景 NOP、任意でマーカータグ）だけで
達成される。これが Core を最小に保つ——初期化モードオペコードなし、エントリアドレス以上のリセットベクタロジック
なし——「複雑性は外へ」と既存プリミティブで要求を解く規律に整合。プログラマは、その不定な性質を理解すれば
state 0 を実作業に使う自由を保つ（「酸化した端」は使えるが、決定的 Stay としては使わない）。

### 6. Where to document the triple role (write-back recommendation; architect decides) / 三重役割をどこに記すか（書き戻し推奨;決定は大中さん）

**Alternatives:** (a) a Chapter 2/3 convention note; (b) a Chapter 4 note next to the prescaler;
(c) both — a primary convention note cross-referenced from the prescaler chapter. **Chosen
(recommended):** (c) — a primary "oxidized end / staff-meal" convention in the state-semantics
chapter, cross-referenced from the prescaler-phase section.

**Rationale:** The triple role is a state-semantics convention (what state 0 means and how to use
it), so its home is with state semantics; but its cause is the free-running prescaler, so the
prescaler section should point to it. Documenting once and cross-referencing avoids duplication.
Because this convention has wide reach (every Formation cold-starts), it deserves an explicit named
convention rather than a buried remark. Left to the architect per amanuensis-never-decides.

**代替案:** (a) 第2/3章の慣習注;(b) プリスケーラの隣に第4章注;(c) 両方——主たる慣習注をプリスケーラ章から相互
参照。**選択（推奨）:** (c)——状態意味論の章に主たる「酸化した端／まかない」慣習を置き、プリスケーラ位相節から
相互参照。**根拠:** 三重役割は状態意味論の慣習（state 0 が何を意味しどう使うか）ゆえ住処は状態意味論;だが原因は
自由走行プリスケーラゆえプリスケーラ節がそれを指すべき。一度記して相互参照すれば重複を避ける。この慣習は射程が
広い（全 Formation が冷態起動する）ため、埋もれた一言でなく明示的に命名された慣習に値する。祐筆は決定しない規律により
大中さんに委ねる。

---

## Major Themes / 主要テーマ

### Theme 1 — Indeterminacy contained, not eliminated / 不定性は封じ込め、除去せず
Some uncertainty is physical and irreducible (the free-running prescaler's cold-start phase).
Mature design does not pretend to remove it; it concentrates it into one disposable place and,
ideally, labels it. State 0's NOP is the container. A general engineering stance — isolate the
unavoidable so the rest stays clean — expressed in three instructions of silicon vocabulary.

ある種の不確実性は物理的で還元不能（自由走行プリスケーラの冷態位相）。成熟した設計はそれを除去するふりをせず、
一つの使い捨ての場所に集約し、理想的には標識する。state 0 の NOP がその容器。一般的な工学姿勢——避けられぬものを
隔離し、残りを綺麗に保つ——を三命令のシリコン語彙で表現したもの。

### Theme 2 — Protecting the determinacy of Stay / Stay の決定性を守る
Stay's entire value is that "Stay N" means exactly N units. The cold-start indeterminacy threatens
that promise on the first instance. Choosing a NOP (which promises nothing) over a Stay 1 (which
promises everything) to hold the uncertainty is an act of protecting a primitive's contract. The
cleanliness of Stay is purchased by giving the dirty job to the primitive that has no contract to
dirty.

Stay の価値の全ては「Stay N」がちょうど N 単位を意味すること。冷態不定性はその約束を初回インスタンスで脅かす。
不確実性を抱える役を、すべてを約束する Stay 1 でなく何も約束しない NOP に選ぶことは、プリミティブの契約を守る
行為。Stay の清潔は、汚す契約を持たないプリミティブに汚れ仕事を与えることで購われる。

### Theme 3 — Externalization to the timing_signals plane: a unifying gesture / timing_signals 面への外部化:統一する仕草
The third role (marking the region) is the same move as idiom C's boundary flag (sibling trace):
when a cycle is special, do not hide it — emit a timing_signal so external logic can recognize it.
Across the three traces, the timing_signals plane is emerging as PTSG's channel for externalizing
meaning the time-axis cannot itself carry: boundaries, startup regions, taxes. The architecture
pushes semantics outward onto observable signals.

第三の役割（区間の標示）は流儀C の境界旗と同じ手（姉妹トレース）: サイクルが特別な時、隠さず timing_signal を出して
外部ロジックに認識させる。三本のトレースを通じ、timing_signals 面は、時間軸自身が運べない意味——境界・起動区間・税——を
外部化する PTSG のチャネルとして立ち現れている。アーキテクチャは意味を観測可能な信号へ外へ押し出す。

### Theme 4 — Post-hoc recognition: the measurement revealed the role / 事後的認識:測定が役割を明らかにした
The triple role was not designed up front; it was recognized after the first ON measured 30 clk
against a steady 25. The extra 5 clk was the cold-start absorption made visible, and reading it
backward revealed that state 0 had been doing this job all along. This is how Layer 4 feeds Layer
2: a measured "anomaly" that turns out to be correct behavior teaches a role the designer had
implicitly relied on but not yet named.

三重役割は事前に設計されたのでなく、初回 ON が定常 25 に対し 30 clk と測られた後に認識された。余分の 5 clk は
可視化された冷態吸収で、それを逆に読むと state 0 がずっとこの仕事をしていたと分かった。これが Layer 4 が Layer 2 を
養う仕方: 正しい挙動と判明する測定上の「異常」が、設計者が暗黙に頼っていたが未だ名付けていなかった役割を教える。

### Theme 5 — The staff-meal convention: usable, just not the headline / まかない慣習:使えるが看板ではない
The architect's framing: state 0 is the "oxidized end" (酸化した端) — the trim not served as the
prime cut but perfectly fine boiled as staff meal (まかない). State 0 is not forbidden for real use;
it is simply understood to have indeterminate first-instance length. A programmer who knows this
can use it deliberately. The convention names a usable-but-caveated resource rather than a
prohibited one — preserving freedom while warning honestly.

大中さんの枠組み: state 0 は「酸化した端」——看板の品としては出さないが、まかないとして煮れば上等な端材。state 0 は
実用を禁じられてはいない;ただ初回インスタンスの長さが不定と理解されるだけ。それを知るプログラマは意図的に使える。
慣習は、禁止された資源でなく使えるが但し書き付きの資源を名指す——自由を保ちつつ正直に警告する。

---

## Resumption Hooks / 再開フック

### Hook A — Quantify worst-case cold-start latency per Formation / Formation ごとの最悪起動レイテンシを定量化
First ON measured 30 vs steady 25 (one prescale period of absorption at PRESCALE=5). For a
Formation with a different PRESCALE or state-0 program, the startup latency differs.
**Starting question:** Derive the worst-case cold-start latency as a function of PRESCALE and the
state-0 program, and state the exact bound a Formation designer should budget before the first
deterministic Stay.

### Hook B — The state-0 convention note (write-back) / state-0 慣習注（書き戻し）
DP-6 recommends a named "oxidized end / staff-meal" convention in the state-semantics chapter,
cross-referenced from the prescaler section. Wording and placement are the architect's decision.
**Starting question:** Draft the convention paragraph — state 0 is the reset-entry state; its
first-instance length is indeterminate due to the free-running prescaler; the recommended use is a
foreground NOP (optionally marker-tagged); it may be used for real work if its nature is
understood. What is the minimal precise wording?

### Hook C — Generalize the isolation-container pattern / 隔離容器パターンの一般化
State 0 is one instance of a general pattern: concentrate irreducible indeterminacy into a single
disposable, optionally-labeled state. This may apply to other transitions (re-entry after an
external interrupt, band switches).
**Starting question:** Are there other points in a PTSG program where indeterminacy enters (an
externally-triggered re-entry, a Condition race) that would benefit from the same
isolation-container + external-marker treatment? Enumerate candidates.

### Hook D — Interaction with idiom D (Stay-exact) at cold start / 冷態起動での流儀D との相互作用
Idiom D makes timing_signals reflect the Stay count exactly, but the FIRST iteration still pays the
cold-start absorption in state 0. A test-vector Formation built on D must account for this.
**Starting question:** For an exact-width generator built on idiom D, how should the state-0
cold-start region be handled so the first emitted vector is also exact — discard-via-marker, a
warm-up loop, or a prescaler-aware trigger? Compare.

### Hook E — Does the marker bit belong to a reserved timing_signals lane? / マーカービットは予約レーンに属すか
If marking the startup region becomes a convention, a reserved timing_signals bit (a "status lane"
distinct from data lanes) might be warranted, echoing idiom C's D17 flag lane.
**Starting question:** Should PTSG conventions reserve a specific timing_signals bit as a
"status/marker lane" (startup region, boundary flags, taxes), or should marker-bit assignment stay
per-Formation? Weigh portability against bit budget.

---

## End of Trace / 軌跡の末尾

Every clock that runs freely pays a small tax at the first tick: nobody knows what phase the world
will be in when the reset lets go. PTSG does not pretend to know. It spends one instruction — a NOP
that promises nothing — to swallow the unknown first moment whole, so that from the second state
onward the timing is exact and the Stay primitive keeps its word. And if you ask it to, that first
instruction will raise a small flag over the uncertain ground, so the outside world need never
mistake the staff meal for the headline cut.

自由に走るクロックは初回ティックで小さな税を払う:リセットが手を離す時、世界がどの位相にあるか誰も知らない。
PTSG は知ったふりをしない。何も約束しない命令——NOP——を一つ費やして未知の最初の瞬間を丸ごと飲み込み、二番目の
状態からタイミングは正確になり、Stay プリミティブは約束を守る。そして望むなら、その最初の命令は不確かな地面に
小さな旗を立てる——外界がまかないを看板の品と取り違えずに済むように。

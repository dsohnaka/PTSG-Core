# PTSG Four Duty Idioms — Controlling Duty on One Skeleton Without an Opcode
# PTSGデューティ4流儀 — オペコードを足さず、同一骨格でデューティを制御する

## Trace Metadata / 軌跡メタデータ

| Field | Value |
|---|---|
| **Date / 日付** | 2026-06-22 |
| **Participants / 参加者** | Tsuneo Ohnaka (大中庸生, FPGA Architect, 40+ years; sole design authority); Claude (Anthropic, Claude Opus 4.8, amanuensis / 祐筆 — Layer 4 verification session) |
| **Topic / トピック** | The articulation and verification of PTSG's four duty-cycle idioms. From the (correct) 25:35 asymmetry of the naive blinky, the same skeleton is shown to yield four duties — 25:35, 30:30, 30:30-flagged, 25:25 — by varying ONLY the foreground treatment. No duty opcode is added. All four verified white-box and on silicon, clock-for-clock. / デューティ4流儀の明確化と検証。素朴blinkyの25:35から、同一骨格が前景の扱いだけで4デューティを生む。デューティ用オペコードは足さない。 |
| **Status / 状態** | Layer 4 verification-era trace — **offspring 1 of 2** of the prescaler-phase-resolution parent. / Layer 4検証期トレース——親「位相決着」の**派生1/2**。 |
| **Original language / 原言語** | Japanese (with English technical terminology) / 日本語（英語技術用語を交える） |
| **License / ライセンス** | CC0 1.0 Universal (Public Domain) |
| **Evidence / エビデンス** | `04_Verification_Evidence/conformance_suite/prescaler_phase_measurement/` program_{A,B,C,D}.{hex,mif} + white-box and silicon `observation.md` |
| **Parent / sibling / 親・姉妹** | Parent: `2026-06-22_ptsg-prescaler-phase-resolution`. Sibling: the state-0 NOP triple role (offspring 2). / 親:位相決着。姉妹:state 0 NOP三重役割。 |

---

## Reading Notes / 読解上の注

The parent trace established that the naive blinky's 25:35 asymmetry is correct — the two
foreground commands (NOP@2, Jump@4) each cost one whole prescale unit on the OFF side. This
trace takes that fact and turns it into a design vocabulary: **duty is not a fixed property of
PTSG but a programming choice**, made by deciding where the foreground cost lands. The same
five-/eight-instruction skeleton yields four duties, and PTSG ships **no** duty primitive to do
it — the freedom is already in the existing four opcodes.

親トレースは、素朴blinkyの 25:35 非対称が正しいこと——前景2コマンド（NOP@2・Jump@4）が各々1プリスケール
単位を OFF 側に費やす——を確立した。本トレースはその事実を設計語彙に変える: **デューティは PTSG の固定的性質
ではなく、前景コストをどこへ落とすかを決めるプログラミング上の選択である**。同一の 5/8 命令骨格が4デューティを
生み、PTSG はそのための専用プリミティブを**持たない**——自由度は既存4オペコードに既に在る。

**Notable conceptual progressions across the dialogue / 対話を通じた特筆すべき概念的進展:**

1. **From "fix the asymmetry" to "place the cost."** The designer's question shifts from removing
   25:35 to choosing where the foreground tax falls. / 「非対称を直す」から「コストを配置する」へ。

2. **Idiom A (25:35) — let it fall.** The naive program; foreground cost lands on OFF. Correct,
   not a defect. / 流儀A——落とすに任せる。前景コストが OFF に乗る。正しく、欠陥でない。

3. **Idiom B (30:30) — move it.** Re-tag NOP@2 to ON (0x0001); one prescale unit moves from OFF
   to ON; symmetric, same five instructions, loop length unchanged at 60 clk. / 流儀B——移す。
   NOP@2 を ON 化、1単位が OFF→ON、対称、命令数同じ、ループ長 60 clk 不変。

4. **Idiom C (30:30 flagged) — move it and flag it.** NOP@2=0x0003, Jump@4=0x0002; D17 marks the
   foreground-added cycles so external logic can see the tax. (Silicon-canonical; a Stay=4 →
   25:25 form is a valid alternative.) / 流儀C——移して旗を立てる。D17 が前景付加サイクルを標示。

5. **Idiom D (25:25 Stay-exact) — banish it.** StaySet/background-NOP/ProgEnd/QueJump push the
   foreground out of the duty entirely; timing_signals shows only Stay-written cycles. / 流儀D——
   追放する。前景をデューティから完全に追い出し、timing_signals に Stay 記述サイクルのみが現れる。

6. **No primitive added.** The four idioms span naive/balanced/flagged/exact duties (and arbitrary
   N:M) using only Stay/NOP/Jump/StaySet — so no duty opcode or PWM register is introduced. /
   プリミティブ不追加。既存4命令だけで空間を張るため、デューティ用オペコードは導入しない。

---

## Notable Decision Points / 重要な決定ポイント

### 1. Asymmetry as problem, or as entry point to a vocabulary? / 非対称は問題か、語彙への入口か

**Alternatives:** (a) a problem to eliminate; (b) the entry point to a design vocabulary.
**Chosen:** entry point.

**Rationale:** Once 25:35 is understood as the correct cost of two foreground prescale units on
OFF (parent DP-2/DP-4), the designer's question shifts from "how do I remove the asymmetry" to
"where do I want the foreground cost to land." That reframing is the whole content of this trace.
**Trade-off:** framing duty as a vocabulary means PTSG ships no duty primitive — the programmer
must know the idioms — accepted, per Chapter 1's "complexity outward, core minimal."

**代替案:** (a) 除去すべき問題;(b) 設計語彙への入口。**選択:** 入口。**根拠:** 25:35 を OFF 側の2前景
プリスケール単位の正しいコストと理解すれば（親 DP-2/DP-4）、問いは「非対称をどう除くか」から「前景コストを
どこへ落とすか」へ移る。**トレードオフ:** デューティを語彙とする＝専用プリミティブを持たない＝プログラマが
流儀を知る必要がある——第1章「複雑性は外へ、コアは小さく」に従い受容。

### 2. Reaching 30:30 (B) — add an instruction, or re-tag one? / 30:30 へ — 命令追加か再タグか

**Alternatives:** (a) add a balancing instruction on the ON side; (b) re-tag the existing NOP@2
to ON (0x0001). **Chosen:** re-tag; no instruction added.

**Rationale:** The naive OFF side carries +2 prescale units (NOP@2 + Jump@4). Re-tagging NOP@2 as
ON moves one unit (5 clk) from OFF to ON: ON = 25 + 5 = 30, OFF = 25 + 5 = 30. **Trade-off vs
adding an instruction:** re-tagging keeps the loop length at 60 clk, so the integer-multiple
phase-lock (parent trace) is preserved unchanged; adding an instruction would have grown the loop
and forced a phase-lock re-check. Re-tagging is strictly cheaper and preserves the invariant.
White-box and silicon: 30:30 exact.

**代替案:** (a) ON 側に均し命令を追加;(b) 既存 NOP@2 を ON 化（0x0001）。**選択:** 再タグ、命令追加なし。
**根拠:** 素朴の OFF 側は +2 単位（NOP@2 + Jump@4）。NOP@2 を ON 化で1単位（5clk）が OFF→ON: ON=25+5=30、
OFF=25+5=30。**追加との比較:** 再タグはループ長 60clk を保ち、整数倍位相ロック（親）を不変に保つ;追加は
ループを伸ばし位相ロック再確認を要する。再タグが厳密に安く不変量を保つ。白箱・実機とも 30:30 完全一致。

### 3. Expressing C ("flag the boundary") — and which realization is canonical? / C の表現 — どの実現を正典とするか

**Alternatives:** (a) Stay=5, NOP@2→ON(0x0003) + Jump@4 flag(0x0002) → 30:30 with D17 flags; (b)
Stay=4 + D17 flags → 25:25 with flags. **Chosen:** the silicon-run version (a) is canonical;
(b) is recorded as a valid alternative.

**Rationale:** Silicon is ground truth, and the architect ran the Stay=5 version (the amanuensis's
white-box exploration had used Stay=4). Both realize the same idea — externally MARK the
foreground-added cycle via timing_signals[1] (D17) — at different duties. **Recorded correction:**
the amanuensis's draft idiom table first listed C as "25:25 flagged" (the Stay=4 form); reconciled
to the silicon's 30:30-flagged form, Stay=4 demoted to "alternative." The deeper point: the +cost
cycle need not be hidden; D17 lets external logic see exactly which cycle is the foreground tax —
the same philosophy as the state-0 external marker (sibling trace 2).

**代替案:** (a) Stay=5、NOP@2→ON(0x0003) + Jump@4 旗(0x0002) → 30:30＋D17旗;(b) Stay=4 + D17 → 25:25＋旗。
**選択:** 実機版 (a) を正典、(b) を有効な別解として記録。**根拠:** シリコンが ground truth で、大中さんは Stay=5
版を走らせた（祐筆の白箱探索は Stay=4 を使っていた）。両者は同じ思想——timing_signals[1]（D17）で前景付加
サイクルを外部標示——を異なるデューティで実現。**記録された訂正:** 祐筆の草稿流儀表は当初 C を「25:25 旗付き」
（Stay=4 形）と記載;実機の 30:30 旗付き形に整合させ、Stay=4 を「別解」に降格。深い要点: 付加コストのサイクルは
隠す必要がない;D17 が前景税のサイクルを外部に見せる——state 0 外部標示と同じ思想（姉妹トレース2）。

### 4. Honouring the written Stay exactly (D) — accept the tax, or remove it? / Stay 厳守 — 税を受容か除去か

**Alternatives:** (a) accept and compensate (A/B/C); (b) remove the tax by driving foreground
commands into the background/queue bands. **Chosen:** idiom D — StaySet → background NOP → Stay →
StaySet → background NOP → ProgEnd → QueJump → Stay (8 instructions). Duty = exactly the written
Stay (25:25).

**Rationale:** D is the only idiom that makes timing_signals reflect the Stay count with zero
foreground contamination. Mechanism (silicon-confirmed at register level): StaySet sets
`window_open`; the in-window NOP advances without consuming a duty prescale unit; ProgEnd latches
`prog_end_seen`; the QueJump is captured as `queued_valid` and fires at timeup, looping.
**Trade-off:** D costs more instructions (8 vs 5) and more concepts (background execution, queued
jump, ProgEnd) for literal Stay fidelity. Use it when the Stay number on the page must equal the
cycles on the wire — e.g. an exact-width test-vector Formation. Reproduces the architect's silicon
`stp1.vcd` 5:5 in white-box.

**代替案:** (a) 受容し補償（A/B/C）;(b) 前景を背景・キュー帯域へ追い込み税を除去。**選択:** 流儀D——
StaySet→背景NOP→Stay→StaySet→背景NOP→ProgEnd→QueJump→Stay（8命令）。デューティ = Stay 記述どおり（25:25）。
**根拠:** D は timing_signals に Stay 数を前景汚染ゼロで反映する唯一の流儀。機構（実機でレジスタレベル確認）:
StaySet が `window_open` をセット;ウィンドウ内 NOP はデューティ単位を消費せず進む;ProgEnd が `prog_end_seen` を
ラッチ;QueJump は `queued_valid` として捕捉され timeup で発火しループ。**トレードオフ:** D は命令数（8対5）と
概念（背景実行・キューJump・ProgEnd）を多く要する代わりに Stay の字義的忠実を得る。紙の Stay 数が線上の
サイクル数と一致せねばならない時に使う——例: 正確幅のテストベクタ Formation。実機 `stp1.vcd` の 5:5 を白箱再現。

### 5. Should a duty primitive be added to the Core? / Core にデューティ用プリミティブを足すか

**Alternatives:** (a) add a duty primitive (PWM mode / duty register / symmetric-blink opcode);
(b) no primitive — duty is an emergent idiom. **Chosen:** no primitive.

**Rationale:** The four idioms show the existing four opcodes already span naive-asymmetric,
balanced, flagged, and Stay-exact duties — including arbitrary N:M by choice of Stay counts and
foreground tagging. A duty primitive would duplicate expressivity already present, enlarge the
invariant Core, and violate "complexity outward, core minimal" and the discipline of resolving
requirements through existing orthogonal primitives — the same discipline that resolved Prog End
and NOP-as-phase-absorber without new opcodes. **Trade-off accepted:** the programmer must learn
the idioms (mitigated by Layer 3 examples + this trace).

**代替案:** (a) デューティ用プリミティブ（PWM モード/デューティレジスタ/対称点滅オペコード）;(b) プリミティブ
なし——デューティは創発的流儀。**選択:** プリミティブなし。**根拠:** 4流儀は既存4オペコードが既に
素朴非対称・均衡・旗付き・Stay厳守のデューティ（Stay 数と前景タグ選択による任意 N:M を含む）を張ることを示す。
デューティ用プリミティブは既存の表現力を重複させ、不変 Core を肥大させ、「複雑性は外へ」と既存直交プリミティブで
要求を解く規律——Prog End や NOP 位相吸収を新オペコードなしで解いたのと同じ規律——に反する。**受容したトレードオフ:**
プログラマが流儀を学ぶ必要（Layer 3 例＋本トレースで緩和）。

### 6. Where do the four idioms belong in the repository? / 4流儀はリポジトリのどこに属すか

**Alternatives:** (a) Layer 1 only (Chapter 4 illustration); (b) Layer 3 only (sample programs);
(c) both, linked, with this Layer 2 trace as the reasoning spine. **Chosen:** (c).

**Rationale:** Each layer answers a different reader: Layer 3 gives runnable programs, Layer 1 the
normative illustration, Layer 2 the judgment (why four, why no primitive, why C's two forms). The
program_{A,B,C,D} files already live in the conformance suite as prescaler_phase_measurement
stimuli, so the family is anchored to silicon evidence rather than floating as prose. Final
placement of the Chapter 4 illustration is the architect's decision (write-back).

**代替案:** (a) Layer 1 のみ（Chapter 4 図解）;(b) Layer 3 のみ（サンプル）;(c) 両方を連結し本 Layer 2
トレースを推論の背骨に。**選択:** (c)。**根拠:** 各層は異なる読者に答える: Layer 3 は走るプログラム、Layer 1 は
規範的図解、Layer 2 は判断（なぜ4つ・なぜ無プリミティブ・なぜ C に2形）。program_{A,B,C,D} は既に適合スイートの
prescaler_phase_measurement スティミュラスとして在り、家族は散文でなく実機エビデンスに錨を下ろす。Chapter 4 図解の
最終配置は大中さんの決定（書き戻し）。

---

## Major Themes / 主要テーマ

### Theme 1 — Duty as a programming choice, not a fixed property / デューティは固定的性質でなくプログラミング上の選択
The central inversion: duty cycle is not something PTSG "has" but something the programmer chooses
by deciding where the foreground cost lands. A (let it fall on OFF), B (move it to ON), C (move and
flag), D (eliminate). The same skeleton spans the space. This is the time-axis analogue of the
architecture's general stance — express variety in the program, not in the silicon.

中心的反転: デューティ比は PTSG が「持つ」ものでなく、前景コストをどこへ落とすかを決めることでプログラマが
選ぶもの。A（OFF に落とす）、B（ON へ移す）、C（移して旗）、D（消す）。同一骨格が空間を張る。これは
アーキテクチャの一般姿勢の時間軸版——多様性をシリコンでなくプログラムで表現する。

### Theme 2 — Resolving a requirement through existing primitives / 既存プリミティブで要求を解く
The temptation on seeing asymmetry is to add a duty primitive. The discipline is to ask first
whether the existing orthogonal primitives already span the requirement. They do: Stay count sets
the base, foreground tagging (timing_signals bits) sets ON/OFF and flags, and the background/queue
bands (StaySet/ProgEnd/QueJump) remove the foreground tax. No opcode added. This mirrors how Prog
End and NOP-as-phase-absorber were resolved — a recurring architectural move.

非対称を見た時の誘惑はデューティ用プリミティブの追加。規律は、既存直交プリミティブが既に要求を張るかをまず問う
こと。張る: Stay 数が基底を、前景タグ（timing_signals ビット）が ON/OFF と旗を、背景・キュー帯域
（StaySet/ProgEnd/QueJump）が前景税の除去を担う。オペコード不追加。Prog End や NOP 位相吸収の解き方と同型——
反復するアーキテクチャの手。

### Theme 3 — The flag is the same gesture as the state-0 marker / 旗は state-0 標示と同じ仕草
Idiom C raises D17 on the foreground-added cycle so external logic can SEE the tax rather than have
it hidden. This is the identical gesture as marking the indeterminate state-0 region with a
timing_signal (sibling trace 2): when a cycle has special status, don't hide it — emit a signal so
the outside world can recognize it. Externalization of meaning to the timing_signals plane unifies
the family.

流儀C は前景付加サイクルに D17 を立て、税を隠すのでなく外部ロジックに見せる。これは不定の state-0 領域を
timing_signal で標示するのと同じ仕草（姉妹トレース2）: サイクルに特別な地位がある時、隠さず、外界が認識できる
信号を出す。意味を timing_signals 面へ外部化することが家族を統一する。

### Theme 4 — Two realizations of one idea (C), and why both are kept / 一つの思想の二実現（C）、なぜ両方残すか
Idiom C exists in two forms: Stay=5 → 30:30-flagged (silicon-canonical) and Stay=4 → 25:25-flagged
(white-box alternative). Rather than collapse to one, both are recorded with their duties, per the
Tie Decision Pattern: a future programmer under a specific duty target picks the realization that
fits. Recording both, not just the chosen, is the Layer 2 discipline.

流儀C は二形を持つ: Stay=5 → 30:30 旗付き（実機正典）と Stay=4 → 25:25 旗付き（白箱別解）。一つに潰さず、
両者をデューティ付きで記録する——引き分け判断パターンに従い、特定のデューティ目標を持つ将来のプログラマが
適合する実現を選ぶ。選択だけでなく両方を記録するのが Layer 2 の規律。

### Theme 5 — Idiom D as the bridge to exact-width applications / 流儀D は正確幅応用への橋
D is the only idiom where the Stay number on the page equals the cycles on the wire. That literal
fidelity is precisely what an exact-width generator needs — a test-vector Formation, or any timing
where the count is a contract, not an approximation. D therefore points beyond blinky: it is the
duty idiom that makes PTSG a candidate for deterministic stimulus generation.

D は紙の Stay 数が線上のサイクル数に等しい唯一の流儀。その字義的忠実こそ正確幅生成器が要するもの——テスト
ベクタ Formation、あるいは数が近似でなく契約であるあらゆるタイミング。ゆえに D は blinky を超えて指す: PTSG を
決定論的スティミュラス生成の候補にするデューティ流儀。

---

## Resumption Hooks / 再開フック

### Hook A — Arbitrary N:M duty from the idiom family / 家族から任意 N:M デューティ
The four idioms are points; the family is a space. Arbitrary N:M should be reachable by choosing
Stay counts and foreground tagging, within the integer-multiple phase-lock constraint (parent
trace).
**Starting question:** Given a target duty N:M (in prescale units), derive the Stay counts and
foreground timing_signals tags that realize it, and state when the result remains an integer
multiple of the prescale period (phase-locked) versus when it does not. Produce a small generator.

### Hook B — Chapter 4 worked-illustration wording (write-back) / Chapter 4 図解の文言（書き戻し）
DP-6 routes a Chapter 4 worked illustration (final wording is the architect's decision).
**Starting question:** Draft the Chapter 4 illustration — A/B/C/D as a progression
(let-fall / move / move+flag / eliminate), each with program, duty, and one-line principle. What
is the minimal normative phrasing that does not over-specify?

### Hook C — Multi-channel duty (more than one timing_signals bit) / 多チャネルデューティ
The idioms used timing_signals[0] as LED and [1] as flag. PTSG has 16 timing-signal bits; multiple
independent duties could be driven at once.
**Starting question:** Can two independent duty waveforms (different N:M) be driven on
timing_signals[0] and [1] from a single PTSG program, or does the shared Stay/foreground structure
couple them? Characterize the coupling.

### Hook D — Idiom D as a test-vector generator / 流儀D をテストベクタ生成器に
D's literal Stay fidelity suggests a PTSG_TestVector_Formation: exact-width, self-checking stimulus
via Branch-on-Condition.
**Starting question:** Sketch a minimal exact-width test-vector pattern using idiom D plus
Branch-on-Condition for closed-loop self-checking. What is the smallest program that emits a
known-width pulse and verifies a response?

### Hook E — Piano-roll IDE mapping of the idioms / ピアノロール IDE への流儀のマッピング
A DAW-style piano-roll GUI was identified as structurally isomorphic to PTSG programs; the four
idioms are different ways a "note" maps to wire cycles.
**Starting question:** In a piano-roll IDE, how should the four idioms be surfaced — a per-note
"foreground-cost" display, an auto-balancing toggle, or a Stay-exact mode? Where does
Branch-on-Condition break the 2D grid?

---

## End of Trace / 軌跡の末尾

A blinking LED has a duty cycle; most architectures would give you a register to set it. PTSG
gives you four ways to write it, and the difference between them is not a setting but a sentence —
where you let the foreground cost fall, whether you flag it, whether you banish it to the
background. The duty was never in the silicon to be configured; it was always in the program to be
said.

点滅するLEDにはデューティ比がある;大抵のアーキテクチャはそれを設定するレジスタを与える。PTSG はそれを書く
4つの方法を与え、その差は設定ではなく一文である——前景コストをどこへ落とすか、旗を立てるか、背景へ追放するか。
デューティは設定されるべくシリコンに在ったのではない;言われるべくプログラムに在ったのだ。

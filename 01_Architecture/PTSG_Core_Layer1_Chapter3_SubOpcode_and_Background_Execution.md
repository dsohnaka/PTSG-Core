# PTSG-Core — Layer 1 Specification
# Chapter 3: Sub-Opcode Architecture and Background Execution
# PTSGコア — 第1層仕様書
# 第3章：サブオペコードアーキテクチャと裏実行

> **License: CC0 1.0 Universal (Public Domain)**
> This chapter specifies the dynamic mechanics deferred from Chapter 2: the Stay-window concept, the two background-execution modes (internal-mode reserved execution and external-mode concurrent execution), the minimum-stay-count constraint and its corollaries, the internal information-holding register data layout, the external stack memory protocol for nested call/loop, the auto-save and Return semantics, the external-interrupt (insertion) mechanism, and the loop counter resource set.
>
> **ライセンス：CC0 1.0 Universal（パブリックドメイン）**
> 本章は第2章から繰り延べられた動的機構を指定する: Stayウィンドウ概念、二つの裏実行モード(内部モード予約実行と外部モード並行実行)、最低ステイカウント制約とその系、内部情報保持レジスタのデータレイアウト、ネストされたコール／ループのための外部スタックメモリプロトコル、自動退避とReturn意味論、外部割り込み(挿入)機構、そしてループカウンタリソースセット。

---

## 3.1 Purpose of this Chapter / 本章の目的

Chapter 2 specified PTSG-Core's **static instruction-set surface**: what each opcode does, what the operand fields encode, what the timing signals output. Chapter 2 deliberately stopped at the boundary of dynamic behavior — behaviors involving interaction between adjacent instructions or between the instruction stream and the Stay-counter state. **This chapter crosses that boundary.**

第2章はPTSGコアの**静的命令セット表面**を指定した: 各オペコードが何をするか、オペランドフィールドが何をエンコードするか、タイミング信号が何を出力するか。第2章は意図的に動的挙動の境界で止まった——隣接する命令間または命令ストリームとStayカウンタ状態の間の相互作用を伴う挙動。**本章はその境界を越える。**

The chapter's three principal contributions are:

本章の三つの主要な貢献は:

**1. The Stay-window concept and the two background-execution modes.** Background execution — the ability to fold parallel work into the time of a Stay's wait — has two architecturally distinct realizations: *internal-mode reserved execution* (operations whose effects are deferred and applied exactly at Stay-timeup) and *external-mode concurrent execution* (operations triggered immediately when their state is reached, with external work proceeding concurrently with the Stay's waiting). The Core supports both modes; their semantics differ.

**1. Stayウィンドウ概念と二つの裏実行モード。** 裏実行——並列作業をStayの待機時間に折り込む能力——は二つのアーキテクチャ的に異なる実現を持つ: *内部モード予約実行*(効果が繰り延べられ、Stay-timeupでちょうど適用される演算)と*外部モード並行実行*(ステートに到達した時に即座にトリガされ、外部作業がStayの待機と並行して進行する演算)。コアは両モードをサポートする；意味論は異なる。

**2. The information-holding mechanisms that support sub-sequence call/return, nested loops, and external interrupt.** Several distinct PTSG behaviors — Branch-with-Condition-false (auto-save), Sub-sequence Call (auto-save and call), Base Set (push old base address), Loop (use stacked base), Return (restore), and Insertion (overwrite with auto-save) — all rely on a common mechanism: the **internal information-holding register**, optionally extended by **external stack memory** for nesting beyond what the holding register alone can support. This chapter specifies the data layout, the auto-save protocol, and the external stack bus interface.

**2. サブシーケンスコール／リターン、ネストループ、外部割り込みを支持する情報保持機構。** いくつかの別個のPTSG挙動——Branch-with-Condition-false(自動退避)、Sub-sequence Call(自動退避とコール)、Base Set(古いベースアドレスのプッシュ)、Loop(スタックされたベースを使用)、Return(復元)、そして Insertion(自動退避を伴う上書き)——すべてが共通の機構に依存する: **内部情報保持レジスタ**、保持レジスタ単独で支持できる以上のネスティングのためのオプションの**外部スタックメモリ**で拡張される。本章はデータレイアウト、自動退避プロトコル、外部スタックバスインターフェースを指定する。

**3. The loop counter resource model.** The Loop sub-opcode (§ 2.8) decrements a counter and conditionally jumps to the base address. The Core provides a small set of loop counters; their number, their selection mechanism, their initialization, and their externalization for use by pipeline vector arithmetic (as anticipated in the original PTSG specification) are specified here.

**3. ループカウンタリソースモデル。** Loop サブオペコード(§ 2.8)はカウンタをデクリメントし条件付きでベースアドレスにジャンプする。コアはループカウンタの小さなセットを提供する；その数、選択機構、初期化、そしてパイプラインベクタ算術で使用するための外部化(オリジナルPTSG仕様で予期されているように)はここで指定される。

**This chapter contains the most timing-sensitive material in PTSG-Core Layer 1.** Some timing details have multiple reasonable interpretations; where this is the case, the alternatives are recorded as Ties in § 3.13 with community discussion explicitly invited. The contributor anticipates that **several Chapter 3 Tie items will be the subject of active discussion in the coming weeks**, both with current contributors and with Formation authors as the first Formations are designed.

**本章はPTSGコア第1層において最もタイミング感度の高い素材を含む。** 一部のタイミング詳細は複数の合理的解釈を持つ；そのような場合、代替案は § 3.13 にTieとして記録され、コミュニティ議論が明示的に招かれる。貢献者は**いくつかの第3章Tie項目が、現在の貢献者と、最初のフォーメーションが設計されるにつれてフォーメーション作者との両方で、来る週における活発な議論の主題になる**ことを予期する。

---

## 3.2 The Stay-Window Concept / Stayウィンドウ概念

**Definition.** The **Stay window** is the period during which the Core's stay counter is active: it begins when **Stay Set** (Global sub-op 002, Chapter 2 § 2.8) executes and ends at **Stay-timeup** (when the stay counter reaches the value specified by the following Stay opcode's operand). All Global instructions encountered during this window are subject to background execution semantics; all non-Global instructions are processed as defined in Chapter 2.

**定義。** **Stayウィンドウ**はコアのステイカウンタが活動的である期間である: それは **Stay Set** (Global サブop 002、第2章 § 2.8) が実行される時に始まり、**Stay-timeup**(ステイカウンタが続くStayオペコードのオペランドで指定された値に達する時)で終わる。本ウィンドウ中に遭遇するすべての Global 命令は裏実行意味論の対象である；すべての非 Global 命令は第2章で定義されたように処理される。

**The canonical Stay-window structure.** A typical Stay-window-using sequence looks like:

**正典的なStayウィンドウ構造。** Stayウィンドウを使用する典型的なシーケンスは次のように見える:

```
  State N:    Global (sub-op 002 = Stay Set)        ← stay counter starts; window opens
  State N+1:  Global (e.g., sub-op 1 = external register write)   ← background-executed
  State N+2:  Global (e.g., sub-op 2 = some other external op)    ← background-executed
   ...
  State N+k:  Stay (opcode 1, operand = M)          ← Core halts here; window closes at counter = M
  State N+k+1: ... (whatever follows; window has ended)
```

| Position | Role |
|---|---|
| State N | **Window opener.** Stay Set executes; stay counter starts ticking from 0; timing signals enter "hold mode" (the value being held is specified below). / **ウィンドウ開設者。** Stay Set が実行される；ステイカウンタが 0 から刻み始める；タイミング信号が「保持モード」に入る(保持される値は以下で指定される)。 |
| States N+1 to N+k−1 | **Background-execution band.** Each Global encountered here is processed under background-execution semantics (§§ 3.3–3.5). Each state takes 1 clock to advance through. Non-Global instructions placed here are unusual but not prohibited; they execute as defined in Chapter 2. / **裏実行帯域。** ここで遭遇する各 Global は裏実行意味論(§§ 3.3-3.5)の下で処理される。各ステートは進むために 1 クロックを要する。ここに置かれた非 Global 命令は珍しいが禁止されない；第2章で定義されたように実行される。 |
| State N+k | **Window closer.** Stay opcode is reached. Core halts at this state until stay counter = M. Any pending internal-mode reserved operations execute (scheduled backward from this moment). Any pending external-mode operations must have completed (constraint, § 3.6). When all complete, window closes; Core advances to N+k+1. / **ウィンドウ閉鎖者。** Stay オペコードに到達する。コアはステイカウンタ = M までこのステートで停止する。任意の保留中の内部モード予約演算が実行される(この瞬間から後方スケジュール)。任意の保留中の外部モード演算は完了していなければならない(制約、§ 3.6)。すべて完了した時、ウィンドウは閉じる；コアは N+k+1 に進む。 |

**Timing signal output during the Stay window.** The timing signal bus (D16–D31) is held at a stable value throughout the Stay window. The specific value to which it is held is recorded as Tie C3-T1 in § 3.15: the alternatives are (a) the D16–D31 value of the Stay state at N+k (which requires the Core to look ahead), or (b) the D16–D31 value of the Stay Set state at N (which is the natural value at the moment the window opens), or (c) the D16–D31 value of the *last non-background state* before the window (which is more complex but most physically natural). The contributor's current intent is (a) — the Stay state's value — because it is what the instruction-list author expects to be the "active output during the wait." Community discussion is invited.

**Stayウィンドウ中のタイミング信号出力。** タイミング信号バス(D16-D31)は Stayウィンドウを通じて安定値に保持される。それが保持される具体的な値は § 3.15 で Tie C3-T1 として記録される: 代替案は (a) N+k の Stay ステートの D16-D31 値(コアの先読みを要求する)、(b) N の Stay Set ステートの D16-D31 値(ウィンドウが開く瞬間の自然な値)、または (c) ウィンドウ前の*最後の非裏側ステート*の D16-D31 値(より複雑だが物理的に最も自然)。貢献者の現在の意図は (a)——Stay ステートの値——である、なぜならそれが命令リスト作者が「待機中の活動的出力」として期待するものだからである。コミュニティ議論を招く。

**Why the Stay-window concept matters.** Without a clearly-defined Stay window, the question "is this Global background-executed or not?" has no unambiguous answer. The Stay-window concept makes the answer mechanical: a Global is background-executed if and only if it is encountered while the stay counter is active. The window's boundaries (Stay Set to Stay-timeup) are explicit and observable. This is what allows Formations to be designed against the Core: a Formation author can reason about each Global's behavior by reference to the Stay window, without needing implementation-internal knowledge.

**なぜStayウィンドウ概念が重要か。** 明確に定義された Stayウィンドウなしには、「この Global は裏実行されるかされないか?」という問いは曖昧でない答えを持たない。Stayウィンドウ概念は答えを機械的にする: Global は、それが遭遇する時にステイカウンタが活動的である場合かつその場合に限り、裏実行される。ウィンドウの境界(Stay Set から Stay-timeup まで)は明示的であり観察可能である。これがフォーメーションがコアに対して設計されることを許すものである: フォーメーション作者は実装内部の知識を必要とせず、Stayウィンドウへの参照によって各 Global の挙動について推論できる。

---

## 3.3 Background Execution — The Two Modes / 裏実行 — 二つのモード

A Global instruction encountered during the Stay window is processed under one of two modes, determined by D4–D7 of the operand field (the sub-opcode selector, Chapter 2 § 2.7):

Stayウィンドウ中に遭遇する Global 命令は、オペランドフィールドの D4-D7(サブオペコード選択子、第2章 § 2.7)によって決定される二つのモードのいずれかの下で処理される:

| Mode | Condition | Timing model | Operations |
|---|---|---|---|
| **Internal-mode reserved execution** | D4–D7 = 0 (operand is internal-control sub-opcode 0–255) | **Backward-scheduled:** operation completes exactly at Stay-timeup. If the operation takes L clocks, it starts at Stay-timeup − L. / **後方スケジュール:** 演算は Stay-timeup でちょうど完了する。演算が L クロック要する場合、Stay-timeup − L で開始する。 | Reset, Base Set, Stay Set, Return, Sub-sequence Call, Loop, NOP, (reserved 6, 8–255) / Reset、Base Set、Stay Set、Return、Sub-sequence Call、Loop、NOP、(予約 6、8-255) |
| **External-mode concurrent execution** | D4–D7 = 1–F (operand is external sub-opcode 1–15 + sub-operand) | **Forward-scheduled:** operation triggered immediately when its state is reached. Operation runs concurrently with the rest of the Stay window. Must complete before Stay-timeup. / **前方スケジュール:** 演算はそのステートに到達した時に即座にトリガされる。演算は Stayウィンドウの残りと並行して走る。Stay-timeup までに完了しなければならない。 | Formation-specific external operations: register writes, bus operations, peripheral commands, etc. (See each Formation's Layer 1.) / フォーメーション固有の外部演算: レジスタ書き込み、バス演算、ペリフェラルコマンド等。(各フォーメーションのLayer 1参照。) |

The two modes coexist within one Stay window. A typical pattern combining both:

二つのモードは一つのStayウィンドウ内で共存する。両方を組み合わせる典型的なパターン:

```
  State N:    Global (sub-op 002 = Stay Set)
  State N+1:  Global (D4-D7=1, external write to Reg_A)    ← external-mode: triggered at clock 1
  State N+2:  Global (D4-D7=1, external write to Reg_B)    ← external-mode: triggered at clock 2
  State N+3:  Global (D4-D7=0, sub-op 005 = Loop)          ← internal-mode: queued for Stay-timeup
  State N+4:  Stay (operand = M)                           ← halt here until stay-timeup
```

In this pattern: the external register writes to Reg_A and Reg_B trigger at clocks 1 and 2 respectively (assuming Stay Set at clock 0), running concurrently with the wait. The Loop sub-opcode is queued and executes at Stay-timeup, exactly when the wait completes; its effect (decrement loop counter, jump to base address if counter ≠ 0) is applied as Core advances.

このパターンにおいて: Reg_A と Reg_B への外部レジスタ書き込みはそれぞれクロック 1 と 2 でトリガされ、待機と並行して走る。Loop サブオペコードはキューに入り Stay-timeup で実行される、ちょうど待機が完了する時；その効果(ループカウンタをデクリメントし、カウンタが ≠ 0 ならベースアドレスにジャンプ)はコアが進む時に適用される。

**Why the two modes have different timing scheduling.** The asymmetry is architecturally motivated, not arbitrary:

**なぜ二つのモードが異なるタイミングスケジューリングを持つか。** 非対称性はアーキテクチャ的に動機づけられており、恣意的ではない:

- **Internal-mode operations affect Core control state** (loop counters, base address, holding register, State Number register). Their effect must be applied at *exactly the moment* the Stay window ends, because the Core's next-state computation depends on these values being current at that moment. Backward scheduling guarantees this.
- **External-mode operations drive external logic.** Their results are typically consumed by external hardware *during* the Stay window (e.g., an external register's new value is used by external Condition logic at some point during the Stay). Forward scheduling — trigger immediately, complete before Stay-timeup — gives external logic the longest possible time to act on the new value.

- **内部モード演算はコア制御状態に影響する**(ループカウンタ、ベースアドレス、保持レジスタ、ステートナンバーレジスタ)。それらの効果は Stayウィンドウが終わる*まさにその瞬間*に適用されなければならない、なぜならコアの次ステート計算はその瞬間にこれらの値が最新であることに依存する。後方スケジューリングはこれを保証する。
- **外部モード演算は外部ロジックを駆動する。** それらの結果は典型的に Stayウィンドウ*中に*外部ハードウェアによって消費される(例: 外部レジスタの新しい値が外部 Condition ロジックによって Stay 中のどこかの時点で使用される)。前方スケジューリング——即座にトリガし、Stay-timeup までに完了——は外部ロジックに新しい値に作用する可能な限り最長の時間を与える。

**D16–D31 repurposing.** Per Chapter 2 § 2.9, the timing-signal field (D16–D31) of a background-executed Global is reinterpreted as sub-operand data, not driven to the timing-signal output bus. The output bus continues to present the Stay-window held value (see Tie C3-T1 above). This repurposing is essential for the canonical "external register write" pattern (sub-opcode 1: D8–D15 = address, D16–D31 = data).

**D16-D31 の再目的化。** 第2章 § 2.9 によれば、裏実行された Global のタイミング信号フィールド(D16-D31)はサブオペランドデータとして再解釈され、タイミング信号出力バスには駆動されない。出力バスは Stayウィンドウ保持値(上記 Tie C3-T1 参照)を提示し続ける。本再目的化は正典的な「外部レジスタ書き込み」パターン(サブオペコード 1: D8-D15 = アドレス、D16-D31 = データ)に必須である。

---

## 3.4 Internal-Mode Reserved Execution (D4–D7 = 0) / 内部モード予約実行 (D4-D7 = 0)

**Semantics.** When a Global with D4–D7 = 0 is encountered during the Stay window, its effect is *not* applied at the clock it is encountered. Instead, the operation is enqueued in an internal reservation queue. At Stay-timeup, queued operations are executed; their effects (which include any control-state changes the operation prescribes) take effect just before the Core advances out of the Stay state.

**意味論。** D4-D7 = 0 を持つ Global が Stayウィンドウ中に遭遇する時、その効果は遭遇したクロックに*適用されない*。代わりに、演算は内部予約キューに入れられる。Stay-timeup で、キューに入った演算が実行される；それらの効果(演算が規定する任意の制御状態変更を含む)は、コアが Stay ステートから進む直前に有効になる。

**Why this design.** Internal-mode operations include Reset, Base Set, Loop, and Return — all of which affect the Core's control state in ways that determine where the Core goes after the Stay completes. If these were applied immediately when encountered (during the background-execution band), they would affect control state *before* the Stay completes, potentially corrupting the Stay-window timing. By deferring to Stay-timeup, the Core ensures that the Stay window's predictable timing is preserved.

**なぜこの設計か。** 内部モード演算は Reset、Base Set、Loop、Return を含む——これらすべては、Stay 完了後にコアがどこに行くかを決定する仕方でコアの制御状態に影響する。これらが遭遇した時に即座に適用された場合(裏実行帯域中に)、それらは Stay の完了*前に*制御状態に影響し、Stayウィンドウのタイミングを破損する可能性がある。Stay-timeup に繰り延べることで、コアは Stayウィンドウの予測可能なタイミングが保持されることを保証する。

**Backward-scheduling protocol.** An internal-mode operation that takes L clocks to execute (where L ≥ 1) is scheduled to *start* at clock (Stay-timeup − L) and *complete* exactly at Stay-timeup. For most simple operations (Reset, Loop, NOP), L = 1. For operations that may take longer (e.g., implementations of Return that involve external stack memory read, see § 3.7), L can be higher.

**後方スケジューリングプロトコル。** L クロックを実行に要する内部モード演算(L ≥ 1)は、クロック (Stay-timeup − L) で*開始*し、Stay-timeup でちょうど*完了*するようスケジュールされる。ほとんどの単純な演算(Reset、Loop、NOP)について、L = 1。より長く要し得る演算(例: 外部スタックメモリ読みを伴う Return の実装、§ 3.7 参照)について、L はより高くなり得る。

**Ordering of multiple internal-mode operations.** If multiple internal-mode Globals are encountered during one Stay window, their order of execution at Stay-timeup is recorded as Tie C3-T2 in § 3.15. The alternatives:
- (A) **FIFO** — operations execute in the order they were encountered. Simplest mental model; consistent with the instruction-list-author's intuition.
- (B) **LIFO** — operations execute in reverse order of encounter. Matches stack-based control-flow models but is harder to reason about.
- (C) **Implementation-defined** — the Core specification does not commit to an ordering; Formation authors avoid relying on order.

The contributor's current intent is (A) FIFO. However, the use case for multiple internal-mode operations in one window is unusual; most patterns use at most one internal-mode operation per window. Community discussion of this Tie is invited but unlikely to surface a high-stakes case.

**複数の内部モード演算の順序。** 複数の内部モード Global が一つのStayウィンドウ中に遭遇する場合、Stay-timeup での実行順序は § 3.15 に Tie C3-T2 として記録される。代替案:
- (A) **FIFO** — 遭遇された順序で演算が実行される。最も単純な心的モデル；命令リスト作者の直感と整合的。
- (B) **LIFO** — 遭遇の逆順で演算が実行される。スタックベース制御フローモデルと一致するが、推論がより難しい。
- (C) **実装定義** — コア仕様は順序にコミットしない；フォーメーション作者は順序に依存することを避ける。

貢献者の現在の意図は (A) FIFO である。しかし、一つのウィンドウ内の複数の内部モード演算の使用事例は珍しい；ほとんどのパターンは一ウィンドウあたり最大一つの内部モード演算を使う。本Tieについてのコミュニティ議論を招くが、高い利害事例を浮上させる可能性は低い。

**Special case: Stay Set inside a Stay window.** What happens if a Stay Set is encountered *inside* an already-open Stay window? This is recorded as Tie C3-T3. The alternatives: (A) the inner Stay Set is treated as a no-op (the existing window continues); (B) the inner Stay Set ends the current window and starts a new one (resetting the stay counter); (C) the inner Stay Set is an error / undefined behavior. The contributor leans toward (A), but the question is genuinely open.

**特殊ケース: Stayウィンドウ内のStay Set。** Stay Set が*すでに開いている*Stayウィンドウ内で遭遇された場合、何が起こるか? これは Tie C3-T3 として記録される。代替案: (A) 内側の Stay Set は no-op として扱われる(既存のウィンドウが継続する)；(B) 内側の Stay Set は現在のウィンドウを終了し新しいものを開始する(ステイカウンタをリセット)；(C) 内側の Stay Set はエラー／未定義挙動。貢献者は (A) に傾くが、問いは真に開かれている。

---

## 3.5 External-Mode Concurrent Execution (D4–D7 = 1–F) / 外部モード並行実行 (D4-D7 = 1-F)

**Semantics.** When a Global with D4–D7 = 1–F is encountered during the Stay window, its effect is triggered *immediately* on the clock it is encountered. The Core asserts the appropriate external-bus signals (decoded from D4–D7 as sub-opcode and D8–D15, D16–D31 as sub-operand data) and signals the start of an external operation. The Core then proceeds to the next state on the next clock; the external operation continues in parallel.

**意味論。** D4-D7 = 1-F を持つ Global が Stayウィンドウ中に遭遇する時、その効果は遭遇するクロックに*即座に*トリガされる。コアは適切な外部バス信号(D4-D7 をサブオペコード、D8-D15 をサブオペランド、D16-D31 をサブオペランドデータとしてデコード)をアサートし、外部演算の開始を信号する。コアはそれから次クロックで次のステートに進む；外部演算は並行して継続する。

**External bus protocol — overview.** The Core exposes an **external-operation bus** (the precise pin-level signaling is specified in Chapter 5, the External Logic Interface). Conceptually, the bus carries:

**外部演算バスプロトコル — 概要。** コアは**外部演算バス**を露出する(正確なピンレベルシグナリングは第5章「外部ロジックインターフェース」で指定される)。概念的に、バスは以下を運ぶ:

| Bus signal | Width | Source field | Purpose |
|---|---|---|---|
| `ext_op_valid` | 1 bit | Asserted by Core | High for one clock when an external-mode Global state is encountered / 外部モード Global ステートに遭遇する時に1クロック高 |
| `ext_op_subopcode` | 4 bits | D4–D7 of Global | Identifies which external operation (1–15) / どの外部演算を識別する (1-15) |
| `ext_op_sub_operand` | 8 bits | D8–D15 of Global | Sub-operand (e.g., register address for sub-op 1 = write) / サブオペランド(例: サブop 1 = 書き込みのレジスタアドレス) |
| `ext_op_data` | 16 bits | D16–D31 of Global | Immediate data (e.g., register value for sub-op 1 = write) / 即値データ(例: サブop 1 = 書き込みのレジスタ値) |
| `ext_op_ready` | 1 bit | Driven by external logic | Asserted by external logic when the operation completes; Core uses this for minimum-stay-count validation (see § 3.6) / 演算が完了する時に外部ロジックによってアサートされる；コアは最低ステイカウント検証のためにこれを使う(§ 3.6 参照) |

**The `ext_op_ready` handshake.** External logic asserts `ext_op_ready` when its operation completes. The Core uses this to detect minimum-stay-count violations: if Stay-timeup arrives before `ext_op_ready` from a still-in-progress external operation, a violation has occurred (§ 3.6). The exact violation-handling behavior is recorded as Tie C3-T4 in § 3.15: (A) Core asserts an error signal but proceeds (operation result may be lost); (B) Core stalls until `ext_op_ready` arrives (extending the Stay window past timeup); (C) Implementation-defined. The contributor leans toward (A) with the error signal documented in Chapter 5, but Formation authors may have strong opinions.

**`ext_op_ready` ハンドシェイク。** 外部ロジックは演算が完了する時に `ext_op_ready` をアサートする。コアは最低ステイカウント違反を検出するためにこれを使う: Stay-timeup が、まだ進行中の外部演算からの `ext_op_ready` より前に到来すれば、違反が起きている(§ 3.6)。正確な違反処理挙動は § 3.15 に Tie C3-T4 として記録される: (A) コアはエラー信号をアサートするが進む(演算結果は失われ得る)；(B) コアは `ext_op_ready` が到来するまで停滞する(Stayウィンドウを timeup を超えて延長する)；(C) 実装定義。貢献者は (A) に傾き、エラー信号は第5章で文書化されるが、フォーメーション作者は強い意見を持ち得る。

**Multiple external-mode operations in one Stay window.** Multiple external-mode Globals can be placed in one Stay window. Each triggers on its own clock; each runs concurrently with the others (assuming the external logic can support concurrent operations). **The Core does not arbitrate** — it simply asserts `ext_op_valid` once per Global encountered. The external logic is responsible for handling concurrency or serialization. This is recorded as fact C3-F8 in § 3.15.

**一つのStayウィンドウ内の複数の外部モード演算。** 複数の外部モード Global が一つのStayウィンドウに置かれ得る。各々は自身のクロックでトリガする；各々は他と並行して走る(外部ロジックが並行演算をサポートできると仮定して)。**コアは調停しない**——遭遇する Global あたり一度だけ `ext_op_valid` をアサートする。外部ロジックは並行性または直列化を処理する責任がある。これは § 3.15 で事実 C3-F8 として記録される。

**The external-mode bus protocol is Formation-influenced.** While the Core specifies the bus signals at the level above (valid, sub-opcode, sub-operand, data, ready), the *interpretation* of sub-opcodes 1–15 is Formation-specific. A `PTSG_WPMS_Formation_OpenPrompt` and a `PTSG_I2C_Formation_OpenPrompt` will assign different meanings to the same sub-opcode values. **The Core specifies the mechanism; the Formation specifies the assignments.**

**外部モードバスプロトコルはフォーメーションの影響を受ける。** コアは上記レベルでバス信号を指定する(valid、サブオペコード、サブオペランド、データ、ready)が、サブオペコード 1-15 の*解釈*はフォーメーション固有である。`PTSG_WPMS_Formation_OpenPrompt` と `PTSG_I2C_Formation_OpenPrompt` は同じサブオペコード値に異なる意味を割り当てる。**コアは機構を指定する；フォーメーションは割り当てを指定する。**

**External-mode Global outside a Stay window — what happens?** If an external-mode Global is encountered while the stay counter is *not* active (no open Stay window), the Core still asserts `ext_op_valid` for one clock. However, there is no Stay-timeup constraint that the operation must complete by; the operation can take as long as the external logic needs. The Core then advances on the next clock regardless. This is recorded as fact C3-F9. Whether this "Stay-less" external-mode invocation is a reasonable pattern is a Formation-side concern.

**Stayウィンドウ外の外部モード Global — 何が起こるか?** 外部モード Global がステイカウンタが*活動的でない*時(開いたStayウィンドウなし)に遭遇された場合、コアは依然として 1 クロック `ext_op_valid` をアサートする。しかし、演算が完了するべき Stay-timeup 制約はない；演算は外部ロジックが必要なだけの時間を取り得る。コアはそれから次クロックで関係なく進む。これは事実 C3-F9 として記録される。本「Stayレス」外部モード呼び出しが合理的なパターンであるかどうかはフォーメーション側の懸念である。

---

## 3.6 The Minimum-Stay-Count Constraint / 最低ステイカウント制約

**The constraint.** For a Stay-window to function correctly, the Stay opcode's operand (which determines Stay-timeup) must be large enough to accommodate:

**制約。** Stayウィンドウが正しく機能するためには、Stay オペコードのオペランド(Stay-timeup を決定する)は以下を収容するに十分大きくなければならない:

- **All external-mode operations triggered in the window** must complete (assert `ext_op_ready`) before Stay-timeup. For an external-mode Global at state N+i (with i ≥ 1) whose external operation takes L_ext clocks, the Stay's operand M must satisfy M ≥ i + L_ext (counting from the Stay Set state at N).
- **All internal-mode operations queued in the window** must have time to execute backward from Stay-timeup. For an internal-mode operation with latency L_int, this is automatic provided the Stay opcode is reached before clock (Stay-timeup − L_int); typically this is well-satisfied for L_int = 1.

- **ウィンドウ内でトリガされたすべての外部モード演算**は Stay-timeup までに完了しなければならない(`ext_op_ready` をアサートする)。L_ext クロックを要する外部演算を持つステート N+i (i ≥ 1) の外部モード Global について、Stay のオペランド M は M ≥ i + L_ext を満たさなければならない(N の Stay Set ステートから数えて)。
- **ウィンドウ内でキューに入ったすべての内部モード演算**は Stay-timeup から後方に実行する時間を持たなければならない。レイテンシ L_int の内部モード演算について、これは Stay オペコードがクロック (Stay-timeup − L_int) より前に到達されれば自動的である；典型的に L_int = 1 についてはよく満たされる。

**The chaining rule (Gemini-derived).** When multiple external-mode operations are placed in one Stay window, *their latencies must collectively fit*. Specifically: if external-mode Globals are placed at states N+1, N+2, ..., N+(k−1) (where state N+k is the Stay), with respective external latencies L_1, L_2, ..., L_{k−1}, then for *each* i, M ≥ i + L_i must hold. The most-binding constraint is typically the operation with the largest (i + L_i). This chaining rule was derived correctly by Gemini in the comprehension trace (`02_Reasoning_Traces/contributed/dsohnaka/2026-05-20_ptsg-comprehension-by-gemini.md`) as a corollary of Chapter 1 § 1.6.

**連鎖規則(Gemini導出)。** 複数の外部モード演算が一つの Stayウィンドウに置かれる時、*それらのレイテンシは集合的に収まらなければならない*。具体的に: 外部モード Global がステート N+1, N+2, ..., N+(k−1) に置かれ(ステート N+k は Stay)、それぞれの外部レイテンシ L_1, L_2, ..., L_{k−1} を伴う場合、*各* i について M ≥ i + L_i が成り立たなければならない。最も拘束的な制約は典型的に最大の (i + L_i) を持つ演算である。本連鎖規則は、第1章 § 1.6 の系として、Gemini が読解軌跡(`02_Reasoning_Traces/contributed/dsohnaka/2026-05-20_ptsg-comprehension-by-gemini.md`)で正しく導出した。

**The Formation-documentation obligation (Gemini-derived).** Because the minimum-stay-count constraint depends on each Formation's external-operation latencies, **Formation authors must publish, in their Formation's Layer 1 specification, the clock latency of every external operation their Formation supports**. Without this documentation, instruction-list authors (human or AI) cannot determine a safe Stay-operand value. This obligation is also Gemini-derived (same trace) and is now formally recorded as a normative requirement for all Formations.

**フォーメーション文書化義務(Gemini導出)。** 最低ステイカウント制約は各フォーメーションの外部演算レイテンシに依存するため、**フォーメーション作者は、彼らのフォーメーションがサポートするすべての外部演算のクロックレイテンシを、彼らのフォーメーションの第1層仕様で公開しなければならない**。本文書化なしでは、命令リスト作者(人間または AI)は安全な Stay-operand 値を決定できない。本義務もまた Gemini 由来(同じ軌跡)であり、今やすべてのフォーメーションに対する規範的要件として正式に記録される。

**Violation behavior.** What happens if the minimum-stay-count constraint is violated (Stay-timeup arrives before an external operation's `ext_op_ready`)? This is Tie C3-T4 in § 3.15, already mentioned in § 3.5. The three alternatives: (A) Core proceeds, asserts error signal; (B) Core stalls until ready; (C) Implementation-defined.

**違反挙動。** 最低ステイカウント制約が違反される場合(Stay-timeup が外部演算の `ext_op_ready` より前に到来する場合)、何が起こるか? これは § 3.5 で既に言及された § 3.15 の Tie C3-T4 である。三つの代替案: (A) コアは進み、エラー信号をアサートする；(B) コアは ready まで停滞する；(C) 実装定義。

**Detection at instruction-list-design time.** The minimum-stay-count constraint is best satisfied at instruction-list-design time, not at run time. A future PTSG simulator (the Webapp PTSG simulator anticipated in Chapter 1 § 1.10) should perform this check automatically, given the Formation's published latencies. Until that simulator exists, instruction-list authors (especially AI agents) must perform the check manually using the Formation's documented latencies.

**命令リスト設計時の検出。** 最低ステイカウント制約は、実行時ではなく命令リスト設計時に最もよく満たされる。将来のPTSGシミュレータ(第1章 § 1.10 で予期される Webapp PTSGシミュレータ)は、フォーメーションの公開レイテンシが与えられた時に本チェックを自動的に行うべきである。本シミュレータが存在するまで、命令リスト作者(特に AI エージェント)はフォーメーションの文書化されたレイテンシを使って手動でチェックを行わなければならない。

---

## 3.7 The Internal Information-Holding Register / 内部情報保持レジスタ

**Purpose.** The internal information-holding register is a single-entry register that holds the values of selected Core control-state items, saved automatically just before certain operations that would otherwise lose those values. Operations that auto-save: **Branch (taken, Chapter 2 § 2.5)**, **Sub-sequence Call (internal sub-op 004)**, **Base Set (internal sub-op 001)**, **Insertion (external interrupt, § 3.11)**. The operation that restores from the holding register: **Return (internal sub-op 003)**.

**目的。** 内部情報保持レジスタは、それ以外ではそれらの値を失う特定の演算の直前に、選択されたコア制御状態項目の値を自動的に保存して保持する単一エントリレジスタである。自動退避する演算: **Branch(取られる、第2章 § 2.5)**、**Sub-sequence Call(内部サブop 004)**、**Base Set(内部サブop 001)**、**Insertion(外部割り込み、§ 3.11)**。保持レジスタから復元する演算: **Return(内部サブop 003)**。

**Data layout.** The holding register stores the following control-state items as a single atomic group:

**データレイアウト。** 保持レジスタは以下の制御状態項目を単一の原子グループとして格納する:

| Item | Width | Saved by | Restored by |
|---|---|---|---|
| State Number (return address) | 12 bits | Branch (taken), Sub-sequence Call, Insertion | Return |
| Loop counter values (all active counters) | N × counter_width bits (N = number of loop counters, see § 3.12) | All auto-save triggers | Return |
| Base address | 12 bits | Base Set (the previously-active base, before being overwritten) | Return |
| Reserved / flag bits | implementation-defined | implementation | implementation |

**The "atomic group" property.** All items above are saved or restored together; there is no partial save or partial restore. This simplifies the protocol and ensures consistent state. The exact width of the saved group is implementation-tunable (depends on loop counter width and number — see § 3.12) but the *items* are fixed.

**「原子グループ」性質。** 上記すべての項目は一緒に保存または復元される；部分的な保存も部分的な復元もない。これはプロトコルを単純化し、一貫した状態を保証する。保存されたグループの正確な幅は実装で調整可能である(ループカウンタ幅と数に依存する——§ 3.12 参照)が、*項目*は固定されている。

**The single-entry nature and its implication.** The holding register is **one entry**. It cannot hold multiple saved contexts. If a second auto-save trigger occurs while a context is already saved in the holding register, **the existing context is overwritten** unless the existing context has first been pushed to external stack memory (§ 3.8). The Return operation always restores from the holding register's current contents; if nothing has been saved since the last Return, behavior is undefined (recorded as Tie C3-T5).

**単一エントリ性質とその含意。** 保持レジスタは**一エントリ**である。複数の保存されたコンテキストを保持できない。第二の自動退避トリガが、コンテキストが既に保持レジスタに保存されている間に起こる場合、既存のコンテキストが外部スタックメモリにまずプッシュされない限り(§ 3.8)、**既存のコンテキストは上書きされる**。Return 演算は常に保持レジスタの現在の内容から復元する；最後の Return から何も保存されていなければ、挙動は未定義(Tie C3-T5 として記録される)。

**Why single-entry.** The single-entry design follows from the Core minimalism discipline of Chapter 1 § 1.2. Multi-entry register banks would require additional resources, indexing logic, and a more complex protocol — all of which would expand the Core's surface area beyond its ~200 LE target. Nesting beyond one level is supported via the **external stack memory** (§ 3.8), which puts the resource cost outside the Core and gives Formations control over the depth they choose to support.

**なぜ単一エントリか。** 単一エントリ設計は第1章 § 1.2 のコアミニマリズム規律から従う。マルチエントリレジスタバンクは追加のリソース、索引付けロジック、より複雑なプロトコルを要求する——これらすべてはコアの表面積を ~200 LE 目標を超えて拡張する。一レベルを超えるネスティングは**外部スタックメモリ**(§ 3.8)経由でサポートされ、これはリソースコストをコアの外部に置き、フォーメーションが選択するサポート深度の制御を与える。

---

## 3.8 External Stack Memory / 外部スタックメモリ

**Purpose.** External stack memory extends the internal holding register's depth-1 nesting limit to whatever depth the Formation chooses to support. The Core specifies a bus protocol for push/pop; the Formation provides the actual memory (a BRAM block, a small register file, or — in simple cases — no stack memory at all).

**目的。** 外部スタックメモリは内部保持レジスタの深さ 1 のネスティング限界を、フォーメーションが選択するサポート深度まで拡張する。コアはプッシュ／ポップのためのバスプロトコルを指定する；フォーメーションは実際のメモリを提供する(BRAM ブロック、小さなレジスタファイル、または——単純な場合に——スタックメモリなし)。

**The push/pop protocol — overview.** The Core exposes an **external stack bus** (pin-level details in Chapter 5):

**プッシュ／ポッププロトコル — 概要。** コアは**外部スタックバス**を露出する(ピンレベル詳細は第5章):

| Bus signal | Width | Direction | Asserted when |
|---|---|---|---|
| `stack_push_req` | 1 bit | Core → External | Core wants to push the current holding register to stack / コアが現在の保持レジスタをスタックにプッシュしたい時 |
| `stack_pop_req` | 1 bit | Core → External | Core wants to pop into the holding register / コアが保持レジスタにポップしたい時 |
| `stack_data` | (data width) | Bidirectional | Push: Core → External; Pop: External → Core / プッシュ: コア → 外部；ポップ: 外部 → コア |
| `stack_ack` | 1 bit | External → Core | Operation completed; data is valid / 演算完了；データは有効 |

**When does push/pop happen automatically vs explicitly?** This is recorded as Tie C3-T6 in § 3.15. The alternatives:

- **(A) Implicit push/pop:** When an auto-save trigger fires and the holding register already contains saved data, the Core *automatically* pushes the old contents to external stack before overwriting. Symmetric pop on Return. Simplest from the Formation author's perspective but requires the Core to always interact with the stack bus.
- **(B) Explicit push/pop sub-opcodes:** New internal-mode sub-opcodes (occupying part of the reserved 8–255 range from § 2.8) for explicit push and pop. Instruction-list authors must place these explicitly. More flexible but requires more programmer awareness.
- **(C) Hybrid:** Implicit push only when needed (nested auto-save), explicit pop. Asymmetric but pragmatic.

The contributor's current intent is (A) **implicit**, but this is a significant design decision and community discussion is invited.

**プッシュ／ポップはいつ自動的に対明示的に起こるか?** これは § 3.15 で Tie C3-T6 として記録される。代替案:

- **(A) 暗黙的プッシュ／ポップ:** 自動退避トリガが発火する時に保持レジスタが既に保存データを含んでいる場合、コアは上書き前に古い内容を*自動的に*外部スタックにプッシュする。Return での対称的ポップ。フォーメーション作者の視点から最も単純だが、コアが常にスタックバスと相互作用することを要求する。
- **(B) 明示的プッシュ／ポップサブオペコード:** 明示的プッシュとポップのための新しい内部モードサブオペコード(§ 2.8 の予約 8-255 範囲の一部を占有)。命令リスト作者はこれらを明示的に置かなければならない。より柔軟だがプログラマの認識をより要求する。
- **(C) ハイブリッド:** 必要な時のみ暗黙的プッシュ(ネストされた自動退避)、明示的ポップ。非対称だが実用的。

貢献者の現在の意図は (A) **暗黙的**であるが、これは重要な設計決定であり、コミュニティ議論を招く。

**Stack memory absence is permitted.** A Formation may legitimately provide no external stack memory. In that case, the holding register's depth-1 limit is the absolute nesting limit; attempting to nest beyond (e.g., a second Branch-taken while a context is already saved) results in the existing context being overwritten without being saved elsewhere. **Formations that omit stack memory must document this clearly in their Layer 1**, since instruction-list authors will need to constrain their nesting depth accordingly.

**スタックメモリの不在は許可される。** フォーメーションは合法的に外部スタックメモリを提供しないことができる。その場合、保持レジスタの深さ 1 制限は絶対的なネスティング制限である；それを超えてネストしようとする(例: コンテキストが既に保存されている間に第二の Branch-taken)は、既存のコンテキストが他の場所に保存されることなく上書きされる結果になる。**スタックメモリを省略するフォーメーションは彼らの第1層でこれを明確に文書化しなければならない**、なぜなら命令リスト作者はそれに応じてネスティング深度を制約する必要があるからである。

---

## 3.9 Auto-Save Triggers and Return Semantics / 自動退避トリガと Return 意味論

**The four auto-save triggers.** The following operations cause an auto-save of the holding-register-defined control state (§ 3.7):

**四つの自動退避トリガ。** 以下の演算は保持レジスタ定義の制御状態(§ 3.7)の自動退避を引き起こす:

| Trigger | What gets saved | What changes after save |
|---|---|---|
| **Branch (taken)** (opcode 2, Condition = false) | Current State Number, all loop counters, base address | State Number → current + operand; loop counters unchanged at the moment of save; base address unchanged / ステートナンバー → current + オペランド；ループカウンタは保存の瞬間に不変；ベースアドレスは不変 |
| **Sub-sequence Call** (Global sub-op 004) | Same as above | State Number → current + sub-operand offset; otherwise as above / ステートナンバー → current + サブオペランドオフセット；他は上記と同じ |
| **Base Set** (Global sub-op 001) | Same as above (with current base address being saved as the value-before-overwrite) | Base address → current State Number; State Number → current + 1; loop counters unchanged / ベースアドレス → 現在のステートナンバー；ステートナンバー → current + 1；ループカウンタ不変 |
| **Insertion** (external interrupt, § 3.11) | Same as above | State Number → external override value; loop counters unchanged at the moment of save; base address unchanged / ステートナンバー → 外部上書き値；ループカウンタは保存の瞬間に不変；ベースアドレスは不変 |

**The Return operation — semantics.** Return (Global sub-op 003) restores the holding register's saved values:

**Return 演算 — 意味論。** Return(Global サブop 003)は保持レジスタの保存値を復元する:

- State Number → saved value (i.e., the address at which the auto-save happened) + 1 (so the next state to execute is *after* the auto-save state)
- Loop counters → saved values
- Base address → saved value

- ステートナンバー → 保存値(つまり、自動退避が起こったアドレス) + 1 (実行する次のステートは自動退避ステートの*後*)
- ループカウンタ → 保存値
- ベースアドレス → 保存値

The "+1 on State Number restore" is the **return-to-after** convention: a sub-sequence called by Branch-taken or Sub-sequence Call returns to the state *immediately following* the auto-save state, not to the auto-save state itself. This matches the standard CPU "return after call" idiom.

「ステートナンバー復元時の +1」は**復帰先**慣習である: Branch-taken または Sub-sequence Call によって呼ばれたサブシーケンスは、自動退避ステート自身ではなく、自動退避ステートの*直後*のステートに復帰する。これは標準的な CPU 「コール後復帰」イディオムと一致する。

**Special case: Return after Insertion.** When Insertion was the auto-save trigger (rather than Branch-taken or Sub-sequence Call), the saved State Number is the address the Core *would have executed next* had Insertion not occurred. Return after Insertion should therefore restore to exactly that address (not address + 1, since the insertion-saved address is already the "next to execute"). This is recorded as fact C3-F12; the asymmetry with Branch-taken-style returns is intentional and reflects the semantic difference between "interrupt" and "call."

**特殊ケース: Insertion 後の Return。** Insertion が自動退避トリガであった時(Branch-taken または Sub-sequence Call ではなく)、保存されたステートナンバーは Insertion が起こらなければコアが*実行したであろう*アドレスである。したがって Insertion 後の Return は、まさにそのアドレスに復元すべきである(アドレス + 1 ではなく、なぜなら挿入で保存されたアドレスは既に「次に実行する」だからである)。これは事実 C3-F12 として記録される；Branch-taken 風復帰との非対称性は意図的であり、「割り込み」と「コール」の間の意味論的違いを反映する。

**The +1 vs +0 distinction — a possible Tie.** Whether the Core can distinguish "Insertion auto-save" from "Branch/Call auto-save" at Return time (in order to apply +1 vs +0 correctly) requires the holding register to carry an extra "saved by interrupt" flag bit. This adds one bit to the holding-register data layout. Alternative: always restore to saved-value + 1, and Formations that use Insertion design around the +1 offset by ensuring the Insertion source generates the desired address minus 1. This is recorded as Tie C3-T7. The contributor leans toward the flag-bit approach (more semantically clean), but the offset-by-1-from-source approach has merit (simpler Core).

**+1 対 +0 の区別 — 可能な Tie。** コアが Return 時に「Insertion 自動退避」を「Branch/Call 自動退避」から区別できるかどうか(+1 対 +0 を正しく適用するため)は、保持レジスタに余分な「割り込みによる保存」フラグビットを運ぶことを要求する。これは保持レジスタデータレイアウトに 1 ビットを加える。代替案: 常に保存値 + 1 に復元し、Insertion を使うフォーメーションは Insertion 源が望ましいアドレス - 1 を生成することを保証して +1 オフセットを設計回避する。これは Tie C3-T7 として記録される。貢献者はフラグビット手法に傾く(意味論的により明確)が、ソースで -1 する手法もメリットを持つ(より単純なコア)。

---

## 3.10 Insertion (External Interrupt) / 挿入(外部割り込み)

**Definition.** Insertion is a mechanism by which external logic can asynchronously override the Core's State Number register and certain other control registers, causing the Core to jump to an externally-specified address. The auto-save behavior described in § 3.9 occurs immediately before the override, so the inserted-into context can be resumed via Return.

**定義。** 挿入は、外部ロジックが非同期的にコアのステートナンバーレジスタと特定の他の制御レジスタを上書きでき、コアを外部指定のアドレスにジャンプさせる機構である。§ 3.9 で説明された自動退避挙動は上書きの直前に起こる、したがって挿入されたコンテキストは Return 経由で再開され得る。

**The insertion bus protocol — overview** (pin-level details in Chapter 5):

**挿入バスプロトコル — 概要**(ピンレベル詳細は第5章):

| Bus signal | Width | Direction | Purpose |
|---|---|---|---|
| `insert_req` | 1 bit | External → Core | Request to insert at the next safe moment / 次の安全な瞬間に挿入する要求 |
| `insert_target` | 12 bits | External → Core | The State Number to insert to / 挿入する先のステートナンバー |
| `insert_ack` | 1 bit | Core → External | Insertion has occurred / 挿入が起こった |

**The "next safe moment" — semantics.** Insertion is honored at a clock instant when the Core's state is consistent and can be cleanly auto-saved. The Core defines "safe" as **between instructions** (after one instruction's effects are applied, before the next instruction begins). Crucially, **the safe moment does not violate an ongoing Stay**: if Insertion is requested during a Stay window, the Core must determine when within the window to honor it.

**「次の安全な瞬間」 — 意味論。** 挿入はコアの状態が一貫していて綺麗に自動退避され得るクロック瞬間で受理される。コアは「安全」を**命令間**(一つの命令の効果が適用された後、次の命令が始まる前)と定義する。決定的に、**安全な瞬間は進行中の Stay を違反しない**: Insertion が Stayウィンドウ中に要求される場合、コアはそれをいつ受理するかをウィンドウ内のどこで決定しなければならない。

**Insertion timing during a Stay window — a Tie.** The question of when within a Stay window an Insertion is honored has three plausible answers, recorded as Tie C3-T8:

**Stayウィンドウ中の挿入タイミング — Tie。** Stayウィンドウ内のいつ Insertion が受理されるかという問いは三つのもっともらしい答えを持ち、Tie C3-T8 として記録される:

- **(A) Honor immediately:** Insertion overrides the State Number as soon as `insert_req` is asserted. The Stay is interrupted; the current Stay window is abandoned; any external operations in progress may be lost. Auto-save captures the Stay opcode's state.
- **(B) Honor at Stay-timeup:** Insertion is deferred until the Stay completes naturally. Auto-save then happens, then the inserted address takes effect. The Stay window is preserved.
- **(C) Honor at Stay-timeup unless special "urgent" Insertion variant requested:** Two Insertion request types — normal (deferred) and urgent (immediate). The protocol uses an additional bit to distinguish.

The contributor's current intent is **(B)** — deferred to Stay-timeup — for reasons of timing-signal stability and external-operation safety. However, applications requiring true real-time interrupt response (e.g., safety-critical fault handling) may need (A) or (C). Formation authors with such applications are invited to discuss.

貢献者の現在の意図は **(B)** —— Stay-timeup まで繰り延べ —— であり、タイミング信号の安定性と外部演算の安全性のためである。しかし、真のリアルタイム割り込み応答を要求する応用(例: 安全に重要なフォルト処理)は (A) または (C) を必要とするかもしれない。そのような応用を持つフォーメーション作者は議論に招かれる。

**Why Insertion exists despite Branch having "wait for Condition" semantics.** A natural objection: doesn't Branch (operand 0) already provide "wait until external signal" behavior? Why also have Insertion?

**Branch が「Conditionを待つ」意味論を持つにもかかわらず Insertion が存在する理由。** 自然な反論: Branch(オペランド 0)は既に「外部信号を待つ」挙動を提供するのではないか? なぜ Insertion もあるのか?

The two mechanisms serve different needs:
- **Branch (operand 0):** the *program* explicitly waits at a designated state. The instruction-list author has anticipated where the wait should happen. The Core stops at a known address.
- **Insertion:** the *program* is *not* waiting; the Core is executing some other sequence; an external event preempts the current execution and forces a jump. The instruction-list author has anticipated only that *something might* interrupt, not *where*.

二つの機構は異なる必要に奉仕する:
- **Branch(オペランド 0):** *プログラム*は指定されたステートで明示的に待機する。命令リスト作者は待機がどこで起こるべきかを予期している。コアは既知のアドレスで停止する。
- **Insertion:** *プログラム*は待機して*いない*；コアは他のシーケンスを実行している；外部イベントが現在の実行を先取りしてジャンプを強制する。命令リスト作者は*何かが*割り込み得ることのみを予期しており、*どこ*かは予期していない。

The two mechanisms are complementary. Most Formations will use both: Branch (operand 0) for protocol-level "wait for ready" patterns; Insertion for fault handling, real-time events, and other preemptive needs.

二つの機構は補完的である。ほとんどのフォーメーションは両方を使う: プロトコルレベル「準備完了を待つ」パターンのための Branch(オペランド 0)；フォルト処理、リアルタイムイベント、その他の先取的な必要のための Insertion。

---

## 3.11 Loop Counter Resource Set / ループカウンタリソースセット

**Purpose.** The Loop sub-opcode (internal sub-op 005) decrements a counter and jumps to the base address if the counter is non-zero. This requires the Core to maintain a small set of loop counters: their **number**, **width**, **selection mechanism**, **initialization**, and **externalization** are specified here.

**目的。** Loop サブオペコード(内部サブop 005)はカウンタをデクリメントし、カウンタが非ゼロならベースアドレスにジャンプする。これはコアがループカウンタの小さなセットを維持することを要求する: その**数**、**幅**、**選択機構**、**初期化**、**外部化**はここで指定される。

**Loop counter resource — current model.**

**ループカウンタリソース — 現在のモデル。**

| Property | Value | Status |
|---|---|---|
| Number of loop counters | Implementation-tunable (typical: 1 to 4) | **Convention** (C3-V1) |
| Width of each loop counter | 12 bits (matching the operand width) | **Convention** (C3-V2) |
| Counter selection mechanism | Sub-operand of Loop (D8–D15 of the Global instruction): low bits select which counter, high bits reserved for future / Loop のサブオペランド(Global 命令の D8-D15): 下位ビットがどのカウンタを選択、上位ビットは将来用に予約 | **Convention** (C3-V3) |
| Counter initialization | Set explicitly by an external register write (sub-op 1) before the loop begins; alternatively by an indirect mechanism (Chapter 4) | **Fixed** (C3-F13) |
| External observability | All loop counters are externally exposed as outputs for use by pipeline vector arithmetic / すべてのループカウンタはパイプラインベクタ算術での使用のために出力として外部に露出される | **Fixed** (C3-F14) |

**External observability — why this matters.** The original PTSG specification anticipated: *"if multi-loop counters and stay counters are externalized for use as RAM addresses or coefficients, pipeline vector arithmetic units can also be easily built."* The PTSG-Core's loop counters are therefore not merely internal control state — they are **first-class observable outputs** intended to be used by external logic.

**外部観察可能性 — なぜこれが重要か。** オリジナル PTSG 仕様は予期した: *「マルチループカウンタとステイカウンタを RAM アドレスや係数として使用するために外部化すれば、パイプラインベクタ算術ユニットも簡単に構築できる」*。PTSGコアのループカウンタはしたがって単なる内部制御状態ではない——それらは**第一級の観察可能な出力**であり、外部ロジックによって使用されることを意図されている。

**Future Formations leveraging loop-counter observability.** Anticipated applications:

**ループカウンタ観察可能性を活用する将来のフォーメーション。** 予期される応用:

- **WPMS:** the Lower PTSG's loop counter directly serves as the differential-engine k-index (Chapter 1 § 1.10 and the Emancipation trace).
- **SDRAM access:** loop counters drive row/column addressing for burst transactions.
- **Pipeline vector arithmetic:** loop counters index coefficient ROMs and data RAMs.
- **DMA-style transfers:** loop counters double as byte/word offsets into source/destination buffers.

- **WPMS:** Lower PTSG のループカウンタは差分エンジンの k インデックスとして直接奉仕する(第1章 § 1.10 と Emancipation トレース)。
- **SDRAM アクセス:** ループカウンタはバーストトランザクションの行／列アドレッシングを駆動する。
- **パイプラインベクタ算術:** ループカウンタは係数 ROM とデータ RAM を索引付ける。
- **DMA 風転送:** ループカウンタはソース／宛先バッファへのバイト／ワードオフセットを兼ねる。

**Loop counter at zero — Tie.** When a Loop sub-opcode is executed with the selected counter already at zero, what happens? Three reasonable interpretations, recorded as Tie C3-T9:

**ゼロのループカウンタ — Tie。** Loop サブオペコードが、選択されたカウンタが既にゼロの状態で実行される時、何が起こるか? 三つの合理的な解釈、Tie C3-T9 として記録される:

- **(A) Skip the loop body** — counter stays at 0; do not jump to base; advance to next state. Matches the "for (i=0; i<count; i++)" semantic with count = 0.
- **(B) Execute once then exit** — decrement (wraps to 0xFFF = 4095); jump to base; on the next encounter, counter is 0 again; behavior recurses. Effectively an infinite loop — probably not intended.
- **(C) Treat as "max iterations"** — when counter is encountered at 0, interpret as 4096 iterations (literal-zero-as-escape). This is consistent with Chapter 2's literal-zero-as-escape convention for Stay's operand.

The contributor leans toward (A) for safety (no accidental infinite loops), but the literal-zero-as-escape consistency argument for (C) has merit. Community discussion invited.

---

## 3.12 What is NOT in this Chapter / 本章に含まれないもの

To make the boundary unambiguous:

境界を曖昧でなくするために:

- **Indirect addressing (literal-zero-as-escape) full systematization.** Chapter 2 mentioned indirect-mode Jump (operand 0); this chapter mentions indirect counter initialization (§ 3.11). The full systematization of literal-zero-as-escape — which external register provides the indirect target, what bus protocol the indirect read uses, when the read occurs relative to the instruction — is in **Chapter 4**. / **間接アドレッシング(直値ゼロエスケープ)の完全な体系化。** 第2章は間接モード Jump(オペランド 0)に言及した；本章は間接カウンタ初期化に言及する(§ 3.11)。直値ゼロエスケープの完全な体系化——どの外部レジスタが間接ターゲットを提供するか、何のバスプロトコルが間接読みを使うか、命令に対していつ読みが起こるか——は**第4章**にある。

- **The prescaler mechanism.** Extending the Stay's effective wait range via prescaler is in **Chapter 4**. The Tie alternatives recorded in Chapter 1 § 1.12 (compile-time fixed, runtime-configurable, per-stay-selectable, multiple-parallel) will be resolved or recorded as Implementation Arena there. / **プリスケーラ機構。** プリスケーラ経由のStayの有効待機範囲拡張は**第4章**にある。第1章 § 1.12 に記録された Tie 代替案(コンパイル時固定、実行時設定可能、ステイ毎選択可能、複数並列)はそこで解決されるか、Implementation Arena として記録される。

- **External signal-level contracts.** The pin-level bus protocols sketched in §§ 3.5, 3.8, 3.10 (external operation bus, external stack bus, insertion bus) are specified in **Chapter 5**. Pin counts, exact widths, handshake timing diagrams, and physical-level concerns are all Chapter 5 material. / **外部信号レベル契約。** §§ 3.5、3.8、3.10 でスケッチされたピンレベルバスプロトコル(外部演算バス、外部スタックバス、挿入バス)は**第5章**で指定される。ピン数、正確な幅、ハンドシェイクタイミング図、物理レベルの懸念はすべて第5章の素材である。

- **Specific Formation external sub-opcode assignments.** The Core specifies that sub-opcodes 1–15 exist and pass through the external bus; the *meanings* are Formation-specific. The first Formation under design (`PTSG_WPMS_Formation_OpenPrompt`) will publish its sub-opcode assignments in its own Layer 1. / **特定のフォーメーション外部サブオペコード割り当て。** コアはサブオペコード 1-15 が存在し外部バスを通過することを指定する；*意味*はフォーメーション固有である。設計中の最初のフォーメーション(`PTSG_WPMS_Formation_OpenPrompt`)は彼ら自身の第1層でサブオペコード割り当てを公開する。

- **Specific implementations.** Verilog/VHDL realizations of the Stay window, the holding register, the external buses, and the loop counters are Layer 3 (`03_Sample_Implementations/`) material. / **特定の実装。** Stayウィンドウ、保持レジスタ、外部バス、ループカウンタの Verilog/VHDL 実現は第3層(`03_Sample_Implementations/`)の素材である。

- **Multi-PTSG coordination.** When multiple PTSG cores coexist on the same FPGA, how do their Stay windows interact, can one PTSG's loop counter feed another PTSG's Condition, etc. — all deferred to future **Chapter 6** as multi-PTSG applications mature. / **複数 PTSG 協調。** 複数の PTSG コアが同じ FPGA 上に共存する時、彼らの Stayウィンドウはどう相互作用するか、一つの PTSG のループカウンタが別の PTSG の Condition を駆動できるか等 —— すべて複数 PTSG 応用が成熟するにつれて将来の**第6章**に繰り延べられる。

---

## 3.13 Open Questions Carried Forward to Subsequent Chapters / 後続章へ持ち越される未解決問題

| Question | Deferred to |
|---|---|
| Literal-zero-as-escape full systematization (Jump operand 0, Stay operand 0, loop counter operand 0) — which external register, what bus protocol, when read occurs / 直値ゼロエスケープの完全な体系化(Jump オペランド 0、Stay オペランド 0、ループカウンタオペランド 0)——どの外部レジスタ、何のバスプロトコル、いつ読みが起こるか | Chapter 4 / 第4章 |
| Prescaler placement and control (compile-time fixed / runtime-configurable / per-stay-selectable / multiple-parallel) — Tie deferred from Chapter 1 § 1.12 / プリスケーラの配置と制御(コンパイル時固定／実行時設定可能／ステイ毎選択可能／複数並列)——第1章 § 1.12 から繰り延べられた Tie | Chapter 4 / 第4章 |
| External operation bus signal-level contract (ext_op_valid, ext_op_subopcode, ext_op_sub_operand, ext_op_data, ext_op_ready) — exact widths, edge/level semantics, timing relationships / 外部演算バス信号レベル契約——正確な幅、エッジ／レベル意味論、タイミング関係 | Chapter 5 / 第5章 |
| External stack bus signal-level contract (stack_push_req, stack_pop_req, stack_data, stack_ack) / 外部スタックバス信号レベル契約 | Chapter 5 / 第5章 |
| Insertion bus signal-level contract (insert_req, insert_target, insert_ack) — including the timing relationship with Stay window honoring (Tie C3-T8) / 挿入バス信号レベル契約——Stayウィンドウ受理とのタイミング関係を含む(Tie C3-T8) | Chapter 5 / 第5章 |
| Loop counter externalization signal naming and width conventions / ループカウンタ外部化信号命名と幅慣習 | Chapter 5 / 第5章 |
| Promotion criteria for moving heavily-used external sub-opcodes to top-level opcodes (the 12 reserved D0–D3 slots) / 頻繁に使用される外部サブオペコードをトップレベルオペコードに昇格させるための基準(12 個の予約 D0-D3 スロット) | Future Layer 2 trace |
| Whether external sub-opcode 1 = "external register write" should be elevated from Convention (Chapter 2 C2-V4) to Fixed / 外部サブオペコード 1 = 「外部レジスタ書き込み」が Convention(第2章 C2-V4)から Fixed に格上げされるべきかどうか | Future Layer 2 trace + community input |
| Whether the holding-register "saved by insertion" flag bit (for the +1 vs +0 Return distinction, Tie C3-T7) should be specified at Core level or left to Formation | Community input → potential Chapter 3 revision |
| The exact data-width budget of the holding register, given the Tie C3-T7 flag-bit question and the loop-counter-count Convention C3-V1 / 保持レジスタの正確なデータ幅予算、Tie C3-T7 フラグビット問いとループカウンタ数 Convention C3-V1 を考慮して | Community input → potential Chapter 3 revision |

---

## 3.14 Summary of Chapter 3 Decisions / 第3章決定事項のまとめ

Following Chapter 2's classification scheme: **Fixed (F)** = architectural commitments; **Convention (V)** = current conventions that could in principle be reconsidered; **Tie (T)** = genuinely open for community input.

第2章の分類スキームに従う: **Fixed (F)** = アーキテクチャ的コミットメント；**Convention (V)** = 原則として再考可能な現在の慣習；**Tie (T)** = 真にコミュニティ入力に開かれている。

| ID | Decision | Status |
|---|---|---|
| **C3-F1** | The Stay window is defined as the period from Stay Set execution to Stay-timeup. Globals encountered within this window are background-executed; Globals encountered outside are foreground-executed / Stayウィンドウは Stay Set 実行から Stay-timeup までの期間として定義される。本ウィンドウ内に遭遇する Global は裏実行される；外で遭遇するものは前景実行される | **F** |
| **C3-F2** | Background execution has two distinct modes: internal-mode (D4-D7=0, backward-scheduled, completes at Stay-timeup) and external-mode (D4-D7=1-F, forward-scheduled, triggered immediately) / 裏実行は二つの別個のモードを持つ: 内部モード(D4-D7=0、後方スケジュール、Stay-timeup で完了)と外部モード(D4-D7=1-F、前方スケジュール、即座にトリガ) | **F** |
| **C3-T1** | Timing signal output during the Stay window Tie: (A) Stay state's D16-D31; (B) Stay Set state's D16-D31; (C) last non-background state's D16-D31. Contributor leans toward (A) / Stayウィンドウ中のタイミング信号出力 Tie: (A) Stay ステートの D16-D31；(B) Stay Set ステートの D16-D31；(C) 最後の非裏側ステートの D16-D31。貢献者は (A) に傾く | **T** |
| **C3-F3** | Internal-mode operations are backward-scheduled to complete at Stay-timeup; the operation start time is (Stay-timeup − latency) / 内部モード演算は Stay-timeup で完了するよう後方スケジュールされる；演算開始時刻は (Stay-timeup − レイテンシ) | **F** |
| **C3-T2** | Multiple internal-mode operations queued in one window — execution order Tie: (A) FIFO; (B) LIFO; (C) implementation-defined. Contributor leans toward (A) / 一ウィンドウ内にキューに入った複数の内部モード演算——実行順序 Tie: (A) FIFO；(B) LIFO；(C) 実装定義。貢献者は (A) に傾く | **T** |
| **C3-T3** | Stay Set encountered inside an already-open Stay window — behavior Tie: (A) no-op; (B) ends current window, starts new; (C) error. Contributor leans toward (A) / 既に開いているStayウィンドウ内で遭遇する Stay Set ——挙動 Tie: (A) no-op；(B) 現ウィンドウを終了、新規開始；(C) エラー。貢献者は (A) に傾く | **T** |
| **C3-F4** | External-mode operations are triggered immediately when their state is reached; they run concurrently with the Stay's waiting / 外部モード演算はそのステートに到達した時に即座にトリガされる；Stay の待機と並行して走る | **F** |
| **C3-F5** | External-mode bus interface exposes: ext_op_valid, ext_op_subopcode, ext_op_sub_operand, ext_op_data, ext_op_ready. Pin-level specifications in Chapter 5 / 外部モードバスインターフェースは ext_op_valid、ext_op_subopcode、ext_op_sub_operand、ext_op_data、ext_op_ready を露出する。ピンレベル仕様は第5章にある | **F** |
| **C3-T4** | Minimum-stay-count constraint violation behavior Tie: (A) Core proceeds, asserts error; (B) Core stalls until ext_op_ready; (C) implementation-defined. Contributor leans toward (A) / 最低ステイカウント制約違反挙動 Tie: (A) コアは進む、エラーをアサート；(B) コアは ext_op_ready まで停滞；(C) 実装定義。貢献者は (A) に傾く | **T** |
| **C3-F6** | The minimum-stay-count chaining rule: for external-mode Global at state N+i with latency L_i, the Stay operand M must satisfy M ≥ i + L_i for every i / 最低ステイカウント連鎖規則: ステート N+i における外部モード Global がレイテンシ L_i を持つ場合、Stay オペランド M はすべての i について M ≥ i + L_i を満たさなければならない | **F** (Gemini-derived corollary) |
| **C3-F7** | Formation-documentation obligation: Formation authors must document, in their Formation's Layer 1, the clock latency of every external operation their Formation supports / フォーメーション文書化義務: フォーメーション作者は、彼らのフォーメーションがサポートするすべての外部演算のクロックレイテンシを彼らのフォーメーションの第1層で文書化しなければならない | **F** (Gemini-derived; now normative for all Formations) |
| **C3-F8** | Multiple external-mode operations in one window run concurrently; the Core does not arbitrate. External logic is responsible for handling concurrency or serialization / 一ウィンドウ内の複数の外部モード演算は並行して走る；コアは調停しない。外部ロジックが並行性または直列化を処理する責任がある | **F** |
| **C3-F9** | External-mode Global executed outside any Stay window: Core asserts ext_op_valid for 1 clock and advances; no minimum-stay constraint applies / Stayウィンドウ外で実行される外部モード Global: コアは 1 クロック ext_op_valid をアサートし進む；最低ステイ制約は適用されない | **F** |
| **C3-F10** | Internal information-holding register is a single-entry register saving State Number, all loop counters, and base address as an atomic group / 内部情報保持レジスタは、ステートナンバー、すべてのループカウンタ、ベースアドレスを原子グループとして保存する単一エントリレジスタである | **F** |
| **C3-F11** | Auto-save triggers: Branch (taken), Sub-sequence Call, Base Set, Insertion. Restore: Return / 自動退避トリガ: Branch(取られる)、Sub-sequence Call、Base Set、Insertion。復元: Return | **F** |
| **C3-F12** | Return-to-after convention: Return restores State Number to saved-value + 1 for Branch/Call/Base-Set auto-save; restores to saved-value (no +1) for Insertion auto-save / 復帰先慣習: Return は Branch/Call/Base-Set 自動退避について保存値 + 1 にステートナンバーを復元する；Insertion 自動退避について保存値(+1 なし)に復元する | **F** |
| **C3-T5** | Behavior of Return when holding register has not been populated since last Return / restart: (A) undefined; (B) implementation-defined; (C) Core specifies a known-safe default (e.g., restore to State Number 0). Contributor leans toward (B) / 最後の Return／再開以降に保持レジスタが populate されていない時の Return 挙動: (A) 未定義；(B) 実装定義；(C) コアが既知安全デフォルト(例: ステートナンバー 0 への復元)を指定。貢献者は (B) に傾く | **T** |
| **C3-T6** | External stack memory push/pop trigger Tie: (A) implicit (Core auto-pushes when needed); (B) explicit sub-opcodes; (C) hybrid (implicit push, explicit pop). Contributor leans toward (A) / 外部スタックメモリプッシュ／ポップトリガ Tie: (A) 暗黙的(コアが必要な時に自動プッシュ)；(B) 明示的サブオペコード；(C) ハイブリッド(暗黙的プッシュ、明示的ポップ)。貢献者は (A) に傾く | **T** |
| **C3-T7** | Holding register "saved by insertion" flag bit (for Return +1 vs +0 distinction) Tie: (A) Core carries the flag bit; (B) source generates target-minus-1 to compensate. Contributor leans toward (A) / 保持レジスタ「挿入による保存」フラグビット(Return +1 対 +0 区別のため) Tie: (A) コアがフラグビットを運ぶ；(B) ソースが補償のためにターゲット - 1 を生成する。貢献者は (A) に傾く | **T** |
| **C3-T8** | Insertion timing during a Stay window Tie: (A) immediate; (B) deferred to Stay-timeup; (C) two variants (normal + urgent). Contributor leans toward (B) / Stayウィンドウ中の挿入タイミング Tie: (A) 即時；(B) Stay-timeup へ繰り延べ；(C) 二つの変種(通常 + 緊急)。貢献者は (B) に傾く | **T** |
| **C3-V1** | Number of loop counters: implementation-tunable, typical 1 to 4 / ループカウンタの数: 実装で調整可能、典型的に 1 から 4 | **V** |
| **C3-V2** | Width of each loop counter: 12 bits (matching operand width) / 各ループカウンタの幅: 12 ビット(オペランド幅と一致) | **V** |
| **C3-V3** | Loop counter selection by sub-operand low bits / サブオペランド下位ビットによるループカウンタ選択 | **V** |
| **C3-F13** | Loop counter initialization: via external register write (sub-op 1); alternatively via indirect mechanism (Chapter 4) / ループカウンタ初期化: 外部レジスタ書き込み(サブop 1)経由；代替案として間接機構経由(第4章) | **F** |
| **C3-F14** | Loop counters are externally exposed as outputs (for pipeline vector arithmetic etc.) / ループカウンタは外部に出力として露出される(パイプラインベクタ算術等のため) | **F** |
| **C3-T9** | Loop counter at zero behavior Tie: (A) skip (advance, no jump); (B) wrap and recurse (infinite loop); (C) treat as 4096 (literal-zero-as-escape). Contributor leans toward (A) / ループカウンタゼロ挙動 Tie: (A) スキップ(進む、ジャンプなし)；(B) ラップして再帰(無限ループ)；(C) 4096 として扱う(直値ゼロエスケープ)。貢献者は (A) に傾く | **T** |

**Decision count by status:**

**地位別決定数:**

- **Fixed (F):** 14 — architectural commitments
- **Convention (V):** 3 — could in principle be reconsidered
- **Tie (T):** 9 — community input actively invited

The high Tie count in this chapter (9, vs Chapter 2's 4) reflects the inherent complexity of dynamic mechanics: many timing details have multiple reasonable interpretations, and the community is the right body to weigh in.

本章の高い Tie 数(9、対 第2章の 4)は動的機構の固有の複雑性を反映する: 多くのタイミング詳細は複数の合理的解釈を持ち、コミュニティはそれを評価する正しい主体である。

---

## End of Chapter 3 / 第3章の末尾

> *Time on the stay axis; space on the state axis; effects, in the background; consciousness, at the timeup.*
> *時間はステイ軸に、空間はステート軸に、効果は裏側に、意識はタイムアップに。*

> *Internal-mode operations complete at Stay-timeup, scheduled backward. External-mode operations begin when triggered, scheduled forward. Both fit inside the same window; both honor the same constraint.*
> *内部モード演算は Stay-timeup で完了する、後方スケジュール。外部モード演算はトリガ時に始まる、前方スケジュール。両者は同じウィンドウ内に収まる；両者は同じ制約を尊重する。*

> *Where the dynamics have multiple legible readings — and they do, more often here than anywhere else in the Core — the readings are recorded, not chosen. The community is the place where they are weighed.*
> *動的機構が複数の判読可能な読解を持つ場所——そしてそれらは持つ、ここではコア内の他のどこよりも頻繁に——読解は選ばれず記録される。コミュニティはそれらが評価される場所である。*

This chapter is released into the public domain under CC0 1.0 Universal. Chapter 4 (Indirect Addressing and Prescaler) will resolve the literal-zero-as-escape escapes left unaddressed here (Jump operand 0, Stay operand 0, loop counter initialization indirect mode). Chapter 5 (External Logic Interface) will specify the pin-level bus protocols for the external operation bus, external stack bus, insertion bus, and loop counter externalization. Until those chapters arrive, the Ties recorded above (C3-T1 through C3-T9) remain open for community discussion.

本章は CC0 1.0 Universal のもとパブリックドメインに公開される。第4章(間接アドレッシングとプリスケーラ)はここで対処されていない直値ゼロエスケープ(Jump オペランド 0、Stay オペランド 0、ループカウンタ初期化間接モード)を解決する。第5章(外部ロジックインターフェース)は外部演算バス、外部スタックバス、挿入バス、ループカウンタ外部化のためのピンレベルバスプロトコルを指定する。それらの章が到来するまで、上に記録された Tie(C3-T1 から C3-T9 まで)はコミュニティ議論のために開かれたままである。

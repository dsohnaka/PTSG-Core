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

> ### Version Note — v1.1 (Bug-Fix + Deliberation-Outcome Revision) / バージョンノート — v1.1（バグ修正＋協議成果改訂）
>
> **This is the v1.1 revision of Chapter 3.** It incorporates the outcomes of the 2026-05-23 Gemini 3.5 Flash deliberation (Layer 2 trace `02_Reasoning_Traces/contributed/dsohnaka/specification_deliberation/2026-05-23_ptsg-loop-dynamics-deliberation-by-gemini.md`), as decided by the architect in consultation with the amanuensis. The changes are substantial and **consciously revise several v1.0 Fixed decisions** — this is acknowledged, not accidental.
>
> **Major v1.1 changes:**
> 1. **The scheduling model is revised (§ 3.3a, new).** v1.0 held that *internal mode = always backward-scheduled, external mode = always forward-scheduled* (C3-F2/F3/F4). v1.1 introduces the **Prog End** command: within a Stay window, scheduling is now determined by **position relative to Prog End** — internal-mode commands *before* Prog End execute immediately (forward); those *after* Prog End are queued (backward, firing at Stay-timeup). This resolves the v1.0 defect that a Loop could not iterate a background sequence, and eliminates the complex backward-scheduling hardware for multi-clock operations.
> 2. **The loop counter model is revised (§ 3.11).** Single primary counter (was 1–4); up-count from 0 (was decrement); auto-clear to 0 on exit; 1-clock match-flag outputs (loop_cnt_match, stay_cnt_match, prescaler_match). Tie C3-T9 (loop-counter-at-zero) is **dissolved** by the up-count transition.
> 3. **Insertion timing (Tie C3-T8) is resolved** as (B) deferred-to-Stay-timeup, for safety; the current WPMS Formation needs no advanced insertion.
> 4. **Five new Ties** (C3-T10 through C3-T14) are recorded, deferred to the prescaler chapter (§ 3.13, § 3.14).
>
> **これは第3章の v1.1 改訂である。** 2026-05-23 の Gemini 3.5 Flash 協議(Layer 2 軌跡)の成果を、アーキテクトが祐筆と協議して決定した形で組み込む。変更は実質的であり、**いくつかの v1.0 Fixed 決定を意識的に改訂する**——これは偶発ではなく自覚的である。
>
> **主要な v1.1 変更:**
> 1. **スケジューリングモデルの改訂(§ 3.3a、新設)。** v1.0 は*内部モード＝常に後方スケジュール、外部モード＝常に前方スケジュール*(C3-F2/F3/F4)としていた。v1.1 は **Prog End** コマンドを導入する: Stayウィンドウ内で、スケジューリングは今や **Prog End に対する位置**によって決定される——Prog End の*前*の内部モードコマンドは即時実行(前方)、*後*のものはキュー(後方、Stay-timeup で発火)。これは Loop が裏シーケンスを反復できなかった v1.0 欠陥を解決し、複数クロック演算の複雑な後方スケジューリングハードウェアを排除する。
> 2. **ループカウンタモデルの改訂(§ 3.11)。** 単一プライマリカウンタ(旧 1-4)；0 からのアップカウント(旧デクリメント)；脱出時 0 へ自動クリア；1クロックの一致フラグ出力(loop_cnt_match、stay_cnt_match、prescaler_match)。Tie C3-T9(ループカウンタゼロ)はアップカウント移行により**消滅**する。
> 3. **挿入タイミング(Tie C3-T8)を解決** —— 安全性のため (B) Stay-timeup 繰り延べ；現在の WPMS Formation は高度な挿入を必要としない。
> 4. **五つの新 Tie**(C3-T10〜C3-T14)が記録され、プリスケーラ章へ繰り延べられる(§ 3.13、§ 3.14)。

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

**3. The loop counter resource model.** The Loop sub-opcode (§ 2.8) up-counts a counter and, while it remains below its target, jumps to the base address (v1.1; was decrement in v1.0). The Core provides a single primary loop counter; its width, target source, exit behavior, match-flag output, and externalization for use by pipeline vector arithmetic (as anticipated in the original PTSG specification) are specified here.

**3. ループカウンタリソースモデル。** Loop サブオペコード(§ 2.8)はカウンタをアップカウントし、目標未満の間はベースアドレスにジャンプする(v1.1；v1.0 ではデクリメント)。コアは単一のプライマリ・ループカウンタを提供する；その幅、目標ソース、脱出挙動、一致フラグ出力、そしてパイプラインベクタ算術で使用するための外部化(オリジナルPTSG仕様で予期されているように)はここで指定される。

**This chapter contains the most timing-sensitive material in PTSG-Core Layer 1.** Some timing details have multiple reasonable interpretations; where this is the case, the alternatives are recorded as Ties in § 3.13 with community discussion explicitly invited. The contributor anticipates that **several Chapter 3 Tie items will be the subject of active discussion in the coming weeks**, both with current contributors and with Formation authors as the first Formations are designed.

**本章はPTSGコア第1層において最もタイミング感度の高い素材を含む。** 一部のタイミング詳細は複数の合理的解釈を持つ；そのような場合、代替案は § 3.13 にTieとして記録され、コミュニティ議論が明示的に招かれる。貢献者は**いくつかの第3章Tie項目が、現在の貢献者と、最初のフォーメーションが設計されるにつれてフォーメーション作者との両方で、来る週における活発な議論の主題になる**ことを予期する。

---

## 3.2 The Stay-Window Concept / Stayウィンドウ概念

**Definition.** The **Stay window** is the period during which the Core's stay counter is active: it **opens** when **Stay Set** (Global sub-op 002, Chapter 2 § 2.8) executes and **closes** at **Stay-timeup** (when the stay counter reaches the value specified by the following Stay opcode's operand). All Global instructions encountered during this window are subject to background execution semantics; all non-Global instructions are processed as defined in Chapter 2.

> **v1.1 refinement (C4-F10 — Stay Set = clear/sync-only), wording corrected 2026-07.** Stay Set *arms* the stay counter (resets it to 0 and opens the window) **and the counter begins counting immediately, on prescaler ticks (On-Tick)**: while the window is open, `stay_cnt` increments on every prescaler tick, through the background program, through Prog End, into the wait. The Stay instruction **never clears** the counter (RH003); it only supplies the target. Stay-timeup is therefore the **Nth prescaler tick after Stay Set** — a point on the free-running tick grid, **independent of the background-program's length in clocks**: that grid-anchoring, not a Prog-End origin, is what eliminates the jitter (C4-F10's purpose). The window-scoping rule (which Globals are background-executed) is unchanged: "encountered between Stay Set and Stay-timeup."
>
> *Correction note:* an earlier v1.1 text stated "counting begins at Prog End (or the Stay instruction)". That sentence was an amanuensis transcription error, contradicting the as-built RTL (RH003/004/005: no clear in OP_STAY; increment on `window_open && presc_tick`) and the silicon-verified idiom-D behavior. Corrected here; reasoning archived in Layer 2 trace `2026-07-06_ptsg-command-phase-table` (DP-2). / *訂正注:* 以前の v1.1 文は「カウントは Prog End（または Stay 命令）で開始」と述べたが、これは祐筆の転記誤りであり、as-built RTL（RH003/004/005: OP_STAY でクリアせず;`window_open && presc_tick` でインクリメント）および実機検証済みの流儀 D の挙動と矛盾していた。ここに訂正する;推論は Layer 2 トレースに保管。

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
| State N | **Window opener.** Stay Set executes; the stay counter is **armed (reset to 0) and starts counting on prescaler ticks** (C4-F10, corrected — On-Tick counting from Stay Set, through the window; the Stay instruction never clears it); timing signals enter "hold mode" (the value being held is specified below). / **ウィンドウ開設者。** Stay Set が実行される；ステイカウンタは**アーム（0 にリセット）され、プリスケーラティックでカウントを開始する**(C4-F10 訂正——Stay Set から窓を通して On-Tick カウント;Stay 命令は決してクリアしない)；タイミング信号が「保持モード」に入る。 |
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

In this pattern: the external register writes to Reg_A and Reg_B trigger at clocks 1 and 2 respectively (assuming Stay Set at clock 0), running concurrently with the wait. The Loop sub-opcode is queued and executes at Stay-timeup, exactly when the wait completes; its effect (increment loop counter, compare to target, jump to base address while below target, else exit and auto-clear) is applied as Core advances. (Under the v1.1 Prog End model, this is the *queued-band* behavior — see § 3.3a.)

このパターンにおいて: Reg_A と Reg_B への外部レジスタ書き込みはそれぞれクロック 1 と 2 でトリガされ、待機と並行して走る。Loop サブオペコードはキューに入り Stay-timeup で実行される、ちょうど待機が完了する時；その効果(ループカウンタをインクリメント、目標と比較、目標未満の間はベースアドレスにジャンプ、さもなくば脱出し自動クリア)はコアが進む時に適用される。(v1.1 の Prog End モデルの下では、これは*キュー帯域*の挙動である——§ 3.3a 参照。)

**Why the two modes have different timing scheduling.** The asymmetry is architecturally motivated, not arbitrary:

**なぜ二つのモードが異なるタイミングスケジューリングを持つか。** 非対称性はアーキテクチャ的に動機づけられており、恣意的ではない:

- **Internal-mode operations affect Core control state** (loop counters, base address, holding register, State Number register). Their effect must be applied at *exactly the moment* the Stay window ends, because the Core's next-state computation depends on these values being current at that moment. Backward scheduling guarantees this.
- **External-mode operations drive external logic.** Their results are typically consumed by external hardware *during* the Stay window (e.g., an external register's new value is used by external Condition logic at some point during the Stay). Forward scheduling — trigger immediately, complete before Stay-timeup — gives external logic the longest possible time to act on the new value.

- **内部モード演算はコア制御状態に影響する**(ループカウンタ、ベースアドレス、保持レジスタ、ステートナンバーレジスタ)。それらの効果は Stayウィンドウが終わる*まさにその瞬間*に適用されなければならない、なぜならコアの次ステート計算はその瞬間にこれらの値が最新であることに依存する。後方スケジューリングはこれを保証する。
- **外部モード演算は外部ロジックを駆動する。** それらの結果は典型的に Stayウィンドウ*中に*外部ハードウェアによって消費される(例: 外部レジスタの新しい値が外部 Condition ロジックによって Stay 中のどこかの時点で使用される)。前方スケジューリング——即座にトリガし、Stay-timeup までに完了——は外部ロジックに新しい値に作用する可能な限り最長の時間を与える。

**D16–D31 repurposing.** Per Chapter 2 § 2.9, the timing-signal field (D16–D31) of a background-executed Global is reinterpreted as sub-operand data, not driven to the timing-signal output bus. The output bus continues to present the Stay-window held value (see Tie C3-T1 above). This repurposing is essential for the canonical "external register write" pattern (sub-opcode 1: D8–D15 = address, D16–D31 = data).

**D16-D31 の再目的化。** 第2章 § 2.9 によれば、裏実行された Global のタイミング信号フィールド(D16-D31)はサブオペランドデータとして再解釈され、タイミング信号出力バスには駆動されない。出力バスは Stayウィンドウ保持値(上記 Tie C3-T1 参照)を提示し続ける。本再目的化は正典的な「外部レジスタ書き込み」パターン(サブオペコード 1: D8-D15 = アドレス、D16-D31 = データ)に必須である。

---

## 3.3a Prog End and the Revised Scheduling Model (v1.1) / Prog End と改訂されたスケジューリングモデル (v1.1)

> **This section revises the v1.0 model of §§ 3.3–3.5.** In v1.0, scheduling was determined by *mode* (internal = always backward-scheduled; external = always forward-scheduled). The v1.1 deliberation revealed that this model has a defect — a Loop placed in a Stay window can never iterate a background sequence, because internal-mode operations are deferred to Stay-timeup, by which point the window has closed. The fix is the **Prog End** command, which makes scheduling depend on *position*, not mode. Sections 3.4 and 3.5 below remain valid for the *queued* region (after Prog End); this section specifies what changes.
>
> **本節は §§ 3.3–3.5 の v1.0 モデルを改訂する。** v1.0 では、スケジューリングは*モード*によって決定された(内部＝常に後方スケジュール；外部＝常に前方スケジュール)。v1.1 協議は、このモデルが欠陥を持つことを明らかにした——Stayウィンドウに置かれた Loop は裏シーケンスを決して反復できない、なぜなら内部モード演算は Stay-timeup へ繰り延べられ、その時点でウィンドウは閉じているからである。修正は **Prog End** コマンドであり、スケジューリングをモードではなく*位置*に依存させる。以下の §§ 3.4 と 3.5 は*キュー*領域(Prog End の後)について有効なままである；本節は何が変わるかを指定する。

### The revised model / 改訂されたモデル

Within a Stay window (opened by Stay Set, § 3.2), the **Prog End** command (internal sub-opcode 6, tentative — Chapter 2 v1.1 § 2.8) divides the window into two bands with different scheduling:

Stayウィンドウ内(Stay Set で開かれる、§ 3.2)で、**Prog End** コマンド(内部サブオペコード 6、暫定 — 第2章 v1.1 § 2.8)はウィンドウを異なるスケジューリングを持つ二つの帯域に分割する:

```
  State N:    Global (Stay Set)          ← window opens; stay counter starts; timing held
                                          ┌─────────────────────────────────────────────┐
  State N+1:  Global (internal, e.g Loop) │  IMMEDIATE BAND (before Prog End)            │
  State N+2:  Global (internal or ext)    │  Internal-mode commands execute IMMEDIATELY   │
   ...                                     │  (forward-scheduled). A Loop here CAN iterate │
                                          │  a background sequence at full speed.         │
  State N+k:  Global (Prog End)           └── boundary: immediate band ends ──────────────┘
                                          ┌─────────────────────────────────────────────┐
  State N+k+1: Global (internal, e.g Loop)│  QUEUED BAND (after Prog End)                │
   ...                                     │  Internal-mode commands are QUEUED, firing at │
                                          │  Stay-timeup (backward-scheduled).            │
  State N+m:  Stay (operand = M)          └── window closes at stay counter = M ──────────┘
```

- **Immediate band (Stay Set → Prog End):** every internal-mode Global executes *immediately* when reached (forward-scheduled, 1 clock each), while the timing-signal output remains held. A Loop in this band iterates a fast background sequence — the v1.0 limitation is resolved. Sub-sequence Call and Return in this band are *immediate* variants (background subroutine call/return with the timing axis held).
- **Queued band (after Prog End):** every internal-mode Global is *queued* and fires at Stay-timeup (backward-scheduled). A Loop here is the "big-period" loop that determines the next major transition exactly at timeup. Sub-sequence Call and Return here are *queued* variants (the timeup transition to/from a major subroutine).

- **即時帯域(Stay Set → Prog End):** すべての内部モード Global は到達時に*即時*実行される(前方スケジュール、各1クロック)、タイミング信号出力は保持されたまま。この帯域の Loop は高速な裏シーケンスを反復する——v1.0 制限は解決される。この帯域の Sub-sequence Call と Return は*即時*変種(タイミング軸を保持したままの裏サブルーチンのコール／リターン)。
- **キュー帯域(Prog End の後):** すべての内部モード Global は*キュー*され Stay-timeup で発火する(後方スケジュール)。ここの Loop はタイムアップでちょうど次の主要遷移を決定する「大周期」ループである。ここの Sub-sequence Call と Return は*キュー*変種(主要サブルーチンへの／からのタイムアップ遷移)。

### Why this is better / なぜこれが優れているか

1. **Background looping works.** The v1.0 defect (a Loop in a Stay window cannot iterate) is resolved: a Loop in the immediate band iterates at full speed while the timing axis is held.
2. **Backward-scheduling complexity is eliminated.** v1.0's C3-F3 required multi-clock internal operations (e.g., a Return with external stack pop) to be *scheduled backward* so they complete exactly at Stay-timeup — complex hardware. Under v1.1, a queued operation simply *fires at* Stay-timeup and absorbs its own latency as post-timeup fetch wait. No backward scheduling is needed.
3. **Timing-chart ergonomics.** A queued Loop fires at timeup, so the Stay operand can be written as the *pure* timing-chart value M, without subtracting 1 for the Loop's own clock. This removes a subtraction-stress that is a known hallucination source for AI-generated instruction lists.

1. **裏ループが機能する。** v1.0 欠陥(Stayウィンドウの Loop が反復できない)は解決される: 即時帯域の Loop はタイミング軸が保持されたまま高速に反復する。
2. **後方スケジューリングの複雑性が排除される。** v1.0 の C3-F3 は複数クロック内部演算(例: 外部スタックポップを伴う Return)を Stay-timeup でちょうど完了するよう*後方スケジュール*することを要求した——複雑なハードウェア。v1.1 では、キュー演算は単に Stay-timeup で*発火*し、自身のレイテンシをタイムアップ後のフェッチ待ちとして吸収する。後方スケジューリングは不要。
3. **タイミングチャートの人間工学。** キュー Loop はタイムアップで発火するため、Stay オペランドは Loop 自身のクロック分の 1 を引かずに*純粋な*タイミングチャート値 M として書ける。これは AI 生成命令リストの既知の幻覚源である引き算ストレスを除去する。

### Edge cases (all decided) / エッジケース（すべて決定済み）

| Case | Resolution |
|---|---|
| **No Prog End in the window** | No look-ahead. Stay Set opens the window; the core proceeds as if a Prog End will come. If none does, the **Stay command itself** is reached and acts as the implicit equivalent of Prog End (the immediate band ends, the wait begins). / 先読みなし。Stay Set がウィンドウを開く；コアは Prog End が来る前提で進む。来なければ、**Stay コマンド自身**に到達し、Prog End の暗黙の等価物として振る舞う(即時帯域が終了し、待機が始まる)。 |
| **Prog End outside a window** | A "blank shot" — no effect. Prog End requires a background-program-window-open flag (set by Stay Set) to have any effect. It cannot open queue-reservation mode on its own. / 「空砲」——効力なし。Prog End は効力を持つために裏プログラムウィンドウOpenフラグ(Stay Set がセット)を必要とする。それ自身でキュー予約モードを開くことはできない。 |
| **Multiple Prog Ends** | The first closes the immediate band; the second and subsequent are blank shots (the window/immediate-band is already closed). / 最初が即時帯域を閉じる；2回目以降は空砲(ウィンドウ／即時帯域は既に閉じている)。 |
| **External mode (D4–D7 = 1–F) × Prog End** | **Formation-dependent.** A Formation that does *not* decode window-vs-queue-reservation runs external ops immediately regardless of position. A Formation that *does* decode it may, e.g., enable a *queued* external register write executed at Stay-timeup by prepared parallel hardware — providing a means of I/O into the foreground timing-chart world. This idea is deliberately retained; Prog End makes it cleanly realizable. / **Formation 次第。** 窓-対-キュー予約をデコード*しない* Formation は、位置に関わらず外部演算を即時実行する。デコード*する* Formation は、例えば、準備された並列ハードウェアによって Stay-timeup で実行される*キュー*外部レジスタ書き込みをイネーブルできる——前景タイミングチャート世界への I/O の手立てを提供する。このアイデアは意図的に温存される；Prog End はそれを綺麗に実現可能にする。 |

### Relationship to §§ 3.4 and 3.5 / §§ 3.4 と 3.5 との関係

Sections 3.4 (Internal-Mode Reserved Execution) and 3.5 (External-Mode Concurrent Execution) were written for the v1.0 model. Under v1.1, read them as follows: **§ 3.4's "backward-scheduled, completes at Stay-timeup" now describes the *queued band* only** (internal-mode commands after Prog End). Internal-mode commands in the *immediate band* (before Prog End) execute immediately, as §3.3a specifies. **§ 3.5's "triggered immediately, forward-scheduled" remains the default for external mode** regardless of band — except where a Formation chooses to decode queue-reservation (the edge case above). The minimum-stay-count constraint (§ 3.6) applies to both bands.

§ 3.4(内部モード予約実行)と § 3.5(外部モード並行実行)は v1.0 モデルのために書かれた。v1.1 では、次のように読む: **§ 3.4 の「後方スケジュール、Stay-timeup で完了」は今や*キュー帯域*のみを記述する**(Prog End の後の内部モードコマンド)。*即時帯域*(Prog End の前)の内部モードコマンドは、§3.3a が指定する通り即時実行される。**§ 3.5 の「即座にトリガ、前方スケジュール」は外部モードの既定のままである**、帯域に関わらず——Formation がキュー予約をデコードすることを選ぶ場合(上記エッジケース)を除いて。最低ステイカウント制約(§ 3.6)は両帯域に適用される。

This section **consciously revises C3-F2, C3-F3, and C3-F4** (see § 3.14). The revision is acknowledged as significant — in the architect's words, "cutting flesh to sever bone": accepting a revision of settled decisions in order to resolve a whole class of deeper difficulties.

本節は **C3-F2、C3-F3、C3-F4 を意識的に改訂する**(§ 3.14 参照)。改訂は重要なものとして自覚されている——アーキテクトの言葉で「肉を切らせて骨を断つ」: より深い難所の一族全体を解決するために、確定した決定の改訂を受け入れる。

---

## 3.4 Internal-Mode Reserved Execution (D4–D7 = 0) / 内部モード予約実行 (D4-D7 = 0)

> **v1.1 note:** This section now describes the **queued band** (internal-mode commands *after* Prog End). For the immediate band (before Prog End), see § 3.3a. / **v1.1 注:** 本節は今や**キュー帯域**(Prog End の*後*の内部モードコマンド)を記述する。即時帯域(Prog End の前)は § 3.3a 参照。

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

## 3.4a The Reset Command — Execution Bands and the No-Prescaler-Reset Principle (v1.1, PROVISIONAL / 仮確定) / Reset コマンド — 実行帯域と非プリスケーラ・リセット原則 (v1.1, 仮確定)

> **PROVISIONAL (仮確定).** This section records a forward-looking decision that still requires (a) RTL changes to the Reset command path and (b) confirmation against the master/slave external interface (Chapter 5 / Chapter 6). It is a committed direction, marked provisional to distinguish it from the silicon-confirmed results elsewhere in v1.1. Reasoning archived in Layer 2 trace `2026-06-23_ptsg-reset-command-bands`.
>
> **仮確定。** 本節は、(a) Reset コマンド経路の RTL 改変と (b) マスター／スレーブ外部インターフェース（第5章／第6章）との照合をなお要する前向きの判断を記録する。確定した方向性であり、v1.1 の他所のシリコン確認済み結果と区別するため仮確定と記す。推論は Layer 2 トレース `2026-06-23_ptsg-reset-command-bands` に保管。

The Reset command is internal-control sub-opcode 0 (Chapter 2 § 2.8, C2-V3): it forces State Number to 0 and resets the stay and loop counters. v1.1 makes two things explicit about it, both enabled by the now-settled free-running prescaler (C4-F9) and the state-0 NOP alignment convention (C4-V3).

Reset コマンドは内部制御サブオペコード 0（第2章 § 2.8、C2-V3）である: ステートナンバーを 0 に強制し、ステイカウンタとループカウンタをリセットする。v1.1 はそれについて二点を明示する。いずれも、決着したフリーランプリスケーラ（C4-F9）と state-0 NOP 整列慣習（C4-V3）が可能にしたものである。

### The no-prescaler-reset principle — C3-F21 (PROVISIONAL) / 非プリスケーラ・リセット原則 — C3-F21（仮確定）

**The Reset command does NOT reset the prescaler.** The prescaler is fully free-running (C4-F9); the Reset command resets the execution context (State Number, stay/loop counters) but leaves the prescaler counter untouched. The reason is **external synchronizability**: a slave PTSG follows an externally-supplied time-base and must have *no* influence over it. If a slave's instruction stream could reset the prescaler, it could break synchronization with its master. The prescaler is therefore a time-base, not a program-controlled timer. (A program needing a "clean phase from Reset" cannot obtain it from the Core; that is a Formation concern, C3-V4.)

**Reset コマンドはプリスケーラをリセットしない。** プリスケーラは完全に自由走行である（C4-F9）；Reset コマンドは実行文脈（ステートナンバー、ステイ／ループカウンタ）をリセットするが、プリスケーラカウンタには触れない。理由は**外部同期可能性**である: スレーブ PTSG は外部供給の時間基準に従い、それに*一切*影響できてはならない。スレーブの命令ストリームがプリスケーラをリセットできれば、マスターとの同期を壊し得る。ゆえにプリスケーラは時間基準であって、プログラム制御のタイマーではない。（「Reset からの綺麗な位相」を要するプログラムはコアからそれを得られない；それは Formation の領分、C3-V4。）

### Reset execution bands — C3-F22 (PROVISIONAL) / Reset 実行帯域 — C3-F22（仮確定）

Like any command, Reset's behavior is selected by the band it runs in (the general band model is C3-F2). Alignment is delegated to the following state-0-style NOP (C4-V3), so Reset itself need not be prescaled:

任意のコマンドと同様、Reset の挙動はそれが走る帯域で選ばれる（一般帯域モデルは C3-F2）。整列は後続の state-0 流 NOP（C4-V3）に委ねられるため、Reset 自身はプリスケールド化されなくてよい:

| Band / 帯域 | Reset behavior / Reset の挙動 |
|---|---|
| **Foreground (non-prescaled, immediate)** / 前景（ノンプリスケールド、即時） | The reset happens at once. The following state-0-style NOP performs the alignment. If Reset and that NOP share the same `timing_signals` value, the combined **Reset+NOP region equals exactly one prescale period**. This is the normal, lowest-latency band. / リセットは即座に起こる。後続の state-0 流 NOP が整列する。Reset とその NOP が同じ `timing_signals` 値を共有すれば、**Reset+NOP 区間はちょうど 1 プリスケール周期に等しい**。これが通常・最小レイテンシ帯域。 |
| **Background ("staff meal", indeterminate)** / 背景（「まかない」、不定） | The Reset+NOP region becomes indeterminate in length. Reserved for genuine **emergencies** where an immediate reset matters more than a defined region length. / Reset+NOP 区間は長さが不定になる。即時リセットが区間長の確定より重要な真の**緊急時**に留保。 |
| **Queued (effectively prescaled)** / Que（実質プリスケールド） | The Reset fires at Stay-timeup, landing on a prescale boundary. / Reset は Stay-timeup で発火し、プリスケール境界に乗る。 |

### Formation opt-in for a prescaler-resetting Reset — C3-V4 (PROVISIONAL) / プリスケーラをリセットする Reset の Formation opt-in — C3-V4（仮確定）

The Core forbids prescaler reset by principle (C3-F21). A **Formation MAY opt in** to a prescaler-resetting Reset where its application genuinely needs one — thereby also accepting the loss of external synchronizability that the deviation implies. A standalone (non-slave) PTSG that will never be externally synchronized loses nothing by resetting its own prescaler; a **slave configuration must structurally never** be able to. The opt-in belongs at the Formation boundary so each application makes the choice with full knowledge of its own synchronization role. This is the Core-Formation separation acting as a release valve: the Core stays synchronizable-by-default, the rare contrary need is met outward.

コアは原則としてプリスケーラ・リセットを禁じる（C3-F21）。**Formation は**、その応用が本当に必要とする場合、プリスケーラをリセットする Reset を**選択してよい**——その際、逸脱が含意する外部同期可能性の喪失も受け入れる。外部同期されない単独（非スレーブ）PTSG は自分のプリスケーラをリセットしても何も失わない；**スレーブ構成は構造的に決してそれをできてはならない**。opt-in は Formation 境界に属し、各応用は自身の同期役割を完全に把握した上で選択する。これは Core-Formation 分離が安全弁として働くものである: コアは既定で同期可能なまま、稀な反対の必要は外で満たされる。

---

## 3.4b Command × Execution-Phase Semantics — The Normative Table (v1.1, PROVISIONAL in part / 一部仮確定) / コマンド×実行フェーズ意味論 — 規範表

> **This table is normative.** Authored by the architect (2026-07) as the complete definition of how
> every command handles the stay counter, the timing signals, the prescaler tick, and the State
> Number in each execution phase — Foreground (FG), Background (BG, the immediate band between Stay
> Set and Prog End), Queued (Q, the reservation band between Prog End and the Stay). Cells marked
> **HALT** are runaway errors (§ 3.4c). Items requiring new RTL are PROVISIONAL (仮確定). Reasoning:
> Layer 2 traces `2026-07-06_ptsg-command-phase-table` and `2026-07-06_ptsg-stay-start-state-register`.
>
> **本表は規範である。** アーキテクトが起草（2026-07）した、全コマンドが各実行フェーズ——前景（FG）・背景
> （BG、Stay Set と Prog End の間の即時帯域）・Que（Q、Prog End と Stay の間の予約帯域）——で Stayカウンタ・
> タイミング信号・プリスケーラティック・State Number をどう扱うかの完全定義。**HALT** のセルは暴走エラー
> （§ 3.4c）。新規 RTL を要する項目は仮確定。推論は上記 Layer 2 トレース二本に保管。

**Reading keys / 読み方:** "when On-Tick" = the stay counter increments on prescaler ticks while the
window is open (C4-F10, corrected). Edge "Leading※" = the two sanctioned leading-edge exceptions of
the Trailing-Edge Doctrine (Ch1 § 1.4a). An in-window **Stay** is not a background command: it is the
FG Stay itself — the terminator of the window content (BG) or of the queue region (Q), and the start
of the next stay period. / 「when On-Tick」= 窓が開いている間、ステイカウンタはプリスケーラティックで
インクリメント（C4-F10 訂正版）。縁「Leading※」= 後縁主義の公認された二つの前縁例外（第1章 § 1.4a）。窓内の
**Stay** は背景コマンドではない: それは FG の Stay そのもの——窓内容（BG）ないし Que 領域（Q）の終端子であり、
次のステイ期間の開始である。

| Command / コマンド | Phase | Stay Counter / Stayカウンタ | Timing Signals / タイミング信号 | Prescaler Tick / ティック | State Number / ステート番号 | Edge / 縁 | Legal | Notes / 備考 |
|---|---|---|---|---|---|---|---|---|
| **Stay** | FG | Continue counting (no reset) | Driven (changes per instruction) | Consumes one tick (waits for next) | Stay Counter満了&tickを待ってインクリメント | Trailing | Legal | Stay's wait scales with the prescaler (§4.8) — but the exact per-tick handling here is exactly what this table should nail down. |
|  | BG | N/A | N/A | N/A | N/A | Trailing | N/A | それはFGのStayであり、Stay Windowの強制的な終わりと、次のステイ期間の始まりを意味します。 |
|  | Q | N/A | N/A | N/A | N/A | Trailing | N/A | それはFGのStayであり、Que待機期間の終わりと次のステイ期間の始まりを意味します。 |
| **Branch** | FG | No effect (untouched すでにReset) | Driven (changes per instruction) | Consumes one tick (waits for next) | tickを待つ-><br>Condition trueの場合:インクリメント<br>Condition failの場合:opeland+現State Numberに更新される | Trailing | Legal |  |
|  | BG | Continue counting (no reset) <br>when On-Tick | Held (unchanged / frozen) | Ignored (runs at full system clock) | 次のクロックで-><br>Condition trueの場合:インクリメント<br>Condition failの場合:opeland+現State Numberに更新される | Trailing | Legal |  |
|  | Q | Continue counting (no reset) <br>when On-Tick | Held (unchanged / frozen) | Ignored (runs at full system clock) | 次のクロックで-><br>インクリメントされる（同時にoperandをque targetにセット） | Trailing | Legal | Queターゲットが実行されるときにConditionが評価され、相対State Numberが計算される |
| **Jump** | FG | No effect (untouched すでにReset) | Driven (changes per instruction) | Consumes one tick (waits for next) | tickを待ってopelandが示すアドレスに更新される | Trailing | Legal |  |
|  | BG | Continue counting (no reset) <br>when On-Tick | Held (unchanged / frozen) | Ignored (runs at full system clock) | 次のクロックでoperandが示すアドレスに更新される | Trailing | Legal |  |
|  | Q | Continue counting (no reset) <br>when On-Tick | Held (unchanged / frozen) | Ignored (runs at full system clock) | 次のクロックでインクリメントされる（同時にoperandをque targetにセット） | Trailing | Legal |  |
| **Global · Reset** | FG | No effect (untouched すでにReset) | Driven (changes per instruction) | Ignored (runs at full system clock) | 次のクロックで0にセット | Leading※ | Legal | Leading-edge exception (Trailing-Edge Doctrine, Ch1 §1.4a); depends on preceding command ending on a prescaler tick. Bands: §3.4a (PROVISIONAL). Never resets presc_cnt (C3-F21). |
|  | BG | Arm (reset to 0, don't start) | Driven (changes per instruction) | Ignored (runs at full system clock) | 次のクロックで0にセット | Trailing | Legal | "Staff meal" band — emergencies only (§3.4a, PROVISIONAL). Never resets presc_cnt (C3-F21). |
|  | Q | Arm (reset to 0, don't start) | Driven (changes per instruction) | Ignored (runs at full system clock) | 次のクロックでインクリメント<br>（Que実行時、0にセット） | Trailing | Legal | Effectively prescaled — fires at Stay-timeup (§3.4a, PROVISIONAL). Never resets presc_cnt (C3-F21). |
| **Global · Base Set** | FG | No effect (untouched) | Held (unchanged / frozen) | N/A | 保持（HALT） | Trailing | **HALT** | Error HALT（暴走検知） |
|  | BG | Continue counting (no reset) <br>when On-Tick | Held (unchanged / frozen) | Ignored (runs at full system clock) | 次のクロックでインクリメント<br>(同時にState NumberをBaseレジスタにセット） | Trailing | Legal | BGプログラムウィンドウ内でのBase Setが実行されたにもかかわらず対応するLoopコマンドを抜けないままProg Endに至った場合はエラーHALTする。 |
|  | Q | Continue counting (no reset) <br>when On-Tick | Held (unchanged / frozen) | Ignored (runs at full system clock) | 次のクロックでインクリメント<br>（同時に、Stay Start StateレジスタをBaseレジスタにセット） | Trailing | Legal | Stay Start Stateレジスタは、Stay SetコマンドがあったState Number。Que実行による表実行（時間処理）のループはこの起点に戻る必要がある。<br>対応するLoopコマンドがBGウィンドウ内にある場合はエラーHALTする。 |
| **Global · Stay Set** | FG | Arm (reset to 0, and start counting) | Driven (changes per instruction) | Ignored (runs at full system clock) | 次のクロックでインクリメント | Leading※ | Legal | C4-F10 (corrected): the counter starts here and counts On-Tick through the window; Stay never clears it. Leading-edge exception (Ch1 §1.4a).<br>【追加機能 → C3-F25、寿命2026-07訂正】Stay Setが行われたState Numberは、そのStay期間中、Stay Start Stateレジスタに保持される（同一サイクル内でQue Base Setに引き継がれるまで;対応するLoopまでではない——Base レジスタの役割と混同していたため訂正）。 |
|  | BG | Continue counting (with reset) | Held (unchanged / frozen) | Consumes one tick (waits for next) | tickを待ってインクリメント | Trailing | Legal |  |
|  | Q | Continue counting (no reset) <br>when On-Tick | Held (unchanged / frozen) | Ignored (runs at full system clock) | 次のクロックでインクリメント | Trailing | Legal |  |
| **Global · Return** | FG | No effect (untouched) | Held (unchanged / frozen) | N/A | 保持（HALT） | Trailing | **HALT** | Error HALT（暴走検知） |
|  | BG | Continue counting (no reset) <br>when On-Tick | Held (unchanged / frozen) | Ignored (runs at full system clock) | 次のクロックでReturn State Number | Trailing | Legal |  |
|  | Q | Continue counting (no reset) <br>when On-Tick | Held (unchanged / frozen) | Ignored (runs at full system clock) | 次のクロックでインクリメント<br>（Que実行時->Return State Number） | Trailing | Legal |  |
| **Global · Sub-sequence Call** | FG | No effect (untouched) | Held (unchanged / frozen) | N/A | 保持（HALT） | Trailing | **HALT** | <br>Error HALT（暴走検知） |
|  | BG | Continue counting (no reset) <br>when On-Tick | Held (unchanged / frozen) | Ignored (runs at full system clock) | 次のクロックでSub-sequence offset + 現State Number | Trailing | Legal | Operand field vs timing-signal field: does D16–D31 mean 'operand' or 'second timing signal' when this is background-executed? (General ambiguity noted in Ch3 for all Globals with extended operands.) |
|  | Q | Continue counting (no reset) <br>when On-Tick | Held (unchanged / frozen) | Ignored (runs at full system clock) | 次のクロックでインクリメント<br>（Que実行時->Sub-sequence offset + 現State Number） | Trailing | Legal |  |
| **Global · Loop** | FG | No effect (untouched) | Held (unchanged / frozen) | N/A | 保持（HALT） | Trailing | **HALT** | loop回数オペランドがD16:31を使用するためloop_cnt_match pulseはタイミング信号としては出せない。Que実行時にクロック幅では出せる。<br>Error HALT（暴走検知） |
|  | BG | Continue counting (no reset) <br>when On-Tick | Held (unchanged / frozen) | Ignored (runs at full system clock) | 次のクロックで-><br>ループ回数内：Baseレジスタをセット<br>ループ回数到来:：インクリメント | Trailing | Legal | BGプログラムウィンドウ内でのループ |
|  | Q | Continue counting (no reset) <br>when On-Tick | Held (unchanged / frozen) | Ignored (runs at full system clock) | 次のクロックでインクリメント<br>（Que実行時-><br>ループ回数内：Baseレジスタをセット<br>ループ回数到来:：インクリメント） | Trailing | Legal | FGタイミングシーケンスのループはQueを使用<br> |
| **Global · Prog End** | FG | No effect (untouched) | Held (unchanged / frozen) | N/A | 保持（HALT） | Trailing | **HALT** | HALT if encountered outside an open background-program window.（暴走検知） |
|  | BG | Continue counting (no reset) <br>when On-Tick | Held (unchanged / frozen) | Ignored (runs at full system clock) | 次のクロックでインクリメント | Trailing | Legal | This command IS the band divider: before it = BG, after it = Q (C3-F2). |
|  | Q | No effect (untouched) | Held (unchanged / frozen) | N/A | 保持（HALT） | Trailing | **HALT** | Can Prog End itself be queued (e.g. after another Prog End)? Worth an explicit ruling. And this causes a HALT（暴走検知） |
| **Global · NOP** | FG | No effect (untouched すでにReset) | Driven (changes per instruction) | Consumes one tick (waits for next) | tickを待ってインクリメント | Trailing | Legal | State-0 cold-start absorber (C4-V3) when used as the state-0 NOP. |
|  | BG | Continue counting (no reset) <br>when On-Tick | Held (unchanged / frozen) | Ignored (runs at full system clock) | 次のクロックでインクリメント | Trailing | Legal |  |
|  | Q | Continue counting (no reset) <br>when On-Tick | Held (unchanged / frozen) | Ignored (runs at full system clock) | 次のクロックでインクリメント | Trailing | Legal |  |

### The FG-Global exclusion principle — C3-F23 (PROVISIONAL / 仮確定) / FG-Global排除原則 — C3-F23

**Global commands do not execute in the foreground**, with exactly three justified exceptions:

**Global コマンドは前景実行しない**。正当化された例外はちょうど三つ:

| Exception / 例外 | Justification / 理由 |
|---|---|
| **Reset** | The strong will to return to the origin, even at the cost of operational continuity. / 動作連続性を無視してでも動作を起点に戻す強い意志。 |
| **Stay Set** | It controls the phase transition itself. / 動作フェーズの移行そのものを制御している。 |
| **NOP** | The immediate, cheap voiding of any command. / あらゆるコマンドの無効化の即時的な手軽さ。 |

Base Set, Return, Sub-sequence Call, Loop, and Prog End are **window-only** (BG/Q); encountering any
of them in the foreground is a runaway error (HALT, § 3.4c). **Consequence:** the foreground admits
only Stay (time), Branch/Jump (transition), and the three exceptions — a disciplined program's
foreground reads as a bare enumeration of Stay durations, the timing chart as text. This is the
time-axis/space-axis separation (Ch1 § 1.4) enforced as band legality. **Structural bonus:** every
extended-operand Global (Loop, Sub-sequence Call) now lives only in bands where the timing signals
are **Held**, so the D16–D31 field is always unambiguously the operand — the dual-use question is
dissolved by banding itself.

Base Set・Return・Sub-sequence Call・Loop・Prog End は**窓内専用**（BG/Q）であり、前景での遭遇は暴走エラー
（HALT、§ 3.4c）。**帰結:** 前景は Stay（時間）・Branch/Jump（遷移）・三例外のみを容れる——規律あるプログラムの
前景は Stay 持続時間の裸の羅列として読める、タイミングチャートがテキストとして。これは時間軸/空間軸分離
（第1章 § 1.4）の帯域合法性としての強制である。**構造的副産物:** 拡張オペランド Global（Loop・Sub-sequence
Call）はタイミング信号が **Held** の帯域にのみ住むため、D16–D31 は常に曖昧なくオペランドである——二重用途の
問いは帯域設計自体が解消した。

### Error HALT — runaway detection — C3-F24 (PROVISIONAL / 仮確定) / Error HALT — 暴走検知 — C3-F24

Rule violations **stop the machine where they happen**: the State Number holds at the violating
instruction (the scene is preserved) and an **error flag output** is raised. Halting cells: the
FG-illegal Globals above; a stray Prog End (outside an open window, or a second one in the Q band);
a queued State-Number overwrite (C3-F26); an unpaired Base Set↔Loop across bands (a BG Base Set
whose Loop is not exited by Prog End; a queued Base Set whose Loop lies in the BG window).

規則違反は**起こった場所で機械を止める**: State Number は違反命令で保持され（現場保存）、**エラーフラグ出力**
が立つ。HALT するセル: 上記の FG 違法 Global;迷子の Prog End（開いた窓の外、または Q 帯域の二発目）;Que の
State Number 上書き（C3-F26）;帯域を跨いで対にならない Base Set↔Loop（Loop を抜けないまま Prog End に至る
BG の Base Set;対応する Loop が BG 窓内にある Que の Base Set）。

- **Escape routes / 脱出経路:** hardware reset; **ISMCE real-time rewriting** over JTAG (NOP-out the
  offending word, patch a Jump) — a halted core is repaired live, without recompiling; insertion. /
  ハードウェアリセット;JTAG 越しの **ISMCE リアルタイム書き換え**（問題語の NOP 化・Jump パッチ）——停止した
  コアを再コンパイルなしに生きたまま修理;インサーション。
- **External visibility / 外部可視性:** the error flag port doubles as a SignalTap trigger (the
  capture shows the scene) and an insertion trigger (automated recovery/diagnosis). Pin definition:
  Chapter 5 (forthcoming). / エラーフラグポートは SignalTap トリガ（キャプチャが現場を示す）と
  インサーション・トリガ（自動回復／診断）を兼ねる。ピン定義は第5章（近刊）。
- **Placement / 所属:** the Base Set↔Loop band-crossing checks are **Core-mandatory** — they guard
  precisely where the most complicated failures arise. Excessive debuggability may be
  **parameterized later** (noted, not decided). / 帯域跨ぎ検査は **Core 必須**——最もややこしい失敗が
  生じる箇所をまさに守る。過剰なデバッガビリティは**後日パラメータ化**を検討（記録のみ、未決定）。

Rationale: an undetected structural violation lets unintended behavior chain, and the triggering
site recedes from the observation point; and giving every illegal combination a meaning proved
laborious to design and burdensome to learn. Refusing to give meaning is the simplification. The
former "blank shot = no effect" reading of a stray Prog End is superseded.

根拠: 未検出の構造違反は意図せぬ動作を連鎖させ、引き金の現場は観測点から遠ざかる;また全違法組合せへの意味付与は
設計に大変で学習に重いと判明した。意味を与えないことが単純化である。迷子 Prog End の旧解釈「空砲（効力なし）」は
置き換えられる。

### The Stay Start State register — C3-F25 (PROVISIONAL / 仮確定) / Stay Start Stateレジスタ — C3-F25

A new register giving the **time axis its own notion of "here"**: when foreground **Stay Set**
executes, its own State Number is written to **Stay Start State**. *(Corrected 2026-07 — see Layer 2
trace `2026-07-06_ptsg-stay-start-state-register`, DP-2: an earlier text described this register as
surviving many Stay periods until the matching Loop and stacked on nesting; that conflated it with the
Base register's own role.)* The corrected lifetime is a **same-cycle hand-off**: the value is valid
only within the Stay cycle in which Stay Set wrote it. If a **queued Base Set** executes in that same
cycle, the value is carried into the Base register and Stay Start State's job for that cycle is done;
if no Base Set occurs, the next Stay Set simply overwrites it. Carrying a target across many Stay
periods to a distant Loop remains the **Base register's own existing role**, including its stack
push/pop on nesting — unaffected by this register. Reset value 0. **No Core-level external
visibility**; a Formation may copy it to a general register to expose it.

時間軸に**固有の「ここ」**を与える新しいレジスタ: 前景の **Stay Set** が実行されると、自身の State
Number が **Stay Start State** に書き込まれる。*（2026-07 訂正——Layer 2 トレース
`2026-07-06_ptsg-stay-start-state-register` の DP-2 参照: 以前の文は本レジスタを対応する Loop まで多数の
Stay 期間を生き延び入れ子でスタックされると記していたが、それは Base レジスタ自身の役割との混同だった。）*
訂正後の寿命は**同一サイクル引き渡し**: 値は Stay Set が書いたのと同じ Stay サイクル内でのみ有効。その
サイクル内で **Que の Base Set** が実行されれば、値は Base レジスタへ運ばれ Stay Start State のそのサイクルの
仕事は済む;Base Set が実行されなければ次の Stay Set が単に上書きする。多数の Stay を跨いで遠い Loop へ標的を
運ぶのは**Base レジスタ既存の役割**（入れ子でのスタック push/pop を含む）のまま——本レジスタの影響を受けない。
リセット値 0。**Core レベルの外部可視性なし**;Formation は汎用レジスタへコピーして可視化できる。

**Queued Base Set semantics / Que の Base Set 意味論:** in the Q band, Base Set loads **Base := Stay
Start State** (the time-axis origin), so a queued Loop returns to the start of the stay period — the
repeatable structure — not to a scan position. (In the BG band, Base Set keeps the space-axis
semantics, Base := current State Number.)

Q 帯域では Base Set は **Base := Stay Start State**（時間軸の起点）をロードし、Que の Loop はスキャン位置で
なく、反復可能な構造たるステイ期間の開始点へ戻る。（BG 帯域の Base Set は空間軸意味論 Base := 現 State Number を
保つ。）

**The self-loop / 自己ループ (worked illustration):** a single stay period can loop on itself:

```
StaySet → ProgEnd → BaseSet(Q) → Loop-65536(Q) → Stay-4096
```

Stay's 12-bit operand × Loop's 16-bit operand = **2^28 clocks** (~268 M clocks ≈ 5.4 s at 50 MHz) of
continuous, exact timing **with no prescaler**, in five instructions. Because Loop's count operand
occupies D16–D31, `loop_cnt_match` cannot be a timing signal; at queued execution it can be emitted
at clock width.

Stay の 12bit × Loop の 16bit = **2^28 クロック**（約 2.68 億クロック ≈ 50 MHz で 5.4 秒）の連続精密タイミング、
**プリスケーラなしで**、命令五語。Loop の回数オペランドが D16–D31 を占めるため `loop_cnt_match` はタイミング
信号としては出せない;Que 実行時にクロック幅で出せる。

### Queue capacity — C3-F26 (PROVISIONAL / 仮確定) and Tie C3-T15 / Que容量 — C3-F26 と Tie C3-T15

The Q band holds a **single reservation register: last-write-wins** — a later reservation replaces an
earlier one. **Exception:** overwriting a queued **State-Number** reservation (Branch/Jump/Return/
Call/Loop targets) is a runaway error — **HALT + error flag** (a silently discarded jump detonates
far downstream, where the trigger is unfindable). Priority arbitration was considered and rejected:
it cannot rescue a violated program (it merely picks which violation), and it loads the Stay-timeup
path with logic — the very path the one-clock-registered tick keeps clean (Fmax).

Q 帯域は**単一の予約レジスタ: 後勝ち（last-write-wins）**——後の予約が先の予約を置き換える。**例外:** Que された
**State Number** 予約（Branch/Jump/Return/Call/Loop の標的）の上書きは暴走エラー——**HALT＋エラーフラグ**
（黙って破棄されたジャンプは、引き金の見つからない遠い下流で爆発する）。優先順位調停は検討の上棄却: 破られた
プログラムを救えず（どの違反にするかを選ぶだけ）、Stay-timeup 経路——1クロック叩きティックが清潔に保つまさに
その経路——にロジックを載せる（Fmax）。

**Tie C3-T15 (open) — nested multi-booking / 入れ子マルチブッキング:** two Base Sets and two Loops in
one window (`…BaseSet → BaseSet → Loop → Loop → Stay…`, nested self-loops of the 2^44 class): (A)
forbid — simple, matches the single register; (B) support — "PTSG-ishly, handling this beautifully is
a temptation" (the architect). Deferred pending cost measurement (a QUEUE_DEPTH parameter may
reconcile both).

一つの窓に Base Set 二つ・Loop 二つ（2^44 級の入れ子自己ループ）: (A) 禁止——単純、単一レジスタと整合;(B) 対応——
「PTSG的にはこれをうまく処理できるのは美しいという欲がある」（アーキテクト）。費用計測まで保留（QUEUE_DEPTH
パラメータが両立させ得る）。

**Formation forward link / Formation 前方リンク:** queue copy to general registers → timing signals
driven by computation results. / キューの汎用レジスタコピー → 演算結果に基づくタイミング信号。

---

## 3.5 External-Mode Concurrent Execution (D4–D7 = 1–F) / 外部モード並行実行 (D4-D7 = 1-F)

> **v1.1 note:** Immediate concurrent execution (below) remains the **default** for external mode, regardless of position relative to Prog End. A Formation *may* optionally decode window-vs-queue-reservation to defer a queued external op to Stay-timeup (§ 3.3a edge cases; decision C3-F4 refined). / **v1.1 注:** 即時並行実行(下記)は、Prog End に対する位置に関わらず外部モードの**既定**のままである。Formation は任意で、窓-対-キュー予約をデコードしてキュー外部演算を Stay-timeup へ繰り延べることができる(§ 3.3a エッジケース；決定 C3-F4 精緻化)。

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

## 3.11 Loop Counter Resource Set (v1.1) / ループカウンタリソースセット (v1.1)

**Purpose.** The Loop sub-opcode (internal sub-op 5) **up-counts the primary loop counter and compares it to a target** (v1.1; was decrement-and-test in v1.0). This requires the Core to maintain a loop counter whose **count, width, target source, exit behavior, match-flag output, and externalization** are specified here.

**目的。** Loop サブオペコード(内部サブop 5)は**プライマリ・ループカウンタをアップカウントし目標と比較する**(v1.1；v1.0 ではデクリメント＆テスト)。これはコアが、その**数、幅、目標ソース、脱出挙動、一致フラグ出力、外部化**がここで指定されるループカウンタを維持することを要求する。

**Loop counter resource — v1.1 model.**

**ループカウンタリソース — v1.1 モデル。**

| Property | Value | Status |
|---|---|---|
| Number of loop counters | **A single primary loop counter** (was 1–4 in v1.0). Nesting is handled by the external stack (§ 3.8); maximum nesting depth is a Formation concern. Parallel indices are provided by Formation-side external counters driven by the match flag (below). / **単一のプライマリ・ループカウンタ**(v1.0 では 1-4)。入れ子は外部スタック(§ 3.8)が扱う；最大入れ子深度は Formation の関心事。並列インデックスは一致フラグ(下記)で駆動される Formation 側外部カウンタが提供する。 | **F** (C3-F16, revises C3-V1) |
| Width of the loop counter | 12 bits (matching the operand and the D16–D31 target field's low 12 bits) | **V** (C3-V2, retained) |
| Count direction | **Up-count from 0** (was decrement in v1.0). On each Loop encounter, increment by 1, then compare to the target. / **0 からのアップカウント**(v1.0 ではデクリメント)。各 Loop 遭遇で 1 増やし、目標と比較する。 | **F** (C3-F17) |
| Target source | The 12-bit target value is read from the **D16–D31 extended operand** (Chapter 2 v1.1 § 2.7/2.8). Indirect target (literal-zero-as-escape) remains a Chapter 4 topic. / 12ビット目標値は **D16-D31 拡張オペランド**から読まれる。間接目標(直値ゼロエスケープ)は第4章の話題として残る。 | **F** (C3-F13, revised) |
| Exit behavior | When counter = target, the loop exits (advance to next state) and the counter **auto-clears to 0** — ready for the next loop with no explicit clear. / カウンタ = 目標の時、ループは脱出し(次のステートへ進む)、カウンタは **0 へ自動クリア**——明示的クリアなしで次のループに備える。 | **F** (C3-F17) |
| Match-flag output | On the exit clock (counter = target), a **1-clock `loop_cnt_match` pulse** is emitted externally. (Companion flags `stay_cnt_match` and `prescaler_match` are emitted by the stay and prescaler counters on their own target-match — see below.) / 脱出クロック(カウンタ = 目標)で、**1クロックの `loop_cnt_match` パルス**が外部に発される。(コンパニオンフラグ `stay_cnt_match` と `prescaler_match` はステイカウンタとプリスケーラカウンタが自身の目標一致で発する——下記参照。) | **F** (C3-F18) |
| External observability | The loop counter (and the match flags) are externally exposed as outputs for use by pipeline vector arithmetic and Formation-side external counters. / ループカウンタ(と一致フラグ)は、パイプラインベクタ算術と Formation 側外部カウンタでの使用のために出力として外部に露出される。 | **F** (C3-F14) |

**Why up-count.** v1.0 used decrement (count down to zero). The v1.1 deliberation identified that down-count causes an underflow glitch (0 → 0xFFF on decrement past zero), which is harmful when the counter value is used externally as a RAM address or index; it also complicates dynamic reload. Up-count from 0 eliminates the glitch (monotonic 0,1,2,…), makes the counter value directly usable as an array index, and matches the existing Stay counter (which already up-counts). The cost — needing a comparison against a target rather than a test-for-zero — is negligible and is what the D16–D31 target field provides.

**なぜアップカウントか。** v1.0 はデクリメント(0 まで数え下げる)を使った。v1.1 協議は、ダウンカウントがアンダーフローグリッチ(ゼロを過ぎてデクリメントで 0 → 0xFFF)を引き起こすことを識別した、これはカウンタ値が外部で RAM アドレスやインデックスとして使われる時に有害である；動的リロードも複雑化する。0 からのアップカウントはグリッチを排除し(単調 0,1,2,…)、カウンタ値を配列インデックスとして直接利用可能にし、既存のステイカウンタ(既にアップカウント)と一致する。コスト——ゼロテストではなく目標との比較を必要とすること——は無視でき、それは D16-D31 目標フィールドが提供する。

**The match flags and Formation-side parallel indices.** The single-counter design (vs v1.0's 1–4 counters) does not lose capability, because of the match flags. A Formation needing multiple simultaneous loop indices (e.g., a 2-D access pattern with an inner and an outer index) places an **external counter in the Formation** and increments it on each `loop_cnt_match` pulse. The Core's single counter provides the inner index; the Formation's counter provides the outer index. Thus: **single core counter + match flags + Formation external counters = the multiple-parallel-counter capability of v1.0**, with the resource cost pushed to the Formation that actually needs it — consistent with the PTSG externalization philosophy. (The external stack, § 3.8, separately handles temporal *nesting*; the match flags handle spatial *parallelism*. These are distinct and complementary.)

**一致フラグと Formation 側並列インデックス。** 単一カウンタ設計(v1.0 の 1-4 カウンタに対し)は能力を失わない、一致フラグのおかげで。複数の同時ループインデックスを必要とする Formation(例: 内側と外側のインデックスを持つ2次元アクセスパターン)は、**Formation に外部カウンタ**を置き、各 `loop_cnt_match` パルスでそれを増やす。コアの単一カウンタが内側インデックスを提供する；Formation のカウンタが外側インデックスを提供する。したがって: **単一コアカウンタ + 一致フラグ + Formation 外部カウンタ = v1.0 の複数並列カウンタ能力**、リソースコストは実際にそれを必要とする Formation へ押し出される——PTSG 外部化哲学と整合的。(外部スタック § 3.8 は別途、時間的*入れ子*を扱う；一致フラグは空間的*並列性*を扱う。これらは別個かつ補完的である。)

**External observability — why this matters.** The original PTSG specification anticipated: *"if multi-loop counters and stay counters are externalized for use as RAM addresses or coefficients, pipeline vector arithmetic units can also be easily built."* Under v1.1, the *single* core counter plus Formation-side counters realize this same intent. The counter and the match flags are **first-class observable outputs** intended for external logic.

**外部観察可能性 — なぜこれが重要か。** オリジナル PTSG 仕様は予期した: *「マルチループカウンタとステイカウンタを RAM アドレスや係数として使用するために外部化すれば、パイプラインベクタ算術ユニットも簡単に構築できる」*。v1.1 では、*単一の*コアカウンタと Formation 側カウンタがこの同じ意図を実現する。カウンタと一致フラグは、外部ロジックを意図した**第一級の観察可能な出力**である。

**Future Formations leveraging counter observability and match flags.** Anticipated applications:

**カウンタ観察可能性と一致フラグを活用する将来のフォーメーション。** 予期される応用:

- **WPMS:** the Lower PTSG's loop counter directly serves as the differential-engine k-index (Chapter 1 § 1.10 and the Emancipation trace); the match flag triggers the k-index advance.
- **SDRAM access:** the counter drives row/column addressing; the match flag triggers row/bank transitions.
- **Pipeline vector arithmetic:** the counter indexes coefficient ROMs; the match flag strobes the result latch.
- **DMA-style transfers:** the counter is the buffer offset; the match flag signals transfer completion.

- **WPMS:** Lower PTSG のループカウンタは差分エンジンの k インデックスとして直接奉仕する(第1章 § 1.10 と Emancipation トレース)；一致フラグが k インデックスの前進をトリガする。
- **SDRAM アクセス:** カウンタが行／列アドレッシングを駆動する；一致フラグが行／バンク遷移をトリガする。
- **パイプラインベクタ算術:** カウンタが係数 ROM を索引付ける；一致フラグが結果ラッチをストローブする。
- **DMA 風転送:** カウンタはバッファオフセット；一致フラグが転送完了を信号する。

**Loop counter at zero — former Tie C3-T9, now dissolved.** Under v1.0's decrement model, "what happens when the counter is already zero?" was a genuine Tie (skip / wrap-and-recurse / treat-as-4096). **The v1.1 up-count transition dissolves this question entirely:** the counter *always starts at 0*, and zero is simply the loop's normal beginning. There is no degenerate "encountered at zero" case to disambiguate. The former Tie C3-T9 is therefore resolved (dissolved) by the up-count decision, not by choosing among its old alternatives.

**ゼロのループカウンタ — 旧 Tie C3-T9、今や消滅。** v1.0 のデクリメントモデルの下では、「カウンタが既にゼロの時何が起こるか?」は本物の Tie だった(スキップ／ラップ＆再帰／4096 扱い)。**v1.1 のアップカウント移行はこの問いを完全に消滅させる:** カウンタは*常に 0 から始まり*、ゼロは単にループの通常の始まりである。曖昧性除去すべき退化した「ゼロで遭遇」事例は存在しない。したがって旧 Tie C3-T9 は、古い代替案の中から選ぶことによってではなく、アップカウント決定によって解決(消滅)される。

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
| **C3-F2** | **(REVISED in v1.1)** Background-execution scheduling is determined by **position relative to Prog End** (§ 3.3a), not by mode. Internal-mode commands *before* Prog End execute immediately (forward); *after* Prog End they are queued (backward, at Stay-timeup). The v1.0 rule "internal = always backward, external = always forward" is superseded. / **(v1.1 で改訂)** 裏実行スケジューリングは、モードではなく **Prog End に対する位置**(§ 3.3a)によって決定される。Prog End の*前*の内部モードコマンドは即時実行(前方)；*後*ではキュー(後方、Stay-timeup で)。v1.0 規則「内部＝常に後方、外部＝常に前方」は置き換えられる。 | **F** (v1.1 revision) |
| **C3-T1** | Timing signal output during the Stay window Tie: (A) Stay state's D16-D31; (B) Stay Set state's D16-D31; (C) last non-background state's D16-D31. Contributor leans toward (A) / Stayウィンドウ中のタイミング信号出力 Tie: (A) Stay ステートの D16-D31；(B) Stay Set ステートの D16-D31；(C) 最後の非裏側ステートの D16-D31。貢献者は (A) に傾く | **T** |
| **C3-F3** | **(REVISED in v1.1)** Internal-mode commands *in the queued band* (after Prog End) fire at Stay-timeup and absorb their own latency as post-timeup fetch wait — no backward "complete-exactly-at-timeup" scheduling is required (the v1.0 backward-scheduling hardware is eliminated). Internal-mode commands in the immediate band execute immediately. / **(v1.1 で改訂)** *キュー帯域*(Prog End の後)の内部モードコマンドは Stay-timeup で発火し、自身のレイテンシをタイムアップ後フェッチ待ちとして吸収する——後方の「タイムアップでちょうど完了」スケジューリングは不要(v1.0 の後方スケジューリングハードウェアは排除される)。即時帯域の内部モードコマンドは即時実行される。 | **F** (v1.1 revision) |
| **C3-T2** | Multiple internal-mode operations queued in one window — execution order Tie: (A) FIFO; (B) LIFO; (C) implementation-defined. Contributor leans toward (A) / 一ウィンドウ内にキューに入った複数の内部モード演算——実行順序 Tie: (A) FIFO；(B) LIFO；(C) 実装定義。貢献者は (A) に傾く | **T** |
| **C3-T3** | Stay Set encountered inside an already-open Stay window — behavior Tie: (A) no-op; (B) ends current window, starts new; (C) error. Contributor leans toward (A) / 既に開いているStayウィンドウ内で遭遇する Stay Set ——挙動 Tie: (A) no-op；(B) 現ウィンドウを終了、新規開始；(C) エラー。貢献者は (A) に傾く | **T** |
| **C3-F4** | **(REFINED in v1.1)** External-mode operations are triggered immediately when reached, running concurrently with the Stay's waiting — the default, regardless of band. A Formation *may* additionally decode window-vs-queue-reservation to execute a queued external op at Stay-timeup via prepared parallel hardware (Formation-dependent; § 3.3a edge cases), enabling I/O into the foreground timing-chart world. / **(v1.1 で精緻化)** 外部モード演算は到達時に即座にトリガされ、Stay の待機と並行して走る——帯域に関わらず既定。Formation は*加えて*、窓-対-キュー予約をデコードし、準備された並列ハードウェアで Stay-timeup にキュー外部演算を実行できる(Formation 次第；§ 3.3a エッジケース)、前景タイミングチャート世界への I/O を可能にする。 | **F** (v1.1 refinement) |
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
| **C3-T8 → C3-F20** | **(RESOLVED in v1.1)** Insertion timing during a Stay window: resolved as **(B) deferred to Stay-timeup**. Rationale: the current WPMS Formation's paramount goal is early sound output and needs no advanced insertion; (B) is the safest option for this Core version. The (A)/(C) alternatives remain available for a future version if a Formation requires real-time preemption. / **(v1.1 で解決)** Stayウィンドウ中の挿入タイミング: **(B) Stay-timeup へ繰り延べ**として解決。根拠: 現在の WPMS Formation の至上目標は早期出音であり高度な挿入を必要としない；(B) はこのコア版で最も安全。(A)/(C) 代替案は、Formation がリアルタイム先取を要求する場合の将来版のために利用可能なまま。 | **F** (was Tie C3-T8) |
| **C3-V1 → C3-F16** | **(REVISED in v1.1)** Number of loop counters: **a single primary loop counter** (was 1–4). Nesting via external stack; parallel indices via Formation external counters driven by match flags. / **(v1.1 で改訂)** ループカウンタの数: **単一のプライマリ・ループカウンタ**(旧 1-4)。入れ子は外部スタック経由；並列インデックスは一致フラグで駆動される Formation 外部カウンタ経由。 | **F** (was Convention C3-V1) |
| **C3-V2** | Width of the loop counter: 12 bits (matching operand width and the D16–D31 target's low 12 bits) / ループカウンタの幅: 12 ビット(オペランド幅と D16-D31 目標の下位 12 ビットと一致) | **V** (retained) |
| **C3-V3** | **(SUPERSEDED in v1.1)** Loop counter selection by sub-operand low bits — no longer needed, as there is a single counter. The field formerly imagined for counter selection does not exist (see the 8-bit/12-bit bug fix, Chapter 2 v1.1). / **(v1.1 で廃止)** サブオペランド下位ビットによるループカウンタ選択——単一カウンタのため不要。かつてカウンタ選択用に想定されたフィールドは存在しない(8ビット/12ビットバグ修正、第2章 v1.1 参照)。 | superseded |
| **C3-F13** | **(REVISED in v1.1)** Loop counter target: the 12-bit target value is read from the D16–D31 extended operand; the counter up-counts from 0 to this target. Indirect target (literal-zero-as-escape) remains a Chapter 4 topic. / **(v1.1 で改訂)** ループカウンタ目標: 12ビット目標値は D16-D31 拡張オペランドから読まれる；カウンタは 0 からこの目標までアップカウントする。間接目標(直値ゼロエスケープ)は第4章の話題として残る。 | **F** (v1.1 revised) |
| **C3-F17** (v1.1) | Up-count: the loop counter counts up from 0; on reaching the target it exits and auto-clears to 0. Eliminates underflow glitch and the reload concept. / アップカウント: ループカウンタは 0 から数え上げる；目標到達で脱出し 0 へ自動クリアする。アンダーフローグリッチとリロード概念を排除。 | **F** (v1.1) |
| **C3-F18** (v1.1) | Match flags: loop_cnt_match / stay_cnt_match / prescaler_match are emitted externally as 1-clock pulses when each counter reaches its target. Enables Formation-side parallel indices, sample-and-hold, and zero-latency triggering. / 一致フラグ: loop_cnt_match / stay_cnt_match / prescaler_match は、各カウンタが目標到達時に 1クロックパルスとして外部に発される。Formation 側並列インデックス、サンプル＆ホールド、ゼロレイテンシトリガを可能にする。 | **F** (v1.1) |
| **C3-F19** (v1.1) | Prog End command (internal sub-opcode 6, tentative): declares the boundary between the immediate band and the queued band within a Stay window. Blank shot outside an open window; second-and-subsequent are blank shots. Cascades to Sub-sequence Call and Return (immediate / queued variants). See § 3.3a. / Prog End コマンド(内部サブオペコード 6、暫定): Stayウィンドウ内の即時帯域とキュー帯域の境界を宣言する。開いた窓の外では空砲；2回目以降は空砲。Sub-sequence Call と Return に波及(即時／キュー変種)。§ 3.3a 参照。 | **F** (v1.1) |
| **C3-F14** | Loop counters are externally exposed as outputs (for pipeline vector arithmetic etc.) / ループカウンタは外部に出力として露出される(パイプラインベクタ算術等のため) | **F** |
| **C3-T9** | **(DISSOLVED in v1.1)** Loop-counter-at-zero behavior — dissolved by the up-count transition (C3-F17). The counter always starts at 0; zero is simply the loop's normal beginning, so there is no degenerate at-zero case to disambiguate. / **(v1.1 で消滅)** ループカウンタゼロ挙動——アップカウント移行(C3-F17)により消滅。カウンタは常に 0 から始まる；ゼロは単にループの通常の始まりであり、曖昧性除去すべき退化したゼロ事例は存在しない。 | dissolved (was Tie) |
| **C3-F15** (v1.1) | D16–D31 extended-operand repurposing for internal-mode Globals needing a 12-bit parameter (Loop target, Sub-sequence Call offset). Flat extended operand, no Mode sub-field; the elaborate Mode scheme was declined (memo only). See Chapter 2 v1.1 § 2.7/§ 2.13 (C2-F11). / 12ビットパラメータを必要とする内部モード Global(Loop 目標、Sub-sequence Call オフセット)のための D16-D31 拡張オペランド再目的化。平坦な拡張オペランド、Mode サブフィールドなし；精巧な Mode スキームは不採用(メモのみ)。第2章 v1.1 § 2.7/§ 2.13 (C2-F11) 参照。 | **F** (v1.1 bug fix) |
| **C3-T10 → C4-F11** (v1.1) | **RESOLVED.** Prescale **edge** for queued execution = **trailing edge**, by the Trailing-Edge Doctrine (Chapter 1 § 1.4a): a queued operation fires at the trailing edge (count completion). The leading-edge-flag hybrid is superseded. Now **Fixed C4-F11** (Chapter 4 § 4.9). (Distinct from the *phase*-alignment question, resolved by C4-F9 — do not conflate.) / **解決。** キュー実行のプリスケール**縁** = **後縁**、後縁主義（第1章 § 1.4a）に従い: キュー演算は後縁（カウント完了）で発火。前縁フラグ・ハイブリッドは置き換えられる。今や **Fixed C4-F11**（第4章 § 4.9）。（*位相*整列の問いとは別個で、C4-F9 が解決——混同しないこと。） | **F** (now C4-F11) |
| **C3-T11 → C4-F10** (v1.1; wording corrected 2026-07) | **RESOLVED.** Stay Set is clear/sync-only: it arms the stay counter, **which counts prescaler ticks from Stay Set onward (On-Tick), through the window; the Stay instruction never clears it** (RH003/004/005). Stay-timeup = the Nth tick after Stay Set, on the free-running grid — independent of the background-program's clock-length (jitter-free). Silicon-confirmed via duty idiom D. Now **Fixed C4-F10** (Chapter 4 § 4.9). *(An earlier v1.1 text mis-stated "begins counting at Prog End"; corrected — see § 3.2.)* / **解決。** Stay Set はクリア／同期のみ: ステイカウンタをアームし、**カウンタは Stay Set 以降プリスケーラティックを数え（On-Tick）、窓を通して継続;Stay 命令は決してクリアしない**（RH003/004/005）。Stay-timeup = Stay Set 後の第 N tick、自由走行グリッド上——背景プログラムのクロック長から独立（ジッタ無縁）。流儀 D で実機確認済み。今や **Fixed C4-F10**。*（以前の v1.1 文は「Prog End で開始」と誤記;訂正済み——§ 3.2 参照。）* | **F** (now C4-F10) |
| **C3-T12** (v1.1, new) | Local Branch — a zero-time-axis conditional branch for use inside the immediate background band (the top-level Branch consumes a clock / self-loops, breaking the timing hold). Would occupy an internal sub-opcode slot. Deferred to Chapter 4. / Local Branch——即時裏帯域内で使うゼロ時間軸条件分岐(トップレベル Branch はクロックを消費／自己ループし、タイミング保持を破壊する)。内部サブオペコードスロットを占有する。第4章へ繰り延べ。 | **T** (deferred) |
| **C3-T13** (v1.1, new) | Queued NOP — whether a NOP placed after Prog End should function as a Timeup-tracking timing placeholder (sliding one prescaled unit / a specific pin phase in at the very end of the wait). Deferred to Chapter 4. / キュー NOP——Prog End の後に置かれた NOP が、Timeup 追尾型タイミングプレースホルダーとして機能すべきか(待機の最末尾にプリスケール1単位／特定ピンフェーズを滑り込ませる)。第4章へ繰り延べ。 | **T** (deferred) |
| **C3-T14** (v1.1, new) | Final internal-control sub-opcode 0–7 layout — including Prog End's permanent slot (tentatively 6), whether a Local Branch is added, and the fate of NOP (one proposal removes NOP to free a slot). Deferred to Chapter 4. / 最終的な内部制御サブオペコード 0-7 レイアウト——Prog End の恒久スロット(暫定 6)、Local Branch が追加されるか、NOP の運命(ある提案は NOP を除いてスロットを空ける)を含む。第4章へ繰り延べ。 | **T** (deferred) |
| **C3-F21** (v1.1, PROVISIONAL) | **No-prescaler-reset principle.** The program-issued Reset command does NOT reset the prescaler; the prescaler is fully free-running (C4-F9). Reason: a slave PTSG must have no influence over the externally-driven time-base. See § 3.4a. / **非プリスケーラ・リセット原則。** プログラム発行の Reset コマンドはプリスケーラをリセットしない；プリスケーラは完全フリーラン（C4-F9）。理由: スレーブ PTSG は外部駆動の時間基準に影響できてはならない。§ 3.4a 参照。 | **F** (仮確定) |
| **C3-F22** (v1.1, PROVISIONAL) | **Reset execution bands.** Reset is selectable across foreground (immediate, aligned by the following state-0 NOP; Reset+NOP sharing one timing_signals value = one prescale period), background ("staff meal", indeterminate, emergencies), and queued (effectively prescaled, fires at Stay-timeup). See § 3.4a. / **Reset 実行帯域。** Reset は前景（即時、後続 state-0 NOP で整列；Reset+NOP が一 timing_signals 値共有 = 1 プリスケール周期）、背景（「まかない」、不定、緊急）、Que（実質プリスケールド、Stay-timeup 発火）で選択可能。§ 3.4a 参照。 | **F** (仮確定) |
| **C3-V4** (v1.1, PROVISIONAL) | **Formation opt-in for prescaler-resetting Reset.** The Core forbids prescaler reset (C3-F21); a Formation MAY opt in where genuinely needed, accepting the loss of external synchronizability. A slave configuration must structurally never be able to reset the prescaler. See § 3.4a. / **プリスケーラをリセットする Reset の Formation opt-in。** コアはプリスケーラ・リセットを禁じる（C3-F21）；Formation は本当に必要なら選択でき、外部同期可能性の喪失を受け入れる。スレーブ構成は構造的に決してプリスケーラをリセットできてはならない。§ 3.4a 参照。 | **V** (仮確定) |
| **C3-F23** (v1.1, PROVISIONAL) | **FG-Global exclusion principle.** Global commands do not execute in the foreground except Reset, Stay Set, NOP (each with a stated justification). Base Set/Return/Sub-sequence Call/Loop/Prog End are window-only; FG encounter = HALT. Enforces time/space separation as band legality; dissolves the D16–D31 dual-use (extended-operand Globals live only in Held-signal bands). See § 3.4b. / **FG-Global排除原則。** Reset・Stay Set・NOP を除き Global は前景実行しない。他は窓内専用、FG 遭遇は HALT。時間/空間分離を帯域合法性として強制;D16–D31 二重用途を解消。§ 3.4b 参照。 | **F** (仮確定) |
| **C3-F24** (v1.1, PROVISIONAL) | **Error HALT (runaway detection).** Rule violations halt at the violating instruction with an error-flag output; escapes = hardware reset / ISMCE live patch / insertion. Base Set↔Loop band-crossing checks are Core-mandatory; excessive debuggability may be parameterized later. Supersedes the "blank shot = no effect" reading of a stray Prog End. See § 3.4b/§ 3.4c list. / **Error HALT（暴走検知）。** 規則違反は違反命令で停止しエラーフラグを出力;脱出 = HWリセット/ISMCE生パッチ/インサーション。帯域跨ぎ検査は Core 必須。迷子 Prog End の「空砲」解釈を置き換える。 | **F** (仮確定) |
| **C3-F25** (v1.1, PROVISIONAL; lifetime corrected 2026-07) | **Stay Start State register.** FG Stay Set writes its own State Number; valid only within that same Stay cycle — a queued Base Set executing in that cycle hands the value to the Base register (discharging it), else the next Stay Set overwrites it. *(Not stacked, not cross-Stay — an earlier text conflated this with the Base register's own long-standing role of carrying a target across many Stay periods to a distant Loop, including nesting; corrected, see Layer 2 trace 2026-07-06_ptsg-stay-start-state-register DP-2.)* Reset 0; Core-invisible (Formation may copy out). Queued Base Set loads Base := Stay Start State (time-axis origin) → queued loops return to the stay-period start; enables the single-period self-loop (2^28 pattern). See § 3.4b. / **Stay Start Stateレジスタ。** FG Stay Set が自身の SN を書き込み、同一 Stay サイクル内でのみ有効——そのサイクル内で Que の Base Set が実行されれば値は Base レジスタへ引き継がれ（用済み）、なければ次の Stay Set が上書き。*（スタック対象でも Stay 跨ぎでもない——以前の文は、多数の Stay を跨いで遠い Loop へ標的を運ぶという Base レジスタ既存の役割〈入れ子を含む〉と混同していた;訂正済み。）* リセット 0;Core 不可視。Que の Base Set は Base := Stay Start State → Que ループはステイ期間起点へ帰還;単一期間自己ループ（2^28）を可能に。 | **F** (仮確定) |
| **C3-F26** (v1.1, PROVISIONAL) | **Queue capacity: last-write-wins; SN-overwrite HALTs.** Single reservation register; a later reservation replaces an earlier one; overwrite of a queued State-Number reservation = runaway error (HALT + flag). Priority arbitration rejected (cannot rescue intent; loads the timeup path / Fmax). Resolves verification-queue #4. See § 3.4b. / **Que容量: 後勝ち;SN上書きはHALT。** 単一予約レジスタ;後の予約が置換;SN 予約の上書きは暴走エラー。優先順位調停は棄却（意図を救えず timeup 経路に負荷）。検証キュー#4 を解決。 | **F** (仮確定) |
| **C3-T15** (v1.1, new) | **Nested multi-booking Tie.** Two Base Sets / two Loops in one window (nested self-loops, 2^44-class): (A) forbid — simple, matches the single-register queue; (B) support elegantly — cost unmeasured (a QUEUE_DEPTH parameter may reconcile). Open pending cost measurement. / **入れ子マルチブッキング Tie。** (A) 禁止——単純;(B) 美しく対応——費用未計測（QUEUE_DEPTH パラメータが両立し得る）。費用計測まで未決。 | **T** |

**Decision count by status (v1.1):**

**地位別決定数(v1.1):**

- **Fixed (F):** 20 — architectural commitments (including v1.1 additions C3-F15–F20 and the revisions of C3-F2/F3/F4)
- **Convention (V):** 1 — C3-V2 (counter width); C3-V1 and C3-V3 were superseded/promoted in v1.1
- **Tie (T):** 12 — C3-T1–T7 (carried from v1.0), plus C3-T10–T14 (new, prescaler-coupled); C3-T8 was resolved and C3-T9 dissolved in v1.1

The Tie count rose (new prescaler-coupled questions surfaced during the v1.1 deliberation) even as two v1.0 Ties closed — which is the healthy signature of a deliberation that resolves what it can and honestly records what it cannot yet resolve.

Tie 数は上昇した(v1.1 協議中に新たなプリスケーラ結合の問いが浮上した)、二つの v1.0 Tie が閉じたにもかかわらず——これは、解決できることを解決し、まだ解決できないことを正直に記録する協議の健全な兆候である。

---

## End of Chapter 3 / 第3章の末尾

> *Time on the stay axis; space on the state axis; effects, in the background; consciousness, at the timeup.*
> *時間はステイ軸に、空間はステート軸に、効果は裏側に、意識はタイムアップに。*

> *Before Prog End, effects land at once; after Prog End, they wait for the timeup. Position, not mode, decides when the background speaks.*
> *Prog End の前では効果は即座に着地する；Prog End の後では timeup を待つ。モードではなく位置が、裏側がいつ語るかを決める。*

> *Where the dynamics have multiple legible readings — and they do, more often here than anywhere else in the Core — the readings are recorded, not chosen. The community is the place where they are weighed.*
> *動的機構が複数の判読可能な読解を持つ場所——そしてそれらは持つ、ここではコア内の他のどこよりも頻繁に——読解は選ばれず記録される。コミュニティはそれらが評価される場所である。*

This chapter is released into the public domain under CC0 1.0 Universal. **This is the v1.1 revision.** Chapter 4 (Indirect Addressing and Prescaler) will resolve the literal-zero-as-escape escapes left unaddressed here (Jump operand 0, Stay operand 0, loop counter target indirect mode) and will deliberate the five new prescaler-coupled Ties (C3-T10–T14). Chapter 5 (External Logic Interface) will specify the pin-level bus protocols for the external operation bus, external stack bus, insertion bus, loop counter externalization, and the match-flag outputs. The Ties remaining open after v1.1 (C3-T1–T7 and C3-T10–T14) await community input and the Chapter 4/5 drafting.

本章は CC0 1.0 Universal のもとパブリックドメインに公開される。**これは v1.1 改訂である。** 第4章(間接アドレッシングとプリスケーラ)はここで対処されていない直値ゼロエスケープ(Jump オペランド 0、Stay オペランド 0、ループカウンタ目標間接モード)を解決し、五つの新しいプリスケーラ結合 Tie(C3-T10〜T14)を協議する。第5章(外部ロジックインターフェース)は外部演算バス、外部スタックバス、挿入バス、ループカウンタ外部化、そして一致フラグ出力のためのピンレベルバスプロトコルを指定する。v1.1 後に開かれたまま残る Tie(C3-T1〜T7 と C3-T10〜T14)はコミュニティ入力と第4章/5章の起草を待つ。

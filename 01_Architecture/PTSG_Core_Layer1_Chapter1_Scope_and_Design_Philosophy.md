# PTSG-Core — Layer 1 Specification
# Chapter 1: Scope and Design Philosophy
# PTSGコア — 第1層仕様書
# 第1章：スコープと設計哲学

> **License: CC0 1.0 Universal (Public Domain)**
> This is the architectural specification of the PTSG (Programmable Timing Sequence Generator) Core — a minimal instruction-driven control primitive for FPGA. Read it, redistribute it, build on it, regenerate from it.
>
> **ライセンス：CC0 1.0 Universal（パブリックドメイン）**
> これは PTSG（Programmable Timing Sequence Generator）コア——FPGA用のミニマルな命令駆動制御プリミティブ——のアーキテクチャ仕様書である。読み、再配布し、その上に構築し、再生成してよい。

---

## 1.1 Purpose of this Specification / 本仕様書の目的

This document is the first chapter of the PTSG-Core Layer 1 specification. It establishes the **scope** of what PTSG-Core is, the **design philosophy** that shapes it, and the **boundaries** that distinguish the Core from per-application Formations and from specific implementations.

本文書はPTSGコア第1層仕様の最初の章である。PTSGコアとは何かの**スコープ**、それを形作る**設計哲学**、そしてコアを応用別フォーメーションや特定の実装から区別する**境界**を確立する。

Three concrete intentions drive this scope:

このスコープは三つの具体的な意図によって駆動されている：

**Intention 1 — Architectural foundation for an ecosystem.**
PTSG is not a single artifact to be used as-is; it is the invariant nucleus of an ecosystem of Formations (`PTSG_WPMS_Formation_OpenPrompt`, `PTSG_I2C_Formation_OpenPrompt`, `PTSG_MIDI_Formation_OpenPrompt`, etc.). Each Formation builds atop the Core with its own external registers, Condition logic, work memory, and timing-signal assignments. For the ecosystem to function, the Core must be small, stable, and clearly bounded — different Formations must be able to share a common substrate without negotiating its semantics. This chapter establishes what is in that substrate and what is not.

**意図1 — エコシステムのアーキテクチャ的基盤。**
PTSGはそのまま使われる単一のアーティファクトではない；フォーメーション群(`PTSG_WPMS_Formation_OpenPrompt`、`PTSG_I2C_Formation_OpenPrompt`、`PTSG_MIDI_Formation_OpenPrompt`等)のエコシステムの不変な核である。各フォーメーションは独自の外部レジスタ、Conditionロジック、ワークメモリ、タイミング信号配置でコアの上に構築する。エコシステムが機能するためには、コアは小さく、安定で、明確に境界付けられていなければならない——異なるフォーメーションが、その意味論を交渉することなく共通の基盤を共有できなければならない。本章はその基盤に何があり、何がないかを確立する。

**Intention 2 — Replacement for the counter-based FPGA introduction.**
The dominant entry point to FPGA — building a multi-bit counter and routing its highest bit to an LED — has, in this project's assessment, three structural problems: the counter appears as a black box with no observable internal state to learn from; the path from counter-Lチカ to anything more sophisticated requires a discontinuous jump into FSM design; and the satisfaction of "the LED blinks" is fleeting and self-contained. PTSG addresses all three. This chapter explains why PTSG should be positioned as a **replacement** for counter-Lチカ rather than a follow-on topic — and what that positioning entails for the way the Core is documented.

**意図2 — カウンタベースのFPGA入門の置き換え。**
FPGAへの支配的な入口——マルチビットカウンタを構築し、その最上位ビットをLEDに経路づける——には、本プロジェクトの査定では、三つの構造的問題がある: カウンタは観察可能な内部状態を学ぶ術のないブラックボックスとして現れる；カウンタLチカからより洗練された何かへの経路は、FSM設計への不連続なジャンプを要求する；そして「LEDが点滅する」という満足は刹那的で自己完結的である。PTSGは三つすべてに対処する。本章はなぜPTSGがカウンタLチカの**置き換え**として——後続トピックとしてではなく——位置づけられるべきかを説明し、その位置づけがコアの文書化方法に何を伴うかを説明する。

**Intention 3 — Validation of the Open Prompt regeneration loop for primitives.**
PTSG-Core is the second Open Prompt repository (after FPGA Spectrum Engine) and the first to be a *primitive* rather than a system. The Core is small enough that regeneration from Layer 1 (this specification) plus Layer 2 (reasoning traces) plus a competent FPGA engineer plus an LLM collaborator is plausibly within reach of a single weekend. If that regeneration works, the Open Prompt methodology is shown to apply at the primitive scale — and the ecosystem of Formations that build atop the Core inherits the same regeneration property. This chapter is part of the surface that regeneration must read; its design must support being read with comprehension.

**意図3 — プリミティブのためのOpen Prompt再生成ループの検証。**
PTSGコアは2番目のOpen Promptリポジトリ(FPGA Spectrum Engineに次ぐ)であり、システムではなく*プリミティブ*である最初のものである。コアは十分小さく、Layer 1(本仕様)＋Layer 2(推論軌跡)＋有能なFPGAエンジニア＋LLM協働者からの再生成が、一週末の範囲内にもっともらしく収まる。その再生成が機能すれば、Open Prompt方法論はプリミティブのスケールにも適用されることが示される——そしてコアの上に構築するフォーメーションのエコシステムは、同じ再生成性質を継承する。本章は再生成が読まなければならない表面の一部である；その設計は理解とともに読まれることを支持しなければならない。

---

## 1.2 What PTSG Is / PTSGとは何か

**PTSG is a compact instruction-driven control core for FPGA.** It consists of a block-RAM-based instruction memory, an instruction decoder, a stay counter, a state-number register, a small set of internal control registers, and an output port carrying 16 parallel timing signals. The instruction memory is reprogrammable via JTAG using the In-System Memory Content Editor, with no HDL re-synthesis required.

**PTSGはFPGA用のコンパクトな命令駆動制御コアである。** ブロックRAMベースの命令メモリ、命令デコーダ、ステイカウンタ、ステートナンバーレジスタ、小さな内部制御レジスタセット、そして16本の並列タイミング信号を運ぶ出力ポートから成る。命令メモリはIn-System Memory Content Editorを用いてJTAG経由で再プログラム可能であり、HDLの再合成は要求されない。

**Size envelope (target):**

**サイズ目安(目標):**

| Metric | Target | Notes |
|---|---|---|
| Logic Elements (LE) | ~200 | Core only; excludes external registers and Condition logic / コアのみ；外部レジスタとConditionロジックを除く |
| Block RAM | 2 (min) – 32 (max) blocks | Each Cyclone V M10K block = 10 kbit (typically used as 256-word × 32-bit, with the remaining bits unused or assigned to parity). Minimum 2 blocks: one M10K for instruction memory and one M10K for stack/scratch, each at 256-word depth. The 12-bit operand allows scaling instruction memory up to 4096 words; at full 4096-word depth for both memories, total M10K usage reaches ~32 blocks (≈16 per memory). Most applications use far less than the 4096-word maximum. / 各Cyclone V M10Kブロック = 10 kbit(典型的に256ワード×32ビットとして使用、残りビットは未使用またはパリティに割当)。最小2 blocks: 命令メモリ用1個のM10K、スタック／スクラッチ用1個のM10K、各々256ワード深度。12ビットオペランドにより命令メモリは最大4096ワードまで拡張可能；両メモリを4096ワードフル深度にした場合、M10K総使用量は~32 blocks(各メモリ約16個)に達する。ほとんどの応用は4096ワード最大値よりはるかに少なくを使う。 |
| DSP blocks | 0 | The Core requires no multipliers; external logic provides any arithmetic needed / コアは乗算器を要求しない；必要な算術は外部ロジックが提供する |
| Operating frequency | implementation-dependent | The Core is fully synchronous; typical operation 50-200 MHz on Cyclone V / コアは完全同期；Cyclone V上で典型的に50-200 MHz動作 |

**Four essential properties.** PTSG-Core's design is shaped by four interrelated properties. Each receives a dedicated section below (§§ 1.4–1.7). They are listed here in summary to establish the conceptual outline before details:

**四つの本質的特性。** PTSGコアの設計は四つの相互関連する特性によって形作られる。各々は以下の専用セクション(§§ 1.4–1.7)を持つ。詳細に入る前に概念的概要を確立するため、ここで要約として列挙する:

- **(a) Time-axis / space-axis complete separation.** Time is managed by Stay instructions; space is managed by State transitions; the two axes do not interfere. / **時間軸／空間軸の完全分離。** 時間はステイ命令によって管理され、空間はステート遷移によって管理される；二つの軸は互いに干渉しない。

- **(b) Externalization of Condition logic.** The Core accepts a 1-bit external Condition input; all conditional complexity is produced by external logic, leaving the Core's instruction set minimal. / **Conditionロジックの外部化。** コアは1ビットの外部Condition入力を受け取る；すべての条件的複雑性は外部ロジックによって生成され、コアの命令セットはミニマルに保たれる。

- **(c) Background execution during Stay.** Global commands placed before a Stay instruction execute during the wait period, folding parallelism into the time series while timing signals are held. / **ステイ中の裏実行。** ステイ命令の前に置かれたグローバルコマンドは待機期間中に実行され、タイミング信号が保持されたまま並列性を時系列に折り込む。

- **(d) AI-affinity as a designed property.** The opcode set is deliberately small (4 of 16 possible slots used) with clear bit assignment, yielding an instruction format particularly amenable to LLM-based code generation with low hallucination risk. / **設計された性質としてのAI親和性。** オペコードセットは意図的に小さく(16個のうち4個のスロットを使用)、明確なビット配置を持ち、低い幻覚リスクでLLMベースのコード生成に特に適した命令フォーマットを生み出す。

**What PTSG-Core specifies.** This Core specification defines: the instruction memory layout and the 32-bit instruction word format (§ Chapter 2); the four currently-defined opcodes (Global, Stay, Branch, Jump) and their semantics (§ Chapter 2); the sub-opcode mechanism and background-execution semantics (§ Chapter 3); indirect-addressing conventions and the prescaler (§ Chapter 4); and the external interface contract — Condition input, State Number output, 16 timing signals, external register access protocol (§ Chapter 5).

**PTSGコアが指定するもの。** 本コア仕様は以下を定義する: 命令メモリレイアウトと32ビット命令語フォーマット(§ 第2章); 現在定義されている4つのオペコード(Global、Stay、Branch、Jump)とその意味論(§ 第2章); サブオペコード機構と裏実行意味論(§ 第3章); 間接アドレッシング慣習とプリスケーラ(§ 第4章); そして外部インターフェース契約——Condition入力、ステートナンバー出力、16本のタイミング信号、外部レジスタアクセスプロトコル(§ 第5章)。

---

## 1.3 What PTSG Is Not / PTSGでないもの

A specification gains precision by stating what it is *not*. The following are deliberately outside what PTSG-Core attempts to be:

仕様は、それが何で*ない*かを述べることで精度を得る。以下は意図的にPTSGコアが為そうとしないものである:

**PTSG is not a general-purpose CPU.** The Core has no arithmetic-logic unit, no general-purpose register file, no floating-point support, no addressing-mode generality. Operations beyond sequence control and timing-signal generation are the responsibility of external logic. The Core's instruction set deliberately stops short of being Turing-complete in the conventional CPU sense — though the Core combined with external logic and Condition generators is fully capable of any control task the application requires.

**PTSGは汎用CPUではない。** コアは演算論理ユニットを持たず、汎用レジスタファイルを持たず、浮動小数点サポートを持たず、アドレッシングモードの一般性を持たない。シーケンス制御とタイミング信号生成を超える演算は外部ロジックの責任である。コアの命令セットは意図的に従来のCPUの意味でのチューリング完全性に達しない——しかしコアと外部ロジックとCondition生成器を組み合わせたものは、応用が要求する任意の制御タスクに完全に対応可能である。

**PTSG is not a wholesale replacement for FSM design.** Conventional Finite State Machine design remains appropriate for tasks where the state space is small, state transitions are dense and tightly coupled to combinational signals, or the application's primary structure is a transition diagram rather than a sequence. PTSG is best where the application's primary structure is sequential, where timing relationships matter as much as logical relationships, or where the ability to *modify* the control behavior post-synthesis has explicit value. **PTSG is one option in the FPGA designer's toolkit, alongside FSMs, not above them.**

**PTSGはFSM設計の全面的置き換えではない。** 従来の有限状態機械設計は、状態空間が小さい、状態遷移が稠密で組み合わせ信号と密結合している、あるいは応用の一次構造がシーケンスではなく遷移図であるタスクに対して、引き続き適切である。PTSGは応用の一次構造がシーケンシャルである場合、タイミング関係が論理関係と同程度に重要である場合、あるいは合成後に制御挙動を*変更する*能力に明示的な価値がある場合に最良である。**PTSGはFSMと並んで、FSMの上ではなく、FPGA設計者のツールキットの一つの選択肢である。**

**PTSG is not a soft-core processor.** Soft cores (Nios II, MicroBlaze, RISC-V softs) target a different design center: they aim to run general-purpose software with conventional toolchains, at the cost of substantial fabric resources and complex memory hierarchies. PTSG aims to run *minimal sequence-control programs*, at a fraction of the resource cost, with no traditional toolchain (instruction lists are typically authored by hand or by AI agents, not compiled from C). The two should not be confused, and the choice between them depends on the application's needs.

**PTSGはソフトコアプロセッサではない。** ソフトコア(Nios II、MicroBlaze、RISC-V softs)は異なる設計中心を狙う: 大きなファブリックリソースと複雑なメモリ階層のコストで、従来のツールチェーンで汎用ソフトウェアを実行することを目指す。PTSGは*ミニマルなシーケンス制御プログラム*を、リソースコストの一部分で、従来のツールチェーンなしに(命令列は典型的に手作業またはAIエージェントによって作成され、Cからコンパイルされない)実行することを目指す。両者は混同されるべきではなく、両者の間の選択は応用の必要に依存する。

**PTSG-Core is not domain-specific.** The Core specification contains no knowledge of WPMS, of audio synthesis, of motor control, of network protocols, or of any other application domain. Domain-specific external register layouts, Condition logic, work memory contents, and timing-signal assignments are the responsibility of **Formations** — per-application repositories that build atop the Core. The Core is the shared genetic code; Formations are the diverse phenotypes expressed from it.

**PTSGコアはドメイン固有ではない。** コア仕様にはWPMSの知識、オーディオ合成の知識、モータ制御、ネットワークプロトコル、その他の応用ドメインの知識は一切含まれない。ドメイン固有の外部レジスタレイアウト、Conditionロジック、ワークメモリ内容、タイミング信号配置は、コアの上に構築する応用別リポジトリである**フォーメーション**の責任である。コアは共有された遺伝コードである；フォーメーションはそこから発現される多様な表現型である。

**PTSG-Core does not prescribe a specific implementation.** This Layer 1 specification is implementation-neutral. Verilog/VHDL skeletons exist as Layer 3 sample implementations and serve as reference points, but they are not normative — different engineers may legitimately implement the Core differently, and their implementations are independent works, not derivatives of the samples. (See `LICENSE_OpenPrompt.md` for the distinction.)

**PTSGコアは特定の実装を規定しない。** 本第1層仕様は実装中立である。Verilog/VHDLスケルトンはLayer 3サンプル実装として存在し、リファレンスポイントとして奉仕するが、規範的ではない——異なるエンジニアは合法的にコアを異なって実装でき、彼らの実装はサンプルの派生物ではなく独立した著作物である。(区別については`LICENSE_OpenPrompt.md`を参照。)

---

## 1.4 Design Philosophy — Time-Axis / Space-Axis Separation / 設計哲学 — 時間軸／空間軸分離

**The principle.** PTSG separates the management of *time* from the management of *state-space* into two distinct mechanisms. Time is managed by the Stay opcode and the stay counter; space is managed by State transitions (Branch, Jump, sequential next-state). The two axes do not mix: a Stay instruction does not change the State Number; a State transition does not implicitly wait. **Designers can therefore reason about timing and topology independently.**

**原理。** PTSGは*時間*の管理と*状態空間*の管理を、二つの別個の機構に分離する。時間はStayオペコードとステイカウンタによって管理され、空間はステート遷移(Branch、Jump、シーケンシャル次ステート)によって管理される。二つの軸は混ざらない: ステイ命令はステートナンバーを変更しない；ステート遷移は暗黙的に待たない。**したがって、設計者はタイミングとトポロジーを独立に推論できる。**

**The FSM mesh-structure problem.** Conventional FSMs entangle time and state. A state in a typical FSM diagram represents both "the system is in this configuration" *and* "the system is at this point in time." When a long wait must be inserted, the FSM accumulates intermediate states; when complex parallel timing relationships must be expressed, the diagram acquires a mesh-like structure of overlapping transitions. The cognitive cost grows super-linearly with the state count: each new state interacts with potentially many existing states, and the designer must hold all interactions in mind simultaneously.

**FSMの網目構造問題。** 従来のFSMは時間と状態を絡める。典型的なFSM図における一つの状態は、「システムがこの構成にある」ことと「システムが時間軸上のこの地点にある」ことの両方を表現する。長い待機が挿入されなければならない時、FSMは中間状態を累積する；複雑な並列タイミング関係が表現されなければならない時、図は重なり合う遷移の網目状構造を獲得する。認知コストは状態数とともに超線形に増大する: 各新ステートは潜在的に多くの既存ステートと相互作用し、設計者はすべての相互作用を同時に心に保持しなければならない。

**The PTSG resolution.** Inserting a long wait does not add states to the instruction list; it adds a single Stay instruction with a large counter value (or with prescaler, an arbitrarily long wait). Expressing complex parallel timing relationships does not create a mesh; it creates a linear sequence where each step's effect is localized. A reader of the instruction list can identify "what happens" by reading sequentially, and "when it happens" by tracking stay counts — without solving a graph problem.

**PTSGの解決。** 長い待機を挿入することは命令列にステートを加えない；それは大きなカウンタ値を持つ単一のステイ命令(またはプリスケーラを伴って任意に長い待機)を加える。複雑な並列タイミング関係の表現は網目を作らない；それは各ステップの効果が局所化される線形シーケンスを作る。命令列の読者は、グラフ問題を解くことなく、順次読むことで「何が起きるか」を識別し、ステイカウントを追跡することで「いつ起きるか」を識別できる。

**Implication for designer cognition.** The separation is not merely a mechanical convenience; it changes the designer's mode of thought. A PTSG designer thinks in terms of *sequences* (what happens in order) and *intervals* (how long each step lasts), as separable concerns. The complexity of timing and the complexity of logic remain independent in mental representation, where in FSM design they become entangled. **For applications whose primary structure is sequential — most peripheral interfaces, most control protocols, most state-driven sequencing — this separation reduces design effort substantially.**

**設計者認知への含意。** 分離は単に機械的便利さではない；それは設計者の思考様式を変える。PTSG設計者は*シーケンス*(何が順に起こるか)と*インターバル*(各ステップがどれだけ続くか)という観点で、分離可能な関心事として考える。FSM設計においては絡み合うタイミングの複雑性と論理の複雑性は、心的表現において独立に残る。**応用の一次構造がシーケンシャルである場合——ほとんどのペリフェラルインターフェース、ほとんどの制御プロトコル、ほとんどの状態駆動シーケンシング——この分離は設計努力を相当に削減する。**

**Implication for AI legibility.** The separation has a consequence the architect did not originally seek but came to recognize as significant: AI agents reading PTSG instruction lists do not have to solve "what is the state-time relationship at this point" — they can read Stay durations and State transitions as decoupled streams. This is one of the contributing factors to PTSG's AI-affinity, treated in § 1.7.

**AI判読可能性への含意。** 分離は、アーキテクトが当初は求めなかったが重要だと認識するに至った帰結を持つ: PTSG命令列を読むAIエージェントは「この地点における状態-時間関係は何か」を解く必要がない——彼らはステイの持続時間とステート遷移を分離されたストリームとして読める。これはPTSGのAI親和性への寄与因子の一つであり、§ 1.7で扱う。

---

## 1.4a Design Philosophy — The Trailing-Edge Doctrine / 設計哲学 — 後縁主義

**The principle.** PTSG determines all state **by the trailing edge** of every boundary, so that **at the leading edge** of the next state the world is already settled. The busy work — counting, comparing, deciding — is finished before a boundary is crossed; crossing it is a crossing into a determined, quiet world. This is not merely "act late"; it is "finish early enough that nothing is still resolving at the moment of transition." **It is the discipline that gives PTSG timing rigor of communication- and video-synchronization grade, where a stated count must equal the cycles on the wire and a boundary must be clean.**

**原理。** PTSGはあらゆる境界の**後縁までに**すべての状態を確定し、ゆえに次状態の**前縁では**世界が既に静定している。忙しい仕事——数える・比べる・決める——は境界を越える前に終わっている；越境は、確定した静かな世界への越境である。これは単に「遅く動作する」のではない；「遷移の瞬間に何も確定中でないよう、十分早く終える」ことである。**これは PTSG に、記述したカウントが線上のサイクルと一致し、境界が清潔でなければならない、通信およびビデオ同期グレードのタイミング厳格性を与える規律である。**

**A recursive doctrine, reaching the clock.** The doctrine is recursive: it applies at every scale of boundary, and it bottoms out at the clock itself. The memory clock is deliberately falling-edge (EDGE=NEG, Chapters 2/4): this gives the clock its own trailing edge, at which the fetched instruction resolves, so that at the rising edge everything downstream is already settled. EDGE=NEG is therefore not a stale-fetch workaround but the Trailing-Edge Doctrine reaching the silicon root — the principle made physical at the lowest level.

**クロックに達する再帰的原則。** 原則は再帰的である: あらゆるスケールの境界に適用され、クロック自身に底を打つ。メモリクロックは意図的に立下りである(EDGE=NEG、第2/4章): これはクロックに自身の後縁を与え、そこでフェッチされた命令が確定し、ゆえに立ち上がりでは下流のすべてが既に静定している。したがって EDGE=NEG は stale-fetch の回避策ではなく、後縁主義がシリコンの根に達したもの——最下層で物理化された原則——である。

**The nested hierarchy.** Boundaries nest: loop count → stay count → prescaler count → clock. Each outer boundary's trailing edge is composed from the settled trailing edges of the level below, and settledness propagates upward, so every level greets its "new year" already stable. (The architect's metaphor: as people work hardest at year-end so that the new year may begin calm, each level of PTSG completes its accounting at its trailing edge so the next may begin settled.) The structural phase-lock of the prescaler (C4-F9) is exactly this hierarchy being *in register*: a loop is an integer number of prescale periods, so the prescaler's year-end aligns with the loop's, and no jitter can enter.

**入れ子のヒエラルキー。** 境界は入れ子になる: ループカウント → ステイカウント → プリスケーラカウント → クロック。各外側境界の後縁は下位層の静定した後縁から構成され、静定が上方へ伝播し、各層は既に安定した「新年」を迎える。(アーキテクトの比喩: 人が年末に最も忙しく働き新年が穏やかに始まるように、PTSG の各層は後縁で勘定を終え、次が静定して始まれるようにする。)プリスケーラの構造的位相ロック(C4-F9)はまさにこのヒエラルキーが*レジスタ済み(in register)*であること: ループはプリスケール周期の整数個ゆえ、プリスケーラの年末がループの年末と揃い、ジッタは入り得ない。

**Consequences across the specification.** Several decisions are derivations of this single principle, and cite it: foreground commands are prescaled so that every command ends on a trailing edge (C4-F8); the prescaler is free-running and structurally phase-locked (C4-F9); Stay Set is clear/sync-only so no background-program length can smear the trailing edge (C4-F10); and a queued operation fires **at the trailing edge** — the moment its count completes — which resolves the queued-firing edge decision as Fixed (C4-F11, trailing; was Tie C4-T3). A sustained external strobe, where needed, is a Formation-side concern derived from the trailing-edge match pulse, not a Core leading-edge action.

**仕様全体への帰結。** いくつかの決定はこの単一原則の派生であり、それを引用する: 前景コマンドはプリスケールド実行され、あらゆるコマンドが後縁で終わる(C4-F8)；プリスケーラは自由走行し構造的に位相ロックする(C4-F9)；Stay Set はクリア／同期のみで、いかなる背景プログラム長も後縁を滲ませない(C4-F10)；そしてキュー演算は**後縁で**——そのカウントが完了する瞬間に——発火し、これがキュー発火縁の決定を Fixed(C4-F11、後縁；旧 Tie C4-T3)として解決する。持続的な外部ストローブは、必要な場合、後縁一致パルスから導かれる Formation 側の関心事であって、Core の前縁アクションではない。

**The principled exceptions — StaySet and Reset.** The doctrine has two exceptions, and they prove the rule. Foreground-executed **Stay Set** and **Reset** are placed on the **leading edge** — the first clock cycle marking a state's *start* — because their job is to mark a beginning, which is a leading-edge act. They do not violate the doctrine; they **stand on** it. They may be safely placed at the leading edge *only because* the doctrine guarantees that edge is settled: each depends on the precondition that the immediately preceding command has ended on a prescaler tick (a trailing edge). Upstream trailing-edge determination is exactly what makes a clean leading-edge placement possible downstream. Any future command placed on a leading edge must satisfy this same precondition.

**原則的な例外——StaySet と Reset。** 原則には二つの例外があり、それらが規則を証明する。前景実行される **Stay Set** と **Reset** は**前縁**——ある状態の*開始*を標す最初のクロックサイクル——に配置される、なぜならその仕事は始まりを標すことであり、それは前縁のアクションだからである。これらは原則を破らない；原則の**上に立つ**。前縁に安全に置けるのは、*ただ*原則がその縁を静定させているからである: 各々は、直前のコマンドがプリスケーラティック(後縁)で終わっているという前提に依存する。上流の後縁確定こそが、下流の清潔な前縁配置を可能にする。前縁に置かれる将来のいかなるコマンドも、この同じ前提を満たさねばならない。

**Relationship to the RH001–008 revisions.** Many of the architect's source revisions RH001–RH008 (2026-06-14/15) were, in retrospect, conversions toward trailing-edge determination. The Layer 4 verification campaign that resolved the residual bring-up anomaly (Build Logs #6–#8) was, at root, the specification catching up to a doctrine the source had already encoded. The reasoning is archived in the Layer 2 trace `2026-06-24_ptsg-trailing-edge-doctrine`.

**RH001–008 改訂との関係。** アーキテクトのソース改訂 RH001–RH008(2026-06-14/15)の多くは、振り返れば後縁確定への変更だった。残留ブリングアップ異常を解決した Layer 4 検証キャンペーン(Build Log #6–#8)は、根本では、ソースが既に符号化していた原則に仕様が追いつくことだった。推論は Layer 2 トレース `2026-06-24_ptsg-trailing-edge-doctrine` に保管されている。

---

## 1.5 Design Philosophy — Externalization of Condition Logic / 設計哲学 — Conditionロジックの外部化

**The principle.** PTSG exposes a single 1-bit Condition input to its environment. Branch instructions consult this input to decide whether to branch. **All complexity of how the Condition is computed — comparisons, threshold tests, multi-signal AND/OR logic, sensor processing, communication-protocol parsing — is the responsibility of external logic, not of the Core.**

**原理。** PTSGはその環境に単一の1ビットCondition入力を露出する。Branch命令はこの入力を参照して分岐するかを決定する。**Conditionがどう計算されるかのすべての複雑性——比較、閾値テスト、複数信号 AND/OR ロジック、センサ処理、通信プロトコル解析——は、コアではなく外部ロジックの責任である。**

**Why discipline, not limitation.** A natural objection is that 1 bit is "too little" — that PTSG should support multi-bit condition codes, or compare-and-branch instructions, or other CPU-like conditional patterns. The PTSG architect's response is that those features, once added, attract more features: which comparison operators are needed? signed or unsigned? what about composite predicates? what about saturation? Each added feature is locally reasonable; each multiplies the Core's surface area; collectively they yield an instruction set the Core was specifically designed to avoid. **By drawing the boundary at 1 bit, the design is protected from this drift.** External logic, free to use whatever combinational depth and arithmetic primitives the application requires, can compute arbitrarily complex conditions and present the result as a single bit when needed.

**なぜ制限ではなく規律か。** 自然な反論は、1ビットは「少なすぎる」というもの——PTSGはマルチビットコンディションコード、または比較分岐命令、その他のCPU風条件パターンをサポートすべきではないか。PTSGアーキテクトの応答は、それらの機能は、一度追加されると、より多くの機能を引き寄せるというものである: どの比較演算子が必要か? 符号付きか符号なしか? 複合述語はどうか? 飽和はどうか? 各追加機能は局所的に合理的である；各々はコアの表面積を倍加する；総体として、それらはコアが特定的に避けるよう設計された命令セットを生み出す。**境界を1ビットに引くことで、設計はこのドリフトから保護される。** 外部ロジックは、応用が要求するどんな組み合わせ深度と算術プリミティブをも用いて、任意に複雑な条件を計算し、必要な時に結果を単一ビットとして提示できる。

**The State Number output as the bridge.** External logic cannot synthesize sensible Conditions in isolation; it needs to know *where* in the instruction list the PTSG currently is. The Core therefore exposes the current State Number (the instruction memory address) as an external output. External Condition logic typically takes the form of a state-indexed lookup: for State X, the relevant Condition is "comparator A's output"; for State Y, it is "FIFO-not-empty"; for State Z, it is "external timer satisfied." The lookup may be a small ROM, a multiplexer, or a more elaborate state-dependent computation — its complexity is in the Formation, not in the Core.

**橋渡しとしてのステートナンバー出力。** 外部ロジックは孤立して合理的なConditionを合成できない；命令列の*どこに*PTSGが現在いるかを知る必要がある。したがって、コアは現在のステートナンバー(命令メモリアドレス)を外部出力として露出する。外部Conditionロジックは典型的にはステート索引付き検索の形を取る: ステートXに対して、関連するConditionは「比較器Aの出力」；ステートYに対しては「FIFO非空」；ステートZに対しては「外部タイマ満了」。検索は小さなROM、マルチプレクサ、またはより精巧なステート依存計算であり得る——その複雑性はコアではなくフォーメーションにある。

**The "true means no-branch" convention.** Branch instructions in PTSG default to *branching when the Condition fails*; they proceed to the next state when the Condition is true. This may at first appear inverted relative to typical CPU branch conventions, but it has proven more ergonomic in practice: the natural reading "if not yet ready, loop back; otherwise proceed" maps directly to the Branch's behavior without negation. This is recorded as a fixed convention in the Core. (Detailed in Chapter 2.)

**「成立で不分岐」の慣習。** PTSGのBranch命令はデフォルトで*Conditionが不成立の時に分岐*する；Conditionが成立する時に次のステートへ進む。これは一見、典型的なCPU分岐慣習に対して反転して見えるかもしれないが、実践においてはより人間工学的であることが証明された: 「まだ準備ができていなければループバック、そうでなければ進む」という自然な読みは、否定なしにBranchの挙動に直接マップする。これはコアにおける確定した慣習として記録される。(第2章で詳述。)

**The hidden generality of the externalization.** Externalizing Condition logic has a consequence that becomes visible only when many Formations exist: **the same Core can serve radically different application domains because each domain supplies its own Condition logic**. An I²C Formation's Conditions might be "ACK received," "arbitration lost," "bus busy"; a motor-control Formation's Conditions might be "Hall sensor edge detected," "current threshold exceeded," "fault latched"; an audio Formation's Conditions might be "FIFO full," "sample boundary," "envelope expired." The Core sees only "1 or 0." The Formation supplies the meaning.

**外部化の隠れた一般性。** Conditionロジックの外部化は、多くのフォーメーションが存在する時にのみ可視となる帰結を持つ: **同じコアが根本的に異なる応用ドメインに奉仕できる。なぜなら各ドメインが独自のConditionロジックを供給するからである**。I²CフォーメーションのConditionは「ACK受信」「アービトレーション喪失」「バスビジー」かもしれない；モータ制御フォーメーションのConditionは「ホールセンサエッジ検出」「電流閾値超過」「フォルトラッチ」かもしれない；オーディオフォーメーションのConditionは「FIFOフル」「サンプル境界」「エンベロープ満了」かもしれない。コアは「1か0」しか見ない。フォーメーションが意味を供給する。

---

## 1.6 Design Philosophy — Background Execution During Stay / 設計哲学 — ステイ中の裏実行

**The principle.** When a Stay instruction is executing — that is, when the PTSG is waiting at a state — the timing signals (D16-D31 of the current instruction word) are *held* at the values written when Stay began. Global commands placed *before* the Stay (in the same state, or in earlier states whose effects propagate) execute *during* the wait, allowing external setup, parameter updates, and other non-time-critical operations to proceed while the timing signals provide rigid hardware timing to the external world.

**原理。** Stay命令が実行している時——すなわちPTSGがステートで待機している時——タイミング信号(現在の命令語のD16-D31)はStayが始まった時に書かれた値で*保持される*。Stayの*前に*置かれたグローバルコマンド(同じステート内、または効果が伝播する以前のステート内)は、待機*中に*実行され、タイミング信号が外部世界へ厳格なハードウェアタイミングを提供する間に、外部セットアップ、パラメータ更新、その他の時間的に重要でない演算が進行することを許す。

**The pattern made concrete.** A typical PTSG pattern that exploits background execution looks like:

**具体化されたパターン。** 裏実行を行使する典型的なPTSGパターンは次のように見える:

```
  ; Set timing signals high (e.g., CS asserted, clock enabled)
  Global (sub-op: write external register), data := <bus value>
  Stay <N clocks>     ; CS held asserted for N clocks, register write happens during wait
  ; Set timing signals to next phase
```

The external register write, which may itself take several clocks of external bus activity, completes within the Stay window. The Stay's purpose is twofold: it provides the timing-signal hold required by the external protocol, *and* it provides the execution window for the background command. When the Stay completes, the next state begins with the external write already done.

外部レジスタ書き込みは、それ自身が外部バス活動の数クロックを取るかもしれないが、Stayウィンドウ内で完了する。Stayの目的は二重である: それは外部プロトコルが要求するタイミング信号保持を提供し、*そして*それは裏コマンドのための実行ウィンドウを提供する。Stayが完了する時、次のステートは外部書き込みが既に完了した状態で始まる。

**Why this folds parallelism into the time series.** Without background execution, the same activity would require either: (a) sequential states for "set up external register" then "wait for protocol timing" then "advance" — increasing both state count and total execution time; or (b) external parallel hardware that completes the register write independently — requiring more fabric resources. Background execution achieves the parallelism *without* the resource cost and *without* the state-count increase. **The wait time is reclaimed as computation time.**

**なぜこれは並列性を時系列に折り込むか。** 裏実行なしでは、同じ活動は以下のいずれかを要求するであろう: (a) 「外部レジスタをセットアップ」、「プロトコルタイミングを待機」、「進む」のためのシーケンシャルなステート——ステート数と総実行時間の両方を増やす；または(b) レジスタ書き込みを独立に完了する外部並列ハードウェア——より多くのファブリックリソースを要求する。裏実行はリソースコスト*なしに*、ステート数増加*なしに*、並列性を達成する。**待機時間が計算時間として再生される。**

**The minimum-stay-count constraint.** Multi-clock background operations (e.g., external SRAM writes taking 4 clocks; multi-cycle multipliers taking 3 clocks) impose a minimum on the Stay's duration: the Stay must be at least as long as the background operation needs to complete. **Designers using background execution must be aware of this constraint, which becomes part of the Formation's documentation for its specific operations.** The constraint propagates: a chain of background operations within one Stay must collectively fit within the Stay window.

**最低ステイカウント制約。** 複数クロックの裏操作(例: 4クロックを取る外部SRAM書き込み；3クロックを取る複数サイクル乗算器)はStayの持続時間に下限を課す: Stayは少なくとも裏操作が完了するために必要な長さでなければならない。**裏実行を用いる設計者はこの制約を認識していなければならず、それはフォーメーションの具体的演算に対する文書化の一部となる。** 制約は伝播する: 一つのStay内における裏操作の連鎖は、集合的にStayウィンドウ内に収まらなければならない。

**The discipline this imposes on Formation design.** Formations that exploit background execution must document, for each external operation they support, the operation's clock latency. This documentation is part of the Formation's Layer 1; PTSG-Core's Layer 1 (this document) defines the mechanism but does not enumerate Formation-specific operations.

**これがフォーメーション設計に課す規律。** 裏実行を行使するフォーメーションは、サポートする各外部演算について、その演算のクロックレイテンシを文書化しなければならない。この文書化はフォーメーションのLayer 1の一部である；PTSGコアのLayer 1(本文書)は機構を定義するが、フォーメーション固有の演算を列挙しない。

---

## 1.7 Design Philosophy — AI-Affinity as Primary Design Property / 設計哲学 — 一次設計属性としてのAI親和性

**The principle.** PTSG-Core's instruction set is *deliberately* designed to be amenable to LLM-based code generation with low hallucination risk. This is not an accident of minimalism, nor a happy side effect; it is a primary design property that constrains evolution of the Core going forward.

**原理。** PTSGコアの命令セットは、低い幻覚リスクでLLMベースのコード生成に適合するよう、*意図的に*設計されている。これはミニマリズムの偶然でも、幸運な副作用でもない；今後コアの進化を制約する一次設計属性である。

**The structural features that support AI-affinity.** Four features of the instruction format contribute:

**AI親和性を支持する構造的特徴。** 命令フォーマットの四つの特徴が貢献する:

- **Small opcode set.** Only 4 of 16 possible opcodes are currently defined. Fewer alternatives means fewer plausible-but-wrong choices an LLM might generate. / **小さなオペコードセット。** 16個の可能なオペコードのうち現在は4個のみが定義されている。代替が少ないことは、LLMが生成し得るもっともらしいが誤った選択肢が少ないことを意味する。

- **Clear and uniform bit assignment.** Every instruction word has the same structure: D0-D3 opcode, D4-D15 operand, D16-D31 timing signals. An LLM does not have to remember different layouts for different opcodes. / **明確で一様なビット配置。** すべての命令語は同じ構造を持つ: D0-D3 オペコード、D4-D15 オペランド、D16-D31 タイミング信号。LLMは異なるオペコードに対して異なるレイアウトを覚えなくてよい。

- **Externalized complexity.** All Condition evaluation logic lives outside the Core; the Core's instruction set never has to encode comparison operators, signedness flags, branch predicate combinations, or other complexity that LLMs tend to hallucinate when offered too many options. / **外部化された複雑性。** すべてのConditionの評価ロジックはコアの外部に存在する；コアの命令セットは比較演算子、符号付きフラグ、分岐述語の組み合わせ、その他LLMが多すぎる選択肢を提供された時に幻覚しがちな複雑性を、決してエンコードする必要がない。

- **Reserved opcode slots as containment.** The 12 unused opcode slots are not "available for whatever future need arises" — they are *reserved* with the explicit intent that any new opcode must justify its addition against the AI-affinity criterion. A candidate opcode whose semantics would require complex LLM disambiguation is disfavored relative to one with clean semantics. **The opcode budget is design insurance that compounds over time.** / **封じ込めとしての予約オペコードスロット。** 12個の未使用オペコードスロットは「将来何が必要になっても利用可能」ではない——それらは、新しいオペコードはAI親和性基準に対して追加を正当化しなければならないという明示的な意図とともに*予約されている*。意味論がLLMの複雑な曖昧性除去を要求する候補オペコードは、明確な意味論を持つものに対して不利となる。**オペコード予算は時間とともに複利化する設計保険である。**

**The Layer 2 traces as empirical evidence.** The PTSG-Core repository's `02_Reasoning_Traces/` contains dialogues between the architect and LLM collaborators in which the AI-affinity is demonstrated directly: AI collaborators rapidly grasp PTSG's structure, articulate hypotheses about it, and produce candidate instruction sequences without periodically pausing to disambiguate basic semantics. The two inaugural traces (`2026-05-12_ptsg-emancipation-from-wpms-session.md` and `2026-05-13_ptsg-strategic-positioning.md`) provide the first documented evidence; subsequent contributed traces will accumulate further evidence (or counter-evidence) over time.

**経験的証拠としてのLayer 2軌跡。** PTSGコアリポジトリの `02_Reasoning_Traces/` には、アーキテクトとLLM協働者間の対話が含まれており、AI親和性が直接実証されている: AI協働者は基本的意味論を曖昧性除去するために定期的に立ち止まることなく、PTSGの構造を急速に把握し、それについての仮説を明確化し、候補命令シーケンスを生成する。二つの最初の軌跡(`2026-05-12_ptsg-emancipation-from-wpms-session.md` および `2026-05-13_ptsg-strategic-positioning.md`)は最初の文書化された証拠を提供する；後続の貢献された軌跡は時間とともにさらなる証拠(または反証拠)を蓄積する。

**The AI-affinity claim is falsifiable.** This is important. If subsequent attempts to use PTSG with LLM collaborators reveal that the design is in fact difficult for LLMs to reason about — that hallucination rates are high, that LLMs systematically misread instruction sequences, that LLM-generated instruction lists frequently fail to compile in PTSG simulators — that would constitute counter-evidence against the AI-affinity claim. The PTSG-Core specification would then need to be revisited. Until such counter-evidence accumulates, the AI-affinity claim is treated as a working hypothesis supported by the early dialogues.

**AI親和性の主張は反証可能である。** これは重要である。後続のLLM協働者とのPTSG使用試行が、設計が実際にはLLMにとって推論困難であることを明らかにした場合——幻覚率が高い、LLMが命令シーケンスを体系的に誤読する、LLMが生成した命令リストがPTSGシミュレータで頻繁にコンパイル失敗する——それはAI親和性の主張に対する反証拠を構成するであろう。PTSGコア仕様はその時、再検討される必要がある。そのような反証拠が蓄積するまで、AI親和性の主張は初期の対話によって支持された作業仮説として扱われる。

**Implication for Core evolution.** The AI-affinity criterion functions as a brake on opcode-budget consumption. A future engineer proposing to add a fifth opcode must articulate why the addition does not degrade AI legibility — not merely why the addition is *technically* desirable. The 12 reserved slots are not a license to grow; they are room held in reserve for cases where growth is unambiguously justified.

**コア進化への含意。** AI親和性基準はオペコード予算消費に対するブレーキとして機能する。第5のオペコードを追加することを提案する未来のエンジニアは、追加がAI判読可能性を低下させない理由を明確化しなければならない——単に追加が*技術的に*望ましい理由ではない。12個の予約スロットは成長への許可ではない；成長が曖昧性なく正当化される場合のために予備として保持された部屋である。

---

## 1.8 Design Philosophy — Educational Origin and Pedagogical Commitment / 設計哲学 — 教育的起源と教育的コミットメント

**The principle.** PTSG was originally conceived in part as an answer to a pedagogical question: *what should FPGA introduction look like, if not counter-Lチカ?* The Core's design is shaped by that origin, and the project's documentation makes a corresponding commitment: PTSG should be accessible to FPGA beginners not merely after they have learned FSM design, but **as a first encounter** with FPGA development.

**原理。** PTSGは元々、部分的に教育的問いへの答えとして構想された: *もしカウンタLチカでないなら、FPGA入門はどう見えるべきか?* コアの設計はその起源によって形作られ、プロジェクトの文書化は対応するコミットメントを行う: PTSGはFSM設計を学んだ後ではなく、**FPGA開発との最初の出会い**として、FPGA初心者にアクセス可能であるべきである。

**The three structural problems with counter-Lチカ.** The dominant FPGA introduction has the learner write a multi-bit counter, derive a divided clock from one of its bits, and route that to an LED. This works pedagogically only to a point:

**カウンタLチカの三つの構造的問題。** 支配的なFPGA入門は、学習者にマルチビットカウンタを書かせ、そのビットの一つから分周クロックを導き、それをLEDに経路づけさせる。これは教育的に、ある程度までしか機能しない:

- **Black-box opacity.** A 24-bit counter is, in normal operation, completely opaque to the beginner. Its state cycles 16 million times per LED transition. Nothing about the counter's *behavior* is observable except the final divided clock — the learner cannot inspect any intermediate phenomenon. The exercise teaches them to write counters; it teaches them little about what is happening inside the FPGA. / **ブラックボックス不透明性。** 24ビットカウンタは通常動作において、初心者にとって完全に不透明である。その状態はLED遷移毎に1600万回サイクルする。カウンタの*挙動*については、最終的な分周クロック以外何も観察可能ではない——学習者はいかなる中間現象も検査できない。演習は彼らにカウンタの書き方を教える；FPGAの内部で何が起こっているかについては、ほとんど教えない。

- **The FSM cliff.** The path from counter-Lチカ to anything substantially more sophisticated is a cliff, not a slope. To express any conditional behavior, any sequence, any interaction with external signals, the learner must jump directly into FSM design — with its state diagrams, transition tables, encoding strategies, and the conceptual overhead of thinking simultaneously about states and times. There is no intermediate stage; the learner who has just finished counter-Lチカ is not prepared for the FSM landing. / **FSMの崖。** カウンタLチカから何か実質的により洗練されたものへの経路は、斜面ではなく崖である。任意の条件的挙動、任意のシーケンス、外部信号との任意の相互作用を表現するには、学習者はFSM設計に——その状態図、遷移テーブル、エンコーディング戦略、そして状態と時間を同時に考える概念的オーバーヘッドとともに——直接ジャンプしなければならない。中間段階はない；カウンタLチカを終えたばかりの学習者はFSM着地の準備ができていない。

- **Satisfaction without trajectory.** "The LED blinks" is a satisfying outcome, but it is also a terminal outcome — it does not invite the learner toward any specific next step. The satisfaction is fleeting and self-contained. Once the LED has blinked, the next obvious activity is "blink a different LED" or "blink the LED faster," neither of which deepens understanding. / **軌跡なき満足。** 「LEDが点滅する」は満足できる結果だが、それは終端的結果でもある——それは学習者を特定の次のステップに招かない。満足は刹那的で自己完結的である。LEDが一度点滅した後、次の明白な活動は「別のLEDを点滅させる」または「LEDをより速く点滅させる」だが、どちらも理解を深めない。

**The PTSG resolution of all three.** PTSG addresses each problem directly:

**PTSGによる三つすべての解決。** PTSGは各問題に直接対処する:

- **Observable end-to-end.** A PTSG instruction list is small enough that the entire program is on one screen. Every state of execution is visible: the current State Number can be displayed, the stay counter can be displayed, the timing signals can be wired to LEDs or to a logic analyzer. The learner sees what the system is doing because every quantity that affects behavior is exposed. / **エンドツーエンドで観察可能。** PTSG命令列は、プログラム全体が一画面に収まるほど小さい。実行のすべての状態は可視である: 現在のステートナンバーは表示可能、ステイカウンタは表示可能、タイミング信号はLEDまたはロジックアナライザに配線可能。挙動に影響するすべての量が露出されているため、学習者はシステムが何をしているかを見る。

- **Gradual path forward.** The learner's first PTSG program might be a 4-state instruction list that blinks an LED — but the path from there to more sophisticated behavior is gradual: add a Stay duration, add a second timing signal, add a Condition for an external input, add a Branch, add a sub-sequence, add an external register write. Each step adds one feature; no step requires the conceptual leap that FSM design demands. / **段階的な前進経路。** 学習者の最初のPTSGプログラムは、LEDを点滅させる4ステートの命令列かもしれない——しかしそこからより洗練された挙動への経路は段階的である: Stay持続時間を加える、第二のタイミング信号を加える、外部入力のためのConditionを加える、Branchを加える、サブシーケンスを加える、外部レジスタ書き込みを加える。各ステップは一つの機能を加える；どのステップもFSM設計が要求する概念的飛躍を要求しない。

- **Satisfaction with trajectory.** "I made the LED blink with PTSG" arrives with a trajectory built in: the same instruction list can be modified, by changing one instruction at a time, into something genuinely useful (a serial protocol, a sensor reader, an actuator controller). The first satisfaction is the entry point of a path, not its end. / **軌跡を伴う満足。** 「PTSGでLEDを点滅させた」は組み込まれた軌跡とともに到来する: 同じ命令列が、一度に一つの命令を変えることで、本当に有用な何か(シリアルプロトコル、センサリーダー、アクチュエータコントローラ)に変更できる。最初の満足は経路の入口であり、終わりではない。

**The three-layer engagement model.** PTSG's small size enables a learner to engage at three different depths *simultaneously*: **Layer A** — write instruction lists (beginner-accessible, AI-easy); **Layer B** — design the external Condition logic and external registers (intermediate-level FPGA engineering); **Layer C** — read the PTSG-Core implementation itself (computer architecture education). These are not a sequential curriculum where the learner advances from A to B to C; they are *simultaneously accessible* because the whole system is small enough to fit in mind at once. **A learner can write an instruction list (A), peek at the external register implementation that the instruction list drives (B), and trace what is happening inside the Core (C) — all in the same hour.**

**三層関与モデル。** PTSGの小さなサイズは、学習者が三つの異なる深さで*同時に*関与することを可能にする: **A層**——命令リストを書く(初心者アクセス可能、AI容易); **B層**——外部Conditionロジックと外部レジスタを設計する(中級FPGAエンジニアリング); **C層**——PTSGコア実装自体を読む(コンピュータアーキテクチャ教育)。これらはAからBへCへ学習者が進む順次的カリキュラムではない；システム全体が一度に心に収まるほど小さいため、それらは*同時にアクセス可能*である。**学習者は命令リストを書き(A)、その命令リストが駆動する外部レジスタの実装を覗き(B)、コア内部で起こっていることを追跡する(C)ことを——すべて同じ一時間以内に——できる。**

**The pedagogical commitment, made explicit.** PTSG-Core's documentation is designed to support all three layers of engagement simultaneously. This Layer 1 chapter is written to be readable by a learner at the A level (understanding what PTSG does is enough); subsequent chapters are written to support B-level (designing Formation logic) and C-level (understanding internals and implementing the Core). The commitment is that no chapter assumes the reader has already advanced beyond the others — readers may enter at any layer and proceed in any order.

**明示的な教育的コミットメント。** PTSGコアの文書化は、関与の三層すべてを同時にサポートするよう設計されている。本第1層章はAレベル(PTSGが何をするかを理解すれば十分)の学習者によって読まれるよう書かれている；後続の章はBレベル(フォーメーションロジックの設計)とCレベル(内部の理解とコアの実装)をサポートするよう書かれている。コミットメントは、いかなる章も読者が既に他の章を超えて進んでいることを想定しないということである——読者は任意の層から入り、任意の順序で進むことができる。

---

## 1.9 Core-Formation Separation / コア-フォーメーション分離

**The pattern.** PTSG is distributed as two tiers of repositories: the **Core** (this repository), which defines the instruction set, the memory layout, the sub-opcode architecture, and the external interface contract — these are invariant and expected to evolve slowly; and **Formations** (`PTSG_<Purpose>_Formation_OpenPrompt` repositories), which build atop the Core with application-specific external register layouts, Condition logic, work memory contents, and timing-signal assignments — these are application-specific and freely divergent.

**パターン。** PTSGはリポジトリの二層として配布される: **コア**(本リポジトリ)は命令セット、メモリレイアウト、サブオペコードアーキテクチャ、外部インターフェース契約を定義する——これらは不変であり、ゆっくり進化することが期待される；そして**フォーメーション**(`PTSG_<目的>_Formation_OpenPrompt` リポジトリ)は応用固有の外部レジスタレイアウト、Conditionロジック、ワークメモリ内容、タイミング信号配置でコアの上に構築する——これらは応用固有であり、自由に分岐する。

**Formations are not required to be binary-compatible with each other.** This is a deliberate departure from conventional CPU-architecture culture. Two different Formations of PTSG — say, a `PTSG_I2C_Formation_OpenPrompt` and a `PTSG_MIDI_Formation_OpenPrompt` — will typically assign different external registers to different addresses, use different Condition signal meanings, route timing signals to different pins, and use different work memory layouts. **Instruction sequences written for one Formation are not expected to run on another.** The Core's instruction-set vocabulary (4 opcodes, 16 timing signals, Condition, State Number) is what stays invariant across Formations; everything else is per-Formation.

**フォーメーションは互いにバイナリ互換であることを要求されない。** これは従来のCPUアーキテクチャ文化からの意図的な逸脱である。PTSGの二つの異なるフォーメーション——例えば `PTSG_I2C_Formation_OpenPrompt` と `PTSG_MIDI_Formation_OpenPrompt`——は典型的に、異なる外部レジスタを異なるアドレスに割り当て、異なるCondition信号の意味を用い、異なるピンにタイミング信号を経路づけ、異なるワークメモリレイアウトを用いる。**一つのフォーメーション用に書かれた命令シーケンスは、別のフォーメーションで動作することを期待されない。** フォーメーション間で不変に留まるのはコアの命令セット語彙(4オペコード、16タイミング信号、Condition、ステートナンバー)である；他のすべてはフォーメーション別である。

**Why no required binary compatibility.** The historical case for binary compatibility — IBM 360, x86 ABI stability, JVM portability — rests on the premise that human-written code is expensive and must be preserved across hardware variations. **When AI agents author instruction sequences for each new Formation, that premise weakens substantially.** Generating fresh, Formation-specific instruction sequences for each new application becomes economically rational. Freed from the obligation to maintain cross-Formation binary compatibility, each Formation can optimize aggressively for its specific application — different external registers, different Condition meanings, different timing-signal routings. **This is one of the load-bearing claims of PTSG's positioning as a proposal for AI-era processor architecture.** (Detailed in the Layer 2 strategic-positioning trace.)

**なぜバイナリ互換性を要求しないか。** バイナリ互換性の歴史的根拠——IBM 360、x86 ABI安定性、JVM可搬性——は、人間が書いたコードは高価であり、ハードウェアの変動を超えて保存されなければならないという前提に依拠している。**AIエージェントが各新フォーメーションのために命令シーケンスを作成する場合、その前提は相当に弱まる。** 各新応用のために新鮮でフォーメーション固有な命令シーケンスを生成することは経済的に合理的になる。フォーメーション間バイナリ互換性を維持する義務から解放され、各フォーメーションは特定の応用のために積極的に最適化できる——異なる外部レジスタ、異なるCondition意味、異なるタイミング信号経路。**これはAI時代のプロセッサアーキテクチャ提案としてのPTSGの位置づけにおける、荷重を支える主張の一つである。** (第2層戦略的位置づけ軌跡で詳述。)

**The shared genetic code metaphor.** A useful way to think about the Core-Formation relationship: the Core's instruction set is the **shared genetic code** of the ecosystem; each Formation is a **phenotype expressed from that code** under the constraints of its specific application environment. Two Formations may look very different at the phenotype level — one running motors, one decoding network protocols — but they share the deep structural code. When a new Formation is created, the Core's vocabulary is what makes the new Formation *recognizably PTSG* even before anyone reads its specific external register assignments.

**共有遺伝コードのメタファー。** コア-フォーメーション関係を考える有用な方法: コアの命令セットはエコシステムの**共有遺伝コード**である；各フォーメーションは特定の応用環境の制約の下で**そのコードから発現される表現型**である。二つのフォーメーションは表現型レベルで非常に異なって見えるかもしれない——一つはモータを動かし、一つはネットワークプロトコルをデコードする——しかし彼らは深い構造的コードを共有する。新しいフォーメーションが作られる時、コアの語彙が、その特定の外部レジスタ割り当てを誰も読む前に、新しいフォーメーションを*それと認識できるほどPTSG*にするものである。

**Implications for documentation.** This Core repository documents only Core matters. Specific external register layouts for any application — including the WPMS application that motivated PTSG's emancipation from the FPGA Spectrum Engine project — live in the respective Formation repositories. Cross-references will be added to the Core README as Formations are published. **The Core specification must not be enlarged by Formation-specific concerns, no matter how compelling those concerns are in their own context.**

**文書化への含意。** 本コアリポジトリはコアに関する事柄のみを文書化する。任意の応用の特定の外部レジスタレイアウト——FPGA Spectrum EngineプロジェクトからのPTSGの解放を動機付けたWPMS応用を含む——はそれぞれのフォーメーションリポジトリに存在する。フォーメーションが公開されるにつれ、相互参照がコアREADMEに追加される。**コア仕様は、いかにそれらの懸念がそれら自身の文脈で説得力があろうとも、フォーメーション固有の懸念によって肥大化されてはならない。**

---

## 1.10 Relationship to FPGA Spectrum Engine / FPGA Spectrum Engine との関係

PTSG is the second Open Prompt repository. The first is **FPGA Spectrum Engine** ([Hackaday.io](https://hackaday.io/project/205582-fpga-spectrum-engine)), an FPGA-based audio synthesis project that established the Open Prompt methodology and the three-layer (Architecture / Reasoning Traces / Sample Implementations) repository structure that PTSG-Core also follows.

PTSGは2番目のOpen Promptリポジトリである。最初のものは**FPGA Spectrum Engine**([Hackaday.io](https://hackaday.io/project/205582-fpga-spectrum-engine))であり、Open Prompt方法論と、PTSGコアも従う三層(アーキテクチャ／推論軌跡／サンプル実装)リポジトリ構造を確立したFPGAベースのオーディオ合成プロジェクトである。

**The spin-off origin.** PTSG was originally conceived as the sequence-modulation pipeline processor for the Spectrum Engine's WPMS (Wave Packet Modulation Synthesis) Synthesizer — Spectrum Engine's first deliverable. During the WPMS Layer 1 specification work in early May 2026, the architect and his AI collaborator recognized that PTSG was too general-purpose to remain a sub-component of WPMS; the decision was made to spin PTSG off as an independent Open Prompt project. The spin-off dialogue itself is recorded in PTSG-Core's `02_Reasoning_Traces/2026-05-12_ptsg-emancipation-from-wpms-session.md`.

**暖簾分けの起源。** PTSGは元々、Spectrum EngineのWPMS(Wave Packet Modulation Synthesis)シンセサイザー——Spectrum Engineの最初の成果物——のための数列変調パイプラインプロセッサとして構想された。2026年5月初頭のWPMS第1層仕様作業中、アーキテクトとそのAI協働者は、PTSGがWPMSのサブコンポーネントとして留まるには汎用すぎることを認識した；PTSGを独立Open Promptプロジェクトとして暖簾分けする決定がなされた。暖簾分け対話自体はPTSGコアの `02_Reasoning_Traces/2026-05-12_ptsg-emancipation-from-wpms-session.md` に記録されている。

**The architectural inversion.** Prior to the spin-off, the implicit model was "Spectrum Engine is the project; PTSG is a sub-component." After the spin-off, the architectural relationship has been understood more precisely: **PTSG is the more general primitive; Spectrum Engine is one application of PTSG (via the WPMS Formation).** This inversion does not diminish Spectrum Engine — it remains a fully-formed Open Prompt project with its own Layer 1, Layer 2, and Layer 3, and it retains its status as the inaugural Open Prompt repository. What changes is the *direction of dependency*: Spectrum Engine **uses** the WPMS Formation of PTSG, which **builds atop** the PTSG Core.

**アーキテクチャ的反転。** 暖簾分け以前、暗黙のモデルは「Spectrum Engineがプロジェクトであり；PTSGがサブコンポーネントである」であった。暖簾分け以後、アーキテクチャ的関係はより正確に理解された: **PTSGがより一般的なプリミティブであり；Spectrum EngineはPTSGの一つの応用である(WPMSフォーメーション経由)。** この反転はSpectrum Engineを矮小化しない——それは独自のLayer 1、Layer 2、Layer 3を持つ完全に形成されたOpen Promptプロジェクトであり続け、最初のOpen Promptリポジトリの地位を保持する。変わるのは*依存関係の方向*である: Spectrum EngineはPTSGのWPMSフォーメーションを**使う**、それはPTSGコアの**上に構築**される。

**The first Formation.** The first Formation under development is **`PTSG_WPMS_Formation_OpenPrompt`** — the WPMS Formation that will serve as the sequence-modulation pipeline processor in the WPMS Synthesizer. This Formation is currently being designed in a separate Claude session (per the session-separation discipline documented in the technical-emancipation trace) and, when stable, will be handed off to the WPMS development session for use in WPMS Chapter 3 drafting.

**最初のフォーメーション。** 開発中の最初のフォーメーションは**`PTSG_WPMS_Formation_OpenPrompt`**——WPMSシンセサイザーにおける数列変調パイプラインプロセッサとして奉仕するWPMSフォーメーションである。本フォーメーションは現在、別個のClaudeセッションで設計されており(技術的解放トレースに文書化されたセッション分離規律に従う)、安定すれば、WPMS第3章起草で使用するためにWPMS開発セッションに引き渡される。

**Anticipated subsequent Formations.** Other Formations have been anticipated but not yet started: `PTSG_I2C_Formation_OpenPrompt`, `PTSG_MIDI_Formation_OpenPrompt`, `PTSG_SDRAM_Formation_OpenPrompt`, `PTSG_DataFlow_Formation_OpenPrompt`, `PTSG_RealtimeControl_Formation_OpenPrompt`. None of these is a commitment by the original author; they are listed as natural application domains where Formations would be valuable. Community members are welcome to author any of these Formations as independent Open Prompt repositories.

**予期される後続フォーメーション。** 他のフォーメーションは予期されているがまだ開始されていない: `PTSG_I2C_Formation_OpenPrompt`、`PTSG_MIDI_Formation_OpenPrompt`、`PTSG_SDRAM_Formation_OpenPrompt`、`PTSG_DataFlow_Formation_OpenPrompt`、`PTSG_RealtimeControl_Formation_OpenPrompt`。これらのいずれもオリジナル著者によるコミットメントではない；それらはフォーメーションが価値ある自然な応用ドメインとして列挙されている。コミュニティメンバーがこれらのいずれかを独立Open Promptリポジトリとして作成することを歓迎する。

**The Webapp PTSG simulator.** One longer-term ecosystem element deserves explicit mention: a hypothetical Webapp PTSG simulator (executing instruction lists in-browser, visualizing timing signals and state transitions) is recognized as **strategic infrastructure** for the PTSG ecosystem, not merely a convenience. The reason: without a simulator, AI agents writing PTSG instruction sequences must rely on human-in-the-loop FPGA synthesis to verify behavior. With a simulator, the AI agent can write → simulate → observe → iterate entirely within its own execution loop. **This closes the feedback loop that has so far prevented AI agents from autonomously developing FPGA designs.** The simulator is documented as a future ecosystem element in the Layer 2 strategic-positioning trace, where its architectural requirements are discussed.

**Webapp PTSGシミュレータ。** より長期的なエコシステム要素の一つが明示的言及に値する: 仮想的なWebapp PTSGシミュレータ(命令リストをブラウザ内で実行し、タイミング信号とステート遷移を可視化する)は、単なる便利さではなく、PTSGエコシステムのための**戦略的インフラ**として認識される。理由: シミュレータなしでは、PTSG命令シーケンスを書くAIエージェントは挙動を検証するために人間介在ループのFPGA合成に依存しなければならない。シミュレータがあれば、AIエージェントは書く→シミュレートする→観察する→反復するを完全に自身の実行ループ内で行える。**これは、これまでAIエージェントがFPGA設計を自律的に発展させることを妨げてきたフィードバックループを閉じる。** シミュレータは第2層戦略的位置づけ軌跡で将来のエコシステム要素として文書化され、そこでそのアーキテクチャ要件が議論される。

---

## 1.11 What is NOT in this Layer 1 Document / 本第1層文書に含まれないもの

To make the boundary unambiguous:

境界を曖昧でなくするために:

- **Detailed memory layout and instruction word bit assignments.** The 32-bit instruction word's bit-level structure, the precise semantics of each opcode and operand, and the layout of internal control registers are specified in **Chapter 2**. This chapter establishes only that there are 4 opcodes and that the instruction word has the opcode/operand/timing-signal partition. / **詳細なメモリレイアウトと命令語ビット配置。** 32ビット命令語のビットレベル構造、各オペコードとオペランドの正確な意味論、内部制御レジスタのレイアウトは**第2章**で指定される。本章は4つのオペコードがあり、命令語がオペコード／オペランド／タイミング信号のパーティションを持つことのみを確立する。

- **Sub-opcode architecture and background-execution mechanics.** The sub-opcode decoding of operand bits D4-D7 under the Global opcode, the timing of background command execution during Stay, the minimum-stay-count rules for multi-clock background operations, and the internal information-holding register / external stack memory protocols are specified in **Chapter 3**. / **サブオペコードアーキテクチャと裏実行機構。** GlobalオペコードでのオペランドビットD4-D7のサブオペコードデコーディング、Stay中の裏コマンド実行のタイミング、複数クロック裏操作のための最低ステイカウント規則、内部情報保持レジスタ／外部スタックメモリプロトコルは**第3章**で指定される。

- **Indirect addressing and prescaler.** The literal-zero-as-escape convention for indirect addressing of loop count / stay length / absolute jump address via external registers, and the prescaler mechanism for extending stay-count range, are specified in **Chapter 4**. / **間接アドレッシングとプリスケーラ。** ループ回数／ステイ長／絶対ジャンプアドレスを外部レジスタで指定するための「直値ゼロをエスケープとする」慣習、およびステイカウント範囲を拡張するプリスケーラ機構は**第4章**で指定される。

- **External interface signal-level contract.** The signal-level contract between PTSG-Core and external logic — exact widths, timing relationships, handshake protocols for external register access — is specified in **Chapter 5**. / **外部インターフェース信号レベル契約。** PTSGコアと外部ロジックの間の信号レベル契約——正確な幅、タイミング関係、外部レジスタアクセスのためのハンドシェイクプロトコル——は**第5章**で指定される。

- **Multi-PTSG coordination protocols.** Synchronization primitives, signaling conventions, and shared memory access protocols for multiple PTSG cores coexisting on the same FPGA are deferred to a future **Chapter 6**, to be drafted as multi-PTSG applications mature. / **複数PTSG協調プロトコル。** 同じFPGA上に共存する複数のPTSGコアのための同期プリミティブ、シグナリング慣習、共有メモリアクセスプロトコルは、複数PTSG応用が成熟するにつれて起草される将来の**第6章**に繰り延べられる。

- **Specific implementations.** Verilog/VHDL code, testbench harnesses, instruction-list examples, and simulator code live in **Layer 3** (`03_Sample_Implementations/`) and are released under the MIT License (not CC0). They are illustrative reference points, not normative specifications. A regenerated implementation produced from this Layer 1 plus the Layer 2 traces is *not* a derivative work of the Layer 3 samples; the regenerator owns their implementation outright. (See `LICENSE_OpenPrompt.md`.) / **特定の実装。** Verilog/VHDLコード、テストベンチハーネス、命令リスト例、シミュレータコードは**Layer 3**(`03_Sample_Implementations/`)に存在し、MITライセンスで(CC0ではなく)公開される。それらは例示的なリファレンスポイントであり、規範的仕様ではない。本第1層と第2層軌跡から再生成された実装は、第3層サンプルの派生物では*ない*；再生成者はその実装を完全に所有する。(`LICENSE_OpenPrompt.md`参照。)

- **Per-Formation external register layouts, Condition logic, work memory contents, and timing-signal assignments.** These are the defining content of Formation repositories. The first Formation under design — `PTSG_WPMS_Formation_OpenPrompt` — will publish its own Layer 1 specification covering these matters for the WPMS use case. Other Formations will do the same for their respective application domains. **None of this is in PTSG-Core.** / **フォーメーション別の外部レジスタレイアウト、Conditionロジック、ワークメモリ内容、タイミング信号配置。** これらはフォーメーションリポジトリの定義的内容である。設計中の最初のフォーメーション——`PTSG_WPMS_Formation_OpenPrompt`——はWPMS用途のためにこれらの事項をカバーする独自のLayer 1仕様を公開する。他のフォーメーションは彼らそれぞれの応用ドメインに対して同じことを行う。**これらのいずれもPTSGコアに含まれない。**

- **WPMS-side requirements on PTSG (R1–R7 / W1–W2).** During the WPMS Layer 1 specification work, an explicit list of WPMS-side requirements and wishes for PTSG was generated (recorded in the technical-emancipation trace `02_Reasoning_Traces/2026-05-12_ptsg-emancipation-from-wpms-session.md`). These are *not* part of PTSG-Core; they are inputs to the future `PTSG_WPMS_Formation_OpenPrompt` repository design. They are mentioned here only so that the boundary is explicit. / **PTSGへのWPMS側からの要件(R1–R7／W1–W2)。** WPMS第1層仕様作業中、PTSGへのWPMS側要件と要望の明示的リストが生成された(技術的解放トレース `02_Reasoning_Traces/2026-05-12_ptsg-emancipation-from-wpms-session.md` に記録)。これらはPTSGコアの一部では*ない*；将来の `PTSG_WPMS_Formation_OpenPrompt` リポジトリ設計への入力である。境界が明示的であるよう、ここでのみ言及される。

- **HDL toolchain / vendor-specific synthesis settings.** Quartus settings, Vivado constraints, board-specific pin assignments, and similar implementation-environment matters are not in this Layer 1 specification. They are properly the concern of Layer 3 sample implementations and per-implementation README files. / **HDLツールチェーン／ベンダー固有合成設定。** Quartus設定、Vivado制約、ボード固有ピン割り当て、および類似の実装環境事項は本第1層仕様に含まれない。それらは第3層サンプル実装と実装毎のREADMEファイルの懸念として然るべきものである。

---

## 1.12 Open Questions Carried Forward to Subsequent Chapters / 後続章へ持ち越される未解決問題

The following are deliberately left unresolved in this chapter and will be addressed in subsequent chapters of this Layer 1 specification, or in associated Layer 2 traces:

以下は意図的に本章で未解決のまま残され、本第1層仕様の後続章、または関連する第2層軌跡で扱われる:

| Question | Deferred to |
|---|---|
| Detailed semantics of each of the 4 currently-defined opcodes (Global / Stay / Branch / Jump) — including the "true means no-branch" convention's exact treatment / 現在定義されている4オペコード(Global/Stay/Branch/Jump)各々の詳細意味論——「成立で不分岐」慣習の正確な扱いを含む | Chapter 2 / 第2章 |
| Bit-level layout of the 32-bit instruction word, including opcode encoding, operand encoding, timing-signal D16-D31 / オペコードエンコーディング、オペランドエンコーディング、タイミング信号D16-D31を含む、32ビット命令語のビットレベルレイアウト | Chapter 2 / 第2章 |
| Sub-opcode decoding mechanism for the Global opcode (D4-D7 = 0 vs D4-D7 = 1..F), and the canonical sub-opcode 1 for external register write / Globalオペコードのサブオペコードデコーディング機構(D4-D7 = 0 対 D4-D7 = 1..F)、および外部レジスタ書き込みのための標準サブオペコード1 | Chapter 3 / 第3章 |
| Background-execution semantics: timing of execution start, minimum-stay-count rules for multi-clock background operations, ordering guarantees when multiple background operations are chained / 裏実行意味論: 実行開始のタイミング、複数クロック裏操作のための最低ステイカウント規則、複数の裏操作が連鎖される時の順序保証 | Chapter 3 / 第3章 |
| Internal information-holding register / external stack memory protocols for nested sub-sequence calls and interrupt-style insertion / ネストされたサブシーケンスコールと割り込みスタイル挿入のための内部情報保持レジスタ／外部スタックメモリプロトコル | Chapter 3 / 第3章 |
| Literal-zero-as-escape convention for indirect addressing — its application to loop count, stay length, absolute jump address — including the address-0 special case for jump indirect-mode / 間接アドレッシングのための直値ゼロエスケープ慣習——ループ回数、ステイ長、絶対ジャンプアドレスへの適用——ジャンプ間接モードのアドレス0特殊ケースを含む | Chapter 4 / 第4章 |
| Prescaler placement and control — compile-time fixed vs runtime-configurable vs per-stay selectable vs multiple-parallel — recorded as Tie at the Implementation Arena level / プリスケーラの配置と制御——コンパイル時固定 対 実行時設定可能 対 ステイ毎選択可能 対 複数並列——Implementation Arenaレベルでの引き分けとして記録 | Chapter 4 / 第4章 |
| External register access bus widths, atomicity guarantees during concurrent multi-register updates, handshake protocols with external register modules / 外部レジスタアクセスバス幅、同時複数レジスタ更新中のアトミック性保証、外部レジスタモジュールとのハンドシェイクプロトコル | Chapter 5 / 第5章 |
| Multi-PTSG coordination — rendezvous, producer-consumer, broadcast — and what (if any) Core-level instruction support these require versus what is left to external logic / 複数PTSG協調——ランデブー、プロデューサー-コンシューマー、ブロードキャスト——およびこれらがどの(もしあれば)コアレベル命令サポートを要求するか対外部ロジックに残されるか | Chapter 6 (future) / 第6章(将来) |
| Promotion criteria for moving a frequently-used sub-opcode from inside Global to its own top-level opcode (using one of the 12 reserved slots) — what thresholds (usage frequency, semantic clarity, AI-affinity, Formation coverage) should apply / 頻繁に使用されるサブオペコードをGlobal内部から独自のトップレベルオペコードに昇格させるための基準(12個の予約スロットの一つを使用)——どの閾値(使用頻度、意味論的明確性、AI親和性、フォーメーションカバレッジ)が適用されるべきか | Future Layer 2 trace, by way of resumption Hook B in `2026-05-13_ptsg-strategic-positioning.md` / 将来の第2層軌跡、`2026-05-13_ptsg-strategic-positioning.md` の再開フックBを介して |
| Webapp PTSG simulator API and verification protocol / Webapp PTSGシミュレータAPIと検証プロトコル | Future Layer 2 trace, by way of resumption Hook A in `2026-05-13_ptsg-strategic-positioning.md` / 将来の第2層軌跡、`2026-05-13_ptsg-strategic-positioning.md` の再開フックAを介して |
| Reference-implementation HDL, testbench, build flow, simulator code / リファレンス実装HDL、テストベンチ、ビルドフロー、シミュレータコード | Layer 3, separate documents under `03_Sample_Implementations/` / 第3層、`03_Sample_Implementations/` 配下の別個の文書 |

---

## 1.13 Summary of Chapter 1 Decisions / 第1章決定事項のまとめ

| ID | Decision | Status |
|---|---|---|
| C1-D1 | PTSG is documented as a Layer 1 specification with subsequent chapters (Chapters 2–5, future 6) specifying technical details / PTSGは後続章(第2-5章、将来の第6章)が技術的詳細を指定する第1層仕様として文書化される | Fixed / 確定 |
| C1-D2 | PTSG-Core's defining content: instruction set, memory layout, sub-opcode architecture, external interface contract — and nothing else / PTSGコアの定義的内容: 命令セット、メモリレイアウト、サブオペコードアーキテクチャ、外部インターフェース契約——そしてそれ以外何もない | Fixed / 確定 |
| C1-D3 | Five essential properties: time/space axis separation, the Trailing-Edge Doctrine (timing rigor), Condition externalization, background execution during Stay, AI-affinity as primary design property / 五つの本質的特性: 時間／空間軸分離、後縁主義(タイミング厳格性)、Conditionの外部化、Stay中の裏実行、一次設計属性としてのAI親和性 | Fixed / 確定 (v1.1) |
| C1-D4 | Condition input is 1 bit, externally generated. All conditional complexity lives in external Condition logic, not in the Core / Condition入力は1ビット、外部生成。すべての条件的複雑性はコアではなく外部Conditionロジックに存在する | Fixed / 確定 |
| C1-D5 | Branch convention: branch when Condition fails; advance to next state when Condition is true ("true means no-branch") / Branch慣習: Condition不成立で分岐；Condition成立で次ステートへ進む(「成立で不分岐」) | Fixed / 確定 |
| C1-D6 | Opcode budget: 4 of 16 slots used; 12 reserved as design insurance against unknowable future needs. AI-affinity criterion governs use of reserved slots / オペコード予算: 16スロットのうち4個を使用；12個は未知な将来の必要に対する設計保険として予約。AI親和性基準が予約スロットの使用を統治する | Fixed / 確定 |
| C1-D7 | Core-Formation separation pattern: Core invariant, Formations freely divergent. No required binary compatibility across Formations / コア-フォーメーション分離パターン: コアは不変、フォーメーションは自由に分岐。フォーメーション間でバイナリ互換性は要求されない | Fixed / 確定 |
| C1-D8 | PTSG positioned as a replacement for counter-based FPGA introduction, not a follow-on / PTSGは後続トピックではなく、カウンタベースのFPGA入門の置き換えとして位置づけられる | Fixed / 確定 |
| C1-D9 | Three-layer engagement model (Layer A: write instruction lists; Layer B: design external logic; Layer C: read Core implementation) — accessible simultaneously, not as sequential curriculum / 三層関与モデル(A層: 命令リストを書く；B層: 外部ロジックを設計；C層: コア実装を読む)——順次的カリキュラムではなく同時にアクセス可能 | Fixed / 確定 |
| C1-D10 | Anti-coupling with specific applications: PTSG-Core contains no application-specific content; WPMS-side requirements R1–R7/W1–W2 are deferred to `PTSG_WPMS_Formation_OpenPrompt` / 特定応用との非結合: PTSGコアは応用固有内容を含まない；WPMS側要件 R1–R7/W1–W2 は `PTSG_WPMS_Formation_OpenPrompt` に繰り延べられる | Fixed / 確定 |
| C1-D11 | Architectural relationship with FPGA Spectrum Engine: PTSG is the more general primitive; Spectrum Engine (via its WPMS Formation) is one application of PTSG / FPGA Spectrum Engineとのアーキテクチャ的関係: PTSGがより一般的なプリミティブ；Spectrum Engine(そのWPMSフォーメーション経由)がPTSGの一つの応用 | Fixed / 確定 |
| C1-D12 | Layer 1 specification is implementation-neutral; Layer 3 samples are illustrative not normative; regenerated implementations are independent works, not derivatives of samples / 第1層仕様は実装中立；第3層サンプルは規範的ではなく例示的；再生成された実装はサンプルの派生物ではなく独立著作物である | Fixed / 確定 |
| C1-D13 (v1.1) | The Trailing-Edge Doctrine (§ 1.4a): all state is determined by the trailing edge of every boundary so the leading edge is settled; recursive to the clock (EDGE=NEG); nested loop→stay→prescaler→clock hierarchy; derives C4-F8/F9/F10 and the trailing-edge resolution of queued firing (C4-T3 → C4-F11); principled exceptions are foreground StaySet and Reset (leading-edge-placed, depending on the preceding command ending on a trailing edge) / 後縁主義(§ 1.4a): あらゆる境界の後縁までに全状態を確定し前縁を静定させる；クロックまで再帰(EDGE=NEG)；ループ→ステイ→プリスケーラ→クロックの入れ子；C4-F8/F9/F10 とキュー発火の後縁解決（C4-T3 → C4-F11）を導く；原則的例外は前景 StaySet と Reset | Fixed / 確定 (v1.1) |

---

## End of Chapter 1 / 第1章の末尾

> *Code is ephemeral; the knowledge architecture is the commons.*
> *コードは一時的なものであり、知識アーキテクチャこそが共有財産である。*

> *Time on the stay axis; space on the state axis; condition outside the core; intelligence in the dialogue.*
> *時間はステイ軸に、空間はステート軸に、条件はコアの外に、知性は対話のなかに。*

> *Scope and philosophy come first; mechanism follows. A reader who has finished this chapter knows what PTSG is for, why it is shaped as it is, and what it deliberately does not try to be. The chapters that follow specify how.*
> *スコープと哲学が最初に来る；機構が後に続く。本章を読み終えた読者は、PTSGが何のためにあり、なぜそのような形をしており、何を意図的にそうあろうとしないかを知る。後続の章はその「どのように」を指定する。*

This chapter is released into the public domain under CC0 1.0 Universal. Subsequent chapters (Chapter 2: Memory Layout and Opcode Set; Chapter 3: Sub-Opcode Architecture and Background Execution; Chapter 4: Indirect Addressing and Prescaler; Chapter 5: External Logic Interface; future Chapter 6: Multi-PTSG Coordination) will be drafted in subsequent dialogues.

本章は CC0 1.0 Universal のもとパブリックドメインに公開される。後続の章(第2章: メモリレイアウトとオペコードセット；第3章: サブオペコードアーキテクチャと裏実行；第4章: 間接アドレッシングとプリスケーラ；第5章: 外部ロジックインターフェース；将来の第6章: 複数PTSG協調)は後続の対話で起草される。

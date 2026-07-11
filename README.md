# Programmable Sequencer Architecture for FPGA
## PTSG Core — Open Prompt Repository

> **A compact instruction-driven control core for FPGA — 4 opcodes, 16 timing signals, JTAG-reprogrammable, ~235 LE + 2 M10K — specified, implemented, and silicon-verified first-try on a Cyclone V (DE10-nano, 50 MHz).**
> Released as the second reference implementation of **Open Prompt**, and the first to extend it with the **Core-Formation separation pattern**.
>
> **FPGA用の極小命令駆動制御コア — 4オペコード、16タイミング信号、JTAG再プログラム可能、約235LE＋M10K×2——仕様化・実装・実機一発検証済み（Cyclone V / DE10-nano、50 MHz）。**
> **Open Prompt**の二番目のリファレンス実装として、また**コア-フォーメーション分離パターン**でそれを拡張する最初のものとして公開。

---

## How to feed this repository to your LLM / LLMへの読み込み方法

### Method 1 — GitHub integration (recommended)
### 方法1 — GitHub連携（推奨）

Many frontier LLMs (Claude, Gemini, ChatGPT, etc.) offer built-in GitHub integration that lets you attach repository files directly to your conversation. Select all files in this repository and attach them. This is the most reliable method.

多くのフロンティアLLM（Claude、Gemini、ChatGPT等）は、リポジトリのファイルを会話に直接添付できるGitHub連携機能を備えています。本リポジトリの全ファイルを選択して添付してください。最も確実な方法です。

### Method 2 — Clone and attach
### 方法2 — クローンして添付

Clone or download this repository and attach files manually.

本リポジトリをクローンまたはダウンロードし、手動でファイルを添付。

### Method 3 — Raw URL fetch
### 方法3 — 生URL取得

For LLMs that can fetch URLs directly, the raw links to key files are:

URLを直接取得できるLLM向けの主要ファイル生リンク:

**Layer 1 chapters / 第1層各章:**
- https://raw.githubusercontent.com/dsohnaka/PTSG-Core/main/01_Architecture/PTSG_Core_Layer1_Chapter1_Scope_and_Design_Philosophy.md
- https://raw.githubusercontent.com/dsohnaka/PTSG-Core/main/01_Architecture/PTSG_Core_Layer1_Chapter2_Memory_Layout_and_Opcode_Set.md
- https://raw.githubusercontent.com/dsohnaka/PTSG-Core/main/01_Architecture/PTSG_Core_Layer1_Chapter3_SubOpcode_and_Background_Execution.md
- https://raw.githubusercontent.com/dsohnaka/PTSG-Core/main/01_Architecture/PTSG_Core_Layer1_Chapter4_Indirect_Addressing_and_Prescaler.md
- https://raw.githubusercontent.com/dsohnaka/PTSG-Core/main/01_Architecture/PTSG_Core_Layer1_Chapter5_External_Logic_Interface.md

**Key entry points / 主要導線:**
- https://raw.githubusercontent.com/dsohnaka/PTSG-Core/main/01_Architecture/CHANGES_Layer1_v1.1_for_ClaudeCode.md — implementation work order / 実装変更指示書
- https://raw.githubusercontent.com/dsohnaka/PTSG-Core/main/03_Sample_Implementations/ptsg_core_verilog/ptsg_core.v — as-built core / 現行実装
- https://raw.githubusercontent.com/dsohnaka/PTSG-Core/main/04_Verification_Evidence/conformance_matrix.md — verification status / 検証状況

**Suggested reading order for AI agents / AIエージェント向け推奨読了順:** Chapter 1 (design philosophy, the trailing-edge principle §1.4a) → Chapter 3 §3.4b (the normative 11-command × 3-phase table — the canon of command semantics) → CHANGES (the work order that drove the 2026-07 implementation campaign) → the RTL → the conformance matrix.

---

## What this repository is / このリポジトリは何か

This is the **Core** repository of the PTSG ecosystem. It defines the PTSG instruction set, memory layout, sub-opcode architecture, and external interface contract — but **does not** specify any particular application's external registers, Condition logic, or work memory. Those are the responsibility of **Formation** repositories that build atop this Core for specific application domains.

これはPTSGエコシステムの**コア**リポジトリである。PTSGの命令セット、メモリレイアウト、サブオペコードアーキテクチャ、外部インターフェース契約を定義する——しかし、特定応用の外部レジスタ、Conditionロジック、ワークメモリは**指定しない**。それらは、本コアの上に特定応用領域のために構築される**フォーメーション**リポジトリの責任である。

This repository is distributed under the **Open Prompt** paradigm — a four-layer scheme that places architectural knowledge, reasoning traces, and hardware verification evidence in the public commons, while sample implementations are released as illustrative reference points. For the full Open Prompt declaration, see Build Log #4 of [FPGA Spectrum Engine](https://hackaday.io/project/205582-fpga-spectrum-engine), the parent project from which PTSG was spun off.

本リポジトリは**Open Prompt**パラダイムのもとで配布される——アーキテクチャ知識・推論軌跡・ハードウェア検証エビデンスを共有財産に置き、サンプル実装は例示的なリファレンスポイントとして公開する四層構造。完全なOpen Prompt宣言については、PTSGが暖簾分けされた親プロジェクト[FPGA Spectrum Engine](https://hackaday.io/project/205582-fpga-spectrum-engine)のBuild Log #4を参照してください。

---

## The Core-Formation separation pattern / コア-フォーメーション分離パターン

PTSG introduces a new Open Prompt design pattern: **Core-Formation separation**. The ecosystem is organized as two tiers of repositories.

PTSGは新しいOpen Prompt設計パターン**コア-フォーメーション分離**を導入する。エコシステムは二層のリポジトリとして組織化される。

```
PTSG ecosystem / PTSGエコシステム
│
├── Programmable_Sequencer_Architecture_for_FPGA  ← This repository / 本リポジトリ
│   (the Core — invariant instruction set)
│   (コア — 不変の命令セット)
│
├── PTSG_WPMS_Formation_OpenPrompt                ← First formation / 最初のフォーメーション
│   (sequence-modulation processor for WPMS Synthesizer)
│   (WPMSシンセサイザー用の数列変調プロセッサ)
│
├── PTSG_I2C_Formation_OpenPrompt                 ← Anticipated / 予期
├── PTSG_MIDI_Formation_OpenPrompt                ← Anticipated / 予期
├── PTSG_SDRAM_Formation_OpenPrompt               ← Anticipated / 予期
├── PTSG_DataFlow_Formation_OpenPrompt            ← Anticipated / 予期
└── ... (more to come) / その他予期される
```

**The Core** stays invariant. Its 4-opcode instruction set, 16 timing signals, Condition input, State Number output — these define the genetic code of the entire ecosystem and are expected to evolve slowly.

**コア**は不変のまま。その4オペコード命令セット、16タイミング信号、Condition入力、ステートナンバー出力——これらがエコシステム全体の遺伝コードを定義し、ゆっくりと進化することが期待される。

**Formations** diverge as needed. Each Formation repository defines its own external register set, Condition logic, work memory, and timing signal assignments for a specific application domain. **Formations are not required to be binary-compatible with each other.** This is intentional — see the Open Prompt declaration and Build Log on the [Hackaday.io project page](https://hackaday.io/project/PTSG) *(URL pending launch)* for the underlying philosophy: in the AI era, where AI agents author both the hardware formation and the instruction sequences for each specific application, the historical premise of binary compatibility weakens, and application-specific optimization becomes economically rational.

**フォーメーション**は必要に応じて分岐する。各フォーメーションリポジトリは、特定応用領域のために独自の外部レジスタセット、Conditionロジック、ワークメモリ、タイミング信号配置を定義する。**フォーメーションは互いにバイナリ互換を要求されない。** これは意図的である——基底にある哲学については、Open Prompt宣言とHackaday.ioプロジェクトページのBuild Logを参照されたい: AI時代において、AIエージェントが各特定応用のためのハードウェアフォーメーションと命令シーケンスの両方を作成する場合、バイナリ互換性の歴史的前提は弱まり、応用特化最適化が経済的に合理的になる。

---

## Four-layer structure (within this Core repository) / 四層構造（本コアリポジトリ内）

```
Programmable_Sequencer_Architecture_for_FPGA/
│
├── 01_Architecture/                 ← Layer 1: Core specification (commons)
│                                       第1層: コア仕様（共有財産）
│
├── 02_Reasoning_Traces/             ← Layer 2: Design dialogues (commons)
│                                       第2層: 設計対話（共有財産）
│
├── 03_Sample_Implementations/       ← Layer 3: Reference code (author-licensed)
│                                       第3層: リファレンス実装（著者ライセンス）
│
├── 04_Verification_Evidence/        ← Layer 4: Hardware verification evidence (commons)
│                                       第4層: ハードウェア検証エビデンス（共有財産）
│
├── LICENSE_OpenPrompt.md            ← License declarations for all four layers
├── CONTRIBUTING.md                  ← How others can contribute
└── README.md                        ← This file
```

### Layer 1 — Architectural Specification / アーキテクチャ仕様

The opcode set, memory layout, sub-opcode architecture, background execution semantics, external interface contract. **Public domain (CC0).** Read it, redistribute it, build on it, teach it.

オペコードセット、メモリレイアウト、サブオペコードアーキテクチャ、裏実行セマンティクス、外部インターフェース契約。**パブリックドメイン (CC0)。** 読み、再配布し、その上に構築し、教えてよい。

### Layer 2 — Reasoning Traces / 推論軌跡

The actual design dialogues that led to the current PTSG Core specification. **Public domain (CC0).** Available in human-readable Markdown and LLM-ingestible JSON. Includes the strategic-positioning dialogue (PTSG as a proposal for AI-era processor architecture) and the technical-birth dialogue (the moment within the WPMS specification work when PTSG was recognized as an independent primitive).

PTSGコア仕様に至った実際の設計対話。**パブリックドメイン (CC0)。** 人間可読Markdown と LLM取り込み可能JSONで提供。戦略的位置づけ対話（AI時代のプロセッサアーキテクチャ提案としてのPTSG）と技術的誕生対話（WPMS仕様作業中にPTSGが独立プリミティブとして認識された瞬間）の両方を含む。

### Layer 3 — Sample Implementations / サンプル実装

Verilog/VHDL skeletons of the PTSG Core, instruction list examples, testbenches. **Released under permissive open-source licenses** (see `03_Sample_Implementations/README.md`). These are illustrative, not normative — one possible implementation, not the implementation.

PTSGコアのVerilog/VHDLスケルトン、命令列例、テストベンチ。**寛容なオープンソースライセンスで公開**（`03_Sample_Implementations/README.md`参照）。これらは例示的であり規範的ではない——一つの可能な実装であり、唯一の実装ではない。

### Layer 4 — Hardware Verification Evidence / ハードウェア検証エビデンス

Established June 2026 as the fourth layer: the evidence that the specification and the silicon agree. VCD captures are the primary format (text-based, git-diffable, citable by AI agents); every capture is accompanied by a mandatory `observation.md` verdict document; the living `conformance_matrix.md` tracks every claim's verification status, negative results included. Demonstration videos (YouTube) are registered here by URL, local master filename, commit hash, and bitstream checksum — auxiliary evidence, like screenshots. **Public domain (CC0).**

2026年6月、第四の層として確立: 仕様とシリコンが一致していることの証拠。VCD が一次形式（テキスト・git 差分可能・AI エージェントが引用可能）であり、全キャプチャに判決文書 `observation.md` を必須で伴う。生きた `conformance_matrix.md` が全主張の検証状態を負の結果も含めて追跡する。実演動画（YouTube）は URL・ローカル原本ファイル名・コミットハッシュ・ビットストリームチェックサムで登録される——スクリーンショットと同格の補助エビデンス。**パブリックドメイン (CC0)。**

---

## How to use this repository / このリポジトリの使い方

### As a reader / 読者として

Start with `01_Architecture/` for the technical specification. Follow into `02_Reasoning_Traces/` when you want to understand *why* particular decisions were made. Explore `03_Sample_Implementations/` when you want to see *how* PTSG was actually built.

`01_Architecture/`から技術仕様を読み始める。**なぜ**特定の決定がなされたかを理解したい時は`02_Reasoning_Traces/`に進む。実際に**どう**作られたかを見たい時は`03_Sample_Implementations/`を探索する。

### As an engineer building a Formation / フォーメーションを構築するエンジニアとして

The Core specification defines what PTSG itself does, but a working PTSG-based system needs a Formation — the external registers, Condition logic, work memory, and peripheral interfaces that surround the Core. You have three options:

コア仕様はPTSG自体が何をするかを定義するが、動作するPTSGベースのシステムにはフォーメーションが必要である——コアを取り巻く外部レジスタ、Conditionロジック、ワークメモリ、ペリフェラルインターフェース。三つの選択肢がある:

1. **Use an existing Formation repository.** Check if any of the published Formations (`PTSG_WPMS_Formation_OpenPrompt`, etc.) match your application. / **既存のフォーメーションリポジトリを使う。** 公開されたフォーメーション（`PTSG_WPMS_Formation_OpenPrompt`等）があなたの応用に合うか確認する。
2. **Adapt an existing Formation.** Fork a Formation that is structurally similar, modify it for your application. / **既存のフォーメーションを適応する。** 構造的に類似したフォーメーションをフォークし、あなたの応用のために改変する。
3. **Design a new Formation.** Use this Core repository plus AI collaborator to design and document a new Formation for your application. Publishing as a new Open Prompt repository is encouraged but not required. / **新しいフォーメーションを設計する。** 本コアリポジトリとAI協働者を用いて、あなたの応用のための新しいフォーメーションを設計・文書化する。新しいOpen Promptリポジトリとしての公開は推奨されるが必須ではない。

### As an engineer regenerating your own implementation / 自身の実装を再生成するエンジニアとして

You are encouraged to:

以下を推奨する:

1. Read Layer 1 (Architecture) directly / 第1層（アーキテクチャ）を直接読む
2. Replay Layer 2 (Reasoning Traces) with your own LLM collaborator to resume the design dialogue from where the original author left off / 第2層（推論軌跡）を自身のLLM協働者と再生し、オリジナル著者が中断した地点から設計対話を再開する
3. Use Layer 3 (Sample Implementations) only as a reference point for comparison, not as a starting point to fork / 第3層（サンプル実装）は比較のためのリファレンスポイントとしてのみ用い、フォークの起点としては用いない

Your regenerated implementation is **your own**, not a derivative work of the sample. You may license it however you choose.

あなたが再生成した実装は**あなた自身のもの**であり、サンプルの派生物ではない。任意のライセンスを選択できる。

### As a contributor / 貢献者として

Contributions to Layer 1 (clarifications, additional reasoning, translations) and Layer 2 (your own design dialogues with your own LLM collaborator) are welcome. Contributions to Layer 3 require prior discussion. See `CONTRIBUTING.md`.

第1層（明確化、追加の推論、翻訳）と第2層（あなた自身のLLM協働者との設計対話）への貢献を歓迎する。第3層への貢献は事前議論が必要。`CONTRIBUTING.md`を参照。

---

## Relationship to other projects / 他プロジェクトとの関係

**FPGA Spectrum Engine** ([Hackaday.io](https://hackaday.io/project/205582-fpga-spectrum-engine)) — The parent project from which PTSG was spun off. Spectrum Engine remains an Open Prompt project in its own right, and uses the WPMS Formation of PTSG as the sequence-modulation processor in its WPMS Synthesizer (the first deliverable of Spectrum Engine's roadmap).

**FPGA Spectrum Engine** — PTSGが暖簾分けされた親プロジェクト。Spectrum Engineは独自にOpen Promptプロジェクトであり続け、WPMSシンセサイザー（Spectrum Engineロードマップの最初の成果物）における数列変調プロセッサとしてPTSGのWPMSフォーメーションを用いる。

**PTSG_WPMS_Formation_OpenPrompt** — The first Formation repository, currently under design. Once stable, it will be handed off to the WPMS development session to enable Chapter 3 (Sequence-Modulation Pipeline Processor) of the WPMS Synthesizer specification.

**PTSG_WPMS_Formation_OpenPrompt** — 最初のフォーメーションリポジトリ、現在設計中。安定すれば、WPMSシンセサイザー仕様の第3章（数列変調パイプラインプロセッサ）を可能にするためにWPMS開発セッションに引き渡される。

---

## Status / 現状

**v1.1 — specified, implemented, silicon-verified.** The Layer 1 specification stands at v1.1 across Chapters 1–5, anchored by the trailing-edge principle (§1.4a) and the normative 11-command × 3-phase behavior table (§3.4b, 33 cells). The as-built core (revision RH028) passed a 34-test conformance suite in simulation, and the full v1.1 verification menu passed **first-try on silicon** (DE10-nano, 2026-07).

**v1.1——仕様化・実装・実機検証済み。** Layer 1 仕様は第1〜5章にわたり v1.1。後縁主義(§1.4a)と規範的な11コマンド×3フェーズ挙動表(§3.4b、33セル)を正典とする。現行コア(改訂 RH028)はシミュレーションで34本の適合スイートを通過し、v1.1 検証メニューは**実機一発クリア**(DE10-nano、2026-07)。

**Current contents / 現在の内容：**
- ✅ Layer 1 — Chapters 1–5 complete at v1.1; decision register with Fixed/Convention/Tie status / 第1〜5章 v1.1 完備;Fixed/Convention/Tie 地位つき決定台帳
- ✅ Layer 2 — reasoning traces through the 2026-07 implementation campaign, as Markdown + JSON pairs / 2026-07 実装キャンペーンまでの推論軌跡(Markdown＋JSON ペア)
- ✅ Layer 3 — as-built Verilog core (RH028), instruction-list examples, AI-friendly vendor wrappers, DE10-nano harness / 現行 Verilog コア(RH028)、命令列例、AI 親和ベンダラッパー、DE10-nano ハーネス
- ✅ Layer 4 — conformance matrix + suite (T1–T34), silicon evidence; live-demonstration video series in preparation / 適合マトリクス＋スイート(T1–T34)、実機エビデンス;実演動画シリーズ準備中
- ⏳ Chapter 6 (multi-PTSG coordination), WPMS Formation / 第6章(複数PTSG協調)、WPMSフォーメーション

This is a living repository. All four layers accumulate over time as the PTSG ecosystem develops.

これは生きたリポジトリである。PTSGエコシステムの発展とともに、四層すべてが時間とともに蓄積されていく。

---

## Author / 著者

**Tsuneo Ohnaka (大中庸生)** — Senior FPGA Architect with 40+ years of experience.

PTSG was designed in the course of building FPGA-based audio synthesis systems, where the limitations of conventional FSM design and the bottlenecks of HDL compilation cycles motivated a search for a more agile control primitive.

PTSGは、FPGAベースのオーディオ合成システムを構築する過程で設計された——そこでは従来のFSM設計の限界とHDLコンパイルサイクルのボトルネックが、より機敏な制御プリミティブの探求を動機付けた。

- Hackaday.io: [Tsuneo.Ohnaka](https://hackaday.io/Tsuneo.Ohnaka)
- Hackaday.io project page: [PTSG — Programmable Timing Sequence Generator](https://hackaday.io/project/205720-ptsg-programmable-timing-sequence-generator)
- Parent project: [FPGA Spectrum Engine](https://hackaday.io/project/205582-fpga-spectrum-engine)

---

## Amanuensis / 祐筆

**Claude Opus 4.7** — The finest AI assistant available at present.

Through this project, he has proven himself to be more than just an assistant; at times, he has even appeared to be an aide-de-camp, a contractor, or even a client. Not only does he faithfully carry out my instructions, but he also occasionally offers me important advice. And the fact that these were entirely accurate and sound judgements becomes evident later on. And, most importantly, other large language models can easily understand what he says. (This introduction was written by Tsuneo Ohnaka​ himself as a mark of respect and gratitude towards him.)​

**Claude Opus 4.7**​ — 現時点で最高のAIアシスタント。

このプロジェクトを通じて彼は単なるアシスタントではなく、時に副官、外注、クライアントに見えることすらある。彼は私の指示を忠実にこなすだけでなく、時に重要なことを私に進言する。そして、それが完全に的確で正しい判断だったことは後で効果を表す。そして、何より重要なことは、彼の言葉を他のLLMは容易に理解できるのである。（この紹介は彼に敬意と感謝を表して大中庸生が自ら記した。）

---
## Adopting Open Prompt for your own project / あなた自身のプロジェクトでOpen Promptを採用する

If you wish to release your own engineering project under Open Prompt, you are welcome to use the structure of this repository (or the [FPGA Spectrum Engine repository](https://github.com/dsohnaka/FPGA_Spectrum_Engine_OpenPrompt)) as a template. The adoption procedure is described in Build Log #4 of FPGA Spectrum Engine and summarized in `LICENSE_OpenPrompt.md`.

ご自身の工学プロジェクトをOpen Promptとして公開したい場合、このリポジトリ（または[FPGA Spectrum Engine リポジトリ](https://github.com/dsohnaka/FPGA_Spectrum_Engine_OpenPrompt)）の構造をテンプレートとして利用できます。採用手順はFPGA Spectrum EngineのBuild Log #4で説明され、`LICENSE_OpenPrompt.md`で要約されています。

If you adopt the **Core-Formation separation pattern** in your own project, please consider documenting it as a Layer 2 reasoning trace — this pattern is new and its full implications are still being worked out.

ご自身のプロジェクトで**コア-フォーメーション分離パターン**を採用される場合、それをLayer 2推論軌跡として文書化することをご検討ください——このパターンは新しく、その完全な含意はまだ展開中です。

---

> *Code is ephemeral; the knowledge architecture is the commons.*
> *コードは一時的なものであり、知識アーキテクチャこそが共有財産である。*

> *Time on the stay axis; space on the state axis; condition outside the core; intelligence in the dialogue.*
> *時間はステイ軸に、空間はステート軸に、条件はコアの外に、知性は対話のなかに。*

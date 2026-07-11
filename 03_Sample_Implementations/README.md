# Layer 3 — Sample Implementations / サンプル実装

> **License: MIT (default; see per-artifact specifications)**
> These are reference points, not blueprints. One possible implementation, not the implementation.
>
> **ライセンス：MIT（デフォルト；アーティファクトごとの指定を参照）**
> これらはリファレンスポイントであり、設計図ではない。一つの可能な実装であり、唯一の実装ではない。

---

## What is in this layer / この層の内容

This layer contains the **concrete artifacts** produced in the course of designing, implementing, and hardware-verifying the PTSG Core: the Verilog core, instruction-list examples, testbenches, vendor-abstraction wrappers, and board-specific build harnesses. These are *illustrative, not normative*.

この層には、PTSGコアの設計・実装・実機検証の過程で生成された**具体的成果物**が含まれる: Verilogコア、命令列例、テストベンチ、ベンダ抽象化ラッパー、ボード固有ビルドハーネス。これらは*例示的であり規範的ではない*。

**This layer covers the Core only.** Formation-specific implementations (external register modules, Condition logic, peripheral interfaces) live in their respective Formation repositories.

**本層はコアのみをカバーする。** フォーメーション固有の実装（外部レジスタモジュール、Conditionロジック、ペリフェラルインターフェース）はそれぞれのフォーメーションリポジトリに存在する。

---

## Directory structure / ディレクトリ構造

Layer 3 separates four kinds of artifact with different lifetimes and different readers — the same discipline that Layer 1 calls Core-Formation separation, applied to the repository itself:

Layer 3 は、寿命と読者の異なる四種類のアーティファクトを分離する——Layer 1 が Core-Formation 分離と呼ぶ規律そのものを、リポジトリ自身に適用したものである:

```
03_Sample_Implementations/
├── examples/                     ← Instruction lists (.hex/.mif). Implementation-INDEPENDENT:
│                                    the same programs run on any conforming Core implementation.
│                                    命令列。実装非依存: 同じプログラムが任意の準拠コア実装で走る。
├── ptsg_core_verilog/            ← The Core itself. Device-independent RTL + self-checking testbench.
│                                    コア本体。デバイス非依存 RTL + 自己チェックテストベンチ。
├── ai_friendly_vendor_wrappers/  ← Vendor-abstracted reusable parts (memory, later PLL/FIFO…),
│                                    each with a SIM branch an AI agent can fully verify and a
│                                    vendor branch the human synthesizes — same timing contract.
│                                    ベンダ抽象化された再利用部品。AI が完全検証できる SIM ブランチと
│                                    人間が合成するベンダブランチ——同一タイミング契約。
└── board_harnesses/              ← Board-specific glue: top-level wrappers, pin constraints,
                                     project files, instrument configs. Per-board subdirectories.
                                     ボード固有の貼り付け: トップ層、ピン制約、プロジェクト、計測器設定。
```

| You want to… / したいこと | Go to / 行き先 |
|---|---|
| Understand or re-implement the Core / コアを理解・再実装する | `ptsg_core_verilog/` (after Layers 1 & 2) |
| Run PTSG programs in simulation / シミュレーションで PTSG プログラムを走らせる | `examples/` + `ptsg_core_verilog/` |
| Build for real hardware / 実機向けにビルドする | `board_harnesses/<your board>/` |
| Use vendor IP in an AI-verifiable way / ベンダ IP を AI 検証可能に使う | `ai_friendly_vendor_wrappers/` |

---

## Currently available / 現在利用可能

| Artifact | Status / 状態 |
|---|---|
| `ptsg_core_verilog/ptsg_core.v` + `ptsg_core_tb.v` | Self-tests passing under Icarus Verilog. Authored by an AI coding agent from the Layer 1 specification alone (Build Log #5); audited, with documented Tie resolutions and known simplifications in its README. / Icarus Verilog で自己テスト通過。Layer 1 仕様のみから AI コーディングエージェントが執筆(Build Log #5)；監査済み、Tie 解決と既知の簡略化は同 README に文書化。 |
| `examples/` — 5 instruction-list programs (.hex/.mif pairs) | Simulation-verified. blinky_with_prescaler additionally **verified on silicon** (DE10-nano, 2026-06). / シミュレーション検証済み。blinky_with_prescaler は加えて**実機検証済み**(DE10-nano、2026-06)。 |
| `ai_friendly_vendor_wrappers/ptsg_imem/` | Instruction-memory wrapper (SIM / Cyclone V M10K branches, EDGE-parameterized, ISMCE-enabled). SIM contract machine-proved; M10K branch **hardware-verified on DE10-nano** (Build Log #6). / 命令メモリラッパー。SIM 契約は機械証明済み；M10K ブランチは **DE10-nano で実機検証済み**(Build Log #6)。 |
| `board_harnesses/de10_nano/` | DE10-nano (Cyclone V) build harness with a zero-re-synthesis JTAG development loop (In-System Memory Content Editor + In-System Sources & Probes). / 再合成ゼロの JTAG 開発ループを備えた DE10-nano ビルドハーネス。 |

Provenance and the full verification story are documented in the Build Logs (#5 implementation, #6 hardware bring-up) and the corresponding Layer 2 traces.

来歴と検証の全容は Build Log(#5 実装、#6 実機ブリングアップ)と対応する Layer 2 軌跡に文書化されている。

**2026-07 update / 2026-07 追記:** The core RTL now stands at **RH028**, v1.1-conformant (FG-Global exclusion traps, S_HALT + `error_flag`, queued-band rulings, LOOP_W=16, P=1 tick-collision discipline), with conformance suite **T1–T34**; the full v1.1 verification menu passed **first-try on silicon** (DE10-nano, 2026-07). / コア RTL は現在 **RH028**、v1.1 準拠(FG-Global 排除トラップ、S_HALT＋`error_flag`、Que 帯域裁定群、LOOP_W=16、P=1 tick 衝突規律)、適合スイート **T1–T34**。v1.1 検証メニューは**実機一発クリア**(DE10-nano、2026-07)。

### Instruction list examples / 命令列例

- `blinky_with_prescaler` — The "moved-on-from-counter-Lチカ" reference: a prescaled LED blink. **Silicon-verified.** / 「カウンタLチカからの卒業」リファレンス: プリスケール LED 点滅。**実機検証済み。**
- `multi_signal_timing` — Multiple timing signals coordinated within a sequence. / シーケンス内で複数のタイミング信号が協調する例。
- `conditional_branching` — Condition-driven branching with external logic. / 外部ロジックを伴う Condition 駆動分岐。
- `sub_sequence_branching` — Sub-sequence call and return (using the **Sub-sequence Call** internal sub-opcode + Return). / サブシーケンス呼び出しと復帰(**Sub-sequence Call** 内部サブオペコード + Return を用いる)。
- `background_execution` — Global commands executing during Stay (the signature PTSG pattern). / Stay 中にグローバル命令が実行される例(PTSG の特徴的パターン)。

### Still planned / 引き続き計画中

- `ptsg_core_vhdl/` — Equivalent VHDL skeleton (community demand permitting). / 等価な VHDL スケルトン(コミュニティ需要に応じて)。
- `ptsg_simulator/` — A standalone PTSG simulator (likely web-based), closing the feedback loop for AI agents authoring PTSG code: write an instruction list, simulate, observe timing patterns, iterate — without human-in-the-loop FPGA synthesis. One of the longer-term goals of the PTSG ecosystem. / 独立 PTSG シミュレータ(おそらくウェブベース)。PTSG コードを作成する AI エージェントのフィードバックループを閉じる: 命令列を書き、シミュレートし、タイミングパターンを観察し、反復する——人間介在の FPGA 合成なしに。PTSG エコシステムの長期目標の一つ。
- Additional vendor wrappers (PLL first candidate) and board harnesses as the project reaches them. / 追加のベンダラッパー(PLL が第一候補)とボードハーネス。

---

## A critical distinction / 重要な区別

A regenerated PTSG Core implementation produced by another engineer from Layer 1 (Architecture) and Layer 2 (Reasoning Traces) is **NOT a derivative work** of these samples. The regenerator owns their implementation outright.

第1層（アーキテクチャ）と第2層（推論軌跡）から他のエンジニアが再生成したPTSGコア実装は、これらのサンプルの**派生物ではない**。再生成者はその実装を完全に所有する。

| Source path / 出発点 | Result / 結果 |
|---|---|
| Forking a Layer 3 sample → modify → redistribute / 第3層サンプルをフォーク→改変→再配布 | Derivative work, MIT license obligations apply / 派生著作物、MITライセンス義務が適用 |
| Reading Layers 1 & 2 → regenerate from architecture → produce new implementation / 第1層・第2層を読む→アーキテクチャから再生成→新しい実装を生成 | Independent work, regenerator's own license / 独立著作物、再生成者自身のライセンス |

This distinction is the structural innovation of Open Prompt. Forking the sample is permitted (under MIT). Regenerating from the architecture is *also* permitted, and the resulting work has no license inheritance from the sample.

この区別がOpen Promptの構造的革新である。サンプルのフォークは許可される（MITのもと）。アーキテクチャからの再生成も許可される——そして結果として得られる著作物にはサンプルからのライセンス継承がない。

---

## Per-artifact licenses / アーティファクトごとのライセンス

Unless specified otherwise within a subdirectory, all sample implementations are released under the **MIT License**. Subdirectories with different licenses will contain their own `LICENSE` file.

サブディレクトリ内で別途指定がない限り、すべてのサンプル実装は**MITライセンス**で公開される。異なるライセンスを持つサブディレクトリは独自の`LICENSE`ファイルを含む。

---

## How to use this layer responsibly / この層を責任を持って利用する方法

### If you want to fork and modify / フォークして改変したい場合

Standard open-source practice. Follow MIT terms. Your fork is a derivative work.

標準的なオープンソース実践。MIT条項に従う。あなたのフォークは派生著作物である。

### If you want to learn from this and build your own / これから学んで自身のものを構築したい場合

Read the samples for understanding, but **do not begin by copying them**. Instead, read Layers 1 and 2, then implement from scratch (with or without LLM assistance). Use the samples only for comparison after your own implementation exists. This preserves the Open Prompt structure: your implementation is genuinely yours.

理解のためにサンプルを読むが、**コピーから始めない**こと。代わりに第1層と第2層を読み、ゼロから実装する（LLM補助の有無を問わず）。自身の実装が存在した後の比較のみのために、サンプルを使う。これがOpen Prompt構造を保持する: あなたの実装は本当にあなた自身のものである。

### If you want to build a Formation / フォーメーションを構築したい場合

Layer 3 gives you a working PTSG Core to instantiate inside your Formation. Your Formation surrounds it with external registers, Condition logic, work memory, and peripheral interfaces specific to your application. Publish your Formation as its own Open Prompt repository.

Layer 3 は、あなたのフォーメーション内部でインスタンス化する動作するPTSGコアを与える。フォーメーションを独自のOpen Promptリポジトリとして公開する。

### If you want to contribute / 貢献したい場合

See the root-level `CONTRIBUTING.md`. Direct contributions to the original author's samples require prior discussion. The recommended alternative is to publish your own Open Prompt repository and link to it.

ルートの `CONTRIBUTING.md` を参照。オリジナル著者のサンプルへの直接貢献は事前議論を必要とする。推奨される代替案は、自身のOpen Promptリポジトリを公開してリンクすることである。

---

## Why "samples," not "the implementation" / なぜ「実装」ではなく「サンプル」か

Calling these "the implementation" would imply that they are the canonical answer. They are not. They are **one possible answer**, made under one set of constraints, at one moment in time. Other engineers — and other AI agents — under different constraints will produce different implementations from the same Layer 1 and Layer 2 inputs. Those implementations are equally legitimate. **The instruction set is the commons. The implementations are the contributions.**

これらを「実装」と呼ぶことは、それらが正典的な答えであることを含意する。そうではない。それらは**一つの可能な答え**であり、一組の制約のもとで、一時点で作成されたものである。他のエンジニア——そして他の AI エージェント——は異なる制約のもとで、同じ第1層・第2層の入力から異なる実装を生み出す。それらは等しく正当である。**命令セットは共有財産である。実装は貢献である。**

---

> *PTSG Core is small enough that re-implementing it from scratch is not a daunting task — it is a learning opportunity.*
>
> *PTSGコアは、ゼロから再実装することが恐ろしい作業ではなく学習機会であるほど小さい。*

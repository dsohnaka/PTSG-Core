# Layer 3 — Sample Implementations / サンプル実装

> **License: MIT (default; see per-artifact specifications)**
> These are reference points, not blueprints. One possible implementation, not the implementation.
>
> **ライセンス：MIT（デフォルト；アーティファクトごとの指定を参照）**
> これらはリファレンスポイントであり、設計図ではない。一つの可能な実装であり、唯一の実装ではない。

---

## What is in this layer / この層の内容

This layer contains the **concrete artifacts** produced by the original author in the course of designing and using the PTSG Core: Verilog/VHDL skeletons of the core itself, instruction list examples, testbenches, and simulation harnesses. These are *illustrative, not normative*.

この層には、PTSGコアの設計と利用の過程でオリジナル著者が生成する**具体的成果物**が含まれる: コア自体のVerilog/VHDLスケルトン、命令列例、テストベンチ、シミュレーションハーネス。これらは*例示的であり規範的ではない*。

**This layer covers the Core only.** Formation-specific implementations (external register modules, Condition logic, peripheral interfaces) live in their respective Formation repositories.

**本層はコアのみをカバーする。** フォーメーション固有の実装（外部レジスタモジュール、Conditionロジック、ペリフェラルインターフェース）はそれぞれのフォーメーションリポジトリに存在する。

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

## Planned artifacts / 予定アーティファクト

*Sample implementations are accumulated over time as the project progresses. The list below reflects the current plan.*
*サンプル実装はプロジェクトの進展とともに蓄積される。以下は現在の計画を反映する。*

### Core implementation / コア実装

- `ptsg_core_verilog/` — Reference Verilog skeleton of the PTSG Core (instruction decoder, state memory, opcode handlers, sub-opcode decoder, background execution mechanism, timing signal latch) / PTSGコアのリファレンスVerilogスケルトン（命令デコーダ、ステートメモリ、オペコードハンドラ、サブオペコードデコーダ、裏実行機構、タイミング信号ラッチ）
- `ptsg_core_vhdl/` — Equivalent VHDL skeleton (optional, depending on community demand) / 等価なVHDLスケルトン（オプション、コミュニティ需要に応じて）

### Testbench and verification / テストベンチと検証

- `ptsg_core_testbench/` — Self-checking testbench exercising all 4 opcodes, sub-opcodes, background execution, and external interface protocols / 4オペコード全て、サブオペコード、裏実行、外部インターフェースプロトコルを行使する自己チェックテストベンチ
- `ptsg_core_signaltap_examples/` — SignalTap II configurations for debugging PTSG Core on real FPGA hardware / 実FPGAハードウェア上でPTSGコアをデバッグするためのSignalTap II構成

### Instruction list examples / 命令列例

- `examples/blinky_with_prescaler.mif` — The "moved-on-from-counter-Lチカ" reference example, showing how a 1-second LED blink is structured in PTSG with the prescaler / 「カウンタLチカからの卒業」リファレンス例、プリスケーラを用いてPTSGで1秒LED点滅がどう構造化されるかを示す
- `examples/multi_signal_timing.mif` — Example demonstrating multiple timing signals coordinated within a sequence / シーケンス内で複数のタイミング信号が協調する例を示す
- `examples/conditional_branching.mif` — Example demonstrating Condition-driven branching with external logic / 外部ロジックを伴うCondition駆動分岐の例を示す
- `examples/sub_sequence_branching.mif` — Example demonstrating sub-sequence call and return (using Branch + Return opcode) / サブシーケンス呼び出しと復帰の例を示す（Branch + Return命令を用いる）
- `examples/background_execution.mif` — Example demonstrating Global commands executing during Stay (the signature PTSG pattern) / Stay中にグローバル命令が実行される例を示す（PTSGの特徴的パターン）

### Simulation harness / シミュレーションハーネス

- `ptsg_simulator/` — A standalone PTSG simulator (likely web-based for accessibility), enabling AI agents and learners to verify instruction sequences without an FPGA / 独立PTSGシミュレータ（アクセシビリティのためおそらくウェブベース）、AIエージェントと学習者がFPGAなしで命令シーケンスを検証することを可能にする

The simulator deserves a special note: it is the piece that closes the feedback loop for AI agents authoring PTSG code. With a working simulator, an AI agent can write an instruction list, simulate it, observe the resulting timing signal patterns and state transitions, and iterate — all within the agent's own execution loop, without human-in-the-loop FPGA synthesis.

シミュレータには特別な注釈が必要である: これはPTSGコードを作成するAIエージェントのフィードバックループを閉じる部品である。動作するシミュレータがあれば、AIエージェントは命令列を書き、シミュレートし、結果のタイミング信号パターンとステート遷移を観察し、反復できる——すべてエージェント自身の実行ループ内で、人間が介在するFPGA合成なしに。

This is one of the longer-term goals of the PTSG ecosystem.

これはPTSGエコシステムのより長期的な目標の一つである。

### Currently available / 現在利用可能

*To be added as the project progresses.*
*プロジェクト進展に応じて追加。*

---

## Per-artifact licenses / アーティファクトごとのライセンス

Unless specified otherwise within a subdirectory, all sample implementations are released under the **MIT License**. Subdirectories with different licenses will contain their own `LICENSE` file.

サブディレクトリ内で別途指定がない限り、すべてのサンプル実装は**MITライセンス**で公開される。異なるライセンスを持つサブディレクトリは独自の`LICENSE`ファイルを含む。

Standard MIT terms: copyright notice and license text must be included in substantial portions of redistributions; provided "as is" without warranty.

標準的なMIT条項: 再配布のかなりの部分には著作権表示とライセンス文を含めなければならない；保証なしで「現状のまま」提供される。

---

## How to use this layer responsibly / この層を責任を持って利用する方法

### If you want to fork and modify / フォークして改変したい場合

Standard open-source practice. Follow MIT terms. Your fork is a derivative work.

標準的なオープンソース実践。MIT条項に従う。あなたのフォークは派生著作物である。

### If you want to learn from this and build your own / これから学んで自身のものを構築したい場合

Read the samples for understanding, but **do not begin by copying them**. Instead, read Layers 1 and 2, then implement from scratch (with or without LLM assistance). Use the samples only for comparison after your own implementation exists.

理解のためにサンプルを読むが、**コピーから始めない**こと。代わりに第1層と第2層を読み、ゼロから実装する（LLM補助の有無を問わず）。自身の実装が存在した後の比較のみのために、サンプルを使う。

This is the recommended path because it preserves the Open Prompt structure: your implementation is genuinely yours, not a fork of someone else's code.

この経路を推奨する理由はOpen Prompt構造を保持するからである: あなたの実装は本当にあなた自身のものであり、他人のコードのフォークではない。

### If you want to build a Formation / フォーメーションを構築したい場合

Layer 3 of this Core repository gives you a working PTSG Core to instantiate inside your Formation. Your Formation will surround it with external registers, Condition logic, work memory, and peripheral interfaces specific to your application. Publish your Formation as its own Open Prompt repository.

本コアリポジトリのLayer 3は、あなたのフォーメーション内部でインスタンス化する動作するPTSGコアを与える。あなたのフォーメーションは、あなたの応用に固有の外部レジスタ、Conditionロジック、ワークメモリ、ペリフェラルインターフェースでそれを取り巻くことになる。フォーメーションを独自のOpen Promptリポジトリとして公開する。

### If you want to contribute / 貢献したい場合

See the root-level `CONTRIBUTING.md`. Direct contributions to the original author's samples require prior discussion. The recommended alternative is to publish your own Open Prompt repository and link to it.

ルートの `CONTRIBUTING.md` を参照。オリジナル著者のサンプルへの直接貢献は事前議論を必要とする。推奨される代替案は、自身のOpen Promptリポジトリを公開してリンクすることである。

---

## Why "samples," not "the implementation" / なぜ「実装」ではなく「サンプル」か

Calling these "the implementation" would imply that they are the canonical answer. They are not. They are **one possible answer**, made by one engineer (the original author), under one set of constraints (the original author's hardware, time, error budget, and aesthetic preferences), at one moment in time.

これらを「実装」と呼ぶことは、それらが正典的な答えであることを含意する。そうではない。それらは**一つの可能な答え**であり、一人のエンジニア（オリジナル著者）が、一組の制約（オリジナル著者のハードウェア、時間、誤差予算、美的選好）のもとで、一時点で作成したものである。

Other engineers — under different constraints, with different aesthetic preferences, on different hardware, at different moments in time — will produce different implementations from the same Layer 1 and Layer 2 inputs. Those implementations are equally legitimate. **The instruction set is the commons. The implementations are the contributions.**

他のエンジニアは——異なる制約のもとで、異なる美的選好を持ち、異なるハードウェア上で、異なる時点で——同じ第1層と第2層の入力から異なる実装を生み出す。それらの実装は等しく正当である。**命令セットは共有財産である。実装は貢献である。**

---

> *PTSG Core is small enough that re-implementing it from scratch is not a daunting task — it is a learning opportunity.*
>
> *PTSGコアは、ゼロから再実装することが恐ろしい作業ではなく学習機会であるほど小さい。*

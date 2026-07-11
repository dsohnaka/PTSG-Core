# Layer 1 — Architectural Specification / アーキテクチャ仕様

> **License: CC0 1.0 Universal (Public Domain)**
> This is the commons. Read it, redistribute it, build on it, teach it, criticize it, refine it. No permission needed.
>
> **ライセンス：CC0 1.0 Universal（パブリックドメイン）**
> これは共有財産である。読み、再配布し、その上に構築し、教え、批評し、洗練してよい。許可は不要。

---

## What is in this layer / この層の内容

The Architectural Specification layer contains the **mathematics, constraints, and structural decisions** that define the PTSG Core. It is written for a competent FPGA engineer to read directly. In combination with current language model capabilities, it is sufficient input for that engineer to regenerate a working PTSG Core implementation in HDL.

アーキテクチャ仕様層には、PTSGコアを定義する**数学、制約、構造的決定**が含まれる。有能なFPGAエンジニアが直接読めるように書かれている。現代の言語モデル能力との組み合わせにより、そのエンジニアが動作するPTSGコア実装をHDLで再生成するに十分な入力である。

**This layer specifies the Core only.** The external registers, Condition logic, work memory, and peripheral interfaces required by any specific application are the responsibility of **Formation repositories** that build atop this Core. See the root `README.md` for the Core-Formation separation pattern.

**本層はコアのみを仕様する。** 特定応用が要求する外部レジスタ、Conditionロジック、ワークメモリ、ペリフェラルインターフェースは、本コアの上に構築する**フォーメーションリポジトリ**の責任である。コア-フォーメーション分離パターンについてはルートの`README.md`を参照。

---

## Chapter structure / 章構成

The Layer 1 specification is being drafted in chapters. The planned structure is:

Layer 1仕様は章ごとに起草される。予定される構成:

### Chapter 1 — Scope and Design Philosophy / スコープと設計哲学

What PTSG is, what it is not, and why it is shaped the way it is. Covers the educational origin, the time-axis/space-axis separation principle, the deliberate offloading of Condition generation to external logic, the AI-affinity properties, and the relationship to the parent FPGA Spectrum Engine project.

PTSGとは何か、何でないか、なぜそのような形なのか。教育起源、時間軸/空間軸分離原則、Condition生成を外部ロジックへ意図的にオフロードすること、AI親和性の性質、親プロジェクトFPGA Spectrum Engineとの関係を扱う。

### Chapter 2 — Memory Layout and Opcode Set / メモリレイアウトとオペコードセット

The 32-bit instruction word structure (opcode / operand / 16 timing signals), the 4 currently-defined opcodes (Global, Stay, Branch, Jump) and their semantics, and the 4-bit opcode space's 12 reserved slots for future expansion.

32ビット命令語構造（オペコード／オペランド／16タイミング信号）、現在定義されている4つのオペコード（グローバル、ステイ、ブランチ、ジャンプ）とそのセマンティクス、4ビットオペコード空間における将来拡張用に予約された12スロット。

### Chapter 3 — Sub-Opcode Architecture and Background Execution / サブオペコードアーキテクチャと裏実行

The Global opcode's sub-opcode decoding mechanism, the background execution semantics (commands placed before Stay execute during the wait), the minimum-stay-count constraints for multi-clock background operations, and the internal information holding register / external stack memory protocols.

グローバル命令のサブオペコードデコード機構、裏実行セマンティクス（ステイの前に置かれたコマンドが待機中に実行される）、複数クロック裏処理のための最低ステイカウント制約、内部情報保持レジスタ／外部スタックメモリプロトコル。

### Chapter 4 — Indirect Addressing and Prescaler / 間接アドレッシングとプリスケーラ

The "literal-zero-as-escape" convention for indirect addressing of loop count / stay length / absolute jump address via external registers. The prescaler mechanism for extending stay-count range while keeping the stay counter compact. Both features are recent additions emerging from the PTSG launch dialogue.

ループ回数／ステイ長／絶対ジャンプアドレスを外部レジスタで指定するための「直値ゼロをエスケープとする」慣習。ステイカウンタをコンパクトに保ちつつステイカウント範囲を拡張するプリスケーラ機構。両機能はPTSGローンチ対話から立ち現れた最近の追加である。

### Chapter 5 — External Logic Interface / 外部ロジックインターフェース

The signal-level contract between PTSG Core and external logic. Condition input (1 bit), State Number output (12 bits), timing signals (16 bits parallel), external register access protocol. This is the boundary across which Formations differentiate.

PTSGコアと外部ロジックの間の信号レベル契約。Condition入力（1ビット）、ステートナンバー出力（12ビット）、タイミング信号（16ビット並列）、外部レジスタアクセスプロトコル。フォーメーションが分化する境界である。

### Chapter 6 (future) — Multi-PTSG Coordination / 複数PTSG協調

When multiple PTSG cores coexist on the same FPGA, what synchronization primitives are needed? How do Condition lines route between PTSGs? What protocols govern shared memory access? This chapter will accumulate as multi-PTSG applications develop.

複数のPTSGコアが同一FPGA上に共存する場合、どのような同期プリミティブが必要か? ConditionラインはPTSG間をどう経路づけるか? 共有メモリアクセスを統治するプロトコルは何か? 本章は複数PTSG応用が発展するにつれて蓄積する。

---

## Currently available / 現在利用可能

*Documents in this layer are accumulated over time. The list below reflects the current state and will grow.*
*この層の文書は時間とともに蓄積される。以下のリストは現状を反映しており、拡張されていく。*

- ✅ **Chapters 1–5** — complete at **v1.1**; silicon-verified 2026-07; the normative command × phase table lives in Chapter 3 §3.4b / **第1〜5章** — **v1.1** 完備;2026-07 実機検証済み;規範のコマンド×フェーズ表は第3章 §3.4b
- ⏳ **Chapter 6** — accumulates as multi-PTSG applications develop / **第6章** — 複数PTSG応用の発展とともに蓄積

The Hackaday.io [PTSG project page](https://hackaday.io/project/205720-ptsg-programmable-timing-sequence-generator) serves as initial high-level documentation while these formal chapters are being drafted.

これらの正式章が準備される間、Hackaday.io [PTSGプロジェクトページ](https://hackaday.io/project/205720-ptsg-programmable-timing-sequence-generator) が初期の高レベル文書として機能する。

---

## How to read this layer / この層の読み方

For a high-level entry: read the Hackaday.io project page Details section, then Chapter 1 (when available).

高レベルからの入り口: Hackaday.io プロジェクトページのDetailsセクション、次に第1章（利用可能になり次第）を読む。

For deep technical understanding: follow the chapters in sequence. Each chapter assumes familiarity with the previous ones.

深い技術的理解のため: 章を順次に追う。各章は前章への親しみを前提とする。

For regenerating your own implementation: Layer 1 alone is not optimal. Pair it with Layer 2 (Reasoning Traces) so you can resume the design dialogue with your own LLM collaborator from where the original author left off.

自身の実装を再生成するため: 第1層単独では最適ではない。第2層（推論軌跡）と組み合わせ、オリジナル著者が中断した地点から自身の LLM 協働者と設計対話を再開できるようにする。

For building a Formation: read Chapter 5 (External Logic Interface) carefully, plus any existing Formation repositories (`PTSG_WPMS_Formation_OpenPrompt`, etc.) for examples of how Formations are structured.

フォーメーションを構築するため: 第5章（外部ロジックインターフェース）を注意深く読み、加えて既存のフォーメーションリポジトリ（`PTSG_WPMS_Formation_OpenPrompt`等）でフォーメーションがどう構造化されるかの例を読む。

---

## How to contribute / 貢献の方法

See the root-level `CONTRIBUTING.md`. Layer 1 contributions are released into the public domain (CC0) by the act of submission.

ルートの `CONTRIBUTING.md` を参照。第1層への貢献は、提出行為によりパブリックドメイン (CC0) で公開される。

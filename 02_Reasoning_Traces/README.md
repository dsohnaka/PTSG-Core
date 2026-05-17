# Layer 2 — Reasoning Traces / 推論軌跡

> **License: CC0 1.0 Universal (Public Domain)**
> These are the design dialogues. Read them, replay them, resume them, build on them, share them. No permission needed.
>
> **ライセンス：CC0 1.0 Universal（パブリックドメイン）**
> これらは設計対話である。読み、再生し、再開し、その上に構築し、共有してよい。許可は不要。

---

## What is in this layer / この層の内容

This layer contains the **actual design dialogues** that led to the PTSG Core specification. Each dialogue is preserved in two paired formats:

この層には、PTSGコア仕様へと至った**実際の設計対話**が含まれる。各対話は2つのペア形式で保存される：

- **`.md` (Markdown)** — for human reading. Formatted for clarity, with section markers and contextual annotations. / 人間が読むため。明確さのために整形され、セクションマーカーと文脈的注釈が付く
- **`.json` (JSON)** — for direct ingestion by language models. Each turn is a structured object with role, content, and metadata. A reader who loads this file into their own LLM context can resume the dialogue. / 言語モデルが直接取り込むため。各ターンは role、content、メタデータを持つ構造化オブジェクト。このファイルを自身の LLM コンテクストにロードする読者は対話を再開できる

---

## Why this layer matters / なぜこの層が重要か

Engineering decisions are rarely fully reconstructible from specifications alone. **"Why this and not that"** lives in the *process* of arriving at the specification.

工学的決定は仕様だけからは完全には再構成できないことが多い。**「なぜこれであってあれでないか」**は仕様に到達する*過程*に宿る。

For PTSG specifically, the design philosophy — minimal opcodes, time-axis/space-axis separation, Condition-generation-as-external-responsibility, AI-affinity, Core-Formation separation — emerged through dialogue across multiple sessions. The reasoning that produced each design choice is captured in the traces below, so that future engineers (human and AI) regenerating or extending PTSG can recover not just the specification but the **judgment** behind it.

PTSGについて特に、設計哲学——ミニマルなオペコード、時間軸/空間軸の分離、Condition生成の外部責任化、AI親和性、コア-フォーメーション分離——は複数のセッションにまたがる対話を通じて立ち現れた。各設計選択を生んだ推論は以下の軌跡に捕らえられており、PTSGを再生成または拡張する将来のエンジニア（人間とAI）は、仕様だけでなくその背後にある**判断**を回復できる。

A reader who replays one of these dialogues with their own language model collaborator does not just *read* the reasoning — they can **resume** it.

これらの対話を自身の言語モデル協働者と再生する読者は、推論を*読む*だけではない——**再開**できる。

---

## Trace inventory / 軌跡一覧

### Inaugural traces / 最初の軌跡

| File | Date | Topic | Participants | Type |
|---|---|---|---|---|
| `2026-05-XX_ptsg-strategic-positioning.md/.json` | 2026-05-XX | The dialogue in which PTSG's role as an AI-era processor architecture proposal crystallized. Covers: three-layer engagement model (write/design/read), Webapp simulator vision for AI agent integration, additive-synth-as-launching-point strategy, Core-Formation separation pattern, the "is code compatibility important?" question, two-tier repository model. | Tsuneo Ohnaka × Claude (Anthropic, Claude Opus 4.7, launch session) | Single-AI / inaugural / strategic |
| `2026-05-XX_ptsg-birth-from-wpms-session.md/.json` | 2026-04-30 〜 2026-05-XX | The dialogue within the WPMS Layer 1 specification work where PTSG was recognized as an independent primitive, was named, and was spun off from FPGA Spectrum Engine to its own project. | Tsuneo Ohnaka × Claude (Anthropic, Claude Opus 4.7, WPMS session) | Single-AI / inaugural / technical-birth |

*(Filenames to be finalized on publication. Dates pending.)*
*(ファイル名は公開時に確定。日付未定。)*

### Contributed traces / 貢献された軌跡

*Place your contributed traces in the `contributed/[your-name]/` subdirectory. See the root `CONTRIBUTING.md` for the contribution procedure.*
*貢献された軌跡は `contributed/[あなたの名前]/` サブディレクトリに置いてください。貢献手順についてはルートの `CONTRIBUTING.md` を参照。*

---

## Two inaugural traces — a note on why two / 最初の軌跡が二つあることについての注

The inaugural Layer 2 of PTSG comprises **two separate traces, recorded across two AI sessions**:

PTSGの最初のLayer 2は、**二つの別個の軌跡**から成り、**二つのAIセッションにまたがって**記録されている:

The **technical-birth trace** records the moment within the FPGA Spectrum Engine WPMS Layer 1 specification work when the need for a programmable sequencer became unavoidable, when the PTSG concept was articulated, when its 4-opcode structure was sketched, and when it was recognized that this primitive was too general-purpose to remain a sub-component of WPMS — leading to the decision to spin it off into its own Open Prompt project. This trace lives in the work-context of WPMS development.

**技術的誕生トレース**は、FPGA Spectrum Engine WPMS第1層仕様作業内において、プログラマブルシーケンサの必要性が回避不能になった瞬間、PTSGコンセプトが明確化された瞬間、その4オペコード構造がスケッチされた瞬間、そしてこのプリミティブがWPMSのサブコンポーネントとして留まるには汎用すぎると認識された瞬間——独自のOpen Promptプロジェクトとして暖簾分けする決定に至った瞬間を記録する。本軌跡はWPMS開発の作業文脈の中に生きる。

The **strategic-positioning trace** records a separate dialogue, in a new session with no shared context with the WPMS session, in which PTSG's larger significance was worked out: PTSG as an AI-era processor architecture proposal, the Core-Formation separation pattern as a new Open Prompt design pattern, the question of whether binary compatibility across formations is necessary in the AI era, the three-layer engagement model that allows learners/engineers/AI agents to engage at different depths simultaneously.

**戦略的位置づけトレース**は、別個の対話を記録する——WPMSセッションとの共有コンテキストを持たない新しいセッションでの対話で、PTSGのより大きな意義が練り上げられたもの: AI時代のプロセッサアーキテクチャ提案としてのPTSG、新しいOpen Prompt設計パターンとしてのコア-フォーメーション分離パターン、AI時代におけるフォーメーション間バイナリ互換性は必要かという問い、学習者/エンジニア/AIエージェントが異なる深さで同時に関与することを可能にする三層関与モデル。

The two traces together represent **the binocular vision** through which PTSG came to be: the close-range technical view from within an active development project, and the strategic-architectural view from outside it. Neither alone would have produced the PTSG that this repository describes. **The Core-Formation separation pattern itself emerged from the strategic trace, but only because the technical trace had already established what PTSG was.**

二つの軌跡は合わせて、PTSGが生まれてきた**両眼視**を表す: 活動的な開発プロジェクト内部からの近距離技術視点と、その外部からの戦略的アーキテクチャ視点。どちらか単独では本リポジトリが記述するPTSGは生まれなかった。**コア-フォーメーション分離パターン自体は戦略的トレースから立ち現れたが、それは技術的トレースがすでにPTSGが何であるかを確立していたからこそである。**

---

## How to replay a dialogue / 対話の再生方法

### With a frontier-class language model (recommended) / フロンティア級言語モデルを用いる方法（推奨）

1. Open the `.json` version of the trace you want to replay
2. Load the conversation history into your LLM's context (most chat interfaces support importing structured conversation history; if not, paste the messages sequentially)
3. The LLM will now have the same context the original participants had at the end of the dialogue
4. Continue the dialogue with your own questions, clarifications, or extensions

1. 再生したい軌跡の `.json` 版を開く
2. 会話履歴を LLM のコンテクストにロードする（多くのチャットインターフェースは構造化会話履歴のインポートをサポート；そうでなければメッセージを順次貼り付ける）
3. これで LLM は、対話終了時にオリジナル参加者が持っていたのと同じコンテクストを持つ
4. 自身の質問、明確化、拡張で対話を継続する

### Easier still — GitHub integration / さらに簡単に — GitHub連携

Most frontier LLMs (Claude, ClaudeCode, Gemini, ChatGPT) now support GitHub integration that lets you attach repository files directly to the conversation. You can attach all of `02_Reasoning_Traces/` plus the relevant Layer 1 documents in one operation.

ほとんどのフロンティアLLM（Claude、ClaudeCode、Gemini、ChatGPT）は現在、リポジトリファイルを会話に直接添付できるGitHub統合をサポートしている。`02_Reasoning_Traces/` のすべてと関連するLayer 1文書を一度に添付できる。

### Without a language model / 言語モデルなしの場合

The `.md` versions are written to be readable as standalone documents. You can read them as you would read any technical document, treating them as detailed records of design reasoning.

`.md` 版は単独文書として読めるように書かれている。任意の技術文書を読むのと同様に読める——設計推論の詳細な記録として扱う。

---

## A note on AI participation / AI参加についての注

The inaugural traces feature collaboration between a human engineer (Tsuneo Ohnaka) and language models (Claude by Anthropic, across two separate sessions). This is not a hidden detail; it is the explicit point of the Layer 2 paradigm.

最初の軌跡は、人間エンジニア（大中庸生）と言語モデル（Anthropic社製Claude、二つの別個のセッションをまたいで）との協働を特徴とする。これは隠された詳細ではない；第2層パラダイムの明示的な要点である。

The reasoning shown in these traces is real reasoning — the kind that produced the PTSG concept itself, its naming, its 4-opcode structure, its Core-Formation separation pattern, and its launch as an independent Open Prompt project. **The dialogues are not transcripts of a brainstorm; they are the actual decision-making process.**

これらの軌跡に示される推論は実際の推論である——PTSGコンセプト自体、その命名、4オペコード構造、コア-フォーメーション分離パターン、独立Open Promptプロジェクトとしてのローンチを生み出した類のもの。**これらの対話はブレインストーミングの記録ではない；実際の意思決定過程である。**

Future engineers regenerating from this archive may collaborate with whatever language model they choose. The reasoning patterns in these traces are reusable across model providers and across time.

このアーカイブから再生成する未来のエンジニアは、彼らが選ぶ任意の言語モデルと協働できる。これらの軌跡における推論パターンは、モデル提供者をまたぎ、時代をまたいで再利用可能である。

---

## How to contribute / 貢献の方法

See the root-level `CONTRIBUTING.md`. The CONTRIBUTING document includes a Layer 2 quality guide with worked examples covering: the `decision_points` discipline, the Tie Convention, resumption hooks, multi-AI dialogue format, and common pitfalls to avoid.

ルートの `CONTRIBUTING.md` を参照。CONTRIBUTING文書は、`decision_points` の作法、引き分け作法、再開フック、複数AI対話フォーマット、避けるべき一般的な落とし穴をカバーする具体例付きのLayer 2品質ガイドを含む。

Layer 2 contributions are placed in `contributed/[your-name]/` and released as CC0 by submission. Your authorship is preserved in the file metadata.

第2層への貢献は `contributed/[あなたの名前]/` に置かれ、提出によりCC0として公開される。あなたの著者性はファイルメタデータに保持される。

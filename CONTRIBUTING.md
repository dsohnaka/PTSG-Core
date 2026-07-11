# Contributing / 貢献について

Contributions to this repository are welcome — but the contribution model differs from a conventional open-source project. This is an Open Prompt repository, and the rules reflect its four-layer structure plus the Core-Formation separation pattern that PTSG introduces.

このリポジトリへの貢献を歓迎します——ただし、貢献モデルは従来のオープンソースプロジェクトとは異なります。これはOpen Promptリポジトリであり、ルールはその4層構造に加えてPTSGが導入するコア-フォーメーション分離パターンを反映しています。

---

## What you can contribute to this Core repository / 本コアリポジトリへの貢献内容

### Layer 1 (Architecture) — Welcome / 第1層（アーキテクチャ）— 歓迎

- Clarifications of existing specifications / 既存仕様の明確化
- Additional reasoning derivations / 追加の推論導出
- Translations into other languages / 他言語への翻訳
- Cross-references between sections / セクション間の相互参照
- Corrections of errors / 誤りの訂正

Submit via pull request. Contributed Layer 1 material is automatically released into the public domain (CC0) by the act of submission.

プルリクエストで提出してください。提出された第1層素材は、提出行為により自動的にパブリックドメイン (CC0) に公開されます。

### Layer 2 (Reasoning Traces) — Welcome / 第2層（推論軌跡）— 歓迎

- **Your own design dialogues** related to PTSG core architecture, with your own LLM collaborator or with other engineers / PTSGコアアーキテクチャに関連する、あなた自身のLLM協働者や他のエンジニアとの**自身の設計対話**
- Critiques and alternative reasoning paths / 批評と代替推論経路
- Educational walkthroughs / 教育的解説
- Translations of existing traces / 既存軌跡の翻訳

Layer 2 contributions are added under your name in `02_Reasoning_Traces/contributed/`. They are also released as CC0 by submission, but your authorship is preserved in the metadata.

第2層への貢献は `02_Reasoning_Traces/contributed/` の下にあなたの名前で追加されます。提出により CC0 として公開されますが、メタデータにあなたの著者性が保持されます。

### Layer 3 (Sample Implementations) — By Discussion / 第3層（サンプル実装）— 議論を経て

Direct contributions to the *original author's* sample implementations are accepted only by prior discussion (open an issue first). The reason: Layer 3 is the original author's reference implementation. We do not want it to gradually become a community-merged codebase, because that would obscure the Open Prompt principle that **regenerated implementations are independent works, not derivatives**.

*オリジナル著者の*サンプル実装への直接貢献は、事前議論（まず Issue を開いてください）を経た場合のみ受け入れられます。理由：第3層はオリジナル著者のリファレンス実装です。これがコミュニティでマージされたコードベースに徐々になることは望ましくありません——なぜなら、それは**再生成された実装は独立した著作物であり派生物ではない**というOpen Promptの原理を曖昧にしてしまうからです。

**If you have built your own PTSG Core implementation from this architecture**, the recommended path is **not** to merge it here, but to publish your own Open Prompt repository and link to it from a discussion thread.

### Layer 4 (Verification Evidence) — Welcome / 第4層（検証エビデンス）— 歓迎

- **Conformance evidence for this Core's reference implementation** — VCD captures, `observation.md` verdicts, and run scripts for tests you have executed against `03_Sample_Implementations/` — is welcome under `04_Verification_Evidence/contributed/[your-name]/`. Include the commit hash, tool names/versions, and (for silicon runs) the board and bitstream checksum. Released as CC0 by submission; authorship preserved in the observation metadata. / **本コアのリファレンス実装に対する適合エビデンス**——実行したテストの VCD、`observation.md` 判決、実行スクリプト——を `04_Verification_Evidence/contributed/[あなたの名前]/` に歓迎します。コミットハッシュ、ツール名/バージョン、（実機の場合）ボードとビットストリームチェックサムを含めてください。提出により CC0;著者性は observation メタデータに保持されます。
- **Negative results are first-class evidence** here — a FAIL with a good observation.md is more valuable than an undocumented PASS. / **負の結果はここでは一級のエビデンス**です——良い observation.md を伴う FAIL は、文書化されない PASS より価値があります。
- Evidence for **your own regenerated implementation** belongs in **your own repository** (mirroring the Layer 3 principle). / **あなた自身の再生成実装**のエビデンスは**あなた自身のリポジトリ**へ（第3層の原理と同じ）。

**本アーキテクチャから自身のPTSGコア実装を構築した場合**、推奨される経路は、ここにマージすることでは**なく**、自身のOpen Promptリポジトリを公開し、議論スレッドからリンクすることです。

---

## What about Formations? / フォーメーションについては?

If you have designed a **new Formation** of PTSG for a specific application (I²C, MIDI, SDRAM, real-time control, dataflow, etc.), the recommended path is **not** to submit it as a contribution to this Core repository, but to **create a new Open Prompt repository for your Formation**.

PTSGの**新しいフォーメーション**を特定応用（I²C、MIDI、SDRAM、リアルタイム制御、データフロー等）のために設計された場合、推奨される経路は、それを本コアリポジトリへの貢献として提出することでは**なく**、**あなたのフォーメーションのための新しいOpen Promptリポジトリを作成する**ことです。

Suggested naming convention: `PTSG_<Purpose>_Formation_OpenPrompt`

推奨命名規則: `PTSG_<目的>_Formation_OpenPrompt`

Examples / 例:
- `PTSG_WPMS_Formation_OpenPrompt` (first Formation, currently under design)
- `PTSG_I2C_Formation_OpenPrompt`
- `PTSG_MIDI_Formation_OpenPrompt`
- `PTSG_SDRAM_Formation_OpenPrompt`
- `PTSG_DataFlow_Formation_OpenPrompt`
- `PTSG_RealtimeControl_Formation_OpenPrompt`

Once your Formation repository is established, please open an issue here in the Core repository so we can link to it from this Core's README. The Core does not "own" the Formations — they are independent peers — but cross-referencing helps the ecosystem grow legibly.

フォーメーションリポジトリが確立されたら、本コアリポジトリでIssueを開いてください——本コアのREADMEからリンクできるようにするためです。コアはフォーメーションを「所有」しません——フォーメーションは独立した同輩です——しかし相互参照はエコシステムが可読的に成長するのを助けます。

---

## How to contribute / 貢献の手順

### For Layer 1 / 第1層

1. Open an issue describing what you propose to add or change / 追加・変更を提案する内容を記述した Issue を開く
2. Submit a pull request with the change / 変更を含むプルリクエストを提出
3. The maintainer will review for technical correctness and integration / メンテナが技術的正確性と統合性をレビュー
4. On merge, your contribution becomes part of the public-domain commons / マージ時、あなたの貢献はパブリックドメインの共有財産の一部となる

### For Layer 2 / 第2層

1. Prepare your dialogue in both Markdown (human-readable) and JSON (LLM-ingestible) formats. See existing files in `02_Reasoning_Traces/` for the format. / 対話を Markdown（人間可読）と JSON（LLM 取り込み可能）の両形式で準備する。形式については `02_Reasoning_Traces/` の既存ファイルを参照
2. Submit a pull request adding your files to `02_Reasoning_Traces/contributed/[your-name]/` / `02_Reasoning_Traces/contributed/[あなたの名前]/` にファイルを追加するプルリクエストを提出
3. Include a metadata header in your Markdown file with date, participants (you + your LLM collaborator's model name and version, if applicable), and topic / 日付、参加者（あなた + あなたのLLM協働者のモデル名とバージョン、該当する場合）、トピックを含むメタデータヘッダを Markdown ファイルに含める

### For Layer 3 / 第3層

Open an issue first. We will discuss whether the contribution belongs in the original author's reference implementation or whether it should become its own Open Prompt repository.

まず Issue を開いてください。貢献がオリジナル著者のリファレンス実装に属するか、独自のOpen Promptリポジトリとなるべきかを議論します。

---

## Layer 2 Quality Guide — The `decision_points` discipline
## 第2層の品質ガイド — `decision_points` の作法

The single most important field in a Layer 2 trace is `decision_points`. This is what distinguishes a Layer 2 reasoning trace from an ordinary chat log or brainstorm transcript. **Decision points are what make a dialogue resumable by another engineer + LLM in the future.**

第2層軌跡で最も重要なフィールドは `decision_points` です。これこそが、第2層の推論軌跡を、ありふれたチャットログやブレインストーミングの書き起こしから区別するものです。**決定ポイントこそが、対話を未来のエンジニア + LLM が再開可能なものにする**のです。

The recommended structure for each decision point is:

各決定ポイントの推奨構造は次のとおりです：

```json
{
  "point": "What was being decided (concise label)",
  "alternatives": ["option A", "option B", "option C"],
  "chosen": "the option chosen, OR 'tie' / 'left in the arena'",
  "rationale": "Why this choice — including what was traded away. Be specific about quantities (bits, ns, MHz, %) wherever possible."
}
```

This format gives a future reader (human or LLM) everything they need to either accept the decision or revisit it under different constraints. **It records what was traded away, not just what was chosen.**

このフォーマットは、未来の読者（人間または LLM）が、決定を受け入れるか異なる制約のもとで再検討するかに必要なすべてを与えます。**選択されたものだけでなく、何が犠牲になったかを記録する**のがポイントです。

---

## Open Prompt Design Patterns / Open Prompt設計パターン

The Open Prompt paradigm is developing a small catalog of named design patterns. Patterns established to date include:

Open Promptパラダイムは、名前付き設計パターンの小さなカタログを発展させています。これまでに確立されたパターンを以下に示します:

### Tie Decision Pattern / 引き分け判断パターン

When two alternatives offer comparable merit but optimize for different constraints, the right move is often to record both with their respective trade-offs and leave the choice to whoever regenerates the implementation under their own specific constraints. *Origin: FPGA Spectrum Engine, 2026-04-29 polynomial arena trace.*

二つの代替案が同等の価値を持ちつつ異なる制約に最適化している場合、しばしば正しい一手は両者を各々のトレードオフとともに記録し、各自の固有の制約の下で実装を再生成する者に選択を委ねることです。*起源: FPGA Spectrum Engine、2026-04-29多項式アリーナトレース。*

### Polynomial Bin-Sequence Pattern / 多項式ビン系列パターン

Whenever a per-bin parameter sequence can be expressed as a low-order polynomial in bin index, the difference-engine pattern (cumulative addition of polynomial differences) eliminates the need for per-bin storage. *Origin: FPGA Spectrum Engine, 2026-04-18 synthesis paradigms trace.*

ビンごとのパラメータ列をビン番号の低次多項式として表現できる任意の場合、差分エンジンパターン（多項式差分の累積加算）はビンごと記憶の必要性を消去します。*起源: FPGA Spectrum Engine、2026-04-18合成パラダイムトレース。*

### Free Precision Floor / 自由精度床

Where a hardware resource cost is discrete (1 unit or 0 units, not fractional), and where the cost does not increase with internal precision, claim the maximum precision. Before deciding what precision is needed, check whether higher precision is free; if so, take it. *Origin: FPGA Spectrum Engine, 2026-05-02 WPMS Layer 1 trace.*

ハードウェアリソースコストが離散的で（1単位か0単位か、小数値ではない）、内部精度を上げてもコストが増加しない場合、最大精度を主張せよ。何の精度が必要かを決定する前に、より高い精度が無料かどうかを確認せよ；そうであれば、それを取れ。*起源: FPGA Spectrum Engine、2026-05-02 WPMS Layer 1トレース。*

### Spin-Off-Ready Subsystem / 暖簾分け準備済みサブシステム

When a subsystem could plausibly be developed as an independent project, structure the integration so that the subsystem can be forked out later without damage. Manifests in (a) clear interface boundary, (b) explicit fork-friendly documentation, (c) avoidance of dependencies that would require the larger project's continuation. *Origin: FPGA Spectrum Engine, 2026-05-02 WPMS Layer 1 trace (camera block).*

サブシステムが独立プロジェクトとして発展し得る場合、サブシステムが後に損傷なくフォーク可能であるよう統合を構造化せよ。(a)明確なインターフェース境界、(b)明示的なフォーク親和的文書、(c)より大きなプロジェクトの継続を要求する依存関係の回避、に現れる。*起源: FPGA Spectrum Engine、2026-05-02 WPMS Layer 1トレース（カメラブロック）。*

### Core-Formation Separation / コア-フォーメーション分離

When a primitive can serve many different application domains, separate it into (a) a minimal invariant Core repository defining the primitive's instruction set and external interface contract, and (b) per-application Formation repositories that build atop the Core with their own external registers, peripheral logic, and conventions. Formations are not required to be binary-compatible with each other; the Core's vocabulary is the shared genetic code. *Origin: PTSG, 2026-05-XX strategic-positioning trace (THIS REPOSITORY).*

プリミティブが多くの異なる応用領域に奉仕し得る場合、(a)プリミティブの命令セットと外部インターフェース契約を定義するミニマルで不変なコアリポジトリと、(b)独自の外部レジスタ、ペリフェラルロジック、慣習でコアの上に構築する応用別フォーメーションリポジトリに分離せよ。フォーメーションは互いにバイナリ互換である必要はなく、コアの語彙が共有された遺伝コードである。*起源: PTSG、2026-05-XX戦略的位置づけトレース（本リポジトリ）。*

---

## Common pitfalls to avoid / 避けるべき一般的な落とし穴

1. **Verbatim transcripts without curation** — A pure dump of every word said is harder to use, not easier. Curate to extract decisions and reasoning. / **キュレーションのない逐語記録** — 言われたすべての言葉のダンプは、使いやすくなるどころか使いにくくなる。決定と推論を抽出するためにキュレーションする
2. **Decisions without rationale** — "We chose X" with no explanation cannot be reconsidered. Always record why. / **根拠なき決定** — 説明のない「Xを選んだ」は再検討できない。常に「なぜ」を記録する
3. **Hidden alternatives** — If you considered an option and rejected it, name it. Future readers may face new constraints under which the rejected option becomes correct. / **隠された選択肢** — 検討して却下した選択肢があれば名指しする。未来の読者は、却下された選択肢が正しくなる新しい制約に直面するかもしれない
4. **Markdown without JSON, or JSON without Markdown** — Both formats are required. Markdown for humans, JSON for LLMs. They are not redundant; they serve different readers. / **JSONなしのMarkdown、またはMarkdownなしのJSON** — 両形式が必須。Markdownは人間のため、JSONはLLMのため。これらは冗長ではない。異なる読者に奉仕する
5. **No resumption hooks** — A trace without resumption hooks is a tomb, not a launching pad. Always leave 2–5 explicit starting questions. / **再開フックなし** — 再開フックのない軌跡は墓場であり、発射台ではない。常に2〜5の明示的な開始質問を残す

---

## Code of conduct / 行動規範

Be respectful, technically rigorous, and intellectually honest. Disagree about ideas, not people. Engage with the strongest version of others' arguments.

敬意を持ち、技術的に厳密に、知的に誠実に。アイデアについて意見を異にし、人について意見を異にしないこと。他者の主張の最強の版に応答すること。

---

## Questions / 質問

Open an issue with the `question` label, or contact the maintainer via the Hackaday.io project page.

`question` ラベル付きの Issue を開くか、Hackaday.io プロジェクトページからメンテナに連絡してください。

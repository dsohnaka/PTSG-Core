# Contributed Reasoning Traces / 貢献された推論軌跡

This directory holds reasoning traces contributed by engineers, researchers, and educators other than the original author.

このディレクトリは、オリジナル著者以外のエンジニア、研究者、教育者によって貢献された推論軌跡を保持します。

To contribute, see the root-level `CONTRIBUTING.md`. Place your trace under a subdirectory named for yourself, e.g.:

貢献するには、ルートの `CONTRIBUTING.md` を参照してください。あなた自身の名前のサブディレクトリの下に軌跡を配置してください。例：

```
contributed/
  jane-doe/
    2026-06-15_ptsg-opcode-extension-experiment.md
    2026-06-15_ptsg-opcode-extension-experiment.json
```

Each contributed trace is released as CC0 by submission, but your authorship is preserved in the file metadata.

貢献された各軌跡は提出によりCC0として公開されますが、あなたの著者性はファイルメタデータに保持されます。

---

## What makes a good contributed trace? / 良い貢献軌跡とは?

Traces that are most valuable to the PTSG ecosystem include:

PTSGエコシステムにとって最も価値ある軌跡は以下を含みます:

- **Design dialogues for new Formations.** If you designed (or are designing) a new PTSG Formation for a specific application — I²C, MIDI, SDRAM, motor control, sensor fusion, etc. — the dialogue that led to your Formation's design decisions is valuable Layer 2 material. (Note: the Formation itself should typically be its own Open Prompt repository; but a "design journal" trace can also live here in the Core repository, especially if it touches on Core-level questions.) / **新フォーメーションの設計対話。** 特定応用——I²C、MIDI、SDRAM、モータ制御、センサ融合等——のための新しいPTSGフォーメーションを設計した（または設計中の）場合、そのフォーメーションの設計決定に至った対話は貴重なLayer 2素材です。（注: フォーメーション自体は典型的に独自のOpen Promptリポジトリであるべきですが、コアレベルの問いに触れる「設計日誌」軌跡は本コアリポジトリ内にも存在し得ます、特にコアレベルの問題に関わる場合。）

- **Educational walkthroughs.** Dialogues that take a beginner through PTSG concepts step by step, exposing the questions that arise naturally during learning. / **教育的解説。** 初心者をPTSGコンセプトを通じて段階的に導き、学習中に自然に生じる問いを露わにする対話。

- **Critiques and alternative designs.** Dialogues exploring "what if PTSG had been designed differently?" — alternative opcode sets, alternative memory layouts, alternative external interface contracts. These are valuable because they map out the neighborhood of design space around the current PTSG, helping future architects understand which choices are essential vs incidental. / **批評と代替設計。** 「PTSGが違った形で設計されていたら?」を探究する対話——代替オペコードセット、代替メモリレイアウト、代替外部インターフェース契約。これらは、現在のPTSG周辺の設計空間の近傍をマップアウトし、どの選択が本質的でどの選択が偶発的かを将来のアーキテクトが理解するのに役立つため貴重です。

- **Multi-AI dialogues.** If you posed the same PTSG design question to multiple LLMs (Claude, Gemini, ChatGPT, ClaudeCode, etc.) and the divergence between their responses revealed something interesting, that comparison is valuable. / **複数AIとの対話。** 同じPTSG設計質問を複数のLLM（Claude、Gemini、ChatGPT、ClaudeCode等）に投げかけ、それらの応答の分岐が興味深い何かを明らかにした場合、その比較は貴重です。

- **Application case studies.** If you used PTSG (or a PTSG Formation) in a real project — production hardware, research instrument, educational kit — the dialogue surrounding the integration is valuable for future adopters facing similar applications. / **応用ケーススタディ。** PTSG（またはPTSGフォーメーション）を実プロジェクト——生産ハードウェア、研究器具、教育キット——に用いた場合、統合を取り巻く対話は類似応用に直面する将来の採用者にとって貴重です。

---

## Format requirements / フォーマット要件

See `CONTRIBUTING.md` for the full quality guide. The minimum requirements:

完全な品質ガイドについては `CONTRIBUTING.md` を参照。最低要件:

- Both `.md` (human-readable) and `.json` (LLM-ingestible) versions / `.md`（人間可読）と`.json`（LLM取り込み可能）の両版
- Metadata header with date, participants, topic / 日付、参加者、トピックを含むメタデータヘッダ
- At least 2-5 `decision_points` with rationale / 根拠付きの2〜5個以上の `decision_points`
- At least 2-5 `resumption_hooks` (specific, actionable starting questions for future dialogue) / 2〜5個以上の `resumption_hooks`（具体的で行動可能な、将来の対話のための開始質問）

---

> *The Layer 2 of an Open Prompt repository is not a closed text. It is a continuing conversation. Your trace adds a new voice to that conversation.*
>
> *Open Promptリポジトリの第2層は閉じられたテキストではない。それは継続する会話である。あなたの軌跡はその会話に新しい声を加える。*

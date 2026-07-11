# LICENSE — Open Prompt Declaration / Open Prompt宣言

This repository is distributed under the **Open Prompt** paradigm, a three-layer knowledge-sharing scheme. Each layer carries its own license terms.

このリポジトリは**Open Prompt**パラダイム——3層構造の知識共有スキーム——のもとに配布されます。各層は独自のライセンス条項を持ちます。

---

## Layer 1 — Architectural Specification / アーキテクチャ仕様

**License: CC0 1.0 Universal (Public Domain Dedication)**

All content under `01_Architecture/` is dedicated to the public domain via CC0 1.0 Universal. To the extent possible under law, the author has waived all copyright and related rights to this work.

`01_Architecture/` 配下のすべてのコンテンツは、CC0 1.0 Universal によりパブリックドメインに献呈されます。法律の許す限り、著者は本著作物に関するすべての著作権および関連する権利を放棄しています。

You may copy, modify, distribute, and use the architectural specifications, including for commercial purposes, without asking permission and without attribution.

アーキテクチャ仕様の複製、改変、配布、利用——商用目的を含む——を、許可を求めることなく、帰属表示なしに行うことができます。

Full CC0 text: https://creativecommons.org/publicdomain/zero/1.0/

---

## Layer 2 — Reasoning Traces / 推論軌跡

**License: CC0 1.0 Universal (Public Domain Dedication)**

All content under `02_Reasoning_Traces/` is dedicated to the public domain via CC0 1.0 Universal. This includes both human-readable Markdown conversations and LLM-ingestible JSON exports.

`02_Reasoning_Traces/` 配下のすべてのコンテンツは、CC0 1.0 Universal によりパブリックドメインに献呈されます。これには人間可読の Markdown 対話と LLM 取り込み可能な JSON エクスポートの両方が含まれます。

Engineers, researchers, and educators are explicitly encouraged to replay these dialogues with their own language model collaborators and resume the reasoning from where it was left off.

エンジニア、研究者、教育者が、自身の言語モデル協働者とこれらの対話を再生し、中断された地点から推論を再開することを明示的に推奨します。

---

## Layer 3 — Sample Implementations / サンプル実装

**License: MIT License (or as otherwise specified per artifact)**

All sample implementations under `03_Sample_Implementations/` are released under the MIT License unless otherwise specified within individual subdirectories. See `03_Sample_Implementations/README.md` for any per-artifact license variations.

`03_Sample_Implementations/` 配下のすべてのサンプル実装は、各サブディレクトリ内で別途指定がない限り、MIT ライセンスで公開されます。アーティファクトごとのライセンス差異については `03_Sample_Implementations/README.md` を参照してください。

**Important:** A regenerated implementation produced by another engineer from Layer 1 and Layer 2 is **not a derivative work** of these samples. The regenerator owns their implementation outright and may license it however they choose.

**重要：** 第1層と第2層から他のエンジニアが再生成した実装は、これらのサンプルの**派生物ではありません**。再生成者はその実装を完全に所有し、任意のライセンスを選択できます。

---

## On Formation repositories / フォーメーションリポジトリについて

The PTSG ecosystem extends Open Prompt with the **Core-Formation separation pattern**. Each Formation (e.g., `PTSG_WPMS_Formation_OpenPrompt`) is an independent Open Prompt repository with its own three layers and its own license file.

PTSGエコシステムは、**コア-フォーメーション分離パターン**でOpen Promptを拡張します。各フォーメーション（例: `PTSG_WPMS_Formation_OpenPrompt`）は独自の三層と独自のライセンスファイルを持つ独立したOpen Promptリポジトリです。

Formations share the Core's instruction set vocabulary but are not constrained to be binary-compatible with each other or with the Core's Layer 3 samples. A Formation's Layer 1 and Layer 2 are typically also released as CC0; a Formation's Layer 3 typically uses MIT or another permissive license, but Formation authors are free to choose.

フォーメーションはコアの命令セット語彙を共有しますが、互いに、またはコアのLayer 3サンプルとバイナリ互換であることを強いられません。フォーメーションのLayer 1とLayer 2は典型的にもCC0として公開され、フォーメーションのLayer 3は典型的にMITまたは他の寛容なライセンスを用いますが、フォーメーション著者は自由に選択できます。

---

## The Open Prompt Paradigm — Summary / Open Promptパラダイム — 要約

The structural innovation of Open Prompt is the recognition that, in the era of capable language models, the **bottleneck of engineering knowledge transfer has shifted upstream** — from source code to architectural specifications and reasoning traces.

Open Promptの構造的革新は、有能な言語モデルの時代において、**工学知識転送のボトルネックが上流に移動した**——ソースコードからアーキテクチャ仕様と推論軌跡へ——という認識にあります。

| Layer | Content | License | Owner |
|---|---|---|---|
| 1 | Architecture | CC0 (public domain) | No one / everyone |
| 2 | Reasoning traces | CC0 (public domain) | No one / everyone |
| 3 | Sample implementations | MIT (or as specified) | The author of each artifact |
| 3 (regenerated) | Other engineers' implementations | At each engineer's discretion | The regenerating engineer |
| 4 | Hardware verification evidence | CC0 (public domain) | No one / everyone |

For the full philosophical declaration, see Build Log #4 of [FPGA Spectrum Engine](https://hackaday.io/project/205582-fpga-spectrum-engine), the parent project from which PTSG was spun off.

完全な哲学的宣言については、PTSGが暖簾分けされた親プロジェクト[FPGA Spectrum Engine](https://hackaday.io/project/205582-fpga-spectrum-engine)のBuild Log #4を参照してください。

---

## Adopting Open Prompt for your own project / あなた自身のプロジェクトでOpen Promptを採用する

To adopt Open Prompt for another project:

他のプロジェクトでOpen Promptを採用するには：

1. **Structure your repository** in the three- or four-layer template (or a clearly-derived variant, such as the Core-Formation pattern). / リポジトリを3層または4層テンプレート（またはコア-フォーメーションパターンのような明確に派生した変種）に従って構造化する
2. **Place Layer 1 and Layer 2 in the public domain** via CC0 1.0. / 第1層と第2層を CC0 1.0 によりパブリックドメインに置く
3. **License Layer 3 as you choose.** Permissive licenses are recommended. / 第3層を任意のライセンスにする。寛容なライセンスを推奨
4. **Include an Open Prompt declaration** in your repository — referencing this file or providing your own equivalent. / リポジトリにOpen Prompt宣言を含める——本ファイルへの参照、または自身の同等宣言で
5. **Maintain the reasoning trace** as the project progresses. Layer 2 accumulates over time. / プロジェクトの進展とともに推論軌跡を維持する。第2層は時間とともに蓄積する

There is no central registry, no certifying body, no required attribution beyond what each contributing engineer chooses for their own Layer 3.

中央レジストリも、認証団体も、各貢献エンジニアが自身の第3層に対して選ぶもの以外の必須帰属表示もありません。

---

*PTSG Core repository established May 2026 as the second Open Prompt repository, and the first to extend Open Prompt with the Core-Formation separation pattern.*
*PTSGコアリポジトリは2026年5月、Open Promptの二番目のリポジトリとして、またコア-フォーメーション分離パターンでOpen Promptを拡張する最初のものとして確立。*

*Parent project: [FPGA Spectrum Engine](https://hackaday.io/project/205582-fpga-spectrum-engine) (inaugural Open Prompt repository, established April 2026).*
*親プロジェクト: [FPGA Spectrum Engine](https://hackaday.io/project/205582-fpga-spectrum-engine)（最初のOpen Promptリポジトリ、2026年4月確立）。*

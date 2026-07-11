# Layer 4 — Verification Evidence / 検証エビデンス

> **License: CC0 1.0 Universal (Public Domain)** for evidence documents and traces;
> conformance programs under MIT (see per-directory notes). Evidence is meant to be
> cited and reused freely.
>
> **ライセンス：検証文書と軌跡は CC0 1.0 Universal（パブリックドメイン）；適合プログラムは
> MIT（ディレクトリ毎の注記を参照）。** エビデンスは自由に引用・再利用されるためにある。

---

## What this layer is / この層とは何か

Layer 4 records **whether the implemented Core actually behaves as Layer 1 specifies** —
the empirical counterpart to Layer 2. Where Layer 2 documents *why* the design is what it
is (the provenance of decisions), Layer 4 documents *whether the build is true* (the
provenance of behavior). The two are sisters: one carries intellectual provenance, the
other empirical provenance.

Layer 4 は、**実装されたコアが実際に Layer 1 の規定通りに振る舞うか**を記録する——Layer 2
の経験的対応物である。Layer 2 が設計が*なぜ*そうなのか(決定の来歴)を文書化するのに対し、
Layer 4 は*構築が真であるか*(振る舞いの来歴)を文書化する。両者は姉妹である: 一方は知的
来歴を、他方は経験的来歴を運ぶ。

| Layer | Question | Nature |
|---|---|---|
| 1 — Architecture | What the Core **is** / コアは**何**か | Normative / 規範的 |
| 2 — Reasoning Traces | **Why** this design / **なぜ**この設計か | Intellectual provenance / 知的来歴 |
| 3 — Sample Implementations | **How** to build it (one way) / **どう**作るか(の一例) | Illustrative / 例示的 |
| **4 — Verification Evidence** | Does the build behave **as specified** / 構築は仕様**通り**か | **Empirical provenance / 経験的来歴** |

**Why this matters.** Without Layer 4, "the design is justified" (Layer 2) and "an
implementation exists" (Layer 3) sit side by side with nothing connecting them to "and it
provably works." Layer 4 is that connection — and, just as importantly, it makes the
**un**verified parts impossible to hide.

**なぜ重要か。** Layer 4 なしでは、「設計は正当である」(Layer 2)と「実装が存在する」
(Layer 3)が、「そして証明可能に動く」へ繋がるものなしに並んでいる。Layer 4 がその繋がり
である——そして同じく重要なことに、**未**検証の部分を隠せなくする。

---

## The Layer 2 ↔ Layer 4 loop / Layer 2 ↔ Layer 4 のループ

Layer 2 traces end with **Resumption Hooks** — open questions handed forward. Layer 4
answers them with **evidence**. A hook issues a task; an evidence entry returns a verdict.
This is the project's verification engine: the reasoning layer asks, the evidence layer
answers, and `conformance_matrix.md` keeps score.

Layer 2 の軌跡は **再開フック** で終わる——前へ手渡された未決の問い。Layer 4 はそれらに
**エビデンス**で答える。フックが課題を発行し、エビデンス項目が評決を返す。これがプロジェクト
の検証エンジンである: 推論層が問い、エビデンス層が答え、`conformance_matrix.md` が得点を
記録する。

The first hook in the queue is **Hook A** of the 2026-06-11 bring-up trace: the residual
anomaly in the aligned waveform, leading suspect being free-running-prescaler phase jitter.
Its conformance program is `conformance_suite/prescaler_phase_measurement/`.

待ち行列の最初のフックは 2026-06-11 ブリングアップ軌跡の **Hook A**: 整列波形の残る違和感、
第一容疑は自由走行プリスケーラの位相ジッタ。その適合プログラムは
`conformance_suite/prescaler_phase_measurement/` である。

---

## Directory structure / ディレクトリ構造

```
04_Verification_Evidence/
├── README.md                    ← this file / 本ファイル
├── conformance_matrix.md        ← the front door: spec item × verification state
│                                   玄関口: 仕様項目 × 検証状態
│
├── conformance_suite/           ← verification PTSG programs (NOT teaching examples)
│   └── <feature>/               検証用 PTSG プログラム（教育用 examples ではない）
│       ├── program.{hex,mif}    ← the stimulus instruction list
│       └── expected.md          ← expected behavior, derived from Layer 1
│
├── modelsim/                    ← white-box evidence (all internal signals visible)
│   └── runs/YYYY-MM-DD_<feature>/   ホワイトボックス証拠
│       ├── run.do               ← ★ reproducible recipe (the primary artifact)
│       ├── observation.md       ← the verdict: what was seen, vs expected
│       └── waveform.vcd.gz      ← small representative VCD only (see capacity policy)
│
└── signaltap/                   ← black-box evidence (limited window, real silicon)
    └── <board>/YYYY-MM-DD_<feature>/   ブラックボックス証拠（実シリコン）
        ├── stp_config.md        ← probe & trigger setup
        ├── observation.md       ← the verdict
        ├── capture.vcd.gz       ← silicon capture (kept: hard to regenerate)
        └── capture.png          ← optional aid, embedded in the verdict
```

---

## Evidence discipline / エビデンスの規律

### Waveforms are VCD, not screenshots / 波形は VCD、スクリーンショットではない

Both ModelSim and SignalTap export to **VCD** (SignalTap via File → Export → VCD). VCD is
text (git-diffable), holds **all** captured signals (re-examinable for signals not thought
of at capture time), and is parseable by both humans (GTKWave) and AI agents (by value, not
by eye). **PNG screenshots are demoted to optional aids** embedded inside a verdict
document; the primary evidence is always the VCD.

ModelSim と SignalTap は両方とも **VCD** にエクスポートする(SignalTap は File → Export →
VCD)。VCD はテキスト(git で差分可能)、捕捉した**全**信号を保持(捕捉時に思いつかなかった
信号も後から再検査可能)、人間(GTKWave)と AI エージェント(目視でなく値で)の両方が解析可能。
**PNG スクリーンショットは任意の補助に降格**され、判決文書の中に埋め込まれる;主たる証拠は
常に VCD である。

### A VCD without an observation.md is meaningless / observation.md なき VCD は無意味

A raw VCD says *what the signals did* but not *what it means*. Every VCD **must** be
accompanied by an `observation.md` — the verdict document — stating: what was being
measured; which signals to look at (an unguided VCD is a maze); what happened at which time
(ns); how that compares to `expected.md`; and the conclusion (**PASS / FAIL / ANOMALY**).
The VCD is the original record; the observation.md is the judgment.

生の VCD は*信号が何をしたか*を語るが*それが何を意味するか*は語らない。すべての VCD は
`observation.md`(判決文書)を**必ず**伴わなければならない——記載事項: 何を測ろうとしたか;
どの信号を見るべきか(指定なしの VCD は迷路);何時刻(ns)に何が起きたか;それが
`expected.md` とどう照合するか;結論(**PASS / FAIL / ANOMALY**)。VCD は原本、observation.md
は判決である。

### expected before observed / 観察の前に期待

A conformance entry states its `expected.md` (derived from Layer 1) **before** the run,
not after. Predicting first, then observing, is what lets a result distinguish
"prediction matched → implementation understood" from "prediction diverged → a discovery."
This is the discipline that turned address `05h` from a curiosity into proof (Build Log #6).

適合項目は、実行の**前**に(後ではなく)その `expected.md`(Layer 1 由来)を述べる。まず予測し、
それから観察することが、結果を「予測一致 → 実装理解」と「予測乖離 → 発見」に区別させる。
これがアドレス `05h` を好奇心から証明へと変えた規律である(Build Log #6)。

---

## Capacity policy / 容量ポリシー

Layer 4 will grow large. VCD is verbose — a single multi-signal run can reach hundreds of
MB before compression. The policy below keeps the repository sustainable.

Layer 4 は巨大に育つ。VCD は冗長で——一回の多信号実行は圧縮前で数百 MB に達し得る。以下の
ポリシーがリポジトリを持続可能に保つ。

**The governing principle: keep the recipe for what is reproducible; keep the evidence for
what is not.**

**統べる原理: 再現可能なものはレシピを保持し、再現困難なものはエビデンスを保持する。**

| Evidence type | Reproducible? | What goes in git |
|---|---|---|
| ModelSim run / ModelSim 実行 | Yes — from `run.do` + the Core sources | **`run.do` + `observation.md`**; the VCD is regenerated on demand and *not* normally committed / VCD は随時再生成、通常コミットしない |
| ModelSim VCD, small & illustrative (< ~1 MB gzipped) | Yes, but handy to keep | Commit `waveform.vcd.gz` as a convenience / 利便のため `.vcd.gz` をコミット |
| SignalTap capture / SignalTap キャプチャ | **No** — that board, that moment | **Commit `capture.vcd.gz`** (gzipped); this is the high-value, irreproducible evidence / gzip してコミット;高価値・再現困難な証拠 |
| Any VCD > ~50 MB gzipped | — | **Do not commit.** Store externally; record the SHA-256 and the external link in `observation.md` / コミットしない。外部保管し、SHA-256 と外部リンクを記録 |

### Compression / 圧縮

VCD is text and compresses well — gzip typically reaches 15–25% of the original. Commit as
`*.vcd.gz`; GTKWave opens `.gz` transactionally and AI agents decompress trivially. (FST
would be smaller still but sacrifices the cross-tool universality of VCD; gzip-VCD is the
chosen balance.)

VCD はテキストでよく圧縮される——gzip は典型的に元の 15-25% に達する。`*.vcd.gz` で
コミット;GTKWave は `.gz` を透過的に開き、AI も容易に解凍する。(FST はさらに小さいが VCD の
クロスツール汎用性を犠牲にする;gzip-VCD が選ばれた均衡点。)

### Video evidence / 動画エビデンス

Public demonstration videos (the live-improvisation series) are produced as **log-side storytelling, outside this layer** — but each demonstration's plan, frozen predictions, and results ARE Layer 4 material. The rule (ruled 2026-07-10): the video file itself is not committed; its `observation.md` records the **YouTube URL, the local master filename, the commit hash, the bitstream checksum, and the filming date**. Predictions are frozen before filming and never edited afterward. The video is auxiliary evidence, peer to a screenshot; where a scope/SignalTap capture of the same run exists, that capture remains the primary record.

公開実演動画(インプロビゼーション実演シリーズ)は**本層の外の、ログ側の演出**として制作される——ただし各実演の計画・凍結済み予言・結果は Layer 4 の資料である。規則(2026-07-10 裁定): 動画ファイル自体はコミットしない;その `observation.md` に **YouTube URL・ローカル原本ファイル名・コミットハッシュ・ビットストリームチェックサム・撮影日**を記録する。予言は撮影前に凍結し、以後編集しない。動画はスクリーンショットと同格の補助エビデンスであり、同一ランのオシロ/SignalTap キャプチャが存在する場合はそちらが一次記録である。

### External storage: Zenodo / 外部保管: Zenodo

Large or long raw captures are deposited to **Zenodo**, which assigns a **DOI** — making
the evidence formally citable from Hackaday build logs, papers, and other Open Prompt
repositories. The `observation.md` records the DOI, the SHA-256, and the file description.
Internet Archive is an acceptable fallback. **Git LFS is deliberately NOT used** — the
small-in-git / large-in-Zenodo two-tier rule keeps the repository simple and keeps forks
working without an LFS pull.

大きい、または長い生キャプチャは **Zenodo** に供託され、**DOI** が割り当てられる——
エビデンスを Hackaday ビルドログ、論文、他の Open Prompt リポジトリから正式に引用可能にする。
`observation.md` が DOI、SHA-256、ファイル説明を記録する。Internet Archive は許容される
フォールバック。**Git LFS は意図的に使用しない**——git に小・Zenodo に大、の二段ルールが
リポジトリを単純に保ち、LFS pull なしでフォークを機能させる。

### .gitignore / .gitignore

Layer 4 work excludes from git: uncompressed `*.vcd`, ModelSim `work/`, `*.wlf`,
`transcript` (the live ModelSim transcript; curated excerpts go into `observation.md`),
and any capture exceeding the size threshold above.

Layer 4 作業は git から除外する: 非圧縮 `*.vcd`、ModelSim `work/`、`*.wlf`、`transcript`
(ライブの ModelSim transcript;選別した抜粋は `observation.md` へ)、および上記サイズ閾値を
超えるキャプチャ。

---

## The examples promotion pipeline / examples 昇格パイプライン

Layer 4 and Layer 3's `examples/` have a defined relationship. A PTSG program is born in
Layer 4 as a **conformance stimulus** (a thing that proves something), is verified, and —
once it both passes and reads well as a demonstration — is **refined and promoted** to
Layer 3 `examples/` as a **teaching reference** (a thing that shows how). The two roles are
distinct: conformance programs are *evidence*; examples are *pedagogy*.

Layer 4 と Layer 3 の `examples/` には定義された関係がある。PTSG プログラムは Layer 4 で
**適合スティミュラス**(何かを証明するもの)として生まれ、検証され——通過しかつ実演として
読みやすくなった時点で——**精錬され昇格して** Layer 3 `examples/` に **教育用参照**(どう使うか
を示すもの)として置かれる。二つの役割は別個である: 適合プログラムは*証拠*、examples は*教育*。

**Provisional status of the current Layer 3 examples.** The five programs currently in
Layer 3 `examples/` were authored by an AI coding agent to pass its own testbench (Build
Log #5); only `blinky_with_prescaler` has been exercised on silicon. They are therefore
marked **provisional** in the Layer 3 README pending Layer 4 re-verification. As each
passes Layer 4 (simulation and, where applicable, silicon), its provisional mark is lifted
and it becomes **verified**, with a link back to the Layer 4 evidence entry that earned the
promotion.

**現 Layer 3 examples の暫定状態。** Layer 3 `examples/` の現 5 プログラムは、AI コーディング
エージェントが自身のテストベンチを通すために執筆したもの(Build Log #5);実機で動かしたのは
`blinky_with_prescaler` のみ。ゆえに Layer 4 再検証待ちとして Layer 3 README で**暫定**と
マークされる。各々が Layer 4(シミュレーション、および該当時は実機)を通過するごとに、暫定
マークが外れて**検証済み**となり、昇格をもたらした Layer 4 エビデンス項目へのリンクが付く。

---

## How to add an evidence entry / エビデンス項目の追加方法

1. Pick a target: a Layer 2 hook, a `conformance_matrix.md` gap, or a known coverage hole.
2. Write `conformance_suite/<feature>/program.{hex,mif}` + `expected.md` (expected **first**).
3. Run it: ModelSim (`run.do` → VCD) and/or SignalTap (capture → export VCD).
4. Write `observation.md` — the verdict, comparing observed to expected.
5. Apply the capacity policy (commit `run.do`/small VCD/`capture.vcd.gz`; Zenodo the large).
6. Update `conformance_matrix.md`.
7. On ANOMALY: diagnose whether the fault is in the implementation or the specification, and
   route the fix (Layer 3 source revision, or a Layer 1 Tie/decision revision).
8. When a cluster of entries closes a theme, it becomes Build Log material.

1. 標的を選ぶ: Layer 2 フック、`conformance_matrix.md` の空白、既知のカバレッジ穴。
2. `conformance_suite/<feature>/` にプログラムと `expected.md` を書く(期待を**先に**)。
3. 実行: ModelSim(`run.do` → VCD)および/または SignalTap(キャプチャ → VCD エクスポート)。
4. `observation.md` を書く——観察を期待と照合した判決。
5. 容量ポリシーを適用(`run.do`/小 VCD/`capture.vcd.gz` をコミット;大は Zenodo)。
6. `conformance_matrix.md` を更新。
7. ANOMALY の場合: 障害が実装側か仕様側かを診断し、修正を経路付け(Layer 3 ソース改訂、
   または Layer 1 の Tie/決定改訂)。
8. 項目群が一つのテーマを閉じたら、Build Log の素材になる。

---

> *Layer 2 says why it should work. Layer 3 says here is one that does. Layer 4 says — and
> here is the proof, sampled the way the silicon sampled it.*
>
> *Layer 2 はなぜ動くべきかを言う。Layer 3 はここに動くものがあると言う。Layer 4 は——
> そしてここに証拠がある、シリコンがサンプルしたのと同じ方法でサンプルされた、と言う。*

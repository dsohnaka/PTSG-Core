# AI-Friendly Vendor Wrappers / AI 親和ベンダラッパー

> **License: MIT.** Vendor-abstracted modules that let an AI agent verify the whole
> design against behavioral models while the human synthesizes for real silicon —
> **both branches honoring the same machine-checked timing contract.**
>
> **ライセンス: MIT。** AI エージェントが behavioral モデルで設計全体を検証でき、
> 人間が実シリコン向けに合成できる、ベンダ抽象化モジュール群——**両ブランチが
> 同一の、機械検証された タイミング契約に従う。**

---

## The problem these wrappers solve / これらのラッパーが解決する問題

AI coding agents systematically avoid vendor IP. Asked to "use M10K," they leave the
spot empty and answer "please do this part yourself in the IP Catalog" — and the same
for PLLs and standard IP generally. The root causes are structural, not attitudinal:

AI コーディングエージェントはベンダ IP を組織的に避ける。「M10K を使って」と頼んでも
その箇所を残し、「ここは IP カタログでご自身で」と答える——PLL や標準 IP 全般でも同様。
根本原因は態度ではなく構造にある:

1. **Vendor simulation libraries are unavailable to AI environments.** `altera_mf`,
   `cyclonev_atoms`, etc. ship only with Quartus / ModelSim-Altera. An agent in a
   general-purpose environment (Icarus Verilog, Verilator) cannot even *elaborate* a
   design instantiating `altsyncram`, let alone verify it. An agent that cannot verify
   will not ship — so it retreats to what it can verify.
2. **IP generation is a GUI/tool-flow step** the agent cannot execute.
3. **Inference-style RTL is the trained best practice** — usually correctly so; the
   danger is when the inferred model silently assumes timing the silicon cannot provide
   (e.g., asynchronous read, which no M10K has).

1. **ベンダシミュレーションライブラリが AI 環境に無い。** 検証できないエージェントは
   納品しない——だから検証できるものへ退却する。
2. **IP 生成はエージェントが実行できない GUI/ツールフロー工程。**
3. **推論スタイル RTL が訓練上のベストプラクティス**——通常はそれで正しい；危険は、
   推論されたモデルがシリコンの提供できないタイミング(例: 非同期読み——M10K には
   存在しない)を黙って仮定する時である。

**The countermeasure: don't fight the avoidance — remove its cause.** Each wrapper
provides two `generate` branches behind one port list:

**対策: 回避と戦わず、その原因を除去する。** 各ラッパーは一つのポートリストの背後に
二つの `generate` ブランチを提供する:

| Branch | Who uses it | What it is |
|---|---|---|
| `VENDOR="SIM"` | AI agents, CI, any simulator / AI エージェント、CI、任意のシミュレータ | Portable behavioral model, **no vendor library required** / 可搬 behavioral モデル、**ベンダライブラリ不要** |
| `VENDOR="<vendor>"` (e.g. `"M10K"`) | Human, Quartus / 人間、Quartus | The real vendor primitive (altsyncram, altera_pll, …) / 実ベンダプリミティブ |

The consuming design is written once and never touched when switching branches.

利用側の設計は一度書けば、ブランチ切替時に触らない。

---

## The iron rules / 鉄則

These rules are what make the pattern *correctness*, not mere convenience. A wrapper
violating them merely relocates the sim/synth mismatch inside itself.

これらの規則がパターンを単なる便利でなく*正しさ*にする。違反するラッパーは sim/synth
ミスマッチを自身の内側へ移設するだけである。

1. **Latency fidelity.** The SIM branch reproduces the silicon's timing *exactly* —
   same latency, same clock edge, same pipeline depth. A "convenient" zero-latency sim
   model behind a registered hardware model is forbidden. / **レイテンシ忠実性。**
   SIM ブランチはシリコンのタイミングを*正確に*再現する——同じレイテンシ、同じクロック
   エッジ、同じパイプライン段数。登録読みハードモデルの陰の「都合のよい」レイテンシ0
   sim モデルは禁止。
2. **One contract, both branches.** Every timing-relevant choice is an explicit
   parameter (e.g., `RD_LAT`, `EDGE`) applied to *both* branches by the same
   expression — never decided independently per branch. / **一つの契約、両ブランチ。**
   タイミングに関わる選択はすべて明示的パラメータとし、同一の式で*両*ブランチに適用——
   ブランチ毎に独立に決めない。
3. **The contract is machine-checked.** Each wrapper ships a self-checking contract
   testbench, runnable in any simulator, that samples signals **the way the consumer
   consumes them** (e.g., registered at the consuming clock edge — not at testbench-
   convenient delays after the edge). Prose comments deceive even their own authors;
   checkers do not. / **契約は機械検証される。** 各ラッパーは、任意のシミュレータで
   走る自己チェック契約テストベンチを同梱し、信号を**消費者が消費するのと同じ方法で**
   サンプルする。散文コメントは著者すら欺く；チェッカーは欺かない。
4. **The contract is stated in the header.** Latency, edges, reset behavior, and the
   consuming-side obligations are written at the top of the wrapper file, bilingually.
   / **契約はヘッダに明記される。** レイテンシ、エッジ、リセット挙動、利用側の義務を
   ラッパーファイル冒頭に日英で書く。

Why rule 3 is non-negotiable: during this collection's first week, the exact question
*"which value exists at the sampling moment?"* tripped the original core implementer
(zero-latency assumption), the hardware (a one-clock stale instruction fetch,
photographed by SignalTap as an address that cannot occur in correct execution), and
the contract-verifier itself (twice, in opposite directions, in its own testbench).
See Build Log #6 and the 2026-06-11 Layer 2 trace.

規則 3 が交渉不能である理由: 本コレクション最初の一週間で、*「サンプリングの瞬間に
どの値が存在するか」*というまさにその問いが、元のコア実装者(レイテンシ0仮定)、
ハードウェア(1クロック古い命令フェッチ——正しい実行では起こり得ないアドレスとして
SignalTap に撮影された)、そして契約検証者自身(二度、逆方向に、自身のテストベンチで)
を引っかけた。Build Log #6 と 2026-06-11 の Layer 2 軌跡を参照。

---

## Current wrappers / 現在のラッパー

| Wrapper | Vendor branch | Status |
|---|---|---|
| `ptsg_imem/` — instruction memory / 命令メモリ | Cyclone V M10K (`altsyncram`, ISMCE-enabled) | SIM contract machine-proved; M10K branch **silicon-verified** (DE10-nano, 2026-06-11) / SIM 契約は機械証明済み；M10K ブランチは**実機検証済み** |

Planned next: PLL (behavioral clock model vs `altera_pll`). FIFO and others as the
project needs them.

次の計画: PLL(behavioral クロックモデル 対 `altera_pll`)。FIFO 他はプロジェクトの
必要に応じて。

---

## Adding a new wrapper / 新しいラッパーの追加

A new wrapper directory must contain:

新しいラッパーディレクトリは以下を含まなければならない:

1. `README.md` — the contract in prose (bilingual), branch table, verification status,
   consuming-side obligations. / 契約の散文(日英)、ブランチ表、検証状況、利用側の義務。
2. `<name>.v` — the wrapper, contract in the header, parameters per iron rule 2.
   / ラッパー本体、ヘッダに契約、鉄則 2 に従うパラメータ。
3. `tb_<name>_contract.v` (or similar) — the machine check per iron rule 3, passing
   under a vendor-library-free simulator. / 鉄則 3 の機械検証、ベンダライブラリ不要の
   シミュレータで通過すること。

The vendor branch cannot be compiled by an AI agent; its verification is the human's
hardware step, and its status ("structurally correct, not yet hardware-verified" vs
"silicon-verified on <board>, <date>") must be stated honestly in the README.

ベンダブランチは AI エージェントにはコンパイルできない；その検証は人間のハードウェア
工程であり、その状態(「構造的に正しいが実機未検証」対「<ボード>で<日付>に実機検証済み」)
を README に正直に記載すること。

---

> *An agent that cannot verify will not ship. Give it something it can verify, and make
> that something tell the truth about the silicon.*
>
> *検証できないエージェントは納品しない。検証できるものを与えよ。そしてそれに、
> シリコンについての真実を語らせよ。*

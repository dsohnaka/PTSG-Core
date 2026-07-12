# PTSG — Canonical Project Abstract / 正典アブストラクト (2026-07-10)
*Single source for README / Hackaday summary / docs top page. Edit here first, radiate outward.*

**EN (short, ~60 words):** PTSG is a compact instruction-driven timing core for FPGA: 4 opcodes, 16 parallel timing signals, ~442 ALMs + 2 M10K in full v1.1 trim, ISMCE live-edit port included (core proper ~398 ALMs / 585 ALUTs), reprogrammable over JTAG while running. Specified, implemented, and silicon-verified first-try on a Cyclone V — and published as an Open Prompt repository: architecture, reasoning traces, reference implementation, and hardware evidence, all in the open.

**EN (one line):** A timing sequencer you reprogram like a music box — specified for humans and AI alike, proven on silicon.

**JA (短):** PTSG は FPGA 向けの極小命令駆動タイミングコア——4オペコード、16並列タイミング信号、完全装備（full trim）v1.1 で約442 ALM＋M10K×2——ISMCE込み（コア本体約398 ALM／585 ALUT）、走行中に JTAG で再プログラム可能。Cyclone V 上で仕様化・実装・実機一発検証済み。アーキテクチャ・推論軌跡・リファレンス実装・実機エビデンスの四層をすべて公開する Open Prompt リポジトリとして公開中。

**Pillars (fixed vocabulary / 語彙を固定):**
1. Time on the stay axis; space on the state axis; condition outside the core / 時間はステイ軸に、空間はステート軸に、条件はコアの外に
2. Trailing-edge principle §1.4a; normative 33-cell command × phase table §3.4b / 後縁主義;規範33セル表
3. Open Prompt, four layers, CC0/CC0/MIT/CC0; Core–Formation separation / 四層と Core-Formation 分離
4. v1.1, RH028, T1–T34, first-try silicon (DE10-nano, 2026-07); ~442 ALMs full trim vs ~235 pre-v1.1, same Fitter column — the price of law and teeth / 実機一発;完全装備約442 ALM 対 旧最小構成235(同列比較)——法と牙の代価
5. Improvisation design: recompile only to change the prescaler; everything else is live ISMCE / インプロビゼーション・デザイン

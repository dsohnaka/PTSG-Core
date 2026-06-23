# prescaler_phase_measurement — conformance item / 適合項目

> **The first completed Layer 4 conformance item, and the template for the rest.**
> This page is the entry point: what is being proven, where every file lives, how to
> reproduce it, and what the verdict was. Future items copy this layout.
>
> **Layer 4 で最初に完了した適合項目であり、以後の雛形。**
> 本ページは入口である: 何を証明するか、各ファイルの所在、再現方法、評決。以後の項目は本構成を踏襲する。

| Field / 項目 | Value / 値 |
|---|---|
| **Target / 標的** | Hook A (2026-06-11 bring-up) — residual prescaler-phase anomaly / 残留プリスケーラ位相異常 |
| **Layer 1 decisions / 関連決定** | C4-F1, **C4-T3** (prescale phase), **C4-T4** (Stay Set role) |
| **Hypothesis / 仮説** | A2 — phase-dependent first-tick jitter / 位相依存の初回ティック・ジッタ |
| **Verdict / 評決** | **PASS — silicon-confirmed (A2 rejected) / PASS — 実機確認済み（A2 棄却）** |
| **Evidence / エビデンス** | white-box (Icarus/ModelSim) **and** silicon (DE10-nano, SignalTap), in exact agreement / 白箱と実機が完全一致 |
| **DUT provenance / 来歴** | `ptsg_core.v` RH001–RH008 + `ptsg_imem.v` v2 |

---

## What this item proves / この項目が証明すること

That the prescaler is **phase-locked**, not jittering. Audit hypothesis A2 predicted that the
free-running `presc_cnt` would make each wait's first stay tick arrive a phase-dependent
1..PRESCALE clocks late, scattering the high/low widths. Observation rejects this: across
every wait window the prescaler enters at the **same phase**, with **zero jitter** — because
the loop's total length is an integer multiple of the prescale period, a structural
consequence of RH001/006 making foreground commands prescaled.

プリスケーラが**位相ロック**しており、ジッタしていないこと。監査仮説 A2 は、自由走行 `presc_cnt` ゆえに
各待機の初回ステイティックが位相依存で 1..PRESCALE クロック遅れ、high/low 幅がばらつくと予測した。観察は
これを棄却する: 全待機ウィンドウでプリスケーラは**同一位相**で突入し、**ジッタはゼロ**——ループ全長が
プリスケール周期の整数倍であるため（RH001/006 の前景プリスケールド化の構造的帰結）。

It also establishes that the bring-up "slightly off" was **the 25:35 duty asymmetry of the
naive program** (foreground NOP+Jump each adding one prescale unit to the OFF side), not
jitter — and documents the **four duty idioms** by which a designer controls duty on the
same skeleton.

また、bring-up の「わずかに off」は**素朴プログラムの 25:35 デューティ非対称**（前景 NOP+Jump が各 1
プリスケール単位を OFF 側に加える）であってジッタではないことを確立し、設計者が同一骨格でデューティを
制御する**4つの流儀**を文書化する。

---

## The four duty idioms / デューティ4流儀

Same skeleton, only the foreground treatment changes. All four are silicon-verified (see the
SignalTap observation) and reproduced in white-box (see the ModelSim observation).

同一骨格、前景の扱いだけが変わる。4本とも実機検証済み（SignalTap observation）かつ白箱再現済み（ModelSim observation）。

| Idiom / 流儀 | Program / プログラム | Duty / デューティ | Principle / 原理 |
|---|---|:---:|---|
| **A** naive / 素朴 | `program_A.{hex,mif}` | **25 : 35** | foreground NOP+Jump prescaled, +10clk on OFF (correct) / 前景がOFFに+10clk（正しい） |
| **B** NOP→ON | `program_B.{hex,mif}` | **30 : 30** | move the added unit to ON to balance / 付加分をONへ移し均す |
| **C** NOP→ON + flag / 旗付き | `program_C.{hex,mif}` | **30 : 30** | balance **and** mark the two added cycles via D17 / 均しつつD17で境界標示 |
| **D** Stay-exact / Stay厳守 | `program_D.{hex,mif}` | **25 : 25** | StaySet/background/queue drive foreground contribution to zero / 前景付加をゼロに |

(`program.{hex,mif}` without a suffix is idiom A, kept for back-compatibility with the
original conformance entry. / 接尾辞なしの `program.{hex,mif}` は流儀 A で、元の適合項目との後方互換のため残す。)

---

## File manifest / ファイル一覧

```
conformance_suite/prescaler_phase_measurement/      ← stimulus + prediction (this dir)
├── README.md                  ← this file / 本ファイル
├── expected.md                ← prediction BEFORE observation (pre-RH A2 + post-RH addendum)
│                                 観察前の予測（RH改修前のA2 + RH改修後の追補）
├── program.{hex,mif}          ← idiom A (back-compat) / 流儀A（後方互換）
└── program_{A,B,C,D}.{hex,mif} ← the four duty idioms / 4流儀

modelsim/runs/2026-06-21_prescaler_phase_measurement/   ← WHITE-BOX evidence / 白箱証拠
├── run.do                     ← ★ reproducible recipe (ModelSim) / 再現レシピ
├── Makefile                   ← ★ reproducible recipe (Icarus, free tool) / 再現レシピ
├── tb_prescaler_phase.v       ← Hook A phase TB (instruments presc_cnt@entry, first-tick)
├── tb_duty.v                  ← 4-idiom duty runner / 4流儀ランナー
├── observation.md             ← white-box verdict / 白箱評決
└── waveform.vcd.gz            ← small representative VCD (idiom A) / 代表VCD

signaltap/DE10-nano/2026-06-22_prescaler_phase_measurement/  ← SILICON evidence / 実機証拠
├── stp_config.md              ← probe & trigger setup / プローブ・トリガ設定
├── observation.md             ← ★ PRIMARY verdict (silicon) / 主評決（実機）
├── blinky_with_prescaler_{A,B,C,D}.vcd.gz  ← the four silicon captures / 実機4キャプチャ
└── ismce/blinky_with_prescaler_{A,B,C,D}_ISMCE.hex  ← ISMCE program images / ISMCEイメージ
```

---

## How to reproduce / 再現方法

**White-box (free tool, Icarus):** from the ModelSim run directory,
`make phase` reproduces the Hook A phase measurement and `waveform.vcd`;
`make duty` reproduces the four-idiom duty table. `run.do` is the ModelSim equivalent.

**白箱（無償ツール Icarus）:** ModelSim run ディレクトリで `make phase` が Hook A 位相測定と
`waveform.vcd` を、`make duty` が4流儀デューティ表を再現する。`run.do` が ModelSim 版。

**Silicon (DE10-nano):** synthesize the Core at `PRESCALE = 5`; load
`ismce/blinky_with_prescaler_A_ISMCE.hex` via the In-System Memory Content Editor over JTAG;
capture with SignalTap (probes/trigger in `stp_config.md`); export to VCD. Swap among A/B/C/D
by editing the ISMCE content and re-writing over JTAG — **no recompile**.

**実機（DE10-nano）:** コアを `PRESCALE = 5` で合成；`ismce/..._A_ISMCE.hex` を ISMCE 経由（JTAG）で
ロード；SignalTap で捕捉（プローブ／トリガは `stp_config.md`）；VCD にエクスポート。A/B/C/D の切替は
ISMCE 内容の編集と JTAG 再書込のみ——**再コンパイル不要**。

---

## Verdict & routing / 評決と経路

**PASS (silicon-confirmed).** A2 rejected in both white-box and silicon; the two agree
clock-for-clock. Not routed to an anomaly fix; routed to documenting the four duty idioms
(Layer 2 / Layer 3) and to the `conformance_matrix.md` updates for C4-T3 / C4-T4 (→ 🟢).
Full reasoning in the two `observation.md` files.

**PASS（実機確認済み）。** A2 は白箱・実機の双方で棄却、両者はクロック単位で一致。異常修正ではなく、
4流儀の文書化（Layer 2 / Layer 3）と `conformance_matrix.md` の C4-T3 / C4-T4 更新（→ 🟢）に経路付け。
詳細は2つの `observation.md` に記す。

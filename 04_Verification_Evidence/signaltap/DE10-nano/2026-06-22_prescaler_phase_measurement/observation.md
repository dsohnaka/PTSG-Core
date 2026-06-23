# observation.md — prescaler_phase_measurement (Hook A / A2) — SILICON / 実機

> **Evidence type: black-box on real silicon (DE10-nano, SignalTap).** This is the PRIMARY
> verdict for this conformance item: a real-board capture, irreproducible in the sense that
> it is *that board, that moment* — kept in git per the capacity policy. The reproducible
> white-box companion is at
> `../../../modelsim/runs/2026-06-21_prescaler_phase_measurement/observation.md`.
>
> **エビデンス種別: 実シリコン上のブラックボックス（DE10-nano, SignalTap）。** 本書が本適合項目の
> 主評決である: 実機キャプチャは*その基板・その瞬間*という意味で再現困難ゆえ、容量ポリシーに従い git に
> 保持する。再現可能な白箱の対は上記 ModelSim の observation.md。
>
> **License: CC0 1.0 Universal.** / **ライセンス: CC0 1.0 Universal。**

| Field / 項目 | Value / 値 |
|---|---|
| **Verdict / 評決** | **PASS — silicon-confirmed (A2 rejected) / PASS — 実機確認済み（A2 棄却）** |
| **Board / 基板** | DE10-nano (Cyclone V 5CSEBA6), FPGA_CLK1_50 = 50 MHz |
| **DUT provenance / 来歴** | bitstream of `ptsg_core.v` RH001–RH008 + `ptsg_imem.v` v2 (M10K branch). *Architect to attest bitstream↔RTL correspondence.* / ビットストリーム↔RTL 対応は大中さんが保証 |
| **Capture / 捕捉** | SignalTap, acquisition clock = FPGA_CLK1_50; PRESCALE=5 |
| **Stimuli / 刺激** | 4 idioms, swapped by **ISMCE edit + JTAG only, no recompile** / ISMCE編集とJTAGのみ、再コンパイルなし |
| **Probe/trigger / プローブ・トリガ** | see `stp_config.md` |

### Evidence files & integrity / 証拠ファイルと完全性

| File | SHA-256 (gzip) |
|---|---|
| `blinky_with_prescaler_A.vcd.gz` | `c927aa5e62bbcb79799596b364dad3b8a78d146c2f976196cc11826f91f49913` |
| `blinky_with_prescaler_B.vcd.gz` | `cd40bd3e631d3d8433f0810ef01cab416b7a4bd3eaa70fb69a4652867ef4efb4` |
| `blinky_with_prescaler_C.vcd.gz` | `825b5b1ebf41f374e8156610b2b7f9d4f888915061e1cbb8b16d8217714215a3` |
| `blinky_with_prescaler_D.vcd.gz` | `089d8cb8789b936dc8587062516cb7643c7e384f8aec59696a565a03d8725a3f` |

(Each ~16–18 KB raw, ~4 KB gzipped — small enough to commit directly; Zenodo not required for
this set. / 各 ~16–18 KB（生）、~4 KB（gzip）——直接コミット可能、本セットに Zenodo 不要。)

---

## 1. What was captured / 何を捕捉したか

Four duty idioms (A/B/C/D) on the DE10-nano at PRESCALE=5, each loaded via the In-System
Memory Content Editor over JTAG and captured with SignalTap, then exported to VCD. The
captures carry the full internal signal set (`state_num`, `presc_cnt`, `stay_cnt`,
`timing_signals`, `window_open`, `prog_end_seen`, `queued_valid`), enabling a white-box-grade
comparison directly on silicon.

DE10-nano 上で 4 流儀を PRESCALE=5 で、各々 ISMCE 経由（JTAG）でロードし SignalTap で捕捉、VCD に
エクスポート。内部信号一式（上記）を保持し、実機上で白箱級の比較を可能にする。

## 2. Silicon duty — sampled at FPGA_CLK1_50 posedge / 実機デューティ（FPGA_CLK1_50立ち上がり）

| Program | silicon duty (clk) / 実機デューティ |
|---|---|
| A | ON **25** : OFF **35** |
| B | ON **30** : OFF **30** |
| C | ON **30** : OFF **30** (D17 boundary flags present / D17境界旗あり) |
| D | ON **25** : OFF **25** |

Idiom A on silicon: ON=25 = Stay5×5; OFF=35 = Stay5×5 + foreground NOP@2 (5) + Jump@4 (5).
This is the foreground-prescaled duty model, confirmed on hardware.

実機の流儀A: ON=25 = Stay5×5;OFF=35 = Stay5×5 + 前景 NOP@2(5) + Jump@4(5)。前景プリスケールド・
デューティモデルが実機で確認された。

## 3. Phase-lock confirmed on silicon — A2 rejected / 実機での位相ロック確認 — A2 棄却

From the silicon `presc_cnt` at each state entry: for A/B/C every state transition occurs at
the same prescaler phase on every iteration; for D the phase is periodic and identical at each
given state across all periods (e.g. state 1 always at the same phase, state 4 always at the
same phase). **The prescaler is phase-locked on real silicon; no jitter. A2 is rejected on
silicon, in agreement with the white-box result.**

実機の `presc_cnt`（各状態突入時）より、A/B/C は全状態遷移が毎周回同一プリスケーラ位相で起こり、D は
各状態の位相が全周期で同一に周期化する（例: state 1 は常に同一位相、state 4 は常に同一位相）。
**プリスケーラは実シリコン上で位相ロック;ジッタなし。A2 は実機でも棄却され、白箱と一致する。**

## 4. Cross-check — silicon vs white-box, exact / 実機 対 白箱、完全一致

| Program | white-box (Icarus) / 白箱 | silicon (SignalTap) / 実機 | Match / 一致 |
|---|:---:|:---:|:---:|
| A | 25 : 35 | 25 : 35 | ✓ exact / 完全 |
| B | 30 : 30 | 30 : 30 | ✓ exact / 完全 |
| C | 30 : 30 | 30 : 30 | ✓ exact / 完全 |
| D | 25 : 25 | 25 : 25 | ✓ exact / 完全 |

Not merely the ratios but the **absolute clock counts** match, because the silicon prescale is
also 5. White-box verdict and silicon verdict therefore close each other.

比だけでなく**絶対クロック数**まで一致する（実機のプリスケールも 5）。ゆえに白箱評決と実機評決は互いを閉じる。

## 5. Idiom D — internal mechanism on silicon / 流儀D — 実機での内部機構

The silicon D capture shows the same `window_open / prog_end_seen / queued_valid` evolution as
white-box: the `ProgEnd → QueJump` pair fires at timeup and loops, so only the Stay-written
cycles appear in `timing_signals`, giving exactly 25:25. **The agreement is at the
internal-register level, not merely the LED output** — white-box (Icarus/ModelSim) and silicon
(DE10-nano) shake hands.

実機 D キャプチャは白箱と同一の `window_open / prog_end_seen / queued_valid` 推移を示す:
`ProgEnd → QueJump` が timeup で発火しループするため、`timing_signals` には Stay 記述サイクルのみが
現れ、正確に 25:25。**一致は LED 出力だけでなく内部レジスタのレベルで成立する**——白箱（Icarus/ModelSim）と
実機（DE10-nano）が握手している。

## 6. Methodological note — ISMCE/JTAG behaviour-swap / 方法論メモ — ISMCE/JTAG挙動切替

All four qualitatively different behaviours were obtained by editing instruction-memory
numbers and writing over JTAG — **no HDL change, no recompile.** This is a direct, on-silicon
demonstration of PTSG-Core's core value proposition (Chapter 1: "edit the instruction memory
and behaviour changes in seconds").

4種の質的に異なる挙動が、命令メモリの数値編集と JTAG 書込のみ（**HDL 変更なし・再コンパイルなし**）で
得られた。これは PTSG-Core の中核的価値（第1章「命令メモリを編集すれば動作が秒単位で変わる」）の実機上の直接実演である。

## 7. The four duty idioms (canonical, as run on silicon) / デューティ4流儀（実機正典）

| Idiom / 流儀 | How / 書き方 | Duty | Principle / 原理 |
|---|---|:---:|---|
| **A** naive / 素朴 | foreground NOP/Jump | **25:35** | foreground prescaled, +10clk OFF (correct) / 前景がOFFに+10clk（正しい） |
| **B** NOP→ON | state2 NOP → ON (0x0001) | **30:30** | move added unit to ON / 付加分をONへ |
| **C** NOP→ON + flag / 旗付き | + D17 on NOP@2 (0x0003) & Jump@4 (0x0002) | **30:30** | balance + mark added cycles via D17 / 均し+D17標示 |
| **D** Stay-exact / Stay厳守 | StaySet→bg NOP→Stay→…→ProgEnd→QueJump | **25:25** | foreground contribution zero / 前景付加ゼロ |

**Note / 補足:** the "flag the boundary" idea (C) admits more than one realization. The silicon
C keeps Stay=5 → 30:30 with D17 flags; an alternative shrinks Stay to 4 → 25:25 with the same
flagging. Silicon C is canonical here.

「境界を旗で標示」（C）には複数の実現がある。実機 C は Stay=5 のまま 30:30＋D17 旗;別解は Stay を 4 に
削って 25:25＋同じ標示。ここでは実機 C を正典とする。

## 8. Routing & cross-reference / 経路と相互参照

25:35 is correct, not a defect → routed to documenting the four duty idioms (Layer 2
deliberation trace and/or Layer 1; final routing is the architect's decision) and to
`conformance_matrix.md` updates (C4-T3, C4-T4 → 🟢 silicon; queue #1 closed). `expected.md`'s
post-RH addendum predicted exactly this PASS.

25:35 は正しく欠陥でない → 4流儀の文書化（Layer 2 / Layer 1、最終経路は大中さんの決定）と
`conformance_matrix.md` 更新（C4-T3, C4-T4 → 🟢、キュー#1 完了）に経路付け。`expected.md` の
RH改修後追補が本 PASS を予測していた。

- **White-box (reproducible) companion / 白箱（再現可能）の対:**
  `../../../modelsim/runs/2026-06-21_prescaler_phase_measurement/observation.md`
- **Prediction / 予測:** `../../../conformance_suite/prescaler_phase_measurement/expected.md`
- **Probe/trigger / プローブ・トリガ:** `stp_config.md` (this directory / 本ディレクトリ)

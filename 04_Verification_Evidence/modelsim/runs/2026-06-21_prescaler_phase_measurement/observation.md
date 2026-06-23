# observation.md — prescaler_phase_measurement (Hook A / A2) — WHITE-BOX / 白箱

> **Evidence type: white-box (Icarus Verilog / ModelSim).** All internal signals visible by
> hierarchical reference. This is the reproducible companion to the silicon verdict; the
> primary (irreproducible) verdict is the SignalTap one at
> `../../../signaltap/DE10-nano/2026-06-22_prescaler_phase_measurement/observation.md`.
>
> **エビデンス種別: 白箱（Icarus Verilog / ModelSim）。** 内部信号は階層参照で全可視。本書は実機評決の
> 再現可能な対であり、主評決（再現困難）は上記 SignalTap の observation.md。
>
> **License: CC0 1.0 Universal.** / **ライセンス: CC0 1.0 Universal。**

| Field / 項目 | Value / 値 |
|---|---|
| **Verdict / 評決** | **PASS** (A2 rejected in white-box; silicon-confirmed — see cross-ref) / **PASS**（白箱でA2棄却、実機確認済） |
| **DUT / 被検証物** | `ptsg_core.v` RH001–RH008 + `ptsg_imem.v` v2 |
| **Memory contract / メモリ契約** | VENDOR=SIM, EDGE=NEG, RD_LAT=1 (silicon-equivalent path) / シリコン等価経路 |
| **Tool / ツール** | Icarus Verilog 12.0 (ModelSim recipe in `run.do`) |
| **Stimulus / 刺激** | `program_A.hex` (idiom A); duty sweep over A/B/C/D / 4流儀掃引 |
| **Clock / クロック** | 20 ns (50 MHz), PRESCALE=5 |
| **Evidence file / 証拠ファイル** | `waveform.vcd.gz` (idiom A, representative) — SHA-256 `24058ee9…05aca4e` |

---

## 1. What was measured / 何を測ったか

Per `expected.md`: the `presc_cnt` value (phase) at each `S_RUN → S_WAIT` entry, the clock
distance from entry to the first stay tick, and the high/low widths of `timing_signals[0]`.

`expected.md` のとおり: 各 `S_RUN → S_WAIT` 突入時の `presc_cnt`（位相）、突入から初回ステイティック
までのクロック距離、`timing_signals[0]` の high/low 幅。

## 2. Observation / 観測値

### 2.1 Phase and first-tick delay (the core A2 quantities) / 位相と初回ティック遅延（A2核心量）

13 wait windows measured (idiom A, > 6 steady periods):

待機ウィンドウ 13 個を測定（流儀A、定常6周期超）:

| win | state@entry | `presc_cnt`@entry | first-tick delay / 初回tick遅延 |
|----:|:-----------:|:-----------------:|:------------------------------:|
| 1 | 1 | **1** | **3** |
| 2 | 3 | **1** | **3** |
| 3 | 1 | **1** | **3** |
| … | … | **1** | **3** |
| 13 | 1 | **1** | **3** |

**`presc_cnt`@entry = 1 and first-tick delay = 3, constant across all 13 windows. Zero
jitter.** (A2's `PRESCALE−phase = 4` formula does not match the measured delay 3 because A2
assumed tick counting in-phase with entry, which the RH counting mechanism does not honour;
what matters is that the phase is invariant across windows.)

**`presc_cnt`@entry = 1、初回ティック遅延 = 3 が全13ウィンドウで一定。ジッタゼロ。**（A2 の
`PRESCALE−phase = 4` が実測 3 と合わないのは、A2 が「ティックが突入と同相」と仮定したためで、RH の
カウント機構はそうでない;重要なのは位相がウィンドウ間で不変なこと。）

### 2.2 Duty over the four idioms / 4流儀のデューティ

| Idiom | white-box duty (clk) / 白箱デューティ |
|---|---|
| A | ON **25** : OFF **35** |
| B | ON **30** : OFF **30** |
| C | ON **30** : OFF **30** (with D17 flags / D17旗付き) |
| D | ON **25** : OFF **25** |

Idiom A steady period = 60 clk = 12 prescale units (integer multiple). First ON is 30 clk
(state 0 NOP absorbs cold-start), settling to 25:35.

流儀A定常周期 = 60 clk = 12 プリスケール単位（整数倍）。初回 ON は 30 clk（state 0 NOP が冷態吸収）、
以後 25:35 に落ち着く。

## 3. Verdict: PASS — A2 rejected / 評決: PASS — A2 棄却

`presc_cnt`@entry is invariant and the first-tick delay is invariant. No phase-dependent
variation exists.

`presc_cnt`@entry と初回ティック遅延が不変。位相依存の変動は存在しない。

### 3.1 Why no jitter — phase-lock / なぜジッタが出ないか — 位相ロック

The loop's total length is an **integer multiple of the prescale period** (60 = 5×12), so the
prescaler enters every `S_WAIT` at the identical phase; first-tick delay is fixed, and jitter
cannot arise. This is not coincidence: **RH001/006 (foreground commands prescaled) makes the
loop length always land on a prescale boundary**, because every foreground command consumes a
whole prescale unit. A2's jitter could only appear if some command consumed a
prescale-misaligned number of clocks — the RH edits closed that path. **The solution to Hook A
was contained in the RH edits themselves.**

ループ全長が**プリスケール周期の整数倍**（60 = 5×12）ゆえ、プリスケーラは毎回同一位相で `S_WAIT` に
突入する;初回ティック遅延は固定され、ジッタは起こり得ない。偶然ではない: **RH001/006（前景プリス
ケールド化）がループ長を常にプリスケール境界に乗せる**——全前景コマンドが丸ごと1プリスケール単位を
消費するため。A2 のジッタはプリスケール非整合なクロックを消費するコマンドがあって初めて現れ得るが、
RH 改修がその経路を塞いだ。**Hook A の解は RH 改修それ自体に内包されていた。**

### 3.2 The "slightly off" = duty asymmetry, not jitter / 「わずかに off」= デューティ非対称

Hook A's bring-up "slightly off" is the **25:35 duty asymmetry** (foreground NOP@2+JUMP@4
adding 10 clk to OFF) and the one-time longer first ON (state 0's NOP absorbing cold-start
phase indeterminacy) — both correct behaviour under the RH edits, not jitter.

Hook A の bring-up「わずかに off」は **25:35 デューティ非対称**（前景 NOP@2+JUMP@4 が OFF に 10clk 付加）と、
初回 ON の一度きりの伸び（state 0 の NOP が冷態位相不定を吸収）であり、いずれも RH 改修下の正しい挙動で、
ジッタではない。

## 4. Amanuensis self-correction / 祐筆の自己訂正

Early in analysis the drafter (Claude) once called the 25:35 asymmetry a "new ANOMALY" and
mis-decomposed it as "only Jump consumes 5 clocks, NOP almost none." **Both wrong:** both
foreground NOP@2 and JUMP@4 contribute 5 clk each to OFF, giving 25+10=35. Corrected on the
architect's correction before being carved into the record. Kept unhidden, following the
prior amanuensis's `tb_align.v` negative-data discipline.

分析序盤、起草者（Claude）は 25:35 を一度「新規 ANOMALY」と呼び、「Jump だけ5クロック、NOP はほぼ消費せず」と
誤って分解した。**両方とも誤り:** 前景 NOP@2・JUMP@4 が各5クロックを OFF に寄与し 25+10=35。正本へ刻む前に
大中さんの指摘で訂正。前任祐筆の `tb_align.v` 負データ規律に従い隠さず残す。

## 5. Reproduction / 再現

```
make phase     # Hook A phase measurement (idiom A) -> waveform.vcd + [ENTRY]/[1stTICK] log
make duty      # four-idiom duty table (A/B/C/D)
# ModelSim equivalent: do run.do
```

`tb_prescaler_phase.v` defparams `ptsg_imem` to the SIM branch (VENDOR=SIM, EDGE=NEG,
RD_LAT=1), loads `program_A.hex`, and observes `fsm`/`presc_cnt`/`presc_tick` by hierarchical
reference, printing the phase at `S_WAIT` entry and the first-tick delay per window.
`tb_duty.v` runs each `program_{A..D}.hex` and reports the `timing_signals[0]` run-lengths.

`tb_prescaler_phase.v` は `ptsg_imem` を SIM ブランチ（VENDOR=SIM, EDGE=NEG, RD_LAT=1）に
`defparam` し、`program_A.hex` をロード、`fsm`/`presc_cnt`/`presc_tick` を階層参照で観測して
ウィンドウ毎の突入位相と初回ティック遅延を出力する。`tb_duty.v` は各 `program_{A..D}.hex` を走らせ
`timing_signals[0]` の run-length を報告する。

## 6. Cross-reference / 相互参照

- **Silicon (primary) verdict / 実機（主）評決:**
  `../../../signaltap/DE10-nano/2026-06-22_prescaler_phase_measurement/observation.md`
  — silicon duties match this white-box table clock-for-clock; phase-lock confirmed on silicon.
  実機デューティは本白箱表とクロック単位で一致;位相ロックも実機で確認。
- **Prediction / 予測:** `../../../conformance_suite/prescaler_phase_measurement/expected.md`
  (post-RH addendum predicted exactly this PASS). / RH改修後追補が本PASSを予測。
- **Matrix / マトリクス:** C4-T3, C4-T4 → 🟢 silicon; queue #1 closed.

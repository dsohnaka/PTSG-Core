# observation — Live Session #1 Scene 4: live prescaler change (RH029), the shifted grid (RH030), and the beat against the DAW
# 観測判決 — 実演第一話 シーン4: プリスケーラ生変更（RH029）、ずれたグリッド（RH030）、そして DAW とのビート

**Verdict / 判決: PASS — all six on-chip claims confirmed at single-clock granularity. The beat phenomenon is not a PTSG defect and is referred to separate proceedings (§ 6). / 合格——チップ上の6主張すべてを1クロック粒度で確認。ビート現象は PTSG の欠陥ではなく、別件送致（§6）。**

**License / ライセンス:** CC0 1.0 Universal. Part of Layer 4 of the PTSG-Core Open Prompt repository.

---

## 1. Setup / 環境

| Item | Value |
|---|---|
| Board / clock | DE10-nano, Cyclone V 5CSEBA6, FPGA_CLK1_50 = 50 MHz |
| RTL | `ptsg_core.v` RH030 head (RH029/RH030 dated 2026-07-16; header patch pending, source frozen during Layer 4) |
| Program (M10K, via ISMCE) | `0: 0000_4E21` (Stay 0x4E2 = 1250, tsig=0) / `1: 0001_4E21` (Stay 1250, tsig=1) / `2: 0000_0000` (zero fill = Reset) |
| Prescaler | boot: `prescaler_value` pin = 0 → `PRESCALE` parameter fallback 6250 (tick 8 kHz). Then **ISSP 16-bit probe on `prescaler_value` set to 20 live** (tick 2.5 MHz) — the C4-T2 form B′ path, exercised without recompilation |
| Instruments | SignalTap (auto_signaltap_0, 1860 LEs / 32000 bits, 08/29/2026 triggers 16:28:29 and 16:39:03); oscilloscope CH1 = `timing_signals[0]`, CH2 = various (see § 6); piezo speaker on the output; DAW = Cubase test tone via DisplayPort → Philips 4K monitor internal DAC → PC speakers |
| Evidence files | `Beating_against_the_DAW_A.vcd` (trigger: output 0→1 edge, 514 samples), `Beating_against_the_DAW_B.vcd` (trigger: output 1→0 edge, 514 samples), two SignalTap screenshots, camera footage (Scene 4 cut, edited) |

## 2. Claims on trial / 審理対象の主張

1. **RH029 (B′):** a live, pin-level `prescaler_value` write retunes the base frequency without recompilation; the registered `value − 1` compare (`presc_valueM`) is correct at P = 20.
2. **RH030 lead:** `prescaler_match` (raw tick) leads the registered internal `presc_tick` by exactly one clock — the Hook A core question of trace `2026-08-27_ptsg-free-running-fruits`, previously unconfirmed in silicon.
3. **RH028 anchor on the shifted grid:** `stay_cnt` terminal value = target − 1 survives RH030's one-clock re-timing.
4. **C3-F21 at P = 20:** `presc_cnt` runs uninterrupted across the Reset seam.
5. **Grid absorption at P = 20:** the Reset clock vanishes into the prescale grid; surface duty exactly 1:1, period exactly 50,000 clocks (1.000000 kHz of the 50 MHz crystal).
6. **Ratio exactness across instruments:** changing 6250 → 20 changes only the ratio; any residual against the oscilloscope is a constant crystal offset, identical at both frequencies.

## 3. Findings / 認定事実 (from the VCDs; clk = 20 ns samples from trigger window start)

**Both captures show the identical engine:** `presc_cnt` cycles 0…19; `prescaler_match` rises in the clock where `presc_cnt = 19`; `presc_tick` rises exactly **one clock later** (claim 2 — **PASS**, first silicon confirmation); `stay_cnt` increments one clock after the tick. P = 20 operation via `presc_valueM = 19` (claim 1 — **PASS**; ratio also confirms: 3.2 Hz → 1 kHz on the scope, piezo click train → continuous tone).

**Capture A (0→1 seam):** `stay_cnt` climbs …1248 → 1249 = 0x4E1 = **target − 1** (claim 3 — **PASS**), then 1249 → 0 with `state_num` 0 → 1 at clk 127; `timing_signals[0]` rises at clk 128.

**Capture B (1→0 seam):** same terminal 1249; `state_num` 1 → **2** at clk 127 (the Reset word), 2 → 0 at clk 128 with `timing_signals[0]` falling at clk 128 — **the Reset occupies exactly one clock**. Across this seam `presc_cnt` runs …18, 19, 0, 1, 2… without disturbance (claim 4 — **PASS**), so the Reset clock is absorbed into the first prescale interval and never surfaces: half-period = 1250 ticks × 20 clk = 25,000 clk on both sides, period = 50,000 clk, duty 1:1 (claim 5 — **PASS**).

**Phase lock:** at both seams `presc_cnt = 1` at the state transition — the same locked entry value observed at P = 6250 on 2026-07 (loop length an exact integer multiple of the prescale period), reproduced at P = 20.

**Cross-instrument ratio (claim 6 — PASS):** scope reads 3.199998 Hz at P = 6250 and 999.9994 Hz at P = 20; both are **−0.6 ppm** of nominal. The offset is one constant — the scope-vs-board crystal pair — and the PTSG ratio change is exact.

## 4. What this closes / 何が閉じたか

- **Hook A of `2026-08-27_ptsg-free-running-fruits` — substantially closed:** the one-clock lead is silicon-confirmed; the RH028 anchor and C3-F21 hold on the RH030 grid. Remaining under Hook A: re-run of the formal conformance rows (T1/T2/T32/T34) and the P = 1 functional tests on this RTL (Scene 5).
- Matrix rows: grid absorption and Reset-seam behaviour now hold at **two prescale settings** (6250 and 20), the second reached **live**, without recompilation — the first hardware exercise of C4-T2 form B′.

## 5. Chain of custody / 証拠経路

Predictions frozen in the Live Session #1 storyboard (Scene 4) before filming. VCDs exported from SignalTap (Quartus VCD export, timescale 1 ps), parsed by script (bus reassembly + transition timeline); screenshots and camera footage auxiliary per Layer 4 policy (VCD primary, PNG auxiliary).

## 6. Separate referral: the beat against the DAW / 別件送致: DAW とのビート

**The defendant is acquitted and seated as expert witness.** With CH1 holding the PTSG 1 kHz square stationary:

- **Oscilloscope CAL output on CH2:** steady, uniform phase drift, ≈ 360° per 10 s = 0.1 Hz ≈ **100 ppm** constant offset. The signature of two free-running crystals. Unremarkable.
- **PC audio 1 kHz (any source — Cubase test tone, media player, web tone — all via DisplayPort → monitor DAC) on CH2:** mean frequency almost exact (only a slow residual drift), but the phase **hunts** over ≈ 180° with a ≈ 1.5 s period, and the audible beat tracks the hunt. A free-running clock cannot produce this; a **servo** can. The ≈ 0.5 ms swing (≈ 24 samples at 48 kHz) is buffer/packet-quantum scale, pointing at clock recovery or adaptive resampling in discrete corrections rather than a hardware PLL's wander.

**Suspects (not yet separated):** (a) DisplayPort audio clock regeneration in the monitor (no dedicated audio clock crosses a DP link; the sink rebuilds it from Maud/Naud and the link clock); (b) the OS audio engine's shared-mode mixer / adaptive resampler. Note: "every source behaves the same" only proves it is not application-specific — every source shares the same output device.

**Discriminating experiments (pending):** (1) same PC, different output device (onboard analog jack or USB DAC) — hunt gone → DP/monitor path; hunt stays → OS side. (2) WASAPI-exclusive/ASIO direct to the DP device — bypasses the mixer. (3) a phone playing the same tone — expected to show the CAL-style steady drift, as the control.

**判決文（要旨・和文）:** PTSG は無罪。オシロの CAL 出力は自走水晶らしい一定ペースの遅相（≈100 ppm）を示し、PC 音声だけが約 1.5 秒周期・180° 幅の位相往復——サーボの署名——を示した。容疑は DisplayPort 音声クロック再生成とOSオーディオエンジンの適応リサンプリングの二者で、全ソース同一挙動は同一出力デバイス共有の帰結にすぎず、両者は未分離。切り分け実験3件を係属とする。被告 PTSG は、オシロスコープと組んで PC を測る鑑定人として本件に留まる。

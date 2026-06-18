# ModelSim Evidence / ModelSim エビデンス

> White-box verification: all internal Core signals visible, stimulus freely controlled,
> **fully reproducible from `run.do`**. Per the capacity policy, the `run.do` is the primary
> committed artifact; the VCD it generates is regenerated on demand and committed only when
> small and illustrative.
>
> ホワイトボックス検証: コア内部信号がすべて可視、スティミュラス自由制御、**`run.do` から
> 完全再現可能**。容量ポリシーにより `run.do` が主たるコミット対象;生成される VCD は随時
> 再生成され、小さく例示的な場合のみコミットされる。

## Layout / レイアウト

```
modelsim/
├── README.md            ← this file
├── run.do.template      ← copy into a run dir and adapt
├── observation.template.md
└── runs/
    └── YYYY-MM-DD_<feature>/
        ├── run.do
        ├── observation.md
        └── waveform.vcd.gz   (only if small & illustrative; else regenerate from run.do)
```

## Conventions / 規約

- One run directory per measurement, named `YYYY-MM-DD_<feature>` matching the
  `conformance_suite/<feature>/` it exercises. / 測定ごとに 1 ディレクトリ、対応する
  `conformance_suite/<feature>/` に合わせて命名。
- `run.do` must be self-contained: compile the Core + a small testbench, load the conformance
  `program.hex`, set required parameters (e.g. `PRESCALE`), run, and write a VCD. / `run.do`
  は自己完結:コア + 小テストベンチをコンパイル、`program.hex` をロード、必要パラメータ設定、
  実行、VCD 出力。
- Every run produces an `observation.md` verdict. A VCD without one is not evidence. / 毎実行
  が `observation.md` 判決を生む。それなき VCD は証拠でない。
- Curated transcript excerpts go **into** `observation.md`; the raw `transcript` is gitignored.
  / 選別した transcript 抜粋は `observation.md` **の中へ**;生 `transcript` は gitignore。

---

## `run.do.template`

```tcl
# run.do — ModelSim evidence run for <feature>
# Reproduces the measurement from sources; regenerates the VCD.
# Usage:  vsim -c -do run.do      (batch)   or   do run.do   (from the GUI)

# --- 1. fresh work library ---
if {[file exists work]} { vdel -all }
vlib work

# --- 2. compile Core + wrappers + testbench ---
# Adjust relative paths to your checkout. The SIM branch of ptsg_imem needs no vendor lib.
vlog -sv ../../../../03_Sample_Implementations/ptsg_core_verilog/ptsg_core.v
vlog -sv ../../../../03_Sample_Implementations/ai_friendly_vendor_wrappers/ptsg_imem/ptsg_imem.v
vlog -sv tb_<feature>.v        ;# small TB: instantiates the core, drives clk/rst, loads program

# --- 3. elaborate with the required parameters ---
# Example: PRESCALE=5 for prescaler_phase_measurement. Set VENDOR=SIM, EDGE=NEG to match silicon.
vsim -g/tb/PRESCALE=5 -gVENDOR=\"SIM\" -gEDGE=\"NEG\" work.tb

# --- 4. VCD: capture exactly the signals expected.md asks for ---
vcd file waveform.vcd
vcd add -r /tb/dut/*
# (or list explicit signals: fsm, presc_cnt, stay_cnt, stay_cnt_match, state_num, timing_signals)

# --- 5. run ---
run 4000 ns                    ;# long enough for several Stay windows; adjust per feature

# --- 6. close the VCD; gzip externally (gitignore the raw .vcd) ---
vcd flush
quit -sim
# After exit:  gzip -k waveform.vcd     (commit waveform.vcd.gz only if small & illustrative)
```

---

## `observation.template.md`

```markdown
# Observation — <feature> (ModelSim) / 観察 — <feature>（ModelSim）

**Date / 日付:** YYYY-MM-DD
**Run / 実行:** run.do (this dir); regenerate VCD with `vsim -c -do run.do`
**Parameters / パラメータ:** PRESCALE=__, VENDOR=SIM, EDGE=NEG, RD_LAT=1
**conformance program:** ../../conformance_suite/<feature>/program.hex
**expected:** ../../conformance_suite/<feature>/expected.md

## What was measured / 測定内容
(one or two sentences)

## Signals examined / 検査信号
(list, matching expected.md)

## What happened (with times) / 何が起きたか（時刻付き）
- t=___ ns: ___
- t=___ ns: ___
(quote VCD values; do not rely on a screenshot)

## Comparison to expected / 期待との比較
(point-by-point against expected.md's prediction and hypothesis)

## VERDICT: PASS | FAIL | ANOMALY
**Routing (if FAIL/ANOMALY):** implementation fix (Layer 3) | spec decision (Layer 1 C_-T_/F_) | new investigation

## VCD / 波形
- waveform.vcd.gz committed here  — OR —  regenerate from run.do (size __ MB gzipped)
- (if > ~50 MB gzipped) Zenodo DOI: ____  SHA-256: ____
```

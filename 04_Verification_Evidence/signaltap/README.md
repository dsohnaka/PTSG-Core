# SignalTap Evidence / SignalTap エビデンス

> Black-box verification on real silicon: a limited capture window, but the only place that
> shows what the actual hardware does (post-place-and-route timing, memory latency,
> metastability, temperature). Per the capacity policy, a SignalTap capture is
> **irreproducible** — that board, that moment — so its VCD is **kept** (gzipped in git, or
> Zenodo if large).
>
> 実シリコン上のブラックボックス検証: 限定された捕捉窓だが、実ハードウェアが何をするか(配置
> 配線後タイミング、メモリレイテンシ、メタステーブル、温度)を示す唯一の場所。容量ポリシーに
> より、SignalTap キャプチャは**再現困難**——そのボード、その瞬間——ゆえにその VCD は**保持**
> される(git に gzip、大きければ Zenodo)。

## Layout / レイアウト

```
signaltap/
├── README.md                 ← this file
├── stp_config.template.md
├── observation.template.md
└── <board>/                  ← e.g. de10_nano/
    └── YYYY-MM-DD_<feature>/
        ├── stp_config.md     ← probe & trigger setup (so the capture is interpretable)
        ├── observation.md    ← the verdict
        ├── capture.vcd.gz    ← exported from SignalTap (File → Export → VCD), gzipped
        └── capture.png       ← optional aid, embedded in observation.md
```

## The one non-negotiable step / 唯一の交渉不能ステップ

**Export every capture to VCD** (File → Export → VCD), not just a screenshot. The VCD holds
all probed signals as values (re-examinable, AI-parseable, git-diffable); a PNG holds only
what was on screen. The PNG is an optional aid embedded in `observation.md`; the VCD is the
evidence.

**全キャプチャを VCD にエクスポート**(File → Export → VCD)、スクリーンショットだけにしない。
VCD は全プローブ信号を値として保持(再検査可能、AI 解析可能、git 差分可能);PNG は画面に
あったものだけ。PNG は `observation.md` に埋め込む任意の補助、VCD が証拠。

## Capacity / 容量

`gzip -k capture.vcd` and commit `capture.vcd.gz` (VCD compresses to ~15–25%). If a gzipped
capture exceeds ~50 MB, deposit to **Zenodo** (DOI-citable) and record the DOI + SHA-256 in
`observation.md` instead of committing the file. **Git LFS is not used.**

`gzip -k capture.vcd` して `capture.vcd.gz` をコミット(VCD は ~15-25% に圧縮)。gzip 後 ~50 MB
超なら **Zenodo**(DOI 引用可能)へ供託し、ファイルをコミットする代わりに DOI + SHA-256 を
`observation.md` に記録。**Git LFS は使わない。**

---

## `stp_config.template.md`

```markdown
# SignalTap config — <feature> @ <board> / SignalTap 設定

**Date / 日付:** YYYY-MM-DD
**Board / ボード:** DE10-nano (Cyclone V 5CSEBA6), FPGA_CLK1_50 = 50 MHz
**Core parameters / コアパラメータ:** PRESCALE=__, EDGE="NEG", RD_LAT=1, VENDOR="M10K"
**Program loaded (via ISMCE) / ロード済プログラム:** <feature>/program.mif
**Sample clock / サンプルクロック:** ___ (e.g. FPGA_CLK1_50)
**Sample depth / サンプル深さ:** ___

## Probed signals / プローブ信号
(list — must match expected.md's "signals to probe")
- ptsg_core1|...|fsm
- ptsg_core1|presc_cnt
- ...

## Trigger / トリガ
(condition, e.g. "S_RUN → S_WAIT transition" or a specific state_num)
```

---

## `observation.template.md`

```markdown
# Observation — <feature> @ <board> (SignalTap) / 観察 — <feature>（SignalTap）

**Date / 日付:** YYYY-MM-DD
**Config / 設定:** see stp_config.md (this dir)
**conformance program:** ../../../conformance_suite/<feature>/program.{hex,mif}
**expected:** ../../../conformance_suite/<feature>/expected.md

## What was captured / 捕捉内容
(one or two sentences)

## What happened (with sample indices / times) / 何が起きたか（サンプル番号/時刻）
- sample ___: ___
(quote VCD values; the PNG, if any, is only an aid)

## Comparison to expected / 期待との比較
(point-by-point against expected.md, including the hypothesis under test)

## Cross-check vs ModelSim (if available) / ModelSim との相互確認
(does silicon agree with the white-box simulation? discrepancies are themselves findings)

## VERDICT: PASS | FAIL | ANOMALY
**Routing:** implementation (Layer 3) | spec decision (Layer 1 C_-T_/F_) | new investigation

## Evidence files / エビデンスファイル
- capture.vcd.gz (committed, __ MB gzipped)   — OR —   Zenodo DOI: ____  SHA-256: ____
- capture.png (optional aid)
```

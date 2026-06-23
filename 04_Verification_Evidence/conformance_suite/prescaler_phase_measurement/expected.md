# Expected — prescaler_phase_measurement / 期待 — プリスケーラ位相測定

> **Written before observation.** This document states what Layer 1 predicts, and the
> competing hypothesis under test, *before* any waveform is captured. Predicting first is
> what lets the result distinguish "prediction matched → implementation understood" from
> "prediction diverged → a discovery."
>
> **観察の前に記述。** 本文書は、Layer 1 が予測することと、検証下の対立仮説を、いかなる波形
> 捕捉よりも*前*に述べる。まず予測することが、結果を「予測一致 → 実装理解」と「予測乖離 →
> 発見」に区別させる。

**Target / 標的:** Hook A (2026-06-11 bring-up trace) — the residual "slightly off" anomaly
in the aligned waveform. Audit finding **A2**: the prescaler counter `presc_cnt` is
free-running (reset only by global `rst`), not re-aligned at the start of each wait.

**Related Layer 1 decisions / 関連 Layer 1 決定:** C4-F1 (prescaler necessity), C4-T3
(prescale edge / phase — currently undocumented in the implementation), C4-T4 (Stay Set =
clear/sync-only, lean B).

---

## Setup / 設定

| Parameter | Value | Where set |
|---|---|---|
| `PRESCALE` | **5** | core synthesis parameter (NOT in the program) / コア合成パラメータ |
| Stay operand | **5** | program states 1 and 3 / プログラム |
| Program | `program.{hex,mif}` (5 words) | this directory |

The program: state 0 raises `timing_signals[0]` (init only); the loop body 1→2→3→4 holds
high for `Stay 5`, clears, holds low for `Stay 5`, and `Jump 1` repeats forever. State 0 is
entered once; the steady-state period is states 1–4.

プログラム: state 0 が `timing_signals[0]` を上げる(初期化のみ);ループ本体 1→2→3→4 が
`Stay 5` の間 high を保持し、クリアし、`Stay 5` の間 low を保持し、`Jump 1` で永久に繰り返す。
state 0 は一度だけ;定常周期は state 1-4。

---

## Ideal prediction (Layer 1, no jitter) / 理想予測（Layer 1、ジッタなし）

Under C4-F1/C4-T4-lean-B, the stay counter ticks once per prescaler period; a `Stay 5` at
`PRESCALE=5` should wait **5 × 5 = 25 system clocks**, exactly, every time.

C4-F1/C4-T4-lean-B の下では、ステイカウンタはプリスケーラ周期ごとに 1 回ティックする;
`PRESCALE=5` での `Stay 5` は毎回ちょうど **5 × 5 = 25 システムクロック**待つはずである。

- High phase (state 1): **25 clocks**, `timing_signals = 0x0001`.
- Low phase (state 3): **25 clocks**, `timing_signals = 0x0000`.
- Plus the per-transition FSM clocks for states 2 and 4 (NOP, Jump) and the one-time state 0.

If the implementation matched the ideal, **every high interval would be identical and every
low interval would be identical**, to the system clock.

実装が理想に一致するなら、**すべての high 区間が同一、すべての low 区間が同一**になるはず——
システムクロック単位で。

---

## Hypothesis under test (the A2 anomaly) / 検証下の仮説（A2 異常）

Because `presc_cnt` is free-running, the first stay tick after each `S_WAIT` entry arrives
not after a full prescaler period but after **(PRESCALE − presc_cnt_at_entry)** clocks —
i.e., a phase-dependent **1..5 clocks**. Subsequent ticks are a full 5 clocks apart. So:

`presc_cnt` が自由走行のため、各 `S_WAIT` 突入後の最初のステイティックは、完全なプリスケーラ
周期の後ではなく **(PRESCALE − 突入時 presc_cnt)** クロック後——すなわち位相依存の **1..5
クロック**後に到来する。以降のティックは完全な 5 クロック間隔。ゆえに:

```
actual wait = (first-tick delay, 1..PRESCALE) + (STAY−1) × PRESCALE
            = (1..5) + 4×5  =  21..25 system clocks      [per Stay window]
```

**Predicted observable:** the high and low intervals are **not constant** — they vary
within a window of up to **PRESCALE − 1 = 4 clocks**, depending on the prescaler phase at
the moment each `S_WAIT` is entered. The variation correlates with `presc_cnt` value
captured at the `S_RUN → S_WAIT` transition.

**予測される観測:** high/low 区間は**一定でない**——各 `S_WAIT` 突入の瞬間のプリスケーラ
位相に応じて、最大 **PRESCALE − 1 = 4 クロック**の窓内で変動する。変動は `S_RUN → S_WAIT`
遷移時に捕捉される `presc_cnt` 値と相関する。

---

## Signals to probe / 観測すべき信号

| Signal | Why |
|---|---|
| `fsm` (state enum) | to mark the exact `S_RUN → S_WAIT` entry clock / S_WAIT 突入クロックを標定 |
| `presc_cnt` | **the key signal** — its value at S_WAIT entry is the phase / **鍵信号**——突入時の値が位相 |
| `presc_tick` (or the tick condition) | to time the first stay tick after entry / 突入後の初回ティックを計時 |
| `stay_cnt` | to confirm 5 ticks per wait / 待機あたり 5 ティックを確認 |
| `stay_cnt_match` | the Stay-timeup pulse / Stay-timeup パルス |
| `state_num` | to correlate with program states 1/3 / プログラム state 1/3 と相関 |
| `timing_signals[0]` | the high/low marker whose width is being measured / 幅を測る high/low マーカー |

**Trigger:** on the `S_RUN → S_WAIT` transition (so each capture starts at a wait entry and
the entry-phase `presc_cnt` is visible). Capture several consecutive waits in one window if
depth allows, to compare phases across iterations.

**トリガ:** `S_RUN → S_WAIT` 遷移時(各キャプチャが待機突入で始まり、突入位相 `presc_cnt`
が見えるように)。深さが許せば連続する複数の待機を一窓で捕捉し、反復間の位相を比較する。

---

## Verdict criteria / 判定基準

| Observation | Verdict | Meaning & routing |
|---|---|---|
| All high intervals equal AND all low intervals equal (= 25 clk each, modulo fixed FSM overhead) | **PASS** | The prediction A2 is *wrong*; the prescaler is effectively wait-aligned. The bring-up "slightly off" is something else — re-open Hook A with a new hypothesis. |
| High/low intervals vary within ≤ 4 clocks, correlated with entry-phase `presc_cnt` | **ANOMALY (A2 confirmed)** | Free-running prescaler causes first-tick phase jitter. Route to Layer 1: decide C4-T3 phase dimension (free-running vs wait-aligned), and if wait-aligned is chosen, the fix is to reset `presc_cnt` on `S_WAIT` entry. |
| Some other pattern (e.g. variation > 4 clocks, or uncorrelated) | **ANOMALY (new)** | Unexpected; document fully and open a fresh investigation. |

A confirmed A2 is **not a bug to be silently patched**: resetting `presc_cnt` per wait would
make the prescaler a per-wait timer rather than a free-running time-base, which changes
`prescaler_match` semantics for any Formation that uses it. That is a conscious Layer 1
decision (C4-T3), which is exactly why this measurement is being recorded as evidence rather
than acted on unilaterally.

確認された A2 は**黙ってパッチすべきバグではない**: 待機ごとに `presc_cnt` をリセットすると、
プリスケーラは自由走行の時間基準ではなく待機ごとのタイマーになり、それを使う Formation の
`prescaler_match` 意味論が変わる。これは意識的な Layer 1 決定(C4-T3)であり、まさにそれゆえ
本測定は一方的に対処されるのではなくエビデンスとして記録される。

---

## Notes for the operator / 操作者への注

- This measurement wants **PRESCALE = 5** (not 50000) so the phase effect is visible within a
  SignalTap capture depth. A separate synthesis (or a small PRESCALE override) is needed.
  / 本測定は **PRESCALE = 5**(50000 ではなく)を要する。別合成または小さな PRESCALE 上書きが必要。
- ModelSim can show this too (white-box, exact `presc_cnt`), and is the cheaper first look;
  SignalTap then confirms it on silicon. Either or both produce a VCD + `observation.md`.
  / ModelSim でも見える(白箱、正確な `presc_cnt`)、かつ安価な初見;SignalTap が実機で確認。
- Remember to export the SignalTap capture to **VCD** (File → Export → VCD), not just a PNG.
  / SignalTap キャプチャは **VCD** にエクスポート(File → Export → VCD)、PNG だけにしない。

---

## Addendum (2026-06-21) — post-RH prediction / 追補 — RH 改修後の予測

> **Why this addendum exists.** The "Ideal prediction" and "A2 hypothesis" above were written
> *before* the source revision history RH001–RH008 (2026-06-14/15) was read. Those edits made
> **foreground commands prescaled** (RH001/006) and made the stay counter carry continuously
> from StaySet (RH002/003/004/005). The original 25:25-symmetric ideal and the framing of A2
> predate that change. Per the expected-before-observed discipline, the original text is kept
> intact above; this addendum records the corrected prediction that was then tested.
>
> **本追補の理由。** 上の「理想予測」と「A2 仮説」は、ソース改訂履歴 RH001–RH008（2026-06-14/15）を
> 読む*前*に書かれた。RH001/006 は**前景コマンドをプリスケールド実行**にし、RH002/003/004/005 は
> StaySet からステイカウンタを連続させた。元の 25:25 対称の理想と A2 の枠組みはその改修より前の
> もの。観察前予測の規律に従い、上の原文はそのまま残し、本追補に「その後に検証された訂正後の予測」を記録する。

### Revised prediction / 訂正後の予測

With foreground prescaling, **both** the foreground NOP (state 2) and Jump (state 4) each
consume one whole prescale unit. The naive program's steady period is therefore not 50 clk
(25:25) but **60 clk = 12 prescale units**, asymmetric **25:35**:

前景プリスケールド化により、前景 NOP（state 2）と Jump（state 4）が**双方とも**丸ごと 1 プリスケール
単位を消費する。ゆえに素朴プログラムの定常周期は 50 clk（25:25）ではなく **60 clk = 12 プリスケール
単位**、非対称の **25:35** となる:

```
high (state 1 Stay 5)                         = 5 × 5 = 25 clk
low  (state 3 Stay 5  +  NOP@2  +  Jump@4)     = 25 + 5 + 5 = 35 clk
period = 60 clk = 12 × PRESCALE   (integer multiple)
```

**This 25:35 is the CORRECT result, not an anomaly.** The +10 clk on the low side is the
foreground commands executing as prescaled commands — exactly as RH001/006 specify.

**この 25:35 は正しい結果であり、異常ではない。** low 側の +10 clk は前景コマンドがプリスケールド
コマンドとして実行された分で、RH001/006 の規定どおり。

### Effect on A2 (the key revision) / A2 への影響（核心の訂正）

Because the loop length is now an **integer multiple of the prescale period** (a structural
consequence of every foreground command being prescaled), the prescaler enters every
`S_WAIT` at the **same phase**. The phase-dependent first-tick jitter that A2 feared
therefore **cannot occur**: it would require a command consuming a prescale-misaligned
number of clocks, which RH001/006 eliminated. **Revised prediction: PASS — `presc_cnt`@entry
constant across all windows, zero jitter.**

ループ長が**プリスケール周期の整数倍**（全前景コマンドがプリスケールド化された構造的帰結）になった
ため、プリスケーラは毎回**同一位相**で `S_WAIT` に突入する。ゆえに A2 が恐れた位相依存の初回ティック・
ジッタは**起こり得ない**——それにはプリスケール非整合なクロックを消費するコマンドが必要だが、RH001/006 が
それを消した。**訂正後の予測: PASS——全ウィンドウで `presc_cnt`@entry 一定、ジッタゼロ。**

The bring-up "slightly off" of Hook A is therefore predicted to be **not jitter but the
25:35 duty asymmetry** (the foreground-prescaled contribution), plus the one-time longer
first ON caused by state 0's NOP absorbing the cold-start phase indeterminacy.

ゆえに Hook A の bring-up「わずかに off」は、**ジッタではなく 25:35 のデューティ非対称**（前景プリス
ケールド寄与）と、state 0 の NOP が冷態位相不定を吸収することによる初回 ON の一度きりの伸びである、と予測する。

### The four duty idioms (predicted) / デューティ4流儀（予測）

The same skeleton, varying only the foreground treatment, is predicted to yield four duties.
These are the stimuli `program_{A,B,C,D}.{hex,mif}` in this directory:

同一骨格で前景の扱いだけを変えると4種のデューティが得られると予測する。本ディレクトリの
`program_{A,B,C,D}.{hex,mif}` がそのスティミュラスである:

| Idiom / 流儀 | Foreground treatment / 前景の扱い | Predicted duty / 予測デューティ |
|---|---|:---:|
| A | naive (NOP OFF, Jump) / 素朴 | **25 : 35** |
| B | NOP@2 → ON (0x0001) | **30 : 30** |
| C | NOP@2 → ON + D17 flags (0x0003 / 0x0002) / 旗付き | **30 : 30** |
| D | StaySet / background NOP / ProgEnd / QueJump / Stay厳守 | **25 : 25** |

### Revised verdict criteria / 訂正後の判定基準

| Observation | Verdict | Meaning |
|---|---|---|
| `presc_cnt`@entry constant across all windows; duties match the table (A 25:35, B/C 30:30, D 25:25) | **PASS** | A2 rejected; foreground-prescaling phase-locks the loop. Route to documenting the four duty idioms (Layer 2 / Layer 3), not an anomaly fix. |
| `presc_cnt`@entry varies across windows; duties scatter | **ANOMALY (A2)** | Revert to the original A2 routing above (C4-T3 phase decision). |

> The original verdict table above remains valid as the *pre-RH* decision tree. This addendum
> supersedes its "ideal 25:25" row: under RH001–RH008, the naive idiom's correct steady duty
> is 25:35, and the PASS condition is phase-constancy (not 25:25 symmetry).
>
> 上の元の判定表は *RH 改修前* の決定木として有効なまま。本追補はその「理想 25:25」行を更新する:
> RH001–RH008 の下では素朴流儀の正しい定常デューティは 25:35 であり、PASS 条件は位相の不変性
> （25:25 対称ではない）である。

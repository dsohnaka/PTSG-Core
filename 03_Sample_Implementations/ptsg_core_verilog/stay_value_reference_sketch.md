# Reference sketch — `stay_value` (Formation-supplied Stay duration) / 参照スケッチ

> **Status / 状態:** PROVISIONAL, **not applied**. `ptsg_core.v` stays frozen at RH030 until the Layer 4 checkpoint; this change is to be folded into the batched Hook C review and given its RH number there. / 仮確定・**未適用**。Layer 4 チェックポイントまで RH030 で凍結;Hook C 一括レビューに合流し、そこで RH 番号を付与。
> **Spec / 仕様:** Chapter 4 § 4.7a, Chapter 5 § 5.12a (`01_Architecture/CHANGES_Layer1_stay-value_2026-09-26.md`). **Trace:** `02_Reasoning_Traces/2026-09-26_ptsg-stay-value-from-formation`.
> **License:** MIT (Layer 3).

## 1. The single substitution point / 唯一の置換点

In RH030, `stay_dur` is consumed only in `OP_STAY` — the bare same-clock timeup `(stay_cnt >= stay_dur - 1'b1)` and the latch `stay_target <= stay_dur` — while `S_WAIT` compares the latched `stay_target`. Redefining `stay_dur` therefore changes every Stay path (FG, BG, Q-scan) at once and makes the value read **once, at execute** by construction (C4-F16). / RH030 では `stay_dur` は `OP_STAY` でのみ消費され、`S_WAIT` はラッチ済み `stay_target` を比較する。ゆえに `stay_dur` の再定義だけで全経路に効き、「実行時一回読み」が構造的に成立する。

## 2. Form B — read in the execute clock (C4-T5 lean) / B 形——実行クロックで読む（傾向）

```verilog
// port list, beside prescaler_value (§5.10 group or a new §5.12a group)
    input  tri0 [CNT_W-1:0]   stay_value                  , // RH0xx: Formation-supplied Stay duration

// replaces the RH030 stay_dur declaration
    // Resolved Stay duration — IND-reverse (RH029 pattern applied to Stay, C4-F15):
    //   stay_value != 0 => stay_value ; else operand ; operand 0 => 4096 (C2-F3)
    //   The zero test and the value are ONE sample (C5-F4).
    wire [CNT_W:0] stay_dur_lit = (operand == 12'd0) ? (1'b1 << CNT_W) : {1'b0, operand};
    wire [CNT_W:0] stay_dur     = (stay_value != {CNT_W{1'b0}}) ? {1'b0, stay_value} : stay_dur_lit;
```
No other line changes. No register is added, so no reset question arises. The only new combinational path is `stay_value → mux → (−1) → compare` in the bare same-clock timeup — the path the operand already takes. / 他の行は不変。レジスタを足さないのでリセットの問いも生じない。

## 3. Form A — registered one clock ahead (C4-T5 alternative) / A 形——1 クロック前に登録

```verilog
    reg [CNT_W-1:0] stay_valueR;                    // pure input pipeline: deliberately NO rst
    always @(posedge clk) stay_valueR <= stay_value; // (a reset-to-0 would force one "as written" clock)
    wire [CNT_W:0] stay_dur = (stay_valueR != {CNT_W{1'b0}}) ? {1'b0, stay_valueR}   // zero test on the
                                                               : stay_dur_lit;        // SAME registered sample
```
Consequence: a Stay uses the pin as it stood one clock before its execute; `len_lut[state_number]` then needs next-state knowledge. / 帰結: 1 クロック先読みとなり、`len_lut[state_number]` は次ステートの知識を要する。

## 4. Anti-pattern — do not copy RH029-as-built / 反パターン——RH029 現行形を写さない

```verilog
    // WRONG: raw-pin zero test beside a registered value
    wire [CNT_W:0] stay_dur = (stay_value != 0) ? {1'b0, stay_valueR} : stay_dur_lit;
```
On a 0→N change in the clock before a Stay executes, `stay_value` already reads N while `stay_valueR` still holds 0: the Stay latches duration 0, `stay_target - 1'b1` wraps to 13'h1FFF, and the Stay runs **8192 ticks** — the quiet-runaway class RH028 retired. For the prescaler the same slip costs one comparison; for a Stay it costs the whole Stay. / 0→N の変化時に 0 をラッチし 8192 ティック暴走。プリスケーラなら比較一回分のずれが、Stay では全体を奪う。

## 5. Width variant (Tie C5-T2 alternative) / 幅の代替案

`input tri0 [CNT_W:0] stay_value` and `stay_dur = (stay_value != 0) ? stay_value : stay_dur_lit;` — pin values up to 8191 on the existing 13-bit `stay_cnt`. `stay_counter` (12-bit, diagnostic) would alias above 4095.

## 6. Independent, optional refactor / 独立・任意のリファクタ

If timing closure ever asks for it, `S_WAIT` can compare a pre-decremented latch (`stay_targetM <= stay_dur - 1'b1`; `stay_cnt >= stay_targetM`) — behaviour-identical for every Stay source and unrelated to this feature.

## 7. Tests (Hook B) / 試験

| # | Stimulus | Expected |
|---|---|---|
| SV-0 | Pin tied 0: T1/T2/T32/T34, P=1 set, Scene 4 program | Bit-identical to RH030 |
| SV-1 | Bare Stay, pin = N, P = 1 | Stay lasts N clocks |
| SV-2 | Pin = 1, P = 1 | One clock (like FG NOP) |
| SV-3 | Pin N1 → N2 during a Stay | Current Stay N1; next Stay N2 |
| SV-4 | 0 → N in the execute clock (Form B) / in the clock before (Form A) | That Stay = N; the anti-pattern shows 8192 ticks — the test must catch it |
| SV-5 | Windowed Stay, pin below the window's elapsed count | Timeup on the first tick in S_WAIT |
| SV-6 | Stay(0), pin silent | 4096 ticks — **first exercise of C2-F3** |
| SV-7 | Two-entry `len_lut[state_number]` (on/off lengths differ; 0 entry = as written) | Per-state lengths; 0 entry keeps the operand |

## 8. Draft header entry (number and date at the checkpoint) / 改訂履歴の下書き

```
// 0xx YYYY-MM-DD       Arch. Ohnaka  Add : Formation-supplied Stay duration (PROVISIONAL; C4-F15..F17, C5-F4).
//                                          New optional port stay_value (tri0 [CNT_W-1:0]). IND-reverse, the
//                                          RH029 pattern applied to Stay: stay_value != 0 => that value;
//                                          0/unconnected => the operand (0 => 4096, C2-F3). stay_dur is the
//                                          single substitution point, so the duration is read ONCE, at the
//                                          Stay's execute clock, and held in stay_target for the whole Stay
//                                          (a pin change mid-Stay affects later Stays only). RH028 >= applies
//                                          unchanged. Zero test and value are one sample (never a raw-pin zero
//                                          test beside a registered value: 0->N would latch 0 => 8192-tick
//                                          runaway). Requirement: WPMS packet length = Stay length.
//                                          Trace: 2026-09-26_ptsg-stay-value-from-formation.
```

# observation — blinky 1 Hz @ P=6250: grid absorption of the Reset clock
# 観測判決 — 1 Hz L チカ @ P=6250: Reset クロックのグリッド吸収

**Verdict / 判決: PASS — prediction confirmed at single-clock granularity. / 合格——予言を1クロック粒度で確認。**

## Claim on trial / 審理対象の主張
A bare-Stay blinker (`0000FA01` / `0001FA01`, remainder zero-filled = Reset) at P=6250 has a period of **exactly 50,000,000 clocks (1.000000 s at 50 MHz) with duty exactly 1:1**; the Reset instruction's single clock (20 ns) is **absorbed inside the first prescale interval of the return-side (address-0) Stay** and never appears in surface time. Prediction frozen in the Live Session #1 storyboard (Scene 2) before filming; the oscilloscope trial (Build Log "Putting 'Approximately' on Trial") returned *consistent but not yet convicted* — 0.02 ppm lies below crystal tolerance — and was adjourned to this SignalTap court.

裸 Stay の点滅器(`0000FA01`/`0001FA01`、残余0フィル=Reset)は P=6250 において**周期が正確に 50,000,000 クロック(50 MHz で 1.000000 秒)、デューティ厳密 1:1**であり、Reset 命令の 1 クロック(20 ns)は**戻り側(0番地)Stay の最初のプリスケール区間内に吸収**され、表時間に現れない。予言は撮影前に第一話絵コンテ(シーン2)で凍結;オシロ法廷(Build Log「『約』を裁判にかける」)は「整合、未確定」(0.02 ppm は水晶公差の下)として本 SignalTap 法廷へ移送した。

## Evidence / 証拠物件
- `blinky_1Hz_prec6250_PTSG_MEM.hex` — program under test / 被験プログラム
- `blinky_1Hz_prec6250_1to0.vcd` — SignalTap capture, on→off seam (contains the Reset) / 点灯→消灯の縫い目(Reset を含む)
- `blinky_1Hz_prec6250_0to1.vcd` — SignalTap capture, off→on seam (control) / 消灯→点灯の縫い目(対照)
- `blinky_1Hz_prec6250_1to0.gif`, `blinky_1Hz_prec6250_oto1.gif` — auxiliary renderings / 補助画像
- Capture date (VCD header): 2026-07-21 23:05. Commit hash: **[TO FILL by architect]**. Bitstream checksum: **[TO FILL]**. Signals: fsm one-hots, state_num, presc_cnt, presc_tick, stay_cnt, timing_signals, window_open, queued_valid, address_a/q_a, indirect handshake. 512-sample windows, one sample per 50 MHz clock (VCD timescale 1 ps, 20,000 ps/step).

## Decoded timeline / 復号タイムライン (clock numbers relative to each capture)

| clk | 1→0 seam (with Reset) | 0→1 seam (control) |
|---|---|---|
| 0 | SN=1 (on-Stay, S_WAIT), tsig=1, stay_cnt=3999, presc_cnt=6124 | SN=0 (off-Stay, S_WAIT), tsig=0, stay_cnt=3999, presc_cnt=6124 |
| 126 | **presc_tick** (4000th tick — Stay-timeup) | **presc_tick** (Stay-timeup) |
| 127 | SN 1→2 (fetch Reset); stay_cnt cleared; **presc_cnt=1 — the grid keeps running** | SN 0→1 (fetch on-Stay); stay_cnt cleared |
| 128 | SN 2→0 (Reset executes); **tsig 1→0 (LED falls)** | **tsig 0→1 (LED rises)** |

## Findings / 所見
1. **Both LED edges land exactly tick+2 clocks — with and without the Reset in the path.** The pipeline latency (tick → SN update → registered tsig) is uniform, so it cancels edge-to-edge: each half-period spans exactly 4000 tick intervals = 25,000,000 clocks; the full period is **exactly 50,000,000 clocks**. Duty is exactly 1:1. / **LED の両縁が、Reset の有無にかかわらず正確にティック+2クロックに着地。** パイプライン遅延(tick→SN更新→レジスタ済み tsig)は一様で縁対縁では相殺され、各半周期は正確に 4000 ティック区間 = 25,000,000 クロック;全周期は**正確に 50,000,000 クロック**。デューティ厳密 1:1。
2. **The Reset's clock exists — internally.** SN=2 for exactly one clock (clk 127→128). It displaces the arming of the address-0 Stay by one clock, but a bare Stay counts *grid ticks*, not clocks-since-arm, so the next timeup remains on the grid: the 20 ns is absorbed inside that Stay's first prescale interval, exactly as claimed. / **Reset のクロックは内部には実在する**(SN=2 がちょうど1クロック)。それは0番地 Stay のアームを1クロック遅らせるが、裸 Stay は*グリッドのティック*を数えるため次の timeup は格子上に留まる: 20 ns は当該 Stay の最初のプリスケール区間内に吸収される——主張どおり。
3. **C3-F21 directly witnessed:** presc_cnt = 1, 2 … continuing across the Reset (clk 127–128); the prescaler is untouched. / **C3-F21 を直接目撃:** Reset を跨いで presc_cnt が 1, 2… と継続;プリスケーラは不擾乱。
4. **RH028 arithmetic in the wild:** terminal stay_cnt = 3999 = target−1 at timeup — the `>=` earliest-fire discipline's steady-state face. / **RH028 算術の野生の姿:** timeup 時の stay_cnt 終端値 3999 = target−1——`>=` 最早発火規律の定常状態の顔。
5. No window (window_open=0 throughout), no queue activity, no indirect activity — the bare-Stay case is clean. / 全区間 window_open=0、キュー・間接活動なし——裸 Stay ケースとして清浄。

## Decisions exercised / 行使された決定
C4-F8/F9 (free-running prescaled execution), C3-F21 (Reset never resets presc_cnt), §3.4b Stay-FG "Consumes" × Reset-FG "Ignored" symmetry, RH028 ③ (`>=` timeup), §1.4a trailing-edge alignment of all transitions.

## Disposition / 処置
- conformance_matrix: add/mark the grid-absorption claim **silicon-verified (SignalTap, 2026-07-21)**; cross-reference Build Log entry and Live Session #1 Scene 2. / conformance_matrix にグリッド吸収の主張を**実機検証済(SignalTap、2026-07-21)**として記載;Build Log と第一話シーン2を相互参照。
- The uniform tick+2 edge latency observed here is also the mechanism behind the clean 8→16 Hz "barline" transition; it feeds the pending **barline-rule** codification item. / 本観測の一様なティック+2縁遅延は、8→16 Hz の「小節線」遷移の清浄さの機構でもあり、係属中の**小節線規則**成文化項目への入力となる。

*Predictions were frozen before filming; this document records the verdict as measured. / 予言は撮影前に凍結済み;本書は測定された判決をそのまま記録する。*

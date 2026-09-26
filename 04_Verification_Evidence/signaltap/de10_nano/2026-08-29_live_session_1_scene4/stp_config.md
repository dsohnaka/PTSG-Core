# SignalTap config — Live Session #1, Scene 4 (prescaler_value live) @ DE10-nano / SignalTap 設定

> Reconstructed by the amanuensis on 2026-09-26 from the exported VCDs and the SignalTap screenshots (the `.stp` file itself was not provided). Items marked *(confirm)* are inferences for the architect to confirm. / 2026-09-26、祐筆がエクスポート VCD とスクリーンショットから復元（`.stp` 本体は未受領）。*(confirm)* はアーキテクト確認待ちの推定。

**Date / 日付:** 2026-08-29 (triggers 16:28:29 = B, 16:39:03 = A)
**Board / ボード:** DE10-nano (Cyclone V 5CSEBA6), FPGA_CLK1_50 = 50 MHz
**Core / コア:** `ptsg_core.v` RH030 head; `EDGE="NEG"`, `VENDOR="M10K"`; boot `PRESCALE` = 6250 (3.2 Hz); `prescaler_value` = 20 via ISSP during the captures (1 kHz output)
**Program loaded (ISMCE) / ロード済プログラム:** `0:0000_4E21` Stay 1250 tsig 0 · `1:0001_4E21` Stay 1250 tsig 1 · `2:0000_0000` Reset
**Sample clock / サンプルクロック:** FPGA_CLK1_50 (recorded in the VCD as a signal; hence 2 time stamps per sample)
**Sample depth / サンプル深さ:** 256 (verified: 256 rising edges of FPGA_CLK1_50 per VCD)
**Trigger position / トリガ位置:** near centre — the seam lies at samples 127–128 *(confirm)*

## Probed signals / プローブ信号
- `FPGA_CLK1_50`
- `ptsg_core1|fsm.S_RUN`, `fsm.S_WAIT`, `fsm.S_IND`, `fsm.S_PUSH`, `fsm.S_POP`
- `ptsg_core1|state_num[11:0]`, `address_a[7:0]` (imem), `q_a[31:0]` (imem)
- `ptsg_core1|stay_cnt[12:0]`
- `ptsg_core1|presc_cnt[31:0]` (probe width as captured) *(confirm the instance's PRESC_W)*, `presc_tick`, `prescaler_match`
- `ptsg_core1|timing_signals[15:0]`
- `ptsg_core1|window_open`, `prog_end_seen`, `queued_valid`, `indirect_ready`, `ind_resolved`

## Trigger / トリガ
- **Capture A (`capture_A_rise.*`):** `timing_signals[0]` rising (state 0 → 1 seam) *(confirm)*
- **Capture B (`capture_B_fall.*`):** `timing_signals[0]` falling (state 1 → 2 (Reset) → 0 seam) *(confirm)*

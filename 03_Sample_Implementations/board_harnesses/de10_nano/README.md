# DE10-nano Harness / DE10-nano ハーネス

> **License: MIT.** Build harness for the Terasic DE10-nano (Intel Cyclone V SoC).
> Provides a working PTSG-Core build with a **zero-re-synthesis JTAG development
> loop**: swap PTSG programs and reset the core entirely over JTAG.
>
> **ライセンス: MIT。** Terasic DE10-nano(Intel Cyclone V SoC)用ビルドハーネス。
> **再合成ゼロの JTAG 開発ループ**を備えた動作する PTSG-Core ビルドを提供する:
> PTSG プログラムの差し替えとコアのリセットを、すべて JTAG 越しに行える。

---

## Board facts / ボード前提

| Item | Value |
|---|---|
| Board / ボード | Terasic DE10-nano |
| Device / デバイス | Cyclone V SoC 5CSEBA6U23I7 |
| System clock / システムクロック | `FPGA_CLK1_50` = 50 MHz |
| JTAG | On-board USB-Blaster II (DE-SoC) |

## What this harness provides / このハーネスが提供するもの

- `DE10_Nano_golden_top.v` — the board's golden top (pin definitions) with the PTSG
  Core instantiated and wired to LEDs/keys / ボードの golden top に PTSG コアを
  インスタンスし LED/KEY へ配線したトップ層
- Quartus project files and pin assignments / Quartus プロジェクトとピン割り当て
- In-System Sources & Probes instance for JTAG-driven reset / JTAG 駆動リセットの
  ための In-System Sources & Probes インスタンス
- (Optional) SignalTap configurations used during bring-up / ブリングアップで使用した
  SignalTap 構成

## What this harness depends on (referenced, not copied) / 依存するもの(参照、非コピー)

- `../../ptsg_core_verilog/ptsg_core.v` — the Core / コア本体
- `../../ai_friendly_vendor_wrappers/ptsg_imem/ptsg_imem.v` — instruction memory,
  configured here as **`VENDOR="M10K"`, `EDGE="NEG"`, `RD_LAT=1`**, ISMCE-enabled
  / 命令メモリ。本ハーネスでの構成は **`VENDOR="M10K"`、`EDGE="NEG"`、`RD_LAT=1`**、ISMCE 有効
- `../../examples/*.mif` — PTSG programs (`.mif` for Quartus/ISMCE) / PTSG プログラム

## Build / ビルド

1. Open the Quartus project. / Quartus プロジェクトを開く。
2. Confirm the `ptsg_imem` parameters above and the initial program
   (`INIT_FILE_MIF`, e.g. `blinky_with_prescaler.mif`). / `ptsg_imem` パラメータと
   初期プログラムを確認。
3. Compile; program the `.sof` over JTAG. / コンパイルし、`.sof` を JTAG で書込み。
4. Expected first light: the prescaled LED blink (PRESCALE = 50000 → visible blink at
   50 MHz). / 期待される初点灯: プリスケール LED 点滅。

Resource reference point: the bring-up build closed at **≈235 LEs + 2 M10K blocks**
(core + memory; SignalTap excluded). / リソース参考値: ブリングアップ時 **約 235 LE +
M10K 2 ブロック**(SignalTap 除く)。

## The zero-re-synthesis JTAG loop / 再合成ゼロの JTAG ループ

This is the harness's main payoff: developing PTSG programs at software speed.

これがこのハーネスの主たる成果である: ソフトウェアの速度で PTSG プログラムを開発する。

1. **Swap the program:** Tools → In-System Memory Content Editor → instance **`PTSG`**
   → load a `.mif`/`.hex` from `examples/` (or hand-edit words) → write to the device.
   / **プログラム差替:** ISMCE のインスタンス **`PTSG`** に書込み。
2. **Reset the core:** Tools → In-System Sources and Probes → toggle the reset source
   bit. / **コアをリセット:** Sources & Probes でリセットビットをトグル。
3. **Observe:** LEDs/pins, or SignalTap for cycle-accurate inspection.
   / **観察:** LED/ピン、またはサイクル精度には SignalTap。

No re-synthesis at any step. Write instructions, press reset, watch the pins — the
FPGA is being *programmed* in the PTSG sense of the word.

どの工程にも再合成は無い。命令を書き、リセットを押し、ピンを見る——FPGA は PTSG の
意味で*プログラムされて*いる。

## SignalTap starter probe set / SignalTap 推奨プローブ

For timing verification, probe: the M10K `address_a` and `q_a`, `state_num`,
`stay_cnt`, `presc_cnt`, `prescaler_match`, `timing_signals`, and the core FSM state.
Trigger on the S_WAIT entry to capture Stay-window boundaries.

タイミング検証には: M10K の `address_a` と `q_a`、`state_num`、`stay_cnt`、
`presc_cnt`、`prescaler_match`、`timing_signals`、コア FSM 状態。Stay ウィンドウ境界の
捕捉には S_WAIT 突入でトリガ。

Diagnostic heuristic from the bring-up: **an address outside the program's reachable
set is a one-clock-stale fetch** (see Build Log #6 — address `05h` in a 5-state
program was the smoking gun for the `EDGE="POS"`-without-fetch-stage defect).

ブリングアップで得た診断ヒューリスティック: **プログラムの到達可能集合の外のアドレスは
1クロック古いフェッチ**(Build Log #6 ——5ステートプログラムでのアドレス `05h` が
動かぬ証拠だった)。

## 100 MHz operation / 100MHz動作（RH029）

The harness now ships a second top, **`DE10_Nano_ptsg100_top.v`**, that runs the
Core at 100 MHz, plus a shared `.sdc` that constrains both builds:

ハーネスに第二のトップ **`DE10_Nano_ptsg100_top.v`**（コアを100MHzで駆動）と、
両ビルドを拘束する共通 `.sdc` を追加した：

1. **Switch tops / トップ切替:** in the `.qsf`, change `TOP_LEVEL_ENTITY` to
   `DE10_Nano_ptsg100_top` (a commented line is provided next to the file list).
   / `.qsf` の `TOP_LEVEL_ENTITY` を `DE10_Nano_ptsg100_top` に変更（ファイル
   リスト付近にコメント行あり）。
2. **Clock source / クロック源:** the DE10-nano has no 100 MHz oscillator; an
   on-chip PLL (direct `altera_pll` instantiation, ×2 from `FPGA_CLK1_50`)
   generates it. `derive_pll_clocks` in the `.sdc` constrains the 100 MHz
   output automatically. / ボードに100MHz発振器は無いため、オンチップPLL
   （`altera_pll` 直接インスタンス、`FPGA_CLK1_50`×2）で生成。SDCの
   `derive_pll_clocks` が自動拘束する。
3. **Reset conditioning / リセット整形:** the JTAG-sourced reset bit is 2-FF
   synchronized into the 100 MHz domain and held until PLL lock. / JTAG由来の
   リセットは2FF同期＋PLLロックまで保持。
4. **Time-axis scaling — read this / 時間軸スケーリング——必読:** the PTSG time
   axis is the **tick grid**, not the raw clock. Doubling the clock without
   touching `PRESCALE` runs every existing program **twice as fast**. The 100 MHz
   top therefore doubles `PRESCALE` (50000 → **100000**), keeping the tick period
   at 1 ms — programs written for the 50 MHz build keep their wall-clock timing
   unchanged. Set it per your needs. / PTSGの時間軸は**tickグリッド**であり生
   クロックではない。`PRESCALE` を触らずクロックを2倍にすると全プログラムが
   **2倍速**で走る。100MHzトップは `PRESCALE` を2倍（50000→**100000**）にして
   tick周期1msを維持——50MHz用プログラムの実時間タイミングは不変。用途に応じて
   調整のこと。
5. **Expected critical path / 想定クリティカルパス:** the `EDGE="NEG"` imem
   half-cycle path (M10K negedge → decode → FSM posedge) becomes a **5 ns**
   budget at 100 MHz — the "Known state" item below, now binding. TimeQuest
   analyzes it automatically (no SDC action needed and **no multicycle waiver
   is legitimate**: the FSM genuinely consumes the word on the next rising
   edge). After compiling, check setup slack on paths from `ptsg_imem`'s M10K
   to the core registers. If it fails on this -7 device, the remedies are
   RTL-side (the `EDGE="POS"` + fetch-stage migration in the `ptsg_imem`
   README) or a faster speed grade — not SDC relaxation. / `EDGE="NEG"` の
   半サイクルパスが100MHzでは**5ns**予算になる（下記「既知の状態」項がここで
   拘束化する）。TimeQuestは自動解析する（SDC操作は不要、**multicycle緩和は
   不正**——FSMは本当に次の立ち上がりで語を消費する）。コンパイル後、M10K→
   コアレジスタのセットアップ・スラックを確認。-7デバイスで不成立なら、対策は
   RTL側（`ptsg_imem` READMEの `EDGE="POS"`＋フェッチ段移行）か上位スピード
   グレードであり、SDCの緩和ではない。

The `.sdc` additionally constrains the JTAG domain (TCK 25 MHz upper bound,
async clock group) — the ISMCE/Sources-&-Probes/SignalTap zero-re-synthesis
loop lives there — and false-paths the human I/O (KEY/SW/LED).

`.sdc` はさらにJTAGドメイン（TCK 25MHz上限・非同期クロックグループ——再合成ゼロ
ループの住処）を拘束し、ヒューマンI/O（KEY/SW/LED）をfalse path化している。

## Known state / 既知の状態

- **Working, `EDGE="NEG"`:** aligned instruction fetch verified by SignalTap on
  2026-06-11 (no overrun addresses; Jump lands on its clock). / **動作中、`EDGE="NEG"`:**
  2026-06-11 に SignalTap で整列フェッチを検証済み。
- **Half-cycle timing path:** memory(negedge) → decode → FSM(posedge). Non-binding at
  50 MHz; treat as a real constraint if raising the clock (see the `ptsg_imem` README
  for the `EDGE="POS"` + fetch-stage migration path). / **半サイクルパス:** 50 MHz では
  非拘束；クロックを上げる場合は実在の制約として扱う。
- **Open item (Hook A of the 2026-06-11 trace):** a slight residual anomaly in the
  aligned capture; leading suspect is free-running-prescaler phase jitter (the first
  stay tick after S_WAIT entry may arrive after a phase-dependent 1..PRESCALE clocks).
  Under measurement. / **未決事項(Hook A):** 整列後キャプチャの軽微な違和感；第一容疑は
  自由走行プリスケーラの位相ジッタ。測定中。

---

> *Copy this directory to port to a new board. Replace the pins, constraints, and
> project files. Keep everything it references unchanged.*
>
> *新ボードへの移植は本ディレクトリを複製。ピン・制約・プロジェクトを差し替え、
> 参照先は変えない。*

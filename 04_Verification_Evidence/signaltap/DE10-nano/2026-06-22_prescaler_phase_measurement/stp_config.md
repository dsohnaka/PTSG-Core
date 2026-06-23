# stp_config.md — SignalTap setup / SignalTap 設定

> Probe and trigger configuration for the silicon capture of `prescaler_phase_measurement`.
> The probe list below is reconstructed from the exported VCDs; **board-specific trigger and
> acquisition-depth values are marked `[architect to confirm]`** where they cannot be
> recovered from the VCD alone.
>
> `prescaler_phase_measurement` 実機キャプチャのプローブ・トリガ設定。プローブ一覧は
> エクスポート済み VCD から復元;**VCD だけでは復元できない基板固有のトリガ・取得深度は
> `[architect to confirm]` と記す**。

| Field / 項目 | Value / 値 |
|---|---|
| Board / 基板 | DE10-nano (Cyclone V 5CSEBA6) |
| Acquisition clock / 取得クロック | `FPGA_CLK1_50` (50 MHz) — one sample per system clock / システムクロック毎に1サンプル |
| Core parameter / コアパラメータ | `PRESCALE = 5` (synthesis) |
| Sample depth / サンプル深度 | 512 (capture spans ~256 system clocks after CLK posedge sampling) `[architect to confirm]` |
| Program load / プログラムロード | In-System Memory Content Editor (ISMCE) over JTAG / ISMCE 経由（JTAG） |

---

## Probes / プローブ

Captured signal set (from the VCD). These give white-box-grade visibility on silicon; the
**bold** signals are the ones `expected.md` asks for.

捕捉信号一式（VCD より）。実機上で白箱級の可視性を与える;**太字**は `expected.md` が要求する信号。

| Probe / プローブ | Width | Why / 理由 |
|---|---|---|
| `FPGA_CLK1_50` | 1 | acquisition clock / 取得クロック |
| **`state_num`** | 12 | mark state transitions; correlate with program states / 状態遷移の標定 |
| **`presc_cnt`** | 32 | **the key signal** — phase at each state/`S_WAIT` entry / **鍵信号**——突入位相 |
| **`prescaler_match`** | 1 | prescaler tick / プリスケーラ・ティック |
| **`stay_cnt`** | 13 | confirm 5 ticks per Stay window / 待機あたり5ティック確認 |
| **`timing_signals`** | 16 | high/low marker whose width is measured (bit 0 = ON/OFF) / 幅測定マーカー |
| `window_open` | 1 | StaySet background-window state (idiom D) / 背景ウィンドウ状態 |
| `prog_end_seen` | 1 | ProgEnd latch (idiom D) / ProgEnd ラッチ |
| `queued_valid` | 1 | queued-Jump latch (idiom D) / キュー Jump ラッチ |
| `address_a` | 8 | instruction-memory address / 命令メモリアドレス |
| `q_a` | 32 | instruction-memory read data / 命令メモリ読出データ |
| `fsm.S_RUN/S_WAIT/S_PUSH/S_POP/S_IND` | 1 each | FSM state one-hot (S_RUN/S_WAIT used here) / FSM ワンホット |

---

## Trigger / トリガ

`[architect to confirm]` — the captures begin near cold start (the state-0 region and first
ON are visible in the VCDs), consistent with a **post-reset / continuous** acquisition rather
than a conditional trigger. For a phase-focused recapture, `expected.md` recommends triggering
on the `S_RUN → S_WAIT` transition so each window starts at a wait entry with the entry-phase
`presc_cnt` visible.

`[architect to confirm]`——キャプチャは冷態起動付近から始まり（state-0 領域と初回 ON が VCD に見える）、
条件トリガではなく**リセット後／連続**取得と整合する。位相に焦点を当てた再捕捉では、`expected.md` は
`S_RUN → S_WAIT` 遷移でのトリガを推奨（各ウィンドウが突入位相 `presc_cnt` 可視の待機突入で始まる）。

---

## Idiom swap procedure / 流儀切替手順

1. Open ISMCE (Tools → In-System Memory Content Editor) over the connected JTAG chain.
2. Load `ismce/blinky_with_prescaler_<X>_ISMCE.hex` (X ∈ {A,B,C,D}) into the PTSG instance.
3. Reset the Core (Sources & Probes, active-high reset).
4. Arm SignalTap, capture, then File → Export → **VCD**.

**No recompile between idioms** — the four behaviours differ only in instruction-memory
content. This is the headline of §6 in the silicon `observation.md`.

**流儀間で再コンパイル不要**——4挙動は命令メモリ内容のみが異なる。実機 `observation.md` §6 の要点。

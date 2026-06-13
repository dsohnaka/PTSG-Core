# Board Harnesses / ボードハーネス

> **License: MIT.** Board-specific glue that connects the device-independent PTSG Core
> to a particular piece of hardware. One subdirectory per board.
>
> **ライセンス: MIT。** デバイス非依存の PTSG コアを特定のハードウェアに接続する、
> ボード固有の貼り付け。ボードごとに一つのサブディレクトリ。

## What a harness IS / ハーネスであるもの

- The top-level wrapper instantiating the core (and wrappers) and mapping them to the
  board's pins / コア(とラッパー)をインスタンスし、ボードのピンへ写像するトップ層
- Pin assignments and timing constraints (`.sdc`) / ピン割り当てとタイミング制約
- Tool project files (Quartus `.qpf`/`.qsf` etc.) / ツールプロジェクトファイル
- Instrument configurations (SignalTap `.stp`, In-System Sources & Probes) and the
  board's debug-loop documentation / 計測器設定とデバッグループの文書

## What a harness is NOT / ハーネスでないもの

- **Not the core.** `ptsg_core.v` lives in `../ptsg_core_verilog/` and is identical for
  every board. / **コアではない。** コアは全ボードで同一。
- **Not the wrappers.** Vendor-abstracted parts live in
  `../ai_friendly_vendor_wrappers/` and are shared across boards of the same vendor
  family. / **ラッパーではない。** 同ベンダファミリのボード間で共有される。
- **Not the programs.** Instruction lists live in `../examples/` and run on any
  conforming implementation. / **プログラムではない。** 命令列は任意の準拠実装で走る。

A harness should *reference* those three; it should not copy them. To port PTSG to a
new board: copy a harness directory, replace the pins, constraints, and project files,
keep everything it references unchanged.

ハーネスはこの三つを*参照*すべきであり、コピーすべきではない。新ボードへの移植は:
ハーネスディレクトリを複製し、ピン・制約・プロジェクトを差し替え、参照先は変えない。

## Available harnesses / 利用可能なハーネス

| Board | Status |
|---|---|
| `de10_nano/` — Terasic DE10-nano (Cyclone V 5CSEBA6) | **Working.** First-light 2026-06-10; aligned-fetch verification 2026-06-11 (Build Log #6). Zero-re-synthesis JTAG development loop. / **動作中。** 再合成ゼロの JTAG 開発ループ。 |

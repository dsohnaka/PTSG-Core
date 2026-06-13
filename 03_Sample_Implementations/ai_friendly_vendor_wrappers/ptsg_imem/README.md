# ptsg_imem — Vendor-Abstracted Instruction Memory / ベンダ抽象化命令メモリ

> **License: MIT.** SIM branch (portable behavioral) and Cyclone V M10K branch
> (`altsyncram`, In-System Memory Content Editor enabled), one port list, one
> machine-checked timing contract. **M10K branch silicon-verified on DE10-nano,
> 2026-06-11** (see Build Log #6).
>
> **ライセンス: MIT。** SIM ブランチ(可搬 behavioral)と Cyclone V M10K ブランチ
> (`altsyncram`、ISMCE 有効)、一つのポートリスト、一つの機械検証されたタイミング契約。
> **M10K ブランチは 2026-06-11 に DE10-nano で実機検証済み**(Build Log #6 参照)。

| File | Purpose |
|---|---|
| `ptsg_imem.v` | The wrapper (v2: `EDGE` parameter). / ラッパー本体(v2: `EDGE` パラメータ)。 |
| `tb_align.v` | FSM's-eye contract check: proves the alignment each `EDGE` mode delivers to a posedge FSM. / FSM 視点の契約検証。 |

## Parameters / パラメータ

| Parameter | Values | Meaning |
|---|---|---|
| `RD_LAT` | ≥ 1 | Synchronous read latency in memory-clock edges. **There is no asynchronous-read M10K** — the input address register is mandatory, so `RD_LAT=0` does not exist on silicon. / メモリクロックエッジ単位の同期読みレイテンシ。**非同期読み M10K は存在しない。** |
| `EDGE` | `"NEG"` (default) / `"POS"` | Which system-clock edge clocks the memory. Applied identically to **both** branches (`mem_clk = (EDGE=="NEG") ? ~clk : clk`). / メモリをどのエッジでクロックするか。**両**ブランチに同一適用。 |
| `VENDOR` | `"SIM"` / `"M10K"` | Behavioral (any simulator) vs `altsyncram` (Quartus/ModelSim-Altera only). |
| `INIT_FILE_HEX` / `INIT_FILE_MIF` | path | `$readmemh` init (SIM) / `init_file` (M10K). Matching pairs live in `../../examples/`. |

## The two EDGE modes / 二つの EDGE モード

**`EDGE="NEG"` (requires `RD_LAT==1`) — current configuration.** The memory clocks on
the falling edge. An address registered by the FSM at posedge N is captured at N+0.5
and the data is valid before posedge N+1. **From the posedge FSM's viewpoint this is a
zero-effective-latency read**: at every rising edge, `rdata == mem[current addr]`. The
single-phase PTSG core FSM works **unmodified**, and the 1-clock-per-opcode model
(Layer 1 C2-T4) is preserved. Cost: the path memory→`q`→decode→FSM is a **half-cycle
path** — comfortable at 50 MHz (≈10 ns budget vs M10K Tco ≈2.4 ns + decode), practical
ceiling roughly 80–120 MHz on Cyclone V.

**`EDGE="NEG"`(`RD_LAT==1` 必須)——現行構成。** メモリは立ち下がりでクロックされる。
posedge FSM の視点では**実効レイテンシ0の読み**: 単相 PTSG コア FSM は**無改修**で
正しく、1命令1クロックモデル(C2-T4)が保持される。代償は半サイクルパス——50 MHz では
余裕、Cyclone V での実用上限はおよそ 80-120 MHz。

**`EDGE="POS"` — the high-clock migration path.** The memory clocks on the rising edge;
data arrives `RD_LAT` posedges after the address. The consuming FSM **must** add a fetch
stage (present address → wait `RD_LAT` clocks → decode). Connecting a `"POS"` memory to
the unmodified single-phase FSM produces a one-clock-stale instruction fetch — the
exact defect captured by SignalTap on 2026-06-10 (an impossible address `05h` on the
bus; see Build Log #6). `tb_align.v` reproduces that defect in simulation on demand.

**`EDGE="POS"`——高クロック移行経路。** 利用側 FSM は**必ず**フェッチ段を追加すること。
`"POS"` メモリを無改修の単相 FSM に接続すると 1 クロック古い命令フェッチになる——
2026-06-10 に SignalTap が捕えたまさにその欠陥(バス上の不可能なアドレス `05h`；
Build Log #6)。`tb_align.v` はその欠陥をシミュレーションで再現する。

## Verification status / 検証状況

- **SIM branch:** machine-proved under Icarus Verilog. `tb_align.v` drives the address
  as a posedge-NBA register (like `state_num`) and consumes `rdata` by posedge
  registration (like the FSM): `EDGE="NEG"` → FSM consumes `mem[its own state]` (fix
  proven, jumps included); `EDGE="POS"` → FSM consumes `mem[one-older state]` (hardware
  bug reproduced). / Icarus Verilog で機械証明済み。
- **M10K branch:** synthesized and **verified on silicon** (DE10-nano, Cyclone V
  5CSEBA6, 50 MHz, 2026-06-11): post-fix SignalTap shows the aligned address sequence
  with no overrun. ISMCE runtime modification confirmed working
  (`lpm_hint "ENABLE_RUNTIME_MOD=YES, INSTANCE_NAME=PTSG"` — instance name `PTSG` in
  the ISMCE tool). / 合成され**実機検証済み**。ISMCE のランタイム書換も動作確認済み。

## Consuming-side obligations / 利用側の義務

1. Drive `addr` from a register updated at posedge (the core's `state_num` qualifies).
2. Under `EDGE="NEG"`: nothing else — but treat the half-cycle path as a real timing
   constraint when raising the clock target.
3. Under `EDGE="POS"`: add the fetch stage; do not assume "addr now ⇒ instruction now."
4. Holding `addr` stable across a stall re-reads the same word (safe in both modes).

1. `addr` は posedge 更新のレジスタから駆動する(コアの `state_num` はこれを満たす)。
2. `EDGE="NEG"`: 他に義務なし——ただしクロック目標を上げる際は半サイクルパスを実在の
   タイミング制約として扱うこと。
3. `EDGE="POS"`: フェッチ段を追加する;「addr=今 ⇒ 命令=今」と仮定しない。
4. 停滞中の `addr` 保持は同じ語の再読みであり、両モードで安全。

---

> *The contract is not what the comment says. The contract is what `tb_align.v` checks,
> sampled the way the FSM samples.*
>
> *契約とはコメントが言うことではない。契約とは、FSM がサンプルするのと同じ方法で
> サンプルされ、`tb_align.v` が検査するものである。*

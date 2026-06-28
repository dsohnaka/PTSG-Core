# PTSG-Core — Layer 1 Specification
# Chapter 5: External Logic Interface
# PTSGコア — 第1層仕様書
# 第5章：外部ロジックインターフェース

> **License: CC0 1.0 Universal (Public Domain)**
> This chapter specifies the pin-level signal contracts for all PTSG-Core external interfaces: the clock and reset inputs, the Condition input, the timing-signal output bus, the State Number output, the external-operation bus, the external-stack bus, the insertion bus, the loop-counter and match-flag outputs, the indirect-read bus, and the prescaler interface. It revisits the timing-discipline Ties from Chapter 2 (C2-T3 glitch-free transitions, C2-T4 per-opcode clock latency) in their pin-level context, and consolidates the complete pin list into a single inventory.
>
> **ライセンス：CC0 1.0 Universal（パブリックドメイン）**
> 本章は、すべてのPTSGコア外部インターフェースのピンレベル信号契約を指定する: クロックとリセット入力、Condition 入力、タイミング信号出力バス、ステートナンバー出力、外部演算バス、外部スタックバス、挿入バス、ループカウンタと一致フラグ出力、間接読みバス、プリスケーラインターフェース。第2章のタイミング規律 Tie(C2-T3 グリッチフリー遷移、C2-T4 オペコード毎クロックレイテンシ)をピンレベル文脈で再訪し、完全なピンリストを単一のインベントリに統合する。

---

> ### Version Note — v1.0 (Deliberation-Stage Release) / バージョンノート — v1.0（協議段階リリース）
>
> **This is the v1.0 deliberation-stage release of Chapter 5.** It is drafted alongside Chapter 4 v1.0 at the architect's request, because the bus protocols sketched in Chapters 3 v1.1 and 4 v1.0 have made the pin-level details inferable to careful AI readers — to the point that they could begin HDL generation with assumed (and potentially divergent) defaults. Specifying these defaults now, as explicit Conventions or Ties, closes the inference gap.
>
> **これは第5章の v1.0 協議段階リリースである。** 第4章 v1.0 と並んで、アーキテクトの要請により起草された。第3章 v1.1 と第4章 v1.0 でスケッチされたバスプロトコルは、注意深い AI 読者にとってピンレベルの詳細を推論可能にした——彼らが仮定された(そして潜在的に分岐する)デフォルトで HDL 生成を始められるほどに。これらのデフォルトを今、明示的な Convention または Tie として指定することは、推論ギャップを閉じる。

---

## 5.1 Purpose of this Chapter / 本章の目的

The previous chapters specified what the Core *does* — its instruction set (Chapter 2), its dynamic mechanics (Chapter 3), its extension protocols (Chapter 4). This chapter specifies how the Core *connects to the world* — the wires that carry data into and out of the Core, the signaling conventions on each wire, the handshake timing, and the discipline by which an implementer must connect external Formation logic to a Core implementation.

前の章はコアが*何をするか*を指定した——その命令セット(第2章)、動的機構(第3章)、拡張プロトコル(第4章)。本章はコアが*世界にどう接続するか*を指定する——コアにデータを出し入れする配線、各配線上の信号化慣習、ハンドシェイクタイミング、そして実装者が外部 Formation ロジックをコア実装に接続しなければならない規律。

**Three principles guide this chapter:**

**三つの原則が本章を導く:**

1. **Minimum sufficient pin count.** Every signal on the Core's boundary serves a documented purpose; signals exist because they are needed by some Core mechanism, not because they might one day be useful. Optional outputs (e.g., the internal stay counter value) are clearly marked as such.
2. **Protocol over physical detail.** Where the Core specifies a bus, it commits to the *protocol* (which signals exist, what they mean, the handshake) but generally leaves *implementation details* (edge vs level, exact clock-cycle alignment, electrical conventions) to either Convention with alternatives recorded as Ties, or to Implementation Arena where the Core is genuinely silent.
3. **Formation-side flexibility.** A Formation may connect any subset of optional Core outputs and may add Formation-specific signals downstream. The Core's pin list is the *minimum* surface; the Formation extends from there.

1. **最小限十分なピン数。** コアの境界上のすべての信号は文書化された目的に奉仕する；信号は、いつか有用かもしれないからではなく、何らかのコア機構によって必要だから存在する。オプション出力(例: 内部ステイカウンタ値)はそのように明確に印付けられる。
2. **物理的詳細よりプロトコル。** コアがバスを指定する場合、*プロトコル*(どの信号が存在するか、それらが何を意味するか、ハンドシェイク)にコミットするが、一般的に*実装詳細*(エッジ対レベル、正確なクロックサイクル整列、電気的慣習)は、代替案が Tie として記録される Convention に、またはコアが真に沈黙する Implementation Arena に残す。
3. **Formation 側の柔軟性。** Formation はオプションのコア出力の任意の部分集合を接続でき、下流に Formation 固有の信号を追加できる。コアのピンリストは*最小*表面である；Formation はそこから拡張する。

**Chapter 5 v1.0 contains the following:**

**第5章 v1.0 は以下を含む:**

- A complete pin inventory (§ 5.2) — the canonical reference for every Core signal.
- Per-interface specifications (§§ 5.3–5.12) — clock/reset, Condition, timing signals, State Number, external buses (operation, stack, insertion), match flags, indirect-read, prescaler.
- Timing discipline (§ 5.13) — revisits C2-T3 and C2-T4 in pin-level context.
- The boundary section, open questions, and decisions table (§§ 5.14–5.16).

- 完全なピンインベントリ(§ 5.2) —— すべてのコア信号の正典的参照。
- インターフェース毎仕様(§§ 5.3-5.12) —— クロック／リセット、Condition、タイミング信号、ステートナンバー、外部バス(演算、スタック、挿入)、一致フラグ、間接読み、プリスケーラ。
- タイミング規律(§ 5.13) —— C2-T3 と C2-T4 をピンレベル文脈で再訪。
- 境界節、未解決問題、決定テーブル(§§ 5.14-5.16)。

---

## 5.2 Signal Inventory — The Complete Pin List / 信号インベントリ — 完全なピンリスト

This section is the canonical reference. Subsequent sections detail each group; this table is the index.

本節は正典的参照である。後続の節は各グループを詳述する；本テーブルはインデックスである。

**Mandatory pins (every Core implementation has these):**

**必須ピン(すべてのコア実装はこれらを持つ):**

| Signal | Direction | Width | Reference | Purpose summary |
|---|---|---|---|---|
| `clk` | input | 1 | § 5.3 | System clock / システムクロック |
| `rst` | input | 1 | § 5.3 | Reset (active-high default; polarity is Convention C5-V1) / リセット(既定はアクティブハイ；極性は Convention C5-V1) |
| `condition` | input | 1 | § 5.4 | Condition signal sampled by Branch / Branch が標本化する Condition 信号 |
| `state_number` | output | 12 | § 5.6 | Current State Number register value / 現在のステートナンバーレジスタ値 |
| `timing_signals` | output | 16 | § 5.5 | Timing-signal bus (D16–D31 of current instruction, with Stay-window hold semantics) / タイミング信号バス |

**External-operation bus (mandatory if any external sub-opcode is used):**

**外部演算バス(任意の外部サブオペコードが使われるなら必須):**

| Signal | Direction | Width | Reference |
|---|---|---|---|
| `ext_op_valid` | output | 1 | § 5.7 |
| `ext_op_subopcode` | output | 4 | § 5.7 |
| `ext_op_sub_operand` | output | 8 | § 5.7 |
| `ext_op_data` | output | 16 | § 5.7 |
| `ext_op_ready` | input | 1 | § 5.7 |

**External-stack bus (mandatory if nesting beyond 1 is needed):**

**外部スタックバス(深さ 1 を超える入れ子が必要なら必須):**

| Signal | Direction | Width | Reference |
|---|---|---|---|
| `stack_push_req` | output | 1 | § 5.8 |
| `stack_pop_req` | output | 1 | § 5.8 |
| `stack_data` | bidirectional | implementation-defined (typically 24–32) | § 5.8 |
| `stack_ack` | input | 1 | § 5.8 |

**Insertion bus (mandatory if external interrupts are used):**

**挿入バス(外部割り込みが使われるなら必須):**

| Signal | Direction | Width | Reference |
|---|---|---|---|
| `insert_req` | input | 1 | § 5.9 |
| `insert_target` | input | 12 | § 5.9 |
| `insert_ack` | output | 1 | § 5.9 |

**Loop-counter and match flags (loop_cnt_match mandatory if Loop is used; other outputs optional):**

**ループカウンタと一致フラグ(Loop が使われるなら loop_cnt_match 必須；他の出力はオプション):**

| Signal | Direction | Width | Reference | Optional? |
|---|---|---|---|---|
| `loop_counter` | output | 12 | § 5.10 | Optional (for Formation external-index use) / オプション |
| `loop_cnt_match` | output | 1 | § 5.10 | Mandatory if Loop is used / Loop が使われるなら必須 |
| `stay_counter` | output | 12 | § 5.10 | Optional / オプション |
| `stay_cnt_match` | output | 1 | § 5.10 | Optional / オプション |
| `prescaler_counter` | output | implementation-defined | § 5.10 | Optional / オプション |
| `prescaler_match` | output | 1 | § 5.10 | Optional / オプション |

**Indirect-read bus (mandatory if any indirect-mode opcode is used):**

**間接読みバス(任意の間接モードオペコードが使われるなら必須):**

| Signal | Direction | Width | Reference |
|---|---|---|---|
| `indirect_req` | output | 1 | § 5.11 |
| `indirect_purpose` | output | 2 | § 5.11 |
| `indirect_data` | input | 12 | § 5.11 |
| `indirect_ready` | input | 1 | § 5.11 |

**Prescaler interface (form depends on Tie C4-T2 resolution):**

**プリスケーラインターフェース(形は Tie C4-T2 解決に依存):**

| Signal | Direction | Width | Reference | Applies to |
|---|---|---|---|---|
| `prescaler_value` | input | implementation-defined (typically 16–32) | § 5.12 | Compile-time fixed (C4-T2 option A): wire input / 合成時固定(C4-T2 案 A): 配線入力 |
| (none externally; configured via external-register write) | — | — | § 5.12 | Runtime-configurable (C4-T2 option B) / 実行時設定可能(C4-T2 案 B) |
| `prescaler_select` | from instruction | 2+ | § 5.12 | Per-Stay-selectable (C4-T2 option C) / Stay 毎選択可能(C4-T2 案 C) |

**Pin count summary.** A minimal Core implementation (no external bus, no stack, no insertion, no Loop) has approximately **5 + 12 + 16 = 33 pins**. A typical configured Core implementation (with external bus, no stack, no insertion, with Loop and loop_cnt_match output, with compile-time-fixed prescaler) is on the order of **70–80 pins**. A fully-equipped Core implementation (with all optional outputs) is on the order of **120 pins**. These figures are illustrative; exact counts depend on the Tie resolutions and the implementation choices.

**ピン数まとめ。** 最小のコア実装(外部バスなし、スタックなし、挿入なし、Loop なし)は約 **5 + 12 + 16 = 33 ピン**を持つ。典型的に構成されたコア実装(外部バスあり、スタックなし、挿入なし、Loop と loop_cnt_match 出力あり、合成時固定プリスケーラあり)は **70-80 ピン**程度。完全装備のコア実装(すべてのオプション出力あり)は **120 ピン**程度。これらの数字は説明的である；正確な数は Tie 解決と実装選択に依存する。

---

## 5.3 Clock and Reset / クロックとリセット

**`clk` — system clock input.** A single-edge-triggered clock; rising edge is the active edge by convention (recorded as Convention C5-V2). All Core state — State Number register, stay/loop counters, holding register, internal control logic — is updated synchronously to the rising edge of `clk`. The Core itself is a single-clock-domain design; multi-clock-domain considerations belong at the Formation level (different external buses may operate on different clocks, with the Formation providing synchronizers).

**`clk` — システムクロック入力。** 単一エッジトリガクロック；立ち上がりエッジが慣習的にアクティブエッジである(Convention C5-V2 として記録)。コアのすべての状態——ステートナンバーレジスタ、ステイ／ループカウンタ、保持レジスタ、内部制御ロジック——は `clk` の立ち上がりエッジに同期的に更新される。コア自身は単一クロックドメイン設計である；複数クロックドメインの考慮は Formation レベルに属する(異なる外部バスは異なるクロックで動作し得て、Formation がシンクロナイザーを提供する)。

**`rst` — reset input.** When asserted, forces the Core into its reset state: State Number = 0, stay counter = 0, loop counter = 0, base address = 0, holding register cleared, timing-signal output = 0. The reset is synchronous by Convention (recorded as C5-V3): assertion of `rst` causes the reset effect on the next rising edge of `clk`. Asynchronous reset is an Implementation Arena alternative (some FPGA fabrics prefer it for global-reset distribution).

**`rst` — リセット入力。** アサートされると、コアをそのリセット状態に強制する: ステートナンバー = 0、ステイカウンタ = 0、ループカウンタ = 0、ベースアドレス = 0、保持レジスタクリア、タイミング信号出力 = 0。リセットは Convention により同期的(C5-V3 として記録): `rst` のアサートは `clk` の次の立ち上がりエッジでリセット効果を引き起こす。非同期リセットは Implementation Arena 代替案である(一部の FPGA ファブリックはグローバルリセット分配のためそれを好む)。

**Reset polarity.** Active-high is the contributor's lean (Convention C5-V1); active-low is an alternative many FPGA vendors prefer. Some HDL libraries assume one or the other. This is a Convention because the Core's behavior is identical regardless of polarity; only the wire-level connection differs.

**リセット極性。** アクティブハイが貢献者の傾向である(Convention C5-V1)；アクティブローは多くの FPGA ベンダーが好む代替案。一部の HDL ライブラリは一方または他方を仮定する。これは Convention である、なぜなら極性に関わらずコアの挙動は同じだから；配線レベルの接続だけが異なる。

**Power-on reset.** Whether the Core implementation includes a power-on reset (one that asserts `rst` automatically when the FPGA initializes) is an Implementation Arena topic. Some FPGAs reset all flip-flops to 0 on configuration, making an explicit power-on reset redundant; others do not. The Core specification is silent on this.

**パワーオンリセット。** コア実装がパワーオンリセット(FPGA 初期化時に `rst` を自動的にアサートするもの)を含むかどうかは Implementation Arena の話題である。一部の FPGA は構成時にすべてのフリップフロップを 0 にリセットし、明示的なパワーオンリセットを冗長にする；他はしない。コア仕様はこれについて沈黙する。

---

## 5.4 The Condition Input / Condition 入力

**`condition` — 1-bit Condition signal.** Externally driven; sampled by the Core when a Branch instruction is executed (Chapter 2 § 2.5). The Convention is to sample `condition` on the same rising clock edge that the Branch instruction is being executed at — i.e., the value of `condition` at the moment of the Branch determines whether the Branch is taken (Condition = false → Branch taken) or skipped (Condition = true → advance to current+1).

**`condition` — 1 ビット Condition 信号。** 外部駆動；Branch 命令が実行される時にコアによって標本化される(第2章 § 2.5)。慣習は、Branch 命令が実行されているのと同じ立ち上がりクロックエッジで `condition` を標本化する——つまり、Branch の瞬間の `condition` の値が Branch が取られる(Condition = false → Branch 取られる)かスキップされる(Condition = true → current+1 に進む)かを決定する。

**Glitch on `condition` — implementer's discipline.** The Core samples `condition` once per Branch encounter; the external logic must ensure that `condition` is stable (not glitching) during the relevant setup-and-hold window around the Branch's clock edge. If the external logic cannot guarantee this (e.g., `condition` is driven by an asynchronous external signal), the Formation must include synchronizer logic (typically a two-flip-flop synchronizer) before connecting to the Core's `condition` input. Recorded as **Fixed** C5-F1: synchronizer responsibility lies with the Formation, not the Core.

**`condition` のグリッチ ——実装者の規律。** コアは Branch 遭遇毎に `condition` を一度標本化する；外部ロジックは、Branch のクロックエッジ周辺の関連するセットアップとホールドのウィンドウ中に `condition` が安定している(グリッチしていない)ことを保証しなければならない。外部ロジックがこれを保証できない場合(例: `condition` が非同期の外部信号によって駆動される)、Formation はコアの `condition` 入力に接続する前にシンクロナイザーロジック(典型的には二段フリップフロップシンクロナイザー)を含めなければならない。**Fixed** C5-F1 として記録: シンクロナイザーの責任は Formation にあり、コアにはない。

**Multiple Condition sources.** The Core has a single `condition` input. A Formation requiring multiple conditions (e.g., "wait for either flag A or flag B") must combine them externally (e.g., via OR gate) before driving the single `condition` line. Multi-Condition variants are a Future Layer 2 trace topic; v1.0 commits to a single 1-bit input.

**複数の Condition ソース。** コアは単一の `condition` 入力を持つ。複数の条件を要求する Formation(例: 「フラグ A またはフラグ B を待つ」)は、単一の `condition` 線を駆動する前にそれらを外部で組み合わせなければならない(例: OR ゲート経由)。複数 Condition 変種は Future Layer 2 trace の話題である；v1.0 は単一 1 ビット入力にコミットする。

---

## 5.5 Timing Signals Output (D16–D31) / タイミング信号出力 (D16-D31)

**`timing_signals[15:0]` — 16-bit timing-signal bus.** Drives 16 parallel output bits. The Convention is:

**`timing_signals[15:0]` — 16 ビットタイミング信号バス。** 16 並列出力ビットを駆動する。慣習は:

- **During foreground Stay, Branch, Jump, NOP, or non-background Global instructions:** `timing_signals` reflects the D16–D31 field of the current instruction word, presented for the duration of that instruction (typically 1 clock for Branch/Jump/NOP/Global, or N clocks for a Stay of operand N — the Stay-hold semantics of C2-F3).
- **During the Stay window (between Stay Set and Stay-timeup, regardless of band):** `timing_signals` is held at the value determined by Tie C3-T1 (contributor lean: Stay state's D16–D31).
- **During an extended-operand-using Global (v1.1; Loop with target, Sub-sequence Call with offset, etc.) in foreground:** `timing_signals` is undefined for that 1 clock (because D16–D31 is being used as operand data, not timing data). Convention is that `timing_signals` retains its previous value for that 1 clock, but this is Convention C5-V4 with an alternative being "all-zeros during that clock."

- **前景 Stay、Branch、Jump、NOP、または非裏側 Global 命令中:** `timing_signals` は現在の命令語の D16-D31 フィールドを反映し、その命令の持続時間(Branch/Jump/NOP/Global に典型的に 1 クロック、または オペランド N の Stay に N クロック —— C2-F3 の Stay ホールド意味論)にわたって提示される。
- **Stay ウィンドウ中(Stay Set と Stay-timeup の間、帯域に関わらず):** `timing_signals` は Tie C3-T1 で決定された値に保持される(貢献者の傾向: Stay ステートの D16-D31)。
- **前景での拡張オペランド使用 Global 中(v1.1；目標付き Loop、オフセット付き Sub-sequence Call 等):** `timing_signals` はその 1 クロックの間未定義(D16-D31 はタイミングデータではなくオペランドデータとして使われるため)。慣習は `timing_signals` がその 1 クロックの間前の値を保持することだが、これは Convention C5-V4 で、代替案は「そのクロック中はオールゼロ」。

**Glitch-free transitions (C2-T3 in pin-level context).** Chapter 2 recorded as Tie C2-T3 whether timing-signal transitions between states are guaranteed glitch-free or merely implementation-defined. At the pin level, this depends on whether `timing_signals` is driven by combinational logic from the instruction-memory output (faster but potentially glitchy) or by a registered version (one clock of latency but glitch-free). The trade-off is fundamental and depends on the Formation's downstream-logic tolerance for transient glitches. Carried forward as Tie C5-T1 in § 5.16 — the pin-level expression of C2-T3.

**グリッチフリー遷移(ピンレベル文脈での C2-T3)。** 第2章は、ステート間のタイミング信号遷移がグリッチフリーを保証されるか単に実装定義かを Tie C2-T3 として記録した。ピンレベルで、これは `timing_signals` が命令メモリ出力からの組み合わせロジック(より速いが潜在的にグリッチ)によって駆動されるか、レジスタ付きバージョン(1 クロックのレイテンシだがグリッチフリー)によって駆動されるかに依存する。トレードオフは根本的で、Formation の下流ロジックの一時的グリッチに対する許容度に依存する。§ 5.16 で Tie C5-T1 として持ち越される —— C2-T3 のピンレベル表現。

---

## 5.6 State Number Output / ステートナンバー出力

**`state_number[11:0]` — 12-bit State Number output.** Reflects the current State Number register value. The Convention is that `state_number` is *registered* — i.e., it updates on the rising clock edge to reflect the state about to be executed. This means an external observer sees `state_number = N` during the clock period in which state N is the current state. Recorded as Convention C5-V5.

**`state_number[11:0]` — 12 ビットステートナンバー出力。** 現在のステートナンバーレジスタ値を反映する。慣習は `state_number` が*レジスタ付き*であること——つまり、立ち上がりクロックエッジで実行されようとしているステートを反映するよう更新される。これは、外部観察者がステート N が現在のステートであるクロック期間中に `state_number = N` を見ることを意味する。Convention C5-V5 として記録。

**Combinational alternative.** An implementation might drive `state_number` combinationally from the state-number register's input rather than its output, allowing external logic to react one clock earlier. The trade-off is timing closure complexity vs reduced latency. Recorded as Implementation Arena alternative.

**組み合わせ的代替案。** 実装は、`state_number` をステートナンバーレジスタの出力ではなく入力から組み合わせ的に駆動でき、外部ロジックが 1 クロック早く反応することを許す。トレードオフはタイミングクロージャ複雑性対レイテンシ削減である。Implementation Arena 代替案として記録。

**State Number during reset.** When `rst` is asserted, `state_number` becomes 0 on the next clock edge (synchronous reset). The Core then begins executing instruction 0 on the following clock.

**リセット中のステートナンバー。** `rst` がアサートされると、`state_number` は次のクロックエッジで 0 になる(同期リセット)。コアはその後、次のクロックで命令 0 の実行を開始する。

---

## 5.7 The External-Operation Bus / 外部演算バス

This bus was introduced in Chapter 3 § 3.5. Here it is specified at the pin level.

このバスは第3章 § 3.5 で導入された。ここではピンレベルで指定される。

**`ext_op_valid` — 1-bit edge / pulse.** Asserted for **exactly one clock** when the Core encounters an external-mode Global instruction (D4–D7 = 1–F). Sampled by external logic on the rising clock edge. After the clock, the Core continues to the next instruction; `ext_op_valid` returns to 0.

**`ext_op_valid` — 1 ビットエッジ／パルス。** コアが外部モード Global 命令(D4-D7 = 1-F)に遭遇する時、**ちょうど 1 クロック**アサートされる。立ち上がりクロックエッジで外部ロジックが標本化する。クロックの後、コアは次の命令に進む；`ext_op_valid` は 0 に戻る。

**`ext_op_subopcode[3:0]`, `ext_op_sub_operand[7:0]`, `ext_op_data[15:0]` — combinational with `ext_op_valid`.** When `ext_op_valid` is high, these three signals carry the operand fields from the current Global instruction. They are guaranteed stable for the duration of the `ext_op_valid` high clock. After that clock, these signals may change (they reflect the next instruction's contents, which are typically irrelevant — external logic should capture the values when `ext_op_valid` is high).

**`ext_op_subopcode[3:0]`、`ext_op_sub_operand[7:0]`、`ext_op_data[15:0]` —— `ext_op_valid` と組み合わせ的。** `ext_op_valid` がハイの時、これら三つの信号は現在の Global 命令からのオペランドフィールドを運ぶ。それらは `ext_op_valid` ハイクロックの持続時間中安定であることが保証される。そのクロックの後、これらの信号は変化し得る(次の命令の内容を反映する、典型的に無関係 —— 外部ロジックは `ext_op_valid` がハイの時に値を捕捉すべきである)。

**`ext_op_ready` — 1-bit level / pulse.** Driven by external logic. Asserted when the external operation completes. The Core uses this primarily for the minimum-stay-count constraint (Chapter 3 v1.1 § 3.6): if Stay-timeup arrives before `ext_op_ready` has been received for a pending external operation, a minimum-stay-count violation has occurred. The semantics of `ext_op_ready` are:

**`ext_op_ready` — 1 ビットレベル／パルス。** 外部ロジックによって駆動される。外部演算が完了する時にアサートされる。コアはこれを主に最低ステイカウント制約のために使う(第3章 v1.1 § 3.6): Stay-timeup が、保留中の外部演算に対する `ext_op_ready` が受信される前に到来すれば、最低ステイカウント違反が起きている。`ext_op_ready` の意味論:

- **(A) Level (Convention C5-V6, contributor lean):** `ext_op_ready` is held high by external logic for as long as the operation is *complete and stable* (i.e., the external operation's effects can be relied upon). Asserted no earlier than the clock following `ext_op_valid`; deasserted when external logic is ready for a new operation. Pros: clear "is the operation done" status. Cons: external logic must maintain the level.
- **(B) Pulse (alternative):** `ext_op_ready` is a 1-clock pulse asserted at the completion clock; the Core must capture the pulse. Pros: external logic simpler. Cons: timing-critical capture.

- **(A) レベル(Convention C5-V6、貢献者の傾向):** `ext_op_ready` は、演算が*完了し安定している*限り(つまり、外部演算の効果が頼りにできる限り)外部ロジックによってハイに保持される。`ext_op_valid` の次のクロック以降にアサートされる；外部ロジックが新しい演算の準備ができたら deassert される。利点: 明確な「演算は完了したか」ステータス。欠点: 外部ロジックがレベルを維持しなければならない。
- **(B) パルス(代替案):** `ext_op_ready` は完了クロックでアサートされる 1 クロックパルス；コアはパルスを捕捉しなければならない。利点: 外部ロジックがより単純。欠点: タイミング重要な捕捉。

---

## 5.8 The External-Stack Bus / 外部スタックバス

Introduced in Chapter 3 § 3.8.

第3章 § 3.8 で導入。

**`stack_push_req`, `stack_pop_req` — 1-bit pulses.** Each asserted for exactly one clock when the Core needs to push or pop, respectively. They are mutually exclusive — both are never asserted in the same clock.

**`stack_push_req`、`stack_pop_req` — 1 ビットパルス。** それぞれ、コアがプッシュまたはポップする必要がある時、ちょうど 1 クロックアサートされる。それらは相互排他的である ——両方が同じクロックでアサートされることは決してない。

**`stack_data` — bidirectional, implementation-defined width.** During a push: the Core drives `stack_data` with the holding-register contents to be saved; external logic captures it. During a pop: external logic drives `stack_data` with the popped contents; the Core captures it. The width depends on the holding-register data layout (Chapter 3 v1.1 § 3.7), which depends on Tie C3-T7 (insertion flag bit). Typical width 24–32 bits: 12 (State Number) + 12 (loop counter) + a few flag bits.

**`stack_data` — 双方向、実装定義の幅。** プッシュ中: コアは保存される保持レジスタ内容で `stack_data` を駆動する；外部ロジックがそれを捕捉する。ポップ中: 外部ロジックがポップされた内容で `stack_data` を駆動する；コアがそれを捕捉する。幅は保持レジスタデータレイアウト(第3章 v1.1 § 3.7)に依存し、それは Tie C3-T7(挿入フラグビット)に依存する。典型的な幅 24-32 ビット: 12(ステートナンバー) + 12(ループカウンタ) + 数個のフラグビット。

**`stack_ack` — 1-bit pulse.** Asserted by external logic for one clock when the push or pop operation has completed. Until `stack_ack` is asserted, the Core stalls. This is option (C) variable timing from Chapter 4 § 4.5 applied to the stack bus; it is the contributor's lean (Fixed C5-F2) because external stack memory may be slower than a single clock cycle (e.g., implemented in BRAM with registered output).

**`stack_ack` — 1 ビットパルス。** プッシュまたはポップ演算が完了した時、外部ロジックによって 1 クロックアサートされる。`stack_ack` がアサートされるまで、コアは停滞する。これは第4章 § 4.5 から、スタックバスに適用された案 (C) 可変タイミングである；外部スタックメモリは単一クロックサイクルより遅い場合があるため(例: レジスタ付き出力で BRAM 実装)、貢献者の傾向(**Fixed** C5-F2)である。

---

## 5.9 The Insertion Bus / 挿入バス

Introduced in Chapter 3 § 3.10. Tie C3-T8 was resolved in v1.1 as (B) deferred-to-Stay-timeup, now C3-F20.

第3章 § 3.10 で導入。Tie C3-T8 は v1.1 で (B) Stay-timeup 繰り延べとして解決された、今は C3-F20。

**`insert_req` — 1-bit level.** Asserted by external logic to request an insertion. The Core captures `insert_req` and `insert_target` at the safe moment per C3-F20 — i.e., at Stay-timeup if currently in a Stay window, or between instructions if not. External logic should hold `insert_req` asserted until `insert_ack` is received; deasserting it earlier may lose the insertion request.

**`insert_req` — 1 ビットレベル。** 挿入を要求するため外部ロジックによってアサートされる。コアは C3-F20 に従って安全な瞬間に `insert_req` と `insert_target` を捕捉する——つまり、現在 Stay ウィンドウ内なら Stay-timeup で、そうでなければ命令間で。外部ロジックは `insert_ack` を受信するまで `insert_req` をアサートしたままにすべきである；早く deassert すると挿入要求を失う可能性がある。

**`insert_target[11:0]` — 12 bits.** The State Number to which the Core will jump on accepting the insertion. Must be stable while `insert_req` is held high.

**`insert_target[11:0]` — 12 ビット。** 挿入を受け入れるとコアがジャンプする先のステートナンバー。`insert_req` がハイに保持されている間、安定でなければならない。

**`insert_ack` — 1-bit pulse.** Asserted by the Core for one clock when the insertion has been accepted (auto-save complete, State Number set to `insert_target`). External logic should deassert `insert_req` no earlier than the clock in which it sees `insert_ack`.

**`insert_ack` — 1 ビットパルス。** 挿入が受け入れられた時(自動退避完了、ステートナンバーが `insert_target` に設定)、コアによって 1 クロックアサートされる。外部ロジックは、`insert_ack` を見るクロック以前に `insert_req` を deassert すべきではない。

**Insertion during a Stay window — timing detail.** Per C3-F20, the insertion is deferred to Stay-timeup. So if `insert_req` is asserted in the middle of a long Stay (e.g., a 1-second wait), the Core continues the Stay normally; `insert_ack` is not asserted until the Stay completes. The external logic must be prepared to hold `insert_req` for potentially long durations.

**Stay ウィンドウ中の挿入 ——タイミング詳細。** C3-F20 により、挿入は Stay-timeup に繰り延べられる。したがって `insert_req` が長い Stay(例: 1 秒の待機)の真ん中でアサートされると、コアは Stay を通常通り継続する；`insert_ack` は Stay が完了するまでアサートされない。外部ロジックは `insert_req` を潜在的に長い持続時間保持する準備ができていなければならない。

**Urgent-insertion alternative.** A future revision may introduce an `insert_urgent` signal that bypasses the Stay-timeup deferral (option (A) or (C) from former C3-T8 alternatives). This is a Future Layer 2 trace topic if and when a Formation requires real-time preemption.

**緊急挿入代替案。** 将来の改訂は、Stay-timeup 繰り延べを迂回する `insert_urgent` 信号を導入し得る(旧 C3-T8 代替案からの案 (A) または (C))。これは、Formation がリアルタイム先取を要求する場合の Future Layer 2 trace の話題である。

---

## 5.10 Loop Counter and Match Flag Outputs / ループカウンタと一致フラグ出力

The v1.1 deliberation established (C3-F14, C3-F18) that the loop counter and match flags are externally observable outputs.

v1.1 協議は(C3-F14、C3-F18)、ループカウンタと一致フラグが外部観察可能な出力であることを確立した。

**`loop_counter[11:0]` — 12-bit, optional output.** Reflects the current value of the single primary loop counter (v1.1 single-counter model, C3-F16). Continuously observable. After auto-clear on loop exit (C3-F17), this output reads 0. A Formation that uses the loop counter as an external index (RAM address, coefficient ROM address, etc.) connects this signal; otherwise it may be left unconnected at the Formation level.

**`loop_counter[11:0]` — 12 ビット、オプション出力。** 単一プライマリループカウンタ(v1.1 単一カウンタモデル、C3-F16)の現在値を反映する。連続的に観察可能。ループ脱出時の自動クリア(C3-F17)後、この出力は 0 と読まれる。ループカウンタを外部インデックス(RAM アドレス、係数 ROM アドレス等)として使う Formation はこの信号を接続する；そうでなければ Formation レベルで未接続のまま残し得る。

**`loop_cnt_match` — 1-bit pulse, mandatory if Loop is used.** Asserted for **exactly one clock** at the moment the loop counter reaches the target value (i.e., on the loop's exit clock). This is the primary mechanism by which Formation-side external counters or other logic synchronize with the Core's loop iteration boundaries. Per C3-F18.

**`loop_cnt_match` — 1 ビットパルス、Loop が使われるなら必須。** ループカウンタが目標値に達する瞬間(つまり、ループの脱出クロック)に**ちょうど 1 クロック**アサートされる。これは、Formation 側の外部カウンタや他のロジックがコアのループ反復境界と同期する主要な機構である。C3-F18 による。

**`stay_counter[11:0]`, `stay_cnt_match` — optional outputs.** Symmetric to `loop_counter` / `loop_cnt_match` but for the Stay counter. `stay_counter` reflects the current stay-counter value (ticking at prescaler rate per C4-F1/F2); `stay_cnt_match` pulses at Stay-timeup. The match-flag timing is governed by C4-F11 (was Tie C4-T3): the pulse is at the **trailing edge** of the prescale period (Trailing-Edge Doctrine, Chapter 1 § 1.4a).

**`stay_counter[11:0]`、`stay_cnt_match` —— オプション出力。** `loop_counter` / `loop_cnt_match` と対称だが Stay カウンタについて。`stay_counter` は現在のステイカウンタ値(C4-F1/F2 に従いプリスケーラレートでティックする)を反映する；`stay_cnt_match` は Stay-timeup でパルスする。一致フラグタイミングは C4-F11（旧 Tie C4-T3）によって支配される —— パルスはプリスケール周期の**後縁**（後縁主義、第1章 § 1.4a）。

**`prescaler_counter`, `prescaler_match` — optional outputs.** Symmetric again. `prescaler_counter` width depends on prescaler configuration (Tie C4-T2): for (A) compile-time fixed, the width matches the chosen prescaler value's bit-width; for (B) runtime-configurable, it matches the prescaler-register width. `prescaler_match` pulses at every prescaler period boundary.

**`prescaler_counter`、`prescaler_match` —— オプション出力。** 再び対称。`prescaler_counter` 幅はプリスケーラ構成(Tie C4-T2)に依存する: (A) 合成時固定では、幅は選ばれたプリスケーラ値のビット幅と一致する；(B) 実行時設定可能では、プリスケーラレジスタ幅と一致する。`prescaler_match` はすべてのプリスケーラ周期境界でパルスする。

**Naming conventions and Formation-side use.** The match flags follow a `<name>_cnt_match` naming Convention (recorded as C5-V7). Formations are encouraged to follow the same pattern for their derived signals (e.g., a Formation-internal counter incremented by `loop_cnt_match` might be named `outer_loop_cnt` with its own `outer_loop_cnt_match`).

**命名慣習と Formation 側使用。** 一致フラグは `<name>_cnt_match` 命名慣習に従う(C5-V7 として記録)。Formation はそれらの派生信号にも同じパターンに従うことが推奨される(例: `loop_cnt_match` でインクリメントされる Formation 内部カウンタは、それ自身の `outer_loop_cnt_match` を持つ `outer_loop_cnt` と命名され得る)。

---

## 5.11 The Indirect-Read Bus / 間接読みバス

Introduced in Chapter 4 § 4.5 at the protocol level. Pin-level details follow.

第4章 § 4.5 でプロトコルレベルで導入。ピンレベル詳細は以下。

**`indirect_req` — 1-bit pulse.** Asserted by the Core for exactly one clock when an indirect-mode opcode is encountered (Jump operand 0, or Loop with D16–D31 = 0).

**`indirect_req` — 1 ビットパルス。** 間接モードオペコードに遭遇する時(Jump オペランド 0、または D16-D31 = 0 の Loop)、コアによってちょうど 1 クロックアサートされる。

**`indirect_purpose[1:0]` — 2-bit code, combinational with `indirect_req`.** Encoded as: `00` = indirect Jump target, `01` = indirect Loop count target, `10` and `11` = reserved.

**`indirect_purpose[1:0]` — 2 ビットコード、`indirect_req` と組み合わせ的。** エンコード: `00` = 間接 Jump ターゲット、`01` = 間接 Loop カウントターゲット、`10` と `11` = 予約。

**`indirect_data[11:0]` — 12-bit input.** Driven by external logic. Captured by the Core per the handshake timing of Tie C4-T1.

**`indirect_data[11:0]` — 12 ビット入力。** 外部ロジックによって駆動される。Tie C4-T1 のハンドシェイクタイミングに従いコアによって捕捉される。

**`indirect_ready` — 1-bit pulse / level.** Asserted by external logic when `indirect_data` is valid. Pulse vs level depends on Tie C4-T1 resolution. Under the contributor's lean (option B, registered/one-clock), `indirect_ready` is a 1-clock pulse asserted on the clock following `indirect_req`.

**`indirect_ready` — 1 ビットパルス／レベル。** `indirect_data` が有効な時、外部ロジックによってアサートされる。パルス対レベルは Tie C4-T1 解決に依存する。貢献者の傾向の下(案 B、レジスタ付き／1 クロック)、`indirect_ready` は `indirect_req` の次のクロックでアサートされる 1 クロックパルスである。

---

## 5.12 The Prescaler Interface / プリスケーラインターフェース

The pin-level form depends on Tie C4-T2 (prescaler configuration). Each option implies a different external surface.

> **v1.1 — Free-running, program-untouchable (C4-F9 / C3-F21).** Whatever C4-T2 form is chosen, the prescaler is a **free-running time-base**: its counter is reset only by the global hardware reset, never on wait entry, and **never by the program-issued Reset command** (C3-F21, provisional). The pin-level interface must therefore expose no path by which a running program can reset or perturb the prescaler. This is what allows a PTSG to be driven as an externally-synchronized **slave**: a slave has no influence over its time-base. (A Formation that deliberately opts in to a prescaler-resetting Reset, C3-V4, is a standalone, non-slave configuration.)
>
> **Forthcoming (Chapter 6 / Build Log #9):** the externalization of a **raw (pre-register) prescaler tick** so that one PTSG can supply the tick to others, making **master/slave synchronization** possible, and the one-clock-registered tick that improves Fmax. These are consequences of accepting the free-running prescaler and are reserved for the multi-PTSG coordination chapter.
>
> **v1.1 —— 自由走行・プログラムから不可触（C4-F9 / C3-F21）。** C4-T2 のいずれの形を選んでも、プリスケーラは**自由走行の時間基準**である: そのカウンタはグローバルハードウェアリセットでのみリセットされ、待機突入では決して、**プログラム発行の Reset コマンドでも決して**リセットされない（C3-F21、仮確定）。ゆえにピンレベルインターフェースは、走行中のプログラムがプリスケーラをリセットまたは擾乱できる経路を露出してはならない。これが PTSG を外部同期される**スレーブ**として駆動可能にするものである: スレーブは自身の時間基準に影響を持たない。（プリスケーラをリセットする Reset を意図的に選択する Formation（C3-V4）は、単独・非スレーブ構成である。）
>
> **近刊（第6章 / Build Log #9）:** 一つの PTSG が他へティックを供給し**マスター／スレーブ同期**を可能にする**生（レジスタ前）プリスケーラ・ティック**の外部化、および Fmax を改善する 1 クロック叩きティック。これらは自由走行プリスケーラ受容の帰結であり、複数 PTSG 協調の章に留保される。

ピンレベル形式は Tie C4-T2(プリスケーラ構成)に依存する。各案は異なる外部表面を含意する。

**Option (A) — Compile-time fixed.** The prescaler value is a synthesis-time parameter, not exposed at the pin level. The Core implementation has a parameter (e.g., a Verilog `parameter PRESCALER = 1` or a VHDL `generic`); the Formation sets it when instantiating the Core. No additional pins.

**案 (A) ——合成時固定。** プリスケーラ値は合成時パラメータであり、ピンレベルで露出されない。コア実装にはパラメータ(例: Verilog の `parameter PRESCALER = 1` または VHDL の `generic`)があり；Formation がコアをインスタンス化する時にそれを設定する。追加のピンなし。

**Option (B) — Runtime-configurable.** The prescaler value is a Core-internal register, updated via the external-operation bus (sub-opcode and sub-operand identifying the prescaler-register address). No new pins, but the external-operation bus is mandatory and one sub-opcode/sub-operand combination is reserved for prescaler-register writes. The exact reservation (which sub-opcode, which sub-operand value) is a Formation-level convention.

**案 (B) ——実行時設定可能。** プリスケーラ値はコア内部レジスタで、外部演算バス(プリスケーラレジスタアドレスを識別するサブオペコードとサブオペランド)経由で更新される。新しいピンはないが、外部演算バスは必須で、一つのサブオペコード／サブオペランドの組み合わせがプリスケーラレジスタ書き込みに予約される。正確な予約(どのサブオペコード、どのサブオペランド値)は Formation レベルの慣習。

**Option (C) — Per-Stay-selectable.** A new field in the Stay instruction (or in a closely-associated reserved bit-field) selects among N pre-configured prescaler values. The N prescaler values are themselves either compile-time fixed or runtime-configurable. Pin-level: same as (A) or (B) plus a `prescaler_select` signal carrying log2(N) bits from the instruction decoder to the prescaler bank.

**案 (C) —— Stay 毎選択可能。** Stay 命令の(または密接に関連する予約ビットフィールドの)新しいフィールドが、N 個の事前設定されたプリスケーラ値の中から選択する。N 個のプリスケーラ値自身は合成時固定または実行時設定可能のいずれか。ピンレベル: (A) または (B) と同じに加え、命令デコーダーからプリスケーラバンクへ log2(N) ビットを運ぶ `prescaler_select` 信号。

**Option (D) — Multiple-parallel.** Same as (C) at the pin level but with N independently-running prescaler counters in the Core, each with its own `prescaler_<i>_counter` and `prescaler_<i>_match` outputs.

**案 (D) ——複数並列。** ピンレベルでは (C) と同じだが、コアに N 個の独立して走るプリスケーラカウンタがあり、それぞれが自身の `prescaler_<i>_counter` と `prescaler_<i>_match` 出力を持つ。

The pin-level surface is therefore **Tie-resolution-dependent**. The Core specification cannot commit to a single pin layout until C4-T2 is resolved. For implementation purposes, Layer 3 reference designs may pick one option and document the choice.

ピンレベル表面はしたがって **Tie 解決依存**である。コア仕様は C4-T2 が解決されるまで単一のピンレイアウトにコミットできない。実装目的では、Layer 3 リファレンス設計が一つの案を選び、選択を文書化し得る。

---

## 5.13 Timing Considerations and Pipelining / タイミング考慮とパイプライニング

This section revisits C2-T3 (glitch-free timing-signal transitions) and C2-T4 (per-opcode clock latency) in their pin-level context, and adds new pin-level Ties surfaced during this chapter's drafting.

本節は C2-T3(グリッチフリータイミング信号遷移)と C2-T4(オペコード毎クロックレイテンシ)をピンレベル文脈で再訪し、本章の起草中に表面化した新しいピンレベル Tie を追加する。

**Per-opcode clock latency (C2-T4 at the pin level).** The Convention is that each opcode takes exactly 1 system clock (except Stay, which waits N prescaled clocks, and indirect-mode opcodes which may add 1 clock per Tie C4-T1 resolution B). A Core implementation may, for high-frequency operation, pipeline the instruction-fetch and decode stages, introducing additional latency. The trade-off is fundamental: lower latency means simpler reasoning for instruction-list authors and tighter timing-coupled bus protocols; pipelining means higher achievable clock frequency. Whether C2-T4 is resolved as 1-clock-required or as Implementation Arena remains an open Tie.

**オペコード毎クロックレイテンシ(ピンレベルでの C2-T4)。** 慣習は、各オペコードがちょうど 1 システムクロックを取ること(N プリスケーラクロック待つ Stay、および Tie C4-T1 解決 B により 1 クロックを加え得る間接モードオペコードを除く)。コア実装は、高周波数動作のため、命令フェッチとデコード段をパイプライン化し、追加のレイテンシを導入し得る。トレードオフは根本的: 低いレイテンシは命令リスト作者にとってより単純な推論とより厳密なタイミング結合バスプロトコルを意味する；パイプライニングはより高い達成可能なクロック周波数を意味する。C2-T4 が 1 クロック要求として解決されるか Implementation Arena として解決されるかは未解決の Tie のままである。

**Bus signal alignment.** The Convention is that all bus signals are aligned to the same clock edge — specifically, the rising edge of `clk` (C5-V2). Synchronous-bus interpretation: at every rising edge of `clk`, the value of every bus signal is the value that should be sampled for that clock period. This Convention simplifies external logic design but does not preclude Formation-side derived signals being synchronized differently.

**バス信号整列。** 慣習は、すべてのバス信号が同じクロックエッジに整列されること——具体的に、`clk` の立ち上がりエッジ(C5-V2)。同期バス解釈: `clk` のすべての立ち上がりエッジで、すべてのバス信号の値は、そのクロック期間に標本化されるべき値である。この慣習は外部ロジック設計を単純化するが、Formation 側の派生信号が異なって同期されることを排除しない。

**Glitch-free transitions revisited (C2-T3 / C5-T1).** As mentioned in § 5.5, whether `timing_signals` transitions glitch-free between states depends on whether the implementation registers the output. The same question applies to `state_number`. The Core specification leaves this as **Tie C5-T1**: option (A) guaranteed glitch-free (one clock of latency, additional register cost) vs option (B) implementation-arena (the implementation chooses; downstream logic must tolerate possible glitches).

**グリッチフリー遷移の再訪(C2-T3 / C5-T1)。** § 5.5 で言及したように、`timing_signals` がステート間でグリッチフリーに遷移するかどうかは、実装が出力をレジスタするかどうかに依存する。同じ問いが `state_number` にも適用される。コア仕様はこれを **Tie C5-T1** として残す: 案 (A) 保証されたグリッチフリー(1 クロックのレイテンシ、追加のレジスタコスト)対 案 (B) 実装アリーナ(実装が選ぶ；下流ロジックは可能なグリッチを許容しなければならない)。

**Setup and hold conventions.** The Core specification follows standard synchronous-design conventions: every input signal must be stable at the clock-edge sample point with implementation-specified setup and hold margins. Specific timing budgets (e.g., "external logic must drive `condition` no later than 2 ns before the rising edge of `clk`") are Implementation Arena and depend on the FPGA fabric, the synthesis target frequency, and the place-and-route results. Layer 3 reference implementations should document their setup/hold requirements.

**セットアップとホールド慣習。** コア仕様は標準的な同期設計慣習に従う: すべての入力信号は、実装が指定するセットアップとホールドのマージンを持って、クロックエッジサンプル点で安定でなければならない。具体的なタイミング予算(例: 「外部ロジックは `clk` の立ち上がりエッジの 2 ns 以上前に `condition` を駆動しなければならない」)は Implementation Arena で、FPGA ファブリック、合成目標周波数、配置配線結果に依存する。Layer 3 リファレンス実装はそれらのセットアップ／ホールド要件を文書化すべきである。

---

## 5.14 What is NOT in this Chapter / 本章に含まれないもの

To make the boundary unambiguous:

境界を曖昧でなくするために:

- **Electrical characteristics.** Drive strength, voltage levels, transition times — these are FPGA-fabric and tool-flow specific, addressed (if at all) in Layer 3 implementation documentation. / **電気特性。** 駆動強度、電圧レベル、遷移時間 ——これらは FPGA ファブリックとツールフロー固有で、Layer 3 実装文書で(もし扱われるなら)扱われる。
- **Specific Formation pin assignments.** Each Formation may rename Core signals (e.g., `condition` → `wpms_sample_ready`), add Formation-specific signals, and arrange pins for board-level routing. Layer 1 specifies the Core's logical interface; Formation Layer 1 specifies the physical Formation-level interface. / **特定の Formation ピン割り当て。** 各 Formation はコア信号を改名でき(例: `condition` → `wpms_sample_ready`)、Formation 固有の信号を追加し、ボードレベルルーティングのためにピンを配置できる。Layer 1 はコアの論理インターフェースを指定する；Formation Layer 1 は物理 Formation レベルインターフェースを指定する。
- **Multi-PTSG inter-Core signaling.** When multiple PTSG Cores coexist, signals connecting them (one Core's `state_number` driving another Core's `condition`, for example) are not Layer 1 material — Future Chapter 6 territory. / **複数 PTSG コア間信号化。** 複数の PTSG コアが共存する時、それらを接続する信号(例: 一つのコアの `state_number` が別のコアの `condition` を駆動する)は Layer 1 素材ではない —— 将来の第6章領域。
- **HDL implementations.** Verilog and VHDL module declarations realizing the signals specified here are Layer 3 material (`03_Sample_Implementations/`). The signal *names* used in this chapter are Convention; specific implementations may use port-name variations (e.g., snake_case vs camelCase) per their HDL style guide. / **HDL 実装。** ここで指定された信号を実現する Verilog と VHDL モジュール宣言は Layer 3 素材(`03_Sample_Implementations/`)。本章で使われる信号*名*は Convention である；特定の実装は HDL スタイルガイドに従いポート名のバリエーション(例: snake_case 対 camelCase)を使い得る。
- **Test and debug pins.** A real implementation may expose additional pins for testbench observation (e.g., a `debug_trace_valid` signal). These are Layer 3 concerns and need not be in the Core's logical pin list. / **テストとデバッグピン。** 実際の実装はテストベンチ観察のための追加ピン(例: `debug_trace_valid` 信号)を露出し得る。これらは Layer 3 の関心事で、コアの論理ピンリストにある必要はない。

---

## 5.15 Open Questions Carried Forward / 後続章へ持ち越される未解決問題

| Question | Deferred to |
|---|---|
| Whether glitch-free `timing_signals` should be promoted from Tie to Fixed (some Formations may require it) / グリッチフリーな `timing_signals` が Tie から Fixed に格上げされるべきかどうか(一部の Formation はそれを要求し得る) | Community input → potential v1.1 |
| Whether `ext_op_ready` should be level (current Convention) or pulse — depends on Formation-side preference / `ext_op_ready` がレベル(現慣習)かパルスか — Formation 側の好みに依存 | Community input |
| Whether the holding-register width Tie C3-T7 (insertion flag bit) should be promoted to a Fixed default to simplify `stack_data` width / 保持レジスタ幅 Tie C3-T7(挿入フラグビット)が `stack_data` 幅を単純化するために Fixed 既定に格上げされるべきかどうか | Community input + potential Chapter 3 revision |
| Whether `insert_urgent` (real-time preemption) should be added — depends on Formation needs / `insert_urgent`(リアルタイム先取)が追加されるべきかどうか —— Formation の必要に依存 | Future Layer 2 trace |
| Multi-clock-domain considerations: signals connecting different-clock external logic (e.g., a slow SPI peripheral) — synchronizer responsibility / 複数クロックドメイン考慮: 異なるクロック外部ロジックを接続する信号(例: 遅い SPI ペリフェラル) —— シンクロナイザー責任 | Layer 3 implementation guidance |
| Whether per-opcode clock latency (C2-T4) is resolved as 1-clock-required or Implementation Arena / オペコード毎クロックレイテンシ(C2-T4)が 1 クロック要求として解決されるか Implementation Arena として解決されるか | Community input + Layer 3 implementation |
| Bus-protocol verification / formal-equivalence-checking against the Core specification / コア仕様に対するバスプロトコル検証／形式的等価性検査 | Future Layer 2 trace |

---

## 5.16 Summary of Chapter 5 Decisions / 第5章決定事項のまとめ

Following the established classification: **Fixed (F)** = architectural commitments; **Convention (V)** = current conventions that could in principle be reconsidered; **Tie (T)** = genuinely open for community input.

確立された分類に従う: **Fixed (F)** = アーキテクチャ的コミットメント；**Convention (V)** = 原則として再考可能な現在の慣習；**Tie (T)** = 真にコミュニティ入力に開かれている。

| ID | Decision | Status |
|---|---|---|
| **C5-F1** | Synchronizer responsibility for asynchronous external signals (e.g., `condition` driven by an off-clock source) lies with the Formation, not the Core / 非同期外部信号(例: オフクロックソースによって駆動される `condition`)に対するシンクロナイザー責任は、コアではなく Formation にある | **F** |
| **C5-F2** | External-stack bus uses variable-clock handshake (option C from § 4.5 alternatives): Core stalls until `stack_ack` is asserted, accommodating BRAM-backed stack implementations / 外部スタックバスは可変クロックハンドシェイクを使う(§ 4.5 代替案の案 C): コアは `stack_ack` がアサートされるまで停滞し、BRAM 裏のスタック実装を収容する | **F** |
| **C5-V1** | Reset polarity: active-high default / リセット極性: 既定はアクティブハイ | **V** |
| **C5-V2** | Clock edge: rising-edge-triggered default / クロックエッジ: 既定は立ち上がりエッジトリガ | **V** |
| **C5-V3** | Reset is synchronous by default (asynchronous reset is an Implementation Arena alternative) / リセットは既定で同期(非同期リセットは Implementation Arena 代替案) | **V** |
| **C5-V4** | During an extended-operand-using foreground Global, `timing_signals` retains its previous value for that 1 clock (alternative: all-zeros that clock) / 前景での拡張オペランド使用 Global 中、`timing_signals` はその 1 クロックの間前の値を保持する(代替案: そのクロックはオールゼロ) | **V** |
| **C5-V5** | `state_number` is registered (updates on the rising clock edge to reflect the state about to be executed) / `state_number` はレジスタ付き(立ち上がりクロックエッジで実行されようとしているステートを反映するよう更新) | **V** |
| **C5-V6** | `ext_op_ready` is level-driven (held high while external operation is complete and stable) / `ext_op_ready` はレベル駆動(外部演算が完了し安定している間ハイに保持) | **V** |
| **C5-V7** | Match-flag naming Convention: `<name>_cnt_match` (loop_cnt_match, stay_cnt_match, prescaler_match) / 一致フラグ命名慣習: `<name>_cnt_match` | **V** |
| **C5-T1** | Glitch-free timing-signal and state-number transitions Tie (pin-level expression of C2-T3): (A) guaranteed glitch-free with 1-clock latency; (B) Implementation Arena. Contributor leans toward (B) for Core minimalism, with Formation able to add registers if needed / グリッチフリーなタイミング信号とステートナンバー遷移 Tie(C2-T3 のピンレベル表現): (A) 1 クロックレイテンシで保証されたグリッチフリー；(B) Implementation Arena。貢献者はコアミニマリズムのために (B) に傾き、必要なら Formation がレジスタを追加できる | **T** |

**Decision count by status:** Fixed (F): 2; Convention (V): 7; Tie (T): 1 (plus references to Ties from earlier chapters that have pin-level expressions here: C2-T3 → C5-T1, C3-T7, C4-T1, C4-T2; C2-T4→C4-F8, C4-T3→C4-F11, C4-T4→C4-F10 are now resolved to Fixed in v1.1).

**地位別決定数:** Fixed (F): 2；Convention (V): 7；Tie (T): 1(これに加え、ここでピンレベル表現を持つ前の章からの Tie への参照: C2-T3 → C5-T1、C3-T7、C4-T1、C4-T2；C2-T4→C4-F8、C4-T3→C4-F11、C4-T4→C4-F10 は v1.1 で Fixed へ解決済み)。

The lower Fixed count compared to earlier chapters reflects the nature of pin-level specification: most decisions are Conventions (sensible defaults that could be varied) rather than architectural absolutes. The single new Tie C5-T1 is the pin-level expression of C2-T3 (glitch-free transitions) and was always destined to live at this level.

前の章と比較して低い Fixed 数は、ピンレベル仕様の性質を反映する: ほとんどの決定はアーキテクチャ的絶対というよりは Convention(変えられ得る合理的なデフォルト)である。単一の新しい Tie C5-T1 は C2-T3(グリッチフリー遷移)のピンレベル表現で、常にこのレベルに住むよう運命づけられていた。

---

## End of Chapter 5 / 第5章の末尾

> *The Core's surface is small. Most of what the Core does is implicit in what reaches its pins.*
> *コアの表面は小さい。コアが行うことのほとんどは、そのピンに届くものの中に暗黙にある。*

> *Where the Core leaves a Tie at the pin level, it is not undecided — it is invited.*
> *コアがピンレベルで Tie を残す場所、それは未決ではない —— 招かれている。*

> *Connect the mandatory pins; choose the optional ones the Formation needs; let the rest be quiet. The Core asks for no more than that.*
> *必須ピンを接続せよ；Formation が必要とするオプションのものを選べ；残りは静かにさせよ。コアはそれ以上を求めない。*

This chapter is released into the public domain under CC0 1.0 Universal. **This is the v1.0 deliberation-stage release.** Together with Chapters 1–4, it completes the Layer 1 specification of PTSG-Core's externally-visible behavior and interface. Implementation in HDL is now possible against this specification, with the Tie resolutions either left to the implementer (where Implementation Arena) or to be agreed via community deliberation (where the chapter records Tie alternatives). Layer 2 (reasoning traces) and Layer 3 (reference implementations) build on this foundation.

本章は CC0 1.0 Universal のもとパブリックドメインに公開される。**これは v1.0 協議段階リリースである。** 第1〜4章と共に、PTSGコアの外部から見える挙動とインターフェースの Layer 1 仕様を完成させる。HDL 実装は今やこの仕様に対して可能であり、Tie 解決は実装者に残されるか(Implementation Arena の場合)、コミュニティ協議経由で合意される(章が Tie 代替案を記録する場合)。Layer 2(推論軌跡)と Layer 3(リファレンス実装)はこの基盤の上に構築される。

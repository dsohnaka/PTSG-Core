# CHANGES — Layer 1 write-back for the Formation-supplied Stay duration (`stay_value`)
# CHANGES — Formation 供給の Stay 長（`stay_value`）の Layer 1 反映案

> **Status / 状態:** PROVISIONAL (仮確定) — drafted by the amanuensis from `02_Reasoning_Traces/2026-09-26_ptsg-stay-value-from-formation`. Mechanism and precedence follow the architect's directive of 2026-09-26; the sampling path (Tie C4-T5) and the pin width (Tie C5-T2) await the PTSG_WPMS_Formation office's answers (trace Hook A). Every item is subject to the architect's ruling and multi-LLM review before it enters chapter text.
> **License / ライセンス:** CC0 1.0 Universal.
> **Scope / 範囲:** Chapter 2 § 2.4 (+ § 2.12 list); Chapter 4 § 4.2, new § 4.7a, § 4.10, § 4.11, § 4.12, end epigraph; Chapter 5 § 5.2, § 5.10, new § 5.12a, § 5.15, § 5.16. Reference RTL: `03_Sample_Implementations/ptsg_core_verilog/stay_value_reference_sketch.md` (not applied; source frozen at RH030).
> **Relation to the pending free-running-fruits delta / 先行差分との関係:** that delta proposed C4-F12–F14 and a `prescaler_match` Fixed item for Chapter 5 (suggested C5-F3). This delta continues the sequence without overlap: C4-F15–F17, C4-V4, C4-T5, C5-F4, C5-V8, C5-T2. Section numbers § 4.7a / § 5.12a are chosen so that no existing section is renumbered.

---

## 1. Chapter 2 § 2.4 — forward note after the operand table / 被演算子表の後に前方注記

**EN — proposed text:**
> **Formation-supplied duration (v1.2, PROVISIONAL).** The table above gives the duration the program writes. A Formation may instead supply it through the optional input `stay_value` (Chapter 4 § 4.7a; Chapter 5 § 5.12a): a non-zero value, read when the Stay executes, replaces the written duration for that Stay; zero or unconnected leaves the table above in force. Operand 0 keeps its meaning (4096, C2-F3) — the Formation-supplied duration is a pin, not an indirect mode of operand 0.

**JA — 提案文:**
> **Formation 供給の持続時間（v1.2、仮確定）。** 上表はプログラムが書く持続時間を与える。Formation はこれに代えて、オプション入力 `stay_value`（第4章 § 4.7a;第5章 § 5.12a）で持続時間を供給できる: Stay の実行時に読まれた非ゼロ値が、その Stay の書かれた持続時間に置き換わる;ゼロまたは未接続なら上表がそのまま有効。オペランド 0 の意味（4096、C2-F3）は変わらない——Formation 供給の持続時間はピンであり、オペランド 0 の間接モードではない。

**§ 2.12 "not in this chapter" list, indirect-addressing bullet — append / 追記:** "(v1.2: a Formation-supplied Stay duration exists, via the `stay_value` pin rather than via operand 0 — Chapter 4 § 4.7a.)" / 「（v1.2: Formation 供給の Stay 長が存在する——オペランド 0 経由ではなく `stay_value` ピン経由——第4章 § 4.7a。）」

---

## 2. Chapter 4 § 4.2 — the reverse reading, and the grammar / 逆読み、そして文法

**EN — proposed paragraph after the § 4.2 table:**
> **The reverse reading (v1.2).** The escape also runs the other way — an external value first, the Core's own value as fallback: `prescaler_value` (RH029: pin → `PRESCALE` → 2^PRESC_W) and `stay_value` (§ 4.7a: pin → operand → 2^12). Operand-first (**IND**) and external-first (**IND-reverse**) are two readings of one grammar: *a field of width W; zero escapes; the 2^W sentinel, held by a W+1-bit counter.* Recorded as Convention **C4-V4**.

| Occurrence | Reading | Chain | Sentinel |
|---|---|---|---|
| Stay operand (C2-F3) | arithmetic | operand 0 → 4096 | 2^12 |
| Jump operand / Loop target (C4-F5/F6) | IND | operand 0 → external register (via § 4.5) | address domain; the v1.2 S_IND-abolition proposal uses 13'd4096 |
| `prescaler_value` (RH029) | IND-reverse | pin 0 → `PRESCALE`; both 0 → 2^PRESC_W (65536 at the default 16 bits) | 2^PRESC_W |
| `stay_value` (§ 4.7a) | IND-reverse | pin 0 → operand; both 0 → 4096 | 2^12 |

**JA — 提案段落:**
> **逆読み（v1.2）。** このエスケープは逆向きにも走る——外部値が先、コア自身の値がフォールバック: `prescaler_value`（RH029: ピン → `PRESCALE` → 2^PRESC_W）と `stay_value`（§ 4.7a: ピン → オペランド → 2^12）。オペランド優先（**IND**）と外部優先（**IND 逆**）は一つの文法の二つの読みである: *幅 W のフィールド;ゼロは逃げる;2^W の番兵を W+1 ビットのカウンタが抱える。* Convention **C4-V4** として記録する。

---

## 3. Chapter 4 — new § 4.7a / 新設 § 4.7a

**EN — proposed text:**
> **§ 4.7a Formation-supplied Stay duration (`stay_value`) — v1.2, PROVISIONAL.** A Formation may supply the duration of Stays through the optional input `stay_value` (pin level: Chapter 5 § 5.12a). The rule is the prescaler's (§ 4.7, RH029) applied to the Stay, in its IND-reverse reading (§ 4.2):
>
> `D = (stay_value ≠ 0) ? stay_value : ((operand ≠ 0) ? operand : 4096)`
>
> When `stay_value` is 0 or unconnected, every Stay behaves exactly as Chapter 2 § 2.4 specifies (**C4-F15**). *Motivation: WPMS forms wave packets of arbitrary length with packet length = Stay length (architect directive, 2026-09-26).*
>
> **Read point (C4-F16).** The value is read once per Stay, in the clock in which the Stay instruction executes, and held for the whole Stay: a change of `stay_value` during a Stay affects only Stays that execute later. For a windowed Stay (Chapter 3 § 3.2) the read happens when the Stay instruction executes — after the Stay Set and any in-window clocks — not at the Stay Set.
>
> **Compare discipline (C4-F17).** Formation-supplied durations are compared exactly as written ones, with `>=` (RH028): a windowed Stay handed a value its window has already counted past times up on the first tick of its wait. The time-base's `==` (fail-loud, 2026-08-27) is not extended to Stays.
>
> **Invariants.** Durations remain whole numbers of prescale ticks, so C4-F8, C4-F9 (phase lock), C4-F10 and C4-F11 are unaffected. `stay_value` carries no Core state: Reset — hardware or sub-operation (C3-F21) — neither reads nor clears it; insertion deferral (C3-F20) is unchanged. In clocks a Stay lasts D × P; at P = 1, Stay-N lasts N clocks.
>
> **Tie C4-T5 — sampling path.** (A) Registered one clock ahead: the pin as it stood in the clock before the Stay executes. (B) Read in the execute clock itself. *Contributor's lean: (B)* — the latch already keeps the pin off the wait's comparator, and (B) lets a Formation drive `stay_value` from a table keyed by `state_number` under any control flow. Under either, the zero test and the value come from the same sample (C5-F4).
>
> **Alternatives considered** (trace DP-1, DP-2): an indirect-read purpose code for Stay; a Core-internal register written over the external-operation bus; a new opcode; Formation rewriting of Stay operands in instruction memory; and the operand-first (IND) reading, in which only Stay(0) consults the pin. The last is retained as the standing alternative should a Formation's program model favour it.

**JA — 提案文:**
> **§ 4.7a Formation 供給の Stay 長（`stay_value`）— v1.2、仮確定。** Formation はオプション入力 `stay_value`（ピンレベル: 第5章 § 5.12a）で Stay の持続時間を供給できる。規則はプリスケーラのもの（§ 4.7、RH029）を Stay に適用した IND 逆の読み（§ 4.2）である:
>
> `D = (stay_value ≠ 0) ? stay_value : ((operand ≠ 0) ? operand : 4096)`
>
> `stay_value` が 0 または未接続なら、すべての Stay は第2章 § 2.4 のとおりに振る舞う（**C4-F15**）。*動機: WPMS は任意長の波束をパケット長＝Stay 長で形成する（アーキテクト指示、2026-09-26）。*
>
> **読み取り時点（C4-F16）。** 値は Stay ごとに一度、Stay 命令が実行されるクロックで読まれ、その Stay の全期間保持される: Stay の途中での `stay_value` の変化は、以後に実行される Stay にのみ効く。窓つき Stay（第3章 § 3.2）では、読み取りは Stay 命令の実行時——Stay Set と窓内のクロックの後——であり、Stay Set の時点ではない。
>
> **比較の規律（C4-F17）。** Formation 供給の持続時間は書かれた持続時間とまったく同じく `>=`（RH028）で比較される: 窓が既に数え越した値を渡された窓つき Stay は、待機の最初のティックでタイムアップする。時間基準の `==`（fail-loud、2026-08-27）は Stay には拡張しない。
>
> **不変量。** 持続時間はプリスケールティックの整数倍のままであり、C4-F8、C4-F9（位相ロック）、C4-F10、C4-F11 は影響を受けない。`stay_value` はコア状態を持たない: Reset——ハードウェアでもサブ演算でも（C3-F21）——はこれを読みも消しもしない;挿入の繰り延べ（C3-F20）も不変。クロック数では Stay は D × P 続き、P = 1 では Stay-N は N クロック。
>
> **Tie C4-T5 —— サンプリング経路。** (A) 1 クロック前に登録: Stay 実行の前クロックにおけるピンの値。(B) 実行クロックそのもので読む。*貢献者の傾向: (B)*——ラッチが既にピンを待機の比較器から外しており、(B) なら Formation が `state_number` をキーとする表から、どんな制御流の下でも `stay_value` を駆動できる。いずれでも、ゼロ判定と値は同一サンプルから取る（C5-F4）。
>
> **検討した代替案**（trace DP-1、DP-2）: Stay 用の間接読み目的コード;外部演算バスで書くコア内部レジスタ;新オペコード;命令メモリ上の Stay オペランドを Formation が書き換える方式;そしてオペランド優先（IND）の読み——Stay(0) だけがピンを参照する。最後のものは、Formation のプログラムモデルがそれを有利とする場合に備え、常設の代替案として保持する。

---

## 4. Chapter 4 § 4.10, § 4.11, § 4.12, end epigraph / § 4.10〜4.12、章末銘

**§ 4.10 — add bullet / 箇条追加:**
> **The pin-level signaling of `stay_value`** (width, default, timing under each C4-T5 alternative) — Chapter 5 § 5.12a. / **`stay_value` のピンレベル信号**（幅、既定値、C4-T5 各案でのタイミング）——第5章 § 5.12a。

**§ 4.11 — add rows / 行追加:**

| Question | Deferred to |
|---|---|
| Sampling path of `stay_value` (Tie C4-T5): registered one clock ahead, or read in the execute clock / `stay_value` のサンプリング経路 | WPMS Formation answers (trace Hook A) + Layer 4 checkpoint |
| Whether a Formation's program model favours the operand-first (IND) reading for Stay / Formation のプログラムモデルが Stay の IND 読みを有利とするか | WPMS Formation answers + multi-LLM review |
| Whether C4-V4 (the zero-escape grammar) should be written into Chapter 4 now or together with the v1.2 S_IND abolition / C4-V4 を今書くか v1.2 の S_IND 廃止と同時か | Architect ruling |

**§ 4.12 — add rows / 行追加:**

| ID | Decision | Status |
|---|---|---|
| **C4-F15** (v1.2, PROVISIONAL) | Formation-supplied Stay duration via `stay_value`, IND-reverse: pin ≠ 0 → pin; pin = 0 → operand per C2-F3. Silent pin = bit-identical behaviour / Formation 供給の Stay 長、IND 逆 | **F** (after review) |
| **C4-F16** (v1.2, PROVISIONAL) | Read once per Stay at its execute clock; held for the whole Stay; windowed Stays read at the Stay instruction, not the Stay Set / Stay ごとに実行時一度読み、全期間保持 | **F** (after review) |
| **C4-F17** (v1.2, PROVISIONAL) | Formation-supplied durations obey RH028 `>=`; the time-base's `==` is not extended to Stays / `>=` を継承、`==` は拡張しない | **F** (after review) |
| **C4-V4** (v1.2) | Zero-escape grammar: field width W, zero escapes, 2^W sentinel in a W+1-bit counter; IND and IND-reverse readings / ゼロエスケープ文法 | **V** |
| **C4-T5** (v1.2) | `stay_value` sampling path: (A) registered one clock ahead; (B) read in the execute clock. Contributor leans (B) / サンプリング経路 | **T** |

**Decision count (v1.2, if adopted) / 地位別決定数:** Fixed 14 (+3); Convention 4 (+1); Tie 3 (+1). *(Before the free-running-fruits delta; add its C4-F12–F14 if both are adopted.)*

**End of Chapter 4 — add epigraph / 章末銘の追加:**
> *In the Core's reverse readings, zero on the pin means: the world is silent — read the score.*
> *コアの逆読みにおいて、ピンのゼロは意味する: 世界は黙している——楽譜を読め。*

---

## 5. Chapter 5 § 5.2 — signal table / 信号表

**Add a sub-table after "Prescaler interface" / 「プリスケーラインターフェース」の後に小表を追加:**

**Formation-supplied Stay duration (optional, v1.2 PROVISIONAL) / Formation 供給の Stay 長（オプション、v1.2 仮確定）:**

| Signal | Direction | Width | Reference | Applies to |
|---|---|---|---|---|
| `stay_value` | input (tri0 default 0) | `CNT_W` = 12 in the reference — Tie C5-T2 (alt. `CNT_W`+1) | § 5.12a | Formations that time Stays (e.g. WPMS: packet length = Stay length) / Stay を計時する Formation |

**Pin count summary — append / ピン数まとめに追記:** "+12 inputs when `stay_value` is used." / 「`stay_value` 使用時 +12 入力。」

---

## 6. Chapter 5 § 5.10 — one sentence on `stay_cnt_match` / 一文追加

**EN:** "`stay_cnt_match` is also the natural pacing strobe for a Formation that sequences `stay_value` (§ 5.12a): it is high in the clock in which the instruction following the timed-out Stay executes."
**JA:** 「`stay_cnt_match` は、`stay_value` を順次与える Formation（§ 5.12a）にとって自然な歩調の合図でもある: タイムアップした Stay の次の命令が実行されるクロックでハイになる。」

---

## 7. Chapter 5 — new § 5.12a / 新設 § 5.12a

**EN — proposed text:**
> **§ 5.12a `stay_value` — Formation-supplied Stay duration (v1.2, PROVISIONAL).**
>
> **`stay_value[CNT_W-1:0]` — input, optional (C5-V8).** Declared `tri0`: unconnected reads 0, and 0 means every Stay as written. Width `CNT_W` (12 in the reference); `CNT_W`+1 is the alternative under Tie **C5-T2** (contributor leans `CNT_W`: both-zero then remains the maximum, and range extension stays the prescaler's job). Semantics: Chapter 4 § 4.7a. A program written for a Stay-timing Formation should state in its header that its Stay counts may be superseded by `stay_value`.
>
> **Timing.** Synchronous to `clk`; any synchronization is the Formation's responsibility (C5-F1). Under C4-T5 (B), the value that applies to a Stay is the one present in the clock in which that Stay executes — the clock in which `state_number` shows the Stay's own address (C5-V5). Under (A), it is the one present one clock earlier.
>
> **One sample, two uses (C5-F4).** An implementation derives the "is it zero?" decision and the value from the same sample of `stay_value`. A zero test on the raw pin beside a registered value can latch 0 on a 0→N change and run that Stay for 8192 ticks.
>
> **Formation idioms (informative).** (i) A constant or a single register: every Stay Formation-timed. (ii) A table keyed by `state_number` (distributed RAM, or an M10K read on the negative edge as `ptsg_imem` does), with 0 entries meaning "as written": per-state lengths; add `loop_counter` to the key for per-iteration lengths. Requires C4-T5 (B). (iii) A sequencer paced by `stay_cnt_match` (§ 5.10): because the pulse coincides with the next instruction's execute clock, the sequencer presents, at each pulse, the length for the Stay after next (double buffering). Works under (A) or (B).

**JA — 提案文:**
> **§ 5.12a `stay_value` —— Formation 供給の Stay 長（v1.2、仮確定）。**
>
> **`stay_value[CNT_W-1:0]` —— 入力、オプション（C5-V8）。** `tri0` 宣言: 未接続は 0 と読まれ、0 はすべての Stay を書かれたとおりに。幅は `CNT_W`（参照実装で 12）;`CNT_W`+1 は Tie **C5-T2** の代替案（貢献者は `CNT_W` に傾く: 両ゼロが最大値のままであり、範囲拡張はプリスケーラの役割に留まる）。意味論: 第4章 § 4.7a。Stay を計時する Formation 向けに書かれたプログラムは、その Stay カウントが `stay_value` により置き換わり得ることをヘッダに明記するのがよい。
>
> **タイミング。** `clk` に同期;同期化は Formation の責任（C5-F1）。C4-T5 (B) の下では、ある Stay に適用される値は、その Stay が実行されるクロック——`state_number` がその Stay 自身のアドレスを示すクロック（C5-V5）——に存在する値である。(A) の下では 1 クロック前の値。
>
> **一つのサンプル、二つの用途（C5-F4）。** 実装は「ゼロか?」の判定と値を `stay_value` の同一サンプルから導く。生ピンでのゼロ判定と登録済みの値の組合せは、0→N の変化で 0 をラッチし、その Stay を 8192 ティック走らせ得る。
>
> **Formation の定石（参考）。** (i) 定数または単一レジスタ: すべての Stay を Formation が計時。(ii) `state_number` をキーとする表（分散 RAM、または `ptsg_imem` と同じく負エッジで読む M10K）、0 のエントリは「書かれたとおり」: ステート毎の長さ;反復毎に変えるなら `loop_counter` をキーに加える。C4-T5 (B) が前提。(iii) `stay_cnt_match`（§ 5.10）で歩調を取るシーケンサ: パルスは次の命令の実行クロックと重なるので、各パルスで「次の次」の Stay の長さを提示する（ダブルバッファ）。(A)(B) いずれでも可。

---

## 8. Chapter 5 § 5.15, § 5.16 / 未解決問題と決定まとめ

**§ 5.15 — add rows / 行追加:**

| Question | Deferred to |
|---|---|
| `stay_value` width (Tie C5-T2) — depends on the longest Formation-timed Stay at the intended P / `stay_value` の幅 | WPMS Formation answers (trace Hook A) |
| Whether any Formation needs `stay_value` from another clock domain (synchronizer pattern to document) / 別クロックドメインからの供給 | Layer 3 guidance |

**§ 5.16 — add rows / 行追加:**

| ID | Decision | Status |
|---|---|---|
| **C5-F4** (v1.2) | One sample, two uses: the zero test and the value of `stay_value` come from the same sample / 同一サンプル規則 | **F** |
| **C5-V8** (v1.2) | `stay_value` is optional, declared tri0 (unconnected = 0 = as written), synchronous to `clk`; programs for Stay-timing Formations say so in their header / オプション・tri0・同期 | **V** |
| **C5-T2** (v1.2) | `stay_value` width: (A) `CNT_W`; (B) `CNT_W`+1. Contributor leans (A) / 幅 | **T** |

---

## 9. Chapter 3 — no change / 第3章 — 変更なし

The Stay-window definition (§ 3.2) and the band table (§ 3.4b) are untouched; the read point for windowed Stays is defined in Chapter 4 § 4.7a. / Stay 窓の定義（§ 3.2）と帯域表（§ 3.4b）は不変;窓つき Stay の読み取り時点は第4章 § 4.7a で定義する。

---

## 10. Summary of proposed classifications / 分類案まとめ

| Item | Proposed | Id | Evidence / basis |
|---|---|---|---|
| `stay_value`, IND-reverse precedence, silent pin = bit-identical | Fixed after review | C4-F15 | architect directive 2026-09-26; trace DP-1/DP-2 |
| Read once at execute, held for the Stay | Fixed after review | C4-F16 | RTL structure (latch at OP_STAY); trace DP-3 |
| `>=` inherited; `==` stays with the time-base | Fixed after review | C4-F17 | RH028; fail-loud ruling 2026-08-27; trace DP-6 |
| Zero-escape grammar (IND / IND-reverse, 2^W sentinel) | Convention | C4-V4 | C2-F3, RH029, S_IND-abolition formula, this item |
| Sampling path | Tie, lean (B) | C4-T5 | trace DP-4; pre-check SV-4/SV-7 (the fork is real); WPMS answers pending |
| One sample, two uses | Fixed | C5-F4 | anti-pattern's 8192-tick runaway — predicted, then reproduced in the Icarus pre-check (SV-4, SV-7) |
| Optional, tri0, synchronous; program header note | Convention | C5-V8 | trace DP-2 cost note |
| Pin width | Tie, lean (A) | C5-T2 | trace DP-5; WPMS answers pending |

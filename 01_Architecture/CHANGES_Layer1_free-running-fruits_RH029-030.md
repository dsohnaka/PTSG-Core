# CHANGES — Layer 1 write-back for RH029/RH030 (the free-running fruits)
# CHANGES — RH029/RH030（フリーランの果実）の Layer 1 反映案

> **Status / 状態:** PROVISIONAL (仮確定) — drafted by the amanuensis from `02_Reasoning_Traces/2026-08-27_ptsg-free-running-fruits`; every item is subject to the architect's ruling and multi-LLM review before it enters Chapter 4/5 text. Items marked **OPEN** carry no proposed wording beyond the recording of the gap.
> **License / ライセンス:** CC0 1.0 Universal.
> **Scope / 範囲:** Chapter 4 (§ 4.7, § 4.8a, § 4.12 table), Chapter 5 (§ 5.2 table, § 5.10, § 5.12), and a placeholder for Chapter 6. RTL header corrections are in `03_Sample_Implementations/ptsg_core_verilog/RH029-030_header_patch.md`.

---

## 0. Governing premise (new, to be placed in Chapter 4 § 4.6 or § 4.8a) / 支配前提

**EN — proposed text:**
> **The prescaler is a base-frequency generator, not an observable counter.** Its counter value is, in principle, not for external use: the Core's only externally meaningful prescaler product is the *tick*. The `prescaler_counter` output (Chapter 5 § 5.10) is therefore diagnostic and carries no timing contract; an implementation may re-time the internal tick (see § 4.8b) without altering any external interface. *(Architect ruling 2026-08-27; trace `2026-08-27_ptsg-free-running-fruits` DP-1.)*

**JA — 提案文:**
> **プリスケーラは基礎周波数の生成器であり、観測用カウンタではない。** そのカウンタ値は原則として外部利用しない: コアが外へ意味を持って出すプリスケーラ由来のものは*ティック*だけである。したがって `prescaler_counter` 出力（第5章 § 5.10）は診断用であり、タイミング契約を持たない;実装は外部インターフェースを変えることなく内部ティックを叩き直してよい（§ 4.8b 参照）。*（アーキテクト裁定 2026-08-27;trace DP-1）*

**Classification proposal / 分類案:** Convention → candidate **Fixed** after review (suggested id **C4-F12**).

---

## 1. Chapter 4 § 4.8b (new) — Two ticks: raw and registered / 二つのティック

**EN — proposed text:**
> **§ 4.8b Raw tick and registered tick (RH030).** The prescaler produces two tick signals:
> - the **raw tick** — combinational, asserted on the clock in which the prescaler counter reaches its terminal value; it drives the counter's own rollover and is the signal exported on `prescaler_match` (Chapter 5 § 5.10);
> - the **registered tick** — the raw tick passed through one register: a one-clock pulse, one clock later, which is the *only* tick the Core's execution semantics reference (Stay counting, foreground advance C4-F8, S_WAIT deadline, tick-collision rules of RH028).
>
> Because every in-core consumer uses the registered tick, the entire tick grid is displaced by exactly one system clock relative to the raw tick; all intervals, the phase-lock (C4-F9), and the tick-collision discipline (RH028) are unchanged. The purpose is timing closure: the comparator sits behind a register boundary. **Normative consequence:** `prescaler_match` leads the Core's internal tick by exactly one clock.

**JA:**
> **§ 4.8b 生ティックと登録ティック（RH030）。** プリスケーラは二つのティック信号を生む:
> - **生ティック**——組合せ信号。プリスケーラカウンタが終値に達したクロックで立つ。カウンタ自身の巻き戻しを駆動し、`prescaler_match`（第5章 § 5.10）として外部化される;
> - **登録ティック**——生ティックをレジスタ一段に通したもの: 1 クロック後の 1 クロック幅パルスで、コアの実行意味論（Stay カウント、前景進行 C4-F8、S_WAIT 締切、RH028 の tick 衝突規則）が参照する*唯一*のティック。
>
> コア内の全消費者が登録ティックを使うため、ティックグリッド全体が生ティックに対しちょうど 1 システムクロックずれる;全区間、位相ロック（C4-F9）、tick 衝突規律（RH028）は不変。目的はタイミング収束: コンパレータがレジスタ境界の背後に置かれる。**規範的帰結:** `prescaler_match` はコア内部ティックにちょうど 1 クロック先行する。

**Classification proposal:** **Fixed** candidate (suggested id **C4-F13**), pending Hook A silicon confirmation.

---

## 2. Chapter 4 § 4.7 / § 4.12 — C4-T2 contributor lean and reference form / C4-T2 の傾向と参照形

**Change:** C4-T2 stays **Tie**. Replace the contributor-lean sentence with:

**EN:**
> **Contributor's lean (2026-08 update).** The reference implementation (RH029) adopts a **pin-level value input** — here called **(B′)**: a `prescaler_value` input whose zero/unconnected state selects the compile-time `PRESCALE` parameter (option A behaviour at zero cost), and whose non-zero value overrides it. Whether the pin is driven by a constant, a Formation register, or an external-operation-bus write is a Formation decision; the Core contains no bus decode and reserves no sub-opcode. This is neither pure (A) nor the Chapter 5 § 5.12 description of (B); the Tie remains open for (C)/(D) Formations.

**JA:**
> **貢献者の傾向（2026-08 更新）。** 参照実装（RH029）は**ピンレベル値入力**——ここで **(B′)** と呼ぶ——を採る: `prescaler_value` 入力のゼロ／未接続状態は合成時 `PRESCALE` パラメータを選び（案 A の挙動をコストゼロで）、非ゼロ値はそれを上書きする。ピンを定数・Formation レジスタ・外部演算バス書込みのいずれで駆動するかは Formation の決定;コアはバスデコードを含まず、サブオペコードも予約しない。純粋な (A) でも第5章 § 5.12 の (B) 記述でもない;(C)/(D) の Formation のため Tie は開いたまま。

**§ 4.12 table row C4-T2:** append "Reference implementation: (B′) pin-level value with parameter fallback (RH029)" to the description; status stays **T**.

---

## 3. Chapter 5 § 5.2 — signal table / 信号表

| Signal | Direction | Width | Reference | Applies to (proposed) |
|---|---|---|---|---|
| `prescaler_value` | input | `PRESC_W` (16 in reference) | § 5.12 | **(B′) pin-level value; 0/unconnected = compile-time parameter.** *(was: "Compile-time fixed (C4-T2 option A): wire input" — relabel)* |
| `prescaler_match` | output | 1 | § 5.10 | Optional; **raw tick**, leads internal tick by 1 clk |
| `prescaler_counter` | output | `PRESC_W` | § 5.10 | Optional, **diagnostic only** (no timing contract) |
| `prescaler_output` | output | `PRESC_W` | — | **OPEN** — declared in RH029, undriven; define (e.g. effective divide value in force) or delete |

---

## 4. Chapter 5 § 5.10 — `prescaler_counter`, `prescaler_match` paragraph / 段落差替え

**EN — replace the existing paragraph with:**
> **`prescaler_counter`, `prescaler_match` — optional outputs.** `prescaler_match` is the **raw tick** (§ 4.8b): a combinational output asserted on the clock in which the prescaler counter reaches its terminal value, exactly **one clock before** the Core's internal registered tick. It is timing-analysed like any combinational output and **must be registered by the consumer**; a Formation that registers it once obtains a pulse coincident with the Core's internal tick — the property that makes it usable as a synchronisation source for other cores (§ 5.12). `prescaler_counter` reflects the running counter value for diagnosis (SignalTap, simulation) and carries **no timing contract** (governing premise, Chapter 4 § 4.8a); its width is `PRESC_W`.

**JA:**
> **`prescaler_counter`、`prescaler_match` —— オプション出力。** `prescaler_match` は**生ティック**（§ 4.8b）: プリスケーラカウンタが終値に達したクロックで立つ組合せ出力で、コア内部の登録ティックのちょうど **1 クロック前**。他の組合せ出力同様にタイミング解析対象であり、**受け側で必ず登録すること**;一段登録した Formation はコア内部ティックと一致するパルスを得る——これが他コアの同期源として使える根拠である（§ 5.12）。`prescaler_counter` は診断（SignalTap、シミュレーション）のため走行中のカウンタ値を映すが、**タイミング契約を持たない**（支配前提、第4章 § 4.8a）;幅は `PRESC_W`。

---

## 5. Chapter 5 § 5.12 — replace the "Forthcoming" note; add (B′); define delivered sync / 近刊注記の差替え

**5a. Replace the v1.1 "Forthcoming (Chapter 6 / Build Log #9)" note with:**

**EN:**
> **Delivered (RH029/RH030; trace `2026-08-27_ptsg-free-running-fruits`).** The two remaining fruits of the free-running prescaler are now in the reference implementation: the **one-clock-registered internal tick** (Fmax; § 4.8b) and the **export of the raw tick** on `prescaler_match` (§ 5.10). Together with the pin-level `prescaler_value` (B′) they provide **period-sharing synchronisation**: cores that receive the same `prescaler_value` and the same hardware reset run phase-locked indefinitely (C4-F9, C3-F21), with identical one-clock tick latency. A **tick-following** configuration — a core that accepts another core's tick in place of its own comparator — is **not** provided by the Core and is reserved for Chapter 6 (Tie candidate; trace DP-4).

**JA:**
> **実装済み（RH029/RH030;trace `2026-08-27_ptsg-free-running-fruits`）。** フリーランプリスケーラの残る二つの果実は参照実装に入った: **1 クロック登録の内部ティック**（Fmax;§ 4.8b）と `prescaler_match` での**生ティック外部化**（§ 5.10）。ピンレベル `prescaler_value`（B′）と合わせて**周期共有同期**を提供する: 同一の `prescaler_value` と同一のハードウェアリセットを受けるコア群は無期限に位相ロックされ（C4-F9、C3-F21）、ティック遅延は全コアで同一の 1 クロック。他コアのティックを自身のコンパレータの代わりに受け入れる**ティック追従**構成はコアでは提供**しない**——第6章に留保（Tie 候補;trace DP-4）。

**5b. Option (B) paragraph:** keep as an alternative; add after it the (B′) paragraph from § 2 above, marked "reference implementation".

**5c. Live-write semantics — OPEN.** Record:
> **OPEN:** the effect timing of a change to `prescaler_value` while running. As built, the new terminal value takes effect at the next compare (one clock after the pin changes, via the registered `value − 1`); there is no boundary quantisation analogous to the barline rule. **By design (architect ruling 2026-08-27) there is no `>=` protection:** a counter already past the new terminal wraps through 2^16 — a fault that is meant to be loud, because a time-base overrun is fatal by concept (deliberate asymmetry with RH028's `>=` on the stay counter). Formations must therefore change `prescaler_value` only while the counter is known to be below the new terminal. Whether a boundary-quantised write is wanted remains OPEN.

---

## 6. Chapter 6 placeholder / 第6章の予約枠

> **Chapter 6 — Multi-PTSG Coordination (reserved).** Owns: the tick-following slave (Core port vs Formation wrapper; slave `presc_cnt` behaviour; slave Reset interaction with C3-F21 — the 2026-06-23 Hook E question); cross-clock-domain tick transfer; Insertion × Multi-PTSG. Inherits DP-4 and Hook B of `2026-08-27_ptsg-free-running-fruits`.

---

## 7. Cross-reference corrections / 相互参照の修正

- `02_Reasoning_Traces/2026-06-23_ptsg-reset-command-bands.{md,json}` — Hook E: add a "closed by 2026-08-27_ptsg-free-running-fruits" line (do not rewrite history; append). Build Log #9 pointer: retarget per Hook D ruling.
- Chapter 5 § 5.12 pointers to "Build Log #9": retarget likewise.
- Session record 2026-07-25 ("`>=` comparator protection" in RH029–30): flagged as disagreeing with the file; resolution per Hook C.

---

## 8. Summary of proposed classifications / 分類案まとめ

| Item | Proposed | Id (suggested) | Evidence |
|---|---|---|---|
| Counter not an interface / base-frequency only | Fixed (after review) | C4-F12 | architect ruling 2026-08-27 |
| Registered internal tick; grid shifted uniformly by 1 clk | Fixed (after Hook A) | C4-F13 | RH030 |
| `prescaler_match` = raw tick, leads internal tick by 1 clk; consumer registers | Fixed (after Hook A) | C5-F? | RH030 |
| (B′) pin-level value with parameter fallback | Convention (reference form); C4-T2 stays Tie | C4-T2 lean | RH029 |
| Period-sharing sync = delivered; tick-following = Chapter 6 | Tie candidate | C6-T1 | DP-4 |
| `presc_tickP` uses `==`, fail-loud, no `>=` | **Fixed** (ruled 2026-08-27) | C4-F14 (suggested) | DP-6 item 1 |
| Live-write boundary semantics of `prescaler_value` | OPEN | — | DP-6 |
| `prescaler_output` definition | OPEN | — | DP-6 |

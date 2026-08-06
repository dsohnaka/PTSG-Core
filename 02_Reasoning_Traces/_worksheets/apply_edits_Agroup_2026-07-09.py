#!/usr/bin/env python3
# A-group codification + trace-1 correction. All replacements asserted count==1
# in memory; files are written ONLY after every assert passes (lesson: a mid-script
# exception must not leave partial saves).
import json, re, shutil, os, sys

SRC = "/home/claude/PTSG-Core-main"
OUT = "/home/claude/edited"
os.makedirs(OUT, exist_ok=True)

files = {
 "ch3": f"{SRC}/01_Architecture/PTSG_Core_Layer1_Chapter3_SubOpcode_and_Background_Execution.md",
 "ch5": f"{SRC}/01_Architecture/PTSG_Core_Layer1_Chapter5_External_Logic_Interface.md",
 "tmd": f"{SRC}/02_Reasoning_Traces/2026-07-08_ptsg-open-prompt-first-closure.md",
 "tjs": f"{SRC}/02_Reasoning_Traces/2026-07-08_ptsg-open-prompt-first-closure.json",
}
buf = {k: open(v, encoding="utf-8").read() for k, v in files.items()}
nrep = 0

def rep(key, old, new):
    global nrep
    c = buf[key].count(old)
    assert c == 1, f"[{key}] count={c} for: {old[:90]!r}"
    buf[key] = buf[key].replace(old, new)
    nrep += 1

# ============ Ch3 — A1: Loop 16-bit ============
rep("ch3",
"| Width of the loop counter | 12 bits (matching the operand and the D16–D31 target field's low 12 bits) | **V** (C3-V2, retained) |",
"| Width of the loop counter | **16 bits** — the full D16–D31 target field (Loop is a Global Mode-0 command; its operand is the 16-bit field). Ruled live 2026-07-06 (RH009); earlier v1.1 text said 12 bits. / **16 ビット**——D16–D31 目標フィールド全幅（Loop は Global Mode-0 カテゴリでオペランドは 16bit）。2026-07-06 生裁定（RH009）;旧 v1.1 文は 12 ビットとしていた。 | **V** (C3-V2, revised 2026-07) |")

rep("ch3",
"| Target source | The 12-bit target value is read from the **D16–D31 extended operand** (Chapter 2 v1.1 § 2.7/2.8). Indirect target (literal-zero-as-escape) remains a Chapter 4 topic. / 12ビット目標値は **D16-D31 拡張オペランド**から読まれる。間接目標(直値ゼロエスケープ)は第4章の話題として残る。 | **F** (C3-F13, revised) |",
"| Target source | The 16-bit target value is read from the **D16–D31 extended operand** (Chapter 2 v1.1 § 2.7/2.8). Indirect target (literal-zero-as-escape) remains a Chapter 4 topic. / 16ビット目標値は **D16-D31 拡張オペランド**から読まれる。間接目標(直値ゼロエスケープ)は第4章の話題として残る。 | **F** (C3-F13, revised; width 16 per C3-V2 rev. 2026-07) |")

rep("ch3",
"| **C3-V2** | Width of the loop counter: 12 bits (matching operand width and the D16–D31 target's low 12 bits) / ループカウンタの幅: 12 ビット(オペランド幅と D16-D31 目標の下位 12 ビットと一致) | **V** (retained) |",
"| **C3-V2** (revised 2026-07) | Width of the loop counter: **16 bits** — the full D16–D31 target field (Loop is Global Mode-0; operand = 16 bits). Ruled live during the implementation campaign (RH009), resolving the 12/16 spec-internal contradiction that the § 3.4b 2^28 example exposed. Downstream widths follow: queued target, holding-register loop field, external stack word 41 bits (§ 3.7; Ch5 § 5.8). / ループカウンタの幅: **16 ビット**——D16–D31 目標フィールド全幅（Loop は Global Mode-0;オペランド = 16bit）。実装キャンペーン中の生裁定（RH009）;§ 3.4b の 2^28 例が暴いた 12/16 仕様内矛盾を解決。下流の幅が従う: Que ターゲット、保持レジスタ loop フィールド、外部スタック語 41bit（§ 3.7;第5章 § 5.8）。 | **V** (revised 2026-07) |")

rep("ch3",
"**(REVISED in v1.1)** Loop counter target: the 12-bit target value is read from the D16–D31 extended operand; the counter up-counts from 0 to this target. Indirect target (literal-zero-as-escape) remains a Chapter 4 topic. / **(v1.1 で改訂)** ループカウンタ目標: 12ビット目標値は D16-D31 拡張オペランドから読まれる；カウンタは 0 からこの目標までアップカウントする。",
"**(REVISED in v1.1)** Loop counter target: the 16-bit target value is read from the D16–D31 extended operand; the counter up-counts from 0 to this target. Indirect target (literal-zero-as-escape) remains a Chapter 4 topic. / **(v1.1 で改訂)** ループカウンタ目標: 16ビット目標値は D16-D31 拡張オペランドから読まれる；カウンタは 0 からこの目標までアップカウントする。")

# ============ Ch3 — A2: Queued NOP (C3-T13 → C3-F27) ============
rep("ch3",
"| **Global · NOP** | FG | No effect (untouched すでにReset) | Driven (changes per instruction) | Consumes one tick (waits for next) | tickを待ってインクリメント | Trailing | Legal | State-0 cold-start absorber (C4-V3) when used as the state-0 NOP. |\n|  | BG | Continue counting (no reset) <br>when On-Tick | Held (unchanged / frozen) | Ignored (runs at full system clock) | 次のクロックでインクリメント | Trailing | Legal |  |\n|  | Q | Continue counting (no reset) <br>when On-Tick | Held (unchanged / frozen) | Ignored (runs at full system clock) | 次のクロックでインクリメント | Trailing | Legal |  |",
"| **Global · NOP** | FG | No effect (untouched すでにReset) | Driven (changes per instruction) | Consumes one tick (waits for next) | tickを待ってインクリメント | Trailing | Legal | State-0 cold-start absorber (C4-V3) when used as the state-0 NOP. |\n|  | BG | Continue counting (no reset) <br>when On-Tick | Held (unchanged / frozen) | Ignored (runs at full system clock) | 次のクロックでインクリメント | Trailing | Legal |  |\n|  | Q | Continue counting (no reset) <br>when On-Tick | Held (unchanged / frozen) | Ignored (runs at full system clock) | 次のクロックでインクリメント | Trailing | Legal | Uniform +1 in every band (C3-F27, ruled 2026-07-06 / RH010): no reservation, never enters the wait state; band judged by in_queued_band; the 3-band template is kept as the sub-op 8–255 extension pattern. Resolves C3-T13. / 全帯域一様+1（C3-F27、2026-07-06 裁定/RH010）: 予約せず待機にも入らない;in_queued_band 判定;3帯域テンプレートはサブop 8–255 拡張の雛形として保持。C3-T13 を解決。 |")

rep("ch3",
"**Formation forward link / Formation 前方リンク:** queue copy to general registers → timing signals\ndriven by computation results. / キューの汎用レジスタコピー → 演算結果に基づくタイミング信号。\n\n---",
"""**Formation forward link / Formation 前方リンク:** queue copy to general registers → timing signals
driven by computation results. / キューの汎用レジスタコピー → 演算結果に基づくタイミング信号。

### Queued-band NOP — C3-F27 (v1.1, ruled 2026-07-06) / Que 帯域の NOP — C3-F27（2026-07-06 裁定）

**A NOP advances the State Number by one in every band, and does nothing else.** In the queued band
it makes no reservation and never enters the wait state. (The pre-ruling RTL drifted into S_WAIT with
a stale stay target — "transitioning to S_WAIT at a place like this is far too frightening," ruled
the architect.) Band membership is judged by `in_queued_band`, and the three-band dispatch template
is deliberately retained in the RTL even though its three arms are now identical: it is the extension
pattern for future internal sub-opcodes 8–255. This resolves Tie C3-T13 — the "Timeup-tracking
placeholder" role once imagined for a queued NOP is not a NOP behavior; if ever wanted, it belongs to
a future sub-opcode carried by the preserved template. (RTL: RH010.)

**NOP は全帯域で State Number を 1 進める。それ以外は何もしない。** Que 帯域では予約を行わず、待機状態にも
決して入らない。（裁定前の RTL は残留した stay 目標のまま S_WAIT に落ちていた——「こんなところで S_WAIT に
遷移するのは恐ろしすぎます」とアーキテクトは裁定した。）帯域の判定は `in_queued_band` によって行い、
3帯域ディスパッチのテンプレートは、三本の腕が同一になった今も RTL に意図的に保持する: それは将来の内部
サブオペコード 8–255 の拡張雛形である。これは Tie C3-T13 を解決する——かつて Que NOP に想像された
「Timeup 追尾プレースホルダー」の役割は NOP の挙動ではない;必要になれば、保持されたテンプレートに乗る
将来のサブオペコードが担う。（RTL: RH010。）

---""")

rep("ch3",
"| **C3-T13** (v1.1, new) | Queued NOP — whether a NOP placed after Prog End should function as a Timeup-tracking timing placeholder (sliding one prescaled unit / a specific pin phase in at the very end of the wait). Deferred to Chapter 4. / キュー NOP——Prog End の後に置かれた NOP が、Timeup 追尾型タイミングプレースホルダーとして機能すべきか(待機の最末尾にプリスケール1単位／特定ピンフェーズを滑り込ませる)。第4章へ繰り延べ。 | **T** (deferred) |",
"| **C3-T13 → C3-F27** (resolved 2026-07-06) | **RESOLVED.** Queued NOP = uniform State-Number increment in every band; no reservation, no wait-state entry; in_queued_band judgment, with the three-band template preserved as the sub-opcode 8–255 extension pattern. The Timeup-tracking-placeholder idea is not a NOP behavior (a future sub-opcode may take it up via the preserved template). Now **Fixed C3-F27** (§ 3.4b). / **解決。** Que NOP = 全帯域一様の SN インクリメント;予約せず待機にも入らない;in_queued_band 判定、3帯域テンプレートはサブオペコード 8–255 拡張の雛形として保持。Timeup 追尾プレースホルダー案は NOP の挙動ではない（必要なら将来のサブオペコードが保持テンプレート経由で担う）。今や **Fixed C3-F27**（§ 3.4b）。 | **F** (now C3-F27) |")

# ============ Ch3 — A3: Reset-Q independent reservation ============
rep("ch3",
"| **Queued (effectively prescaled)** / Que（実質プリスケールド） | The Reset fires at Stay-timeup, landing on a prescale boundary. / Reset は Stay-timeup で発火し、プリスケール境界に乗る。 |",
"| **Queued (effectively prescaled)** / Que（実質プリスケールド） | The Reset fires at Stay-timeup, landing on a prescale boundary. **Independent parallel reservation (ruled 2026-07-07, RH015):** a queued Reset does NOT use the shared single reservation slot (C3-F26); it reserves in its own parallel channel, outranks every other queued command and any deferred insertion at timeup, and fires destructively — a hardware-reset-grade clear of the execution context, sparing only presc_cnt (C3-F21). \"Reset is initialization; destructive behavior is acceptable\" (the architect). / Reset は Stay-timeup で発火し、プリスケール境界に乗る。**独立並列予約（2026-07-07 裁定、RH015）:** Que の Reset は共有単一予約スロット（C3-F26）を使わない;自前の並列チャネルに予約され、timeup では他のあらゆる Que 済みコマンド・繰り延べ挿入に優先し、破壊的に発火する——presc_cnt のみを除く実行文脈のハードウェアリセット級クリア（C3-F21）。「Reset は初期化なので、破壊的な挙動をしてもかまいません」（アーキテクト）。 |")

rep("ch3",
"Effectively prescaled — fires at Stay-timeup (§3.4a, PROVISIONAL). Never resets presc_cnt (C3-F21). |",
"Effectively prescaled — fires at Stay-timeup (§3.4a, PROVISIONAL). Never resets presc_cnt (C3-F21). Independent parallel reservation, absolute priority, destructive clear at firing (C3-F22 rev. 2026-07, RH015) — outside the C3-F26 shared slot. / 独立並列予約・絶対優先・発火時破壊的クリア（C3-F22 改訂、RH015）——C3-F26 共有スロットの外。 |")

rep("ch3",
"プログラムを救えず（どの違反にするかを選ぶだけ）、Stay-timeup 経路——1クロック叩きティックが清潔に保つまさに\nその経路——にロジックを載せる（Fmax）。\n",
"プログラムを救えず（どの違反にするかを選ぶだけ）、Stay-timeup 経路——1クロック叩きティックが清潔に保つまさに\nその経路——にロジックを載せる（Fmax）。\n\n**Reset carve-out (2026-07, RH015) / Reset の別枠:** the queued **Reset** lives outside this single\nslot: it reserves in an independent parallel channel, takes absolute priority at timeup, and clears\ndestructively (§ 3.4a). / Que の **Reset** はこの単一スロットの外に住む: 独立並列チャネルに予約され、\ntimeup で絶対優先し、破壊的にクリアする（§ 3.4a）。\n")

rep("ch3",
"| **C3-F22** (v1.1, PROVISIONAL) | **Reset execution bands.** Reset is selectable across foreground (immediate, aligned by the following state-0 NOP; Reset+NOP sharing one timing_signals value = one prescale period), background (\"staff meal\", indeterminate, emergencies), and queued (effectively prescaled, fires at Stay-timeup). See § 3.4a. / **Reset 実行帯域。** Reset は前景（即時、後続 state-0 NOP で整列；Reset+NOP が一 timing_signals 値共有 = 1 プリスケール周期）、背景（「まかない」、不定、緊急）、Que（実質プリスケールド、Stay-timeup 発火）で選択可能。§ 3.4a 参照。 | **F** (仮確定) |",
"| **C3-F22** (v1.1, PROVISIONAL; queued channel revised 2026-07) | **Reset execution bands.** Reset is selectable across foreground (immediate, aligned by the following state-0 NOP; Reset+NOP sharing one timing_signals value = one prescale period), background (\"staff meal\", indeterminate, emergencies), and queued (effectively prescaled, fires at Stay-timeup). **Queued-channel revision (2026-07, RH015):** the queued Reset reserves independently and in parallel — not in the C3-F26 shared slot — with absolute priority over all queued commands and deferred insertions, and performs a destructive hardware-reset-grade clear at firing (presc_cnt excepted, C3-F21). See § 3.4a. / **Reset 実行帯域。** Reset は前景（即時、後続 state-0 NOP で整列；Reset+NOP が一 timing_signals 値共有 = 1 プリスケール周期）、背景（「まかない」、不定、緊急）、Que（実質プリスケールド、Stay-timeup 発火）で選択可能。**Que チャネル改訂（2026-07、RH015）:** Que の Reset は C3-F26 共有スロットではなく独立並列に予約され、全 Que 済みコマンド・繰り延べ挿入に絶対優先し、発火時に破壊的なハードウェアリセット級クリアを行う（presc_cnt を除く、C3-F21）。§ 3.4a 参照。 | **F** (仮確定) |")

rep("ch3",
"Resolves verification-queue #4. See § 3.4b. / **Que容量: 後勝ち;SN上書きはHALT。** 単一予約レジスタ;後の予約が置換;SN 予約の上書きは暴走エラー。優先順位調停は棄却（意図を救えず timeup 経路に負荷）。検証キュー#4 を解決。 | **F** (仮確定) |",
"Queued Reset is exempt — independent parallel channel (C3-F22 rev. 2026-07). Resolves verification-queue #4. See § 3.4b. / **Que容量: 後勝ち;SN上書きはHALT。** 単一予約レジスタ;後の予約が置換;SN 予約の上書きは暴走エラー。優先順位調停は棄却（意図を救えず timeup 経路に負荷）。Que Reset は適用外——独立並列チャネル（C3-F22 改訂）。検証キュー#4 を解決。 | **F** (仮確定) |")

# New C3-F27 row after the C3-T15 row
rep("ch3",
"（QUEUE_DEPTH パラメータが両立し得る）。費用計測まで未決。 | **T** |",
"（QUEUE_DEPTH パラメータが両立し得る）。費用計測まで未決。 | **T** |\n| **C3-F27** (v1.1, ruled 2026-07-06) | **Queued-band NOP: uniform increment.** NOP advances the State Number by one in every band and does nothing else; no reservation, no wait state. The in_queued_band dispatch template is preserved in RTL as the sub-opcode 8–255 extension pattern. Resolves Tie C3-T13. RTL: RH010. See § 3.4b. / **Que 帯域 NOP: 一様インクリメント。** NOP は全帯域で SN を 1 進める以外何もしない;予約も待機もなし。in_queued_band 判定テンプレートは 8–255 拡張の雛形として RTL に保持。Tie C3-T13 を解決。RTL: RH010。§ 3.4b 参照。 | **F** |")

# Recounted status bullets (old block had drifted)
rep("ch3",
"- **Fixed (F):** 20 — architectural commitments (including v1.1 additions C3-F15–F20 and the revisions of C3-F2/F3/F4)\n- **Convention (V):** 1 — C3-V2 (counter width); C3-V1 and C3-V3 were superseded/promoted in v1.1\n- **Tie (T):** 12 — C3-T1–T7 (carried from v1.0), plus C3-T10–T14 (new, prescaler-coupled); C3-T8 was resolved and C3-T9 dissolved in v1.1",
"- **Fixed (F):** all rows above carrying status F, including the v1.1 additions C3-F15–F20, the PROVISIONAL block C3-F21–F26, C3-F27 (2026-07), and the former Ties resolved into F (C3-T8→C3-F20, C3-T13→C3-F27) or promoted to Chapter 4 (C3-T10→C4-F11, C3-T11→C4-F10)\n- **Convention (V):** 2 — C3-V2 (counter width, revised to 16 bits 2026-07) and C3-V4 (Formation opt-in, PROVISIONAL); C3-V1 and C3-V3 were superseded/promoted in v1.1\n- **Tie (T):** 10 open — C3-T1–T7 (carried from v1.0), C3-T12, C3-T14, C3-T15\n\n*(Counts re-derived from the table itself, 2026-07-09; the earlier prose predated the C3-F21–F26/T15 additions and had drifted. / 数は 2026-07-09 に表自体から再導出;旧文は C3-F21–F26/T15 追加以前のもので、ずれが生じていた。)*")

# §3.4b preamble: cross-reference to the publication Excel (agreed 2026-07-09)
rep("ch3",
"> （§ 3.4c）。新規 RTL を要する項目は仮確定。推論は上記 Layer 2 トレース二本に保管。\n",
"> （§ 3.4c）。新規 RTL を要する項目は仮確定。推論は上記 Layer 2 トレース二本に保管。\n>\n> **Publication rendering / 公開用整形版:** a non-normative Excel rendering of this table (with its\n> bilingual draft worksheet) is maintained at `02_Reasoning_Traces/_worksheets/`. The canon is this\n> section. / 本表の非規範な公開用 Excel 整形版（日英たたき台と共に）は `02_Reasoning_Traces/_worksheets/`\n> に維持される。正典は本節である。\n")

# ============ Ch5 — A1 downstream widths ============
rep("ch5",
"| `stack_data` | bidirectional | implementation-defined (typically 24–32) | § 5.8 |",
"| `stack_data` | bidirectional | implementation-defined (as-built 41: ins 1 + base 12 + loop 16 + state 12) | § 5.8 |")

rep("ch5",
"| `loop_counter` | output | 12 | § 5.10 | Optional (for Formation external-index use) / オプション |",
"| `loop_counter` | output | 16 | § 5.10 | Optional (for Formation external-index use) / オプション |")

rep("ch5",
"Typical width 24–32 bits: 12 (State Number) + 12 (loop counter) + a few flag bits.",
"As-built width **41 bits**: insertion flag (1) + base (12) + loop counter (16; C3-V2 rev. 2026-07 / RH009) + State Number (12). (The earlier 24–32 estimate predates the Loop 16-bit ruling; carrying the insertion-flag bit is the C3-T7 lean-(A) layout.)")

rep("ch5",
"典型的な幅 24-32 ビット: 12(ステートナンバー) + 12(ループカウンタ) + 数個のフラグビット。",
"現行実装幅 **41 ビット**: 挿入フラグ(1) + Base(12) + ループカウンタ(16;C3-V2 改訂 2026-07/RH009) + ステートナンバー(12)。（従来の 24-32 見積もりは Loop 16bit 裁定以前のもの;挿入フラグビットの搭載は C3-T7 の (A) 傾斜レイアウト。）")

rep("ch5",
"**`loop_counter[11:0]` — 12-bit, optional output.**",
"**`loop_counter[15:0]` — 16-bit, optional output (width revised 2026-07: C3-V2 rev. / RH009).**")

rep("ch5",
"**`loop_counter[11:0]` — 12 ビット、オプション出力。**",
"**`loop_counter[15:0]` — 16 ビット、オプション出力（2026-07 幅改訂: C3-V2 改訂/RH009）。**")

# ============ Trace ① md — tier boundary correction ============
rep("tmd",
"**Claude Code — Fable 5** (planning & inspection tier: audit, 7-phase plan, Phase 0, final inspection RH027, RH028 analysis); **Claude Code — Sonnet 5** (execution tier: Phases 1–6, entirely on the rails laid by the planning tier)",
"**Claude Code — Fable 5** (planning & inspection tier: audit, 7-phase plan, Phases 0–1, final inspection RH027, RH028 analysis); **Claude Code — Sonnet 5** (execution tier: Phases 2–6, entirely on the rails laid by the planning tier) *(tier boundary corrected 2026-07-09, architect-confirmed — the model switch occurred after Phase 1; an earlier text drew the boundary at Phase 0/1)*")

rep("tmd",
"**Chosen:** tiered — **Fable 5** performed the opening audit + 7-phase plan + Phase 0, and the\nclosing inspection (RH027) + the RH028 boundary analysis; **Sonnet 5 executed Phases 1–6 entirely**,\nincluding the HALT machinery and the Stay Start State register, with zero derailments; the architect\njudged the Phase 3 code \"beautiful and high-quality\".",
"**Chosen:** tiered — **Fable 5** performed the opening audit + 7-phase plan + Phases 0–1, and the\nclosing inspection (RH027) + the RH028 boundary analysis; **Sonnet 5 executed Phases 2–6 entirely**,\nincluding the HALT machinery and the Stay Start State register, with zero derailments; the architect\njudged the Phase 3 code \"beautiful and high-quality\". *(Tier boundary corrected 2026-07-09,\narchitect-confirmed: the model switch occurred after Phase 1; an earlier text drew it at Phase 0/1.)*")

rep("tmd",
"**選択:** 階層化——**Fable 5** が冒頭の監査＋7フェーズ計画＋Phase 0 と、締めの総点検（RH027）＋RH028 境界解析を担い、\n**Sonnet 5 が Phase 1–6 の全実装**（HALT 機構も Stay Start State レジスタも含めて）を脱線ゼロで遂行;アーキテクトは\nPhase 3 のコードを「非常に美しい、高品質」と評した。",
"**選択:** 階層化——**Fable 5** が冒頭の監査＋7フェーズ計画＋Phase 0–1 と、締めの総点検（RH027）＋RH028 境界解析を担い、\n**Sonnet 5 が Phase 2–6 の全実装**（HALT 機構も Stay Start State レジスタも含めて）を脱線ゼロで遂行;アーキテクトは\nPhase 3 のコードを「非常に美しい、高品質」と評した。*（階層境界 2026-07-09 訂正・アーキテクト確認済み: モデル切替は\nPhase 1 完了後;旧文は境界を Phase 0/1 に置いていた。）*")

# ============ Trace ① json — tier boundary correction ============
rep("tjs",
'"role": "execution tier: Phases 1–6 implemented entirely on the rails laid by the planning tier",',
'"role": "execution tier: Phases 2–6 implemented entirely on the rails laid by the planning tier (tier boundary corrected 2026-07-09, architect-confirmed; an earlier text said Phases 1–6)",')

rep("tjs",
'"role_ja": "実行層: 計画層が敷いたレールの上でPhase 1–6の全実装を遂行"',
'"role_ja": "実行層: 計画層が敷いたレールの上でPhase 2–6の全実装を遂行（階層境界2026-07-09訂正・アーキテクト確認済み;旧文はPhase 1–6としていた）"')

rep("tjs",
'"role": "planning & inspection tier: conformance audit, 7-phase plan, final inspection (RH027), and the RH028 boundary analysis"',
'"role": "planning & inspection tier: conformance audit, 7-phase plan, Phases 0–1, final inspection (RH027), and the RH028 boundary analysis"')

rep("tjs",
"Sonnet 5 executed Phases 1–6 entirely on those rails.\",",
"Sonnet 5 executed Phases 2–6 entirely on those rails (tier boundary corrected 2026-07-09).\",")

rep("tjs",
"Sonnet 5 がそのレールの上で Phase 1–6 の全実装を遂行した。\",",
"Sonnet 5 がそのレールの上で Phase 2–6 の全実装を遂行した（階層境界2026-07-09訂正）。\",")

rep("tjs",
'"characterization": "Fable 5 performed the opening audit + 7-phase plan + Phase 0, and the closing inspection (RH027) + the RH028 boundary analysis; Sonnet 5 executed Phases 1–6 entirely"',
'"characterization": "Fable 5 performed the opening audit + 7-phase plan + Phases 0–1, and the closing inspection (RH027) + the RH028 boundary analysis; Sonnet 5 executed Phases 2–6 entirely (tier boundary corrected 2026-07-09)"')

rep("tjs",
'"chosen": "Tiered, and it worked: Phases 1–6 — the bulk of the RTL work, including the HALT machinery and the Stay Start State register — were implemented by Sonnet 5 on the rails Fable 5 had laid',
'"chosen": "Tiered, and it worked: Phases 2–6 — the bulk of the RTL work, including the HALT machinery and the Stay Start State register — were implemented by Sonnet 5 on the rails Fable 5 had laid (tier boundary corrected 2026-07-09: the model switch occurred after Phase 1)')

rep("tjs",
"Fable 5 performed the opening audit/plan/Phase 0 and the closing inspection (RH027) and RH028 analysis; Sonnet 5 executed Phases 1–6 entirely on those rails, flawlessly.",
"Fable 5 performed the opening audit/plan/Phases 0–1 and the closing inspection (RH027) and RH028 analysis; Sonnet 5 executed Phases 2–6 entirely on those rails, flawlessly (tier boundary corrected 2026-07-09).")

# ============ All asserts passed — validate JSON, then save ============
d = json.loads(buf["tjs"])
assert len(d["decision_points"]) == 7 and len(d["themes"]) == 5 and len(d["resumption_hooks"]) == 5, "json structure changed"

outnames = {
 "ch3": "PTSG_Core_Layer1_Chapter3_SubOpcode_and_Background_Execution.md",
 "ch5": "PTSG_Core_Layer1_Chapter5_External_Logic_Interface.md",
 "tmd": "2026-07-08_ptsg-open-prompt-first-closure.md",
 "tjs": "2026-07-08_ptsg-open-prompt-first-closure.json",
}
for k, name in outnames.items():
    with open(os.path.join(OUT, name), "w", encoding="utf-8") as f:
        f.write(buf[k])

print(f"OK — {nrep} replacements applied, all asserted count==1; JSON valid (DP=7/themes=5/hooks=5); 4 files written to {OUT}")

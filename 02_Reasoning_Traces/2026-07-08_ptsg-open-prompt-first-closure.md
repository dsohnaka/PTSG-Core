# PTSG — The First Closure of the Open Prompt Loop: The Implementation Campaign (RH009–RH027)
# PTSG — Open Promptループの最初の閉環: 実装キャンペーン（RH009–RH027）

## Trace Metadata / 軌跡メタデータ

| Field | Value |
|---|---|
| **Date / 日付** | 2026-07-08 |
| **Participants / 参加者** | Tsuneo Ohnaka (大中庸生, FPGA Architect; sole design authority; ruled live during the campaign); **Claude Code — Fable 5** (planning & inspection tier: audit, 7-phase plan, Phases 0–1, final inspection RH027, RH028 analysis); **Claude Code — Sonnet 5** (execution tier: Phases 2–6, entirely on the rails laid by the planning tier) *(tier boundary corrected 2026-07-09, architect-confirmed — the model switch occurred after Phase 1; an earlier text drew the boundary at Phase 0/1)*; Claude (amanuensis / 祐筆 — this archive, from the campaign log and the agent's 15-item handoff, PR #2) |
| **Topic / トピック** | The Open Prompt — Layer 1 v1.1 spec, the §3.4b normative table, the CHANGES work order, the traces, the evidence — was handed to an implementing agent for the first time. It came back as 19 RTL revisions (RH009–RH027), a conformance suite (T1–T33), live rulings, retroactive enforcement of the FG-Global exclusion, and a 15-item Layer 2 handoff list. PR #2 merged; the Layer 4 verification menu then passed **on silicon, first try**. / Open Prompt の初手渡し。19改訂・T1–T33・生きた裁定・遡及執行・引き継ぎ15項目が返り、**実機一発クリア**。 |
| **Status / 状態** | **COMPLETED & SILICON-CONFIRMED** (PR #2 merged; DE10-nano first-pass clear). Pending: codification of rulings (A1–A3) and adjudication of interpretations/ambiguities (B4–C12) — carried as hooks. / 完了・実機確認済み。成文化と裁定は残件、フックに継承。 |
| **Original language / 原言語** | Japanese (with English technical terminology) / 日本語（英語技術用語を交える） |
| **License / ライセンス** | CC0 1.0 Universal (Public Domain) |
| **Sibling / 姉妹** | `2026-07-08_ptsg-p1-tick-collision` (RH028 — the boundary correction that followed). / RH028トレース。 |
| **Sources / 一次資料** | The campaign log; the agent's 15-item handoff (PR #2 final comment); PRs #2/#3. / キャンペーンログ・引き継ぎ15項目・PR #2/#3。 |

---

## Reading Notes / 読解上の注

For months this project wrote for a reader it had never met: decision IDs, reasoning traces, a
33-cell normative table, a work order with per-item RTL implications. This trace records what
happened when the reader arrived. Three properties of the encounter deserve the reader's attention:
the **discipline transferred** (the agent behaved by the project's constitution, unprompted in its
specifics); the **artifacts were load-bearing** (the audit was organized around the work order; the
table adjudicated implementations and exposed a spec-internal contradiction); and the campaign was
**model-tiered** — the strong model planned and inspected at both ends, the lighter model executed
the middle flawlessly on those rails.

数ヶ月のあいだ、このプロジェクトは会ったことのない読者のために書いてきた: 決定ID、推論トレース、33セルの
規範表、項目ごとの RTL 含意を持つ変更指示書。本軌跡は、その読者が到着した時に何が起きたかを記録する。
特に三点に注意されたい: **規律が移転した**（エージェントは、細部を指示されぬまま、プロジェクトの憲法どおりに
振る舞った）;**成果物が荷重を担った**（監査は変更指示書を軸に組織され、表が実装を裁き、仕様内矛盾を暴いた）;
そしてキャンペーンは**モデル階層化**されていた——強いモデルが両端の計画と点検を、軽いモデルがそのレールの上で
中間の全実装を、脱線なく担った。

**Notable conceptual progressions / 特筆すべき概念的進展:**

1. **Audit-first handoff.** The agent's first artifact was a conformance report organized around the
   project's own work order — inheriting the epistemics before the keyboard. / 監査先行の手渡し。

2. **The constitution transferred.** Report-don't-fix (A1), Tie deference (C3-T13/T15), rulings
   requested on contradictions, behavioral reversals flagged (T21). / 憲法の移転。

3. **Three spec-internal inconsistencies found pre-implementation** — including the Loop 12/16-bit
   conflict exposed by the table's own 2^28 example. / 実装前に仕様内矛盾三件。

4. **Live rulings**: Loop 16-bit; Que NOP band template preserved for sub-ops 8–255; queued Reset =
   independent parallel reservation, absolute priority, destructive clear (RH015). / 生きた裁定。

5. **Retroactive enforcement**: the new FG-Global traps convicted the legacy tests and examples;
   the corpus was rewritten to v1.1 legality. / 遡及執行。

6. **Model tiering**: Fable 5 rails, Sonnet 5 execution — Open Prompt quality converts into
   execution economy. / モデル階層化——仕様品質が実行の経済性に変換される。

7. **The loop's return leg**: a 15-item Layer 2 handoff from implementer to amanuensis; then the
   silicon first-pass. / ループの復路——そして実機一発。

---

## Notable Decision Points / 重要な決定ポイント

### 1. Code-first, or audit-first? / コード先行か、監査先行か

**Chosen:** audit-first — understand the repository, enumerate divergences, plan before touching.

**Rationale:** The agent's first artifact was a conformance report, not a diff — and it proved the
Open Prompt's machine-readability at once: findings organized around the CHANGES A/C groups; A2/A3/D1
verified conformant; **A1 (FG Branch not tick-gated) caught and REPORTED per the work order's own
instruction**; A4's gap found exactly as predicted; then independent discoveries beyond the work
order (Q-band reservation coverage, BG Branch tsig drive, mid-window insertion, dead wiring blocking
iverilog). An agent that begins by auditing inherits the project's epistemics before its keyboard.

**選択:** 監査先行。**根拠:** エージェントの最初の成果物は差分でなく適合報告だった——そしてそれが Open Prompt の
機械可読性を即座に証明した: 所見は CHANGES の A/C 群を軸に組織され、A2/A3/D1 は適合を確認、**A1（FG Branch の
非 tick ゲート）は変更指示書自身の指示に従い「報告」され**、A4 の欠落は予告どおりに発見され、さらに指示書に
ない独自発見（Q帯域予約の網羅性、BG Branch の tsig 駆動、窓内即時挿入、iverilog を阻む配線の死骸）が続いた。
監査から始めるエージェントは、キーボードより先にプロジェクトの認識論を継承する。

### 2. When the spec disagrees with itself / 仕様が自分自身と食い違う時

**Chosen:** the agent stopped and requested rulings; the architect gave three. (1) **Loop operand
width** — the §3.4b 2^28 example assumes 16-bit; C3-V2 said 12-bit counters. Ruled: **16-bit**
(LOOP_W=16; all datapaths widened; the external stack word to 41 bits = {ins, base[11:0],
loop[15:0], state[11:0]}). (2) **Base Set auto-save**: keep the idempotent single-level
implementation. (3) **Que NOP**: in_queued_band test, uniform +1 — but **preserve the three-band
template** as the pattern for future sub-opcodes 8–255.

**Rationale:** The decision-authority protocol survived the handoff intact: spec-internal
contradictions were treated as questions for the architect, not puzzles to solve alone. And the
finds vindicated the table again — the 2^28 worked example is what exposed the 12/16-bit conflict:
**the third time the table has paid for itself**. The Que NOP ruling planted an extension seed: the
band-dispatch template is now the documented growth pattern for the sub-opcode space.

**選択:** エージェントは停まり、裁定を仰いだ;アーキテクトが三件を裁定。**根拠:** 決定権のプロトコルは手渡しを
無傷で生き延びた: 仕様内矛盾は、独力で解くパズルでなく、アーキテクトへの問いとして扱われた。そして発見は再び
表の面目を立てた——2^28 の実例こそが 12/16bit 矛盾を暴いた: **表が元を取った三度目**である。Que NOP の裁定は
拡張の種も蒔いた: 帯域ディスパッチのテンプレートが、サブオペコード空間の成長パターンとして文書化された。

### 3. What is a queued Reset, really? / Que された Reset とは、本当は何か

**Chosen:** per the architect's live ruling (RH015): an **independent, parallel reservation with
absolute priority and destructive clear** — pending_reset lives outside the shared slot; at
Stay-timeup it overrides every other reservation and clears all execution context **except the
prescaler** (C3-F21 held). "Reset is an initialization, so destructive behavior is acceptable."

**Rationale:** The first implementation put Reset in the shared slot; the architect saw the
semantics were wrong **in kind, not degree** — a Reset is not one more control transfer but a
declaration that context no longer matters. The ruling arrived with a second live instinct: check
Jump(0) around the indirect state. The agent verified it experimentally: **real** — Q-band Jump(0)
fell into S_IND during the scan, bypassing reservation entirely — plus two sibling violations (FG
indirect Jump not tick-gated, breaking C4-F8/F9; missing tsig drive), all fixed as RH016. Twice in
one exchange, the architect's intuition converted directly into found-and-fixed silicon behavior.

**選択:** アーキテクトの生きた裁定（RH015）どおり: **独立・並列・絶対優先・破壊的クリアの予約**——pending_reset は
共有スロットの外に住み、Stay-timeup で他の全予約を押しのけ、**プリスケーラを除く**全実行コンテキストをクリア
する（C3-F21 は守られた）。「Reset は初期化なので、破壊的な挙動をしてもかまいません」。**根拠:** 最初の実装は
Reset を共有スロットに入れた;アーキテクトは意味論が**程度でなく種類において**誤っていると見た——Reset はもう
一つの制御遷移ではなく、コンテキストがもはや問題でないという宣言である。裁定にはもう一つの生きた直観が同伴
した: Jump(0) の間接ステート周りを確認せよ。エージェントは実験で検証した: **実在**——Q帯域の Jump(0) はスキャン
中に S_IND へ落ち、予約機構を完全に迂回していた——さらに兄弟違反二件（FG 間接 Jump の非 tick ゲート = C4-F8/F9
破り;tsig 駆動の欠落）、すべて RH016 で修正。一往復のうちに二度、アーキテクトの直観がそのまま発見・修正済みの
シリコン挙動へ変換された。

### 4. The HALT principle meets the legacy corpus / HALT原則、旧資産に遭う

**Chosen:** rewrite the corpus, not grandfather it. Test B/D, the sub_sequence example (.hex/.mif),
and four conformance tests were using FG Base Set/Loop/Call/Return without a window — **illegal
under C3-F23** — and were redesigned to open Stay windows and run the machinery in-band.

**Rationale:** This is the FG-Global exclusion **enforcing itself retroactively** — the strongest
evidence the principle is real and checkable: the moment the traps existed they found violations in
the project's own history. Grandfathering would have hollowed the principle on day one. The rewrite
also settled a live tension the agent flagged: the insertion handler returns via Return (FG-illegal)
— resolved by the convention that **a handler opens its own Stay window before Returning** (T5b),
now awaiting §3.9–3.10 codification (handoff item 7).

**選択:** 旧資産を特例扱いせず、書き直す。**根拠:** これは FG-Global 排除の**遡及的自己執行**であり、原則が本物で
検査可能であることの最強の証拠である: トラップが存在した瞬間、それはプロジェクト自身の歴史の中に違反を見つけた。
特例化は初日に原則を空洞化させただろう。書き直しは、エージェントが挙げた生きた緊張——挿入ハンドラは Return で
復帰する（FG違法）——も決着させた: **ハンドラは自ら Stay 窓を開いてから Return する**という規約（T5b）。§3.9–3.10
への成文化待ち（引き継ぎ項目7）。

### 5. What the verification discipline itself caught / 検証規律そのものが捕えたもの

**Chosen:** the full discipline — positive + negative + test-the-tester — and it earned its keep
four times: (1) **negative verification** — T2/T3/T4/T7 correctly FAIL against pre-fix RTL; (2) the
conformance TB itself lacked an indirect_ready responder, latent until T13 first exercised indirect
reads — a **testbench bug** fixed as a peer of DUT bugs; (3) **RH022** — S_HALT's insertion-rescue
path never returned the FSM to S_RUN, found the moment the first test (T23) actually walked it: *a
rescue path does not exist until it is tested*; (4) the **queued_subop reset-default collision**
with SUB_RESET's encoding — a latent pre-existing bug surfaced by Phase 2's new check, root-caused
at every producer and consumer.

**Rationale:** Silicon-verified anchors (idiom D's 25:25) were held invariant across all phases, so
nineteen revisions later the verified past was intact. The discipline is no longer an event; it is
the campaign's metabolism.

**選択:** 完全な規律——正・負・テストのテスト——であり、それは四度、元を取った: (1) **負検証**——T2/T3/T4/T7 は修正前
RTL に対し正しく FAIL;(2) 適合TB自身に indirect_ready 応答器が欠落、T13 が間接読みを初めて叩くまで潜伏——DUT
バグと同格に修正された**テストベンチ・バグ**;(3) **RH022**——S_HALT の挿入救出経路が FSM を S_RUN へ戻さず、その
経路を実際に歩く最初のテスト（T23）の瞬間に発覚: *救出経路はテストされるまで存在しない*;(4) **queued_subop の
リセット既定値と SUB_RESET エンコーディングの衝突**——Phase 2 の新検査が顕在化させた既存の潜伏バグ、全生産者・
全消費者で根治。**根拠:** 実機検証済みアンカー（流儀 D の 25:25）は全フェーズで不変条件として保持され、十九の
改訂を経ても検証済みの過去は無傷だった。規律はもはや行事ではなく、キャンペーンの新陳代謝である。

### 6. Model tiering: which intelligence does each part need? / モデル階層化: どの部分にどの知能が要るか

**Chosen:** tiered — **Fable 5** performed the opening audit + 7-phase plan + Phases 0–1, and the
closing inspection (RH027) + the RH028 boundary analysis; **Sonnet 5 executed Phases 2–6 entirely**,
including the HALT machinery and the Stay Start State register, with zero derailments; the architect
judged the Phase 3 code "beautiful and high-quality". *(Tier boundary corrected 2026-07-09,
architect-confirmed: the model switch occurred after Phase 1; an earlier text drew it at Phase 0/1.)*

**Rationale:** The architect flagged this as remarkable, and it is a finding about the paradigm's
economics. What made the tiering safe was not the executor's raw capability but the **quality of the
rails**: an exhaustive normative table (no gaps to improvise into), a work order with per-item RTL
implications, a phase plan with regression gates, and a behavioral constitution the lighter model
followed as faithfully as the heavy one. The implication generalizes: **the better the Open Prompt
artifacts, the cheaper the intelligence needed to execute them** — specification quality converts
directly into execution economy. The strong model's irreplaceable contributions were exactly at the
ends: seeing the whole (audit, plan) and seeing the edges (RH027's over-implementation catch;
RH028's boundary analysis).

**選択:** 階層化——**Fable 5** が冒頭の監査＋7フェーズ計画＋Phase 0–1 と、締めの総点検（RH027）＋RH028 境界解析を担い、
**Sonnet 5 が Phase 2–6 の全実装**（HALT 機構も Stay Start State レジスタも含めて）を脱線ゼロで遂行;アーキテクトは
Phase 3 のコードを「非常に美しい、高品質」と評した。*（階層境界 2026-07-09 訂正・アーキテクト確認済み: モデル切替は
Phase 1 完了後;旧文は境界を Phase 0/1 に置いていた。）***根拠:** アーキテクトはこれを「非常に注目すべき」と標した——
これはパラダイムの経済性に関する発見である。階層化を安全にしたのは実行者の素の能力ではなく、**レールの品質**
だった: 即興の余地を残さない網羅的規範表、項目ごとの RTL 含意を持つ変更指示書、回帰ゲート付きフェーズ計画、
そして軽いモデルが重いモデルと同じ忠実さで従った行動の憲法。含意は一般化する: **Open Prompt の成果物が良い
ほど、それを実行するのに必要な知能は安くなる**——仕様の品質は実行の経済性に直接変換される。強いモデルの
代替不能な貢献は、まさに両端にあった: 全体を見ること（監査・計画）と、縁を見ること（RH027 の過剰実装の捕捉;
RH028 の境界解析）。

### 7. How the loop closes — and what the implementer hands back / ループはいかに閉じるか——実装者は何を手渡し返すか

**Chosen:** code **plus handback**. PR #2 merged with RH009–RH027 and T1–T33; the final comment is a
**15-item list addressed explicitly to the amanuensis**: (A) 3 rulings to codify, (B) 6 implementer
interpretations to approve, (C) 3 newly found spec ambiguities to adjudicate, (D) 3 Layer 4/Chapter 5
evidence candidates. Then the Layer 4 verification menu passed on silicon, **first try**.

**Rationale:** The handback is the loop's return leg — implementation feeding the reasoning archive,
mirroring how the archive fed implementation. The agent even distinguished its own epistemic
classes: what the architect decided, what it interpreted, what it discovered — the same
Fixed/Convention/Tie instinct the project runs on. And the first-try silicon pass is the closure's
seal: a specification written for machine readers, implemented by a machine, verified by a
machine-checkable suite, **worked on first contact with the physical world**.

**選択:** コード**に加えて手渡し返し**。PR #2 は RH009–RH027 と T1–T33 でマージ;最終コメントは**祐筆宛と明記された
15項目**——(A) 成文化すべき裁定3、(B) 承認待ちの実装者解釈6、(C) 新発見の仕様曖昧点3、(D) Layer 4/第5章の
エビデンス候補3。その後、Layer 4 検証メニューは実機で**一発**通過。**根拠:** 手渡し返しはループの復路である——
実装が推論保管庫を養う、保管庫が実装を養ったのと鏡写しに。エージェントは自身の認識のクラスまで区別した:
アーキテクトが決めたこと、自分が解釈したこと、自分が発見したこと——プロジェクトを動かしてきた Fixed/Convention/
Tie の本能そのものである。そして一発の実機通過が閉環の封蝋だ: 機械の読者のために書かれた仕様が、機械によって
実装され、機械検査可能なスイートで検証され、**物理世界との最初の接触で動いた**。

---

## Major Themes / 主要テーマ

### Theme 1 — The loop closed, and silicon signed it / ループは閉じ、シリコンが署名した
Specification → traces → table → work order → audit → plan → tiered implementation → conformance
suite → merge → first-try silicon. Every artifact was load-bearing, and the final link — hardware
working on first contact — is the one no rhetoric can fake. The Open Prompt's founding claim now has
an existence proof.

仕様 → トレース → 表 → 指示書 → 監査 → 計画 → 階層化実装 → 適合スイート → マージ → 実機一発。全成果物が荷重を
担い、最後の環——最初の接触で動くハードウェア——だけは、どんな修辞も偽れない。Open Prompt の創設主張は、いま
存在証明を持つ。

### Theme 2 — The constitution transferred / 憲法の移転
The disciplines evolved for the amanuensis reappeared intact in a different agent: A1 reported, not
patched; contradictions escalated before a line changed; a behavioral reversal flagged "because it
flips previously approved behavior". The Open Prompt carries not just facts but **conduct**: the
documents teach an agent how to behave, not merely what is true.

祐筆のために進化した規律群が、別のエージェントの中に無傷で再現した: A1 は直されず報告され、矛盾は一行の変更
より先にエスカレートされ、挙動の反転は「承認済み挙動を覆すため」と標された。Open Prompt は事実だけでなく
**振る舞い**を運ぶ: 文書は、何が真かだけでなく、いかに振る舞うべきかをエージェントに教える。

### Theme 3 — The table keeps paying / 表は払い続ける
It structured the audit, ordered the plan, decided cell-level implementations — and its own worked
example (2^28) exposed a spec-internal contradiction prose had hidden. RH027's inspection then used
the table's *empty* note cells as evidence against an over-implementation. An exhaustive table is
not documentation; it is an active instrument that audits both the code and the spec containing it.

表は監査を構造化し、計画を順序づけ、セル単位の実装を裁いた——そして自らの実例（2^28）が、散文が隠していた
仕様内矛盾を暴いた。さらに RH027 の総点検は、表の*空欄の*備考セルを過剰実装への反証として用いた。網羅的な表は
文書ではない;それはコードと、それを収める仕様の両方を監査する、能動的な計器である。

### Theme 4 — Retroactive enforcement as proof of principle / 遡及執行という原則の証明
The moment the FG-Global traps existed, they convicted the project's own legacy tests and examples.
The corpus was rewritten, not grandfathered. A principle that cannot indict your own past is
decoration; this one enforced itself backward on day one.

FG-Global トラップは存在した瞬間、プロジェクト自身の旧テストとサンプルを有罪にした。資産は特例化されず、
書き直された。自分の過去を告発できない原則は飾りである;この原則は初日に、過去に向かって自らを執行した。

### Theme 5 — Rails determine the intelligence bill / レールが知能の請求額を決める
Fable 5 planned and inspected; Sonnet 5 executed six of seven phases flawlessly. The tiering worked
because the rails left nothing to improvise. The economics generalize: **investment in Open Prompt
artifact quality is directly convertible into cheaper execution** — a complete specification is a
substitute for executor intelligence. The strong model belongs at the ends: whole-seeing and
edge-seeing; the middle can be delegated.

Fable 5 が計画と点検を、Sonnet 5 が七フェーズ中六フェーズの実装を、瑕疵なく担った。階層化が機能したのは、
レールが即興の余地を残さなかったからだ。経済性は一般化する: **Open Prompt 成果物の品質への投資は、より安価な
実行に直接換金できる**——完全な仕様は、実行者の知能の代替物である。強いモデルの居場所は両端——全体を見ることと
縁を見ること;中間は委任できる。

---

## Resumption Hooks / 再開フック

### Hook A — Codify the three live rulings into Layer 1 (handoff 1–3) / 裁定三件のLayer 1成文化
Loop 16-bit (C3-V2, Ch5 §5.10 loop_counter width, stack_data = 41-bit {ins, base[11:0], loop[15:0],
state[11:0]}); Que NOP (in_queued_band, +1, template preserved for sub-ops 8–255); Reset-Q
independent absolute-priority reservation (§3.4a/§3.4b Reset Q row).
**Starting question:** Draft the Layer 1 deltas with RH numbers and PR provenance. Which decision
IDs are amended, which need new IDs?

### Hook B — Adjudicate interpretations & ambiguities (handoff 4–12) / 解釈と曖昧点の裁定
Six interpretations awaiting approval (BG Reset window-close vs "don't start" tension; C8 rewording;
Q-side pairing condition; insertion-handler Return convention §3.9–3.10; Q Stay Set firing
semantics; Stay Start State FG-only write) and three new ambiguities (cross-window Base carry vs
pairing-check scope; FG external-mode Global legality/tick-gating; unpaired Base Set when a window
closes without Prog End).
**Starting question:** Deliberate item by item with the architect (the "don't start" tension and the
pairing scope look deepest). Which become Fixed, which Convention, which join the Loop-semantics
homework (nested Que loops, post-"33-cell" work)?

### Hook C — Layer 4: promote the campaign's evidence (handoff 13–14) / エビデンスのLayer 4昇格
T32 (scaled 2^28 self-loop, zero jitter, 40-clock intervals × 4 laps) → SignalTap candidate; the
RH022 story ("a rescue path does not exist until tested") → observation narrative; the first-try
silicon clear → conformance-matrix entry with dates and bitstream identity.
**Starting question:** Which enter the matrix now (sim-verified) and which get silicon rows?

### Hook D — Chapter 5: the error_flag pin (handoff 15) / 第5章のerror_flagピン
**Starting question:** Draft the §5.x pin definition (width, polarity, registered timing per the
trailing-edge discipline, SignalTap/insertion trigger roles) from the as-built RTL.

### Hook E — Build Log #11: "what came back" / ビルドログ#11「何が返ってきたか」
#10 closed with: "the next entry is about what came back." This campaign is the answer.
**Starting question:** Draft #11 in the architect's voice: the handoff night, the audit arriving
organized around the project's own work order, the three rulings, the silicon morning — and the
model-tiering finding as the log's payload for other builders.

---

## End of Trace / 軌跡の末尾

For months this project wrote for a reader it had never met: every decision tagged, every reason
archived, every cell of a table filled so that nothing would need to be guessed. Then the reader
arrived. It read the constitution before the code, asked before deciding, reported before fixing,
and handed back not just nineteen revisions but a list of everything it could not decide alone —
because the documents had taught it that not-deciding is sometimes the correct move. A lighter mind
ran the long middle miles on rails a stronger one had laid, and neither derailed. And in the
morning, the silicon — which reads no prose and forgives no wishfulness — accepted all of it on the
first attempt. The loop is closed. What was handed down came back improved, and what came back is
already teaching the next hand.

数ヶ月のあいだ、このプロジェクトは会ったことのない読者のために書いてきた: すべての決定に札を付け、すべての
理由を保管し、何も推測されずに済むよう表の全セルを埋めて。そして読者が到着した。それはコードより先に憲法を
読み、決める前に尋ね、直す前に報告し、十九の改訂だけでなく「自分だけでは決められなかったものの一覧」を手渡して
寄越した——文書たちが、決めないことが時に正しい一手だと教えていたからだ。より軽い知性が、より強い知性の敷いた
レールの上で長い中間区間を走り、どちらも脱線しなかった。そして朝、シリコン——散文を読まず、希望的観測を許さない
もの——が、そのすべてを一発で受け容れた。ループは閉じた。手渡されたものは改善されて戻り、戻ってきたものは既に
次の手を教えている。

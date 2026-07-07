# PTSG Stay Start State Register — Queued Time-Axis Loops, the 2^28 Pattern, and Queue Capacity
# PTSG Stay Start Stateレジスタ — Que時間軸ループ・2^28パターン・Que容量

## Trace Metadata / 軌跡メタデータ

| Field | Value |
|---|---|
| **Date / 日付** | 2026-07-06 |
| **Participants / 参加者** | Tsuneo Ohnaka (大中庸生, FPGA Architect, 40+ years; sole design authority); Claude (Anthropic, Claude Opus 4.8, amanuensis / 祐筆) |
| **Topic / トピック** | Filling the Q-band cells of the command × phase table forced the question: where does a **queued time-axis Loop return to?** Answer: a new register — **Stay Start State** — written by Stay Set with its own State Number. A queued Base Set loads the Base register from it. A jewel falls out: a single Stay period can loop on itself, giving **2^28 clocks** of exact timing with no prescaler. The same deliberation settled **queue capacity**: last-write-wins, except a State-Number-queue overwrite HALTs. / Que時間軸ループの帰還先=新レジスタStay Start State;2^28自己ループ;Que容量=後勝ち＋SN上書きHALT。 |
| **Status / 状態** | **ADOPTED, PROVISIONAL (仮確定)** — requires RTL (a same-cycle hand-off register, no stack-frame extension — Base-source mux, overwrite detection). Nested multi-booking = **open Tie**. Lifetime corrected 2026-07 (see DP-2). / 採択、仮確定。入れ子マルチブッキングは未決Tie。寿命は2026-07訂正（DP-2参照）。 |
| **Original language / 原言語** | Japanese (with English technical terminology) / 日本語（英語技術用語を交える） |
| **License / ライセンス** | CC0 1.0 Universal (Public Domain) |
| **Sibling / 姉妹** | `2026-07-06_ptsg-command-phase-table` (the table that forced these questions; the HALT error philosophy applied here). / 表トレース。 |
| **Forward / 前方** | Verification queue #4 (resolved here as last-write-wins). Queue #3 (two-level stack) is **not** affected — see the 2026-07 lifetime correction. / 検証キュー#4へ。#3は本レジスタの影響を受けない（2026-07寿命訂正参照）。 |

---

## Reading Notes / 読解上の注

Nobody set out to add a register. The Q-band Base Set cell demanded an answer — *base := what?* —
and every existing answer was wrong for the time axis. This trace records how one small register was
**found** in that empty cell, what it makes possible (a stay period that loops on itself,
five instructions, a quarter-billion clocks), and how the queue's capacity was ruled.

誰もレジスタを足そうとはしていなかった。Q 帯域の Base Set のセルが答えを要求し——*base := 何?*——既存の
どの答えも時間軸には誤りだった。本軌跡は、その空セルの中に小さなレジスタ一つが**見出された**経緯と、それが
可能にするもの（自分自身をループするステイ期間、命令五語、二億五千万クロック）、そして Que 容量の裁定を記録する。

**Notable conceptual progressions / 特筆すべき概念的進展:**

1. **The time axis needs its own "here".** Space-axis loops return to a State Number; time-axis
   loops must return to the start of a *stay period* — the moment Stay Set spoke. / 時間軸には固有の
   「ここ」が要る——Stay Set が発話した瞬間。

2. **Stay Start State register.** Written by FG Stay Set with its own SN; a **queued** Base Set
   loads Base from it (BG Base Set keeps base := current SN — space axis). / 新レジスタ。Que の
   Base Set はここから Base をロード。

3. **Same-cycle hand-off, reset-0, Core-invisible (corrected 2026-07).** It is valid only within the
   Stay cycle in which Stay Set wrote it: a (queued) Base Set executing in that cycle carries it into
   the Base register, discharging it; otherwise the next Stay Set overwrites it. No stack involvement —
   carrying a target across many Stay periods to a distant Loop remains the Base register's own
   existing role. A Formation may copy Stay Start State out for visibility. / 同一サイクル引き渡し・
   リセット0・Core不可視（2026-07訂正）。Stay Set が書いたのと同じ Stay サイクル内でのみ有効: そのサイクル内で
   （Que の）Base Set が実行されれば Base レジスタへ運ばれ用済みに;さもなければ次の Stay Set が上書きする。
   スタックへの関与なし——多数の Stay を跨いで遠い Loop へ標的を運ぶのは Base レジスタ既存の役割のまま。
   Formation はコピーして可視化できる。

4. **The 2^28 pattern.** `StaySet → ProgEnd → BaseSet(Q) → Loop-65536(Q) → Stay-4096`: one stay
   period looping on itself — 12-bit Stay × 16-bit Loop = 2^28 clocks, prescaler-free, exact. /
   2^28 パターン。

5. **Queue capacity: last-write-wins; SN-overwrite HALTs.** Priority arbitration rejected
   (cannot rescue a violated program; costs resources and Fmax on the timeup path). / Que 容量:
   後勝ち;SN 上書きは HALT。

6. **Nested multi-booking = open Tie.** Forbid (simple) vs handle beautifully (the 2^44-class
   temptation). / 入れ子マルチブッキングは未決 Tie。

---

## Notable Decision Points / 重要な決定ポイント

### 1. Where does a queued Loop return to? / Que の Loop はどこへ戻るか

**Alternatives:** (a) the current State Number (space-axis semantics); (b) the start of the stay
period, via a new register. **Chosen:** (b) — **Stay Start State**: FG Stay Set writes its own SN
there; a queued Base Set sets Base := Stay Start State.

**Rationale:** A time-axis loop repeats a *structure* — StaySet, its window, its Stay — not an
instruction position. The only address that names that structure is where it began: the Stay Set's
own state. The current SN during the Q-band scan points into the window's interior, which is not a
repeatable origin. One new register, written by a command that already exists, gives queued loops a
correct landing site with no new opcode — composition over addition, again. In-window (BG) Base Set
keeps the space-axis semantics: base := current SN.

**代替案:** (a) 現在の State Number（空間軸意味論）;(b) 新レジスタ経由でステイ期間の起点。**選択:** (b)——
**Stay Start State**: FG Stay Set が自身の SN を書き込み、Que の Base Set が Base := Stay Start State とする。
**根拠:** 時間軸ループは*構造*——StaySet・その窓・その Stay——を反復するのであって、命令位置ではない。その構造を
名指す唯一の番地は、それが始まった場所: Stay Set 自身のステートである。Q 帯域スキャン中の現 SN は窓の内部を
指しており、反復可能な起点ではない。既存コマンドが書き込む新レジスタ一つが、新オペコードなしで Que ループに
正しい着地点を与える——ここでもまた、追加ではなく合成。窓内（BG）の Base Set は空間軸意味論（base := 現 SN）を保つ。

### 2. Lifetime, hand-off, reset, visibility / 生存期間・引き渡し・リセット・可視性

> **Correction (2026-07) / 訂正（2026-07）:** the architect's first account of this decision point —
> recorded below as it was originally stated — described the register as long-lived, surviving many
> Stay periods until the matching Loop, stacked on nesting. On review, this was found to **conflate
> the new register with the Base register's own established role**. The corrected decision follows;
> the withdrawn alternative is kept visible for the record.
>
> アーキテクトの当初の説明——以下に原文のまま記す——は本レジスタを、対応する Loop まで多数の Stay 期間を
> 生き延び入れ子でスタックされる長寿命のものと述べた。レビューの結果、これは**新レジスタを Base レジスタ
> 自身の既存の役割と混同していた**と判明した。訂正後の決定を以下に示す;撤回された代替案も記録として残す。

**Alternatives:** (a) short-lived (cleared at timeup); (b) *[withdrawn]* long-lived, surviving across
many Stay periods until the matching Loop, stacked on nesting — the architect's initial statement,
later found to conflate this register with the Base register's own role; (c) **same-cycle hand-off
(adopted)** — valid only within the Stay cycle in which Stay Set wrote it: a (queued) Base Set
executing in that same cycle carries the value into the Base register, discharging the new
register's job; if no Base Set executes, the next Stay Set simply overwrites it. Carrying a target
across many Stay periods to a distant Loop remains the Base register's own long-standing role
(including its stack push/pop on nesting) — unchanged and undisturbed by this register.

**Chosen:** (c), same-cycle hand-off. Reset value 0. No Core-level external visibility; a Formation
may copy it to a general register.

**Rationale:** The architect's first account of this register's lifetime — surviving across many
Stay periods until the matching Loop, stacked on nesting — was withdrawn on review as a conflation
with the Base register's own role, which *already* carries a loop target across an arbitrary number
of Stay periods and *already* survives nesting via the existing holding-register stack. Once that
duty is recognized as already and properly owned by Base, Stay Start State's job shrinks to exactly
the gap Base cannot fill on its own: naming the time-axis origin (the Stay Set's own State Number)
at the one instant Base needs it — the moment a queued Base Set asks. A same-cycle hand-off is
sufficient, and is in fact simpler: no stack-frame member, no nested-context POP, no multi-Stay
survival logic. **Tellingly, the authored table's own entry for queued Base Set ("sets Base :=
Stay Start State register") already described exactly this hand-off, at the moment of Base Set's
execution — the table was correct before the narration was.** This is the same shape as the sibling
trace's C4-F10 finding: the artifact (RTL there, the table here) was ahead of the sentence describing
it; correcting the sentence is not correcting the design.

**代替案:** (a) 短命（timeup でクリア）;(b) *[撤回]* 対応する Loop まで多数の Stay 期間を生き延び入れ子で
スタック——アーキテクトの当初の説明、後に Base レジスタ自身の役割との混同と判明;(c) **同一サイクル引き渡し
（採用）**——Stay Set が書いたのと同じ Stay サイクル内でのみ有効: そのサイクル内で（Que の）Base Set が
実行されれば値は Base レジスタへ運ばれ、新レジスタの仕事は済む;Base Set が実行されなければ次の Stay Set が
単に上書きする。多数の Stay を跨いで遠い Loop へ標的を運ぶのは、Base レジスタ既存の役割（入れ子でのスタック
push/pop を含む）のまま——本レジスタに乱されず不変。

**選択:** (c) 同一サイクル引き渡し。リセット値 0。Core レベルの外部可視性なし;Formation は汎用レジスタへ
コピー可。**根拠:** アーキテクトの当初の説明——対応する Loop まで多数の Stay 期間を生き延び入れ子でスタック——は
レビューで、Base レジスタ自身の役割との混同と判明し撤回された。Base は*既に*任意個数の Stay 期間を跨いで
ループ標的を運び、既存の holding-register スタックで入れ子も*既に*生き延びる。その務めが既に正しく Base に
属すると認識された途端、Stay Start State の仕事は、Base が自力で埋められない隙間——Base がそれを必要とする
まさにその瞬間（Que の Base Set が尋ねる瞬間）に時間軸の起点（Stay Set 自身の State Number）を名指すこと——
だけに縮む。同一サイクル引き渡しで十分であり、実際より単純である: スタックフレームのメンバーなし、入れ子
コンテキストの POP なし、多 Stay 生存ロジックなし。**特筆すべきは、起草済みの表の Que Base Set の項目
（「Base := Stay Start State レジスタをセット」）が、Base Set 実行の瞬間という、まさにこの引き渡しを最初から
記していたことである——表は、ナレーションより先に正しかった。** これは姉妹トレースの C4-F10 の発見と同じ
かたち: 成果物（そちらでは RTL、こちらでは表）が、それを記述する文より先を行っていた;文を訂正することは
設計を訂正することではない。

### 3. The smallest thing it enables — the 2^28 pattern / 最小の可能性——2^28 パターン

**Alternatives:** (a) only distant multi-Stay loops pay off; (b) **a single stay period looping on
itself**. **Chosen:** both — and the self-loop is the jewel.

**Rationale:** Because the queued Base Set reads Stay Start State, the loop target can be the stay
period *that contains the Loop itself* — impossible with SN-based bases. The pattern:

```
StaySet → ProgEnd → BaseSet(Q) → Loop-65536(Q) → Stay-4096
```

Stay's 12-bit operand × Loop's 16-bit operand = **2^28 clocks ≈ 268M clocks ≈ 5.4 s at 50 MHz**,
timed exactly, prescaler-free, in five instructions. This extends the duty-idiom lesson —
expressivity lives in placement, not primitives — into the large: a 28-bit timer emerges from a
12-bit one and a 16-bit one composed through the queue. (The architect: "it makes you want GUI
programming" — the piano-roll IDE pull strengthens.)

**代替案:** (a) 遠距離の多 Stay ループのみが利得;(b) **一つのステイ期間が自分自身をループ**。**選択:** 両方——
そして自己ループが宝石。**根拠:** Que の Base Set が Stay Start State を読むため、ループ標的は *Loop 自身を
含むステイ期間*であり得る——SN ベースでは不可能。パターンは上記のとおり、Stay の 12bit × Loop の 16bit =
**2^28 クロック ≈ 2.68 億クロック ≈ 50 MHz で 5.4 秒**、正確に、プリスケーラなしで、命令五語。デューティ流儀の
教訓——表現力はプリミティブでなく置き方に宿る——を大に延長する: 28bit のタイマが、12bit と 16bit をキュー越しに
合成して立ち上がる。（アーキテクト:「GUI プログラミングがしたくなってきますね」——ピアノロール IDE の引力が強まる。）

### 4. Queue capacity / Que 容量

**Alternatives:** (a) priority arbitration among Branch/Jump/Return/Call/Loop; (b) multi-entry
queue memory; (c) **last-write-wins + State-Number-queue overwrite detected → HALT + error flag**.
**Chosen:** (c).

**Rationale:** Priority was weighed and rejected on two grounds: it cannot actually rescue the
program (whichever entry loses, intent is already violated — priority merely picks *which*
violation), and it costs resources and Fmax on the timeup path — the very path the registered tick
(Build Log #9) had just cleaned. Last-write-wins keeps the queue a single register. But silently
discarding a queued *State-Number* reservation is the worst failure mode: the discarded jump's
absence lets execution "run considerably wild" downstream, far from the cause. So the sibling
trace's error philosophy applies: SN-reservation overwrite = structural violation = **HALT +
flag**, scene preserved. (Initially weighed as a non-fatal error-out; the architect tightened it to
HALT precisely because of the chained-consequence risk.)

**代替案:** (a) Branch/Jump/Return/Call/Loop 間の優先順位調停;(b) 複数エントリのキューメモリ;(c) **後勝ち＋
State Number Que の上書き検出 → HALT＋エラーフラグ**。**選択:** (c)。**根拠:** 優先順位は検討の上棄却——
プログラムを実際に救えない（どちらが負けても意図は既に破られており、優先順位は*どの*違反にするかを選ぶだけ）、
かつ timeup 経路——Build Log #9 の叩いたティックが掃除したばかりのその経路——に資源と Fmax のコストを載せる。
後勝ちはキューを単一レジスタに保つ。だが Que された *State Number* 予約の黙った破棄は最悪の故障モードである:
破棄されたジャンプの不在が、原因から遠い下流で実行を「かなり荒ぶらせる」。ゆえに姉妹トレースの誤り哲学が適用
される: SN 予約の上書き = 構造違反 = **HALT＋旗**、現場保存。（当初は非致命のエラー出力も検討されたが、連鎖的
帰結のリスクゆえアーキテクトが HALT へ引き締めた。）

### 5. Nested multi-booking — open Tie / 入れ子マルチブッキング——未決 Tie

**Alternatives:** (a) forbid (simple, matches the single-register queue); (b) support elegantly —
`StaySet → ProgEnd → BaseSet → BaseSet → Loop-65536 → Loop-65536 → Stay-4096`, nested self-loops of
the 2^44 class. **Chosen:** deferred as a **Tie**.

**Rationale:** The Tie is genuine: the simple rule matches last-write-wins, while the beautiful rule
needs Q-band reservation stacking whose cost is unmeasured. "PTSG-ishly, handling this beautifully
is a temptation" (the architect). Per the Tie discipline, both alternatives stand recorded until the
cost side is known — a QUEUE_DEPTH parameter may be the same move as the debuggability
parameterization noted in the sibling trace.

**代替案:** (a) 禁止（単純、単一レジスタと整合）;(b) 美しく対応——`StaySet → ProgEnd → BaseSet → BaseSet →
Loop-65536 → Loop-65536 → Stay-4096`、2^44 級の入れ子自己ループ。**選択:** **Tie** として保留。**根拠:** 本物の
引き分けである: 単純則は後勝ちと整合し、美しい則は費用未計測の Q 帯域予約スタックを要する。「PTSG的にはこれを
うまく処理できるのは美しいという欲がある」（アーキテクト）。Tie 規律に従い、費用側が判明するまで両代替案を記録の
まま立たせる——QUEUE_DEPTH パラメータは、姉妹トレースのデバッガビリティ・パラメータ化と同じ一手かもしれない。

### 6. Forward: the queue as a data path (Formation) / 前方: データパスとしてのキュー（Formation）

**Chosen:** recorded as a Formation-side forward link (not a Core change): **queue copy to general
registers** would let timing signals be driven by computation results.

**Rationale:** The queue's essence is "a value that takes effect at a time boundary" — exactly what
a computed timing output needs. Placing the copy in the Formation keeps the Core queue minimal while
opening arithmetic-driven timing (e.g. measured-latency-compensated pulse placement).

**選択:** Formation 側の前方リンクとして記録（Core 変更ではない）: **キューの汎用レジスタへのコピー**により、
演算結果に基づくタイミング信号出力が可能になる。**根拠:** キューの本質は「時間境界で効力を持つ値」——それは
計算されたタイミング出力がまさに必要とするもの。コピーを Formation に置けば Core キューは最小のまま、
演算駆動タイミング（例: 実測レイテンシ補償のパルス配置）への扉が開く。

---

## Major Themes / 主要テーマ

### Theme 1 — A register born from a question the table asked / 表が発した問いから生まれたレジスタ
Nobody set out to add a register. The Q-band Base Set cell demanded "base := what?", and every
existing answer was wrong for the time axis. The Stay Start State register is the minimal object
that makes the cell answerable — the healthy direction of feature growth: not capability sought,
but a hole in the semantics plane that had to be filled.

誰もレジスタを足そうとしなかった。Q 帯域 Base Set のセルが「base := 何?」を要求し、既存のどの答えも時間軸には
誤りだった。Stay Start State はそのセルを回答可能にする最小の対象——機能成長の健全な方向: 能力を求めたのでなく、
埋めねばならない意味論の面の穴が先にあった。

### Theme 2 — The time axis gets its own "here" / 時間軸が固有の「ここ」を得る
The space axis names positions by State Number; the time axis's natural unit is the stay *period*,
and its origin is where Stay Set spoke. The new register is a program counter for periods rather
than instructions. Queued Base Set/Loop become the time-axis mirror of the space-axis loop
machinery — same commands, different notion of "here", selected by band.

空間軸は位置を State Number で名指す; 時間軸の自然単位はステイ*期間*であり、その起点は Stay Set が発話した
場所である。新レジスタは、命令でなく期間のプログラムカウンタ。Que の Base Set/Loop は空間軸ループ機構の時間軸の
鏡になる——同じコマンド、異なる「ここ」、帯域で選択される。

### Theme 3 — 2^28 from five instructions: composition at scale / 命令五語からの 2^28: スケールする合成
The duty idioms showed expressivity-by-placement in the small; the self-looping stay period shows it
at scale: 12-bit × 16-bit composing into a 28-bit exact timer, prescaler-free. No new counter was
built; the composition was unlocked by one register that lets a period aim at itself. **The
arithmetic of PTSG's minimalism is multiplicative, not additive.**

デューティ流儀は「置き方による表現力」を小で示した; 自己ループするステイ期間はそれを大で示す: 12bit × 16bit が
28bit の正確なタイマへ合成される、プリスケーラなしで。新しいカウンタは作られていない; 期間が自分自身を狙える
ようにするレジスタ一つが合成を解錠した。**PTSG の極小主義の算術は加法でなく乗法である。**

### Theme 4 — Arbitration rejected on Fmax grounds: the #9 sensibility / Fmax を理由に調停を棄却: #9 の感性
Priority arbitration was rejected partly because it loads the timeup path — the path the registered
tick (Build Log #9) had just cleaned. Correctness arguments sufficed, but the Fmax argument arrived
first-class. **Timing-path hygiene has become a standing criterion, not an afterthought.**

優先順位調停は、timeup 経路——Build Log #9 の叩いたティックが掃除したばかりの経路——に負荷を載せることも理由に
棄却された。正しさの論証で足りたが、Fmax の論証が第一級で到着した。**タイミング経路の衛生は、後付けでなく
常設の判断基準になった。**

### Theme 5 — Severity calibrated by consequence distance / 帰結距離で較正される深刻度
Why does an SN-queue overwrite HALT while last-write-wins is otherwise tolerated? Because severity
is calibrated by how far the consequence lands from the cause. A discarded SN reservation detonates
downstream where the trigger is unfindable; a replaced non-SN value fails near its use. **The longer
the causal chain from violation to symptom, the stronger the case for halting at the violation.**

なぜ SN-Que の上書きは HALT で、他の後勝ちは許容されるのか。深刻度は、帰結が原因からどれだけ遠くに着弾するかで
較正されるからだ。破棄された SN 予約は引き金の見つからない下流で爆発する; 置き換えられた非 SN 値はその使用点の
近くで失敗する。**違反から症状までの因果連鎖が長いほど、違反地点で止める理由は強くなる。**

---

## Resumption Hooks / 再開フック

### Hook A — RTL: the register and the mux (no stack change) / RTL: レジスタとマルチプレクサ（スタック変更なし）
**Starting question:** In `ptsg_core.v`, add `stay_start_state` as a plain register (no stack entry);
write it in SUB_STAYSET (FG path); mux the SUB_BASESET base source by band (Q: Stay Start State,
discharging the register for that cycle; BG: current SN). Confirm no change is needed to the
existing context-save/restore (holding-register) stack — Stay Start State's lifetime never crosses a
save/restore boundary in a way that would require it to be pushed. Does verification-queue #3's
two-level test need any change? (Expected: no.)

### Hook B — Conformance item: the 2^28 pattern (scaled) / 適合項目: 2^28 パターン（縮小版）
**Starting question:** Build the scaled self-loop item (e.g. Loop-4 × Stay-8): predict the exact
total duration (iterations × Stay ticks × PRESCALE + startup), run white-box, verify the queued
Base Set landed on the Stay Set state each iteration. What does the `expected.md` look like?

### Hook C — Resolve the nested multi-booking Tie / 入れ子マルチブッキング Tie の解決
**Starting question:** Estimate the LE/Fmax cost of a two-deep Q-band reservation stack on
Cyclone V. Does a QUEUE_DEPTH parameter (default 1) satisfy both camps, and how does it interact
with the overwrite-HALT rule?

### Hook D — Formation: queue copy to general registers / Formation: キューの汎用レジスタコピー
**Starting question:** Sketch the mechanism — which queue fields are copied, at what edge
(trailing, per doctrine), and what is the first demonstrator (e.g. a measured-latency-compensated
pulse)?

### Hook E — The piano-roll pull, strengthened / 強まるピアノロールの引力
**Starting question:** In a piano-roll IDE, how is a self-looping stay period drawn — a repeat
bracket over one bar? How do nested repeats (if the Tie resolves toward elegance) map to nested
brackets, and what does the 2^28 pattern look like on screen?

---

## End of Trace / 軌跡の末尾

Every loop needs a place called "back". On the space axis, "back" is an address; on the time axis,
it turned out to be a moment — the instant a Stay Set spoke and a period began. One small register
remembers that moment, and with it the queue learned to aim loops at periods instead of positions: a
stay period can now hold itself by the hand and go around again, sixty-five thousand times, five
instructions wide, a quarter-billion clocks deep. The register was not invented; it was found,
sitting in an empty cell of a table, waiting for someone to ask where a queued loop goes home to.

あらゆるループには「戻る場所」が要る。空間軸では、それは番地だった; 時間軸では、それは瞬間だと判明した——
Stay Set が発話し、期間が始まったその瞬間。小さなレジスタ一つがその瞬間を覚え、それによってキューはループを
位置でなく期間へ向けることを学んだ: ステイ期間はいま、自分の手を取ってもう一周できる——六万五千回、命令五語の
幅で、二億五千万クロックの深さまで。このレジスタは発明されたのではない; 見出されたのだ——表の空白のセルに
座って、Que のループはどこへ帰るのかと誰かが問うのを待ちながら。

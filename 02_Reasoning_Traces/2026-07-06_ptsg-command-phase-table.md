# PTSG Command × Execution-Phase Table — The FG-Global Exclusion Principle and Error HALT
# PTSGコマンド×実行フェーズ表 — FG-Global排除原則とError HALT

## Trace Metadata / 軌跡メタデータ

| Field | Value |
|---|---|
| **Date / 日付** | 2026-07-06 |
| **Participants / 参加者** | Tsuneo Ohnaka (大中庸生, FPGA Architect, 40+ years; sole design authority; **author of the behavior table**); Claude (Anthropic, Claude Opus 4.8, amanuensis / 祐筆 — template design, RTL cross-checking) |
| **Topic / トピック** | Before the Claude Code handoff, the architect defined the complete 11-command × 3-phase (FG/BG/Q) normative behavior table — Stay counter, timing signals, prescaler tick, **State Number** per cell. Filling the plane surfaced the **FG-Global exclusion principle** (Globals do not run in the foreground, except Reset / Stay Set / NOP) and the **Error HALT** runaway-detection mechanism. A specification error in C4-F10 was caught and corrected. / 全コマンド×全フェーズの規範表の確定。FG-Global排除原則とError HALTが立ち上がり、C4-F10の仕様誤りを訂正。 |
| **Status / 状態** | **ADOPTED** as the normative table (Layer 1 write-back in the same push); items requiring new RTL (HALT, traps, band-crossing checks) are **PROVISIONAL (仮確定)**. / 規範表として採択;新規RTL項目は仮確定。 |
| **Original language / 原言語** | Japanese (with English technical terminology) / 日本語（英語技術用語を交える） |
| **License / ライセンス** | CC0 1.0 Universal (Public Domain) |
| **Sibling / 姉妹** | `2026-07-06_ptsg-stay-start-state-register` (the new register and queue capacity, decided in the same deliberation). / 同じ協議から生まれた新レジスタとQue容量。 |

---

## Reading Notes / 読解上の注

Every prior verification had defined command behavior point-wise, as needed. This trace records the
moment the plane was filled: an architect-authored table in which **every cell is either defined or
explicitly illegal**. The table was built to record decisions; its first effect was to *generate*
them — in the architect's words, "because it was so clear, previously invisible design questions
became visible."

これまでの検証はコマンド挙動を必要に応じ点として定義してきた。本軌跡は面が埋められた瞬間を記録する:
**全セルが定義済みか明示的に違法か**のいずれかである、アーキテクト起草の表。表は決定を記録するために
作られたが、その最初の効果は決定を*生み出す*ことだった——アーキテクトの言葉では「非常にわかりやすかった
がゆえに、今まで見えていなかった検討課題が良く見えた」。

**Notable conceptual progressions / 特筆すべき概念的進展:**

1. **Fill the plane before implementing.** Gaps left undefined would be filled by an implementing
   agent's inference — a faithful implementation requires an explicit plane. / 実装前に面を埋める。

2. **A spec error caught by the table.** C4-F10's "counting begins at Prog End" contradicted both
   the table and the RTL (RH003/004/005); corrected to: Stay Set arms **and starts**, counting
   continues On-Tick through the window, Stay never clears. / 表がC4-F10の仕様誤りを捕捉・訂正。

3. **Illegality + HALT over assigned meanings.** Unused or inferior combinations are declared
   illegal; encountering one halts the machine with an error flag — for debuggability and
   programming simplicity. / 意味付与でなく違法化＋HALT。

4. **The FG-Global exclusion principle.** Only Reset, Stay Set, NOP may run in the foreground;
   Base Set / Return / Call / Loop / Prog End are window-only. Time/space separation becomes an
   enforced band legality. / FG-Global排除原則。時間/空間分離が帯域合法性として強制される。

5. **The exceptions carry justifications** — Reset (the strong will to return to the origin),
   Stay Set (controls the phase transition itself), NOP (immediate voiding) — PTSG's **second
   principle-with-exceptions structure**, with the same cast as the trailing-edge doctrine's. /
   例外は理由を帯びる——二つ目の「原則＋例外」構造。

6. **A structural bonus:** the D16–D31 operand-vs-timing-signal ambiguity dissolves, because
   extended-operand Globals are now legal only in bands where timing signals are Held. /
   帯域設計がD16-31二重用途を構造的に解消。

---

## Notable Decision Points / 重要な決定ポイント

### 1. Define the full plane now, or let the implementer fill gaps? / 面を今埋めるか、実装者に推測させるか

**Alternatives:** (a) defer — implement from the point-wise definitions; (b) complete the plane
first, architect-authored. **Chosen:** complete the plane first.

**Rationale:** Point-wise definitions leave gaps an implementing agent would fill by inference —
and inferred semantics can silently violate the trailing-edge doctrine or the band model. The table
makes every gap visible as an empty cell, forcing each to be decided or declared illegal. Making
the plane explicit is the precondition for a faithful implementation.

**代替案:** (a) 先送り——点定義から実装;(b) 面を先に完成、アーキテクト起草。**選択:** 面を先に。
**根拠:** 点定義の隙間は実装エージェントが推論で埋める——推論された意味論は後縁主義や帯域モデルを静かに
破り得る。表は全ての隙間を空セルとして可視化し、各々に決定か違法宣言かを強いる。面の明示が忠実な実装の
前提条件である。

### 2. Spec vs table/RTL on when counting starts — which is true? / カウント開始の仕様と表・RTLの矛盾——どちらが真か

**Alternatives:** (a) spec is right (counting begins at Prog End); (b) table and RTL are right
(counting starts at Stay Set). **Chosen:** (b). C4-F10's wording is corrected: **Stay Set arms and
starts the count; it continues On-Tick through the window; the Stay instruction never clears it.**

**Rationale:** The committed RTL settled it — RH003 explicitly refuses to clear `stay_cnt` in
OP_STAY ("may have already started counting in StaySet"); RH004/005 increment on
`window_open && presc_tick`. The silicon-verified idiom-D behavior is StaySet-origin counting. The
jitter-freedom C4-F10 exists for comes from **tick-based counting on the free-running grid**
(timeup = Nth tick after Stay Set, independent of the window's clock-length) — not from a Prog End
origin. The erroneous sentence was introduced by the amanuensis in the v1.1 write-back and carried
a silicon-confirmed label; recorded openly per the negative-data discipline. **Lesson: a spec
sentence, however plausible, must be diffed against the as-built source before being carved as
Fixed.**

**代替案:** (a) 仕様が正（Prog End 開始）;(b) 表とRTLが正（Stay Set 開始）。**選択:** (b)。C4-F10 を訂正:
**Stay Set がアームし開始;窓を通して On-Tick で継続;Stay 命令は決してクリアしない。** **根拠:** コミット済み
RTL が決着させた——RH003 は OP_STAY での `stay_cnt` クリアを明示的に拒み（「StaySet で既にカウント開始して
いる可能性がある」）、RH004/005 は `window_open && presc_tick` でインクリメント。実機検証済みの流儀 D は
StaySet 起点カウントである。C4-F10 が存在する理由たるジッタ無縁性は、**自由走行グリッド上の tick 基準
カウント**（timeup = Stay Set 後の第 N tick、窓のクロック長から独立）に由来し、Prog End 起点に由来しない。
誤文は祐筆が v1.1 書き戻しで導入し、実機確認済みラベルを帯びていた;負データ規律に従い公に記録。
**教訓: 仕様文は、どれほど尤もらしくとも、Fixed として刻む前に as-built ソースと突き合わせよ。**

### 3. Illegal combinations: assign meanings, or declare illegality and stop? / 違法な組み合わせ——意味を与えるか、違法化して止めるか

**Alternatives:** (a) every combination gets a meaning (stray Prog End = harmless NOP, etc.); (b)
declare illegality; on encounter, **HALT with an error flag**. **Chosen:** (b).

**Rationale:** Two forces, one conclusion. **Debuggability:** an undetected structural violation
(e.g. a Base Set whose Loop never comes) lets unintended behavior *chain* — by the time it is
observed, the triggering site is far away and hard to locate; halting at the violation pins the
evidence to the scene. **Simplicity:** assigning meanings to every illegal cell was "extremely
laborious" to design and would complicate PTSG programming. Refusing to give meaning is itself the
simplification: for what is unused or has a better alternative, declare it illegal without
hesitation and stop. The earlier "blank shot = no effect" reading of a stray Prog End is superseded
by HALT.

**代替案:** (a) 全組合せに意味（迷子 Prog End = 無害な NOP 等）;(b) 違法宣言、遭遇時 **HALT＋エラーフラグ**。
**選択:** (b)。**根拠:** 二つの力、一つの結論。**デバッガビリティ:** 未検出の構造違反（Loop が来ない Base Set 等）
は意図しない動作を*連鎖*させる——観測される頃には引き金の現場は遠く、特定困難;違反地点での停止が証拠を現場に
留める。**単純性:** 全違法セルへの意味付与は設計が「非常に大変」で、プログラミングをややこしくする。意味を
与えないこと自体が単純化である: 使わないもの・より良い方法があるものは遠慮なく違法とし、止める。迷子 Prog End の
旧解釈「空砲（効力なし）」は HALT に置き換えられる。

### 4. Which Globals may run in the foreground? / どの Global が前景実行できるか

**Alternatives:** (a) all; (b) **none, except three justified exceptions**. **Chosen:** the
FG-Global exclusion principle — Reset, Stay Set, NOP only.

**Rationale:** This is time-axis/space-axis separation sharpened into band legality: state-control
machinery (loops, calls, returns, bases) is kept OUT of the time-domain foreground, so the
foreground expresses only Stay-based timing and Branch/Jump transitions. With Branch/Jump also
usable in BG/Q, a disciplined program's foreground reads as a **bare enumeration of Stay times** —
the timing chart is the visible text. Each exception carries its justification: **Reset** — the
strong will to return to the origin even at the cost of continuity; **Stay Set** — it controls the
phase transition itself; **NOP** — the immediate, cheap voiding of any command. This is PTSG's
second principle-with-exceptions structure, and the cast overlaps the trailing-edge doctrine's
(Reset and Stay Set appear in both — the commands that mark *beginnings*). Structural bonus: the
D16–D31 dual-use ambiguity dissolves — extended-operand Globals now live only in bands where
timing signals are Held.

**代替案:** (a) 全て;(b) **三つの正当化された例外を除き、なし**。**選択:** FG-Global 排除原則——Reset・
Stay Set・NOP のみ。**根拠:** 時間軸/空間軸分離を帯域合法性へ研いだもの: 状態制御機構（ループ・コール・
リターン・ベース）を時間領域の前景から締め出し、前景は Stay タイミングと Branch/Jump 遷移のみを表現する。
Branch/Jump を BG/Q でも使えるようにしたことで、規律あるプログラムの前景は **Stay 時間の裸の羅列**として
読める——タイミングチャートがそのまま可視のテキストになる。各例外は理由を帯びる: **Reset**——動作連続性を
無視してでも起点に戻す強い意志;**Stay Set**——フェーズ移行そのものの制御;**NOP**——あらゆるコマンドの即時的で
手軽な無効化。これは PTSG の二つ目の「原則＋例外」構造であり、顔ぶれは後縁主義のそれと重なる（Reset と
Stay Set が両方に登場——*始まり*を標す命令たち）。構造的な副産物: D16–D31 の二重用途曖昧性が解消——拡張
オペランド Global はタイミング信号が Held の帯域にのみ住む。

### 5. HALT mechanics — escape, visibility, placement / HALT の機構——脱出・可視性・所属

**Alternatives:** (a) silent halt, hardware-reset-only, Formation-optional; (b) observable and
recoverable, Core-mandatory for the riskiest checks. **Chosen:** (b).

**Rationale:** An **error-flag output port** turns a halt into an instrument: SignalTap triggers on
it (the capture shows the scene), and a Formation can wire it to the insertion mechanism. Escapes:
hardware reset; **ISMCE real-time rewriting** (NOP-out the offending word, patch a Jump) — uniquely
PTSG-ish, since behavior lives in editable memory a halted core can be repaired live over JTAG;
insertion. On Core minimalism: the exclusion principle **net-simplifies** the Core (the whole FG
semantics of five sub-opcodes disappears, replaced by a trap), and the Base Set↔Loop band-crossing
check guards precisely "the place where the most complicated things happen" — Core-mandatory.
Excessive debuggability may be **parameterized later** (noted, not decided).

**代替案:** (a) 沈黙の停止、HWリセットのみ、Formation 任意;(b) 可観測・回復可能、最重要検査は Core 必須。
**選択:** (b)。**根拠:** **エラーフラグ出力ポート**が停止を計器に変える: SignalTap がそれでトリガでき
（キャプチャが現場を示す）、Formation はインサーション機構に配線できる。脱出: ハードウェアリセット;
**ISMCE リアルタイム書き換え**（問題語の NOP 化・Jump パッチ）——挙動が編集可能メモリに住む PTSG ならではで、
停止したコアを JTAG 越しに生きたまま修理できる;インサーション。Core 極小主義について: 排除原則は Core を
**正味で単純化**し（5サブオペコードの FG 意味論が丸ごと消えトラップに置き換わる）、Base Set↔Loop 帯域跨ぎ
検査は「一番ややこしいことが起こる箇所」をまさに守る——Core 必須。過剰なデバッガビリティは**後日パラメータ化**
を検討（記録のみ、未決定）。

### 6. What is a Stay encountered inside a window? / 窓内で遭遇した Stay とは何か

**Alternatives:** (a) an error or a nested wait; (b) **it IS the foreground Stay — the window's
terminator**. **Chosen:** (b).

**Rationale:** There is no such thing as a background Stay: the Stay is where the State Number
rests during the wait, so the scan reaching it is by construction the boundary of the window's
program. The band structure `StaySet | BG… | ProgEnd | Q… | Stay` is closed at both ends by its
two foreground anchors.

**代替案:** (a) エラーまたは入れ子待機;(b) **それは FG の Stay——窓の終端子**。**選択:** (b)。**根拠:**
背景の Stay というものは存在しない: Stay は待機中に State Number が座る場所であり、スキャンがそこへ達する
ことが構成上、窓プログラムの境界である。帯域構造 `StaySet | BG… | ProgEnd | Q… | Stay` は、二つの前景
アンカーによって両端を閉じられる。

---

## Major Themes / 主要テーマ

### Theme 1 — The empty grid as an instrument of discovery / 空の格子という発見の計器
The table was built to record decisions, but its first effect was to generate them: 33 cells, each
demanding an answer, surfaced questions point-wise verification had never asked. A complete blank
plane is a stronger review tool than any checklist, because an empty cell cannot be overlooked.

表は決定を記録するために作られたが、最初の効果は決定の生成だった: 33 のセルが各々答えを要求し、点検証が
一度も発しなかった問いを浮上させた。完全な空白の面はいかなるチェックリストより強い査読装置である——空セルは
見落とせないからだ。

### Theme 2 — Refusing to give meaning as the simplification / 意味を与えない、という単純化
Forcing a meaning onto every cell was laborious to design and burdensome to learn. Declaring the
unused and the inferior illegal — and stopping at the violation — is simpler for the Core (a trap
instead of five foreground semantics), simpler for the programmer, and stronger for debugging.

全セルへの意味の強制は設計に骨が折れ、学習に重い。使わないもの・劣るものを違法と宣言し違反地点で止めることは、
Core に単純（5つの前景意味論の代わりに一つのトラップ）、プログラマに単純、デバッグに強い。

### Theme 3 — Band legality as the enforcement of time/space separation / 帯域合法性による時間/空間分離の強制
The FG-Global exclusion converts the founding philosophy into a checkable rule: state-control
machinery cannot appear on the time axis. A disciplined foreground reads as a bare sequence of Stay
durations — the timing chart is literally the program text. The separation is no longer a style; it
is enforced by HALT.

FG-Global 排除は創設哲学を検査可能な規則へ変換する: 状態制御機構は時間軸に現れられない。規律ある前景は Stay
持続時間の裸の列として読める——タイミングチャートが文字通りプログラムテキストである。分離はもはや作法でなく、
HALT により強制される。

### Theme 4 — The second principle-with-exceptions, same cast / 二つ目の「原則＋例外」、同じ顔ぶれ
PTSG now holds two principle-plus-exceptions structures: the Trailing-Edge Doctrine (exceptions:
FG Stay Set and Reset) and the FG-Global exclusion (exceptions: Reset, Stay Set, NOP). The overlap
is not coincidence: Reset and Stay Set are the commands whose job is to mark *beginnings* — of the
whole machine, or of a phase — and beginnings are exactly where both principles must bend, each
exception carrying its explicit justification.

PTSG は「原則＋例外」構造を二つ持つに至った: 後縁主義（例外: FG Stay Set と Reset）と FG-Global 排除
（例外: Reset・Stay Set・NOP）。重なりは偶然でない: Reset と Stay Set は*始まり*——機械全体の、あるいは
フェーズの——を標すことが仕事の命令であり、始まりこそ両原則が撓まねばならぬ場所であって、各例外は明示的な
理由を帯びる。

### Theme 5 — Debuggability as a first-class design force / 第一級の設計力としてのデバッガビリティ
The HALT decision was driven by the anatomy of debugging pain: unintended behavior that chains, and
a triggering site that recedes from the observation point. Halting at the violation — with a flag
SignalTap can trigger on, insertion can react to, and ISMCE can repair past — turns the failure into
a captured, inspectable, repairable scene. For an architecture whose value is "behavior lives in
editable memory," the natural error philosophy is: **stop where it broke, and fix the memory in
place.**

HALT の決定はデバッグの苦痛の解剖学に駆動された: 連鎖する意図せぬ動作と、観測点から遠ざかる引き金の現場。
違反地点での停止——SignalTap がトリガでき、インサーションが反応でき、ISMCE が修理できる旗とともに——は、
失敗を捕獲され・検分でき・修理できる現場に変える。「挙動は編集可能メモリに住む」ことが価値である
アーキテクチャの自然な誤り哲学は: **壊れた場所で止まり、メモリをその場で直す。**

---

## Resumption Hooks / 再開フック

### Hook A — RTL: the traps and the HALT state / RTL: トラップと HALT 状態
FG Base Set/Return/Call/Loop/Prog End → HALT; stray Prog End → HALT; queue SN-overwrite → HALT;
error-flag output; exit by hardware reset (ISMCE/insertion as repair paths).
**Starting question:** In `ptsg_core.v`, design the S_HALT state and the trap conditions of the
Chapter 3 normative table. What is the minimal decode addition, and how is the flag registered and
exported?

### Hook B — RTL conformance: window tick-increment on every path / 全経路での窓内 tick インクリメント
RH005's `window_open && presc_tick` increment appears on the Global and OP_STAY paths; the table
requires it during ANY in-window command, including BG Branch/Jump.
**Starting question:** Verify white-box that `stay_cnt` ticks during BG Branch/Jump; if not, hoist
the increment to one unconditional rule outside the opcode case. Does the hoist change any verified
timing?

### Hook C — Parameterizing debuggability / デバッガビリティのパラメータ化
**Starting question:** Measure the LE/Fmax cost of the HALT machinery and the pairing checks on
Cyclone V. At what cost does a DEBUG_CHECKS parameter earn its place, and which checks must remain
unconditional?

### Hook D — HALT external protocol (Chapter 5 / Formation) / HALT の外部プロトコル
**Starting question:** Draft the Chapter 5 error-flag interface (width, polarity, timing relative
to the violating fetch) and a Formation recipe for halt→insert→diagnose→ISMCE-patch→resume flows.

### Hook E — Conformance items for the illegality table / 違法表の適合項目
**Starting question:** Design conformance items provoking each trap (FG Loop, stray Prog End, queue
overwrite, unpaired Base Set) and verifying the halt, the flag, and the preserved scene. Which
existing queue items do these fold into?

---

## End of Trace / 軌跡の末尾

A machine is defined as much by what it refuses as by what it does. PTSG's foreground now refuses
everything that is not time: the loops, the calls, the bases all live behind the window, and if one
strays onto the time axis the machine does not improvise — it stops, raises a flag, and preserves
the scene. What remains in the foreground is what a timing chart shows: durations, transitions, and
the three commands allowed to mark a beginning. The table that recorded these decisions also
produced them; thirty-three small boxes asked their questions, and the architecture answered by
learning to say no.

機械は、何をするかと同じだけ、何を拒むかで定義される。PTSG の前景はいま、時間でないものすべてを拒む: ループ
も、コールも、ベースもすべて窓の裏に住み、もし一つでも時間軸に迷い出れば、機械は取り繕わない——停止し、旗を
揚げ、現場を保存する。前景に残るのはタイミングチャートが示すもの: 持続と、遷移と、始まりを標すことを許された
三つの命令。これらの決定を記録した表は、決定を生み出した表でもあった; 三十三の小さな枠がそれぞれの問いを発し、
アーキテクチャは「否」の言い方を学ぶことで答えたのである。

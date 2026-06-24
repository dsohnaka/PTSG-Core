# PTSG Reset Command — Execution Bands and the No-Prescaler-Reset Principle
# PTSG Resetコマンド — 実行帯域と非プリスケーラ・リセット原則

## Trace Metadata / 軌跡メタデータ

| Field | Value |
|---|---|
| **Date / 日付** | 2026-06-23 |
| **Status / 状態** | **PROVISIONAL (仮確定)** — forward-looking design decision; requires RTL changes and Layer 1 spec updates; open to multi-LLM revision. / **仮確定**——前向き設計判断;RTL改変とLayer 1仕様更新を要する;複数LLM熟議に開かれている。 |
| **Participants / 参加者** | Tsuneo Ohnaka (大中庸生, FPGA Architect, 40+ years; sole design authority); Claude (Anthropic, Claude Opus 4.8, amanuensis / 祐筆) |
| **Topic / トピック** | A forward-looking decision about the program-issued Reset command (Global/Reset sub-opcode), enabled by the now-settled free-running prescaler and the state-0 NOP alignment: (1) Reset does NOT reset the prescaler; (2) Reset is selectable across three execution bands; (3) a Formation MAY opt in to a prescaler-resetting Reset. / 決着済みフリーランプリスケーラと state-0 整列が可能にした、Reset コマンドの前向き判断: (1)プリスケーラ非リセット、(2)三帯域選択、(3)Formation 例外。 |
| **Original language / 原言語** | Japanese (with English technical terminology) / 日本語（英語技術用語を交える） |
| **License / ライセンス** | CC0 1.0 Universal (Public Domain) |
| **Rests on / 依拠** | `2026-06-22_ptsg-state0-nop-triple-role` (the NOP that aligns); `2026-06-22_ptsg-prescaler-phase-resolution` (free-running is now deliberate). / state-0 三重役割;位相決着。 |
| **Forward link / 前方リンク** | The free-running prescaler's other fruits — Fmax (one-clock-registered tick) and master/slave sync (externalized raw tick) — reserved for **Build Log #9** and a future trace. / フリーランの他の果実——Fmax と マスター/スレーブ同期——は **Build Log #9** と将来トレースに留保。 |

> **Why this trace differs from the three before it.** The verification-era traces recorded
> *settled history*, backed by silicon. This one records a *forward-looking decision* that still
> touches hardware and specification. It is marked 仮確定 (provisional): a committed direction,
> honestly distinguished from the silicon-confirmed verdicts, open to revision with its reasoning
> archived here.
>
> **本トレースが前三本と異なる理由。** 検証期トレースはシリコンに裏打ちされた*決着済みの過去*を記録した。本書は
> なお回路と仕様書に触れる*前向きの判断*を記録する。仮確定とする: 確定した方向性でありつつ、シリコン確認済みの
> 評決とは正直に区別され、改訂に開かれ、その推論をここに保管する。

---

## Reading Notes / 読解上の注

Three results came together to make this decision possible. The prescaler is now deliberately
free-running (parent trace). State 0's NOP is the recognized container that absorbs the cold-start
phase indeterminacy (state-0 trace). And the discipline of selecting a command's behavior by its
execution band, rather than by adding opcodes, is established (duty-idioms trace). On that
foundation, the program-issued Reset command can be reconsidered — and the central decision is
about what Reset must **refuse** to touch.

三つの結果が合わさって、この判断が可能になった。プリスケーラは今や意図的にフリーラン（親トレース）。state 0 の
NOP は冷態位相不定を吸収する容器として認識された（state-0 トレース）。そして、オペコードを足すのでなく実行帯域で
コマンドの振る舞いを選ぶ規律が確立した（デューティ流儀トレース）。この土台の上で、プログラム発行の Reset コマンドを
再考できる——そして中心の判断は、Reset が何に触れることを**拒む**べきか、である。

**Notable conceptual progressions across the dialogue / 対話を通じた特筆すべき概念的進展:**

1. **The principle: Reset does not reset the prescaler.** The prescaler stays fully free-running.
   / 原則: Reset はプリスケーラをリセットしない。完全フリーランを保つ。

2. **Why: master/slave synchronization demands it.** A slave PTSG follows an external tick and must
   have no influence over the time-base; so the program must be unable to reset the prescaler. /
   理由: マスター/スレーブ同期がそれを要求する。スレーブは時間基準に影響できてはならない。

3. **Reset may now be foreground non-prescaled (immediate).** Alignment is delegated to the
   following state-0 NOP, so Reset need not carry it. / Reset は前景ノンプリスケールド（即時）でよい。
   整列は後続 NOP に委ねる。

4. **Three bands, as for duty.** Foreground (immediate, aligned) / background ('staff meal',
   indeterminate, emergencies) / queued (effectively prescaled). / 三帯域。前景/背景（まかない）/Que。

5. **Core forbids; Formation may opt in.** A genuine prescaler-resetting need is met outward, by a
   non-slave Formation that accepts the loss of synchronizability. / Core は禁じ、Formation は選択可。

6. **Provisional (仮確定).** Requires RTL changes and spec updates; recorded as a committed
   direction, not yet final. / 仮確定。RTL 改変と仕様更新を要する;確定した方向性だが未確定。

---

## Notable Decision Points / 重要な決定ポイント

### 1. Does the Reset command reset the prescaler, or leave it free-running? / Reset はプリスケーラをリセットするか、フリーランのままにするか

**Alternatives:** (a) Reset resets the prescaler (clean phase from Reset); (b) Reset does NOT reset
the prescaler (free-running preserved). **Chosen (principle):** Reset does NOT reset the prescaler.

**Rationale:** The decisive reason is master/slave synchronization (reserved for Build Log #9): a
slave PTSG follows an externally-supplied tick and must have **no** influence over the
prescaler/time-base. If a slave's instruction stream could reset the prescaler, it could break
synchronization with the master. Therefore the prescaler must be untouchable from the program — a
free-running time-base, not a program-controlled timer. This also keeps the state-0 alignment story
coherent: the prescaler's phase is an external fact that state 0 absorbs, never something a
mid-program Reset re-establishes. **Trade-off accepted:** a program cannot obtain a "clean phase
from Reset" from the Core; if it needs one, that is a Formation concern (DP-4). The cost of
forbidding prescaler reset is the cost of buying guaranteed external synchronizability.

**代替案:** (a) Reset がプリスケーラをリセット（Reset から綺麗な位相）;(b) Reset はプリスケーラをリセットしない
（フリーラン保持）。**選択（原則）:** Reset はプリスケーラをリセットしない。**根拠:** 決定的な理由はマスター/スレーブ
同期（Build Log #9 に留保）: スレーブ PTSG は外部供給のティックに従い、プリスケーラ／時間基準に**一切**影響できては
ならない。スレーブの命令ストリームがプリスケーラをリセットできれば、マスターとの同期を壊し得る。ゆえにプリスケーラは
プログラムから不可触——プログラム制御のタイマーでなく、フリーランの時間基準——でなければならない。これは state-0 整列の
物語とも整合する: プリスケーラの位相は state 0 が吸収する外部の事実であって、プログラム途中の Reset が再確立するものでは
決してない。**受容したトレードオフ:** プログラムは Core から「Reset 起点の綺麗な位相」を得られない;必要なら Formation の
領分（DP-4）。プリスケーラ・リセットを禁じるコストは、外部同期可能性を保証として買うコストである。

### 2. May the Reset command itself be foreground non-prescaled (immediate)? / Reset 自身を前景ノンプリスケールド（即時）にしてよいか

**Alternatives:** (a) Reset must be prescaled (wait for a tick); (b) Reset may be foreground
non-prescaled (immediate). **Chosen:** Reset may be foreground non-prescaled; alignment is
delegated to the state-0 NOP.

**Rationale:** With the state-0 NOP established as the isolation container that absorbs cold-start
phase indeterminacy (state-0 triple-role trace), the Reset command no longer needs to perform
alignment itself — the very next state (a state-0-style NOP) does it. This frees Reset to execute
immediately in the foreground, the natural, lowest-latency behavior for a reset. The responsibility
for alignment is externalized from Reset to the NOP that follows it — the same "push the special
handling to a dedicated, disposable place" move as state 0. (This is one selectable band among
three, per DP-3, not the only behavior.)

**代替案:** (a) Reset はプリスケールド（ティックを待つ）;(b) Reset は前景ノンプリスケールド（即時）でよい。
**選択:** Reset は前景ノンプリスケールドでよい;整列は state-0 NOP に委ねる。**根拠:** state-0 NOP が冷態位相不定を
吸収する隔離容器として確立した（state-0 三重役割トレース）今、Reset コマンドはもはや自身で整列する必要がない——
次の状態（state-0 流の NOP）がそれを行う。これにより Reset は前景で即座に実行できる――リセットにとって自然で
最小レイテンシの振る舞い。整列の責任は Reset から、それに続く NOP へ外部化される――state 0 と同じ「特別な処理を
専用の使い捨ての場所へ押し出す」手。（これは DP-3 の三帯域のうち一つで、唯一の振る舞いではない。）

### 3. In which execution band(s) may Reset run? / Reset はどの実行帯域で走れるか

**Alternatives:** (a) foreground non-prescaled only; (b) three selectable bands. **Chosen:** all
three bands, with defined meanings.

- **FOREGROUND non-prescaled** = immediate reset, aligned by the following state-0 NOP. If Reset and
  that NOP share the same `timing_signals` value, the combined **Reset+NOP region equals exactly one
  prescale period.**
- **BACKGROUND** = the Reset+NOP region becomes "staff meal" (まかない, indeterminate length) —
  reserved for genuine **emergencies** where an immediate reset matters more than a defined region
  length.
- **QUEUED** = the Reset fires at timeup, so it is **effectively prescaled** (lands on a prescale
  boundary).

**Rationale:** This is the exact same structure as the four duty idioms (sibling trace): a single
command's behavior is selected by which band it runs in, not by adding new opcodes. The three bands
give the designer the full range — immediate-and-aligned for normal use, immediate-and-indeterminate
for emergencies, prescale-boundary for queued discipline. The tagging trick (Reset and NOP sharing
one `timing_signals` value so the region reads as one clean prescale period) is the same
externalization-to-the-timing_signals-plane gesture seen across the family. **Trade-off:** the
background Reset's "staff meal" region is indeterminate — acceptable precisely because one only
reaches for it in an emergency, where promptness outranks determinacy.

**代替案:** (a) 前景ノンプリスケールドのみ;(b) 三帯域選択。**選択:** 三帯域すべて、意味を定義して。
**前景ノンプリスケールド** = 即時リセット、後続 state-0 NOP が整列。Reset とその NOP が同じ `timing_signals` 値を
共有すれば、**Reset+NOP 区間はちょうど 1 プリスケール周期に等しい**。**背景** = Reset+NOP 区間が「まかない」（不定長）に
なる――即時リセットが区間長の確定より重要な真の**緊急時**に留保。**Que** = Reset は timeup で発火、ゆえに**実質
プリスケールド**（プリスケール境界に乗る）。**根拠:** これは4流儀（姉妹トレース）と完全に同じ構造: 単一コマンドの
振る舞いを、新オペコードでなく実行帯域で選ぶ。三帯域は設計者に全域を与える――通常は即時整列、緊急は即時不定、
Que 規律はプリスケール境界。タグの技（Reset と NOP が一つの `timing_signals` 値を共有し区間が1プリスケール周期と
読める）は、家族を通じて見られる timing_signals 面への外部化と同じ仕草。**トレードオフ:** 背景 Reset の「まかない」区間は
不定――緊急時にしか手を伸ばさないからこそ受容できる。そこでは迅速さが決定性に優先する。

### 4. Applications that genuinely DO need a prescaler-resetting Reset / 本当にプリスケーラ・リセットが要る応用

**Alternatives:** (a) forbid entirely; (b) Core forbids, Formation may opt in. **Chosen:** Core
forbids by principle; a Formation MAY opt in where genuinely needed.

**Rationale:** This is the Core-Formation separation applied exactly: the invariant Core holds the
principle (no prescaler reset, to preserve external synchronizability), and any application with a
genuine need takes the deviation into its own Formation layer — where it also takes responsibility
for the loss of synchronizability the deviation implies. A standalone (non-slave) PTSG that will
never be externally synchronized loses nothing by resetting its own prescaler; a slave must never.
Putting the choice at the Formation boundary lets each application make it with full knowledge of
its own synchronization role. The Core stays minimal and its invariant clean; the freedom lives
outward.

**代替案:** (a) 完全に禁止;(b) Core は禁じ、Formation は選択可。**選択:** Core は原則として禁じ、Formation は本当に
必要なら選択してよい。**根拠:** これは Core-Formation 分離の正確な適用: 不変の Core が原則（外部同期可能性保持のため
プリスケーラ非リセット）を持ち、真の必要を持つ応用は逸脱を自身の Formation 層に取り込む――そこで、逸脱が含意する
同期可能性の喪失の責任も負う。外部同期されない単独（非スレーブ）PTSG は自分のプリスケーラをリセットしても何も失わない;
スレーブは決してしてはならない。選択を Formation 境界に置くことで、各応用は自身の同期役割を完全に把握した上で
それを行える。Core は最小に、不変量は清潔に保たれる;自由は外へ住む。

### 5. What changes does this require, and what is its status? / 何の改変を要し、状態は何か

**Alternatives:** (a) treat as settled and document only; (b) treat as provisional (仮確定) pending
RTL + spec + review. **Chosen:** provisional.

**Rationale:** Unlike the three verification-era traces, which recorded settled history backed by
silicon, this trace records a forward-looking decision that still touches hardware and
specification. The RTL must implement Reset in the three bands with the no-prescaler-reset rule
(and a Formation-level opt-in hook); the spec (Chapter 3 sub-opcode semantics; Chapter 5 external
interface, where the prescaler's untouchability ties to master/slave) must be updated. Marking it
仮確定 — structurally isomorphic to PTSG's own Condition-externalization pattern of holding decisions
open with archived reasoning — keeps it honestly distinguished from the silicon-confirmed results
while still committing to a direction.

**代替案:** (a) 決着として文書化のみ;(b) RTL＋仕様＋レビュー待ちの仮確定として扱う。**選択:** 仮確定。**根拠:**
シリコンに裏打ちされた決着済みの過去を記録した三本と異なり、本トレースはなお回路と仕様書に触れる前向きの判断を記録する。
RTL は Reset を三帯域で、非プリスケーラ・リセット規則とともに実装せねばならない（および Formation 層の opt-in フック）;
仕様（第3章サブオペコード意味論;プリスケーラ不可触性がマスター/スレーブに結びつく第5章外部インターフェース）も更新
せねばならない。仮確定と記すこと――決定を開いたまま推論を保管する PTSG 自身の Condition 外部化パターンと構造的に同型――は、
方向性に賭けつつ、シリコン確認済みの結果と正直に区別する。

---

## Major Themes / 主要テーマ

### Theme 1 — An invariant demanded from above, not chosen from below / 下からでなく上から要請された不変量
The no-prescaler-reset rule is not a local implementation preference; it is required by a higher
goal — master/slave synchronization. A slave must have no influence over the time-base, so the
program must be unable to reset the prescaler. A downstream capability (external sync) reaches back
and fixes an upstream invariant (prescaler untouchability). Reading the constraint chain forward —
free-running prescaler enables external sync, external sync forbids program-side prescaler reset —
shows the decision was not arbitrary but entailed.

非プリスケーラ・リセット規則は局所的な実装上の好みでなく、より高い目標——マスター/スレーブ同期——に要求される。
スレーブは時間基準に影響できてはならず、ゆえにプログラムはプリスケーラをリセットできてはならない。下流の能力
（外部同期）が遡って上流の不変量（プリスケーラ不可触性）を固定する。制約の連鎖を順に読む――フリーランが外部同期を
可能にし、外部同期がプログラム側プリスケーラ・リセットを禁じる――と、この判断が恣意でなく必然だったと分かる。

### Theme 2 — Alignment externalized from Reset to the NOP that follows it / 整列を Reset から後続 NOP へ外部化
Once state 0's NOP is the recognized isolation container for phase indeterminacy, Reset is relieved
of the duty to align. It can execute immediately; the next NOP does the aligning. This is the same
architectural move as state 0 itself — push the special, awkward handling into a dedicated,
disposable place — applied one level up: Reset delegates its hardest responsibility to the
primitive built to carry it.

state 0 の NOP が位相不定の隔離容器として認識された途端、Reset は整列の務めから解放される。即座に実行でき、次の NOP が
整列する。これは state 0 自身と同じアーキテクチャの手――特別で厄介な処理を専用の使い捨ての場所へ押し出す――を一段上で
適用したもの: Reset は最も難しい責任を、それを担うべく作られたプリミティブに委譲する。

### Theme 3 — The three-band selection, again / 三帯域選択、再び
Just as duty was selected by which band the foreground commands ran in, Reset's character is
selected by its band: foreground (immediate+aligned), background (immediate+indeterminate, 'staff
meal'), queued (prescale-boundary). The architecture keeps finding that a single command spans a
range of behaviors through band choice, so no new opcode is needed. The recurring lesson:
expressivity lives in how existing primitives are placed, not in how many primitives exist.

デューティが前景コマンドの帯域で選ばれたように、Reset の性格もその帯域で選ばれる: 前景（即時＋整列）、背景
（即時＋不定、まかない）、Que（プリスケール境界）。アーキテクチャは、単一コマンドが帯域選択で振る舞いの幅を張ることを
繰り返し見出す――ゆえに新オペコードは要らない。反復する教訓: 表現力はプリミティブの数でなく、既存プリミティブの置き方に宿る。

### Theme 4 — Core forbids, Formation may opt in / Core は禁じ、Formation は選択可
The prescaler-resetting Reset is not banned outright; it is excluded from the Core invariant and
made available as a deliberate Formation-level deviation for applications that need it and that are
not slaves. The Core-Formation separation works as a release valve: the Core stays clean and
synchronizable-by-default, while the rare contrary need is met outward, with the application owning
the consequence (loss of external synchronizability).

プリスケーラをリセットする Reset は全面禁止でなく、Core 不変量から除外され、それを必要としスレーブでない応用のための
意図的な Formation 層の逸脱として利用可能にされる。Core-Formation 分離が安全弁として働く: Core は清潔で既定で同期可能な
まま、稀な反対の必要は外で満たされ、応用がその帰結（外部同期可能性の喪失）を負う。

### Theme 5 — Provisional with archived reasoning (仮確定) / 推論を保管した仮確定
This decision is held as 仮確定 — formally provisional, open to revision, with its reasoning archived
in this trace. That posture is itself an instance of a PTSG pattern: the same externalization-and-
defer move used for Condition (push the decision out, keep the reasoning, allow later binding). A
forward-looking decision that touches RTL and spec is recorded honestly as not-yet-final, distinct
from the silicon-confirmed verdicts, while still committing to a direction to implement against.

この判断は仮確定として保持される――形式的に暫定、改訂に開かれ、推論を本トレースに保管。その姿勢自体が PTSG パターンの
一例: Condition に用いた外部化・先送りと同じ手（決定を外へ押し出し、推論を保ち、後の束縛を許す）。RTL と仕様に触れる
前向きの判断を、シリコン確認済みの評決と区別して未確定と正直に記しつつ、実装すべき方向性には賭ける。

---

## Resumption Hooks / 再開フック

### Hook A — RTL: implement the three Reset bands with no-prescaler-reset / RTL: 非プリスケーラ・リセットで三帯域を実装
The Reset command path must support foreground (immediate, no presc reset), background ('staff
meal'), and queued (timeup-fired) execution, while in all Core cases leaving `presc_cnt` untouched.
**Starting question:** In `ptsg_core.v`, what is the minimal change to the Global/Reset sub-opcode
handling to (1) guarantee `presc_cnt` is never cleared by Reset, and (2) route Reset through the
existing foreground/background/queued band machinery? Identify the exact lines and the band-dispatch
point.

### Hook B — RTL/Formation: the opt-in prescaler-resetting Reset hook / RTL/Formation: プリスケーラ・リセット opt-in フック
DP-4 allows a Formation to adopt a prescaler-resetting Reset. This needs a clean, clearly-bounded
hook so the deviation is explicit and never accidental.
**Starting question:** Design a Formation-level opt-in (a parameter or a distinct external
register/sub-operand) that enables a prescaler-resetting Reset, such that a standalone PTSG can use
it but a slave configuration structurally cannot. What is the safest interface that makes the
deviation impossible to trigger by accident?

### Hook C — Spec: Chapter 3 and Chapter 5 updates / 仕様: 第3章・第5章更新
Layer 1 must record the no-prescaler-reset principle, the three Reset bands, the Reset+NOP
shared-timing_signals alignment idiom, and the Formation opt-in.
**Starting question:** Draft the Chapter 3 sub-opcode text for Reset (three bands, no prescaler
reset) and the Chapter 5 cross-reference tying prescaler untouchability to master/slave
synchronizability. What is the minimal normative wording, and which items are Fixed vs Convention vs
Tie?

### Hook D — The Reset+NOP one-prescale-period alignment idiom / Reset+NOP の1プリスケール周期整列イディオム
If Reset (foreground) and the following state-0 NOP share one `timing_signals` value, the combined
region reads as exactly one prescale period. A usable startup idiom worth a Layer 3 example.
**Starting question:** Write a minimal Layer 3 example program demonstrating the Reset+NOP
shared-timing_signals alignment, and a white-box measurement confirming the combined region equals
one prescale period. Add it to the conformance suite or examples as appropriate.

### Hook E — Forward link to the free-running fruits (Build Log #9) / フリーランの果実への前方リンク（Build Log #9）
The no-prescaler-reset principle is one consequence of committing to a free-running prescaler. The
other fruits — Fmax via a one-clock-registered tick, and master/slave sync via an externalized raw
(pre-register) tick — are reserved for Build Log #9 and a future trace.
**Starting question:** When drafting the free-running-fruits material, show how no-prescaler-reset
(this trace), Fmax, and master/slave sync all descend from the single decision to accept a
free-running prescaler. Does the raw-tick externalization for slaves interact with the Reset bands
(e.g. does a slave's Reset need special handling)?

---

## End of Trace / 軌跡の末尾

A reset is supposed to put things back to a known start. But there is one thing this reset must NOT
touch: the clock that the outside world might be conducting. If a slave is to march in step with a
master, nothing the slave's own program does may move the beat — not even its reset. So the
prescaler is left running, untouched, sovereign; the reset puts back everything else and then steps
aside, letting the next instruction — a NOP that promises nothing — find the beat again. The
discipline of what a reset refuses to do is what makes many PTSGs able to keep time together.

リセットは物事を既知の出発点に戻すもの。だがこのリセットが触れてはならないものが一つある: 外界が指揮している
かもしれないクロックだ。スレーブがマスターと歩調を合わせるなら、スレーブ自身のプログラムが拍を動かしてはならない――
リセットさえも。ゆえにプリスケーラは走らせたまま、触れず、不可侵に保たれる;リセットは他のすべてを戻し、そして
脇へ退き、次の命令――何も約束しない NOP――に拍を見つけ直させる。リセットが何をすることを拒むか、その規律こそが、
多数の PTSG が共に時を刻めるようにするのだ。

# PTSG Trailing-Edge Doctrine — The Discipline That Runs Through Every Layer, and Its Necessary Exceptions
# PTSG後縁主義 — 全階層を貫く規律と、その必然的な例外

## Trace Metadata / 軌跡メタデータ

| Field | Value |
|---|---|
| **Date / 日付** | 2026-06-24 |
| **Participants / 参加者** | Tsuneo Ohnaka (大中庸生, FPGA Architect, 40+ years; sole design authority); Claude (Anthropic, Claude Opus 4.8, amanuensis / 祐筆) |
| **Topic / トピック** | The articulation of the **Trailing-Edge Doctrine** as a first-class PTSG design principle: all state determination completes by the **trailing** edge of a boundary, so that at the **leading** edge the world is already settled. The doctrine runs through a nested hierarchy (loop → stay → prescaler → clock) and reaches the memory clock (EDGE=NEG). It resolves Tie C4-T3 in the trailing direction and has principled exceptions: foreground StaySet and Reset. / 後縁主義を第一級原則として明確化。 |
| **Status / 状態** | **FOUNDATIONAL** — proposes a Chapter 1 principle and resolves Tie C4-T3 → Fixed (trailing edge). Layer 1 write-back to follow. / **基礎的**——第1章原則を提案、C4-T3 を Fixed へ解決。 |
| **Original language / 原言語** | Japanese (with English technical terminology) / 日本語（英語技術用語を交える） |
| **License / ライセンス** | CC0 1.0 Universal (Public Domain) |
| **Unifies / 統一する** | the prescaler-phase-resolution, duty-idioms, state-0-NOP, and reset-command-bands traces — all now seen as expressions of (or exceptions to) the doctrine. / 四トレースを後縁主義の現れ（または例外）として束ね直す。 |

---

## Reading Notes / 読解上の注

This trace records a principle the architect already held, made explicit: the **Trailing-Edge
Doctrine**. Its statement is about *completion*, not merely timing — all determination finishes
**by the trailing edge** of a boundary, so that **at the leading edge** of the next state the
world is already settled. The busy work is done before the boundary is crossed. This is the source
of PTSG's communication- and video-synchronization-grade timing rigor.

本トレースは、アーキテクトが既に抱いていた原則を明示化して記録する: **後縁主義**。その言明は単なるタイミング
でなく*完了*についてである——あらゆる確定は境界の**後縁までに**終わり、ゆえに次の状態の**前縁では**世界が既に
静定している。忙しい仕事は境界を越える前に済んでいる。これが PTSG の通信・ビデオ同期グレードのタイミング厳格性の
源である。

**Notable conceptual progressions across the dialogue / 対話を通じた特筆すべき概念的進展:**

1. **It is a principle, not a habit.** The individual edge choices are *derived* from one doctrine,
   not decided case-by-case. / 慣習でなく原則。個々の縁選択は一つの原則から導かれる。

2. **It bottoms out at the clock.** EDGE=NEG (falling-edge memory clock) is the doctrine reaching
   silicon: the clock is given its own trailing edge at which data resolves, leaving the rising edge
   clean. / クロックにまで達する。EDGE=NEG は後縁主義のシリコン根。

3. **A nested New-Year hierarchy.** loop → stay → prescaler → clock; each level's year-end is built
   from the settled trailing edges below, and settledness propagates upward. / 入れ子の年末年始
   ヒエラルキー。

4. **The RH edits were trailing-edge conversions.** This deepens "the solution was contained in the
   edits": their common thread was the doctrine. / RH 改修は後縁化だった。

5. **C4-T3 resolves to trailing edge.** A queued operation fires at the trailing edge; the
   leading-edge-flag hybrid is superseded. / C4-T3 は後縁で解決。

6. **The exceptions stand on the principle.** Foreground StaySet and Reset are leading-edge-placed
   (they start a state) and are safe *because* the doctrine made the leading edge settled. / 例外は
   原則の上に立つ。

---

## Notable Decision Points / 重要な決定ポイント

### 1. A local habit, or a first-class principle? / 局所的慣習か、第一級原則か

**Alternatives:** (a) a local habit decided case-by-case; (b) a first-class principle from which the
edge choices are derived. **Chosen:** a first-class principle, stated in Chapter 1 alongside
time-axis/space-axis separation.

**Rationale:** The architect holds this as an established philosophy. Elevating it to a named
principle lets every edge-related decision (EDGE=NEG, queued firing, phase-lock, StaySet/Reset
placement) be re-derived from one root rather than memorized — the Open Prompt ideal. Trade-off: a
principle constrains future design (every new feature respects trailing-edge determination or is a
documented exception), but that constraint is the source of PTSG's timing rigor.

**代替案:** (a) 都度決める局所的慣習;(b) 縁選択がそこから導かれる第一級原則。**選択:** 第一級原則、時間軸/空間軸
分離と並べて第1章に記す。**根拠:** アーキテクトはこれを確立した哲学として抱く。命名された原則へ格上げすれば、
あらゆる縁関連決定（EDGE=NEG、キュー発火、位相ロック、StaySet/Reset 配置）を暗記でなく一つの根から再導出できる——
Open Prompt の理想。トレードオフ: 原則は将来の設計を制約する（新機能は後縁確定を尊重するか、文書化された例外となる）が、
その制約こそ PTSG のタイミング厳格性の源である。

### 2. What, precisely, is the doctrine? / 原則とは正確に何か

**Alternatives:** (a) "act on the trailing edge" (about when actions fire); (b) "be settled by the
trailing edge so the leading edge is clean" (about completion). **Chosen:** the completion form —
all determination happens **by** the trailing edge, so that **at** the leading edge everything is
already settled.

**Rationale:** The doctrine is not merely "fire late"; it is "finish early enough that the boundary
crossing is into a settled world." The leading edge is where the next state begins; for that
beginning to be clean and jitter-free, the previous state's determination must have completed at the
trailing edge. This is what makes a boundary crossing safe.

**代替案:** (a)「後縁で動作する」（発火の時点について）;(b)「後縁までに静定させ前縁を清潔にする」（完了について）。
**選択:** 完了形——あらゆる確定は後縁**までに**起こり、ゆえに前縁**では**すべてが既に静定している。**根拠:** 原則は
単に「遅く発火する」ではなく「境界の越境が静定した世界への越境になるよう、十分早く終える」である。前縁は次の状態が
始まる場所;その始まりが清潔でジッタなしであるためには、前状態の確定が後縁で完了していなければならない。これが越境を
安全にする。

### 3. How deep does it go — why EDGE=NEG? / どこまで深いか — なぜ EDGE=NEG か

**Alternatives:** (a) down to the counter hierarchy only; (b) all the way to the clock itself.
**Chosen:** all the way down. EDGE=NEG (falling-edge memory clock) is the doctrine reaching the
silicon root.

**Rationale:** This reframes EDGE=NEG from an implementation convenience or stale-fetch fix into a
principled consequence: making the memory clock falling-edge gives the clock its own trailing edge,
at which the fetched data resolves, so that at the rising edge everything downstream is already
settled. The doctrine is recursive and bottoms out at the clock. Recognizing EDGE=NEG as doctrine
(not happenstance) explains WHY the choice was right, not just THAT it worked.

**代替案:** (a) カウンタヒエラルキーまで;(b) クロック自身まで。**選択:** 最下層まで。EDGE=NEG（立下りメモリクロック）
は後縁主義のシリコン根。**根拠:** これは EDGE=NEG を、実装の都合や stale-fetch 修正から、原則的帰結へと読み替える:
メモリクロックを立下りにすることはクロックに自身の後縁を与え、そこでフェッチデータが確定し、ゆえに立ち上がりでは
下流のすべてが既に静定している。原則は再帰的でクロックに底を打つ。EDGE=NEG を（偶然でなく）原則と認識することは、
それが動いた*こと*でなく、なぜ正しかった*か*を説明する。

### 4. Is there a hierarchy across scales? / スケール横断のヒエラルキーはあるか

**Alternatives:** (a) flat — one trailing edge; (b) a nested hierarchy. **Chosen:** a nested
hierarchy — loop count → stay count → prescaler count → clock — each outer boundary composed from
the settled trailing edges below.

**Rationale:** The architect's New-Year metaphor makes this precise: a loop's year-end is the
accumulation of its stays' year-ends; each stay's of prescale-period year-ends; each prescale
period bottoms out at clock trailing edges. The busiest work happens at the lowest level's year-end,
and settledness propagates upward, so every level greets its new year already stable. This nesting
is exactly why phase-lock holds (prescaler-phase-resolution trace): the prescaler's year-end aligns
with the loop's because the loop length is an integer number of prescale periods — the hierarchy is
in register.

**代替案:** (a) 平坦——一つの後縁;(b) 入れ子のヒエラルキー。**選択:** 入れ子——ループカウント→ステイカウント→
プリスケーラカウント→クロック——各外側境界は下位の静定した後縁から構成される。**根拠:** アーキテクトの年末年始の
比喩がこれを精密にする: ループの年末はそのステイ群の年末の集積;各ステイのそれはプリスケール周期の年末の集積;各
プリスケール周期はクロックの後縁に底を打つ。最も忙しい仕事は最下層の年末で起こり、静定が上方へ伝播し、各層は既に
安定した新年を迎える。この入れ子こそ位相ロックが成立する理由（位相決着トレース）: ループ長がプリスケール周期の整数個
ゆえ、プリスケーラの年末がループの年末と揃う——ヒエラルキーがレジスタ済み（in register）。

### 5. Do the RH001–008 edits relate to the doctrine? / RH001-008 修正は原則と関係するか

**Alternatives:** (a) unrelated fixes; (b) trailing-edge conversions. **Chosen:** many RH001–008
edits are recognized post-hoc as trailing-edge conversions.

**Rationale:** This deepens "the solution was contained in the edits": the edits' common thread was
the doctrine. Foreground prescaling (C4-F8) makes commands end on prescale trailing edges; the
free-running phase-lock (C4-F9) is the hierarchy in register at the trailing edge; Stay-Set
clear/sync-only (C4-F10) removes the jitter that would smear the trailing edge. The Layer 4
verification that "caught up" to the architect's intent was, at root, the spec catching up to the
Trailing-Edge Doctrine the RH edits had already encoded.

**代替案:** (a) 無関係な修正;(b) 後縁化。**選択:** RH001-008 の多くは事後的に後縁化と認識される。**根拠:** これは
「解は改修に内包されていた」を深める: 改修群の共通の筋は原則だった。前景プリスケールド化（C4-F8）はコマンドを
プリスケール後縁で終わらせ;自由走行位相ロック（C4-F9）は後縁でヒエラルキーがレジスタ済みであること;Stay Set
クリア/同期のみ（C4-F10）は後縁を滲ませるジッタを除く。アーキテクトの本意に「追いついた」Layer 4 検証は、根本では、
RH 改修が既に符号化していた後縁主義に仕様が追いつくことだった。

### 6. Does the doctrine resolve Tie C4-T3? / 原則は Tie C4-T3 を解決するか

**Alternatives:** (a) leave as Tie / hybrid; (b) resolve as trailing edge. **Chosen:** RESOLVED as
trailing edge. C4-T3 is promoted from Tie to Fixed (trailing-edge firing).

**Rationale:** Under the doctrine, a queued operation fires at the trailing edge — the moment the
count completes — so the Stay literally ends when it should, and the next state's leading edge
begins into a settled world. The earlier "hybrid" lean (leading-edge match flag) is superseded:
emitting an action or a defining event on the leading edge contradicts the principle that the
leading edge is already-settled, not a place where things happen. (A sustained external strobe, if
needed, is a Formation-side concern derived from the trailing-edge match pulse, not a Core
leading-edge action.) This is the architect's ruling; the Layer 1 write-back will promote C4-T3 →
Fixed.

**代替案:** (a) Tie/ハイブリッドのまま;(b) 後縁で解決。**選択:** 後縁として解決。C4-T3 を Tie から Fixed（後縁発火）へ
昇格。**根拠:** 原則の下、キュー演算は後縁——カウントが完了する瞬間——で発火し、ゆえに Stay は終わるべき時に文字通り
終わり、次状態の前縁は静定した世界で始まる。以前の「ハイブリッド」傾向（前縁一致フラグ）は置き換えられる: 前縁で
アクションや定義的事象を発することは、前縁が「事が起こる場所」でなく「既に静定した場所」であるという原則に反する。
（持続的な外部ストローブが要るなら、それは後縁一致パルスから導かれる Formation 側の関心事であって、Core の前縁
アクションではない。）これはアーキテクトの裁定;Layer 1 書き戻しが C4-T3 → Fixed へ昇格する。

### 7. Are there exceptions, and what governs them? / 例外はあるか、何が統べるか

**Alternatives:** (a) no exceptions — the doctrine is absolute; (b) principled exceptions exist.
**Chosen:** principled exceptions exist — foreground-executed StaySet and Reset are
leading-edge-placed, at the first clock cycle marking a state's start.

**Rationale:** The exceptions do not break the doctrine; they **stand on** it. StaySet and Reset
mark the START of a state, so they belong on the leading edge. They can be safely placed there ONLY
because the doctrine guarantees the leading edge is settled — i.e. they depend on the precondition
that the immediately preceding command has ended on a prescaler tick (a trailing edge). The
exception is therefore a consequence of the principle, not a violation: trailing-edge determination
upstream is exactly what makes a clean leading-edge placement possible downstream. This is the same
structure as Reset's foreground band (reset-command-bands trace) and state-0's NOP delegation
(state-0 trace): a leading-edge act made safe by upstream trailing-edge settledness.

**代替案:** (a) 例外なし——原則は絶対;(b) 原則的な例外がある。**選択:** 原則的な例外がある——前景実行される StaySet と
Reset は、ある状態の開始を表す前縁の最初のクロックサイクルに配置される。**根拠:** 例外は原則を破らない;原則の**上に
立つ**。StaySet と Reset は状態の開始を標すゆえ前縁に属す。そこに安全に置けるのは、ただ原則が前縁を静定させているから
である——すなわち、直前のコマンドがプリスケーラティック（後縁）で終わっているという前提に依存する。ゆえに例外は原則の
帰結であって違反ではない: 上流の後縁確定こそが、下流の清潔な前縁配置を可能にする。これは Reset の前景帯域（Reset 帯域
トレース）と state-0 の NOP 委譲（state-0 トレース）と同じ構造: 上流の後縁静定によって安全になった前縁のアクション。

### 8. Where to record the doctrine and its exceptions? / 原則と例外をどこに記すか

**Alternatives:** (a) scattered notes; (b) a first-class principle in Chapter 1, referenced from each
decision. **Chosen:** (b) — state it in Chapter 1 (Design Philosophy), alongside time-axis/space-axis
separation, cross-referenced from each derived decision. (Layer 1 write-back to follow; final wording
is the architect's.)

**Rationale:** A principle belongs with the other principles, so a reader meets it before the
decisions it generates. Each edge-related decision then cites it, so the dependency is legible:
EDGE=NEG, C4-F8/F9/F10, the trailing-edge resolution of C4-T3, and the StaySet/Reset exceptions all
point back to one root. This maximizes re-derivability (the Open Prompt ideal). The amanuensis
proposes; the Chapter 1 wording and the C4-T3 promotion are the architect's to finalize.

**代替案:** (a) 散在する注;(b) 第1章の第一級原則、各決定から参照。**選択:** (b)——第1章（設計哲学）に、時間軸/空間軸
分離と並べて記し、各派生決定から相互参照。（Layer 1 書き戻しは後続;最終文言はアーキテクト。）**根拠:** 原則は他の
原則と共にあるべきで、読者はそれが生む決定より前にそれに出会う。各縁関連決定がそれを引用し、依存が可読になる:
EDGE=NEG、C4-F8/F9/F10、C4-T3 の後縁解決、StaySet/Reset 例外がすべて一つの根を指す。これが再導出可能性（Open Prompt の
理想）を最大化する。祐筆は提案する;第1章の文言と C4-T3 昇格はアーキテクトが確定する。

---

## Major Themes / 主要テーマ

### Theme 1 — Settled-by-trailing, clean-at-leading / 後縁で静定、前縁で清潔
The doctrine is about completion, not just timing: all determination finishes by the trailing edge
of a boundary, so crossing into the next state at the leading edge is a crossing into an
already-settled world. The busy work is done before the boundary. This gives PTSG its communication-
and video-sync-grade rigor: every boundary crossing is clean because nothing is still resolving when
it happens.

原則は単なるタイミングでなく完了についてである: あらゆる確定は境界の後縁までに終わり、ゆえに前縁で次状態へ越境する
ことは既に静定した世界への越境である。忙しい仕事は境界の前に済む。これが PTSG に通信・ビデオ同期グレードの厳格性を
与える: 越境の瞬間に何も確定中でないから、あらゆる越境が清潔である。

### Theme 2 — A recursive doctrine that bottoms out at the clock / クロックに底を打つ再帰的原則
Trailing-edge determination recurses all the way down to the memory clock, made falling-edge
(EDGE=NEG) so the clock has its own trailing edge at which fetched data resolves, leaving the rising
edge clean. Recognizing EDGE=NEG as the doctrine reaching silicon — not a stale-fetch workaround —
explains WHY the choice was right. The principle reaches the root.

後縁確定はメモリクロックにまで再帰し、それを立下り（EDGE=NEG）にすることでクロックは自身の後縁を持ち、そこで
フェッチデータが確定し、立ち上がりは清潔に保たれる。EDGE=NEG を、stale-fetch の回避でなく、シリコンに達した原則と
認識することが、なぜその選択が正しかったかを説明する。原則は根に達する。

### Theme 3 — The nested New-Year hierarchy / 入れ子の年末年始ヒエラルキー
loop → stay → prescaler → clock: each level's boundary (its "year-end") is composed from the settled
trailing edges of the level below, and settledness propagates upward so every level greets its "new
year" stable. The architect's metaphor — humans work hardest at year-end so the new year begins calm
— captures the upward propagation. Phase-lock is this hierarchy in register: the prescaler's year-end
aligns with the loop's because the loop is an integer number of prescale periods.

ループ→ステイ→プリスケーラ→クロック: 各層の境界（その「年末」）は下位層の静定した後縁から構成され、静定が上方へ
伝播し、各層は「新年」を安定して迎える。アーキテクトの比喩——人は年末に最も忙しく働き、新年が穏やかに始まるように——が
上方伝播を捉える。位相ロックはこのヒエラルキーがレジスタ済みであること: ループがプリスケール周期の整数個ゆえ、
プリスケーラの年末がループの年末と揃う。

### Theme 4 — The RH edits were trailing-edge conversions / RH 改修は後縁化だった
The common thread of RH001-008 was the doctrine. Foreground prescaling, the free-running phase-lock,
and Stay-Set clear/sync-only all push determination onto trailing edges and remove anything that
would smear them. "The solution was contained in the edits" deepens here: the edits encoded the
doctrine, and Layer 4 / Layer 1 were the spec catching up to a principle already committed to
silicon.

RH001-008 の共通の筋は原則だった。前景プリスケールド化・自由走行位相ロック・Stay Set クリア/同期のみは、いずれも
確定を後縁へ押しやり、後縁を滲ませるものを除く。「解は改修に内包されていた」はここで深まる: 改修は原則を符号化し、
Layer 4 / Layer 1 は既にシリコンに委ねられた原則に仕様が追いつくことだった。

### Theme 5 — Exceptions that stand on the principle / 原則の上に立つ例外
Foreground StaySet and Reset are leading-edge-placed because they mark a state's START. They are not
violations: they are safe precisely because the doctrine guarantees the leading edge is settled (the
preceding command ended on a prescaler tick). The exception depends on the principle. This is the
same structure as Reset's foreground band and state-0's NOP delegation — a clean leading-edge act
enabled by upstream trailing-edge settledness. A principle is best understood through the exceptions
it makes safe.

前景 StaySet と Reset は状態の開始を標すゆえ前縁に配置される。違反ではない: 安全なのは、まさに原則が前縁を静定させて
いるから（直前のコマンドがプリスケーラティックで終わった）。例外は原則に依存する。これは Reset の前景帯域と state-0 の
NOP 委譲と同じ構造——上流の後縁静定によって可能になった清潔な前縁アクション。原則は、それが安全にする例外を通じて
最もよく理解される。

---

## Resumption Hooks / 再開フック

### Hook A — Chapter 1 write-back: state the Trailing-Edge Doctrine / 第1章書き戻し: 後縁主義を記す
DP-8 routes a first-class principle into Chapter 1 (Design Philosophy): the completion statement, the
nested hierarchy, EDGE=NEG as its silicon root, and the StaySet/Reset exceptions. Final wording is the
architect's.
**Starting question:** Draft the Chapter 1 principle — the completion statement (settled-by-trailing,
clean-at-leading), the loop→stay→prescaler→clock hierarchy, EDGE=NEG as the doctrine at the clock, and
the StaySet/Reset exceptions. What is the minimal wording, and which cross-references (C4-F8/F9/F10,
C4-T3, EDGE=NEG) does it carry?

### Hook B — C4-T3 promotion to Fixed (trailing edge) / C4-T3 の Fixed 昇格（後縁）
DP-6 resolves C4-T3 in the trailing direction; the write-back promotes it from Tie to Fixed and
removes the hybrid lean.
**Starting question:** Revise Chapter 4 § 4.9 and § 4.12: C4-T3 → Fixed, queued firing at the trailing
edge, the leading-edge-flag hybrid superseded (sustained strobes are a Formation concern derived from
the trailing-edge pulse). Update the conformance matrix accordingly. What is the exact new wording?

### Hook C — Audit the spec for any leading-edge actions / 仕様の前縁アクション監査
If the doctrine is now first-class, any Core action specified to occur on a leading edge is either an
error or a documented exception.
**Starting question:** Sweep Chapters 2–5 for any specified leading-edge action or determination.
Classify each as (i) correctly trailing, (ii) a sanctioned StaySet/Reset-style exception, or (iii) an
inconsistency to fix. Produce the list.

### Hook D — Formalize the exception precondition for new features / 新機能の例外前提を形式化
Any future leading-edge-placed command (like StaySet/Reset) must depend on the guarantee that the
preceding command ended on a prescaler tick. This precondition should be a stated extension rule.
**Starting question:** State the extension rule: a command may be leading-edge-placed only if the
doctrine guarantees its leading edge is settled (preceding command ended on a trailing edge /
prescaler tick). How should a Formation or Core extension author check this precondition before adding
such a command?

### Hook E — Trailing-edge and master/slave sync (forward to Build Log #9) / 後縁主義とマスター/スレーブ同期
The free-running prescaler's raw (pre-register) tick externalization for master/slave sync interacts
with the doctrine: slaves must register the master's tick on their own clock's trailing-edge
discipline.
**Starting question:** When drafting the master/slave material (Build Log #9), show how the raw-tick
externalization respects the doctrine across chips: does each slave's local trailing-edge
determination keep the hierarchy in register with the master, and what happens at the slave's clock
boundary?

---

## End of Trace / 軌跡の末尾

Every new year, the work is done in the old one. PTSG keeps this faith at every scale: a loop, a
stay, a prescale period, a single clock — each finishes its accounting at the trailing edge so that
the next one may begin already settled. The discipline reaches all the way down to the clock, which
was taught to fall so that its rising would find nothing left to decide. And the two commands that
start a year — StaySet and Reset — are allowed to stand at the leading edge for exactly one reason:
the doctrine has already made that edge a clean and quiet place to stand.

新しい年の仕事は、古い年のうちに済ませる。PTSG はこの信義をあらゆるスケールで守る: ループ、ステイ、プリスケール
周期、一つのクロック——どれも後縁で勘定を終え、次のものが既に静定した状態で始められるように。規律はクロックにまで
達し、クロックは立ち下がるよう教えられた——その立ち上がりが、もう決めるべき何も残っていない場所であるように。
そして年を始める二つの命令——StaySet と Reset——が前縁に立つことを許されるのは、ただ一つの理由による: 原則が既に、
その前縁を、静かで清潔な立ち場にしておいたからである。

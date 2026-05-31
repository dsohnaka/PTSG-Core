# PTSG-Core — Layer 1 Specification
# Chapter 4: Indirect Addressing and Prescaler
# PTSGコア — 第1層仕様書
# 第4章：間接アドレッシングとプリスケーラ

> **License: CC0 1.0 Universal (Public Domain)**
> This chapter specifies the indirect-addressing mechanism (the literal-zero-as-escape extensions for Jump operand 0 and Loop target 0 deferred from Chapters 2 and 3), the indirect-read bus shared between these uses, the prescaler (its necessity, its placement, its four configuration alternatives, and its interactions with background execution), and resolves or formally records the prescaler-coupled Ties C3-T10 and C3-T11 deferred from Chapter 3 v1.1.
>
> **ライセンス：CC0 1.0 Universal（パブリックドメイン）**
> 本章は、間接アドレッシング機構(第2章と第3章から繰り延べられた Jump オペランド 0 と Loop 目標 0 の直値ゼロエスケープ拡張)、これらの用途間で共有される間接読みバス、プリスケーラ(その必要性、配置、四つの構成代替案、裏実行との相互作用)を指定し、第3章 v1.1 から繰り延べられたプリスケーラ結合の Tie である C3-T10 と C3-T11 を解決するか正式に記録する。

---

> ### Version Note — v1.0 (Deliberation-Stage Release) / バージョンノート — v1.0（協議段階リリース）
>
> **This is the v1.0 deliberation-stage release of Chapter 4.** Following the same pattern as Chapters 2 and 3 v1.0, the chapter is published with explicit Tie / Convention / Fixed classifications, where Ties are alternatives the contributor leaves open for community deliberation. This chapter was drafted at the architect's request because reading PTSG-Core through Chapters 1–3 v1.1 has made the latent content of Chapters 4–5 inferable to careful AI readers — to the point that they could begin code generation from inferred details. Specifying these chapters now closes the gap before independent inferences diverge.
>
> **これは第4章の v1.0 協議段階リリースである。** 第2章および第3章 v1.0 と同じパターンに従い、本章は明示的な Tie / Convention / Fixed 分類とともに公開され、Tie は貢献者がコミュニティ協議のために開いたままにしておく代替案である。本章は、第1〜3章 v1.1 を通じて PTSG-Core を読むことが、注意深い AI 読者にとって第4〜5章の潜在的内容を推論可能にした——彼らが推論された詳細からコード生成を始められるほどに——というアーキテクトの要請により起草された。これらの章を今指定することは、独立した推論が分岐する前にギャップを閉じる。

---

## 4.1 Purpose of this Chapter / 本章の目的

Chapters 2 and 3 specified the Core's static instruction-set surface and its dynamic background-execution mechanics. Several extension points were deferred to this chapter because they share a common architectural pattern: **the Core extends its reach by selectively delegating to external resources.** Specifically:

第2章と第3章はコアの静的命令セット表面と動的裏実行機構を指定した。いくつかの拡張点が本章に繰り延べられたが、それらは共通のアーキテクチャ的パターンを共有する: **コアは選択的に外部リソースに委任することで到達範囲を拡張する。** 具体的に:

- **Indirect addressing** (Jump operand 0, Loop target 0): the operand value is read from an external register rather than encoded literally in the instruction word. This extends the Core's reach to operands that change at runtime without consuming additional opcode space.
- **Prescaler**: the system clock is divided externally before reaching the stay/loop counters. This extends the Core's effective wait range from microseconds to seconds and beyond, without consuming additional operand bits.

- **間接アドレッシング**(Jump オペランド 0、Loop 目標 0): オペランド値が命令語に直接エンコードされる代わりに外部レジスタから読まれる。これは追加のオペコード空間を消費することなく、実行時に変化するオペランドへのコアの到達範囲を拡張する。
- **プリスケーラ**: システムクロックが ステイ／ループカウンタに到達する前に外部で分周される。これは追加のオペランドビットを消費することなく、コアの有効待機範囲をマイクロ秒から秒、そしてそれを超えて拡張する。

Both mechanisms exemplify the PTSG-Core minimalism discipline (Chapter 1 § 1.2): **the Core remains small; the resource cost is pushed to the Formation that actually needs the extension.** A Formation with no need for indirect addressing or extended wait ranges can omit the corresponding external resources, and the Core continues to function correctly using only the literal-encoded operand values and the unprescaled system clock.

両機構は PTSG コアミニマリズム規律(第1章 § 1.2)を例示する: **コアは小さなままに留まり、リソースコストは実際に拡張を必要とする Formation に押し出される。** 間接アドレッシングや拡張待機範囲を必要としない Formation は対応する外部リソースを省略でき、コアは直値エンコードされたオペランド値と非プリスケールのシステムクロックのみを使って正しく機能し続ける。

**Chapter 4 v1.0 contains five principal contributions:**

**第4章 v1.0 は五つの主要な貢献を含む:**

1. **A unified view of the literal-zero-as-escape pattern** (§ 4.2), distinguishing the *arithmetic* uses (Stay operand 0 = 4096, Branch operand 0 = self-loop) from the *indirect* uses (Jump operand 0, Loop target 0). Only the indirect uses are the subject of this chapter.
2. **The indirect-read bus specification** (§§ 4.3–4.5), establishing the shared protocol used by both indirect Jump and indirect Loop. Pin-level signaling is in Chapter 5.
3. **The prescaler's necessity** (§ 4.6) — established by the Gemini comprehension trace (`02_Reasoning_Traces/contributed/dsohnaka/2026-05-20_ptsg-comprehension-by-gemini.md`) and re-stated here as architectural fact, not convenience.
4. **The prescaler configuration Tie** (§ 4.7) — the four alternatives from Chapter 1 § 1.12 are systematized here for community deliberation.
5. **Resolution of Chapter 3 v1.1 Ties C3-T10 (prescale edge) and C3-T11 (Stay Set role)** (§ 4.9) — these are prescaler-coupled and now have enough context to be examined; the chapter records the contributor's analysis and leaves the final decisions as Ties pending community input.

1. **直値ゼロエスケープパターンの統一的視点**(§ 4.2)、*算術的*用途(Stay オペランド 0 = 4096、Branch オペランド 0 = 自己ループ)と*間接的*用途(Jump オペランド 0、Loop 目標 0)を区別する。間接用途のみが本章の主題である。
2. **間接読みバス仕様**(§§ 4.3-4.5)、間接 Jump と間接 Loop の両方で使われる共有プロトコルを確立する。ピンレベル信号は第5章にある。
3. **プリスケーラの必要性**(§ 4.6) —— Gemini 読解軌跡によって確立され、便利さではなくアーキテクチャ的事実としてここで再陳述される。
4. **プリスケーラ構成 Tie**(§ 4.7) —— 第1章 § 1.12 の四つの代替案がコミュニティ協議のためにここで体系化される。
5. **第3章 v1.1 Tie C3-T10(プリスケール縁)と C3-T11(Stay Set 役割)の解決**(§ 4.9) —— これらはプリスケーラ結合であり、今や検討に十分な文脈を持つ；章は貢献者の分析を記録し、最終決定はコミュニティ入力待ちの Tie として残す。

---

## 4.2 The Literal-Zero-as-Escape Pattern: A Unified View / 直値ゼロエスケープパターン: 統一的視点

Across the Core's instruction set, an operand value of **0** carries a special meaning rather than its literal arithmetic value. This is the **literal-zero-as-escape** convention, mentioned in passing in Chapters 2 and 3 and unified here. The pattern serves two architecturally distinct purposes:

コアの命令セット全体で、**0** というオペランド値は、その字義的な算術値ではなく特別な意味を運ぶ。これは**直値ゼロエスケープ**慣習であり、第2章と第3章でついでに触れられ、ここで統一される。本パターンは二つのアーキテクチャ的に異なる目的に奉仕する:

| Use | Opcode/Sub-op | Operand value | Special meaning | Type |
|---|---|---|---|---|
| Stay operand 0 | Stay (opcode 1) | 0 | 4096 clocks (the maximum count, since 0 in 12-bit would otherwise waste an encoding) / 4096 クロック(12ビットの 0 は他の場合エンコーディングを無駄にするため最大カウント) | **Arithmetic shortcut** |
| Branch operand 0 | Branch (opcode 2) | 0 | Self-loop / wait-for-Condition (the state remains current until Condition becomes true or insertion occurs) / 自己ループ／Conditionを待つ | **Arithmetic shortcut** |
| Jump operand 0 | Jump (opcode 3) | 0 | Indirect-mode: target address read from external register / 間接モード: ターゲットアドレスを外部レジスタから読む | **Indirect data source** |
| Loop target 0 (v1.1) | Loop (Global sub-op 5) | D16–D31 = 0 | Indirect-mode: target count read from external register / 間接モード: ターゲットカウントを外部レジスタから読む | **Indirect data source** |

**The two types are architecturally different.** Arithmetic shortcuts (Stay, Branch) repurpose an otherwise-degenerate operand value (literal 0 would mean "wait 0 clocks" or "branch by 0 states," both of which are meaningless) to provide a useful alternative semantic. The Core handles these entirely internally; no external interaction is required. Indirect data sources (Jump, Loop), by contrast, replace the literal operand with a *runtime-read* value from an external register. This **requires external interaction** via the indirect-read bus.

**二つのタイプはアーキテクチャ的に異なる。** 算術的近道(Stay、Branch)は、それ以外は退化したオペランド値(直値 0 は「0クロック待つ」または「0ステート分岐」を意味し、両方とも無意味)を、有用な代替的意味論を提供するために再目的化する。コアはこれらを完全に内部的に扱う；外部相互作用は不要。間接的データソース(Jump、Loop)は対照的に、直値オペランドを外部レジスタからの*実行時読み*値で置き換える。これは間接読みバス経由の**外部相互作用を要求する**。

This chapter focuses on the indirect-data-source cases. The arithmetic-shortcut cases were already fully specified in Chapter 2 (C2-F3 for Stay, C2-F5 for Branch) and need no further treatment.

本章は間接データソース事例に焦点を当てる。算術的近道事例は既に第2章で完全に指定された(Stay の C2-F3、Branch の C2-F5)、追加の取り扱いは不要。

**Why a single pattern for both Jump and Loop indirection.** The natural alternative would have been a dedicated opcode or sub-opcode for "indirect operations." The literal-zero-as-escape approach has three advantages:

**なぜ Jump と Loop の両方の間接化に単一パターンか。** 自然な代替案は「間接演算」のための専用オペコードまたはサブオペコードを持つことだろう。直値ゼロエスケープ手法は三つの利点を持つ:

- **No new opcode/sub-opcode consumed.** The 4 used + 12 reserved top-level opcode budget remains untouched. The internal-control 0–7 sub-opcode budget is similarly untouched.
- **No syntactic distinction in instruction lists.** A Jump with operand 5 and a Jump with operand 0 use the same opcode; the AI or human author needs only one mental model for "Jump."
- **Uniform external bus.** Indirect Jump and indirect Loop share a single indirect-read bus, simplifying the Core's external interface.

- **新しいオペコード／サブオペコードが消費されない。** 4個使用 + 12個予約のトップレベルオペコード予算は手付かずのまま。内部制御 0-7 サブオペコード予算も同様。
- **命令リストにおける構文的区別がない。** オペランド 5 の Jump とオペランド 0 の Jump は同じオペコードを使う；AI または人間の作者は「Jump」のための一つの心的モデルだけを必要とする。
- **統一された外部バス。** 間接 Jump と間接 Loop は単一の間接読みバスを共有し、コアの外部インターフェースを単純化する。

---

## 4.3 Indirect Jump (Jump operand = 0) / 間接 Jump (Jump オペランド = 0)

**Semantics.** When the Jump opcode (3) is executed with operand 0, the Core performs an **indirect jump**: it asserts a read request on the indirect-read bus (§ 4.5) with the purpose code identifying "indirect Jump," waits for the external logic to return a 12-bit target address, and then sets the State Number register to that target address (treating the address as absolute, exactly as a literal-operand Jump would).

**意味論。** Jump オペコード(3)がオペランド 0 で実行される時、コアは**間接ジャンプ**を実行する: 間接読みバス(§ 4.5)に「間接 Jump」を識別する目的コードと共に読み要求をアサートし、外部ロジックが 12ビットのターゲットアドレスを返すのを待ち、それからステートナンバーレジスタをそのターゲットアドレスに設定する(直値オペランド Jump と同じく、アドレスを絶対として扱う)。

**Use cases.** Indirect Jump enables several patterns that literal Jump cannot:

**使用事例。** 間接 Jump は、直値 Jump では不可能ないくつかのパターンを可能にする:

- **Jump tables.** A Formation maintains an externally-writable register holding the desired branch target. An earlier instruction (via external register write) sets the target; a later indirect Jump dispatches to it. This is the classic "switch on N alternatives" pattern without consuming N states for an if-else chain.
- **Runtime mode dispatch.** A Formation's operating mode (e.g., "playback mode" vs "recording mode" in a WPMS-style application) selects an indirect Jump target, dispatching to the appropriate sub-sequence.
- **AI-driven re-targeting.** An AI agent generating the instruction list can leave decision points as indirect Jumps and supply target addresses externally based on runtime conditions, without modifying the instruction memory.

- **ジャンプテーブル。** Formation は希望するブランチターゲットを保持する外部書き込み可能なレジスタを維持する。先行する命令(外部レジスタ書き込み経由)がターゲットを設定する；後の間接 Jump がそれにディスパッチする。これは if-else 連鎖に N ステートを消費することなく、「N 個の代替案による分岐」の古典的パターンである。
- **実行時モードディスパッチ。** Formation の動作モード(例: WPMS スタイル応用における「再生モード」対「録音モード」)が間接 Jump ターゲットを選択し、適切なサブシーケンスにディスパッチする。
- **AI 駆動再ターゲティング。** 命令リストを生成する AI エージェントは、決定点を間接 Jump として残し、命令メモリを変更することなく実行時条件に基づき外部でターゲットアドレスを供給できる。

**Interaction with Branch.** Note that Branch (opcode 2) does *not* have an indirect mode: Branch's operand 0 is the self-loop / wait-for-Condition idiom (C2-F5), a different semantic that the Core uses heavily for protocol synchronization. A Formation needing an indirect *conditional* branch can compose: a Branch (operand 0) waiting for a flag, followed by a Jump (operand 0) using the indirect address. This composition is intentional; promoting an indirect-conditional-branch to a single opcode is a Future Layer 2 trace topic, not a v1.0 commitment.

**Branch との相互作用。** Branch(オペコード 2)は間接モードを*持たない*ことに注意: Branch のオペランド 0 は自己ループ／Condition 待ちイディオム(C2-F5)であり、コアがプロトコル同期に多用する異なる意味論である。間接*条件付き*分岐を必要とする Formation は合成できる: フラグを待つ Branch(オペランド 0)、その後に間接アドレスを使う Jump(オペランド 0)。この合成は意図的である；間接条件付き分岐を単一オペコードに昇格させることは Future Layer 2 trace の話題であり、v1.0 のコミットメントではない。

---

## 4.4 Indirect Loop Target (Loop with D16–D31 = 0) / 間接 Loop 目標 (D16-D31 = 0 の Loop)

**Semantics.** When the Loop sub-opcode (5) is executed with the D16–D31 extended-operand field equal to 0 (v1.1; see Chapter 2 § 2.7 and Chapter 3 § 3.11), the Core performs an **indirect loop target read**: it asserts a read request on the indirect-read bus with the purpose code identifying "indirect Loop target," waits for the external logic to return a 12-bit target count, and uses that count as the up-count comparison target. The rest of the Loop semantics (up-count from 0, compare to target, exit-and-auto-clear, match-flag pulse) is unchanged.

**意味論。** Loop サブオペコード(5)が D16-D31 拡張オペランドフィールドが 0 で実行される時(v1.1；第2章 § 2.7 と第3章 § 3.11 参照)、コアは**間接ループ目標読み**を実行する: 間接読みバスに「間接 Loop 目標」を識別する目的コードと共に読み要求をアサートし、外部ロジックが 12ビットのターゲットカウントを返すのを待ち、そのカウントをアップカウント比較目標として使う。Loop 意味論の残り(0 からのアップカウント、目標との比較、脱出と自動クリア、一致フラグパルス)は変わらない。

**Use cases.**

**使用事例。**

- **Runtime-determined loop counts.** A Formation can compute or measure a value (e.g., a sample count, a packet length, a sensor reading) and write it to the indirect-target register before the loop begins; the loop then iterates exactly that many times.
- **Coordinated loop boundaries.** Multiple loops in different parts of an instruction list can share an external target register, ensuring they iterate the same number of times even when that number is determined at runtime.
- **WPMS waveform-length parametrization.** The WPMS Formation (under design) can use indirect Loop to make waveform period or sample-count parameters dynamic without rewriting the instruction list.

- **実行時決定のループ数。** Formation は値(例: サンプル数、パケット長、センサ読み)を計算または測定でき、ループ開始前に間接目標レジスタに書ける；ループはそれからちょうどその回数反復する。
- **協調するループ境界。** 命令リストの異なる部分の複数のループが外部目標レジスタを共有でき、その数が実行時に決定されてもそれらが同じ回数反復することを保証する。
- **WPMS 波形長パラメータ化。** WPMS Formation(設計中)は、波形周期やサンプル数パラメータを命令リスト書き直しなしに動的にするため、間接 Loop を使える。

**Target value 0 in indirect mode.** What happens if the indirect-read returns 0? The Loop's exit condition (counter = target) is immediately true on the first iteration. Under up-count semantics (v1.1), this means the loop body never executes (counter starts at 0, target is 0, exit on first compare). This matches the "for (i=0; i<0; i++)" semantic and is the contributor's intended interpretation. Recorded as **Convention** C4-V1 in § 4.13.

**間接モードでの目標値 0。** 間接読みが 0 を返したら何が起こるか? Loop の脱出条件(カウンタ = 目標)は最初の反復で即座に真となる。アップカウント意味論の下(v1.1)、これはループ本体が決して実行されないことを意味する(カウンタは 0 から始まり、目標は 0、最初の比較で脱出)。これは "for (i=0; i<0; i++)" 意味論と一致し、貢献者の意図する解釈である。§ 4.13 で **Convention** C4-V1 として記録。

---

## 4.5 The Indirect-Read Bus — Common Protocol / 間接読みバス — 共通プロトコル

Both indirect Jump and indirect Loop use a shared bus to read the runtime-supplied 12-bit operand. The bus is specified here at the **protocol level**; pin-level details are in Chapter 5.

間接 Jump と間接 Loop は両方とも、実行時に供給される 12ビットオペランドを読むために共有バスを使う。バスはここで**プロトコルレベル**で指定される；ピンレベルの詳細は第5章にある。

**Conceptual signals.**

**概念的信号。**

| Signal | Width | Direction | Purpose |
|---|---|---|---|
| `indirect_req` | 1 bit | Core → External | Asserted by the Core for one clock when an indirect-read is needed / 間接読みが必要な時にコアが 1 クロックアサートする |
| `indirect_purpose` | 2 bits | Core → External | Identifies which indirect use (00 = indirect Jump, 01 = indirect Loop target, 10/11 reserved) / どの間接用途かを識別する(00 = 間接 Jump、01 = 間接 Loop 目標、10/11 予約) |
| `indirect_data` | 12 bits | External → Core | The 12-bit operand value the Core uses / コアが使う 12ビットオペランド値 |
| `indirect_ready` | 1 bit | External → Core | Asserted by external logic when `indirect_data` is valid / `indirect_data` が有効な時に外部ロジックがアサートする |

**The shared-bus design vs per-purpose buses — Convention.** The contributor's intent is a single shared bus distinguished by `indirect_purpose` (above). The alternative — separate buses for indirect Jump and indirect Loop — would simplify external logic at the cost of more Core pins. The shared-bus approach is recorded as **Convention** C4-V2: it is the contributor's lean, but a Formation could be built with separate buses if the Formation's external logic strongly prefers that. The Core specification commits to the *protocol* (request + purpose + data + ready), not to the *physical multiplexing*.

**共有バス設計 対 用途別バス — Convention。** 貢献者の意図は `indirect_purpose`(上記)で区別される単一の共有バスである。代替案——間接 Jump と間接 Loop に分離されたバス——は、より多くのコアピンを引き換えに外部ロジックを単純化するだろう。共有バス手法は **Convention** C4-V2 として記録される: それは貢献者の傾向だが、Formation の外部ロジックがそれを強く好む場合、分離バスで Formation を構築できる。コア仕様は*プロトコル*(要求 + 用途 + データ + ready)にコミットし、*物理的多重化*にコミットしない。

**Handshake timing.** The handshake between `indirect_req` and `indirect_ready` has multiple reasonable interpretations:

**ハンドシェイクタイミング。** `indirect_req` と `indirect_ready` の間のハンドシェイクは複数の合理的な解釈を持つ:

- **(A) Combinational (zero-clock):** external logic drives `indirect_data` and asserts `indirect_ready` combinationally on the same clock that `indirect_req` is asserted. The Core captures the data on the next clock edge. Pros: minimum latency, no stalling. Cons: external logic must respond within the clock period (timing tight at high frequencies).
- **(B) Registered (one-clock):** external logic registers the request and presents data on the next clock with `indirect_ready` asserted. The Core stalls for one clock. Pros: easy timing closure for external logic. Cons: one-clock latency added to indirect Jump / indirect Loop.
- **(C) Variable (multi-clock):** external logic may take arbitrarily many clocks; the Core stalls until `indirect_ready` is asserted, then captures. Pros: maximum flexibility for slow external sources (e.g., reading from external SRAM). Cons: the Core must implement stall logic; instruction-list authors must reason about variable timing.

- **(A) 組み合わせ(ゼロクロック):** 外部ロジックが `indirect_req` がアサートされる同じクロックで `indirect_data` を駆動し `indirect_ready` を組み合わせ的にアサートする。コアは次のクロックエッジでデータを捕捉する。利点: 最小レイテンシ、停滞なし。欠点: 外部ロジックはクロック周期内に応答しなければならない(高周波数でタイミングが厳しい)。
- **(B) レジスタ付き(1クロック):** 外部ロジックが要求をレジスタし、次のクロックで `indirect_ready` アサートと共にデータを提示する。コアは 1 クロック停滞する。利点: 外部ロジックのタイミングクロージャが容易。欠点: 間接 Jump／間接 Loop に 1 クロックのレイテンシが加わる。
- **(C) 可変(複数クロック):** 外部ロジックは任意のクロック数を取り得る；コアは `indirect_ready` がアサートされるまで停滞し、それから捕捉する。利点: 遅い外部ソース(例: 外部 SRAM からの読み)に対する最大柔軟性。欠点: コアは停滞ロジックを実装しなければならない；命令リスト作者は可変タイミングについて推論しなければならない。

The handshake timing is recorded as **Tie** C4-T1 in § 4.13. The contributor's lean is **(B) registered**, balancing implementation simplicity with predictable timing.

ハンドシェイクタイミングは § 4.13 で **Tie** C4-T1 として記録される。貢献者の傾向は **(B) レジスタ付き**で、実装単純性と予測可能なタイミングのバランスを取る。

**Foreground vs background invocation.** Indirect Jump and indirect Loop can be invoked both in the foreground (outside a Stay window) and within a Stay window (as background-executed Globals). When in the immediate band before Prog End (Chapter 3 v1.1 § 3.3a), the indirect-read happens immediately. When in the queued band after Prog End, the indirect-read happens at Stay-timeup when the queued operation fires. Either way, the bus protocol is the same; only the timing of `indirect_req` differs by band.

**前景対裏側呼び出し。** 間接 Jump と間接 Loop は、前景(Stay ウィンドウの外)でも、Stay ウィンドウ内(裏実行された Global として)でも呼び出され得る。Prog End の前の即時帯域(第3章 v1.1 § 3.3a)では、間接読みは即時に起こる。Prog End の後のキュー帯域では、間接読みはキュー演算が発火する Stay-timeup で起こる。どちらにせよ、バスプロトコルは同じである；`indirect_req` のタイミングだけが帯域で異なる。

---

## 4.6 The Prescaler — Why It Is Necessary / プリスケーラ — なぜ必要か

The bare Stay opcode provides waits of 1 to 4096 clocks (Chapter 2 § 2.4). At typical FPGA clock rates, this corresponds to wait durations of:

裸の Stay オペコードは 1 から 4096 クロックの待機を提供する(第2章 § 2.4)。典型的な FPGA クロックレートで、これは以下の待機持続時間に対応する:

| System clock | Max bare Stay | Comment |
|---|---|---|
| 50 MHz | 81.92 µs | Sufficient for bus-protocol timing; far below human-perceivable durations / バスプロトコルタイミングに十分；人間が知覚できる持続時間には遠く及ばない |
| 100 MHz | 40.96 µs | |
| 200 MHz | 20.48 µs | |

A common audio-rate or display-rate task — for example, blinking an LED at half-second intervals — requires waits on the order of 25 million clocks at 50 MHz. This is approximately **6000× larger than the bare Stay can express.** Even chaining sequential Stays (using ~4000 states each waiting ~4000 clocks) cannot reach 25 million clocks within the Core's 12-bit address space of 4096 total states.

一般的な音声レートまたは表示レートのタスク——例えば、半秒間隔で LED を点滅させる——は、50 MHz で約 2500 万クロック程度の待機を必要とする。これは**裸の Stay が表現できるよりおよそ 6000 倍大きい。**順次 Stay を連鎖させる(~4000 ステートをそれぞれ ~4000 クロック待たせて使用)場合でも、コアの 12ビットアドレス空間 4096 ステート全体内で 2500 万クロックに達することはできない。

**Therefore, a prescaler is not a convenience but a mathematical/physical necessity** for any application requiring wait durations on the order of milliseconds or longer. This conclusion was established by the Gemini comprehension trace (Reading Note 3 of `02_Reasoning_Traces/contributed/dsohnaka/2026-05-20_ptsg-comprehension-by-gemini.md`) and is now formally recorded as **Fixed** C4-F1.

**したがって、プリスケーラは便利さではなく数学的／物理的必然である**、ミリ秒以上の待機持続時間を要求する任意の応用に対して。本結論は Gemini 読解軌跡(`02_Reasoning_Traces/contributed/dsohnaka/2026-05-20_ptsg-comprehension-by-gemini.md` の Reading Note 3)によって確立され、現在 **Fixed** C4-F1 として正式に記録される。

**What the prescaler does.** Conceptually, the prescaler is a clock divider sitting between the system clock and the input to the stay/loop counters. If the prescaler is set to divide-by-N, then each "tick" of the stay/loop counter occurs once every N system clocks, multiplying the effective Stay/Loop range by N.

**プリスケーラが何をするか。** 概念的に、プリスケーラは、システムクロックと ステイ／ループカウンタへの入力との間に位置するクロック分周器である。プリスケーラが N 分周に設定されると、ステイ／ループカウンタの各「ティック」は N システムクロックごとに 1 回起こり、有効な Stay／Loop 範囲を N 倍する。

| Prescaler N | Effective Stay range at 50 MHz | Effective Stay range at 100 MHz |
|---|---|---|
| 1 (no prescale) | 20 ns – 81.92 µs | 10 ns – 40.96 µs |
| 1000 | 20 µs – 81.92 ms | 10 µs – 40.96 ms |
| 50,000 | 1 ms – 4.096 s | 500 µs – 2.048 s |
| 1,000,000 | 20 ms – 81.92 s | 10 ms – 40.96 s |

**Prescaler scope — which counters are affected.** The prescaler ticks the Stay counter and (by C3-F18 in v1.1) the prescaler counter itself (whose match-flag is `prescaler_match`). **The Loop counter is *not* affected by the prescaler by default** — Loop counter increments occur in foreground (1 clock per Loop instruction) or in the immediate background band (1 clock per encounter), regardless of prescaler setting. This default is recorded as **Fixed** C4-F2: the prescaler is a time-axis device, and the Loop counter is a space-axis device. Mixing them would conflate axes. (A Formation needing prescaled Loop counting can use an external counter driven by `loop_cnt_match` and the prescaler clock combined.)

**プリスケーラの範囲——どのカウンタが影響を受けるか。** プリスケーラは Stay カウンタと(v1.1 の C3-F18 により)プリスケーラカウンタ自身(その一致フラグが `prescaler_match`)をティックさせる。**Loop カウンタは既定でプリスケーラの影響を*受けない*** —— Loop カウンタのインクリメントは、プリスケーラ設定に関わらず、前景(Loop 命令あたり 1 クロック)または即時裏側帯域(遭遇あたり 1 クロック)で起こる。この既定は **Fixed** C4-F2 として記録される: プリスケーラは時間軸装置であり、Loop カウンタは空間軸装置である。これらを混ぜると軸を混同する。(プリスケールされた Loop カウントを必要とする Formation は、`loop_cnt_match` とプリスケーラクロックを組み合わせて駆動される外部カウンタを使える。)

---

## 4.7 The Prescaler Configuration Tie — Four Alternatives / プリスケーラ構成 Tie — 四つの代替案

Chapter 1 § 1.12 deferred the prescaler's *placement and control* as a Tie with four alternatives. This section systematizes them.

第1章 § 1.12 はプリスケーラの*配置と制御*を四つの代替案を持つ Tie として繰り延べた。本節はそれらを体系化する。

| Alternative | Description | Pros | Cons | Resource cost |
|---|---|---|---|---|
| **(A) Compile-time fixed** | One prescaler value baked in at synthesis. The Formation chooses N when generating the FPGA bitstream. / 合成時に焼き付けられる一つのプリスケーラ値。Formation は FPGA ビットストリーム生成時に N を選ぶ。 | Simplest hardware; no operand bits consumed; deterministic; minimal LE / 最も単純なハードウェア；オペランドビット消費なし；決定的；最小 LE | Cannot change wait scale at runtime; one Formation = one prescaler setting / 実行時に待機スケール変更不可；一 Formation = 一プリスケーラ設定 | Smallest |
| **(B) Runtime-configurable** | Single prescaler register, settable via an external register write (e.g., external sub-op 1 to a designated address). The current value applies to all Stays until changed. / 単一のプリスケーラレジスタ、外部レジスタ書き込み経由で設定可能。現在の値は変更されるまですべての Stay に適用される。 | Can switch between coarse-grained and fine-grained wait regimes at runtime; small register cost / 実行時に粗粒度と細粒度の待機制度を切り替え可能；小さなレジスタコスト | Switching prescaler requires a Stay-window-internal register write (uses Global slots); transitions may have edge cases / プリスケーラ切替は Stay ウィンドウ内レジスタ書き込みを要求する(Global スロットを使う)；遷移にエッジケースの可能性 | Small |
| **(C) Per-stay-selectable** | The Stay instruction itself includes a small "prescaler-select" field selecting among N pre-configured prescaler values. Different Stays in the same program can use different prescalers. / Stay 命令自身が小さな「プリスケーラ選択」フィールドを含み、N 個の事前設定されたプリスケーラ値の中から選択する。同じプログラム内の異なる Stay が異なるプリスケーラを使える。 | Maximum expressiveness; no extra instruction overhead for switching / 最大の表現力；切替のための余分な命令オーバーヘッドなし | Stay's operand space is partially consumed (e.g., 2 bits for 4 prescaler choices); requires N parallel prescaler counters / Stay のオペランド空間が部分的に消費される(例: 4 プリスケーラ選択に 2 ビット)；N 個の並列プリスケーラカウンタを要求する | Medium |
| **(D) Multiple-parallel** | Multiple independent prescalers, all running, selectable per-Stay via a "prescaler-bank" field. Differs from (C) in that the prescalers run independently with potentially different N values continuously. / 複数の独立したプリスケーラ、すべて走り、Stay 毎に「プリスケーラバンク」フィールド経由で選択可能。(C) との違いは、プリスケーラが潜在的に異なる N 値で連続的に独立して走ること。 | Allows simultaneous coarse + fine timing in the same program; useful for nested rhythms / 同じプログラムで同時の粗 + 細タイミングを許可；ネストしたリズムに有用 | Most LE-expensive; requires careful documentation per Formation / 最も LE 高コスト；Formation 毎の注意深い文書化を要求 | Largest |

**The contributor's lean — and why it is recorded as Tie not Fixed.** The contributor leans toward **(A) compile-time fixed for the Core**, with **(B) runtime-configurable as a Formation-extension option** if a Formation explicitly needs it. The reasoning: (A) preserves Core minimalism; the WPMS Formation (currently under design) appears to need only a single prescaler value per running configuration; and the runtime case can be added at the Formation level via external register write without modifying the Core. However, this is recorded as **Tie** C4-T2 because: (i) other Formations (e.g., audio synthesizers with simultaneous LFO and modulation timing) genuinely may need (C) or (D); (ii) the choice has ABI implications for the Core (specifically, whether Stay's operand or the instruction word's reserved bits are consumed). Community input invited.

**貢献者の傾向 ——そしてそれが Fixed ではなく Tie として記録される理由。** 貢献者は**コアには (A) 合成時固定**、Formation が明示的に必要とすれば **Formation 拡張オプションとして (B) 実行時設定可能**に傾く。理由: (A) はコアミニマリズムを保持する；WPMS Formation(現在設計中)は実行中構成あたり単一のプリスケーラ値のみを必要とするように見える；そして実行時事例はコアを変更することなく外部レジスタ書き込み経由で Formation レベルで追加できる。しかし、これは **Tie** C4-T2 として記録される、なぜなら: (i) 他の Formation(例: 同時 LFO とモジュレーションタイミングを持つオーディオシンセサイザー)は (C) や (D) を真に必要とし得る；(ii) この選択はコアの ABI 含意を持つ(具体的に、Stay のオペランドまたは命令語の予約ビットが消費されるかどうか)。コミュニティ入力を招く。

---

## 4.8 Prescaler Interactions with Background Execution / プリスケーラと裏実行の相互作用

The prescaler interacts with the v1.1 background-execution model (Chapter 3 § 3.3a) in specific ways:

プリスケーラは v1.1 の裏実行モデル(第3章 § 3.3a)と特定の方法で相互作用する:

**Foreground states run at full system clock.** A state advances every system clock regardless of prescaler setting. Foreground Stay, Branch, Jump, and Global instructions take 1 system clock each (subject to C2-T4).

**前景ステートはフルシステムクロックで走る。** ステートはプリスケーラ設定に関わらずシステムクロック毎に進む。前景 Stay、Branch、Jump、Global 命令はそれぞれ 1 システムクロックを取る(C2-T4 対象)。

**The Stay window's wait scales with prescaler.** Once a Stay instruction is reached and the Core halts waiting for the stay counter to reach the operand value, the stay counter ticks at the *prescaled* rate. So a Stay with operand 1000 and prescaler 50,000 waits 1000 × 50,000 = 50,000,000 system clocks (1 second at 50 MHz).

**Stay ウィンドウの待機はプリスケーラに合わせてスケールする。** Stay 命令に到達しコアがステイカウンタがオペランド値に達するのを待つために停止すると、ステイカウンタは*プリスケールされた*レートでティックする。したがってオペランド 1000、プリスケーラ 50,000 の Stay は 1000 × 50,000 = 50,000,000 システムクロック待つ(50 MHz で 1 秒)。

**The immediate-band background program runs at full system clock.** This is the crucial design point. The Stay window's *background-program-execution band* (between Stay Set and Prog End, Chapter 3 v1.1 § 3.3a) advances at the system clock rate, *not* the prescaled rate. This is what makes background execution useful: an instruction-list author can fit a complex background subroutine (multiple Loops, external register writes, etc.) into a single prescaled stay tick, then have the rest of the Stay window be wait time. Recorded as **Fixed** C4-F3.

**即時帯域裏プログラムはフルシステムクロックで走る。** これは決定的な設計点である。Stay ウィンドウの*裏プログラム実行帯域*(Stay Set と Prog End の間、第3章 v1.1 § 3.3a)は、プリスケールされたレートではなく、システムクロックレートで進む。これが裏実行を有用にするものである: 命令リスト作者は、複雑な裏側サブルーチン(複数の Loop、外部レジスタ書き込み等)を単一のプリスケールされたステイティックに収め、Stay ウィンドウの残りを待機時間にできる。**Fixed** C4-F3 として記録。

**The queued-band executes at Stay-timeup, prescaler-aligned.** Operations after Prog End fire at Stay-timeup. Since Stay-timeup is determined by the prescaled counter reaching the operand value, queued operations are inherently aligned to a prescaler boundary. This is the source of Tie C3-T10 (prescale edge for queued execution), addressed in § 4.9.

**キュー帯域は Stay-timeup で、プリスケーラに整列して実行される。** Prog End の後の演算は Stay-timeup で発火する。Stay-timeup はプリスケールされたカウンタがオペランド値に達することによって決定されるため、キュー演算は本質的にプリスケーラ境界に整列する。これは Tie C3-T10(キュー実行のプリスケール縁)の出所であり、§ 4.9 で扱われる。

---

## 4.9 Resolution of C3-T10 (Prescale Edge) and C3-T11 (Stay Set Role) / C3-T10(プリスケール縁)と C3-T11(Stay Set 役割)の解決

Two Ties deferred from Chapter 3 v1.1 are prescaler-coupled and are addressed here. Both remain Ties pending community input; this section records the contributor's analysis and tentative lean.

第3章 v1.1 から繰り延べられた二つの Tie がプリスケーラ結合であり、ここで扱われる。両方ともコミュニティ入力を待つ Tie のままである；本節は貢献者の分析と暫定的傾向を記録する。

### C3-T10 — Prescale Evaluation Timing (Leading vs Trailing Edge)

**The question.** When a queued operation fires at Stay-timeup, where within the prescale period does it fire — at the **leading edge** of the prescale period that completes the count, or at the **trailing edge**?

**問い。** キュー演算が Stay-timeup で発火する時、プリスケール周期のどこで発火するか——カウントを完了するプリスケール周期の**前縁**か、**後縁**か?

**Alternatives:**

- **(A) Leading edge:** the queued operation fires at the *beginning* of the prescale period in which the counter reaches its target. The match flag (`stay_cnt_match`) is asserted at the leading edge and held for the full prescale period. Pros: external hardware has a full prescale period (potentially long) to react to the match flag — useful as a sustained strobe. Cons: the "Stay completes" event is now misaligned with the literal end of the wait — slightly counter-intuitive.
- **(B) Trailing edge:** the queued operation fires at the *end* of the prescale period in which the counter reaches its target — i.e., exactly when the Stay actually ends. The match flag is asserted for 1 system clock at this trailing edge. Pros: aligned with intuition (Stay ends → operations fire). Cons: short match-flag pulse may be hard for slow external logic to capture.

- **(A) 前縁:** キュー演算はカウンタが目標に達するプリスケール周期の*始まり*で発火する。一致フラグ(`stay_cnt_match`)は前縁でアサートされ、完全なプリスケール周期にわたって保持される。利点: 外部ハードウェアが一致フラグに反応するのにフルプリスケール周期(潜在的に長い)を持つ——持続的なストローブとして有用。欠点: 「Stay 完了」イベントが今や字義的な待機の終わりと不整合——わずかに直感に反する。
- **(B) 後縁:** キュー演算はカウンタが目標に達するプリスケール周期の*終わり*で発火する——つまり、Stay が実際に終わるちょうどその時。一致フラグはこの後縁で 1 システムクロック アサートされる。利点: 直感と整列(Stay 終わり → 演算発火)。欠点: 短い一致フラグパルスは遅い外部ロジックには捕捉が難しい場合がある。

**Contributor's lean.** **(A) leading edge** for the match flag (full-prescale-period hold gives external logic time to react cleanly) but **(B) trailing edge** for the actual queued-operation firing (so that the Stay literally ends when it should). This is technically a hybrid: the flag is leading-edge, the action is trailing-edge. The hybrid may be the most useful in practice but requires careful Chapter 5 specification. Recorded as **Tie** C4-T3 with the hybrid as the leading proposal.

**貢献者の傾向。** 一致フラグには **(A) 前縁**(フルプリスケール周期保持は外部ロジックが綺麗に反応する時間を与える)、しかし実際のキュー演算発火には **(B) 後縁**(Stay は実際に終わるべき時に文字通り終わるように)。これは技術的にはハイブリッドである: フラグは前縁、アクションは後縁。ハイブリッドは実際には最も有用かもしれないが、第5章の注意深い仕様化を要求する。ハイブリッドを先頭提案として **Tie** C4-T3 で記録。

### C3-T11 — Stay Set Exact Role

**The question.** Should Stay Set (Global sub-opcode 2) be only a clear/sync command (resetting and arming the stay counter, with the actual count starting at Prog End or at the Stay instruction), or should it immediately start the stay counter? The Gemini deliberation raised this because immediate-start makes the background program's clocks (between Stay Set and Stay) implicitly part of the wait, potentially introducing jitter if the number of background instructions varies.

**問い。** Stay Set(Global サブオペコード 2)は単なるクリア／同期コマンド(ステイカウンタをリセットしてアームし、実際のカウントは Prog End または Stay 命令で始まる)であるべきか、それともステイカウンタを即座に開始すべきか? Gemini 協議は、即座開始が裏プログラムのクロック(Stay Set と Stay の間)を暗黙に待機の一部にし、裏側命令の数が変動するとジッタを導入する可能性があるためにこれを提起した。

**Alternatives:**

- **(A) Immediate start (v1.0 behavior):** Stay Set asserts and starts the stay counter from 0; the count begins on the clock after Stay Set. Background program clocks are part of the wait. Pros: simple; the stay counter is straightforwardly the "time since Stay Set." Cons: variable background-program length causes variable effective wait — jitter.
- **(B) Clear/sync only:** Stay Set resets the stay counter to 0 and arms it, but the counter does *not* start ticking. The actual count starts when **Prog End** is encountered (or when the Stay instruction is reached, if no Prog End is present). Pros: eliminates jitter; the wait is exactly the Stay operand value (in prescale ticks) plus a fixed startup latency, independent of background-program length. Cons: more complex Stay Set semantics; the "Stay window" concept becomes "Stay-Set arm → Prog End start → Stay timeup."
- **(C) Configurable per Stay Set:** a flag bit in Stay Set's encoding selects between immediate-start and arm-only modes. Pros: maximum flexibility. Cons: consumes an encoding bit; adds Stay Set variant complexity.

- **(A) 即時開始(v1.0 挙動):** Stay Set はステイカウンタをアサートし 0 から開始する；カウントは Stay Set の次のクロックで始まる。裏プログラムクロックは待機の一部である。利点: 単純；ステイカウンタは素直に「Stay Set 以来の時間」である。欠点: 可変の裏プログラム長は可変の有効待機を引き起こす——ジッタ。
- **(B) クリア／同期のみ:** Stay Set はステイカウンタを 0 にリセットしアームするが、カウンタはティックを*開始しない*。実際のカウントは **Prog End** が遭遇された時(または Prog End が存在しないなら Stay 命令に到達した時)に始まる。利点: ジッタを排除；待機はちょうど Stay オペランド値(プリスケールティックで)に固定起動レイテンシを加えたもので、裏プログラム長から独立する。欠点: より複雑な Stay Set 意味論；「Stay ウィンドウ」概念が「Stay Set アーム → Prog End 開始 → Stay timeup」になる。
- **(C) Stay Set 毎に設定可能:** Stay Set のエンコーディング内のフラグビットが即時開始とアームのみモードの間を選択する。利点: 最大の柔軟性。欠点: エンコーディングビットを消費；Stay Set 変種の複雑性を追加。

**Contributor's lean.** **(B) clear/sync only.** The jitter elimination is architecturally important for any application where the Stay's actual duration matters (e.g., audio sample timing, communication-protocol timing). The added complexity is local to Stay Set and Prog End; the rest of the Core is unchanged. Recorded as **Tie** C4-T4 with (B) as the leading proposal.

**貢献者の傾向。** **(B) クリア／同期のみ。** ジッタ排除は、Stay の実際の持続時間が重要な任意の応用(例: 音声サンプルタイミング、通信プロトコルタイミング)にアーキテクチャ的に重要である。追加された複雑性は Stay Set と Prog End にローカルである；コアの残りは変わらない。(B) を先頭提案として **Tie** C4-T4 で記録。

**Note.** If (B) is adopted, the v1.1 Chapter 3 § 3.2 "Stay window" definition needs revision: the window opens when Stay Set is encountered, but the counter does not start until Prog End. The amanuensis flagged this for a future Chapter 3 revision.

**注。** (B) が採用された場合、v1.1 第3章 § 3.2 の「Stay ウィンドウ」定義は改訂を必要とする: ウィンドウは Stay Set が遭遇された時に開くが、カウンタは Prog End まで開始しない。祐筆は将来の第3章改訂のためにこれを印付けた。

---

## 4.10 What is NOT in this Chapter / 本章に含まれないもの

To make the boundary unambiguous:

境界を曖昧でなくするために:

- **Pin-level signaling for the indirect-read bus.** Wire widths, edge vs level conventions, exact timing diagrams — Chapter 5. / **間接読みバスのピンレベル信号化。** 配線幅、エッジ対レベル慣習、正確なタイミング図——第5章。
- **The prescaler's pin-level interface.** Whether the prescaler value is a wire input (compile-time fixed) or a register-write address (runtime-configurable) — Chapter 5. / **プリスケーラのピンレベルインターフェース。** プリスケーラ値が配線入力(合成時固定)かレジスタ書き込みアドレス(実行時設定可能)か——第5章。
- **Specific Formation indirect-target register addresses.** Each Formation defines which external register supplies the indirect target for Jump and which supplies it for Loop. Cross-Formation legibility convention C2-V4 may be extended, but the specifics are per-Formation. / **特定の Formation 間接ターゲットレジスタアドレス。** 各 Formation は Jump への間接ターゲットを供給する外部レジスタと Loop へのそれを定義する。クロス Formation 可読性慣習 C2-V4 は拡張され得るが、特定は Formation 毎である。
- **Verilog/VHDL realizations.** The indirect-read state machine, the prescaler counter, and the prescaler-Stay-counter integration are Layer 3 (`03_Sample_Implementations/`) material. / **Verilog/VHDL 実現。** 間接読みステートマシン、プリスケーラカウンタ、プリスケーラ-ステイカウンタ統合は第3層(`03_Sample_Implementations/`)の素材である。
- **Multi-PTSG prescaler coordination.** Multiple PTSG cores sharing or independently configuring prescalers — Chapter 6 future material. / **複数 PTSG プリスケーラ協調。** 複数の PTSG コアがプリスケーラを共有するか独立に設定する——第6章の将来素材。

---

## 4.11 Open Questions Carried Forward / 後続章へ持ち越される未解決問題

| Question | Deferred to |
|---|---|
| Indirect-read bus pin-level signaling (edge/level, exact widths, timing diagrams) / 間接読みバスのピンレベル信号化(エッジ／レベル、正確な幅、タイミング図) | Chapter 5 / 第5章 |
| Prescaler pin-level interface (compile-time-fixed: wire input; runtime: register-write protocol) / プリスケーラピンレベルインターフェース(合成時固定: 配線入力；実行時: レジスタ書き込みプロトコル) | Chapter 5 / 第5章 |
| Whether C3-T10's hybrid (leading-edge flag, trailing-edge action) creates timing-closure issues at high clock rates / C3-T10 のハイブリッド(前縁フラグ、後縁アクション)が高クロックレートでタイミングクロージャ問題を作るかどうか | Chapter 5 + Layer 3 implementation |
| Whether (B) clear/sync-only Stay Set (C3-T11/C4-T4) requires modifications to the holding-register save protocol / (B) クリア／同期のみ Stay Set(C3-T11/C4-T4)が保持レジスタ退避プロトコルへの修正を必要とするかどうか | Community input + Chapter 3 revision |
| Whether indirect-mode could be extended to Sub-sequence Call offset (i.e., D16-D31 = 0 → indirect Call offset) / 間接モードが Sub-sequence Call オフセットに拡張できるかどうか(つまり D16-D31 = 0 → 間接 Call オフセット) | Future Layer 2 trace |
| Whether a Formation needing both indirect Jump and indirect Loop in the same Stay window has bus contention issues / 同じ Stay ウィンドウで間接 Jump と間接 Loop の両方を必要とする Formation がバス競合問題を持つかどうか | Community input |

---

## 4.12 Summary of Chapter 4 Decisions / 第4章決定事項のまとめ

Following the established classification: **Fixed (F)** = architectural commitments; **Convention (V)** = current conventions that could in principle be reconsidered; **Tie (T)** = genuinely open for community input.

確立された分類に従う: **Fixed (F)** = アーキテクチャ的コミットメント；**Convention (V)** = 原則として再考可能な現在の慣習；**Tie (T)** = 真にコミュニティ入力に開かれている。

| ID | Decision | Status |
|---|---|---|
| **C4-F1** | Prescaler is architectural necessity, not convenience, for applications requiring waits beyond ~80 µs (at 50 MHz); 4096-clock bare-Stay limit confirms this (Gemini-derived) / プリスケーラは便利さではなくアーキテクチャ的必然である、~80 µs(50 MHz で)を超える待機を要求する応用に対して；4096 クロックの裸 Stay 限界がこれを確認する(Gemini 由来) | **F** |
| **C4-F2** | Prescaler scope: Stay counter and prescaler counter are prescaled; Loop counter is NOT prescaled (Loop is space-axis, prescaler is time-axis; mixing conflates axes) / プリスケーラ範囲: ステイカウンタとプリスケーラカウンタはプリスケールされる；Loop カウンタはプリスケールされない(Loop は空間軸、プリスケーラは時間軸；混合は軸を混同する) | **F** |
| **C4-F3** | Immediate-band background program runs at full system clock rate (not prescaled), enabling complex background subroutines within a single prescaled stay tick / 即時帯域裏プログラムはフルシステムクロックレートで走る(プリスケールされない)、単一のプリスケールされたステイティック内で複雑な裏サブルーチンを可能にする | **F** |
| **C4-F4** | Literal-zero-as-escape unified pattern: operand 0 has special meaning across multiple Core instructions; classified as arithmetic-shortcut (Stay, Branch) or indirect-data-source (Jump, Loop) / 直値ゼロエスケープ統一パターン: オペランド 0 は複数のコア命令にわたって特別な意味を持つ；算術的近道(Stay、Branch)または間接データソース(Jump、Loop)に分類される | **F** |
| **C4-F5** | Indirect Jump (Jump operand 0): Core asserts indirect-read request with purpose code, captures 12-bit target from external, jumps to absolute target / 間接 Jump(Jump オペランド 0): コアは目的コード付きの間接読み要求をアサートし、外部から 12 ビットターゲットを捕捉し、絶対ターゲットにジャンプする | **F** |
| **C4-F6** | Indirect Loop target (Loop with D16-D31 = 0): Core asserts indirect-read request with purpose code, captures 12-bit target count from external, uses as up-count comparison target / 間接 Loop 目標(D16-D31 = 0 の Loop): コアは目的コード付きの間接読み要求をアサートし、外部から 12 ビットターゲットカウントを捕捉し、アップカウント比較目標として使う | **F** |
| **C4-F7** | Indirect-read bus protocol signals: indirect_req (Core→External, 1-bit), indirect_purpose (Core→External, 2-bit), indirect_data (External→Core, 12-bit), indirect_ready (External→Core, 1-bit) / 間接読みバスプロトコル信号: indirect_req、indirect_purpose、indirect_data、indirect_ready | **F** |
| **C4-V1** | Indirect Loop target of 0 means "loop body executes 0 times" (counter=target on first iteration under up-count), matching for(i=0;i<0;i++) semantic / 間接 Loop 目標 0 は「ループ本体は 0 回実行される」を意味する(アップカウントの下で最初の反復でカウンタ=目標)、for(i=0;i<0;i++) 意味論と一致 | **V** |
| **C4-V2** | Indirect-read uses a shared bus distinguished by indirect_purpose code; per-purpose buses are an alternative Formation may choose / 間接読みは indirect_purpose コードで区別される共有バスを使う；用途別バスは Formation が選択し得る代替案 | **V** |
| **C4-T1** | Indirect-read handshake timing Tie: (A) combinational/zero-clock; (B) registered/one-clock; (C) variable/multi-clock. Contributor leans toward (B) / 間接読みハンドシェイクタイミング Tie: (A) 組み合わせ／ゼロクロック；(B) レジスタ付き／1クロック；(C) 可変／複数クロック。貢献者は (B) に傾く | **T** |
| **C4-T2** | Prescaler configuration Tie (Chapter 1 § 1.12, systematized here): (A) compile-time fixed; (B) runtime-configurable; (C) per-stay-selectable; (D) multiple-parallel. Contributor leans toward (A) for Core with (B) as Formation-level extension / プリスケーラ構成 Tie(第1章 § 1.12、ここで体系化): (A) 合成時固定；(B) 実行時設定可能；(C) ステイ毎選択可能；(D) 複数並列。貢献者はコアには (A)、Formation レベル拡張として (B) に傾く | **T** |
| **C4-T3** | Prescale edge for queued execution Tie (was C3-T10): (A) leading edge throughout; (B) trailing edge throughout; (HYBRID) leading-edge match flag, trailing-edge action. Contributor leans toward HYBRID / キュー実行のプリスケール縁 Tie(旧 C3-T10): (A) 前縁全般；(B) 後縁全般；(ハイブリッド) 前縁一致フラグ、後縁アクション。貢献者はハイブリッドに傾く | **T** |
| **C4-T4** | Stay Set role Tie (was C3-T11): (A) immediate start (v1.0 behavior, jitter-prone); (B) clear/sync-only (count starts at Prog End/Stay, jitter-free); (C) per-Stay-Set configurable. Contributor leans toward (B) / Stay Set 役割 Tie(旧 C3-T11): (A) 即時開始(v1.0 挙動、ジッタ起こりやすい)；(B) クリア／同期のみ(カウントは Prog End/Stay で開始、ジッタなし)；(C) Stay Set 毎に設定可能。貢献者は (B) に傾く | **T** |

**Decision count by status:** Fixed (F): 7; Convention (V): 2; Tie (T): 4.

**地位別決定数:** Fixed (F): 7；Convention (V): 2；Tie (T): 4.

Notable: two Ties (C4-T3, C4-T4) were inherited from Chapter 3 v1.1 (formerly C3-T10, C3-T11) and are now situated in their prescaler-coupled context. They remain Ties pending community input but with the contributor's analysis now articulated.

注目すべき: 二つの Tie(C4-T3、C4-T4)は第3章 v1.1 から継承され(旧 C3-T10、C3-T11)、プリスケーラ結合の文脈に置かれた。コミュニティ入力を待つ Tie のままだが、貢献者の分析は今や明確化された。

---

## End of Chapter 4 / 第4章の末尾

> *Operand zero, in the Core's two literal arithmetics, means the count's full extent or the protocol's patient wait. In the Core's two indirect modes, it means: ask the world.*
> *コアの二つの字義的算術における オペランド ゼロは、カウントの全範囲またはプロトコルの忍耐強い待機を意味する。コアの二つの間接モードにおいては、それは意味する: 世界に尋ねよ。*

> *The prescaler is not a luxury. Without it, half a second cannot fit inside the Core. Necessity, not convenience.*
> *プリスケーラは贅沢ではない。それなしには、半秒はコア内に収まらない。便利さではなく、必然。*

> *Where the Core extends, the Formation pays. This is the rule that keeps the Core small.*
> *コアが拡張する場所で、Formation が支払う。これがコアを小さく保つ規則である。*

This chapter is released into the public domain under CC0 1.0 Universal. **This is the v1.0 deliberation-stage release.** Chapter 5 (External Logic Interface) will specify the pin-level signaling for all buses introduced here (indirect-read bus, prescaler interface) alongside the bus protocols from Chapters 3. The Ties recorded above (C4-T1 through C4-T4) await community discussion alongside the still-open Ties from Chapters 2 and 3.

本章は CC0 1.0 Universal のもとパブリックドメインに公開される。**これは v1.0 協議段階リリースである。** 第5章(外部ロジックインターフェース)は、第3章のバスプロトコルと共に、ここで導入されたすべてのバス(間接読みバス、プリスケーラインターフェース)のピンレベル信号を指定する。上に記録された Tie(C4-T1 から C4-T4 まで)は、第2章と第3章からのまだ開かれた Tie と共にコミュニティ議論を待つ。

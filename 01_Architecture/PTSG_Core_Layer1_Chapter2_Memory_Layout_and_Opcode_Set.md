# PTSG-Core — Layer 1 Specification
# Chapter 2: Memory Layout and Opcode Set
# PTSGコア — 第1層仕様書
# 第2章：メモリレイアウトとオペコードセット

> **License: CC0 1.0 Universal (Public Domain)**
> This chapter specifies the 32-bit instruction word layout, the encoding of the 4-bit opcode field, the semantics of the four currently-defined opcodes (Global, Stay, Branch, Jump), the internal-control sub-opcodes of Global (operands 000–007), the 16-bit timing-signal field, the 12 reserved top-level opcode slots, and the externally-observable memory and state-number organization.
>
> **ライセンス：CC0 1.0 Universal（パブリックドメイン）**
> 本章は32ビット命令語レイアウト、4ビットオペコードフィールドのエンコーディング、現在定義されている4オペコード(Global、Stay、Branch、Jump)の意味論、Globalの内部制御サブオペコード(operand 000–007)、16ビットタイミング信号フィールド、12個の予約トップレベルオペコードスロット、そして外部から観察可能なメモリとステートナンバー構成を指定する。

---

## 2.1 Purpose of this Chapter / 本章の目的

This chapter establishes the **static instruction-set surface** of PTSG-Core: the 32-bit instruction word's field layout, the values that the opcode field can take, and the semantics each value commits the Core to execute. Chapter 1 established *why* PTSG is shaped the way it is; Chapter 2 establishes *what* each instruction does.

本章はPTSGコアの**静的命令セット表面**を確立する: 32ビット命令語のフィールドレイアウト、オペコードフィールドが取り得る値、そして各値がコアに実行することをコミットさせる意味論。第1章は*なぜ*PTSGがそのような形をしているかを確立した；第2章は各命令が*何をするか*を確立する。

The word "static" deserves emphasis. Some PTSG behaviors — most notably background execution during Stay, the multi-clock sub-opcode mechanics, and the internal-info-holding-register protocols that support sub-sequence call/return and external-interrupt insertion — are *dynamic* in the sense that they involve interaction between adjacent instructions and the Stay-counter state. Those dynamic behaviors are deferred to **Chapter 3** (Sub-Opcode Architecture and Background Execution). This chapter specifies what each opcode means *in isolation*, which is sufficient for understanding instruction lists that do not exploit background execution and is necessary as a foundation for Chapter 3.

「静的」という語は強調に値する。PTSGの一部の挙動——特にステイ中の裏実行、複数クロックサブオペコード機構、そしてサブシーケンスコール／リターンと外部割り込み挿入を支持する内部情報保持レジスタプロトコル——は、隣接する命令とステイカウンタ状態の間の相互作用を伴うという意味で*動的*である。これらの動的挙動は**第3章**(サブオペコードアーキテクチャと裏実行)に繰り延べられる。本章は各オペコードが*孤立して*何を意味するかを指定する、それは裏実行を行使しない命令リストを理解するのに十分であり、第3章のための基盤として必要である。

**Implementation neutrality is maintained throughout.** The semantics specified here constrain *what an implementation must produce*, not *how it must produce it*. Specific clock latencies of opcodes, internal pipeline stages, and synthesis choices are Implementation Arena matters (Layer 3); Chapter 2 specifies only the observable input/output relationships.

**実装中立性は本章を通じて維持される。** ここで指定される意味論は実装が*何を生み出さなければならないか*を制約し、*どのようにそれを生み出さなければならないか*を制約しない。オペコードの具体的なクロックレイテンシ、内部パイプライン段、合成選択はImplementation Arena事項(Layer 3)である；第2章は観察可能な入出力関係のみを指定する。

A note on community input: Chapter 2 marks the project's first descent into bit-level commitment. Some decisions in this chapter are *firmly settled by the original specification* and are recorded as Fixed in § 2.13. Other decisions are *conventions that could in principle be reconsidered* — particularly the specific numbering of internal-control sub-opcodes (§ 2.8) and the interpretation of certain operand values; these are recorded as Convention. A few questions remain *genuinely open* and are flagged as Ties in § 2.13 with the alternatives recorded for community input. The contributor invites discussion on any of these matters via the standard issue process described in `CONTRIBUTING.md`.

コミュニティ入力についての注: 第2章はプロジェクトのビットレベルコミットメントへの最初の下降を示す。本章の一部の決定は*オリジナル仕様によって確固として確定済み*であり、§ 2.13 で Fixed として記録される。他の決定は*原則として再考可能な慣習*である——特に内部制御サブオペコードの具体的な番号付け(§ 2.8)と特定のオペランド値の解釈；これらは Convention として記録される。いくつかの問いは*真に未解決*のままであり、§ 2.13 で代替案がコミュニティ入力のために記録された Tie として印付けられている。貢献者は `CONTRIBUTING.md` で説明される標準 issue プロセス経由でこれらの事項のいずれかについての議論を招く。

---

## 2.2 The 32-Bit Instruction Word — Field Layout / 32ビット命令語 — フィールドレイアウト

Every PTSG instruction is a 32-bit word, stored in the instruction memory at one state address. The word is partitioned into three fields:

すべてのPTSG命令は32ビット語であり、命令メモリの一つのステートアドレスに格納される。語は三つのフィールドに分割される:

| Bit range / ビット範囲 | Field name / フィールド名 | Width | Purpose |
|---|---|---|---|
| **D0–D3** | **Opcode** | 4 bits | Selects which of the 4 currently-defined opcodes (or 12 reserved slots) this instruction is / 本命令が現在定義されている4オペコード(または12個の予約スロット)のいずれであるかを選択する |
| **D4–D15** | **Operand** | 12 bits | Carries opcode-specific parameter data (wait clock count, branch offset, jump target, sub-opcode selector, etc.) / オペコード固有のパラメータデータ(待機クロック数、分岐オフセット、ジャンプ先、サブオペコード選択子等)を運ぶ |
| **D16–D31** | **Timing Signals** | 16 bits | Drives 16 parallel output signals to external logic; semantics specified in § 2.9 / 16本の並列出力信号を外部ロジックへ駆動する；意味論は § 2.9 で指定される |

```
  31                              16 15                  4  3      0
 ┌────────────────────────────────────┬────────────────────┬─────────┐
 │       Timing Signals (D16–D31)     │   Operand (D4–D15) │ Opcode  │
 │              16 bits                │      12 bits       │ 4 bits  │
 └────────────────────────────────────┴────────────────────┴─────────┘
                                       ▲                    ▲
                                       │                    │
                                       │                    └─ Selects opcode (§ 2.3)
                                       └─ Opcode-specific parameter
                                          • Stay: wait clock count (§ 2.4)
                                          • Branch: relative offset (§ 2.5)
                                          • Jump: absolute address (§ 2.6)
                                          • Global: sub-opcode + sub-operand (§§ 2.7–2.8)
```

**Field independence.** The three fields are read independently by the Core's decoder; no opcode causes the operand or timing-signal fields to be reinterpreted as part of the opcode, nor does any operand value cause the timing-signal field to be reinterpreted as part of the operand. **The boundaries between D0–D3, D4–D15, and D16–D31 are invariant across all instructions.** (The single nuance is that during Stay-window background execution, the timing-signal field of *the Global instruction being background-executed* can be repurposed as a "second operand"; this is detailed in Chapter 3. It does not affect static decoding.)

**フィールドの独立性。** 三つのフィールドはコアのデコーダーによって独立に読まれる；どのオペコードもオペランドまたはタイミング信号フィールドをオペコードの一部として再解釈させず、どのオペランド値もタイミング信号フィールドをオペランドの一部として再解釈させない。**D0-D3、D4-D15、D16-D31 の境界はすべての命令にわたって不変である。** (唯一の機微は、ステイウィンドウ裏実行中に、*裏実行されている Global 命令の*タイミング信号フィールドが「第二オペランド」として再目的化され得ること；これは第3章で詳述される。これは静的デコーディングに影響しない。)

**Byte/word endianness is not a Core concern.** The instruction word is stored as a 32-bit unit in BRAM; how that unit is laid out in any external storage format (.mif file, .hex file, etc.) is an implementation-environment matter (Layer 3 and tool-chain documentation), not a Core specification matter.

**バイト／ワードエンディアンはコアの懸念ではない。** 命令語は32ビット単位としてBRAMに格納される；その単位が任意の外部格納形式(.mifファイル、.hexファイル等)においてどのように配置されるかは実装環境事項(第3層およびツールチェーン文書)であり、コア仕様事項ではない。

---

## 2.3 Opcode Encoding — Four Used, Twelve Reserved / オペコードエンコーディング — 4使用、12予約

The 4-bit opcode field (D0–D3) accommodates 16 distinct opcode values. The current specification defines four; the remaining twelve are **reserved** under the AI-affinity-driven non-promotion discipline described in Chapter 1 § 1.7.

4ビットオペコードフィールド(D0-D3)は16個の異なるオペコード値を収容する。現在の仕様は四つを定義する；残りの12個はChapter 1 § 1.7 で説明されるAI親和性駆動の非昇格規律のもと**予約されている**。

| Opcode value (hex) | Opcode name | Status | Detailed in § |
|---|---|---|---|
| **0** | **Global** | Defined / 定義済み | § 2.7, § 2.8 |
| **1** | **Stay** | Defined / 定義済み | § 2.4 |
| **2** | **Branch** | Defined / 定義済み | § 2.5 |
| **3** | **Jump** | Defined / 定義済み | § 2.6 |
| **4–F** | (twelve slots) | **Reserved** / 予約 | — |

**The twelve reserved slots are not "available capacity."** As Chapter 1 § 1.7 articulates: any proposal to assign one of these slots to a new top-level opcode must justify the addition against the AI-affinity criterion (does the new semantics demand complex LLM disambiguation? does it overlap with existing capabilities in a way that increases hallucination risk?), not merely against technical desirability. Most candidate operations that *could* become new opcodes belong inside Global's sub-opcode space first, and are eligible for promotion to a top-level opcode only when their usage frequency, semantic distinctness, and AI legibility all clear high thresholds. The promotion-criteria methodology will be developed in future Layer 2 traces.

**12個の予約スロットは「利用可能容量」ではない。** 第1章 § 1.7 が明確化するように: これらのスロットの一つを新しいトップレベルオペコードに割り当てる任意の提案は、追加をAI親和性基準に対して(新しい意味論はLLMの複雑な曖昧性除去を要求するか? 既存能力と幻覚リスクを増す仕方で重なるか?)正当化しなければならず、単に技術的望ましさに対してではない。新しいオペコードに*なり得る*ほとんどの候補演算は、まずGlobalのサブオペコード空間内に属し、その使用頻度、意味論的独自性、AI判読可能性のすべてが高い閾値を超えた時にのみトップレベルオペコードへの昇格に適格である。昇格基準方法論は将来のLayer 2軌跡で発展する。

**The opcode values 0–3 are conventional but not arbitrary.** Opcode 0 is Global (the "everything-else" opcode containing the internal-control sub-opcodes and the external-sub-opcode mechanism); 1, 2, 3 are the three structural opcodes (time, conditional-space, unconditional-space) in approximate order of frequency of use in typical programs. This numbering predates the Open Prompt formalization of PTSG and is recorded as a Convention rather than a Fix in § 2.13 — but in practice it is unlikely to change, since any renumbering would invalidate every existing instruction list.

**オペコード値 0-3 は慣習的だが任意ではない。** オペコード 0 は Global(内部制御サブオペコードと外部サブオペコード機構を含む「他のすべて」オペコード)；1, 2, 3 は三つの構造的オペコード(時間、条件付き空間、無条件空間)であり、典型的なプログラムにおける使用頻度のおおよその順である。この番号付けはOpen PromptによるPTSGの形式化に先行しており、§ 2.13 では Fix ではなく Convention として記録される——しかし実際には変わる可能性は低い、なぜなら任意の再番号付けはすべての既存命令リストを無効にするからである。

---

## 2.4 Stay (Opcode 1) — Time Management / Stay(オペコード1) — 時間管理

**Semantics.** When the Core reaches a state whose opcode field is 1 (Stay), it remains at that state address until the stay counter reaches the value specified by the operand field. During the wait, the instruction word's timing-signal field (D16–D31) is held at its written value. When the stay counter matches the operand, the Core advances to the next state (current address + 1).

**意味論。** コアがオペコードフィールド1(Stay)のステートに到達すると、ステイカウンタがオペランドフィールドで指定された値に達するまでそのステートアドレスに留まる。待機中、命令語のタイミング信号フィールド(D16-D31)は書き込まれた値で保持される。ステイカウンタがオペランドと一致すると、コアは次のステート(現在アドレス + 1)に進む。

**Operand semantics.** The 12-bit operand is interpreted as an unsigned wait count, with one special case:

**オペランド意味論。** 12ビットオペランドは符号なし待機カウントとして解釈される、一つの特殊ケースを伴って:

| Operand value | Wait duration |
|---|---|
| 1 to 4095 | Wait for the specified number of clocks (1 to 4095 clocks) / 指定されたクロック数(1から4095クロック)待機 |
| **0** | **Wait for 4096 clocks (the "literal-zero-as-escape" convention)** / **4096クロック待機(「直値ゼロをエスケープとする」慣習)** |

The literal-zero-as-escape convention is the first-encountered instance of a general pattern that recurs in PTSG: an operand value of zero, which would otherwise represent a degenerate "wait zero clocks" case, is repurposed to mean "the maximum value the field can represent" or "use an alternative addressing mode." For Stay's operand, the convention yields the natural full-range upper bound (4096 = 2^12). The general treatment of the literal-zero-as-escape convention, including its application to indirect addressing via external registers, is detailed in **Chapter 4** (Indirect Addressing and Prescaler).

直値ゼロエスケープ慣習は、PTSGにおいて繰り返される一般パターンの最初に遭遇する事例である: オペランド値ゼロは、そうでなければ退化した「ゼロクロック待機」事例を表現するであろうが、「フィールドが表現できる最大値」または「代替アドレッシングモードを使用」を意味するように再目的化される。Stayのオペランドに対して、慣習は自然な完全範囲上限(4096 = 2^12)を生む。直値ゼロエスケープ慣習の一般的扱い、その外部レジスタ経由の間接アドレッシングへの適用を含めて、は**第4章**(間接アドレッシングとプリスケーラ)で詳述される。

**Stay-counter range and prescaler.** The bare Stay opcode provides waits of 1 to 4096 clocks. At typical FPGA clock rates (50–200 MHz), this corresponds to wait durations from approximately 5 nanoseconds to approximately 80 microseconds — sufficient for many bus-protocol timing requirements but far short of human-perceivable time scales. Extending the Stay's effective range is the role of the **prescaler** mechanism specified in Chapter 4. (As shown in the Gemini comprehension trace at `02_Reasoning_Traces/contributed/dsohnaka/2026-05-20_ptsg-comprehension-by-gemini.md`, the prescaler's role is not convenience but mathematical/physical necessity: at 50 MHz, half a second of LED on/off cannot otherwise fit within the Core's 12-bit operand × 12-bit address space.)

**ステイカウンタ範囲とプリスケーラ。** 裸のStayオペコードは1から4096クロックの待機を提供する。典型的なFPGAクロックレート(50-200 MHz)では、これは約5ナノ秒から約80マイクロ秒の待機持続時間に対応する——多くのバスプロトコルタイミング要件に十分だが、人間が感知可能な時間スケールには遠く及ばない。Stayの有効範囲を拡張することは、第4章で指定される**プリスケーラ**機構の役割である。(`02_Reasoning_Traces/contributed/dsohnaka/2026-05-20_ptsg-comprehension-by-gemini.md` のGemini読解軌跡で示されるように、プリスケーラの役割は便利さではなく数学的・物理的必然性である: 50 MHzにおいて、LEDのオン／オフの0.5秒は、それ以外の方法ではコアの12ビットオペランド × 12ビットアドレス空間内に収まらない。)

**Stay-during-execution external observability.** The current State Number is output externally throughout the Stay (see § 2.10), which means external logic can observe the entire duration of any Stay by sampling the State Number and the Stay counter. This supports SignalTap and similar in-system debugging without specialized PTSG-aware test infrastructure.

**Stay実行中の外部観察可能性。** 現在のステートナンバーはStayを通じて外部に出力される(§ 2.10参照)、これは外部ロジックがステートナンバーとステイカウンタをサンプリングすることで、任意のStayの全持続時間を観察できることを意味する。これは特殊なPTSG対応テストインフラなしにSignalTapと類似のシステム内デバッグをサポートする。

**Relation to background execution.** The Stay window — the clock interval during which the Core is at a Stay state — is also the window during which Global commands placed at *adjacent* states can execute "in the background" with their results applied at Stay-timeup. This background-execution mechanism is the most consequential dynamic behavior in PTSG-Core and is specified in **Chapter 3**. Chapter 2's specification of Stay is complete *as a static behavior*: it says nothing about background execution and is correct regardless of whether background execution is in use.

**裏実行との関係。** Stayウィンドウ——コアがStayステートにいるクロック間隔——は、*隣接する*ステートに置かれたGlobalコマンドが「裏側で」実行され得るウィンドウでもあり、その結果はStayタイムアップ時に適用される。この裏実行機構はPTSGコアにおける最も帰結的な動的挙動であり、**第3章**で指定される。第2章のStayの仕様は*静的挙動として*完全である: それは裏実行について何も言わず、裏実行が使われているかどうかに関わらず正しい。

---

## 2.5 Branch (Opcode 2) — Conditional State Transition / Branch(オペコード2) — 条件付きステート遷移

**Semantics.** When the Core reaches a state whose opcode field is 2 (Branch), it samples the 1-bit external Condition input and selects the next state based on the result:

**意味論。** コアがオペコードフィールド2(Branch)のステートに到達すると、1ビット外部Condition入力をサンプリングし、結果に基づき次のステートを選択する:

- **Condition is true (1):** advance to next state (current address + 1). The branch is *not* taken. / **Conditionが true (1):** 次のステート(現在アドレス + 1)に進む。分岐は*取られない*。
- **Condition is false (0):** branch to the relative target address (current + operand). The branch *is* taken. / **Conditionが false (0):** 相対先アドレス(現在 + オペランド)に分岐する。分岐は*取られる*。

This is the **"true means no-branch" convention** introduced in Chapter 1 § 1.5 (decision C1-D5). In conventional CPU branch instructions, the convention is typically inverted (condition true → take the branch); PTSG's inversion is a deliberate ergonomic choice rooted in the most common PTSG idiom: *"loop here until ready, then proceed."* The natural reading "while NOT ready, hold position" maps directly to Branch's behavior when Condition is the "ready" signal. No mental negation is required.

これは第1章 § 1.5 (決定 C1-D5)で導入された**「成立で不分岐」慣習**である。従来のCPU分岐命令では、慣習は典型的に反転している(条件成立 → 分岐を取る)；PTSGの反転は、最も一般的なPTSGイディオム——*「準備が整うまでここでループし、それから進む」*——に根ざした意図的な人間工学的選択である。Conditionが「準備完了」信号である時、自然な読み「準備が*できていない*間、位置を保持」は Branch の挙動に直接マップする。心的否定は要求されない。

**Operand semantics.** The 12-bit operand is interpreted as an unsigned relative forward offset, with one special case:

**オペランド意味論。** 12ビットオペランドは符号なしの相対前方オフセットとして解釈される、一つの特殊ケースを伴って:

| Operand value | When Condition is false (branch taken) | When Condition is true (branch not taken) |
|---|---|---|
| 1 to 4095 | Branch target = current address + operand (forward only) / 分岐先 = 現在アドレス + オペランド(前方のみ) | Advance to current address + 1 / 現在アドレス + 1 に進む |
| **0** | **Branch target = current address ("self-loop" / "wait for Condition" idiom)** / **分岐先 = 現在アドレス(「自己ループ」／「Conditionを待つ」イディオム)** | Advance to current address + 1 / 現在アドレス + 1 に進む |

The Branch (operand 0) instruction is the **canonical "wait for Condition" idiom in PTSG**. The state self-loops on every clock until Condition becomes true, then advances. The behavior is observable: external logic can see the State Number remain unchanged at this address during the wait, and the timing-signal field's value (D16–D31) is presented continuously throughout. When an "insertion" (external interrupt) overwrites the State Number register, the self-loop also terminates and execution resumes at the inserted address; this is detailed in **Chapter 3**.

Branch (operand 0) 命令はPTSGにおける**正典的な「Conditionを待つ」イディオム**である。ステートはConditionが成立になるまで毎クロック自己ループし、その後進む。挙動は観察可能である: 外部ロジックは待機中このアドレスでステートナンバーが変更されないままであることを見ることができ、タイミング信号フィールドの値(D16-D31)は通じて連続的に提示される。「挿入」(外部割り込み)がステートナンバーレジスタを上書きする時、自己ループも終了し、実行は挿入されたアドレスから再開する；これは**第3章**で詳述される。

**Forward-only relative addressing — a noted Convention.** The operand is unsigned, meaning Branch can only reach forward targets (current+1 through current+4095) or self (operand 0). Backward addressing is the role of **Jump (opcode 3)**, which carries an absolute address. The choice to make Branch forward-only rather than signed (which would yield a range of approximately current−2047 to current+2047) is recorded in § 2.13 as Convention C2-V1; the alternative (signed Branch offset) is recorded as a Tie alternative, and the discussion of which alternative serves the ecosystem better is invited from the community.

**前方のみの相対アドレッシング——注記された慣習。** オペランドは符号なし、つまりBranchは前方の目標(current+1 から current+4095)または自己(オペランド 0)のみに到達できる。後方アドレッシングは**Jump(オペコード 3)**の役割であり、それは絶対アドレスを運ぶ。Branchを符号付き(これはおよそ current-2047 から current+2047 の範囲を生む)ではなく前方のみとする選択は、§ 2.13 に Convention C2-V1 として記録されている；代替案(符号付きBranchオフセット)はTie代替として記録されており、どちらの代替案がエコシステムにより良く奉仕するかについての議論はコミュニティから招かれる。

**Auto-save on branch taken.** When a Branch is taken (Condition was false), several internal control registers — including the State Number register and any in-use loop counters — are automatically pushed to the internal information-holding register. This auto-save mechanism is what enables Branch to be used as the *forward-half* of a sub-sequence call (with the Return sub-opcode of Global, see § 2.8, providing the return). The detailed semantics of the internal info-holding register, the auto-save protocol, and the external stack memory connection for deeper nesting are specified in **Chapter 3**. Chapter 2 records only the existence of the auto-save behavior so that the static specification of Branch is complete.

**取られた分岐での自動退避。** Branchが取られる時(Conditionが不成立であった)、いくつかの内部制御レジスタ——ステートナンバーレジスタと使用中の任意のループカウンタを含む——が自動的に内部情報保持レジスタにプッシュされる。この自動退避機構は、Branchがサブシーケンスコールの*前方半分*として(GlobalのReturnサブオペコード — § 2.8 参照 — がリターンを提供する)使用されることを可能にするものである。内部情報保持レジスタの詳細意味論、自動退避プロトコル、より深いネスティングのための外部スタックメモリ接続は**第3章**で指定される。第2章はBranchの静的仕様が完全であるよう、自動退避挙動の存在のみを記録する。

---

## 2.6 Jump (Opcode 3) — Unconditional State Transition / Jump(オペコード3) — 無条件ステート遷移

**Semantics.** When the Core reaches a state whose opcode field is 3 (Jump), it unconditionally sets the State Number to the operand value, then begins execution at the new state on the next clock.

**意味論。** コアがオペコードフィールド3(Jump)のステートに到達すると、無条件にステートナンバーをオペランド値に設定し、次クロックで新しいステートでの実行を開始する。

**Operand semantics.** The 12-bit operand is interpreted as an unsigned absolute target address (the address itself, not an offset), with one special case:

**オペランド意味論。** 12ビットオペランドは符号なしの絶対先アドレス(オフセットではなくアドレスそのもの)として解釈される、一つの特殊ケースを伴って:

| Operand value | Jump target |
|---|---|
| 1 to 4095 | Jump to absolute address = operand value / 絶対アドレス = オペランド値 にジャンプする |
| **0** | **Jump to indirect-mode target (deferred to Chapter 4 — see Open Question in § 2.12)** / **間接モード先にジャンプ(第4章へ繰り延べ — § 2.12 のOpen Question参照)** |

The literal-zero-as-escape convention again repurposes operand 0. Rather than meaning "jump to address 0" (which would be redundant with Reset, see § 2.8) or being a degenerate "no jump" case (which would have no semantic content), operand 0 in Jump indicates **indirect-mode jump**: the target address is read from an external register identified by an implementation-defined mechanism. The full specification of this mechanism — which external register, what bus protocol, when the read occurs — is the subject of **Chapter 4** (Indirect Addressing and Prescaler). Chapter 2 only records that operand 0 has this special interpretation, so that no implementation will repurpose Jump (operand 0) for a different semantic.

直値ゼロエスケープ慣習は再びオペランド 0 を再目的化する。「アドレス0にジャンプする」(これはResetと冗長である、§ 2.8 参照)または退化した「ジャンプなし」事例(意味論的内容がない)を意味するのではなく、Jumpのオペランド 0 は**間接モードジャンプ**を示す: 先アドレスは実装定義の機構によって識別される外部レジスタから読まれる。この機構の完全な仕様——どの外部レジスタ、何のバスプロトコル、いつ読みが起きるか——は**第4章**(間接アドレッシングとプリスケーラ)の主題である。第2章はオペランド 0 がこの特殊解釈を持つことのみを記録し、いかなる実装もJump(オペランド 0)を異なる意味論に再目的化しないようにする。

**No auto-save on Jump.** Unlike Branch, Jump does not automatically push any internal registers to the holding register. The reason: Jump is unconditional and is typically used to express loop backs, structural transitions, and explicit goto-style control flow — none of which has the call-and-return structure that Branch's auto-save anticipates. If a sub-sequence-call-style transition is desired with unconditional invocation, the canonical idiom is to use Branch with a Condition that is always-false (which the Formation provides as a constant logic-0 Condition lane), thereby exploiting Branch's auto-save while behaving as an unconditional transition. Future Formations may wish to provide such an always-false Condition lane explicitly.

**Jumpでの自動退避なし。** Branchとは異なり、Jumpは内部レジスタを自動的に保持レジスタにプッシュしない。理由: Jumpは無条件であり、典型的にループバック、構造的遷移、明示的なgoto風制御フローを表現するために使われる——どれもBranchの自動退避が予想するコール-アンド-リターン構造を持たない。サブシーケンスコール風遷移が無条件呼び出しで望まれる場合、正典的なイディオムは常時偽のCondition(これはフォーメーションが定数 logic-0 Conditionレーンとして提供する)とともにBranchを使うことであり、それによりBranchの自動退避を行使しつつ無条件遷移として振る舞う。将来のフォーメーションはそのような常時偽のConditionレーンを明示的に提供したいと望むかもしれない。

---

## 2.7 Global (Opcode 0) — Overview and Dual Nature / Global(オペコード0) — 概要と二重性

**Semantics overview.** When the Core reaches a state whose opcode field is 0 (Global), the interpretation of the operand field depends on the value of D4–D7 (the *upper four bits* of the operand, in instruction-word terms — see Figure below):

**意味論概要。** コアがオペコードフィールド 0 (Global) のステートに到達すると、オペランドフィールドの解釈は D4-D7(命令語の用語では*オペランドの上位4ビット* — 以下の図参照)の値に依存する:

```
  D15  D14  D13  D12  D11  D10  D9  D8 | D7  D6  D5  D4 | D3  D2  D1  D0
 ┌────────────────────────────────────┬────────────────┬─────────────┐
 │   sub-operand (8 bits, D8–D15)      │  sub-opcode    │   Opcode    │
 │                                     │  selector      │             │
 │                                     │  (D4–D7, 4 bit)│   = 0       │
 └────────────────────────────────────┴────────────────┴─────────────┘
                                         │
                                         ├─ If D4–D7 = 0: "internal control mode"
                                         │    The 8 bits D8–D15 select an internal-control sub-opcode
                                         │    (Currently defined: 0–7; see § 2.8)
                                         │
                                         └─ If D4–D7 = 1–F: "external sub-opcode mode"
                                              D4–D7 is the external sub-opcode (15 slots)
                                              D8–D15 is the sub-operand passed to the external mechanism
                                              (Mechanism specified in Chapter 3; assignment is Formation-specific)
```

This dual-mode structure is the most distinctive feature of Global. It creates two coexisting sub-opcode spaces:

この二重モード構造はGlobalの最も特徴的な特徴である。これは二つの共存するサブオペコード空間を作る:

- **Internal-control mode (D4–D7 = 0):** the 8-bit field D8–D15 selects one of up to 256 internal-control sub-opcodes; the Core defines the meanings of values 0–7 (Reset, Base Set, Stay Set, Return, Sub-sequence Call, Loop, reserved, NOP) — see § 2.8. The remaining 248 values are reserved for future Core-level internal-control extensions, subject to the same AI-affinity discipline as top-level opcodes.
- **External sub-opcode mode (D4–D7 = 1–F):** the 4-bit field D4–D7 selects one of 15 external sub-opcodes; the 8-bit field D8–D15 is the sub-operand. The interpretation of each external sub-opcode is **Formation-specific**: a `PTSG_WPMS_Formation_OpenPrompt` will assign sub-opcode 1 to "write to WPMS external register," a `PTSG_I2C_Formation_OpenPrompt` will assign sub-opcode 1 to "issue I²C START condition" (or similar), and the assignments need not match across Formations. The Core specifies the mechanism (D4–D7 = which sub-opcode; D8–D15 = sub-operand; how this interfaces with background execution and the external bus) in **Chapter 3**; the assignments are in each Formation's Layer 1.

- **内部制御モード(D4-D7 = 0):** 8ビットフィールド D8-D15 は最大256個の内部制御サブオペコードの一つを選択する；コアは値 0-7 の意味を定義する(Reset、Base Set、Stay Set、Return、Sub-sequence Call、Loop、予約、NOP)— § 2.8 参照。残りの248値は将来のコアレベル内部制御拡張のために予約されており、トップレベルオペコードと同じAI親和性規律の対象である。
- **外部サブオペコードモード(D4-D7 = 1-F):** 4ビットフィールド D4-D7 は15個の外部サブオペコードの一つを選択する；8ビットフィールド D8-D15 はサブオペランドである。各外部サブオペコードの解釈は**フォーメーション固有**である: `PTSG_WPMS_Formation_OpenPrompt` はサブオペコード 1 を「WPMS外部レジスタへの書き込み」に割り当てるかもしれず、`PTSG_I2C_Formation_OpenPrompt` はサブオペコード 1 を「I²C STARTコンディション発行」(または類似)に割り当てるかもしれず、割り当てはフォーメーション間で一致する必要はない。コアは機構(D4-D7 = どのサブオペコード；D8-D15 = サブオペランド；これがどのように裏実行と外部バスとインターフェースするか)を**第3章**で指定する；割り当ては各フォーメーションのLayer 1にある。

**The canonical external sub-opcode 1 = "external register write."** Across Formations, sub-opcode 1 is conventionally reserved as the "external register write" operation (D8–D15 = destination register address, D16–D31 = data; when this Global is in a background-execution window, D16–D31 is reinterpreted as the data field). This convention is not enforced by the Core but is strongly recommended for cross-Formation legibility. Formations may justify deviation on a per-case basis, documented in their Layer 1.

**正典的な外部サブオペコード 1 = 「外部レジスタ書き込み」。** フォーメーションをまたいで、サブオペコード 1 は慣習的に「外部レジスタ書き込み」演算として予約される(D8-D15 = 宛先レジスタアドレス、D16-D31 = データ；このGlobalが裏実行ウィンドウ内にある時、D16-D31 はデータフィールドとして再解釈される)。本慣習はコアによって強制されないが、クロスフォーメーション可読性のため強く推奨される。フォーメーションは事例別の根拠で逸脱を正当化でき、それぞれのLayer 1で文書化される。

**Why this dual structure.** The dual-mode design serves a precise architectural purpose: it lets PTSG-Core specify *all* Core-level Global semantics (Reset, Base Set, etc.) without constraining Formation-level extension semantics. The Core "owns" the D4–D7 = 0 region; Formations "own" the D4–D7 = 1–F region. The boundary is bitwise, observable, and protected against accidental encroachment.

**なぜこの二重構造か。** 二重モード設計は正確なアーキテクチャ的目的に奉仕する: それはPTSGコアが*すべて*のコアレベルGlobal意味論(Reset、Base Set等)を、フォーメーションレベル拡張意味論を制約することなく指定することを可能にする。コアは D4-D7 = 0 領域を「所有」する；フォーメーションは D4-D7 = 1-F 領域を「所有」する。境界はビット単位で、観察可能であり、偶発的侵入から保護される。

---

## 2.8 Global Internal-Control Sub-opcodes / Globalの内部制御サブオペコード

When Global's D4–D7 = 0, the 8-bit field D8–D15 selects one of up to 256 internal-control sub-opcodes. The current specification defines values 0–7. The remaining 248 values are reserved.

GlobalのD4-D7 = 0の時、8ビットフィールドD8-D15は最大256個の内部制御サブオペコードの一つを選択する。現在の仕様は値0-7を定義する。残りの248値は予約されている。

| Sub-op value (decimal) | Name | Brief semantic |
|---|---|---|
| **0** | **Reset** | Force State Number to 0; reset stay counter and loop counters to initial values. (Detailed external visibility of reset behavior: § 2.10.) / ステートナンバーを強制的に 0 にする；ステイカウンタとループカウンタを初期値にリセットする。(リセット挙動の詳細な外部可視性: § 2.10。) |
| **1** | **Base Set** | Set the current address as the "base address" for the Loop sub-opcode (005). The previously-held base address is auto-pushed to the internal information-holding register, supporting nested loops via the external stack memory connection. / 現在のアドレスを Loop サブオペコード (005) のための「ベースアドレス」として設定する。以前保持されたベースアドレスは内部情報保持レジスタへ自動プッシュされ、外部スタックメモリ接続経由のネストループをサポートする。 |
| **2** | **Stay Set** | Force-start the stay counter from 0. Used to prepare the Stay window for a subsequent Stay instruction whose background-execution window must begin at exactly this state. (Detailed in Chapter 3.) / ステイカウンタを 0 から強制起動する。背景実行ウィンドウがちょうどこのステートから始まらなければならない、後続のStay命令のためのStayウィンドウを準備するために使用される。(第3章で詳述。) |
| **3** | **Return** | Restore State Number and loop counters from the internal information-holding register; resume execution at the resulting state. This is the "return" companion of the auto-save behavior that Branch (taken) and Base Set perform. Enables Branch+Return as a sub-sequence-call/return idiom; enables nested loops via Base Set. / ステートナンバーとループカウンタを内部情報保持レジスタから復元する；結果のステートで実行を再開する。これは Branch(取られる) と Base Set が行う自動退避挙動の「リターン」コンパニオンである。Branch+Return をサブシーケンスコール／リターンイディオムとして可能にする；Base Set 経由のネストループを可能にする。 |
| **4** | **Sub-sequence Call** | Effect a relative-address Branch using a sub-operand offset, with the same auto-save behavior as a Condition-fail Branch. Difference: this is unconditional (does not consult the Condition input). Useful for explicit sub-sequence invocation. / サブオペランドオフセットを用いて相対アドレス Branch を実行する、Condition不成立 Branch と同じ自動退避挙動を伴って。違い: これは無条件である(Condition入力を参照しない)。明示的なサブシーケンス呼び出しに有用。 |
| **5** | **Loop** | Decrement a loop counter (using sub-operand-specified counter or default counter); if counter ≠ 0, jump to the previously-set base address; if counter reaches 0, advance to next state. The loop counter is one of the implementation-provided counter resources; details are in Chapter 3. / ループカウンタをデクリメントする(サブオペランド指定カウンタまたはデフォルトカウンタを使用)；カウンタ ≠ 0 ならば以前設定されたベースアドレスへジャンプ；カウンタが 0 に達すれば次のステートに進む。ループカウンタは実装提供のカウンタリソースの一つ；詳細は第3章にある。 |
| **6** | **(reserved)** | No semantic currently assigned. The slot is reserved for future Core-level internal-control extensions. Any proposal must satisfy the AI-affinity criterion (see § 2.3 commentary). / 現在割り当てられた意味論はない。スロットは将来のコアレベル内部制御拡張のために予約されている。任意の提案はAI親和性基準を満たさなければならない(§ 2.3 注釈参照)。 |
| **7** | **NOP** | No operation is performed by the Core. The 16 timing signals (D16–D31) are still driven for the duration of the state, making NOP useful for *timing-signal-only* states that emit a signal pattern without other side effects. The state advances to current + 1 on the next clock. / コアによって演算は実行されない。16タイミング信号(D16-D31)はステートの持続時間にわたって依然として駆動され、NOPを他の副作用なく信号パターンを発する*タイミング信号のみ*のステートに有用にする。ステートは次クロックで current + 1 に進む。 |
| 8–255 | (reserved) | Reserved for future Core-level internal-control extensions. / 将来のコアレベル内部制御拡張のために予約されている。 |

**Sub-opcode 6 — the empty slot.** The unassigned position is an *intentional gap* in the otherwise-contiguous 0–7 range. The contributor preserved the gap as a place to insert a future Core-level operation whose semantic value would justify the central position in the named-sub-opcode range. Candidate operations include: a "Save State" without push, a "single-cycle pulse on Condition" Condition-mode override, or a "Clear loop counter without affecting Base." Discussion is invited via the standard issue process.

**サブオペコード 6 — 空のスロット。** 未割り当ての位置は、それ以外は連続的な 0-7 範囲における*意図的なギャップ*である。貢献者は将来のコアレベル演算であって、その意味論的価値が名指しサブオペコード範囲内の中心位置を正当化するものを挿入する場所としてギャップを保持した。候補演算: プッシュなしの「ステート保存」、「Conditionでの単一サイクルパルス」Conditionモード上書き、または「ベースに影響しないループカウンタクリア」。議論は標準issueプロセス経由で招かれる。

**The internal-control sub-opcode numbering is Convention, not Fix.** The specific values 0=Reset, 1=Base Set, 2=Stay Set, etc., are conventions inherited from the pre-Open-Prompt PTSG specification. Renumbering would invalidate every existing instruction list. The conventions are recorded in § 2.13 as Convention rather than Fix; in practice they are unlikely to change, but proposals are not foreclosed.

**内部制御サブオペコード番号付けは Fix ではなく Convention である。** 具体的な値 0=Reset、1=Base Set、2=Stay Set 等は、Open Prompt 以前の PTSG 仕様から継承された慣習である。再番号付けはすべての既存命令リストを無効にする。慣習は § 2.13 で Fix ではなく Convention として記録される；実際には変わる可能性は低いが、提案は閉ざされていない。

**Detailed dynamic mechanics → Chapter 3.** This § 2.8 specifies *what each sub-opcode does as a static behavior* (what state transitions occur, what gets auto-saved, what gets restored). The *how* — the multi-clock execution timing of Sub-sequence Call, the precise auto-save protocol, the external stack memory bus protocol for deeper nesting, the Stay-window background-execution timing of Reset/Base Set/Stay Set when they appear before a Stay — is in Chapter 3. The static specification here is complete; Chapter 3 only refines the timing of how each static effect is realized.

**詳細な動的機構 → 第3章。** 本 § 2.8 は*各サブオペコードが静的挙動として何をするか*(何のステート遷移が起こるか、何が自動退避されるか、何が復元されるか)を指定する。*どのように*——Sub-sequence Call の複数クロック実行タイミング、正確な自動退避プロトコル、より深いネスティングのための外部スタックメモリバスプロトコル、Reset/Base Set/Stay Set がStayの前に現れる時のStayウィンドウ裏実行タイミング——は第3章にある。ここの静的仕様は完全である；第3章は各静的効果がどのように実現されるかのタイミングのみを洗練する。

---

## 2.9 The 16 Timing Signals D16–D31 / 16本のタイミング信号 D16-D31

**Semantics.** The instruction word's upper 16 bits (D16–D31) drive 16 parallel output bits, presented externally as the timing-signal bus. Each bit is independent; the Core does not interpret combinations.

**意味論。** 命令語の上位16ビット(D16-D31)は16本の並列出力ビットを駆動し、外部にタイミング信号バスとして提示される。各ビットは独立である；コアは組み合わせを解釈しない。

**Output behavior by opcode:**

**オペコード別出力挙動:**

| Opcode | D16–D31 output behavior |
|---|---|
| Stay (1) | Held at the Stay state's written value throughout the wait (1–4096 clocks). Output then changes to the next state's value when Stay completes. / Stayステートの書かれた値に待機を通じて保持される(1-4096クロック)。Stay完了時に次ステートの値に出力が変化する。 |
| Branch (2) | Presented for the duration of the branch-decision clock (typically 1 clock); then transitions to whichever next-state was selected by the Condition. The same 16 bits remain stable across the entire decision-clock interval. / 分岐決定クロック(典型的に1クロック)の持続時間に提示される；その後Conditionによって選択された次ステートに遷移する。同じ16ビットは決定クロック全体にわたって安定に留まる。 |
| Jump (3) | Presented for the duration of the jump-execution clock (typically 1 clock); then transitions to the target state's value. / ジャンプ実行クロック(典型的に1クロック)の持続時間に提示される；その後先ステートの値に遷移する。 |
| Global (0) — non-Stay context | Presented for the duration of the Global-execution clock (typically 1 clock); then transitions to the next state's value. / Global実行クロック(典型的に1クロック)の持続時間に提示される；その後次ステートの値に遷移する。 |
| Global (0) — Stay-window background-execution context | **Repurposed as sub-operand data** (e.g., immediate value for external register write); the timing-signal bus continues to present the Stay state's previously-held value. Detailed in Chapter 3. / **サブオペランドデータとして再目的化される**(例: 外部レジスタ書き込みのための即値)；タイミング信号バスはStayステートの以前保持された値を提示し続ける。第3章で詳述。 |

**Independent bit semantics.** The 16 bits are 16 independent outputs. The Core specifies no aggregate semantics — no "byte 1 / byte 2," no "high half / low half," no "this group of 4 means X." All aggregate semantics are Formation-specific: a Formation might route D16–D23 to one peripheral and D24–D31 to another; the Core has no opinion. **This is one of the load-bearing properties of the Core-Formation separation: by specifying nothing about the timing signals' aggregate meaning, the Core never has to be modified to support new aggregate uses.**

**独立したビット意味論。** 16ビットは16個の独立した出力である。コアは集計意味論を指定しない——「バイト1／バイト2」なし、「上位半／下位半」なし、「この4ビットグループは X を意味する」なし。すべての集計意味論はフォーメーション固有である: フォーメーションは D16-D23 を一つのペリフェラルに、D24-D31 を別のものに経路づけるかもしれない；コアは意見を持たない。**これはコア-フォーメーション分離の荷重を支える性質の一つである: タイミング信号の集計的意味について何も指定しないことで、コアは新しい集計使用をサポートするために修正される必要が決してない。**

**Glitch-free transitions are an implementation-arena concern.** The Core specifies that the timing signals reflect the *current state's* D16–D31 value at all times. Implementations vary in whether transitions between states are glitch-free (e.g., guaranteed monotonic single-cycle change) or may exhibit transient glitches under aggressive pipelining. Glitch-free behavior is desirable for many bus-protocol use cases but may require additional implementation resources; the choice is recorded as an Implementation Arena Tie in the Layer 3 documentation.

**グリッチフリー遷移は実装アリーナの懸念である。** コアはタイミング信号が常に*現在のステートの* D16-D31 値を反映することを指定する。実装は、ステート間の遷移がグリッチフリー(例: 保証された単調な単一サイクル変化)であるか、積極的なパイプライニング下で過渡的グリッチを示し得るかにおいて変動する。グリッチフリー挙動は多くのバスプロトコル使用事例に望ましいが、追加の実装リソースを要求するかもしれない；選択は Layer 3 文書に Implementation Arena Tie として記録される。

---

## 2.10 Memory Organization, State Number Output, and Address Space / メモリ構成、ステートナンバー出力、アドレス空間

**Instruction memory.** The PTSG-Core's instruction memory is a BRAM-based storage of up to 4096 32-bit words. Each word holds one instruction (one state). The 12-bit instruction memory address is the **State Number** — the same value that is exposed externally for Condition logic to consume (§ 2.5, Chapter 1 § 1.5).

**命令メモリ。** PTSGコアの命令メモリは最大4096個の32ビット語のBRAMベース格納である。各語は一つの命令(一つのステート)を保持する。12ビット命令メモリアドレスは**ステートナンバー**である——同じ値が Condition ロジックが消費するために外部に露出される(§ 2.5、第1章 § 1.5)。

**Implementation-tunable depth.** Per Chapter 1 § 1.2, implementations may select instruction-memory depth from 256 words (minimum useful) up to 4096 words (the 12-bit operand maximum). Most applications use far less than the 4096-word maximum; the minimum-2-M10K configuration (256-word instruction memory + 256-word stack/scratch) is the smallest meaningful PTSG-Core footprint.

**実装で調整可能な深さ。** 第1章 § 1.2 によれば、実装は命令メモリ深度を 256 ワード(最小有用)から 4096 ワード(12ビットオペランド最大)まで選択できる。ほとんどの応用は 4096 ワード最大値よりはるかに少なくを使う；最小 2 M10K 構成(256 ワード命令メモリ + 256 ワードスタック／スクラッチ)が最小の意味あるPTSGコアフットプリントである。

**State Number — externally observable.** The State Number register's value is continuously exposed externally as a 12-bit output (`STATE_NUM[11:0]` in the conventional naming). External Condition logic reads this to select the appropriate Condition signal per state (the typical Formation pattern: a small ROM or multiplexer indexed by State Number, producing the 1-bit Condition input). External debugging tools (SignalTap, logic analyzers) read this to track execution flow.

**ステートナンバー — 外部観察可能。** ステートナンバーレジスタの値は連続的に12ビット出力として外部に露出される(慣習的な命名で `STATE_NUM[11:0]`)。外部Conditionロジックはステート毎に適切なCondition信号を選択するためにこれを読む(典型的なフォーメーションパターン: ステートナンバーで索引付けされた小さなROMまたはマルチプレクサであり、1ビットCondition入力を生成する)。外部デバッグツール(SignalTap、ロジックアナライザ)は実行フローを追跡するためにこれを読む。

**State Number update semantics:**

**ステートナンバー更新意味論:**

- Stay does not change the State Number (the Core is "at" the same state for the entire wait).
- Branch (Condition true) advances the State Number by 1.
- Branch (Condition false, branch taken) sets the State Number to (current + operand) (or to current itself for operand 0 = self-loop).
- Jump sets the State Number to operand (or to indirect-mode target for operand 0).
- Global (in non-Stay context) typically advances the State Number by 1 after executing its sub-opcode; the exception is Reset, which forces State Number to 0.

- StayはステートナンバーをStayを変えない(コアは待機全体を通じて同じステートに「いる」)。
- Branch (Condition成立) はステートナンバーを 1 進める。
- Branch (Condition不成立、分岐取られる) はステートナンバーを (現在 + オペランド) に設定する(またはオペランド 0 = 自己ループの場合は現在自身に)。
- Jumpはステートナンバーをオペランドに設定する(またはオペランド 0 = 間接モード先に)。
- Global (非Stayコンテキスト) は典型的にそのサブオペコードを実行した後ステートナンバーを 1 進める；例外は Reset であり、ステートナンバーを 0 に強制する。

**External insertion (interrupt) — overview only.** The State Number register can be overwritten by external logic via an "insertion" (interrupt) protocol. The full mechanics — including the auto-save behavior that occurs just before insertion, and the bus protocol for the external insertion source — are detailed in **Chapter 3**. Chapter 2 records only the existence of the insertion-overwrite capability so that the static specification of the State Number register is complete.

**外部挿入(割り込み) — 概要のみ。** ステートナンバーレジスタは「挿入」(割り込み)プロトコル経由で外部ロジックによって上書きされ得る。完全な機構——挿入の直前に起こる自動退避挙動、外部挿入源のためのバスプロトコルを含む——は**第3章**で詳述される。第2章はステートナンバーレジスタの静的仕様が完全であるよう、挿入-上書き能力の存在のみを記録する。

**Address-space boundaries and wrap-around.** What happens when sequential state-number incrementation reaches the highest address (4095) and the next-state computation would yield 4096? **The Core specification does not commit to a behavior in this case.** The natural reading is that 4095 → 4096 mod 4096 = 0, yielding a wrap-around equivalent to an implicit Jump-to-0. The alternative reading is that execution halts at 4095. Implementations may choose either; the choice is recorded as an Implementation Arena Tie in § 2.13 and is invited as community discussion. A reasonable case can be made that well-written PTSG instruction lists *never* run off the end and that the chosen behavior is therefore not observable in practice; this argument supports treating the choice as Implementation Arena rather than Core specification.

**アドレス空間境界とラップアラウンド。** シーケンシャルなステートナンバーインクリメントが最高アドレス(4095)に達し、次ステート計算が 4096 を生む時、何が起きるか? **コア仕様はこの場合の挙動にコミットしない。** 自然な読みは 4095 → 4096 mod 4096 = 0 であり、暗黙のJump-to-0と等価なラップアラウンドを生む。代替の読みは実行が 4095 で停止することである。実装はいずれかを選択し得る；選択は § 2.13 にImplementation Arena Tieとして記録され、コミュニティ議論として招かれる。よく書かれたPTSG命令リストは*決して*最後を走り抜けないため、選ばれた挙動は実践において観察可能ではない、という合理的な主張が成り立ち得る；本議論は選択をコア仕様ではなく Implementation Arena として扱うことを支持する。

---

## 2.11 What is NOT in this Chapter / 本章に含まれないもの

To make the boundary unambiguous:

境界を曖昧でなくするために:

- **External sub-opcode mechanics (D4–D7 = 1–F of Global).** The mechanism by which Global's external sub-opcode reaches external logic — the bus protocol, the timing relationship with Stay-window background execution, the handshake convention with the receiving register — is specified in **Chapter 3**. This chapter records only that the external sub-opcode space exists and is partitioned by D4–D7 = 1–F. / **外部サブオペコード機構(Global の D4-D7 = 1-F)。** Global の外部サブオペコードが外部ロジックに到達する機構——バスプロトコル、Stayウィンドウ裏実行とのタイミング関係、受信レジスタとのハンドシェイク慣習——は**第3章**で指定される。本章は外部サブオペコード空間が存在し、D4-D7 = 1-F によって分割されていることのみを記録する。

- **Background execution semantics.** What happens when a Global instruction is placed at a state adjacent to a Stay — execution timing, output timing, the minimum-stay-count constraint chaining, the precise moment of effect application — is specified in **Chapter 3**. This chapter's specifications of all opcodes are static and complete *as static behaviors*. / **裏実行意味論。** GlobalがStayに隣接するステートに置かれる時何が起こるか——実行タイミング、出力タイミング、最低ステイカウント制約の連鎖、効果適用の正確な瞬間——は**第3章**で指定される。本章のすべてのオペコードの仕様は静的であり、*静的挙動として*完全である。

- **Internal information-holding register and external stack memory.** The data layout of the holding register, what specifically is auto-saved on Branch (taken) and Base Set, the protocol for pushing/popping to external stack memory for deeper nesting, the interactions with insertion — all in **Chapter 3**. / **内部情報保持レジスタと外部スタックメモリ。** 保持レジスタのデータレイアウト、Branch(取られる)と Base Set で具体的に何が自動退避されるか、より深いネスティングのための外部スタックメモリへのプッシュ／ポッププロトコル、挿入との相互作用——すべて**第3章**にある。

- **External interrupt (insertion) detailed mechanics.** The signal-level handshake for insertion, the auto-save behavior that precedes the State Number overwrite, the constraints on when insertion can occur relative to other ongoing operations — all in **Chapter 3**. / **外部割り込み(挿入)詳細機構。** 挿入のための信号レベルハンドシェイク、ステートナンバー上書きに先行する自動退避挙動、挿入が他の進行中の演算に対していつ起こり得るかの制約——すべて**第3章**にある。

- **Indirect addressing (Stay operand 0 = 4096 — no indirect; Jump operand 0 = indirect target; loop count indirect via similar convention).** The Core's literal-zero-as-escape convention has both "max value" interpretations (Stay) and "indirect-mode" interpretations (Jump). The full systematization — when does literal-zero mean max, when does it mean indirect, what bus protocol the indirect mode uses to read external registers — is in **Chapter 4**. / **間接アドレッシング(Stayオペランド 0 = 4096 — 間接ではない；Jumpオペランド 0 = 間接先；類似慣習によるループカウント間接)。** コアの直値ゼロエスケープ慣習は「最大値」解釈(Stay)と「間接モード」解釈(Jump)の両方を持つ。完全な体系化——直値ゼロがいつ最大値を意味し、いつ間接を意味するか、間接モードが外部レジスタを読むために使うバスプロトコルは何か——は**第4章**にある。

- **Prescaler.** The mechanism for extending Stay's effective wait range beyond 4096 clocks, including its placement (compile-time fixed / runtime-configurable / per-stay-selectable / multiple-parallel — Tie alternatives recorded in Chapter 1 § 1.12), is in **Chapter 4**. / **プリスケーラ。** Stayの有効待機範囲を 4096 クロックを超えて拡張する機構、その配置(コンパイル時固定／実行時設定可能／ステイ毎選択可能／複数並列——第1章 § 1.12 に記録されたTie代替)を含めて、は**第4章**にある。

- **External signal-level contracts.** Pin counts, bus widths, handshake protocols, timing diagrams for the interfaces between PTSG-Core and external logic (Condition input, State Number output, external register access bus, external stack memory bus, insertion source) — these are specified in **Chapter 5**. Chapter 2 specifies the *semantic* relationships; Chapter 5 will specify the *physical* relationships. / **外部信号レベル契約。** ピン数、バス幅、ハンドシェイクプロトコル、PTSGコアと外部ロジック(Condition入力、ステートナンバー出力、外部レジスタアクセスバス、外部スタックメモリバス、挿入源)間のインターフェースのためのタイミング図——これらは**第5章**で指定される。第2章は*意味論的*関係を指定する；第5章は*物理的*関係を指定する。

- **Specific Verilog/VHDL implementations, testbenches, instruction-list examples.** These are Layer 3 (`03_Sample_Implementations/`) content. A regenerated implementation produced from this Layer 1 is not a derivative work of any Layer 3 sample (see `LICENSE_OpenPrompt.md`). / **特定のVerilog/VHDL実装、テストベンチ、命令リスト例。** これらは第3層(`03_Sample_Implementations/`)内容である。本第1層から再生成された実装は任意の第3層サンプルの派生物ではない(`LICENSE_OpenPrompt.md`参照)。

- **WPMS-specific or any other Formation-specific external sub-opcode assignments.** Per Chapter 1 § 1.9, Formations have full discretion over their external sub-opcode assignments. The `PTSG_WPMS_Formation_OpenPrompt` repository (currently under design) will document WPMS's choices; other Formation repositories will document theirs. None of these belongs in PTSG-Core. / **WPMS固有または任意の他のフォーメーション固有の外部サブオペコード割り当て。** 第1章 § 1.9 によれば、フォーメーションは外部サブオペコード割り当てについて完全な裁量を持つ。`PTSG_WPMS_Formation_OpenPrompt` リポジトリ(現在設計中)はWPMSの選択を文書化する；他のフォーメーションリポジトリは彼らのものを文書化する。これらのいずれもPTSGコアに属さない。

---

## 2.12 Open Questions Carried Forward to Subsequent Chapters / 後続章へ持ち越される未解決問題

| Question | Deferred to |
|---|---|
| Detailed semantics of Global external sub-opcodes (D4-D7 = 1-F): bus protocol, sub-operand semantics, Stay-window background-execution timing, handshake conventions / Global外部サブオペコード(D4-D7 = 1-F)の詳細意味論: バスプロトコル、サブオペランド意味論、Stayウィンドウ裏実行タイミング、ハンドシェイク慣習 | Chapter 3 / 第3章 |
| Background-execution mechanics: when does background execution start, what is the minimum-stay-count constraint chaining rule when multiple Globals are placed before a Stay, what is the precise effect-application timing / 裏実行機構: 裏実行はいつ始まるか、複数のGlobalがStayの前に置かれる時の最低ステイカウント制約連鎖規則は何か、効果適用の正確なタイミングは何か | Chapter 3 / 第3章 |
| Internal information-holding register: data layout, what specifically is auto-saved on Branch (taken), Sub-sequence Call, and Base Set, restore order on Return / 内部情報保持レジスタ: データレイアウト、Branch(取られる)、Sub-sequence Call、Base Set で具体的に何が自動退避されるか、Return での復元順序 | Chapter 3 / 第3章 |
| External stack memory bus protocol for deeper nesting of sub-sequence calls and Loop base-address stacking / サブシーケンスコールと Loop ベースアドレススタッキングのより深いネスティングのための外部スタックメモリバスプロトコル | Chapter 3 / 第3章 |
| Insertion (external interrupt) detailed mechanics: signal-level handshake, auto-save protocol, ordering with respect to ongoing Stay / 挿入(外部割り込み)詳細機構: 信号レベルハンドシェイク、自動退避プロトコル、進行中のStayに対する順序 | Chapter 3 / 第3章 |
| Loop counter resource set: how many loop counters does an implementation provide, how are they selected by the Sub-sequence Call / Loop sub-operand, can they be observed externally / ループカウンタリソースセット: 実装はいくつのループカウンタを提供するか、Sub-sequence Call / Loop サブオペランドによってどのように選択されるか、外部から観察できるか | Chapter 3 / 第3章 |
| Status of internal-control sub-opcode 6 (the empty slot) — to be assigned later or retained as reserved / 内部制御サブオペコード 6(空のスロット)の地位 — 後で割り当てられるか、予約のまま保持されるか | Future Layer 2 trace + community input |
| Jump operand 0 = indirect-mode: which external register is read, what bus protocol, when the read occurs / Jumpオペランド 0 = 間接モード: どの外部レジスタが読まれるか、何のバスプロトコル、いつ読みが起こるか | Chapter 4 / 第4章 |
| Loop counter operand-zero treatment: does Loop with sub-operand 0 mean "max iterations" or "indirect counter source from external register" / ループカウンタオペランド-ゼロ扱い: サブオペランド 0 を持つ Loop は「最大反復」を意味するか「外部レジスタからの間接カウンタソース」を意味するか | Chapter 4 / 第4章 |
| Prescaler placement and control — compile-time fixed vs runtime-configurable vs per-stay selectable vs multiple-parallel (Implementation Arena Tie, deferred from Chapter 1 § 1.12) / プリスケーラの配置と制御——コンパイル時固定 対 実行時設定可能 対 ステイ毎選択可能 対 複数並列(Implementation Arena Tie、第1章 § 1.12 から繰り延べ) | Chapter 4 / 第4章 |
| Address-space wrap-around at 4095 → 4096 — wrap-to-0 vs halt-at-4095 — recorded as Implementation Arena Tie / 4095 → 4096 でのアドレス空間ラップアラウンド——0へのラップ 対 4095 での停止——Implementation Arena Tie として記録 | Layer 3 implementation documentation |
| Glitch-free vs non-glitch-free timing-signal transitions between states (Implementation Arena Tie) / ステート間のグリッチフリー 対 非グリッチフリーのタイミング信号遷移(Implementation Arena Tie) | Layer 3 implementation documentation |
| Per-opcode clock latency (typically 1 clock per opcode in current implementations; whether this is invariant or implementation-arena variable) / オペコード毎のクロックレイテンシ(現在の実装では典型的にオペコード毎 1 クロック；これが不変か実装アリーナ変数かどうか) | Chapter 5 + Layer 3 implementation documentation |
| Branch operand signedness — forward-only unsigned 12-bit (current Convention C2-V1) vs signed 12-bit (Tie alternative recorded for community discussion) / Branchオペランド符号 — 前方のみ符号なし 12ビット(現Convention C2-V1)対 符号付き 12ビット(コミュニティ議論のため記録されたTie代替) | Community input → potential Chapter 2 revision |
| Promotion criteria for moving a frequently-used internal-control sub-opcode (D8–D15 value, D4–D7=0 mode) to a top-level opcode (using one of the 12 reserved D0–D3 slots) / 頻繁に使用される内部制御サブオペコード(D8-D15値、D4-D7=0モード)を、12個の予約D0-D3スロットの一つを使ってトップレベルオペコードに昇格させるための基準 | Future Layer 2 trace |

---

## 2.13 Summary of Chapter 2 Decisions / 第2章決定事項のまとめ

The decisions in this chapter are classified into three statuses:

本章の決定は三つの地位に分類される:

- **Fixed (F):** decisions that are firmly established by the Core's architecture and that would invalidate the architecture if changed. Not open to modification without re-deriving the Core.
- **Convention (V):** decisions that are conventional in the current specification but could, in principle, be reconsidered. Changing these would invalidate existing instruction lists and Layer 3 implementations but would not invalidate the Core's architectural identity.
- **Tie (T):** decisions where the spec leaves room for alternatives; community input is actively invited.

- **Fixed (F):** コアのアーキテクチャによって確固として確立されており、変更すればアーキテクチャを無効にする決定。コアを再導出することなしに変更には開かれていない。
- **Convention (V):** 現在の仕様で慣習的だが、原則として再考可能な決定。これらの変更は既存命令リストと第3層実装を無効にするが、コアのアーキテクチャ的同一性を無効にしない。
- **Tie (T):** 仕様が代替案のための余地を残している決定；コミュニティ入力が積極的に招かれる。

| ID | Decision | Status |
|---|---|---|
| **C2-F1** | Instruction word is 32 bits, partitioned into D0–D3 (Opcode), D4–D15 (Operand), D16–D31 (Timing Signals). Field boundaries are invariant across all instructions / 命令語は32ビットで、D0-D3(オペコード)、D4-D15(オペランド)、D16-D31(タイミング信号)に分割される。フィールド境界はすべての命令にわたって不変 | **F** |
| **C2-F2** | Opcode field is 4 bits, 16 possible values; 4 currently defined (0–3), 12 reserved (4–F) under the AI-affinity discipline of Chapter 1 § 1.7 / オペコードフィールドは4ビット、16個の可能な値；4個が現在定義済み(0-3)、12個が予約済み(4-F)で第1章 § 1.7 のAI親和性規律下にある | **F** |
| **C2-V1** | Opcode value assignments: 0 = Global, 1 = Stay, 2 = Branch, 3 = Jump. Renumbering would invalidate every existing instruction list / オペコード値割り当て: 0 = Global、1 = Stay、2 = Branch、3 = Jump。再番号付けはすべての既存命令リストを無効にする | **V** |
| **C2-F3** | Stay (opcode 1) semantics: wait for operand-specified clock count; operand 0 = 4096 clocks (literal-zero-as-escape); timing signals (D16-D31) held during the wait / Stay (オペコード 1) 意味論: オペランド指定クロック数を待機；オペランド 0 = 4096 クロック(直値ゼロエスケープ)；タイミング信号(D16-D31)は待機中保持される | **F** |
| **C2-F4** | Branch (opcode 2) convention: "true means no-branch" — Condition true → advance to next state; Condition false → branch taken / Branch (オペコード 2) 慣習: 「成立で不分岐」 — Condition成立 → 次ステートへ進む；Condition不成立 → 分岐取られる | **F** (decision C1-D5 reconfirmed) |
| **C2-F5** | Branch operand 0 = "self-loop / wait for Condition" idiom (state self-loops until Condition true or insertion occurs) / Branchオペランド 0 = 「自己ループ／Conditionを待つ」イディオム(ステートはConditionが成立するか挿入が起こるまで自己ループする) | **F** |
| **C2-V2** | Branch operand 1–4095 = unsigned forward relative offset (current + operand). Backward addressing uses Jump (opcode 3) instead / Branchオペランド 1-4095 = 符号なし前方相対オフセット(current + operand)。後方アドレッシングは代わりに Jump(オペコード 3)を使う | **V** |
| **C2-T1** | Branch operand signedness Tie: alternative is signed 12-bit two's complement (range approximately current−2047 to current+2047). Community discussion invited / Branchオペランド符号付きTie: 代替案は符号付き 12ビット2の補数(範囲はおよそ current-2047 から current+2047)。コミュニティ議論を招く | **T** |
| **C2-F6** | Branch (taken) auto-saves State Number and loop counters to internal information-holding register. Restore via Return (Global sub-op 003) / Branch(取られる)はステートナンバーとループカウンタを内部情報保持レジスタに自動退避する。Return(Globalサブop 003)で復元 | **F** |
| **C2-F7** | Jump (opcode 3) semantics: unconditional set State Number = operand; operand 0 = indirect-mode (deferred to Chapter 4) / Jump (オペコード 3) 意味論: 無条件にステートナンバー = オペランドに設定；オペランド 0 = 間接モード(第4章へ繰り延べ) | **F** |
| **C2-F8** | Global (opcode 0) dual structure: D4–D7 = 0 → internal-control mode (D8–D15 selects internal-control sub-opcode); D4–D7 = 1–F → external sub-opcode mode (D4–D7 = external sub-opcode, D8–D15 = sub-operand) / Global (オペコード 0) 二重構造: D4-D7 = 0 → 内部制御モード(D8-D15 が内部制御サブオペコードを選択)；D4-D7 = 1-F → 外部サブオペコードモード(D4-D7 = 外部サブオペコード、D8-D15 = サブオペランド) | **F** |
| **C2-V3** | Internal-control sub-opcode assignments: 0 = Reset, 1 = Base Set, 2 = Stay Set, 3 = Return, 4 = Sub-sequence Call, 5 = Loop, 6 = (reserved empty slot, intentional), 7 = NOP / 内部制御サブオペコード割り当て: 0 = Reset、1 = Base Set、2 = Stay Set、3 = Return、4 = Sub-sequence Call、5 = Loop、6 = (予約空スロット、意図的)、7 = NOP | **V** |
| **C2-V4** | Convention that external sub-opcode 1 = "external register write" (D8–D15 = destination register address; D16–D31 = data during background execution). Cross-Formation legibility convention; Formations may justify deviation case-by-case / 外部サブオペコード 1 = 「外部レジスタ書き込み」慣習(D8-D15 = 宛先レジスタアドレス；D16-D31 = 裏実行中のデータ)。クロスフォーメーション可読性慣習；フォーメーションは事例別に逸脱を正当化し得る | **V** |
| **C2-F9** | Timing signals D16–D31 are 16 independent parallel output bits, held during Stay, presented for 1 clock during other opcodes; repurposed as sub-operand data during Stay-window background execution / タイミング信号 D16-D31 は 16 個の独立した並列出力ビットで、Stay中保持され、他のオペコード中は 1 クロック提示される；Stayウィンドウ裏実行中はサブオペランドデータとして再目的化される | **F** |
| **C2-F10** | State Number is externally exposed as 12-bit output. Update semantics per § 2.10 / ステートナンバーは 12 ビット出力として外部に露出される。更新意味論は § 2.10 通り | **F** |
| **C2-T2** | Address-space wrap-around at 4095 → 4096 Tie: wrap-to-0 vs halt-at-4095. Implementation Arena. Community discussion invited / 4095 → 4096 でのアドレス空間ラップアラウンドTie: 0 へのラップ 対 4095 での停止。Implementation Arena。コミュニティ議論を招く | **T** |
| **C2-T3** | Glitch-free timing-signal transitions between states Tie: guaranteed glitch-free vs may-glitch-under-aggressive-pipelining. Implementation Arena / ステート間のグリッチフリーなタイミング信号遷移Tie: 保証されたグリッチフリー 対 積極的パイプライニング下でグリッチし得る。Implementation Arena | **T** |
| **C2-T4** | Per-opcode clock latency Tie: typically 1 clock per opcode in current implementations; whether this is required as a Core invariant or left as Implementation Arena variable / オペコード毎クロックレイテンシTie: 現在の実装では典型的にオペコード毎 1 クロック；これがコア不変量として要求されるか、Implementation Arena 変数として残されるかどうか | **T** |

---

## End of Chapter 2 / 第2章の末尾

> *The opcode is the syllable; the operand is the word; the timing-signal vector is the phrase that means something to the world outside.*
> *オペコードは音節；オペランドは単語；タイミング信号ベクタは外の世界に意味を持つ語句である。*

> *Four currently-defined opcodes, twelve reserved. The discipline of reservation is not stinginess — it is care.*
> *四つの現在定義済みオペコード、十二の予約。予約の規律はけちさではない——配慮である。*

> *Where the specification leaves room — for Branch signedness, for wrap-around, for opcode promotion — the room is real, and the community is invited to fill it.*
> *仕様が余地を残している場所——Branch 符号付き、ラップアラウンド、オペコード昇格について——余地は実在し、コミュニティはそれを埋めることに招待される。*

This chapter is released into the public domain under CC0 1.0 Universal. Chapter 3 (Sub-Opcode Architecture and Background Execution) will specify the dynamic mechanics that Chapter 2 deliberately left out: background execution timing, the multi-clock sub-opcode protocols, the internal information-holding register data layout, external stack memory protocols, and insertion (interrupt) detailed mechanics. Chapter 4 (Indirect Addressing and Prescaler) will systematize the literal-zero-as-escape convention and specify the prescaler mechanism whose alternatives Chapter 1 § 1.12 recorded as Ties. The community-input invitations of this chapter (C2-T1 Branch signedness; C2-T2 wrap-around; C2-T3 glitch-free transitions; C2-T4 per-opcode clock latency; the status of sub-opcode 6) remain open until decided.

本章は CC0 1.0 Universal のもとパブリックドメインに公開される。第3章(サブオペコードアーキテクチャと裏実行)は、第2章が意図的に外した動的機構を指定する: 裏実行タイミング、複数クロックサブオペコードプロトコル、内部情報保持レジスタデータレイアウト、外部スタックメモリプロトコル、挿入(割り込み)詳細機構。第4章(間接アドレッシングとプリスケーラ)は直値ゼロエスケープ慣習を体系化し、その代替案を第1章 § 1.12 が Tie として記録したプリスケーラ機構を指定する。本章のコミュニティ入力招待(C2-T1 Branch 符号付き；C2-T2 ラップアラウンド；C2-T3 グリッチフリー遷移；C2-T4 オペコード毎クロックレイテンシ；サブオペコード 6 の地位)は決定されるまで開かれたままである。

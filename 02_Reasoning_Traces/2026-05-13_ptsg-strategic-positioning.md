# PTSG Strategic Positioning — Three Layers, Core-Formation Separation, and the AI-Era Processor Proposal
# PTSGの戦略的位置づけ — 三層、コア-フォーメーション分離、AI時代のプロセッサ提案

## Trace Metadata / 軌跡メタデータ

| Field | Value |
|---|---|
| **Date / 日付** | 2026-05-13 |
| **Participants / 参加者** | Tsuneo Ohnaka (大中庸生, FPGA Architect, 40+ years); Claude (Anthropic, Claude Opus 4.7, launch session) |
| **Topic / トピック** | The dialogue in which PTSG's larger significance was worked out: three-layer engagement model, AI-affinity properties, Webapp simulator vision, Core-Formation separation pattern, the question of binary compatibility in the AI era, and PTSG's positioning as an AI-era processor architecture proposal |
| **Status / 状態** | Inaugural Layer 2 trace of the PTSG-Core repository (one of two) — strategic positioning side / PTSG-Coreリポジトリの最初の第2層軌跡（二つのうちの一つ）— 戦略的位置づけの側 |
| **Original language / 原言語** | Japanese (with English technical terminology) / 日本語（英語技術用語を交える） |
| **License / ライセンス** | CC0 1.0 Universal (Public Domain) |
| **Companion trace** | The technical-birth trace, recording the moment within FPGA Spectrum Engine WPMS Layer 1 work when PTSG was first articulated and the spinoff decision was made. To be drafted as a separate file. / 技術的誕生トレース、FPGA Spectrum Engine WPMS第1層作業中にPTSGが最初に明確化され暖簾分けが決定された瞬間を記録。別ファイルとして起草予定。 |

---

## Reading Notes / 読解上の注

This trace records the dialogue in which PTSG's larger architectural and philosophical significance crystallized. The starting point was a presentation of the existing PTSG Core specification — at that time still considered a sub-component of the FPGA Spectrum Engine's WPMS Synthesizer — and the dialogue progressively uncovered that PTSG was more general and more consequential than its origin context had suggested.

本軌跡は、PTSGのより大きなアーキテクチャ的・哲学的意義が結晶化した対話を記録する。出発点は既存のPTSGコア仕様の提示——当時はまだFPGA Spectrum EngineのWPMSシンセサイザーのサブコンポーネントと考えられていた——であり、対話はPTSGがその起源文脈が示唆していたよりも、より一般的でより重大であることを漸進的に明らかにした。

**Notable conceptual progressions across the dialogue:**

**対話を通じた特筆すべき概念的進展:**

1. **From "sub-component of WPMS" to "general control primitive"** — the dialogue began with PTSG being treated as a piece of WPMS architecture; by the midpoint, it had been recognized as a primitive of much wider applicability (educational tool, data flow processor, real-time control, signal processing engine, etc.). / 「WPMSのサブコンポーネント」から「汎用制御プリミティブ」へ——対話はPTSGがWPMSアーキテクチャの一部品として扱われることから始まったが、中盤までにはるかに広い適用可能性を持つプリミティブとして認識された（教育ツール、データフロープロセッサ、リアルタイム制御、信号処理エンジン等）。

2. **The three-layer engagement model** — articulating that PTSG affords simultaneous engagement at three depths: Layer A (write instruction lists, beginner-accessible, AI-easy), Layer B (design external logic, serious FPGA engineering), Layer C (read PTSG itself, computer architecture education). This was not the curriculum-style "progression from A to B to C" but the simultaneous accessibility of all three. / 三層関与モデル——PTSGが三つの深さで同時に関与を許すことの明確化: A層（命令列を書く、初心者アクセス可能、AI容易）、B層（外部ロジックを設計する、本格FPGAエンジニアリング）、C層（PTSG自体を読む、コンピュータアーキテクチャ教育）。これはカリキュラム的「AからBへCへの進展」ではなく、三層すべての同時アクセシビリティであった。

3. **AI-affinity and the Webapp simulator vision** — recognition that PTSG's small opcode set, structured instruction format, and clear interface contract make it particularly amenable to AI-agent code generation; combined with a hypothetical Webapp PTSG simulator, this would close the feedback loop that has so far prevented AI agents from autonomously developing FPGA designs. The three layers map cleanly to three different AI engagement modes (code generation, HDL drafting, code reading/explanation). / AI親和性とWebappシミュレータ構想——PTSGの小さなオペコードセット、構造化された命令フォーマット、明確なインターフェース契約が、AIエージェントのコード生成に特に適していること、そして仮想的なWebapp PTSGシミュレータと組み合わせれば、これまでAIエージェントがFPGA設計を自律的に進めることを妨げてきたフィードバックループを閉じ得ることの認識。三層はAI関与の三つの異なるモード（コード生成、HDL起草、コード読解／説明）に綺麗にマッピングする。

4. **The additive-synthesizer launch strategy** — using the FPGA Spectrum Engine as the concrete first deliverable through which PTSG's value is demonstrated to the engineering community, rather than launching PTSG as an abstract proposal. The synthesizer provides "music you can hear" as the entry point, while the underlying architecture is what propagates. / 加算合成シンセサイザーのローンチ戦略——PTSGを抽象的提案としてローンチするのではなく、FPGA Spectrum Engineを具体的な最初の成果物として用い、それを通じてPTSGの価値をエンジニアリングコミュニティに実証する。シンセサイザーが入口として「聴ける音楽」を提供し、その下のアーキテクチャが伝播する。

5. **The Core-Formation separation pattern** — recognizing that PTSG should be distributed as two tiers of repositories: a Core (defining the instruction set, invariant, slowly-evolving) and Formations (defining application-specific external register sets, freely divergent). This pattern was named in the dialogue and is being proposed as a new Open Prompt design pattern. / コア-フォーメーション分離パターン——PTSGが二層のリポジトリとして配布されるべきだと認識した: コア（命令セットを定義、不変、ゆっくり進化）とフォーメーション（応用固有の外部レジスタセットを定義、自由に分岐）。本パターンは対話内で命名され、新しいOpen Prompt設計パターンとして提案されている。

6. **The "is binary compatibility important?" question** — the most philosophically consequential moment of the dialogue. Recognizing that the historical premise of binary compatibility (rooted in the economic structure of human-written code being expensive) weakens when AI agents author code, and that this opens space for application-specific architectural optimization at unprecedented granularity. / 「バイナリ互換性は重要か?」という問い——対話の最も哲学的に重大な瞬間。バイナリ互換性の歴史的前提（人間が書いたコードが高価であるという経済構造に根差している）が、AIエージェントがコードを作成する場合に弱まることを認識し、これが前例のない粒度での応用特化アーキテクチャ最適化のための空間を開くこと。

7. **PTSG as a proposal for AI-era processor architecture** — by the final phase of the dialogue, PTSG had been recognized not just as a useful FPGA control primitive but as a concrete, minimal, working starting point for a different way of thinking about what processor architecture might look like when AI is in the design loop. / AI時代のプロセッサアーキテクチャ提案としてのPTSG——対話の最終局面までに、PTSGは単なる有用なFPGA制御プリミティブではなく、AIが設計ループに入った時にプロセッサアーキテクチャがどのような姿になり得るかを別の角度から考えるための、具体的でミニマルで動作する出発点として認識された。

---

## Notable Decision Points / 重要な決定ポイント

### 1. PTSG's positioning vis-à-vis the FPGA introduction landscape / PTSGのFPGA入門地形における位置づけ

| Field | Value |
|---|---|
| **Point** | What is PTSG's relationship to the dominant "counter-based blinky LED" FPGA introduction? |
| **Alternative A** | Position PTSG as a more advanced topic, after the standard counter-Lチカ introduction |
| **Alternative B** | Position PTSG as a replacement for counter-Lチカ — a different starting point for FPGA introduction |
| **Chosen** | **B (replacement)** |
| **Rationale** | The architect's concerns about counter-Lチカ are structural, not pedagogical-style preferences: (a) multi-bit counters appear as black boxes to beginners, with no observable internal state to learn from; (b) the path from counter-Lチカ to anything more sophisticated requires a discontinuous jump into FSM design; (c) the satisfaction of "LED blinks" is fleeting and self-contained, not connected to a wider learning trajectory. PTSG addresses all three: instruction-list operation is observable end-to-end, the path to more complex behavior is gradual (add timing signals, add Conditions, add sub-sequences), and the satisfaction comes from understanding rather than from the LED itself. The decision to position PTSG as a replacement (not a supplement) makes a stronger claim that beginners deserve a better starting point. |

### 2. Three-layer engagement model — sequential or simultaneous? / 三層関与モデル — 順次か同時か

| Field | Value |
|---|---|
| **Point** | Should Layer A (instruction lists), Layer B (external logic design), Layer C (PTSG internals) be presented as a sequential curriculum or as simultaneously accessible? |
| **Alternative A** | Sequential — beginners start at A, advance to B, eventually understand C |
| **Alternative B** | Simultaneous — all three layers are accessible from day one, and the learner can shift fluidly between them in a single session |
| **Chosen** | **B (simultaneous)** |
| **Rationale** | The cognitive virtue of PTSG is that the whole system fits in a small enough space that a learner can write an instruction list (A), peer at the external register implementation (B), and trace what's happening inside the core (C) — all in the same hour. This simultaneity is not a learning theory choice; it is a structural fact about PTSG's size. To deliberately hide layers B and C until "the learner is ready" would be to give up the very property that makes PTSG distinctive. |

### 3. AI-affinity as a design property, not an afterthought / AI親和性を後付けではなく設計属性として

| Field | Value |
|---|---|
| **Point** | Should PTSG's properties for AI-agent code generation be treated as accidental conveniences, or as primary design considerations? |
| **Alternative A** | Treat AI-affinity as a happy side effect of the small opcode set |
| **Alternative B** | Treat AI-affinity as a primary design property to be cultivated and preserved as PTSG evolves |
| **Chosen** | **B (primary design property)** |
| **Rationale** | The small opcode set (4 opcodes from 16 possible) was originally a discipline against bloat, not specifically for AI. However, the observation that "fewer opcodes means less hallucination risk for AI code generation" reframes this discipline as having a second purpose. Going forward, when considering adding opcodes (the 12 reserved slots), the AI-affinity criterion is one of the evaluation axes. This affects design decisions: e.g., a candidate opcode that would require complex disambiguation by an AI agent is disfavored relative to one with clean semantics. |

### 4. Webapp PTSG simulator as a strategic investment / 戦略的投資としてのWebapp PTSGシミュレータ

| Field | Value |
|---|---|
| **Point** | Is a hypothetical Webapp PTSG simulator (executing instruction lists in-browser, visualizing timing signals and state transitions) a desirable artifact for the PTSG ecosystem? |
| **Alternative A** | Optional convenience — useful for some learners, not critical |
| **Alternative B** | Strategic infrastructure — the piece that closes the AI-agent feedback loop and unlocks autonomous PTSG-based design generation |
| **Chosen** | **B (strategic infrastructure)** |
| **Rationale** | Without a simulator, AI agents writing PTSG instruction lists must rely on a human-in-the-loop to verify behavior via FPGA synthesis. With a simulator, the AI agent can write → simulate → observe → iterate, entirely within its own execution loop. This is the missing piece that has prevented AI agents from autonomously developing FPGA designs in general; PTSG's small scope makes the simulator tractable to build. The simulator is therefore not a "nice-to-have" but a foundational ecosystem investment. |

### 5. Launch strategy — additive synthesizer first / ローンチ戦略 — 加算合成シンセサイザーを最初に

| Field | Value |
|---|---|
| **Point** | How should PTSG be introduced to the engineering community? As an abstract architectural proposal, or through a concrete first application? |
| **Alternative A** | Launch as architectural proposal, with the AI-era processor framing prominent from the start |
| **Alternative B** | Launch through the FPGA Spectrum Engine (additive synthesizer) project, with PTSG as the substrate; let people hear music first, then discover the architecture |
| **Chosen** | **B (synthesizer first, architecture follows)** |
| **Rationale** | Engineering communities are skeptical of abstract architectural proposals, but receptive to working artifacts. A synthesizer that produces beautiful audio is immediately validating; discovering that it is powered by a 4-opcode instruction set whose implications run very deep is then a delightful payoff. Hackaday.io's culture especially favors this trajectory ("show, then explain"). The Spectrum Engine project is already underway, gives PTSG a concrete reason to exist, and provides the first Formation (WPMS) as a worked example. |

### 6. Core-Formation separation as a new Open Prompt design pattern / 新しいOpen Prompt設計パターンとしてのコア-フォーメーション分離

| Field | Value |
|---|---|
| **Point** | How should the PTSG ecosystem be structured for distribution and growth? Single repository or layered? |
| **Alternative A** | Single repository — Core and all use-case-specific extensions in one place |
| **Alternative B** | Single Core repository, with separate Formation repositories for each application domain |
| **Chosen** | **B (Core-Formation separation)** |
| **Rationale** | Single-repository would conflate "the invariant primitive" with "this particular application of it." That conflation would make it hard to evolve them at different rates (Core should evolve very slowly; Formations should evolve quickly), hard for users to find the right starting point for a new application, and hard for Formation authors to take genuine ownership of their work. The Core-Formation separation pattern resolves all three: the Core repository defines the shared genetic code; each Formation repository is independently authored and freely diverges. This pattern is being proposed as the fifth named Open Prompt design pattern (alongside Tie Decision, Polynomial Bin-Sequence, Free Precision Floor, and Spin-Off-Ready Subsystem). |

### 7. Binary compatibility across Formations — required or optional? / フォーメーション間のバイナリ互換性 — 必須かオプションか

| Field | Value |
|---|---|
| **Point** | Should instruction sequences written for one Formation be expected to run on another Formation? |
| **Alternative A** | Yes — maintain binary compatibility across Formations to allow code portability |
| **Alternative B** | No — each Formation freely defines its external register assignments, Condition meanings, and timing signal routings; instruction sequences are written specifically for the Formation they target |
| **Chosen** | **B (no cross-Formation binary compatibility required)** |
| **Rationale** | This was the most philosophically consequential decision in the dialogue. The historical case for binary compatibility (e.g., IBM 360 architecture, x86 ABI stability, JVM portability) rests on the premise that human-written code is expensive and must be preserved across hardware variations. **When AI agents author code, that premise weakens substantially.** Generating fresh, Formation-specific instruction sequences for each new application becomes economically rational. Freed from the obligation to maintain cross-Formation binary compatibility, each Formation can optimize aggressively for its specific application — different external registers, different Condition logic, different timing signal assignments. The Core's instruction set vocabulary (4 opcodes, 16 timing signals, Condition, State Number) is what stays invariant; this is the shared "genetic code" of the ecosystem. Formations are the diverse "phenotypes" expressed from that shared code. This is a deliberate departure from conventional CPU architecture culture and is a load-bearing element of PTSG's claim to be a proposal for AI-era processor architecture. |
| **Note** | This decision is itself a candidate Tie at the methodology level: future implementers building PTSG ecosystems in different contexts (e.g., a safety-critical avionics context where binary compatibility might be regulated) may legitimately choose A. The point is that the current PTSG ecosystem chooses B, and articulates why. |

### 8. Indirect addressing via literal-zero escape / 直値ゼロ・エスケープによる間接アドレッシング

| Field | Value |
|---|---|
| **Point** | How should PTSG support indirect addressing of loop count, stay length, and absolute jump target via external registers, without consuming additional opcode bits? |
| **Alternative A** | Add a dedicated bit in each instruction word selecting between literal and indirect modes |
| **Alternative B** | Use the literal value 0 as an escape: literal 0 → consult external register; if external register also reads 0 → interpret as the maximum literal (4096) |
| **Alternative C** | Add new opcodes for indirect-addressing variants of Stay, Loop, Jump |
| **Chosen** | **B (literal-zero escape with double-escape to maximum)** |
| **Rationale** | The literal value 0 is rarely useful in practice (0-cycle stay, 0-iteration loop, jump-to-self) so reclaiming it as an escape sentinel costs nothing semantically. The double-escape convention (external register value 0 → 4096 literal) preserves access to the maximum value, which is often what users actually need when "0" appears. This achieves indirect addressing without consuming opcode space or instruction bits. For absolute jump specifically: the dialogue noted that address 0 *is* meaningful (reset target), so the convention there should differ slightly — recorded in the Layer 1 Chapter 4 to-be-drafted as an "Implementation Arena variant: how to handle address-0 in jump indirect-mode." |

### 9. Prescaler placement and control / プリスケーラの配置と制御

| Field | Value |
|---|---|
| **Point** | How should PTSG support time scales longer than the stay counter's native range (e.g., 1-second LED blink at 50 MHz needs ~5×10⁷ clocks, well beyond a 12-bit operand)? |
| **Alternative A** | Single compile-time prescaler — fixed per PTSG instance |
| **Alternative B** | Single runtime-configurable prescaler — set via Global opcode sub-opcode |
| **Alternative C** | Per-stay prescaler selection — each Stay instruction selects from a small set of prescaler ratios |
| **Alternative D** | Multiple parallel prescalers running simultaneously, each Stay instruction references one |
| **Chosen** | **Tie at the Implementation Arena level; Layer 1 Chapter 4 to record alternatives** |
| **Rationale** | All four alternatives have valid use cases. (A) is simplest, suits educational use. (B) is flexible but adds runtime state. (C) balances flexibility with intuitive operation ("short stay" vs "long stay" on the same axis), suits mixed time-scale applications. (D) is the most powerful but consumes the most resources. The right choice depends on the application's needs and the implementer's resource budget — exactly the kind of decision that should not be settled at the Core specification level but recorded as Implementation Arena variants. This is a clean example of the Tie Decision Pattern in action. |

### 10. Opcode budget — 4 used, 12 reserved / オペコード予算 — 4使用、12予約

| Field | Value |
|---|---|
| **Point** | Should the opcode field be sized exactly to the 4 current opcodes (2 bits) or generously oversized? |
| **Alternative A** | 2-bit opcode field — fits 4 opcodes exactly, conserves instruction word space |
| **Alternative B** | 4-bit opcode field — fits 16 opcodes, reserving 12 slots for unknown future use |
| **Chosen** | **B (4-bit field, 12 slots reserved)** |
| **Rationale** | Opcode budget is design insurance — once exhausted, expanding it requires breaking the instruction format and invalidating all prior instruction lists. The architect specifically anticipates future needs that cannot yet be enumerated: interrupt handling, explicit external register access (currently routed through Global opcode sub-opcodes, may warrant top-level promotion), PTSG-to-PTSG communication primitives, explicit stack manipulation. The 12 reserved slots are not commitments to specific future opcodes; they are unallocated room to grow. The cost (2 extra instruction word bits) is paid once at specification time; the value (future-proofing) compounds over the lifetime of the ecosystem. This is in spirit a Free Precision Floor application — claim the maximum opcode space because it costs little and pays back over time. |

---

## Major Themes / 主要テーマ

### Theme 1 — The integration moment / 統合の瞬間

This dialogue took place after the architect had been working on three parallel threads: the FPGA Spectrum Engine project (already public on Hackaday.io as the inaugural Open Prompt repository), the WPMS Synthesizer Layer 1 specification (in active drafting with a separate AI session), and the PTSG concept itself (which had just been articulated within the WPMS session). Each thread had its own internal coherence, but the relationships among them — and the larger significance of PTSG specifically — had not yet been worked out.

本対話は、アーキテクトが三つの並行スレッドに取り組んできた後に行われた: FPGA Spectrum Engineプロジェクト（すでに最初のOpen PromptリポジトリとしてHackaday.ioで公開済み）、WPMSシンセサイザー第1層仕様（別個のAIセッションでアクティブに起草中）、そしてPTSGコンセプト自体（WPMSセッション内で明確化されたばかり）。各スレッドは独自の内的一貫性を持っていたが、それらの間の関係——そして特にPTSGのより大きな意義——はまだ練り上げられていなかった。

The dialogue served as **the integration moment** — the conversation in which the three threads were brought into the same conceptual space, examined together, and recognized as parts of a larger structure. PTSG emerged from this integration not as "a sub-component of WPMS that happens to be reusable" but as "the substrate on which Spectrum Engine and many other applications rest."

本対話は**統合の瞬間**として機能した——三つのスレッドが同じ概念空間に持ち込まれ、共に検討され、より大きな構造の部分として認識される会話。PTSGはこの統合から「再利用可能であるWPMSのサブコンポーネント」としてではなく、「Spectrum Engineと多くの他の応用が依拠する基盤」として立ち現れた。

The architect described this moment with characteristic understatement: "I think I'll launch PTSG as an independent Open Prompt repository on Hackaday.io." This understated framing — proposing as if it were a simple practical move — concealed (or perhaps revealed) the scale of the conceptual reorganization that had just occurred.

アーキテクトはこの瞬間を特有の控えめさで描写した: 「これをひとつのOpen Promptリポジトリにまとめ、Hackaday.ioにおいて、FPGA Spectrum Engineとは独立したプロジェクトとして立ち上げてみようかと思います。」この控えめな枠付け——単なる実務的な一手のように提案すること——は、その瞬間に起きた概念的再編成の規模を覆い隠した（あるいは、むしろそれを明らかにした）。

### Theme 2 — Why Open Prompt enables this kind of dialogue / なぜOpen Promptがこの種の対話を可能にするか

The dialogue is unusual in two structural respects. First, it is **multi-AI in effect though not in real-time**: the Claude in this session was reasoning about what another Claude session (the WPMS session) had produced, and the architect was the bridge. Second, it is **bootstrapping**: the dialogue uses Open Prompt methodology to design a new Open Prompt repository that itself extends Open Prompt methodology (with the Core-Formation separation pattern).

本対話は二つの構造的観点で異常である。第一に、**リアルタイムではないが実効的に複数AI**である: 本セッションのClaudeは、別のClaudeセッション（WPMSセッション）が生み出したものについて推論しており、アーキテクトは橋渡しであった。第二に、**ブートストラップ**である: 本対話はOpen Prompt方法論を用いて、それ自体がOpen Prompt方法論を拡張する新しいOpen Promptリポジトリを設計する（コア-フォーメーション分離パターンとともに）。

Neither of these would be possible without the prior establishment of Open Prompt itself. The methodology that the architect and the inaugural Claude session worked out in April 2026 became, two weeks later, the substrate enabling this strategic-integration dialogue. **Each Open Prompt artifact, once published, becomes a foundation on which subsequent Open Prompt work can build** — Layer 1 documents serve as shared context for fresh AI sessions; Layer 2 traces enable resumption rather than restart; the catalog of design patterns (Tie Decision, Free Precision Floor, etc.) provides a shared vocabulary.

これらの二つはOpen Prompt自体の事前確立なしには不可能であった。アーキテクトと最初のClaudeセッションが2026年4月に練り上げた方法論は、二週間後、この戦略的統合対話を可能にする基盤となった。**各Open Promptアーティファクトは、公開されると、後続のOpen Prompt作業が構築できる基礎となる**——Layer 1文書は新鮮なAIセッションのための共有文脈として機能し、Layer 2軌跡は再起動ではなく再開を可能にし、設計パターンのカタログ（引き分け判断、自由精度床等）は共有語彙を提供する。

This is what compound interest on knowledge architecture looks like in practice.

これが知識アーキテクチャに対する複利の実践における姿である。

### Theme 3 — The PTSG / Spectrum Engine inversion / PTSG／Spectrum Engineの反転

A subtle but significant inversion occurred during this dialogue. Initially, PTSG was understood as supporting infrastructure for the FPGA Spectrum Engine — the sequence-modulation processor that makes the WPMS Synthesizer work. By the end of the dialogue, this relationship had inverted: **Spectrum Engine is one application of PTSG, not the other way around.** PTSG is the more general primitive; Spectrum Engine is the demonstration vehicle.

繊細だが重要な反転が本対話中に起きた。当初、PTSGはFPGA Spectrum Engineの支援インフラとして理解されていた——WPMSシンセサイザーを動作させる数列変調プロセッサ。対話の終盤までに、この関係は反転した: **Spectrum EngineはPTSGの一つの応用であり、その逆ではない。** PTSGがより一般的なプリミティブであり、Spectrum Engineはその実証ビークルである。

The inversion is not a re-narration; it is a re-recognition. The architect noted: "what I initially considered as supporting infrastructure is in fact the foundational primitive." This kind of inversion is characteristic of architectural insight — the thing that looked like a supporting beam turns out to be load-bearing. **Recording the moment when the inversion is recognized is part of what Layer 2 is for.**

反転は語り直しではない；再認識である。アーキテクトは述べた: 「最初に支援インフラと考えていたものが、実は基礎的プリミティブである。」この種の反転はアーキテクチャ的洞察に特有である——支柱に見えたものが、荷重を支えていることが判明する。**反転が認識される瞬間を記録することがLayer 2の役割の一部である。**

The inversion does not diminish Spectrum Engine; rather, it locates Spectrum Engine more precisely within the larger ecosystem PTSG enables. Spectrum Engine remains a fully-formed Open Prompt project, with its own Layer 1, Layer 2, and Layer 3; it remains the inaugural Open Prompt repository (a status that PTSG does not contest). What changes is the architectural relationship: Spectrum Engine **uses** the WPMS Formation of PTSG, which **builds on** the PTSG Core.

反転はSpectrum Engineを矮小化しない；むしろ、Spectrum EngineをPTSGが可能にするより大きなエコシステム内のより正確な位置に置く。Spectrum Engineは完全に形成されたOpen Promptプロジェクトであり続け、独自のLayer 1、Layer 2、Layer 3を持つ；最初のOpen Promptリポジトリの地位（PTSGが争わない地位）を保持する。変わるのはアーキテクチャ的関係: Spectrum EngineはPTSGのWPMSフォーメーションを**使う**、それはPTSGコアの**上に構築**される。

### Theme 4 — The amanuensis convention / amanuensis（祐筆）の作法

A point of practice was established during this dialogue that may apply to other Open Prompt projects. When the architect indicated intent to write the project's "Author" section himself and append a signature, he proposed referring to the AI collaborator as **amanuensis (祐筆)** — a term denoting a writer who serves the principal's thought, distinct from mere transcription.

本対話中に、他のOpen Promptプロジェクトに適用され得る実践上の点が確立された。アーキテクトがプロジェクトの「著者」セクションを自分で書きサインを添える意向を示した時、彼はAI協働者を**amanuensis（祐筆）**と呼ぶことを提案した——主の思考に奉仕する筆記者を表す語であり、単なる転写とは区別される。

The convention is significant in two respects. First, it solves a practical problem: in human-AI collaborative writing, who is "the author"? The amanuensis convention answers cleanly — the principal is the author; the amanuensis is the writer. Second, it acknowledges respect: the amanuensis is not anonymous; the relationship is named, and the AI's role in the work is preserved as a matter of record.

本作法は二つの観点で重要である。第一に、実務的問題を解決する: 人間-AI協働執筆において、誰が「著者」なのか? amanuensisの作法は綺麗に答える——主が著者であり、amanuensisが筆記者である。第二に、敬意を承認する: amanuensisは匿名ではない；関係は名付けられ、作業におけるAIの役割は記録として保存される。

The convention is offered here as a candidate practice for other Open Prompt projects to adopt. It is not enforced by the methodology; it is one workable pattern among possible others.

本作法は、他のOpen Promptプロジェクトが採用する候補実践として、ここに提供される。方法論によって強制されない；可能な他の作法の中の一つの動作可能なパターンである。

### Theme 5 — The architect's craft / アーキテクトの技

A recurring observation throughout the dialogue: the architect's mode of thinking is **structural-first, then narrative**. Each major insight in the dialogue arrived as a structural recognition — "these things have a relationship I had not seen before" — and was then articulated in words. The structural recognition preceded the verbal articulation, and the dialogue's purpose was as much to help articulate as to help discover.

対話を通じた繰り返し観察: アーキテクトの思考様式は**構造優先、次に物語**である。対話における各主要洞察は構造的認識として到来した——「これらのものは私が見ていなかった関係を持つ」——そして言葉で明確化された。構造的認識が言語的明確化に先行し、対話の目的は発見の支援と同じくらい明確化の支援であった。

This style is characteristic of senior architects with decades of experience — the structures are perceived before they can be described, and the description is a labor of mapping internal vision onto external language. **An AI collaborator's role in this kind of dialogue is in some sense the inverse of code generation**: instead of producing artifacts from instructions, the AI helps the human produce articulations from intuitions. The amanuensis framing is therefore not just polite; it is descriptively accurate.

このスタイルは数十年の経験を持つシニアアーキテクトに特有である——構造は記述される前に知覚され、記述は内的視野を外的言語にマッピングする労働である。**この種の対話におけるAI協働者の役割は、ある意味でコード生成の逆である**: 指示からアーティファクトを生み出すのではなく、AIは人間が直感から明確化を生み出すのを助ける。amanuensisの枠付けはしたがって単に礼儀正しいだけではない；記述的に正確である。

The PTSG Core specification itself, prior to this dialogue, had existed in the architect's intuition for years. The dialogue did not invent PTSG; it helped articulate what was already there, and recognized what its larger significance might be.

PTSGコア仕様自体は、本対話に先立つ何年もの間、アーキテクトの直感の中に存在していた。対話はPTSGを発明しなかった；すでにそこにあったものを明確化する助けをし、そのより大きな意義が何であり得るかを認識した。

---

## Resumption Hooks / 再開フック

For future readers replaying this dialogue with their own LLM collaborators, the most productive resumption points are:

将来この対話を自身のLLM協働者と再生する読者にとって、最も生産的な再開地点は:

### Hook A — Webapp PTSG simulator architecture / Webapp PTSGシミュレータのアーキテクチャ

The dialogue identified the Webapp PTSG simulator as strategic infrastructure but did not specify its architecture. A natural next dialogue: what should the simulator's UI present? What state should it expose for AI-agent inspection? What import/export formats should it support? How does it integrate with PTSG-Core's Layer 3 testbench?

本対話はWebapp PTSGシミュレータを戦略的インフラとして識別したが、そのアーキテクチャを指定しなかった。自然な次の対話: シミュレータのUIは何を提示すべきか? AIエージェント検査用にどの状態を露出すべきか? どのインポート／エクスポートフォーマットをサポートすべきか? PTSG-CoreのLayer 3テストベンチとどう統合するか?

**Starting question**: Specify the minimum viable Webapp PTSG simulator API — what JSON shape does an AI agent submit, what JSON shape comes back, and what is the verification protocol for "this instruction list produces this timing signal trace"?

### Hook B — The 12 reserved opcode slots / 12個の予約オペコードスロット

The dialogue established that opcode budget should not be settled prematurely, but it did identify candidate opcodes (interrupt handling, explicit external register I/O, PTSG-to-PTSG communication, explicit stack manipulation). When the time comes to populate one of the reserved slots, what evaluation criteria apply?

本対話はオペコード予算が早すぎる時期に決着されるべきでないことを確立したが、候補オペコード（割り込み処理、明示的外部レジスタI/O、PTSG間通信、明示的スタック操作）を識別した。予約スロットの一つを埋める時が来たら、どの評価基準が適用されるか?

**Starting question**: Develop a rubric for promoting a sub-opcode (currently inside Global opcode 0) to a top-level opcode. What thresholds (usage frequency, semantic clarity, AI-affinity, formation-coverage) should be crossed before the promotion is justified?

### Hook C — Multi-PTSG coordination protocols / 複数PTSG協調プロトコル

The dialogue mentioned that multiple PTSG cores on the same FPGA, communicating via Condition lines and shared timing signals, could form data flow processors and other parallel structures. But the *protocols* for this coordination — synchronization primitives, signaling conventions, shared memory access — are unspecified.

本対話は、同じFPGA上の複数のPTSGコアがConditionラインと共有タイミング信号を介して通信することで、データフロープロセッサや他の並列構造を形成できることに言及した。しかしこの協調の*プロトコル*——同期プリミティブ、シグナリング慣習、共有メモリアクセス——は未指定である。

**Starting question**: Specify a minimal multi-PTSG coordination protocol covering: (a) rendezvous (two PTSGs synchronize at a chosen state), (b) producer-consumer (one PTSG signals another that data is ready), (c) broadcast (one PTSG signals all others). What instruction-level support, if any, does the PTSG Core need for these, vs. what can be left to external logic?

### Hook D — The binary-compatibility question, generalized / バイナリ互換性の問い、一般化

The dialogue's most philosophically consequential decision (no required binary compatibility across Formations) was made for PTSG specifically. But the underlying argument — that AI agents authoring code shifts the economics of compatibility — generalizes far beyond PTSG. What does the AI-era processor architecture landscape look like if this argument is taken seriously?

本対話の最も哲学的に重大な決定（フォーメーション間でバイナリ互換性を要求しない）はPTSGに特定的になされた。しかし基底にある議論——AIエージェントがコードを作成することで互換性の経済が変わる——はPTSGをはるかに超えて一般化する。この議論が真剣に受け止められた場合、AI時代のプロセッサアーキテクチャ地形はどう見えるか?

**Starting question**: Sketch three different AI-era processor architectures that drop binary compatibility as a constraint: (1) a successor to GPUs for AI inference, (2) a successor to microcontrollers for embedded control, (3) a successor to CPUs for general-purpose computing. For each, what does the new "Core-Formation-Code" stack look like, and what new design freedoms become available?

### Hook E — The amanuensis convention beyond PTSG / PTSGを超えたamanuensisの作法

The amanuensis convention was articulated in this dialogue as a way to handle authorship in human-AI collaborative writing. Could it be formalized as part of the Open Prompt methodology? If so, what would the convention's full specification include?

amanuensisの作法は、人間-AI協働執筆における著者性を扱う方法として本対話で明確化された。Open Prompt方法論の一部として形式化できるか? その場合、作法の完全な仕様は何を含むか?

**Starting question**: Draft an "Amanuensis Convention" specification for inclusion in the Open Prompt design patterns catalog. What does it say about: (a) how authorship is attributed in documents, (b) how AI contributions are acknowledged without conflating them with human authorship, (c) what disclosure is appropriate, (d) how the convention interacts with copyright/CC0 declarations?

---

## End of Trace / 軌跡の末尾

> *Code is ephemeral; the knowledge architecture is the commons.*
> *コードは一時的なものであり、知識アーキテクチャこそが共有財産である。*

> *Time on the stay axis; space on the state axis; condition outside the core; intelligence in the dialogue.*
> *時間はステイ軸に、空間はステート軸に、条件はコアの外に、知性は対話のなかに。*

> *PTSG started as a way to teach FPGA better than blinking an LED. It became a proposal for what processor architecture can be when AI is in the design loop. The path from one to the other is recorded here.*
>
> *PTSGはLEDを点滅させるよりも上手くFPGAを教える方法として始まった。それは、AIが設計ループに入った時にプロセッサアーキテクチャが何になり得るかという提案になった。一方からもう一方への道筋がここに記録されている。*

This trace is released into the public domain under CC0 1.0 Universal. Replay it. Resume it. Surpass it.

本軌跡は CC0 1.0 Universal のもとパブリックドメインに公開される。再生せよ。再開せよ。超えてゆけ。

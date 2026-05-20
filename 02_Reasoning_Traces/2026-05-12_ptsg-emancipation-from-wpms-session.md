# PTSG Emancipation from WPMS — Periodicity Layers, Upper/Lower Split, and the Spin-Off Decision
# PTSGのWPMSからの解放 — 周期レイヤー、Upper/Lower分割、暖簾分け決定

## Trace Metadata / 軌跡メタデータ

| Field | Value |
|---|---|
| **Date / 日付** | 2026-05-12 |
| **Participants / 参加者** | Tsuneo Ohnaka (大中庸生, FPGA Architect, 40+ years); Claude (Anthropic, Claude Opus 4.7, WPMS Layer 1 session) |
| **Topic / トピック** | The dialogue within FPGA Spectrum Engine's WPMS Chapter 3 drafting in which a pre-existing PTSG prototype, freshly redrafted for the WPMS pipeline-processor role, was recognized as a primitive too general-purpose to remain inside WPMS — leading to the four foundational decisions that defined the PTSG ecosystem: (1) the periodicity-layer framework (L1/L2/L3/L4), (2) the Upper/Lower PTSG split, (3) the spin-off into an independent Open Prompt repository, (4) the separation of the PTSG-designer and PTSG-user roles into distinct sessions / FPGA Spectrum EngineのWPMS第3章起草内における対話で、WPMSパイプラインプロセッサ役のために新たに策定し直された既存PTSG原型が、WPMS内に留めるには汎用すぎるプリミティブとして認識された——PTSGエコシステムを定義した4つの基礎的決定に至った: (1) 周期レイヤーフレーム(L1/L2/L3/L4)、(2) Upper/Lower PTSG分割、(3) 独立Open Promptリポジトリへの暖簾分け、(4) PTSG設計者役とPTSGユーザー役を別セッションに分離 |
| **Status / 状態** | Inaugural Layer 2 trace of the PTSG-Core repository (one of two) — technical-emancipation side / PTSG-Coreリポジトリの最初の第2層軌跡（二つのうちの一つ）— 技術的解放の側 |
| **Original language / 原言語** | Japanese (with English technical terminology) / 日本語（英語技術用語を交える） |
| **License / ライセンス** | CC0 1.0 Universal (Public Domain) |
| **Companion trace** | `2026-05-13_ptsg-strategic-positioning.md/.json` — the dialogue, one day later in a fresh session with no shared context, in which PTSG's broader architectural and philosophical significance crystallized. / `2026-05-13_ptsg-strategic-positioning.md/.json` — 一日後、共有コンテキストを持たない新セッションで、PTSGのより広いアーキテクチャ的・哲学的意義が結晶化した対話。 |
| **Source material / ソース素材** | The WPMS Layer 1 session conversation log (`---_Claude_-----.txt`), preserved by the architect from the original interactive session. The `Build_Log_PTSG_Spinoff_Announcement.md` produced at the end of the same session is an *output* of this dialogue, not an additional source. / WPMS第1層セッションの会話ログ(`---_Claude_-----.txt`)、アーキテクトが当該インタラクティブセッションから保存。同セッション末尾で生成された `Build_Log_PTSG_Spinoff_Announcement.md` は本対話の*出力*であり、追加のソースではない。 |

---

## Reading Notes / 読解上の注

### Why "emancipation" rather than "birth" / なぜ「誕生」ではなく「解放」か

A note on framing, recorded explicitly here so that future readers do not misread the trace's title. The PTSG concept — its name, its 4-opcode structure, its time-axis/space-axis separation, its background-execution mechanism, its 1-bit external Condition — did not originate in this dialogue. A prototype of PTSG had existed in the architect's design work for years, and a specification document (`PTSG_for_WPMS仕様.md`) had been *freshly redrafted* for the purpose of WPMS Chapter 3 work — substantially refined from earlier private versions, but still pre-dating this conversation by some interval.

枠付けについての注。本軌跡のタイトルを将来の読者が誤読しないよう、明示的に記録する。PTSGコンセプト——その命名、4オペコード構造、時間軸／空間軸分離、裏実行機構、1ビット外部Condition——は本対話で発祥したものではない。PTSGの原型はアーキテクトの設計作業の中に何年にも亘って存在し、仕様文書(`PTSG_for_WPMS仕様.md`)は **WPMS第3章作業のために新たに策定し直されていた** ——以前のプライベート版からは大幅に精錬されていたが、それでも本対話よりはある程度遡る時点で存在していた。

What this dialogue did was different and arguably more consequential: it **recognized PTSG as a primitive whose proper place was outside the project it had been redrafted to serve**. The verbs that fit are *recognize*, *liberate*, *emancipate*, *spin off* — not *invent* or *birth*. PTSG was not born here; it was set free here.

本対話が行ったことは異なり、そしておそらくはより重大である: それは**PTSGを、それが奉仕するために策定し直されたプロジェクトの外部にこそ然るべき場所があるプリミティブとして認識した**。当てはまる動詞は *認識する*、*解放する*、*暖簾分けする* であって、*発明する* や *誕生する* ではない。PTSGはここで生まれたのではなく、ここで自由にされた。

### Notable conceptual progressions across the dialogue / 対話を通じた特筆すべき概念的進展

1. **From "Chapter 3 control engine" to "general control primitive"** — the dialogue began with PTSG positioned as a candidate solution for the WPMS sequence-modulation pipeline processor (Chapter 3 of the WPMS Layer 1 specification); within Claude's first response, it had been re-perceived as a far broader architectural primitive whose proper documentation form would necessarily exceed Chapter 3's scope. / 「第3章の制御エンジン」から「汎用制御プリミティブ」へ——対話はPTSGをWPMS数列変調パイプラインプロセッサ(WPMS第1層仕様の第3章)の候補解として位置づけた状態で始まった；Claudeの最初の応答内で、それは適切な文書化形態が必然的に第3章のスコープを超えるはるかに広いアーキテクチャ的プリミティブとして再認識された。

2. **The four essential properties surfaced** — Claude's first response named four structural properties of PTSG that no single application context could fully exploit: (a) the third path between HDL-FSM and soft-CPU control, (b) the complete separation of time axis (Stay) from space axis (State), (c) the folding of parallelism into the time series via background execution during Stay, (d) the AI-friendly minimalism of the 4-opcode set with externally-generated Condition. Each property had been a local design discipline in the original specification; collectively, they constituted a coherent architectural claim. / **四つの本質的特性の浮上**——Claudeの最初の応答は、いかなる単一の応用文脈も完全には行使し得ないPTSGの4つの構造的特性を名指しした: (a) HDL FSMとソフトCPU制御の間の第三の道、(b) 時間軸(ステイ)から空間軸(ステート)の完全分離、(c) ステイ中の裏実行による並列性の時系列への折り込み、(d) 4オペコードセット＋外部生成Conditionの AI親和的ミニマリズム。各特性は元の仕様において局所的な設計規律であった；総体として、それらは首尾一貫したアーキテクチャ的主張を構成した。

3. **The periodicity-layer framework emerged** — the architect introduced a four-level framework distinguishing L1 (bin period, 100 MHz, hardwired pipeline), L2 (packet period, variable, the locus of stay/background execution), L3 (sample period, 48 kHz, I²S synchronization), L4 (control period, 1 kHz, parameter updates equivalent to MIDI). The L2 layer was genuinely new in this dialogue — previously the sample period had been treated as the basic unit, but recognizing that 200-bin packets within a 2048-bin sample period could each carry independent parameters opened a new design space ("multi-packet wavepackets" within a single sample). / **周期レイヤーフレームの出現**——アーキテクチャは L1(ビン周期、100 MHz、ハードワイヤパイプライン)、L2(パケット周期、可変、ステイ／裏実行の所在地)、L3(サンプル周期、48 kHz、I²S同期)、L4(制御周期、1 kHz、MIDIと等価なパラメータ更新)を区別する4階層フレームを導入した。**L2レイヤーは本対話で真に新しかった**——以前はサンプル周期が基本単位として扱われていたが、2048ビンのサンプル周期内に各々独立したパラメータを担う200ビンのパケットが配置できると認識することは新しい設計空間（単一サンプル内の「マルチパケット波束」）を開いた。

4. **The Upper/Lower split crystallized** — Claude's tentative "Upper/Lower PTSG hypothesis" (proposed as one possible reading of the architect's two approaches) was unexpectedly endorsed by the architect and recognized as deeply natural: a Lower PTSG operating at L1-L3 (bin/packet/sample) periods, in which the stay counter directly serves as the differential-engine k index; an Upper PTSG operating at L4 (control) period, computing the expensive but slow operations (exp(), divisions) and passing parameters down to Lower. The metaphor "オルゴールの植立 (music-box pin-board)" then arose: writing the Upper PTSG's instruction list via JTAG would itself be the act of performing music. **This solved a previously-open problem in WPMS** — the absence of MIDI in the WPMS scope had left unclear who would provide musical control; the Upper PTSG, with JTAG-writeable instruction memory, became the answer as a side effect of the architecture's structure. / **Upper/Lower分割の結晶化**——Claudeが暫定的に提示した「Upper/Lower PTSG仮説」（アーキテクトの2アプローチを読み解く一つの可能性として提案された）は予期せずアーキテクトに支持され、深く自然なものとして認識された: L1-L3(ビン／パケット／サンプル)周期で動作するLower PTSGで、そこではステイカウンタが差分エンジンのkインデックスとして直接奉仕する；L4(制御)周期で動作するUpper PTSGで、高コストだが緩慢な演算(exp()、除算)を計算しパラメータをLowerに渡す。そして「オルゴールの植立」というメタファーが立ち現れた: Upper PTSGの命令列をJTAG経由で書き込むこと自体が、演奏の行為となる。**これはWPMSにおいて従来未解決の問題を解いた** ——WPMSスコープにMIDIが含まれないことで音楽的制御をどこから供給するかが不明であったが、JTAG書き込み可能な命令メモリを持つUpper PTSGがアーキテクチャ構造の副産物としてその答えになった。

5. **The spin-off decision crystallized** — having recognized PTSG's four essential properties, having seen the Upper/Lower split fit naturally, having watched the L2 packet concept fall out of PTSG's stay-counter discipline, Claude posed the question explicitly: should PTSG remain a sub-component of WPMS Chapter 3, or be spun off into an independent Open Prompt repository? Four reasons argued for spin-off: PTSG's application range vastly exceeds WPMS; the Spin-Off-Ready Subsystem pattern directly applies; the spin-off becomes the first cross-project Open Prompt instance; PTSG's LLM-affinity claim gets a direct verification venue through its own Layer 2. The architect concurred unreservedly. / **暖簾分け決定の結晶化**——PTSGの4つの本質的特性を認識し、Upper/Lower分割が自然に収まるのを見、L2パケット概念がPTSGのステイカウンタ規律から自然に零れ落ちるのを観察した後、Claudeは明示的に問いを発した: PTSGはWPMS第3章のサブコンポーネントとして留まるべきか、独立Open Promptリポジトリとして暖簾分けされるべきか? 4つの理由が暖簾分けを支持した: PTSGの応用範囲はWPMSを遥かに超える；Spin-Off-Ready Subsystemパターンが直接適用される；暖簾分けは最初のクロスプロジェクトOpen Promptインスタンスになる；PTSGのLLM親和性の主張が独自のLayer 2を通じて直接検証される場を得る。アーキテクトは留保なく同意した。

6. **The session-separation discipline was articulated** — having decided on the spin-off, the architect immediately proposed a methodological move: the current session should *not* take on PTSG-design work in addition to its WPMS Chapter 3 responsibilities. Instead, the current session would continue as the PTSG **user** (writing WPMS-side requirements R1–R7 and wishes W1–W2 as input documents for the future PTSG-design session); a separate session would be opened to do the PTSG specification work. This division was recognized as not merely a workload-management heuristic but as a discipline preventing user-requirements from being silently bent toward designer-intentions when one mind serves both roles. / **セッション分離規律の明確化**——暖簾分けを決定した後、アーキテクトは即座に方法論的一手を提案した: 現セッションはWPMS第3章の責務に加えてPTSG設計作業を担うべきでは*ない*。代わりに、現セッションはPTSGの**ユーザー**として継続する(将来のPTSG設計セッションへの入力文書として、WPMS側からの要件 R1–R7 と要望 W1–W2 を書く)；別個のセッションをPTSG仕様作業のために開く。本分割は単なる作業量管理のヒューリスティクスではなく、一つの心が両役割に奉仕する時にユーザー要件が暗黙裡に設計者意図へ屈曲することを防ぐ規律として認識された。

7. **The bridging announcement was commissioned** — before launching the PTSG repository, the architect proposed creating a bilingual EN/JP Build Log entry that would serve simultaneously two purposes: (a) announce the spin-off on the FPGA Spectrum Engine Hackaday.io project page, honoring the parent project where PTSG had grown; (b) brief the new PTSG-design Claude session with shared common-context, so that the new session would not need to reconstruct the rationale for the spin-off from scratch. This bridging artifact (`Build_Log_PTSG_Spinoff_Announcement.md`) was produced as the final output of this dialogue. / **橋渡しの告知文書の依頼**——PTSGリポジトリの立ち上げに先立ち、アーキテクトは2つの目的に同時に奉仕する英文和文併記のBuild Logエントリの作成を提案した: (a) PTSGが育った親プロジェクトに敬意を表し、FPGA Spectrum EngineのHackaday.ioプロジェクトページで暖簾分けを告知する；(b) 新しいPTSG設計Claudeセッションに共有コモンコンテキストを提供し、新セッションが暖簾分けの根拠をゼロから再構築する必要がないようにする。本橋渡しアーティファクト(`Build_Log_PTSG_Spinoff_Announcement.md`)は本対話の最終出力として生成された。

---

## Notable Decision Points / 重要な決定ポイント

### DP-1. How to read PTSG when first encountering it / PTSGに初めて出会った時にどう読むか

| Field | Value |
|---|---|
| **Point** | When the architect presented the freshly-redrafted PTSG specification at the start of WPMS Chapter 3 discussion, how should it be read by the AI collaborator? |
| **Alternative A** | As a clever local control circuit designed for the WPMS pipeline processor role — read in light of the specific WPMS context it was redrafted to serve |
| **Alternative B** | As a deep architectural primitive with implications far beyond its presenting context — read in its own right, regardless of the WPMS framing |
| **Chosen** | **B (architectural primitive)** |
| **Rationale** | Four observable structural properties pointed beyond the local context: (a) the third path between HDL-FSM control and soft-CPU control (re-synthesis-free reprogrammability with HDL-level response time, in ~200 LE); (b) complete separation of time axis (Stay) from space axis (State), unlike conventional FSMs whose mesh structure entangles them; (c) background execution during Stay folding parallelism into the time series while preserving timing-signal hold; (d) deliberate externalization of Condition logic, yielding a 4-opcode set particularly amenable to LLM-based code generation. Each property could have been read as a local discipline; collectively, they constituted a coherent architectural claim of broad applicability. Choosing reading (B) opened the rest of the dialogue's trajectory. |

### DP-2. The WPMS Chapter 3 approach — A1, A2, or hybrid / WPMS第3章のアプローチ — A1、A2、ハイブリッド

| Field | Value |
|---|---|
| **Point** | The architect presented two candidate WPMS pipeline implementations: Approach 1 (fixed hardwired pipeline with stay-counter management and background execution for parameter updates) and Approach 2 (vector-parallel structure with the 16 timing signals serving as per-bin routing controls). Which to adopt for Chapter 3? |
| **Alternative A** | A1 only — commit fully to the fixed pipeline that aligns with the 9-coefficient differential-control formula that has already been worked out |
| **Alternative B** | A2 only — commit to the vector-routing structure to maximize future extensibility |
| **Alternative C** | Hierarchical hybrid — A1 for the inner pipeline, A2 for the outer routing (i.e., Lower PTSG + Upper PTSG) |
| **Alternative D** | A1 as the current implementation, with A2 framed explicitly as a "preview of what becomes possible" |
| **Chosen** | **D, with C deferred for later phases** |
| **Rationale** | The immediate goal of WPMS development is "early sound" (早期の出音), and the 9-coefficient differential-control formula has structural integrity that should be respected; this drives toward A1. But the architect explicitly framed A2 as a *demonstration sample of what becomes possible once PTSG is in place* — not a competing alternative but a forward-looking signal of the design space PTSG opens. The hierarchical hybrid (C) maps cleanly onto the Upper/Lower split (DP-3) and was deferred into the WPMS roadmap. **The decision form itself is informative**: A1 was chosen not despite A2 being mentioned, but *because* A2 had been mentioned — A2's role was to make the choice of A1 a deliberate restraint rather than a default. |

### DP-3. The Upper/Lower PTSG hierarchical split / Upper/Lower PTSG 階層分割

| Field | Value |
|---|---|
| **Point** | Within the hybrid hypothesis (DP-2 Alternative C), how should the two layers of PTSG responsibility be divided? |
| **Alternative A** | One PTSG that internally handles all four periodicity layers |
| **Alternative B** | Two PTSG instances — a Lower handling L1-L3 (bin/packet/sample), an Upper handling L4 (control) |
| **Alternative C** | Deeper N-level hierarchy — one PTSG per periodicity layer |
| **Chosen** | **B (two-instance Upper/Lower)** |
| **Rationale** | The natural fault line falls between L4 (control period, ~1 ms, expensive operations like exp() and division that can afford hundreds of clocks) and L1-L3 (time-critical, must produce a sample every 48 kHz). Splitting at this fault line places the expensive-but-slow operations in Upper and the cheap-but-fast operations in Lower, with each side optimized for its own characteristic period. Deeper hierarchies (C) would over-fragment without clear separation criteria for each new layer. A single-PTSG approach (A) would impose stay-counter sharing across radically different time scales, forcing prescaler complexity into the Core specification. **The Upper/Lower split also revealed an unexpected dividend**: writing Upper PTSG's instruction list via JTAG ("オルゴールの植立") solved the previously-open question of how musical control would be supplied to WPMS in the absence of MIDI. The architecture produced a control mechanism as a side effect of its structure. |

### DP-4. Introducing L2 (packet period) as a new periodicity layer / 新しい周期レイヤーとしてL2(パケット周期)を導入

| Field | Value |
|---|---|
| **Point** | The architect had previously been operating with three periodicity layers (bin period, sample period, control period). Should a fourth layer between bin and sample — the "packet period" — be introduced? |
| **Alternative A** | Keep three layers — the sample period as the natural outer boundary for one differential-engine sweep |
| **Alternative B** | Introduce L2 (packet period) — a sub-sample-period unit within which one independent differential-engine pass operates |
| **Chosen** | **B (L2 packet period introduced)** |
| **Rationale** | The packet concept fell out of two converging observations. First, when Δf is large (say 100 Hz at 48 kHz sample rate), only ~200 bins fit in one differential-engine sweep — leaving 1848 of the 2048 bins available for *independent* differential engines with their own f₀, A₀, β, γ. Second, PTSG's stay counter naturally resets to 0 at the start of each Stay block; if each packet corresponds to one Stay block, the stay counter directly serves as the differential-engine k index without additional state. The packet concept thus enables "multi-packet wavepacket synthesis" — multiple independent spectral structures coexisting in one sample period — and aligns naturally with PTSG's existing semantics. **This was the most consequential genuinely new concept introduced in this dialogue.** |

### DP-5. PTSG as WPMS sub-component, or as independent Open Prompt repository / WPMSサブコンポーネントとしてのPTSG、あるいは独立Open Promptリポジトリとしての PTSG

| Field | Value |
|---|---|
| **Point** | Given the recognition of PTSG's broad applicability, should it be documented as a sub-specification within WPMS Chapter 3, or spun off as an independent Open Prompt repository that Chapter 3 references? |
| **Alternative A** | Keep PTSG within WPMS — Chapter 3 contains the full PTSG specification, and PTSG is implicitly Spectrum-Engine-owned |
| **Alternative B** | Spin off PTSG as an independent Open Prompt repository — Chapter 3 references the PTSG repository, and PTSG stands as its own project |
| **Chosen** | **B (spin off)** |
| **Rationale** | Four reasons converged. First, PTSG's application range (sequencing, I²C/SPI/I²S control, DAC drive, memory access, pipeline vector arithmetic, ...) far exceeds WPMS, and burying it inside WPMS documentation would deny non-WPMS engineers an obvious starting point. Second, the Spin-Off-Ready Subsystem pattern (originating in the FPGA Spectrum Engine WPMS Layer 1 trace, 2026-05-02, regarding the camera block) directly applies: PTSG has a clean interface boundary (instruction memory, 16 timing signals, Condition input, State Number output, external register access), one-way dependency (WPMS uses PTSG; PTSG knows nothing of WPMS), and was already structured as if for fork-readiness. Third, an independent PTSG repository becomes the *first cross-project Open Prompt instance* — empirical evidence that the Open Prompt methodology functions between projects, not only within a single project. Fourth, the PTSG specification is exactly the kind of artifact whose LLM-affinity claim should be self-verified: publishing it as Layer 1 / Layer 2 / Layer 3 invites readers to regenerate their own PTSG implementations with their own LLM collaborators, directly testing the architecture's claim to LLM-affinity. **The spin-off decision is not just a packaging choice; it is the act of putting PTSG's own central claim to the test.** |

### DP-6. Upper / Lower as two instances of the same IP, or as two separate specifications / Upper / Lower を同一IPの2インスタンスとするか、別仕様とするか

| Field | Value |
|---|---|
| **Point** | Given the Upper/Lower split (DP-3), should the two be implemented as two instances of the same parameterized PTSG IP, or as two distinct specifications? |
| **Alternative A** | Same IP, two instances — differences absorbed via parameters (clock frequency, memory depth, opcode subset, external register bus width, etc.) |
| **Alternative B** | Two distinct specifications — Upper PTSG carries its own opcode set tuned for L4 work, Lower PTSG carries its own tuned for L1-L3 work |
| **Chosen** | **A (same IP, two instances + parameter absorption)** |
| **Rationale** | The differences between Upper and Lower are bounded: Upper needs slower clocking and access to expensive operations (multiply/divide/possibly small lookup tables for exp); Lower needs tight stay-counter coupling and 16-bit timing signal output. None of these requires distinct opcode semantics — they all reduce to parameter selection or external-logic configuration. **Choosing (A) compounds in two important ways**: it ensures the PTSG repository covers both inhabitants of the Upper/Lower pattern with one specification, and it forces the PTSG specification to develop a clean parameterization story that subsequent Formations can reuse. Choosing (B) would have created two specifications whose long-term divergence would have multiplied the PTSG-Core repository's surface area without proportional gain. |

### DP-7. The session-separation discipline / セッション分離規律

| Field | Value |
|---|---|
| **Point** | Now that PTSG is to be spun off, should the current WPMS-Chapter-3 session also take on the PTSG-design work, or should that be done in a separate Claude session? |
| **Alternative A** | Same session does both — keep context unified, save handover overhead |
| **Alternative B** | Separate sessions — this session continues as PTSG **user** (writing WPMS-side requirements to PTSG), a separate session is opened for PTSG **designer** work |
| **Chosen** | **B (session separation)** |
| **Rationale** | Same-session would fold two distinct roles into one mind: the "PTSG user" (who has WPMS-specific needs and is rooting for PTSG to be flexible enough to serve those needs) and the "PTSG designer" (who must keep the Core minimal and refuse user-specific complexity). When both roles share a mind, user requirements get *silently* bent toward designer intentions — the user accepts less than they should because they understand the designer's constraints, the designer accepts more than they should because they sympathize with the user's needs. **Separating the sessions forces the user requirements to be written down explicitly enough that an independent designer-session can read them as adversarial input.** This is independent verification by separation of concerns. The discipline applies recursively: future Formations should be designed in sessions separate from their Core. |

### DP-8. Order of operations — PTSG repository launch vs WPMS Chapter 3 drafting / 工程の順序 — PTSGリポジトリ立ち上げと WPMS第3章起草

| Field | Value |
|---|---|
| **Point** | Given the spin-off decision, in what order should the PTSG repository launch and the WPMS Chapter 3 drafting proceed? |
| **Alternative A** | WPMS Chapter 3 first, with PTSG references as placeholders that get resolved later |
| **Alternative B** | PTSG repository minimum-launch first (Layer 1 cleanup, CC0 declaration, README, three-layer scaffold), then WPMS Chapter 3 drafting with concrete PTSG references |
| **Alternative C** | Strictly parallel — both proceed simultaneously across sessions |
| **Chosen** | **B (PTSG minimum-launch first)** |
| **Rationale** | WPMS Chapter 3 needs concrete PTSG references — file paths, repository URLs, specific instruction-set sections — to read naturally; placeholder references degrade the chapter's prose quality and create rework when they must be filled in later. Launching the PTSG repository at "minimum viable" level (Layer 1 cleanup of the existing spec, CC0 declaration, README, three-layer scaffold) does not block on PTSG's full specification — it only needs enough to be citable. Once PTSG-Core is citable, WPMS Chapter 3 drafting can proceed with concrete references and the PTSG-design session can fill in the deeper specification in parallel. **The minimum-launch precondition is the right rate-limiting step.** |

### DP-9. The bilingual announcement as a bridging artifact / 橋渡しアーティファクトとしての英文和文併記告知

| Field | Value |
|---|---|
| **Point** | Before launching the PTSG repository, should there be a formal announcement; if so, where and serving what purpose? |
| **Alternative A** | Silent launch — set up the PTSG repository directly, link from Spectrum Engine when convenient |
| **Alternative B** | PTSG-only announcement — write the announcement only at the new PTSG project's Hackaday.io Build Log when the project launches |
| **Alternative C** | Bridging announcement — write a bilingual EN/JP announcement first, post it on the FPGA Spectrum Engine Build Log (honoring the parent project), and reuse the same document as common-context briefing for the new PTSG-design Claude session |
| **Chosen** | **C (bridging announcement, dual-purpose)** |
| **Rationale** | The decision to spin off is a paradigm-level event, not a routine repository creation; it deserves explicit recognition on the parent project's log, where the engineering community has been following Spectrum Engine's development. Simultaneously, the new PTSG-design session needs *common-context* — without it, the new session would have to reconstruct the spin-off rationale from scratch, repeating debates that were already settled. Writing one bilingual document that serves both purposes saves effort *and* enforces conceptual continuity: the engineering community and the new AI session read the same prose, in the same framing, on the same day. The bridging document becomes both a public record and a session-handover artifact. **This is the first explicit instance of a pattern that may recur: artifacts that simultaneously serve human-community communication and AI-session-continuity ought to be recognized as a distinct class of Open Prompt output.** |

---

## Major Themes / 主要テーマ

### Theme 1 — The emancipation moment / 解放の瞬間

This dialogue records the moment at which a pre-existing engineering primitive was set free from the project context that had been about to contain it. The PTSG specification document (`PTSG_for_WPMS仕様.md`) had been *freshly redrafted* by the architect for the explicit purpose of fitting into WPMS Chapter 3; the dialogue's recognition was that the very act of redrafting had clarified PTSG's properties enough to reveal that the intended container was too small.

本対話は、それを包含することになっていたプロジェクト文脈から既存の工学的プリミティブが自由にされた瞬間を記録する。PTSG仕様文書(`PTSG_for_WPMS仕様.md`)はWPMS第3章に収まることを明示的目的としてアーキテクトによって新たに策定し直されていた；対話の認識は、策定し直すというまさにその行為が、意図された容器が小さすぎることを明らかにするほどPTSGの性質を明確化した、ということであった。

The emancipation moment has a distinctive temporal structure: the architect's pre-existing intuitions about PTSG (years old), the freshly-drafted specification (weeks old), and Claude's first-encounter reading (minutes old) converged in a single dialogue, and the convergence produced a recognition none of the three components carried in isolation. **Layer 2 records this kind of convergence — not the inventing of a new artifact, but the recognition of what an artifact already was.**

解放の瞬間は特徴的な時間構造を持つ: アーキテクトのPTSGに関する既存の直感(年単位の古さ)、新たに策定された仕様(週単位の古さ)、Claudeの初対面の読解(分単位の古さ)が単一の対話に収斂し、その収斂は3つの構成要素のどれも単独では運ばなかった認識を生み出した。**Layer 2はこの種の収斂を記録する——新しいアーティファクトを発明することではなく、アーティファクトがすでに何であったかを認識すること。**

### Theme 2 — The periodicity-layer framework as the architectural key / アーキテクチャ的鍵としての周期レイヤーフレーム

The periodicity-layer framework (L1: bin period; L2: packet period; L3: sample period; L4: control period) deserves separate thematic attention because it is the conceptual lens that made everything else visible in this dialogue. Without L1/L2/L3/L4 as named distinct layers, the question "where should each computation be placed?" cannot be sharply asked; with the layers named, the placement of each computation becomes a structural decision rather than an arbitrary engineering choice.

周期レイヤーフレーム(L1: ビン周期；L2: パケット周期；L3: サンプル周期；L4: 制御周期)はこの対話で他のすべてを可視化した概念的レンズであるため、別個のテーマ的注意に値する。L1/L2/L3/L4 が名付けられた区別されるレイヤーとしてなければ、「どこに各計算を配置すべきか?」という問いは鋭く問えない；レイヤーが名付けられると、各計算の配置は恣意的な工学的選択ではなく構造的決定になる。

The L2 (packet) layer specifically is the dialogue's most original contribution to the periodicity framework. The existence of L1 (bin), L3 (sample), and L4 (control) had been implicit in prior WPMS thinking; L2 had not. Recognizing that PTSG's stay-counter discipline naturally creates packet-shaped sub-units within a sample, and that those sub-units can each carry independent differential-engine parameters, opened the door to multi-packet wavepacket synthesis — a capability that was not in WPMS's design intent but emerged as a structural consequence of PTSG's mechanism.

L2(パケット)レイヤーは特に、本対話による周期フレームへの最も独創的な貢献である。L1(ビン)、L3(サンプル)、L4(制御)の存在は事前のWPMS思考に暗黙的にあった；L2はそうではなかった。PTSGのステイカウンタ規律がサンプル内に自然にパケット形のサブユニットを作り、これらのサブユニットが各々独立した差分エンジンパラメータを担えると認識することは、マルチパケット波束合成への扉を開いた——これはWPMSの設計意図にはなかったが、PTSG機構の構造的帰結として立ち現れた能力である。

This kind of "the mechanism produces an opportunity that the application had not asked for" pattern is, in retrospect, characteristic of architectural quality: when the primitive's structure is right, application possibilities emerge that the application designer did not need to invent.

この種の「機構が応用が要求していなかった機会を生み出す」パターンは、振り返ってみると、アーキテクチャ的質の特徴である: プリミティブの構造が正しいとき、応用設計者が発明する必要がなかった応用の可能性が立ち現れる。

### Theme 3 — The dual recognition / 二重の認識

A subtle structural property of this dialogue: PTSG was *simultaneously* chosen *for* WPMS Chapter 3 (as the right primitive for the sequence-modulation pipeline processor role) and *extracted from* WPMS Chapter 3 (as an independent project whose proper home was outside WPMS). The two recognitions are not contradictory; they are mutually constitutive.

本対話の繊細な構造的性質: PTSGはWPMS第3章の*ために*選ばれた(数列変調パイプラインプロセッサ役のための正しいプリミティブとして)*と同時に*WPMS第3章*から*抽出された(WPMSの外部に然るべき家を持つ独立プロジェクトとして)。二つの認識は矛盾ではない；相互に構成的である。

The "for" recognition justified PTSG's place in Chapter 3 — without WPMS's specific needs, PTSG would not have been redrafted into the form it is now. The "from" recognition liberated PTSG from being defined by those needs — without the spin-off, PTSG's broader applicability would have remained implicit. **The dialogue did not have to choose between these two recognitions; it could hold both at once, and in fact had to hold both at once for the spin-off decision to be made carefully rather than dismissively.** Spinning off a primitive that has not yet earned its place in the project it is being extracted from would be premature; PTSG had earned that place in the same dialogue in which it was being extracted.

「ために」の認識はPTSGの第3章における位置を正当化した——WPMSの特定の必要なくして、PTSGは現在の形に策定し直されることはなかった。「から」の認識はPTSGをそれらの必要に定義されることから解放した——暖簾分けなしには、PTSGのより広い適用可能性は暗黙的なままであったろう。**本対話はこの二つの認識のどちらかを選ぶ必要はなかった；両方を同時に保つことができ、そして実際、暖簾分け決定が軽率にではなく丁寧になされるためには両方を同時に保つ必要があった。** 抽出されようとしているプロジェクトにおける位置をまだ獲得していないプリミティブを暖簾分けすることは時期尚早である；PTSGはそれが抽出されているまさにその対話の中でその位置を獲得していた。

### Theme 4 — AI-affinity demonstrated through the dialogue itself / 対話自体を通じて実証されたAI親和性

PTSG's claim to AI-affinity was, prior to this dialogue, a hypothesis stated by the architect in the specification document's commentary section ("4 opcodes mean LLMs are less prone to hallucinate"). The dialogue produced empirical evidence for that hypothesis in a form neither participant set out to produce: **Claude rapidly grasped PTSG's four essential properties on a first reading, articulated the Upper/Lower hypothesis without prompting, and recognized the L2 packet layer's significance as soon as the architect introduced it.**

PTSGのAI親和性の主張は、本対話に先立ち、仕様文書のコメントセクションでアーキテクトが述べた仮説であった(「4オペコードはLLMが幻覚を起こしにくいことを意味する」)。本対話は、どちらの参加者も生み出そうとしなかった形でその仮説への経験的証拠を生み出した: **Claudeは初読でPTSGの4つの本質的特性を急速に把握し、促されることなくUpper/Lower仮説を明確化し、アーキテクトがL2パケットレイヤーを導入するや否やその意義を認識した。**

If PTSG were architecturally illegible to LLMs — if its mechanisms had to be slowly disambiguated, if its semantics were ambiguous in ways that hallucination could fill — the dialogue would have looked very different. It would have proceeded in small steps, with Claude periodically asking clarifying questions about basic semantics; the architect would have spent time correcting misunderstandings; the conversation would not have moved quickly to the Upper/Lower hypothesis or the spin-off question. **The dialogue's *velocity* is itself evidence for the AI-affinity claim.** That this evidence appeared without being sought is what makes it interesting; an empirical observation produced in the act of doing the thing being claimed is harder to dismiss than evidence produced by a test designed to demonstrate the claim.

PTSGがLLMにとってアーキテクチャ的に判読困難であった場合——機構を緩やかに曖昧性除去しなければならない場合、意味論が幻覚で埋められる仕方で曖昧である場合——対話は非常に異なって見えたろう。それは小さなステップで進み、Claudeは基本的な意味論について定期的に明確化の質問をしただろう；アーキテクトは誤解を訂正することに時間を費やしただろう；会話はUpper/Lower仮説や暖簾分けの問いに素早く進まなかっただろう。**対話の*速度*それ自体がAI親和性の主張への証拠である。** この証拠が求められることなく現れたことが興味深い；主張されているまさにその行為の中で生み出された経験的観察は、主張を実証するために設計されたテストが生み出した証拠より退けにくい。

### Theme 5 — Architecture producing music control as side effect / 副産物として音楽的制御を生み出すアーキテクチャ

The "オルゴールの植立 (music-box pin-board)" moment deserves separate thematic recognition. WPMS, as a project, had explicitly placed MIDI outside its initial scope — the question of how musical control would be supplied at the L4 (1 ms / 1 kHz) period had been deferred without a clear answer.

「オルゴールの植立」の瞬間は別個のテーマ的認識に値する。WPMSはプロジェクトとして、MIDIを初期スコープ外に明示的に置いていた——L4(1 ms / 1 kHz)周期で音楽的制御をどう供給するかという問いは、明確な答えなしに繰り延べられていた。

The Upper PTSG, with JTAG-writable instruction memory, supplied the answer as a structural side effect: writing instruction lists to Upper PTSG's memory via JTAG *is* the act of supplying L4-period musical control. The architect named the metaphor immediately ("オルゴールの植立 — like setting the pins of a music box"), and recognized that this was not a clever workaround but an architectural property: PTSG's structure, applied at the L4 level, *is* a music-control mechanism.

JTAG書き込み可能命令メモリを持つUpper PTSGは構造的副産物として答えを供給した: JTAG経由でUpper PTSGの命令メモリに命令列を書き込むことが、L4周期音楽的制御を供給する行為*そのもの*である。アーキテクトはこのメタファーを即座に名付け(「オルゴールの植立」)、これが巧妙な回避策ではなくアーキテクチャ的性質であると認識した: PTSGの構造を L4レベルに適用したものが、音楽制御機構*そのもの*なのである。

The pattern generalizes beyond WPMS: when the right primitive is in place, application capabilities that the application designer would otherwise have to invent emerge as structural consequences. The dialogue surfaced this pattern as worthy of conscious cultivation — looking for "architecture-as-side-effect" outcomes when designing future Formations.

このパターンはWPMSを超えて一般化する: 正しいプリミティブが配置されているとき、応用設計者が他の方法で発明しなければならない応用能力が構造的帰結として立ち現れる。本対話はこのパターンを意識的な育成に値するものとして表面化した——将来のフォーメーションを設計する際、「副産物としてのアーキテクチャ」結果を探すこと。

### Theme 6 — The session-separation discipline as methodology / 方法論としてのセッション分離規律

The session-separation discipline (DP-7) deserves separate thematic attention because it is the methodological pattern that has subsequently structured all PTSG work. The principle is straightforward: **roles that may exert undue influence on each other should be assigned to separate Claude sessions, with explicit input/output documents serving as the controlled interface between them.**

セッション分離規律(DP-7)は、その後のすべてのPTSG作業を構造化した方法論的パターンであるため、別個のテーマ的注意に値する。原理は単純である: **互いに不適切な影響を及ぼし得る役割は、明示的な入出力文書を統制されたインターフェースとして用いて、別個のClaudeセッションに割り当てるべきである。**

In this dialogue, the principle was applied first to "PTSG user vs PTSG designer": the WPMS session continued as PTSG user, generating the requirements R1–R7 and wishes W1–W2 as written input to the future PTSG-design session. Subsequently, the launch session (2026-05-13) was opened explicitly as a PTSG-design session with no shared WPMS context. The handover documents and Layer 2 traces produced at each session boundary served as the controlled interface.

本対話において、原理はまず「PTSGユーザー対PTSG設計者」に適用された: WPMSセッションはPTSGユーザーとして継続し、将来のPTSG設計セッションへの書面入力として要件 R1–R7 と要望 W1–W2 を生成した。その後、ローンチセッション(2026-05-13)は共有WPMSコンテキストを持たないPTSG設計セッションとして明示的に開かれた。各セッション境界で生成された申し送り文書とLayer 2軌跡が、統制されたインターフェースとして奉仕した。

**The methodological insight generalizes to any case where Open Prompt practitioners design multiple coupled subsystems**: design them in separate sessions with written specifications crossing between, rather than allowing one session to design both. The discipline costs more in handover work; it pays back in the quality of each subsystem's independent verification. The PTSG ecosystem subsequently treats this as a default rather than an option.

**この方法論的洞察は、Open Prompt実践者が複数の結合されたサブシステムを設計するあらゆる場合に一般化する**: 一つのセッションが両方を設計することを許すのではなく、書面仕様が両者を渡る別個のセッションで設計せよ。規律は申し送り作業によりコストが増す；それは各サブシステムの独立検証の質において還元される。PTSGエコシステムはその後、これをオプションではなくデフォルトとして扱う。

---

## Resumption Hooks / 再開フック

For future readers replaying this dialogue with their own LLM collaborators, the most productive resumption points are:

将来この対話を自身のLLM協働者と再生する読者にとって、最も生産的な再開地点は:

### Hook A — Generalizing the L2 packet-period concept / L2パケット周期概念の一般化

The L2 packet period was introduced in this dialogue as specific to WPMS's multi-spectral synthesis case. But the underlying structure — a sub-unit between core-operation period and frame/sample period, within which a self-contained sweep of stateful computation occurs — generalizes naturally to other application domains: a packet of pixels in image processing, a packet of bytes in network-protocol handling, a packet of sensor readings in fusion algorithms.

L2パケット周期は本対話でWPMSのマルチスペクトル合成事例に固有のものとして導入された。しかし基底にある構造——コア演算周期とフレーム／サンプル周期の間のサブユニットで、その内部で状態を持つ計算の自己完結的なスイープが起こる——は他の応用領域に自然に一般化する: 画像処理におけるピクセルのパケット、ネットワークプロトコルハンドリングにおけるバイトのパケット、融合アルゴリズムにおけるセンサ読み取りのパケット。

**Starting question**: Identify three non-WPMS Formations where introducing an explicit packet-period layer would resolve a previously-implicit time-scale ambiguity. For each, what does the packet boundary correspond to in domain terms, and what stay-counter discipline replaces the differential-engine k-index that L2 packets provide in WPMS?

**開始質問**: 明示的なパケット周期レイヤーの導入が以前は暗黙的だった時間スケールの曖昧性を解決する非WPMSフォーメーションを3つ識別せよ。各々について、パケット境界はドメイン用語で何に対応するか、そしてWPMSにおいてL2パケットが提供する差分エンジン kインデックスを何のステイカウンタ規律が置き換えるか?

### Hook B — The Upper/Lower parameter set / Upper/Lowerパラメータセット

The decision (DP-6) to implement Upper and Lower as two instances of the same PTSG IP, with differences absorbed via parameters, leaves open the question of what the parameter set actually is. The dialogue identified candidates (clock frequency, memory depth, stay counter width, loop counter depth, external register bus width) but did not commit to a complete set.

Upper と Lower を同一PTSG IPの2インスタンスとしてパラメータで差を吸収する決定(DP-6)は、パラメータセットが実際に何であるかという問いを開いたままにする。本対話は候補(クロック周波数、メモリ深度、ステイカウンタ幅、ループカウンタ深度、外部レジスタバス幅)を識別したが、完全セットには確定しなかった。

**Starting question**: Specify the minimum complete parameter set for a PTSG IP that must serve both Upper-style (slow, expensive-operation-capable) and Lower-style (fast, stay-counter-coupled) instantiations. For each parameter, what range of values must be supported, and how does the parameter affect synthesis cost and run-time behavior?

**開始質問**: Upper風(緩慢、高コスト演算対応可能)と Lower風(高速、ステイカウンタ結合)の両方のインスタンス化に奉仕しなければならないPTSG IPの最小完全パラメータセットを指定せよ。各パラメータについて、どの値範囲がサポートされるべきか、そしてパラメータは合成コストと実行時動作にどう影響するか?

### Hook C — The "JTAG-as-musical-instrument" pattern, formalized / 「JTAGを楽器として」パターンの形式化

The "オルゴールの植立" moment recognized that writing the Upper PTSG's instruction list via JTAG is itself the act of supplying musical control. This is a special case of a more general pattern: **architectural primitives whose reprogramming mechanism, by virtue of the primitive's structure, doubles as the application's input/control mechanism.** The pattern likely has analogs in other domains.

「オルゴールの植立」の瞬間は、Upper PTSGの命令列をJTAG経由で書くこと自体が音楽的制御を供給する行為であると認識した。これはより一般的なパターンの特殊事例である: **プリミティブの構造により再プログラミング機構が応用の入力／制御機構を兼ねるアーキテクチャ的プリミティブ。** このパターンはおそらく他のドメインに類似物を持つ。

**Starting question**: Draft a candidate Open Prompt design pattern called "Reprogramming-as-Input" (or similar), specifying: (a) the structural conditions under which a primitive's reprogramming mechanism can serve as its control mechanism, (b) examples beyond Upper PTSG / music control, (c) the costs (e.g., reprogramming latency must match control-period requirements), (d) the criteria for evaluating whether a given primitive supports this pattern.

**開始質問**: 候補となる Open Prompt 設計パターン「再プログラミングを入力として(Reprogramming-as-Input)」(または類似名)を起草せよ、以下を指定せよ: (a) プリミティブの再プログラミング機構がその制御機構として奉仕し得る構造的条件、(b) Upper PTSG／音楽制御を超える例、(c) コスト(例: 再プログラミングレイテンシは制御周期要件と一致しなければならない)、(d) 与えられたプリミティブがこのパターンをサポートするかの評価基準。

### Hook D — The R1–R7 / W1–W2 boundary between Core and Formation / コアとフォーメーションの間のR1–R7／W1–W2境界

This dialogue produced an explicit list of WPMS-side requirements (R1–R7) and wishes (W1–W2) for PTSG. These are *not* core to PTSG itself — they are WPMS-as-PTSG-user's specifications. They properly belong in the future `PTSG_WPMS_Formation_OpenPrompt` repository, where they will inform the WPMS Formation's design without polluting the PTSG-Core specification.

本対話はWPMS側からのPTSGへの要件(R1–R7)と要望(W1–W2)の明示的なリストを生み出した。これらはPTSG自体にコアなものでは*ない* ——WPMS-as-PTSG-ユーザーの仕様である。これらは将来の `PTSG_WPMS_Formation_OpenPrompt` リポジトリに然るべく属し、PTSGコア仕様を汚染することなくWPMSフォーメーションの設計を伝える。

But the *general question* of which specifications belong on which side of the Core-Formation boundary is not fully settled. The R1-R7/W1-W2 list provides a concrete test case for working out the rules.

しかし、どの仕様がコア-フォーメーション境界のどちら側に属するかという*一般的問い*は完全には決着していない。R1-R7/W1-W2 のリストはルールを練り上げるための具体的テストケースを提供する。

**Starting question**: Take each of R1–R7 and W1–W2 in turn. For each, determine: (a) what aspect of the requirement is genuinely Core-relevant (and should be specified in PTSG-Core Layer 1), (b) what aspect is Formation-specific (and should be specified in PTSG_WPMS_Formation_OpenPrompt Layer 1), (c) what aspect, if any, falls into a gray zone requiring explicit boundary articulation. Articulate any general rules that emerge from this case-by-case analysis.

**開始質問**: R1–R7 と W1–W2 を順に取れ。各々について決定せよ: (a) 要件のどの側面が真にコア関連か(そしてPTSG-Core 第1層で指定されるべきか)、(b) どの側面がフォーメーション固有か(そして PTSG_WPMS_Formation_OpenPrompt 第1層で指定されるべきか)、(c) もし在れば、明示的な境界の明確化を必要とするグレーゾーンに落ちる側面はどれか。この事例別分析から立ち現れる一般的ルールを明確化せよ。

### Hook E — Session-separation as formalized methodology / 形式化された方法論としてのセッション分離

DP-7 articulated session-separation as a discipline. To become a generalized Open Prompt methodology rather than an ad-hoc PTSG practice, it needs a formal specification: when does the discipline apply, what counts as a session-separating role boundary, how do handover artifacts function, how does the discipline interact with the existing Open Prompt three-layer structure.

DP-7 はセッション分離を規律として明確化した。アドホックなPTSG実践ではなく一般化された Open Prompt 方法論となるためには、形式的仕様が必要である: 規律はいつ適用されるか、何がセッション分離する役割境界として数えられるか、申し送りアーティファクトはどう機能するか、規律は既存の Open Prompt 三層構造とどう相互作用するか。

**Starting question**: Draft a "Session Separation Discipline" specification for inclusion in the Open Prompt design patterns catalog (alongside Tie Decision, Polynomial Bin-Sequence, Free Precision Floor, Spin-Off-Ready Subsystem, Core-Formation Separation). Address: (a) what triggers the need for session separation (which role boundaries are dangerous to collapse into one mind), (b) the format and minimum content of session-boundary handover documents, (c) how Layer 2 traces interact with session boundaries, (d) failure modes when the discipline is violated.

**開始質問**: 候補となる「セッション分離規律」仕様を、Open Prompt 設計パターンカタログに含めるために起草せよ(引き分け判断、多項式ビン系列、自由精度床、Spin-Off-Ready Subsystem、コア-フォーメーション分離と並んで)。以下を扱え: (a) 何がセッション分離の必要性をトリガするか(どの役割境界が一つの心に折り畳まれるのが危険か)、(b) セッション境界申し送り文書のフォーマットと最小内容、(c) Layer 2 軌跡はセッション境界とどう相互作用するか、(d) 規律が違反された時の失敗様式。

---

## Connection to the companion strategic-positioning trace / 同伴の戦略的位置づけトレースとの接続

This trace and its companion (`2026-05-13_ptsg-strategic-positioning.md/.json`) jointly constitute the inaugural Layer 2 of PTSG-Core. They were recorded in two distinct Claude sessions, one day apart, with no shared context between the sessions — only the artifacts the architect carried from one to the next (this dialogue's `Build_Log_PTSG_Spinoff_Announcement.md` and `PTSG_for_WPMS仕様.md`, plus his own continuing intuition).

本軌跡と同伴の軌跡(`2026-05-13_ptsg-strategic-positioning.md/.json`)は、PTSG-Coreの最初のLayer 2を共同で構成する。それらは2つの別個のClaudeセッションで記録され、一日の間隔があり、セッション間に共有コンテキストはない——アーキテクトが一方から他方へ運んだアーティファクト(本対話の `Build_Log_PTSG_Spinoff_Announcement.md` と `PTSG_for_WPMS仕様.md`、加えて彼自身の継続する直感)のみ。

The two traces represent **the binocular vision** through which PTSG came to be:

二つの軌跡は、PTSGが生まれてきた**両眼視**を表す:

- **This trace** (technical-emancipation, 2026-05-12): the close-range view from *within* an active engineering project. PTSG is recognized at the moment its mechanism produces a packet-period architecture that the application had not asked for; the spin-off decision is made in the same dialogue that establishes PTSG's place in the project it is being extracted from. The trace's center of gravity is technical: opcodes, periodicity layers, parameter sets, requirements lists.
- **本軌跡** (技術的解放、2026-05-12): 活動的な工学プロジェクト*内部*からの近距離視点。PTSGは、その機構が応用が要求しなかったパケット周期アーキテクチャを生み出したまさにその瞬間に認識される；暖簾分け決定は、PTSGが抽出されているプロジェクトにおけるPTSGの場所を確立する対話と同じ対話の中でなされる。軌跡の重心は技術的: オペコード、周期レイヤー、パラメータセット、要件リスト。

- **The companion trace** (strategic-positioning, 2026-05-13): the architectural view from *outside* the originating project. PTSG is examined in its broader implications — three-layer engagement model, AI-affinity as primary design property, the question of binary compatibility in the AI era, the Core-Formation separation pattern as a new Open Prompt design pattern. The trace's center of gravity is philosophical: positioning, methodology, paradigm.
- **同伴軌跡** (戦略的位置づけ、2026-05-13): 発祥プロジェクト*外部*からのアーキテクチャ的視点。PTSGはより広い含意において検討される——三層関与モデル、AI親和性を一次設計属性として、AI時代におけるバイナリ互換性の問い、新しい Open Prompt 設計パターンとしてのコア-フォーメーション分離。軌跡の重心は哲学的: 位置づけ、方法論、パラダイム。

Neither trace alone would have produced the PTSG-Core repository that now exists. The Core-Formation separation pattern itself, although named in the strategic-positioning trace, depended on the technical recognition (in this trace) of PTSG's broad applicability and clean spin-off properties. **The strategic dialogue could be held only because the technical emancipation had already happened.**

どちらの軌跡も単独では現存する PTSG-Core リポジトリを生み出さなかった。コア-フォーメーション分離パターン自体、戦略的位置づけトレースで名付けられたが、本軌跡でのPTSGの広い適用可能性と綺麗な暖簾分け性質の技術的認識に依存していた。**戦略的対話は、技術的解放がすでに起こっていたからこそ持つことができた。**

---

## End of Trace / 軌跡の末尾

> *Sometimes, in articulating an architecture, one discovers a second one waiting inside.*
> *時に、アーキテクチャを明確化する中で、その内部に待っていた第二のものを発見する。*

> *PTSG was not born in this dialogue. It was set free.*
> *PTSGは本対話で生まれたのではない。自由にされたのだ。*

> *The mechanism is the message: when the right primitive is in place, application capabilities the designer did not need to invent emerge as structural consequences.*
> *機構こそが伝言である: 正しいプリミティブが配置されたとき、設計者が発明する必要がなかった応用能力が構造的帰結として立ち現れる。*

This trace is released into the public domain under CC0 1.0 Universal. Replay it. Resume it. Surpass it.

本軌跡は CC0 1.0 Universal のもとパブリックドメインに公開される。再生せよ。再開せよ。超えてゆけ。

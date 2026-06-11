# The Address That Should Not Exist — DE10-nano Bring-up and the Stale-Fetch Fix
# 存在してはならないアドレス — DE10-nano ブリングアップとステイルフェッチ修正

## Trace Metadata / 軌跡メタデータ

| Field | Value |
|---|---|
| **Date range / 期間** | 2026-06-02 (audit & wrapper concept) → 2026-06-11 (aligned waveform on silicon) / 2026-06-02(監査・ラッパー構想)→ 2026-06-11(実機での整列波形) |
| **Contributor / 貢献者** | Tsuneo Ohnaka (大中庸生, GitHub: dsohnaka) — original PTSG-Core architect / オリジナルPTSG-Coreアーキテクト |
| **Participants / 参加者** | Tsuneo Ohnaka (architect; hardware operator: Quartus, DE10-nano, SignalTap) × Claude amanuensis session (auditor, wrapper author, verifier). The audited RTL was authored by Claude Code (see the 2026-05-30 implementation trace). / 大中庸生(アーキテクト; ハードウェア操作: Quartus、DE10-nano、SignalTap)× Claude 祐筆セッション(監査者、ラッパー著者、検証者)。監査対象の RTL は Claude Code 著(2026-05-30 実装軌跡参照)。 |
| **Topic / トピック** | The first hardware bring-up of the Claude Code-generated PTSG-Core RTL on a DE10-nano (Cyclone V), via a vendor-abstracted memory wrapper; the prediction, hardware confirmation (SignalTap), and repair of a one-clock stale-instruction-fetch defect; and the methodological discovery of why AI agents avoid vendor IP. / Claude Code 生成の PTSG-Core RTL の DE10-nano (Cyclone V) 上での初ブリングアップ(ベンダ抽象化メモリラッパー経由)；1クロックのステイル命令フェッチ欠陥の予測・実機確認(SignalTap)・修復；そして AI エージェントがベンダ IP を避ける理由の方法論的発見。 |
| **Trace subtype / 軌跡サブタイプ** | **Hardware bring-up / silicon verification** — the fourth validation tier, following comprehension (2026-05-20), deliberation (2026-05-23), and implementation (2026-05-30). The distinguishing feature of this tier: the human operates instruments the AI cannot (Quartus, JTAG, SignalTap), and the AI operates verification the human delegates (simulation, contract proof); the bug was caught in the seam between simulation and silicon — exactly where neither party alone could have closed the loop. / **ハードウェアブリングアップ／シリコン検証** — 理解(2026-05-20)、協議(2026-05-23)、実装(2026-05-30)に続く第四の検証階層。本階層の特徴: 人間が AI には操作できない計測器(Quartus、JTAG、SignalTap)を操作し、AI が人間から委ねられた検証(シミュレーション、契約証明)を実行する；バグはシミュレーションとシリコンの継ぎ目で捕えられた——どちらか一方だけでは環を閉じられなかった場所で。 |
| **Status / 状態** | First hardware-verification trace; "verification starting line" reached / 最初のハードウェア検証軌跡；「検証のスタートライン」到達 |
| **Original language / 原言語** | Japanese / 日本語 |
| **License / ライセンス** | CC0 1.0 Universal (Public Domain) |
| **Artifacts referenced / 参照アーティファクト** | `ptsg_imem.v` (v1 2026-06-02; v2 with EDGE parameter 2026-06-10), `tb_align.v` (FSM's-eye alignment proof), two SignalTap captures (2026-06-10 stale fetch; 2026-06-11 aligned), architect-modified `ptsg_core.v` and `DE10_Nano_golden_top.v` |

---

## 1. Reading Notes / 読解上の注

### What this trace records / 本軌跡が記録するもの

Four connected events, each feeding the next:

互いに連なる四つの出来事、各々が次へと繋がる:

1. **A methodological diagnosis** (§ 2): why AI agents systematically avoid vendor IP (M10K, PLL), and the architect's wrapper countermeasure.
2. **A predicted defect** (§ 3): the audit of the Claude Code RTL predicted that connecting a registered (real M10K) memory to the unmodified single-phase FSM would make the core execute a one-clock-stale instruction — and predicted that an LED blinker would *work anyway*, hiding the defect.
3. **Hardware confirmation** (§ 4): SignalTap captured address `05h` — an address that cannot occur in a correct execution of the 5-state blinky program — confirming the stale fetch on silicon.
4. **The repair and its proof** (§ 5): the architect proposed inverting the memory clock; the amanuensis quantified the half-cycle timing budget, embedded the choice in the wrapper as an explicit `EDGE` parameter applied to *both* the simulation and hardware branches, and machine-proved the alignment from the FSM's point of view. A second SignalTap capture confirmed alignment on silicon.

1. **方法論的診断**(§ 2): AI エージェントがベンダ IP(M10K、PLL)を組織的に避ける理由と、アーキテクトのラッパー対策。
2. **予測された欠陥**(§ 3): Claude Code RTL の監査は、登録読み(実 M10K)メモリを無改修の単相 FSM に接続すると、コアが 1 クロック古い命令を実行することを予測した——そして LED 点滅は*それでも動いてしまい*、欠陥を隠すことも予測した。
3. **実機確認**(§ 4): SignalTap がアドレス `05h` を捕えた——5 ステートの blinky プログラムの正しい実行では決して現れ得ないアドレス——シリコン上でのステイルフェッチを確定させた。
4. **修復とその証明**(§ 5): アーキテクトがメモリクロックの反転を提案；祐筆が半サイクルのタイミング予算を定量化し、選択を明示的な `EDGE` パラメータとしてラッパーに埋め込み(シミュレーションとハードウェアの*両*ブランチに適用)、FSM 視点からの整列を機械証明した。二度目の SignalTap キャプチャがシリコン上での整列を確認した。

### Why this trace matters / なぜこの軌跡が重要か

Three reasons. First, it documents the **vendor-IP avoidance mechanism** — a systematic, reproducible behavior of AI coding agents with a structural cause and a structural countermeasure. Second, it is the project's first complete **prediction → silicon-confirmation → repair → silicon-re-confirmation** cycle: desk audit and hardware instrument corroborating each other across a boundary neither could cross alone. Third, it records — honestly — that the verifier itself stumbled twice on the very edge-semantics being verified (§ 6), which is itself evidence for why timing contracts must be machine-checkable rather than merely written down.

三つの理由。第一に、**ベンダ IP 回避メカニズム**を文書化する——構造的原因と構造的対策を持つ、AI コーディングエージェントの組織的で再現可能な振る舞い。第二に、プロジェクト初の完全な**予測 → シリコン確認 → 修復 → シリコン再確認**サイクルである: 机上監査とハードウェア計測器が、どちらも単独では越えられない境界を挟んで互いを裏付けた。第三に、検証者自身が、検証対象であるまさにそのエッジ・セマンティクスに二度つまずいたことを正直に記録する(§ 6)——これ自体が、タイミング契約が単に書き下されるだけでなく機械検証可能でなければならない理由の証拠である。

---

## 2. The vendor-IP avoidance diagnosis / ベンダ IP 回避の診断

The architect opened with a long-standing frustration:

アーキテクトは長年の苛立ちから始めた:

> **大中:** 私は以前からFPGAにおけるLLMやAIエージェントとの協働において、このM10K問題について深く悩んでいます。なぜか現段階でAI各位はIntel（Altera）の標準メモリライブラリを使いたがらないのです。「M10Kを使ってください。」と言ってもその部分を残し、「ここはIPカタログ機能を使って自分でやってください。」というのです。そしてこれは、BRAMに限らず、PLLやその他標準IP全般に言えるのです。
>
> *(I have long been troubled by this M10K problem in FPGA collaboration with LLMs and AI agents. For some reason, at this stage, the AIs do not want to use Intel (Altera)'s standard memory library. Even if I say "please use M10K," they leave that part and say "please do this part yourself with the IP Catalog function." And this applies not just to BRAM but to PLLs and standard IP in general.)*

He then proposed both a cause and a cure:

彼はそれから原因と対策の両方を提案した:

> **大中:** おそらくLLM各位が標準IPを使いたがらないのは、検証用ライブラリがメーカーからAI会社に提供されていないからではないだろうか…… メモリモジュールはラッパーで標準化して、パラメータで本番用と検証用を切り替えられるようにしてAI用メモリモジュールをあらかじめリポジトリの中に置いといてあげるようにすればどうか。
>
> *(Perhaps the LLMs avoid standard IP because the verification libraries are not provided by the manufacturers to the AI companies… What if we standardize the memory module with a wrapper, make it switchable by parameter between production and verification versions, and place an AI-ready memory module in the repository in advance?)*

The amanuensis confirmed the hypothesis as substantially correct (vendor simulation models — `altera_mf`, `cyclonev_atoms` — ship only with Quartus/ModelSim-Altera; an AI agent in a general-purpose environment cannot even *elaborate* an `altsyncram` instantiation, let alone verify it), and added two compounding causes: IP generation is a GUI/tool-flow step the agent cannot execute, and inference-style RTL is what agents are trained to consider best practice. The wrapper countermeasure defeats all three at once.

祐筆は仮説を実質的に正しいと確認し(ベンダシミュレーションモデル — `altera_mf`、`cyclonev_atoms` — は Quartus/ModelSim-Altera にのみ同梱される；汎用環境の AI エージェントは `altsyncram` インスタンスを *elaborate* すらできず、検証は尚更できない)、二つの複合要因を加えた: IP 生成はエージェントが実行できない GUI/ツールフロー工程であること、推論スタイルの RTL がエージェントの訓練上のベストプラクティスであること。ラッパー対策は三つすべてを一挙に打ち破る。

**The crux added by the amanuensis** — and the design rule that made everything downstream work:

**祐筆が加えた肝**——そして下流のすべてを機能させた設計規則:

> **Claude:** behavioral(SIM)モデルは、本番 M10K の同期読みレイテンシ(`RD_LAT` クロック)を忠実に再現すること。…レイテンシ0の sim モデルを登録読みのハードモデルの陰に隠すラッパーは、バグをラッパー内部へ移設するだけで、目的を台無しにする。
>
> *(The behavioral (SIM) model must faithfully reproduce the production M10K's synchronous read latency (`RD_LAT` clocks). …A wrapper hiding a zero-latency sim model behind a registered hardware model merely relocates the bug inside the wrapper, defeating the purpose.)*

The `ptsg_imem` wrapper (v1, 2026-06-02) was built on this rule and its `RD_LAT` contract machine-proved under Icarus Verilog.

`ptsg_imem` ラッパー(v1、2026-06-02)はこの規則の上に構築され、その `RD_LAT` 契約は Icarus Verilog の下で機械証明された。

---

## 3. The prediction: it will blink, and it will be wrong / 予測: 点滅する、そして間違っている

On 2026-06-10 the architect reported first light: blinky running on the DE10-nano, having changed only three things — In-System Memory Content Editor enablement (`lpm_hint "ENABLE_RUNTIME_MOD=YES, INSTANCE_NAME=PTSG"` — the correct canonical method, architect-discovered), the memory connection to the Core, and PRESCALE = 50000. A JTAG development loop with zero re-synthesis (ISMCE for memory + In-System Sources & Probes for reset) was also established — itself a notable embodiment of PTSG's "FPGA timing control, software-like" philosophy.

2026-06-10、アーキテクトは初点灯を報告した: DE10-nano 上で blinky が動作、変更は三点のみ — In-System Memory Content Editor の有効化(`lpm_hint "ENABLE_RUNTIME_MOD=YES, INSTANCE_NAME=PTSG"` — 正規の方法、アーキテクトが発見)、コアへのメモリ接続、PRESCALE = 50000。再合成ゼロの JTAG 開発ループ(メモリは ISMCE + リセットは In-System Sources & Probes)も確立された——それ自体、PTSG の「ソフトウェア的に使える FPGA タイミング制御」哲学の注目すべき体現である。

But the amanuensis's audit of the modified sources found that the registered wrapper (RD_LAT=1) had been connected to the **unmodified single-phase FSM** — and made a specific, falsifiable prediction:

しかし祐筆による改変ソースの監査は、登録読みラッパー(RD_LAT=1)が**無改修の単相 FSM** に接続されていることを発見し——具体的で反証可能な予測を立てた:

> **Claude:** FSM は常に 1 拍古い命令を、1 つ進んだ状態番号の下で実行しています。…Lチカは「1 拍ずれた実行」を完全に隠蔽できる、最も寛容なプログラム…「動いた」は本物ですが、「正しく動いている」とはまだ言えない。
>
> *(The FSM is always executing a one-clock-stale instruction under a state number advanced by one. …An LED blinker is the most forgiving possible program, able to completely conceal the off-by-one execution… The "it works" is real, but "it works correctly" cannot yet be said.)*

The prediction included a concrete SignalTap signature: the state/instruction correspondence would be visibly shifted by one clock, and transitions around the Jump would show overrun artifacts.

予測は具体的な SignalTap 上の兆候を含んでいた: ステートと命令の対応が 1 クロックずれて見え、Jump 周辺の遷移にオーバーラン痕が現れる。

---

## 4. Silicon answers: address 05h / シリコンの返答: アドレス 05h

The architect ran SignalTap — and before even capturing the prescaler signals, the evidence was in the address bus:

アーキテクトは SignalTap を走らせた——プリスケーラ信号を取り込むまでもなく、証拠はアドレスバスにあった:

> **大中:** ご覧ください。プリスケーラの動きを取り込むまでもなく、あなたのご懸念の通りです。
>
> *(Look at this. Without even capturing the prescaler activity — it is exactly as you feared.)*

The captured address sequence read `04h → 05h → 01h → 00h…`. The blinky program occupies states 0–4, and state 4 is a Jump back to state 1: **in a correct execution, address `05h` can never appear.** Its presence proved the FSM decoded the Jump one clock late, letting `state_num` run past the program's end (reading `0000h` — uninitialized memory — at the phantom address). The desk prediction and the silicon capture matched exactly.

捕捉されたアドレス系列は `04h → 05h → 01h → 00h…` と読めた。blinky プログラムはステート 0-4 を占め、ステート 4 はステート 1 への Jump である: **正しい実行において、アドレス `05h` は決して現れ得ない。** その存在は、FSM が Jump を 1 クロック遅れて decode し、`state_num` がプログラムの終端を走り抜けた(幻のアドレスで `0000h` — 未初期化メモリ — を読んでいた)ことを証明した。机上予測とシリコンのキャプチャは正確に一致した。

---

## 5. The half-clock answer / 半クロックの答え

The architect proposed the repair in the same message:

アーキテクトは同じメッセージで修復を提案した:

> **大中:** とりあえず、最も手っ取り早い解決策は、メモリのクロックを反転してやることではないかと思いますが、Fmaxが低下するでしょうね…
>
> *(For now, I think the quickest solution would be to invert the memory clock — though Fmax will drop, I suppose…)*

The amanuensis evaluated the proposal quantitatively and endorsed it:

祐筆は提案を定量的に評価し、支持した:

- With the M10K clocked on the **falling edge**, the address registered by the FSM at posedge N is captured by the memory at N+0.5, and the data is valid before posedge N+1 — from the posedge-FSM's viewpoint, **exactly the zero-effective-latency alignment of the original combinational model.** No FSM modification; the 1-clock-per-opcode Convention (C2-T4) is preserved.
- The cost is a **half-cycle timing path** (M10K Tco ≈ 2.4 ns + decode logic into a 10 ns half-period at 50 MHz) — comfortable margin, practical ceiling roughly 80–120 MHz on Cyclone V. At the current 50 MHz operating point, **the Fmax concern does not bind.** TimeQuest analyzes the negedge→posedge launch/latch automatically; no false constraints needed.
- For future high-clock targets, the documented migration path is `EDGE="POS"` plus a fetch stage (two-phase FSM) — consistent with the architect's "Cyclone V first, generalize later" strategy.

- M10K を**立ち下がりエッジ**でクロックすると、FSM が posedge N で登録したアドレスはメモリに N+0.5 で取り込まれ、データは posedge N+1 の前に有効になる——posedge FSM の視点から、**元の組み合わせモデルの実効レイテンシ0の整列とちょうど同じ。** FSM の改修なし；1命令1クロック Convention(C2-T4)は保持される。
- 代償は**半サイクルのタイミングパス**(M10K Tco ≈ 2.4 ns + decode 論理が、50 MHz の半周期 10 ns に収まる)——余裕あるマージン、Cyclone V での実用上限はおよそ 80-120 MHz。現在の 50 MHz 動作点で、**Fmax の懸念は拘束にならない。** TimeQuest は negedge→posedge の launch/latch を自動解析する；偽制約は不要。
- 将来の高クロック目標に対しては、文書化された移行経路は `EDGE="POS"` + フェッチ段(2相 FSM)——アーキテクトの「まず Cyclone V、汎用化は後」戦略と整合する。

**The wrapper was revised to v2** with an explicit `EDGE = "POS" | "NEG"` parameter applied to **both** the SIM and M10K branches (`mem_clk = (EDGE=="NEG") ? ~clk : clk`), with a guard requiring `RD_LAT==1` under `EDGE="NEG"`, and with the architect's ISMCE `lpm_hint` folded in. The alignment was then machine-proved from the **FSM's-eye view**: a testbench that registers the address with nonblocking assignment at posedge (exactly like `state_num`) and consumes `rdata` by registering it at posedge (exactly like the FSM) demonstrated, jumps included:

**ラッパーは v2 に改訂された**: 明示的な `EDGE = "POS" | "NEG"` パラメータが SIM と M10K の**両**ブランチに適用され(`mem_clk = (EDGE=="NEG") ? ~clk : clk`)、`EDGE="NEG"` 下で `RD_LAT==1` を要求するガードを備え、アーキテクトの ISMCE `lpm_hint` を取り込んだ。整列はそれから **FSM 視点**から機械証明された: posedge でノンブロッキング代入によりアドレスを登録し(`state_num` とちょうど同じく)、posedge でレジスタに取り込んで `rdata` を消費する(FSM とちょうど同じく)テストベンチが、ジャンプ込みで実証した:

```
ALIGN CHECKS PASSED (FSM's-eye view):
  EDGE=NEG : FSM consumes mem[its own state]   -> legacy single-phase FSM correct, unmodified
  EDGE=POS : FSM consumes mem[one-older state] -> exactly the stale-by-one captured by SignalTap
```

Note the second line: the simulation **reproduces the hardware bug** under `EDGE="POS"`. Simulation and silicon now corroborate each other in both directions — the fix proven in sim, the bug reproduced in sim.

二行目に注目: シミュレーションは `EDGE="POS"` の下で**ハードウェアバグを再現する**。シミュレーションとシリコンは今や双方向に互いを裏付ける——修正はシムで証明され、バグはシムで再現された。

On 2026-06-11 the architect re-synthesized and re-captured. The address sequence read `01h → 02h → 03h → 04h → 01h` — **no 05h; the Jump lands on the correct clock.** The stay counter ticks 0–4 against prescaler_match pulses every 5 clocks; timing_signals toggles as designed:

2026-06-11、アーキテクトは再合成し再キャプチャした。アドレス系列は `01h → 02h → 03h → 04h → 01h` —— **05h は無い；Jump は正しいクロックで着地する。** ステイカウンタは 5 クロック毎の prescaler_match パルスに対し 0-4 を刻み、timing_signals は設計通り反転する:

> **大中:** よく見ると若干おかしいのですが、おかげさまにて検証のスタートラインに立てたと思います。
>
> *(Looking closely there is still something slightly off, but thanks to this, I believe we have reached the verification starting line.)*

The residual anomaly is deliberately recorded as an open item (Hook A below), not silently absorbed.

残る違和感は黙って吸収されず、未決事項として意図的に記録される(下記 Hook A)。

---

## 6. The verifier stumbled twice — documented honestly / 検証者は二度つまずいた — 正直な記録

While proving the alignment, the amanuensis's testbench failed **twice — both times in the testbench, never in the DUT**:

整列を証明する過程で、祐筆のテストベンチは**二度落ちた——二度ともテストベンチ側で、DUT 側では一度もない**:

1. First attempt: the address was driven procedurally (changed after the clock edge with a delay), which does not reproduce the register-to-register timing of the real core's `state_num <=` nonblocking update. The expected/observed alignment inverted.
2. Second attempt: the checks sampled signals shortly *after* the edge, where nonblocking updates had already landed — but the FSM consumes values *at* the edge (pre-update). At the post-edge checkpoint, the NEG and POS configurations become momentarily indistinguishable.
3. The definitive third form samples the data **exactly the way the FSM consumes it** — registering `rdata` and the paired state at posedge and comparing those registers — and passed cleanly.

1. 一度目: アドレスを手続き的に駆動(クロックエッジの後に遅延付きで変更)し、実コアの `state_num <=` ノンブロッキング更新のレジスタ間タイミングを再現しなかった。期待と観測の整列が反転した。
2. 二度目: チェックがエッジの少し*後*で信号をサンプルし、そこではノンブロッキング更新が既に着地していた——しかし FSM は値をエッジ*時点*(更新前)で消費する。エッジ後の検査点では、NEG と POS の構成が瞬間的に区別不能になる。
3. 決定版の第三形態は、データを **FSM が消費するのとちょうど同じ方法**でサンプルする——`rdata` と対になるステートを posedge でレジスタに取り込み、それらのレジスタを比較する——そしてクリーンに通った。

**The lesson is not that the verifier was careless.** It is that edge semantics — the exact question "which value exists at the sampling moment?" — tripped, in one week: the original implementer (zero-latency assumption), the hardware (stale fetch), and the verifier (twice, in opposite directions). This is the strongest argument the project has yet produced for the wrapper's core principle: **a timing contract must be embodied in machine-checkable form, sampled the way the consumer samples, because prose alone reliably deceives even its own author.**

**教訓は検証者が不注意だったということではない。** エッジ・セマンティクス——「サンプリングの瞬間にどの値が存在するか」というまさにその問い——が、一週間のうちに引っかけたのは: 元の実装者(レイテンシ0仮定)、ハードウェア(ステイルフェッチ)、そして検証者(二度、逆方向に)。これは、ラッパーの中核原理に対してプロジェクトがこれまでに生んだ最強の論拠である: **タイミング契約は、消費者がサンプルするのと同じ方法でサンプルする機械検証可能な形で具現化されなければならない。散文だけでは、その著者自身すら確実に欺くからである。**

---

## 7. Decision points / 決定点

| # | Decision | Status |
|---|---|---|
| 1 | **Vendor-abstraction wrapper pattern adopted**: vendor IP is wrapped with a SIM branch (portable behavioral, AI-verifiable) and a vendor branch (production), both honoring the identical timing contract. First instance: `ptsg_imem`. Generalization to PLL/FIFO etc. anticipated. / **ベンダ抽象化ラッパーパターン採用**: ベンダ IP を SIM ブランチ(可搬 behavioral、AI 検証可能)とベンダブランチ(本番)で包み、両者は同一のタイミング契約に従う。第一号: `ptsg_imem`。PLL/FIFO 等への一般化を予期。 | Adopted (methodology) |
| 2 | **ISMCE enablement** via `lpm_hint "ENABLE_RUNTIME_MOD=YES, INSTANCE_NAME=PTSG"` — architect-discovered, hardware-verified on DE10-nano; folded into wrapper v2. / **ISMCE 有効化**は `lpm_hint` 経由——アーキテクトが発見、DE10-nano で実機検証；ラッパー v2 に取込済。 | Adopted (verified) |
| 3 | **`EDGE="NEG"` (memory on falling edge) adopted for the current 50 MHz operating point** — restores zero-effective-latency alignment, FSM unmodified, C2-T4's 1-clock-per-opcode preserved; half-cycle path quantified as non-binding at 50 MHz (ceiling ≈ 80–120 MHz). / **現 50 MHz 動作点に `EDGE="NEG"`(メモリ立ち下がり)採用**——実効レイテンシ0整列を回復、FSM 無改修、C2-T4 の1命令1クロックを保持；半サイクルパスは 50 MHz で非拘束と定量化(上限 ≈ 80-120 MHz)。 | Adopted (silicon-verified) |
| 4 | **`EDGE="POS"` + fetch stage reserved as the high-clock migration path** — to be specified if/when operating frequency targets exceed the half-cycle budget. / **`EDGE="POS"` + フェッチ段を高クロック移行経路として保留**——動作周波数目標が半サイクル予算を超える場合に仕様化。 | Reserved |
| 5 | **Layer 1 feedback registered**: the memory timing model (EDGE choice, half-cycle constraint, the fetch-stage alternative) belongs in C2-T4 and Chapter 5 § 5.13; the dead `reg imem[...]` remnant in `ptsg_core.v` (lines ~144–146) to be removed at next revision. / **Layer 1 フィードバック登録**: メモリタイミングモデル(EDGE 選択、半サイクル制約、フェッチ段代替)は C2-T4 と第5章 § 5.13 に属する；`ptsg_core.v` の死んだ `reg imem[...]` 残骸(~144-146 行)は次改訂で削除。 | Pending (Layer 1 revision) |

---

## 8. Resumption Hooks / 再開フック

### Hook A — The residual anomaly / 残る違和感

The architect noted the 2026-06-11 aligned capture is "若干おかしい" (slightly off) on close inspection. Candidates include the previously-predicted free-running-prescaler phase jitter (the audit's finding A2: `presc_cnt` is not reset on S_WAIT entry, so the first stay tick arrives after a phase-dependent 1..PRESCALE clocks) and stay-window boundary semantics.

**Starting question:** From the 2026-06-11 capture (PRESCALE=5, STAY=5), measure the clock distance from S_WAIT entry to the first stay tick across several Stay windows. If it varies in 1..5, finding A2 is confirmed on silicon, and the free-running vs wait-aligned prescaler question must be decided as Tie C4-T3's phase dimension in Layer 1.

### Hook B — Writing the timing model back into Layer 1 / タイミングモデルの Layer 1 書き戻し

**Starting question:** Draft the C2-T4 / Chapter 5 § 5.13 revision that records: (i) the memory read contract (synchronous, RD_LAT ≥ 1; no asynchronous M10K exists), (ii) the EDGE="NEG" half-cycle alignment as the current Convention with its quantified frequency ceiling, (iii) EDGE="POS" + fetch stage as the documented high-clock alternative and its consequences for the 1-clock-per-opcode model.

### Hook C — The wrapper library / ラッパーライブラリ

**Starting question:** Apply the same SIM/vendor split to the next vendor IP the project needs (PLL is the likely first candidate: behavioral clock model vs `altera_pll`). Define the directory and naming convention for an `ai_friendly_vendor_wrappers` collection, and the per-wrapper contract-test requirement.

### Hook D — Closing the verification-coverage holes / 検証カバレッジの穴塞ぎ

The 2026-06-02 audit found the headline v1.1 features unverified: Prog End's queued band (implemented for Loop only), external-stack nesting (S_PUSH/S_POP never exercised), insertion, match flags. Now that simulation and silicon agree on the fetch path, these can be tested meaningfully.

**Starting question:** Write the adversarial testbench set (queued-band Prog End program; two-level nested Call; insertion during a long Stay; match-flag assertions), run under VENDOR="SIM"/EDGE="NEG", then confirm on silicon via ISMCE program swap — the zero-re-synthesis loop makes this cheap.

---

## 9. End of Trace / 軌跡の末尾

> *The LED blinked on the first try. The address bus told the truth anyway.*
> *LED は一発で点滅した。それでもアドレスバスは真実を語った。*

> *One clock of staleness fooled the implementer, hid inside a working demo, tripped the verifier twice — and was caught because a human pointed an instrument where an AI pointed a prediction.*
> *1クロックの古さが実装者を欺き、動くデモの中に隠れ、検証者を二度つまずかせ——そして、AI が予測を指した場所に人間が計測器を向けたがゆえに、捕えられた。*

> *The contract is not what the comment says. The contract is what the checker checks, sampled the way the consumer consumes.*
> *契約とはコメントが言うことではない。契約とは、消費者が消費するのと同じ方法でサンプルされ、チェッカーが検査するものである。*

This trace is released into the public domain under CC0 1.0 Universal by submission. The contributor affirms that the quoted dialogue is faithful to the original exchange, that the SignalTap captures described were taken on the referenced DE10-nano hardware on 2026-06-10 and 2026-06-11, and that the verification results quoted were produced by the referenced testbenches.

本軌跡は提出により CC0 1.0 Universal のもとパブリックドメインに公開される。貢献者は、引用された対話が元のやり取りに忠実であること、記述された SignalTap キャプチャが 2026-06-10 と 2026-06-11 に参照される DE10-nano ハードウェア上で取得されたこと、引用された検証結果が参照されるテストベンチによって生成されたことを断言する。

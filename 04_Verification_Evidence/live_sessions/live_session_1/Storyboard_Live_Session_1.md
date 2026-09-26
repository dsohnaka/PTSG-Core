# PTSG Live Session #1 — Storyboard with Expectation Tables
# PTSG 実演 第一話 — 期待値表つき絵コンテ
## "Improvisation Design: from a stuck Reset to a 25 MHz divider, without recompiling"
## 「インプロビゼーション・デザイン——固まった Reset から 25 MHz 分周器まで、再コンパイルなしで」

> **Status:** 撮影台本たたき台(祐筆起草 2026-07-09、裁定はアーキテクト)。
> **Position:** ログ用演出として L4 の**外**。ただし各シーンの計画・期待値・結果は L4 に蓄積する
> (動画実体は YouTube、リポジトリには URL＋ローカルファイル名＋コミットハッシュのみ)。
> **Doctrine:** 「期待する状態を先に想定し、その通りになることを検証せよ」——各シーンは
> **Prediction(撮影前に確定)** → **Observed(撮影で記入)** → **Verdict** の三段で記録する。

---

## 0. Rig & evidence protocol / 機材と記録プロトコル

**機材:** DE10-nano(Cyclone V、50 MHz)。LED をカメラで直撮り。GPIO にピエゾスピーカー。
同じ GPIO をオシロで並行プローブ(画面も撮影)。ISMCE ウィンドウを画面キャプチャ。
比較音源用に DAW＋外部スピーカー(シーン4)。

**各テイクの記録(observation.md の骨格):**
- Commit hash / bitstream checksum / prescaler P(コンパイル時定数)
- Program words(番地順の hex 列)
- **Prediction**(本書の該当行を転記)/ **Observed** / **Verdict**(PASS・FAIL・SURPRISE)
- YouTube URL / ローカル動画ファイル名 / 撮影日

**命令語エンコーディング(as-built RTL、ptsg_core.v L340–352・L507–512 で裏取り済み):**
`[31:16]=timing signals`、`[15:4]=operand`、`[3:0]=opcode`。
opcode: 0=Global、1=Stay、2=Branch、3=Jump。Global の sub-op は D8–D15:
0=Reset、2=Stay Set、6=Prog End、7=NOP。LED = tsig bit 0(= instr bit 16)。

**再コンパイルが要るのは P の変更のみ**(P=6250 → 20 → 1 の計2回)。他は全部 ISMCE 生打ち。

---

## Scene 1 — 起動: 永久 Reset ループと手動 L チカ / Boot: the eternal Reset loop, manual blink

**状況:** メモリ全域 0 フィル。`00000000` = Global Reset(tsig 全消灯)。PTSG は Reset を
永久ループしている——「機械は動いているが、時間はまだ始まっていない」画から入る。

| # | 操作(ISMCE) | Prediction / 期待値 | 行使セル |
|---|---|---|---|
| 1-a | 起動のみ | LED 消灯。オシロ: GPIO 完全フラット(Reset ループ、毎クロック SN=0) | §3.4b FG Reset 行、C3-F21(presc_cnt は自由走行のまま) |
| 1-b | 0番地 ← `00010000` | **書いた瞬間 LED 点灯**(Reset 語自身の tsig が Driven)。以後定常点灯 | FG Reset: Timing Signals = Driven |
| 1-c | 0番地 ← `00000000` | 消灯。手動 L チカ成立 | 同上 |

**演出ノート:** ここで「Reset は命令であり、命令は 16 本の信号を運ぶ」——tsig フィールドの
存在を、コードを一語も書かずに見せている。

---

## Scene 2 — 1 Hz L チカと「約1秒」の裁判 / The 1 Hz blink — putting "approximately" on trial

**操作:** 0番地 ← `0000FA01`(消灯 Stay 4000)、1番地 ← `0001FA01`(点灯 Stay 4000)。
2番地は 0 フィルのまま = `00000000`(Reset、tsig 消灯側)。P=6250 → tick = 125 µs。

**台本上の問い(撮影前にカメラへ宣言):** 「Reset の 1 クロック(20 ns)ぶん、周期は
1 秒より*わずかに*長いはずだ——果たして?」

| Prediction / 期待値(祐筆の白箱、ここが第一の山場) |
|---|
| **周期はぴったり 1.000000 秒(水晶精度)。20 ns は周期に現れない。** プリスケーラは自由走行(C4-F9)であり、裸 Stay はグリッドの tick を数える。Reset の 1 クロックは tick と tick の狭間に**吸収**され、次の Stay の初回 tick 間隔が 1 クロック短くなるだけ。さらに 0 フィルの Reset 語は tsig=消灯なので、その 1 クロックは消灯側の中に消える——**デューティも正確に 1:1**。 / **Period = exactly 8000 ticks = 1.000000 s; the 20 ns is absorbed by the free-running grid (C4-F9) and never appears in the period. Duty exactly 1:1 (the Reset word's tsig rides the OFF side).** |
| **対照予言:** 同じ理屈が P=1 では**成り立たない**(全クロックが tick なので吸収先がない)。この対比はシーン5で回収する。 / The same program at P=1 WILL stretch — the payoff lands in Scene 5. |

**追加実験(任意):** 2番地 ← `00010000`(Reset を点灯側 tsig に)。予言: 周期・デューティとも
測定可能な変化なし(20 ns @1 Hz)。ただし「Reset の 1 クロックがどちら側に乗るかは Reset 語の
tsig が決める」という原理宣言として撮っておく——P=1 での伏線。

**行使セル:** C4-F8/F9、§3.4b Stay FG 行(Consumes)× Reset FG 行(Ignored)の対称性。

---

## Scene 3 — デューティ遊びと可聴化 / Duty play, and the program becomes audible

**操作(すべて生打ち、再コンパイルなし):** Stay 値を段階的に短縮。点滅 → ちらつき → 音。

| # | Words(0/1番地) | Prediction | 備考 |
|---|---|---|---|
| 3-a | `00000FA1` / `0001 0FA1` → 順次短縮 | 8 Hz あたりでちらつき、~30 Hz で融合(輝度=デューティ) | 人間の網膜が最初の計測器 |
| 3-b | `00000041` / `00010041` | **周期 8 tick = 1.000 ms = 1.000 kHz。ピエゾが A 上の C6 近傍の純音(矩形波)** | この語対はシーン5で P=1 のまま再登場する——伏線 |
| 3-c | `00000021` / `00010061`(2:6) | 同じ 1 kHz、音色が変わり(高調波構成)、LED 輝度が上がる | デューティ=音色=輝度の三位一体 |
| 3-d | `00000061` / `00010021`(6:2) | 同じ 1 kHz、暗く、細い音 | |

**演出ノート:** 「ピッチは合計、音色は比率」——PTSG プログラムの時間軸が耳で読める瞬間。

---

## Scene 4 — DAW とのビート: 水晶を耳で測る / Beating against the DAW: measuring the crystal by ear

**再コンパイル①: P=20**(tick 400 ns)。0番地 ← `00004E21`、1番地 ← `00014E21`
(Stay 1250 ×2 = 2500 tick × 400 ns = 1.000 ms)。DAW から 1 kHz 正弦波を別スピーカーで再生。

| Prediction / 期待値 |
|---|
| PTSG 側は構成上 50 MHz 水晶に対して**厳密に** 1.000 kHz(シーン2の吸収則により Reset の補正項なし)。残るビートは **DAW/オーディオ IF のクロックと FPGA 水晶の相対 ppm 誤差の直読**。例: 相対誤差 50 ppm → ビート 0.05 Hz → 20 秒周期のうねり。 / The residual beat frequency directly reads out the relative ppm error between the FPGA crystal and the DAW's audio clock. |
| **見せ場:** 「$130 のボードが DAW を検波している」——どちらが基準器かの逆転。オシロで両波形を重ね、ゆっくり滑る位相も同時に見せる。 |

**行使セル:** C4-F8(前景プリスケールド実行)の精度主張の実測。

---
## Scene 5 — P=1: オシロの世界と 5:4 の異形 / P=1: into the oscilloscope, and the 5:4 anomaly

**再コンパイル②: P=1**(全クロックが tick)。語はシーン 3-b と同一: `00000041` / `00010041`。

**台本上の問い:** 「同じプログラム。P=6250 では完璧な 1:1 だった。P=1 では?」

| Prediction / 期待値(RH028 の実機初確認、ここが第二の山場) |
|---|
| **周期 9 クロック = 180 ns(5.556 MHz)。デューティは 消灯:点灯 = 5:4。** 内訳: 消灯 Stay-4 = 4 clk、点灯 Stay-4 = 4 clk、Reset = 1 clk(0 フィル語 → tsig 消灯側に加算)。P=1 では全クロックが tick なので Reset の 1 クロックに**吸収先がなく**、周期がまる 1 クロック伸びる——シーン2の対照予言の回収。 / **Period 9 clk (5.556 MHz), duty OFF:ON = 5:4.** At P=1 every clock is a tick; the Reset clock has nowhere to hide. |
| **裸 Stay-N@P=1 = 正確に N クロック**(RH028 ②)——これはシミュレーション検証のみで**実機未確認**のフック。この画が撮れて数値が合えば、RH028 が実機で初めて 🟢 になる。 / First silicon confirmation of RH028's exactness statement. |

**演出ノート:** 2番地 ← `00010000` に打ち替えると 5:4 が**点灯:消灯 = 5:4** に反転する
(Reset の 1 クロックが点灯側へ引っ越す)。シーン2で宣言した原理が、今度は目に見える。

---

## Scene 6 — Que Reset で 1:1 を取り返す / Reclaiming 1:1 with a queued Reset

**操作:** 点灯側を窓付きシーケンスに書き換える(生打ち4語):

```
addr0: 00000041   消灯 Stay-4                      (4 clk)
addr1: 00010200   Stay Set(tsig 点灯、窓を開く)     (1 clk、FG 前縁例外)
addr2: 00010600   Prog End(BG/Q 境界宣言)          (裏スキャン、tsig は Held=点灯)
addr3: 00000000   ← 0 フィルのまま = Global Reset   (Que 帯域 → 予約のみ)
addr4: 00010041   Stay 4(S_WAIT の座席、目標値 4)
```

**演出ノート(ここは口上で強調):** addr3 は**打っていない**。0 フィルのメモリは Reset で
あり、Que 帯域に置かれた 0 は「timeup で発火する Reset の予約」として読まれる——
何も書かないことがプログラムになる。

| Prediction / 期待値(本日成文化した C3-F22 改訂の実機初確認、第三の山場) |
|---|
| **周期 8 クロック = 160 ns(6.250 MHz)、デューティ正確に 1:1。** Que Reset は独立並列チャネルに予約され(C3-F22 rev.、RH015)、Stay-timeup の**境界そのもの**で発火する(C4-F11 後縁)——前景のクロックを 1 つも消費しない。Reset の 1 クロックが波形から消える。 / **Exactly 8 clk, exactly 1:1.** The queued Reset fires ON the timeup boundary and consumes no foreground clock — first silicon confirmation of the independent-channel reservation (C3-F22 rev. 2026-07 / RH015). |
| 副次予言: Stay Set が tick と重なっても計数は正しい(RH028 ①: FG Stay Set の tick 優先インクリメント、P=1 では毎回重なる)。 |

---

## Scene 7 — Stay を 2 に詰める: 崖だった場所 / Tightening Stay to 2: where the cliff used to be

**操作:** addr4 ← `00010021`(窓付き Stay-2)。窓のスキャン(Stay Set＋Prog End＋Reset 予約)
が Stay 値を追い越す——**わざと下限制約(N ≥ スキャン長+1)を破る**。

| Prediction / 期待値(負検証の映像化、「生々しい失敗」第一号) |
|---|
| **暴走はしない。** RH028 ③(S_WAIT 判定の >= 化)により、カウンタが目標を追い越していても最初の判定機会で発火する。点灯側は「2 clk」ではなく**スキャン所要ぶん(予測: 4 clk 前後、±1 clk の不確かさを明記して実測)**に張り付き、デューティは 1:1 に戻らない——**静かに、しかし正直に、仕様の下限を破った代償を払う波形**。 / **No runaway.** The >= rule (RH028 ③) fires at the first opportunity; the ON side pins to the scan length (predicted ~4 clk ± 1 — to be measured), and the duty honestly refuses to be 1:1. |
| **反実仮想(口上で):** RH028 以前の `==` 判定なら、追い越したカウンタは 12bit を一周するまで帰れず——**約 4096 tick、点灯しっぱなしの暗礁**だった。EXP1/EXP5 が机上で落ちた崖を、実機では「つまずき」で済む姿として見せる。 / Before RH028 this was a ~4096-tick wrap catastrophe (EXP1/EXP5); the camera now sees a stumble where there used to be a cliff. |

**行使セル:** §3.6 最低ステイ制約、窓付き下限 N≥スキャン長+1(RH028 文書)、>= 最早発火則。

---

## Scene 8 — トリック手法の見本市と、一つの罠 / A bazaar of trick idioms — and one trap

**8-a: Reset の 1 クロックを戦力化する(3語・4 clk・12.5 MHz):**

```
addr0: 00000021   消灯 Stay-2          (2 clk)
addr1: 00010011   点灯 Stay-1          (1 clk — 裸 Stay-1@P=1 = 正確に 1 clk)
addr2: 00010000   点灯 Reset           (1 clk、tsig 点灯側!)
```

| Prediction: 周期 4 clk、**1:1**、12.5 MHz。Reset の 1 クロックを tsig で点灯側に雇い入れ、Stay-1 と合わせて 2 clk を作る——欠陥だったものが部品になる。 |
|---|

**8-b: Jump 版 —— ここに罠がある(白箱からの警告):**

大中さん案の `00000021` / `00010003`(Jump で 0 番地へ)は、**そのままでは発振しない**と
予言します。

| Prediction / 期待値(SURPRISE 枠、撮る価値がむしろ高い) |
|---|
| `00010003` = Jump・operand **0**。しかし operand 0 の Jump は**直値ゼロエスケープ = 間接ジャンプ**(literal-zero-as-escape)であり、コアは S_IND に入って `indirect_ready` を待つ。ハーネスが間接バスを駆動していなければ**LED は点灯のまま静止**——発振しない。 / `Jump 0` is the indirect escape, not a jump to address 0. Without an external driver on the indirect bus, the core parks in S_IND: the LED freezes ON. |
| **救出は二通り(どちらも画になる):** (A) プログラムを 1 番地始まりに引っ越し、`00010013`(Jump→1)にする——周期 3 clk(2:1、16.67 MHz)の予言で再挑戦。 (B) 罠を**主役に昇格**: スイッチ/外部ロジックで indirect_data と indirect_ready を人力駆動し、「ジャンプ先を手で差し込む」画を撮る——間接アドレッシングの実機デモが一本増える。 |

---

## Scene 9 — フィナーレ: 2 語の 2 分周器、25 MHz / Finale: the two-word divide-by-2 at 25 MHz

**操作:** メモリを消し、2 語だけ:

```
addr0: 00000011   消灯 Stay-1    (1 clk)
addr1: 00010000   点灯 Reset     (1 clk)
```

| Prediction / 期待値 |
|---|
| **周期 2 クロック = 40 ns、正確に 1:1 の 25 MHz 矩形波**——システムクロックの究極の 2 分周。裸 Stay-1@P=1 = 正確に 1 クロック(RH028 ②)が、これ以上ないほど雄弁な形でオシロに現れる。「前景はステイ持続時間の裸の羅列である——1 に至るまで」を、波形そのもので言い切って終わる。 / **A clean 25 MHz square, exactly 1:1** — the ultimate divide-by-2, and the loudest possible statement of RH028's exactness. |

**締めの口上:** 「ここまで、再コンパイルは P の変更 2 回だけ。残りは全部、走っている
シリコンへの生打ち——インプロビゼーション・デザインである。」

---

## Appendix A — ゲスト AI セグメント(次回以降の仕込み) / Guest-AI segment (for later episodes)

各段階のお題(「P=1 で 1:1 の 6.25 MHz を作れ」等)を、リポジトリ URL とともに ChatGPT・
Gemini 等へ渡し、返ってきたプログラムを**無修正で**実機投入する。ルール: (1) 与えるのは
リポジトリと課題文のみ、(2) 生成物は改変せず走らせる、(3) 失敗はそのまま放送する。
失敗は恥ではなく **Open Prompt の抽象完全性プローブ**(本プロジェクト既定の原則: LLM の
幻覚は仕様の穴の診断器)——どの AI がどのセルで転ぶかが、そのまま Layer 1 の改訂素材になる。

## Appendix B — 本話が 🟢 にする(かもしれない)マトリクス行 / Matrix rows this episode may turn green

急がない方針は堅持しつつ、記録だけしておく: RH028 実機確認(S5・S9)、C3-F22 改訂
(独立並列 Que Reset)実機確認(S6)、>= 最早発火則の負検証(S7)、間接ゼロエスケープの
実機挙動(S8-b、経路 B を選んだ場合)。「楽しんでいるうちにやがて埋まっていた」の第一回分。

---

*Prediction 欄は撮影前に確定し、以後編集しない。外れたら外れたまま Observed に記録する——*
*それが一番おいしい回である。 / Predictions are frozen before filming. A missed prediction*
*is not a retake; it is the best possible episode.*

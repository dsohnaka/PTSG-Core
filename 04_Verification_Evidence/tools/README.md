# PTSG amanuensis tools / 祐筆の道具箱 — 2026-07-23

Tools precipitated by the work, not planned in advance — committed with the evidence
and documents they touched, per the "tools live with their evidence" rule.
計画されてではなく作業から析出した道具たち——「道具はエビデンスと同居する」の規律に従い、
触れた証拠・文書とともにコミットされる。

| Tool | Born | Why it exists / 出自 | Suggested home | License |
|---|---|---|---|---|
| `ptsg_vcd_decode.py` | 2026-07-22 | Decoded the SignalTap VCDs for the 1 Hz grid-absorption verdict; reassembles bit-level $var dumps into clock-numbered bus timelines. Rerun the verdict with one command. / 1 Hz グリッド吸収判決の VCD 復号のために誕生。判決の再演が一コマンドになる。 | `04_Verification_Evidence/tools/` | CC0 |
| `ptsg_patch.py` | 2026-07-23 | Distillation of the L1 write-back discipline: every anchor must match exactly once; nothing is written until every check passes. Born of the 2026-07-07 partial-save accident. / L1 書き戻し規律の蒸留(count==1・全或無)。2026-07-07 の部分保存事故から誕生。 | `tools/` (repo root) | CC0 |
| `examples/apply_edits_Agroup_2026-07-09.py` | 2026-07-09 | The surviving single-purpose instance of the pattern: the actual A-group codification + trace-① correction script (32 edits, hardcoded). Kept as a historical record and as a worked example of what `ptsg_patch.py` generalizes. / 型の生き残った単用途実例: A群成文化＋トレース①訂正の実スクリプト(32編集・焼き込み)。歴史記録かつ汎用化の元例として保存。 | `02_Reasoning_Traces/_worksheets/` or alongside the trace | CC0 |

Honest note / 正直な注記: the patch scripts for the README overhaul and the 442-ALM
unification were written as inline one-shots and not preserved as files; their edits
survive in the committed documents, and their discipline survives in `ptsg_patch.py`.
README 刷新と 442 ALM 統一のパッチはインラインの一回限りで、ファイルとしては残っていない。
編集結果はコミット済み文書に、規律は `ptsg_patch.py` に生きている。

Next to precipitate (planned by need, not by roadmap) / 次に析出予定(必要駆動):
the edge-merge compiler for multi-channel duty (duty-idioms Hooks A+C), which grows
toward the score compiler and, someday, the piano-roll IDE (Hook E).
多チャネルデューティの縁マージ・コンパイラ(流儀トレース Hook A+C)——楽譜コンパイラを経て、
いつかピアノロール IDE(Hook E)へ。

# Conformance Suite / 適合スイート

> Verification PTSG programs — **evidence, not pedagogy.** Each program is a stimulus
> designed to exercise a specific Layer 1 decision and produce a falsifiable result. This is
> distinct from Layer 3 `examples/`, which are teaching references showing how to *use* the
> Core.
>
> 検証用 PTSG プログラム——**証拠であって教育ではない。** 各プログラムは特定の Layer 1 決定を
> 行使し反証可能な結果を生むよう設計されたスティミュラスである。コアの*使い方*を示す教育用
> 参照である Layer 3 `examples/` とは別物。

## Structure / 構造

Each `<feature>/` directory contains:

各 `<feature>/` ディレクトリは以下を含む:

- `program.hex` / `program.mif` — the stimulus instruction list (`.hex` for simulation /
  `.mif` for Quartus & In-System Memory Content Editor). / スティミュラス命令列。
- `expected.md` — **written before observation**: what Layer 1 predicts, the hypothesis
  under test, which signals to probe, and the PASS / ANOMALY criteria. / **観察前に記述**:
  Layer 1 の予測、検証下の仮説、観測すべき信号、PASS / ANOMALY 基準。

The matching evidence (VCD + `observation.md`) lives under `../modelsim/runs/` or
`../signaltap/`, linked from `../conformance_matrix.md`.

対応するエビデンス(VCD + `observation.md`)は `../modelsim/runs/` または `../signaltap/`
配下にあり、`../conformance_matrix.md` からリンクされる。

## Entries / 項目

| Directory | Target (Layer 1) | Source | Status |
|---|---|---|---|
| `prescaler_phase_measurement/` | C4-T3 phase / C4-F1 | Hook A (2026-06-11) | program + expected ready; awaiting run |
| `match_flag_assertions/` | C3-F18, C4-F2 | Audit hole #4 | planned |
| `nested_call_two_levels/` | C5-F2, external-stack path | Audit hole #2 | planned |
| `prog_end_queued_band/` | C3-F2/F3/F4, C3-F19 | Audit hole #1 | planned |
| `base_set_idempotency_probe/` | C3-F11 | Build Log #5 self-flag | planned |
| `insertion_during_long_stay/` | C3-F20, C3-F12 | Audit hole #3 | planned |

## Relationship to Layer 3 examples / Layer 3 examples との関係

A program is born here as a conformance stimulus. Once it passes verification **and** reads
well as a demonstration, a refined copy is **promoted** to Layer 3 `examples/` as a teaching
reference, carrying a link back to the Layer 4 evidence that earned the promotion. The
direction is one-way: **Layer 4 proves, Layer 3 teaches.**

プログラムはここで適合スティミュラスとして生まれる。検証を通過し**かつ**実演として読みやすく
なったら、精錬された複製が Layer 3 `examples/` へ教育用参照として**昇格**し、昇格をもたらした
Layer 4 エビデンスへのリンクを携える。方向は一方向: **Layer 4 が証明し、Layer 3 が教える。**

## Encoding quick reference / エンコーディング早見

32-bit word: `D0–D3` opcode, `D4–D15` operand, `D16–D31` timing signals (or extended
operand for internal Globals).

| Opcode | Encoding | Note |
|---|---|---|
| Stay N | `(tsig<<16) \| (N<<4) \| 1` | N=0 ⇒ 4096 |
| Branch K | `(tsig<<16) \| (K<<4) \| 2` | K=0 ⇒ self-loop / wait |
| Jump A | `(tsig<<16) \| (A<<4) \| 3` | A=0 ⇒ indirect |
| Global internal subop S | `(D16_31<<16) \| (S<<8) \| 0` | S: 0=Reset 1=BaseSet 2=StaySet 3=Return 4=Call 5=Loop 6=ProgEnd 7=NOP |

See Layer 1 Chapters 2–4 for full semantics. / 完全な意味論は Layer 1 第2-4章を参照。

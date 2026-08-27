# Free-running fruits (RH029/RH030) — reconciliation package, 2026-08-27
# フリーランの果実（RH029/RH030）— 辻褄合わせ一式

Drop-in layout mirroring `dsohnaka/PTSG-Core`. All items PROVISIONAL unless marked RULED.

| Path | What | Status |
|---|---|---|
| `02_Reasoning_Traces/2026-08-27_ptsg-free-running-fruits.md` / `.json` | Layer 2 trace (CC0). Closes Hook E of `2026-06-23_ptsg-reset-command-bands`. DP 6 / Themes 3 / Hooks 5 / Key outputs 10, MD-JSON count-verified. | PROVISIONAL; DP-6 item 1 RULED (`==` stays, fail-loud) |
| `01_Architecture/CHANGES_Layer1_free-running-fruits_RH029-030.md` | Layer 1 write-back proposals for Ch4 (§4.7, new §4.8b, §4.12) and Ch5 (§5.2, §5.10, §5.12), Ch6 placeholder. | PROVISIONAL; multi-LLM review |
| `03_Sample_Implementations/RH029-030_header_patch.md` | `ptsg_core.v` header entries RH029/RH030 (2026-07-16), Tie-lean line, inline tags. | **CANONICAL** (architect, 2026-08-27); not yet applied — source frozen during Layer 4 |

Suggested final location of the patch file: `03_Sample_Implementations/ptsg_core_verilog/RH029-030_header_patch.md` (next to `ptsg_core.v`), per the "tools live with their evidence" rule.

Pending (batched Layer 2 review at the next Layer 4 checkpoint): Hook C (zero-check timing; `prescaler_output`; `rst` on `presc_tick`/`presc_valueM`) plus the architect's own Live Session #1 findings.

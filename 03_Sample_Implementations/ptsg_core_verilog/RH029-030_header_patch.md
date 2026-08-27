# ptsg_core.v — header / tag corrections for RH029 and RH030 (proposed)
# ptsg_core.v — RH029/RH030 のヘッダ・タグ修正案

> **Architect-approved as canonical, 2026-08-27** ("これが正です"). Entry dates confirmed by the architect: 2026-07-16. **Not yet applied to `ptsg_core.v`:** the source is under Layer 4 verification (Live Session #1 retakes) and is deliberately left untouched; this patch accompanies the source until the batched Layer 2 review at the next Layer 4 checkpoint, where it is applied together with the Hook C rulings and the architect's own accumulated findings.

## A. REVISION HISTORY entries (append after 028, same column format)

```
// 029 2026-07-16       Arch. Ohnaka  Add : Externally settable prescaler (C4-T2, reference form "B'": pin-level
//                                          value with parameter fallback, PROVISIONAL). New ports prescaler_value
//                                          (tri0 input; 0/unconnected => PRESCALE parameter, i.e. option-A
//                                          behaviour at zero cost) and prescaler_output (reserved, see note).
//                                          presc_valueM registers (prescaler_value - 1) so the "-1" is off the
//                                          compare path; presc_tickP compares presc_cnt against presc_valueM
//                                          (or PRESCALE-1 at zero). Premise (architect, 2026-08-27): the
//                                          prescaler counter value is not for external use; the prescaler is a
//                                          base-frequency generator only. Trace: 2026-08-27_ptsg-free-running-
//                                          fruits (closes 2026-06-23 reset-command-bands Hook E).
// 030 2026-07-16       Arch. Ohnaka  Mod : One-clock registered tick (Fmax) + raw-tick export (sync).
//                                          presc_tick <= presc_tickP: the internal tick is now a registered
//                                          one-clock pulse; every in-core consumer uses it, so the whole tick
//                                          grid shifts by exactly one clock and all intervals / C4-F9 phase-lock
//                                          / RH028 collision rules are unchanged (silicon re-confirmation:
//                                          Hook A). presc_cnt rolls over on the raw presc_tickP. prescaler_match
//                                          now exports the RAW (pre-register) tick, one clock ahead of the
//                                          internal tick; consumers must register it — a slave that does so
//                                          lands coincident with this core's internal tick. Sync delivered =
//                                          period-sharing (same prescaler_value + common rst + C3-F21);
//                                          tick-following slave NOT provided (Chapter 6).
//                                          RULING (architect, 2026-08-27): presc_tickP deliberately uses ==,
//                                          NOT >=. A prescaler that runs past its terminal is a fatal fault;
//                                          a loud 2^16-wrap is preferred to a quiet small error (fail-loud).
//                                          This is the intended asymmetry with RH028's >= on the stay counter.
//                                          OPEN (architect): prescaler_value==0 test is combinational while presc_valueM is
//                                          registered (1-clk mismatch at 0<->non-0); prescaler_output is
//                                          declared but undriven; presc_tick/presc_valueM have no rst.
```

## B. Tie-lean line in the header (L45)

```
-    C4-T2 prescaler config ....... compile-time fixed (PRESCALE parameter)
+    C4-T2 prescaler config ....... pin-level prescaler_value with PRESCALE parameter
+                                   fallback (reference form "B'", RH029, PROVISIONAL)
```

## C. Parameter block comment (L273)

```
-    // ---- Prescaler (C4-T2 option A: compile-time fixed) ---------------------
+    // ---- Prescaler (C4-T2 form B': pin-level value, PRESCALE = fallback) -----
```

## D. Inline tags

```
L457  //RH029: prescaler_value override (C4-T2 option B, PROVISIONAL)
   -> //RH029: prescaler_value override (C4-T2 form B', PROVISIONAL); raw tick

L458  // RH030    -cycle pulse, synchronous to clk, at every prescaler tick
   -> // RH030: registered one-clock pulse, one clk after presc_tickP; the only tick the FSM uses

L579  assign prescaler_match = presc_tickP;    // RH030: prescaler_value override (C4-T2 option B, PROVISIONAL)
   -> assign prescaler_match = presc_tickP;    // RH030: RAW tick export (1 clk ahead of presc_tick; consumer registers)

L633-636  (two RH tags inside the always block — architect ruling 2026-08-27)
    always @(posedge clk) begin
        // RH030: registered one-clock tick, one clk after presc_tickP
        presc_tick   <= presc_tickP;
        // RH029: pre-decremented compare value, registered off the compare path
        presc_valueM <= prescaler_value - 1;
    end
```

## E. Items intentionally NOT patched here (await Hook C ruling)

- ~~`==` → `>=` in `presc_tickP`~~ — **RULED 2026-08-27: stays `==` (fail-loud)**
- zero-check on the registered path
- `prescaler_output` assignment (or removal)
- `rst` for `presc_tick` / `presc_valueM`

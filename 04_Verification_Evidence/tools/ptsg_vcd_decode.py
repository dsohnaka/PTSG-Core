#!/usr/bin/env python3
# ptsg_vcd_decode.py — PTSG evidence VCD decoder / PTSG エビデンス VCD 復号器
#
# Decodes SignalTap/Quartus VCD exports into a clock-numbered transition timeline:
# reassembles per-bit $var declarations into buses (state_num, presc_cnt, stay_cnt,
# timing_signals, ...), forward-fills sample state, and prints every change of the
# watched signals with the full register context at that clock.
# Born 2026-07-22 to adjudicate the 1 Hz grid-absorption claim
# (observation_blinky_1Hz_prec6250_signaltap.md); committed with the evidence it
# touched, per the tools-live-with-evidence rule. Stdlib only. License: CC0 (Layer 4).
#
# SignalTap/Quartus の VCD 書き出しを、クロック番号つき遷移タイムラインへ復号する:
# ビット単位の $var 宣言をバスへ再構成し、サンプル状態を前方充填し、監視信号の
# 全変化をその時点のレジスタ文脈つきで印字する。2026-07-22、1 Hz グリッド吸収の
# 審理のために誕生。「エビデンスに触れた道具はエビデンスと一緒にコミットする」の
# 規律に従い、証拠と同居する。標準ライブラリのみ。ライセンス: CC0(Layer 4)。
#
# Usage / 使い方:
#   python3 ptsg_vcd_decode.py capture.vcd
#   python3 ptsg_vcd_decode.py capture.vcd --watch state_num timing_signals presc_tick
#   python3 ptsg_vcd_decode.py capture.vcd --list          (signal inventory only)
#   python3 ptsg_vcd_decode.py capture.vcd --clock-ps 20000 --context presc_cnt stay_cnt

import argparse, re, sys

def parse_vcd(path):
    with open(path, encoding="utf-8", errors="replace") as f:
        txt = f.read()
    ts = re.search(r'\$timescale\s+([\d]+)\s*(\w+)', txt)
    unit = {"s":10**12, "ms":10**9, "us":10**6, "ns":10**3, "ps":1}
    ts_ps = int(ts.group(1)) * unit.get(ts.group(2), 1) if ts else 1
    buses = {}
    for m in re.finditer(r'\$var\s+\S+\s+\d+\s+(\S+)\s+([^\s$]+?)(?:\[(\d+)\])?\s+\$end', txt):
        code, name, bit = m.group(1), m.group(2), m.group(3)
        buses.setdefault(name, {})[int(bit) if bit else 0] = code
    body = txt[txt.find('$enddefinitions'):]
    t, cur, hist = None, {}, []
    for line in body.splitlines():
        line = line.strip()
        if line.startswith('#'):
            if t is not None: hist.append((t, dict(cur))); cur = {}
            t = int(line[1:])
        elif line and line[0] in '01xz' and not line.startswith('$'):
            cur[line[1:]] = line[0]
        elif line.startswith('b'):                       # vector dump: bVAL code
            val, code = line[1:].split()
            for i, ch in enumerate(reversed(val)):
                buses_rev = code                          # vector codes map whole bus
                cur[(code, i)] = ch
    if t is not None: hist.append((t, dict(cur)))
    return ts_ps, buses, hist

def decode(ts_ps, buses, hist, clock_ps):
    state, rows = {}, []
    for t, ch in hist:
        state.update(ch)
        row = {"t": t, "clk": (t * ts_ps) // clock_ps if clock_ps else t}
        for b, bits in buses.items():
            v, ok = 0, True
            for i, c in bits.items():
                s = state.get(c, state.get((c, i), 'x'))
                if s not in '01': ok = False; break
                v |= int(s) << i
            row[b] = v if ok else None
        rows.append(row)
    return rows

def main():
    ap = argparse.ArgumentParser(description="PTSG evidence VCD decoder")
    ap.add_argument("vcd")
    ap.add_argument("--watch", nargs="+", default=["state_num", "timing_signals", "presc_tick"],
                    help="signals whose changes are reported / 変化を報告する信号")
    ap.add_argument("--context", nargs="+", default=["presc_cnt", "stay_cnt"],
                    help="registers printed alongside each change / 併記するレジスタ")
    ap.add_argument("--clock-ps", type=int, default=20000,
                    help="system clock period in ps (default 20000 = 50 MHz)")
    ap.add_argument("--list", action="store_true", help="list signals and exit / 信号一覧のみ")
    a = ap.parse_args()

    ts_ps, buses, hist = parse_vcd(a.vcd)
    if a.list:
        print(f"# {a.vcd}: timescale {ts_ps} ps, {len(hist)} samples")
        for b in sorted(buses): print(f"  {b} [{len(buses[b])} bit]")
        return
    rows = decode(ts_ps, buses, hist, a.clock_ps)
    missing = [w for w in a.watch if w not in buses]
    if missing:
        print(f"! not in this capture: {missing} (use --list)", file=sys.stderr)
    print(f"# {a.vcd}: {len(rows)} samples, 1 sample = {ts_ps} ps, clock = {a.clock_ps} ps")
    prev = None
    for row in rows:
        if prev:
            for w in a.watch:
                if w in buses and row.get(w) != prev.get(w):
                    ctx = "  ".join(f"{c}={row.get(c)}" for c in a.context if c in buses)
                    print(f"clk {row['clk']:>8}  {w}: {prev.get(w)} -> {row.get(w)}   [{ctx}]")
        prev = row

if __name__ == "__main__":
    main()

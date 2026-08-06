#!/usr/bin/env python3
# ptsg_patch.py — asserted all-or-nothing text patcher / assert付き全或無テキストパッチャ
#
# The distillation of the L1 write-back discipline used in the PTSG-Core sessions:
# every replacement must match EXACTLY ONCE (count==1); all replacements are applied
# in memory first; files are written ONLY after every check passes. Born of a real
# accident (2026-07-07): a mid-script exception left successful edits unsaved while
# the session believed otherwise. This tool makes that failure impossible.
# Stdlib only. License: CC0 (it edits the CC0 layers; the architect may rule otherwise).
#
# PTSG-Core セッションの L1 書き戻し規律の蒸留: 全置換は正確に1回一致(count==1)、
# 全置換をまずメモリ上で完遂し、全検査通過後にのみファイルへ書く。実際の事故
# (2026-07-07: スクリプト途中例外で成功済み編集が未保存のまま、セッションは保存済みと
# 誤認)から生まれた。本ツールはその失敗を構造的に不可能にする。標準ライブラリのみ。
# ライセンス: CC0(CC0層を編集する道具;アーキテクトの裁定があれば従う)。
#
# Patch spec (JSON) / パッチ仕様(JSON):
#   [ {"file": "path/to/target.md",
#      "edits": [ {"old": "exact unique string", "new": "replacement"}, ... ]}, ... ]
#
# Usage / 使い方:
#   python3 ptsg_patch.py spec.json --check      # dry run: verify all anchors, write nothing
#   python3 ptsg_patch.py spec.json --out DIR    # write patched copies into DIR
#   python3 ptsg_patch.py spec.json --in-place   # overwrite originals (after all checks)

import argparse, json, os, sys

def main():
    ap = argparse.ArgumentParser(description="asserted all-or-nothing text patcher")
    ap.add_argument("spec")
    ap.add_argument("--check", action="store_true")
    ap.add_argument("--out")
    ap.add_argument("--in-place", action="store_true")
    a = ap.parse_args()
    spec = json.load(open(a.spec, encoding="utf-8"))
    bufs, n, errs = {}, 0, []
    for item in spec:
        fp = item["file"]
        s = bufs.get(fp)
        if s is None:
            s = open(fp, encoding="utf-8").read()
        for e in item["edits"]:
            c = s.count(e["old"])
            if c != 1:
                errs.append(f"[{fp}] count={c} (need 1): {e['old'][:70]!r}")
                continue
            s = s.replace(e["old"], e["new"])
            n += 1
        bufs[fp] = s
    if errs:
        print(f"FAILED — {len(errs)} anchor(s) did not match exactly once; NOTHING was written:", file=sys.stderr)
        for e in errs:
            print("  " + e, file=sys.stderr)
        sys.exit(1)
    if a.check:
        print(f"CHECK OK — {n} edits across {len(bufs)} file(s); all anchors unique; nothing written.")
        return
    for fp, s in bufs.items():
        dst = fp if a.in_place else os.path.join(a.out or "patched", os.path.basename(fp))
        d = os.path.dirname(dst)
        if d:
            os.makedirs(d, exist_ok=True)
        open(dst, "w", encoding="utf-8").write(s)
        print(f"wrote {dst}")
    print(f"OK — {n} edits, {len(bufs)} file(s), written only after all checks passed.")

if __name__ == "__main__":
    main()

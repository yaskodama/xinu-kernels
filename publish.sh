#!/bin/bash
# 三板のカーネル像を GitHub に上げ、manifest.json（版・大きさ・md5・fnv64）を作る。
# 板は airilab.app 経由（http）でこの manifest を読み、自分の build id と比べる。
#   ./publish.sh            三板とも手元の compile/ から
#   ./publish.sh pi5        一板だけ
set -euo pipefail
cd "$(dirname "$0")"
src_of() { case "$1" in pi5) echo "$HOME/projects/xinu-rpi5/compile/kernel_2712.img";; pi4) echo "$HOME/projects/xinu-rpi4/compile/kernel8.img";; pi3) echo "$HOME/projects/xinu-rpi3/compile/xinu.boot";; esac; }
dst_of() { case "$1" in pi5) echo "pi5/kernel_2712.img";; pi4) echo "pi4/kernel8.img";; pi3) echo "pi3/kernel.img";; esac; }
boards="$*"; [ -z "$boards" ] && boards="pi5 pi4 pi3"
for b in $boards; do mkdir -p "$b"; cp "$(src_of $b)" "$(dst_of $b)"; done
python3 - <<'PY'
import json, hashlib, os, re, subprocess, datetime
man = {}
try: man = json.load(open('manifest.json'))
except Exception: pass
man.setdefault('boards', {})
for b, path in {'pi5':'pi5/kernel_2712.img','pi4':'pi4/kernel8.img','pi3':'pi3/kernel.img'}.items():
    if not os.path.exists(path): continue
    data = open(path,'rb').read()
    # build id は kversion.c の __DATE__ " " __TIME__（"Sep 13 2026 17:40:44"）
    m = re.search(rb'([A-Z][a-z]{2} [ \d]\d \d{4} \d\d:\d\d:\d\d)', data)
    build = m.group(1).decode() if m else ''
    h = 0xcbf29ce484222325
    for c in data: h = ((h ^ c) * 0x100000001b3) & 0xFFFFFFFFFFFFFFFF
    man['boards'][b] = { 'file': path, 'size': len(data), 'md5': hashlib.md5(data).hexdigest(),
                         'fnv64': '%016x' % h, 'build': build }
man['updated'] = datetime.datetime.now(datetime.timezone.utc).isoformat(timespec='seconds')
json.dump(man, open('manifest.json','w'), indent=2, ensure_ascii=False)
for b, e in man['boards'].items(): print(b, e['build'], e['size'], e['md5'][:8], e['fnv64'])
PY
git add -A
git commit -q -m "kernels: $(python3 -c "import json;m=json.load(open('manifest.json'));print(', '.join(b+' '+e['build'] for b,e in m['boards'].items()))")" || true
git push -q origin main 2>/dev/null || echo "(push later: git push -u origin main)"

# xinu-kernels

三板（Pi 3 / Pi 4 / Pi 5）の Embedded Xinu カーネル像と `manifest.json`。
板は `https://airilab.app/api/xinu/manifest`（板からは http）でこれを読み、自分の build id と
比べて「最新かどうか」を知り、違えば `…/api/xinu/kernel?board=pi4&off=&len=` で取って
起動媒体に書き、再起動する（右クリック → 最新を確認）。

- `publish.sh [pi5|pi4|pi3]` — 手元の `compile/` の像を写して manifest を作り、push。
- `build` は kversion.c の `__DATE__ __TIME__`。`fnv64` は板が自分で計算して照合する簡易ハッシュ。

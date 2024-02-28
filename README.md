# CuNNy - Convolutional upscaling Neural Network, yeah!

Nice, small, and fast CNN-based upscaler. Works by refining the output of FSR
for fast and brilliant images.

Currently very new and immature 😭.

Supports exporting to an mpv ~~meme~~shader!

# Usage

Use them like any other mpv usershader.

The order of best quality -> worst quality is `3x32 -> 2x32 -> 1x32 -> 1x16 ->
1x8 -> 1x4 -> 0x4`.

Conversely the order of fastest -> slowest would be the reverse, with `0x4`
being the fastest and `3x32` being the slowest.

There are `RCAS` variants that provide slightly sharper results for a very small
cost in performance (which becomes negligible the bigger the model).

# Training

Tested training with PyTorch nightly. If any errors arise try using nightly.

Prepare data by running `sh scripts/build.sh` and then `sh scripts/proc.sh
<input-folder> <use-rcas>`.

To train `py train.py <N> <D>` where `N` is the number of internal convolutions
and `D` is the number of feature layers.

Convert the resulting model by running `py convert.py <models/model.pt>`

Trains very fast on my machine.

# Quality

Good.

TODO: add examples

# License

LGPL v3

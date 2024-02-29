# CuNNy - Convolutional upscaling Neural Network, yeah!

Nice, small, and fast CNN-based upscaler. Works by refining the output of FSR
for fast and brilliant images.

Currently very new and immature 😭.

Supports exporting to an mpv ~~meme~~shader!

And now a Magpie effect!

# Usage

The order of best quality -> worst quality is `3x32` -> `2x32` -> `1x32` ->
`1x16` -> `1x8` -> `1x4` -> `0x4`.

Conversely the order of fastest -> slowest would be the reverse, with `0x4`
being the fastest and `3x32` being the slowest.

Variants:
- `RCAS`: Provide slightly sharper results for a very small cost in performance
  (which becomes negligible the bigger the model).
- `DS`: Trained on images downsampled with Hermite and compressed to JPEG quality
  75. It's kinda splodgy, but seems okay on some shows.
- `NVL`: Trained on VN screenshots/CG. Amazing results. Will probably work great
   on regular artwork as well.

# Training

Tested training with PyTorch nightly. If any errors arise try using nightly.

Prepare data by running `sh scripts/build.sh`, then `sh scripts/split.sh
<input-folder> <output-128-grids>`, then `sh scripts/proc.sh <128-grids>
<use-rcas>`.

To train `py train.py <N> <D>` where `N` is the number of internal convolutions
and `D` is the number of feature layers.

Convert the resulting model to an mpv shader by running
`py mpv.py <models/model.pt>`.

Convert the resulting model to a Magpie effect by running
`py magpie.py <models/model.pt>`.

Trains very fast on my machine.

# Quality

Good.

TODO: add examples

# License

LGPL v3

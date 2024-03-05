# CuNNy - Convolutional upscaling Neural Network, yeah!

Nice, small, and fast realtime CNN-based upscaler.

Currently very new and immature 😭.

Supports exporting to an mpv ~~meme~~shader!

And now a Magpie effect!

# Usage

The order of best quality -> worst quality is sorted by the 2nd number first,
then the first number. So `16x16` > `4x16` > `16x8`.

Conversely the order of fastest -> slowest would be the reverse, with `0x4`
being the fastest and `3x32` being the slowest.

Variants:
- `RCAS`: Provide slightly sharper results for a very small cost in performance
   (which becomes negligible the bigger the model).
- `DS`: Trained to denoise & sharpen images.
- `NVL`: Trained on VN screenshots/CG.

# Training

Tested training with PyTorch nightly. If any errors arise try using nightly.

Prepare data by running `sh scripts/build.sh`, then `sh scripts/split.sh
<input-folder> <output-128-grids>`, then `sh scripts/proc.sh <128-grids>
<use-rcas>`.

To train `py train.py <data> <N> <D>` where `N` is the number of internal
convolutions and `D` is the number of feature layers.

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

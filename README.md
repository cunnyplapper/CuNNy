# CuNNy - Convolutional upscaling Neural Network, yeah!

Nice, small, and fast CNN-based upscaler. Works by refining the FSR EASU pass
for fast and brilliant images.

Currently very new and immature 😭.

Supports exporting to an mpv ~~meme~~shader!

# Training

Tested training with PyTorch nightly. If any errors arise try using nightly.

Prepare data by running `sh scripts/build.sh ` and then `sh scripts/proc.sh
input-folder`.

To train `py train.py N D` where N is the number of internal convolutions and D
is the number of feature layers.

Convert the resulting model by running `py convert.py models/out.pt`

Trains very fast on my machine.

# Quality

Good.

TODO: add examples

# License

LGPL v3

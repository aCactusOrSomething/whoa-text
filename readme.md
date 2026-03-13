# WHOA TEXT

I'm using the WGPU library to render the text "Whoa!" in 3d letters, with each letter rendered with different shading techniques and a light source that moves with the user's mouse.

If your curious, some info on the shading techniques used for each:

- **W**: stylized, uses a halftone effect for unlit sections.
- **H**: gooch
- **O**: blinn-phong
- **A**: gouraud
- **!**: debug rainbow effect

## How to build

If you want to run this as a desktop application, simply use the standard cargo build command:

`cargo build`

i used wasm-pack for generating the web assembly code that runs in a browser. if you've installed it, you don't need anything special there either:

`wasm-pack build --target web`

you can add `--release` to either command to build for release. Note that `cargo.toml` specifies some optimizations when built this way - if you'd rather compile quickly, delete those. the code should still perform fine.

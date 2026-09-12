# Noro module template

A starting point for a [Noro](https://github.com/NoroProject/noro-shared) module, as a
GitHub template: press **Use this template** and you get this repository with its CI
already wired up.

If you do not need the repository — only the module — `cargo noro new my-module` gives
you the same files in a directory, offline, and is the shorter path.

**Documentation: https://noroproject.github.io/noro-shared/**

## What you need

```bash
cargo install --git https://github.com/NoroProject/noro-shared.git cargo-noro
```

Plus the Rust toolchain (`rust-toolchain.toml` here adds the wasm target for you), and
[Bun](https://bun.sh) for the mini-app. [`wasm-opt`](https://github.com/WebAssembly/binaryen)
is optional: it cuts the package by about a third and the build works without it.

## Make it yours

```bash
./scripts/rename.sh my-module "My Module"
```

The identifier lands in four places that have to agree — the crate name, the manifest
`id`, the locale key prefix and the mini-app package — so it is one script rather than
four edits. (`cargo noro new` does the same thing at creation time; this script exists
because **Use this template** hands you a repository already named something else.)

Pick it carefully: `id` becomes the Postgres schema `mod_<id>`, the prefix of every
locale key you ship, the path of your endpoints, and the root of your permission nodes.

## Build it

```bash
cargo noro package          # → dist/my-module.noromod
```

Upload that file in the admin panel under **Modules**, grant what it asks for, enable it.
Nothing is recompiled and the master is not restarted.

## Develop it

```bash
cargo noro dev              # rebuild on every save
```

Then point the master at this folder — **Modules → Dev mode**. It reads the wasm, the
mini-app and the locales from disk and reloads the module when you rebuild, so there is
no packaging and no uploading in the loop.

## What is in here

```
manifest.toml       identity and the capabilities you ask for
src/lib.rs          your handlers — events, endpoints, settings
ui/App.vue          the page in the panel
ui/app.js           the mini-app entry point
locales/{en,ru}.ftl your text, keys prefixed mod-<id>-
scripts/rename.sh   renaming, for when you came via **Use this template**
```

`src/lib.rs` ships one working example of each thing a module can do: a settings field,
a one-off setup step, an event handler and an endpoint. Delete what you do not need —
none of it is required for the module to load.

## The part worth knowing before you start

Events, endpoints and tasks are declared **in code**, with attributes. The event name
comes from your handler's argument type:

```rust
#[event]
fn on_join(e: PlayerJoined) -> Result<()> { Ok(()) }
```

So subscribing to one event while accepting another's struct does not compile, and no
handler name is repeated as a string anywhere. The
[event catalog](https://noroproject.github.io/noro-shared/reference/events/) lists every
event next to the struct that carries it.

The manifest holds only what the master must know *before* running your code: who you
are, which ABI you need, and what you ask for.

## Licence

The template is MIT: what you build from it is yours to licence as you like.

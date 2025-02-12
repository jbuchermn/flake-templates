# Nix templates

## Clash
See [Clash](https://github.com/clash-lang/clash-compiler). This template uses their provided flake, currently on version ``1.9.0``. Simply remove the overlay and change cabal version specification to use nixpkgs provided ``1.8.1``.

To set up use

```bash
nix flake init -t github:jbuchermn/flake-templates#clash
```

Build using

```bash
nix build .#sample
```

Or enter a dev shell with properly configured ``haskell-language-server``

```bash
nix develop
```

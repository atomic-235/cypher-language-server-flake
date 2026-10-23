# cypher-language-server-flake

The [Neo4j openCypher language server](https://github.com/neo4j/cypher-language-support)
(`cypher-language-server`), packaged from the npm tarball and published as a
**self-contained arx bundle**.

Note the dist-tags: upstream's `latest` points at a stale 2025 canary, so this
flake tracks **`next`** (currently `2.0.0-next.x`).

## Packages

| Attribute | Contents |
|---|---|
| `packages.<system>.default` | the published bundle |
| `packages.<system>.cypher-language-server` | alias of `default` |
| `packages.<system>.unbundled` | npm tarball + runtime deps, before bundling |

`overlays.default` provides `pkgs.cypher-language-server`.

## Usage

```nix
{
  inputs.cypher-flake.url = "github:atomic-235/cypher-language-server-flake";
  inputs.cypher-flake.inputs.nixpkgs.follows = "nixpkgs";
}
```

```nix
nixpkgs.overlays = [ inputs.cypher-flake.overlays.default ];
# pkgs.cypher-language-server
```

`cypher-language-server` speaks LSP over stdio — pass `--stdio` when starting it
from an editor:

```lua
vim.lsp.start({ name = "cypher", cmd = { "cypher-language-server", "--stdio" } })
```

## Implementation notes

The upstream `bin` is a symlink to an ESM `.js` file inside its package. A
bundle copies the target out of that package directory, so Node parses it as
CommonJS and fails with a syntax error. `unbundled.nix` therefore replaces the
bin with a shell wrapper that execs node on the file in place, keeping its
`package.json` context.

## Updates

CI runs weekly (Monday 06:00 UTC): resolve `@neo4j-cypher/language-server/next`,
regenerate the lock and `npmDepsHash`, build, bundle, upload
`cypher-language-server-linux-x86_64`, verify, commit and tag `v<version>`.

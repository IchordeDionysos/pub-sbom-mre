# MRE: GitHub SBOM export loses direct/transitive information for Dart (pub)

Two Dart packages in one repository:

| Folder | Files | Direct dependencies |
|---|---|---|
| `with_lockfile/` | `pubspec.yaml` + committed `pubspec.lock` | `http` (main), `lints` (dev) |
| `manifest_only/` | `pubspec.yaml` only (no lockfile) | `path: ^1.9.0`, `args: 2.6.0` (exact pin), `crypto: any` |

## Steps

```bash
# 1. Create a new repository (public, or private with the dependency graph enabled)
gh repo create pub-sbom-mre --public --clone && cd pub-sbom-mre
# copy the contents of this folder into it, then:
(cd with_lockfile && dart pub get)   # creates with_lockfile/pubspec.lock (commit it)
git add -A && git commit -m "pub SBOM MRE" && git push -u origin HEAD

# 2. Wait until Insights -> Dependency graph lists the packages (usually a few minutes)

# 3. Export the SBOM and inspect it
./check_sbom.sh <owner>/pub-sbom-mre
```

## Expected

* `with_lockfile`: only `http` and `lints` are linked from the root with `DEPENDS_ON`;
  their dependencies (`http_parser`, `async`, `collection`, `meta`, `typed_data`, `web`, ...) are
  linked from `http` (or are at least distinguishable as transitive). `pubspec.lock` contains
  this information: `dependency: "direct main"`, `"direct dev"` or `"transitive"` for every package.
* `manifest_only`: `path`, `args` and `crypto` all appear as direct dependencies.

## What we observe in our production repository (to be confirmed with this MRE)

1. **All lockfile packages are flattened to direct.** Every pub package from `pubspec.lock` is linked
   from the repository root and there is not a single pub -> pub `DEPENDS_ON` relationship
   (production repo: 705 pub packages, 705 root edges, 0 pub -> pub edges).
   npm packages in the same SBOM do get transitive edges (896 npm -> npm edges).
2. **`pubspec.yaml` is ignored when a `pubspec.lock` sits next to it.** No constraint from such a
   manifest appears in the SBOM, so the only remaining hint that a package is direct is gone.
   In the production repo, all 8 `pubspec.yaml` files with a sibling lockfile are affected;
   all workspace members without their own lockfile are represented.
3. **Manifest-only entries drop some constraint forms** (to be confirmed with `manifest_only/`):
   `any` / empty constraints do not appear, and exact pins are indistinguishable from lockfile entries.

`check_sbom.sh` prints the number of pub packages, root edges and pub -> pub edges, plus all
packages linked from the root, so the result can be pasted directly into the support ticket.

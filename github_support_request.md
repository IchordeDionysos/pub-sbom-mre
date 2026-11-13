**Subject:** Dependency graph SBOM export: all Dart/pub packages are linked to the repository root, with no transitive relationships

**Product area:** Dependency graph / SBOM export (Insights → Dependency graph → Export SBOM, `GET /repos/{owner}/{repo}/dependency-graph/sbom`)

Hi GitHub Support,

We use the SPDX SBOM export of the dependency graph to list our **direct** open-source dependencies. For Dart (pub) packages this doesn't work: every package from `pubspec.lock` is exported with a `DEPENDS_ON` relationship from the repository root, and there are no relationships between pub packages. Direct and transitive dependencies therefore look identical in the SBOM.

The information is available in the source: `pubspec.lock` states for every package whether it is `dependency: "direct main"`, `"direct dev"` or `"transitive"`.

**Minimal reproduction**

Repository: https://github.com/IchordeDionysos/pub-sbom-mre

`with_lockfile/pubspec.yaml` declares exactly two dependencies, `http: ^1.2.0` (main) and `lints: ^5.0.0` (dev). The committed `pubspec.lock` (from `dart pub get`) marks those two as `direct main` / `direct dev` and the other 10 packages as `transitive`.

Output of `check_sbom.sh` (in the repo), which downloads the SBOM via the API and counts the pub relationships:

```
pub packages: 13
edges ROOT -> pub: 13
edges pub -> pub:  0

pub packages linked from ROOT:
  async 2.13.1
  collection 1.19.1
  http 1.6.0
  http_parser 4.1.2
  lints 5.1.1
  meta 1.19.0
  path 1.9.1
  path >= 1.9.0,< 2.0.0
  source_span 1.10.2
  string_scanner 1.4.1
  term_glyph 1.2.2
  typed_data 1.4.0
  web 1.1.1
```

(The `path >= 1.9.0,< 2.0.0` line comes from a second test folder in the same repository and is unrelated to this issue.)

Only `http` and `lints` should be linked from the root. The transitive packages, e.g. `async`, `http_parser`, `source_span`, `string_scanner`, `term_glyph`, `typed_data` and `web`, are linked from the root in exactly the same way.

**Production impact**

In our production repository (private), all 705 pub packages are linked from the root and there are 0 pub → pub relationships. 217 of the 418 distinct pub packages aren't declared in any `pubspec.yaml`; they are transitive, but they look exactly like direct dependencies. npm packages in the same SBOM do get transitive relationships (896 npm → npm edges), so the problem appears to be specific to pub.

**Expected behaviour**

- Only packages marked `direct main` / `direct dev` in `pubspec.lock` are linked from the repository root, as the export already does for npm.
- Transitive packages are linked from the package that requires them. If that can't be derived from `pubspec.lock` alone, they should at least not be linked from the root as if they were direct.

**Questions**

1. Is this known or expected behaviour for the pub ecosystem?
2. Is there a recommended way to get direct vs. transitive information for pub packages from the dependency graph (SBOM, REST or GraphQL API)?
3. Would dependencies submitted via the dependency submission API with `relationship: direct` / `indirect` be reflected in the SBOM export for pub packages?

Thanks!

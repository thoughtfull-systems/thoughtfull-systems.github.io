{ pkgs, ... }:

{
  # Tools needed to build and preview this Hugo site.
  # Mirrors the GitHub Pages workflow (.github/workflows/hugo.yaml).
  packages = [
    pkgs.hugo       # extended build (embedded Dart Sass); site requires >= 0.87.0
    pkgs.dart-sass  # Sass transpiler used by the Congo theme / CI
    pkgs.git        # theme is vendored, but submodule/repo ops still need it
  ];

  env.HUGO_ENVIRONMENT = "development";

  # Live-reloading local preview, including draft/future content.
  scripts.serve.exec = "hugo server --buildDrafts --buildFuture";

  # Production-style build matching CI.
  scripts.build.exec = ''hugo --gc --minify "$@"'';

  enterShell = ''
    hugo version
  '';
}

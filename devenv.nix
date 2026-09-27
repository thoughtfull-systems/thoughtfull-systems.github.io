{ pkgs, ... }:

{
  # Tools needed to build and preview this Hugo site.
  # Mirrors the GitHub Pages workflow (.github/workflows/hugo.yaml).
  packages = [
    pkgs.hugo       # extended build (embedded Dart Sass); site requires >= 0.87.0
    pkgs.dart-sass  # Sass transpiler used by the Congo theme / CI
    pkgs.git        # theme is vendored, but submodule/repo ops still need it
    pkgs.vale       # prose linter (see .vale.ini); `vale sync` fetches styles
  ];

  env.HUGO_ENVIRONMENT = "development";

  # Live-reloading local preview, including draft/future content.
  scripts.serve.exec = "hugo server --buildDrafts --buildFuture";

  # Production-style build matching CI.
  scripts.build.exec = ''hugo --gc --minify "$@"'';

  # Lint all content prose with Vale.
  scripts.lint.exec = "vale content";

  # Pre-commit hook: lint staged Markdown with Vale.
  # `.vale.ini` sets MinAlertLevel = suggestion, so Vale exits non-zero on ANY
  # finding — the commit is blocked until findings are resolved, a word is added
  # to the Blog vocabulary, or a rule is disabled in `.vale.ini`.
  git-hooks.hooks.vale = {
    enable = true;
    name = "vale";
    description = "Lint prose with Vale (blocks on any finding)";
    entry = "${pkgs.vale}/bin/vale";
    files = "^content/.*\\.md$";
    pass_filenames = true;
  };

  enterShell = ''
    hugo version
  '';
}

# GitHub Actions

The root workflow in `.github/workflows/ci.yml` runs contract/backend checks and Flutter checks.

Native Flutter platform folders are generated in CI through `scripts/bootstrap-mobile-platforms.sh` until a machine with Flutter can run `flutter create` locally and commit the generated platform projects.

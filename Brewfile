# Brewfile — local-dev tooling for Zhip.
#
# Install everything in one shot:
#   brew bundle install
#
# Or run `just bootstrap`, which calls `brew bundle install` and then
# `xcodegen generate` so a fresh checkout becomes a runnable Xcode project.

# Build / project generation
brew "just"          # task runner; recipes live in /justfile
brew "xcodegen"      # generates Zhip.xcodeproj from project.yml (gitignored project)
brew "xcpretty"      # nicer xcodebuild output

# Lint / format / typo-check (matched to the CI versions where it matters)
brew "swiftformat"
brew "swiftlint"
brew "typos-cli"

# Coverage tooling — only needed if you run `just cov-detailed` locally.
# (CI installs xcresultparser via the workflow.)
brew "xcresultparser"

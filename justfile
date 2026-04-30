# Zhip — task runner (https://github.com/casey/just)
#
# First-time setup:
#   brew install just     # bootstraps the rest
#   just bootstrap        # `brew bundle install` + xcodegen generate
#
# The Xcode project is generated from project.yml — run `just gen` after
# pulling new commits or whenever project.yml / Package.swift changes.

set shell := ["zsh", "-cu"]

project    := "Zhip.xcodeproj"
scheme     := "Zhip"
result_dir := ".build"
result     := result_dir + "/TestResults.xcresult"
cov_json   := result_dir + "/coverage.json"
sim_device := env_var_or_default("SIM_DEVICE", "iPhone 17")
sim_os     := env_var_or_default("SIM_OS", "26.1")

# Keep in sync with .github/workflows/ci.yml to ensure local and CI use
# the same Apple Silicon simulator destination.
sim := "platform=iOS Simulator,name=" + sim_device + ",OS=" + sim_os + ",arch=arm64"

# ── Default ───────────────────────────────────────────────────────────────────

# List available recipes
default:
    @just --list

# ── Bootstrap ────────────────────────────────────────────────────────────────

# One-shot: install every brew tool the repo needs, then generate the Xcode
# project. Run after a fresh checkout. Idempotent — safe to re-run anytime.
bootstrap:
    brew bundle install
    just gen

# ── Project generation ───────────────────────────────────────────────────────

# Regenerate Zhip.xcodeproj from project.yml. The .xcodeproj is gitignored;
# checkout / branch switch / project.yml edit ⇒ run this.
gen:
    xcodegen generate

# ── Testing ───────────────────────────────────────────────────────────────────

# Build and run the unit test suite
test:
    xcodebuild test \
        -project {{project}} \
        -scheme {{scheme}} \
        -destination '{{sim}}' \
        -only-testing:ZhipTests \
        ENABLE_USER_SCRIPT_SANDBOXING=NO \
        | xcpretty

# Run tests, then print a pretty per-file coverage table.
# Produces .build/coverage.json for machine use (no extra tools required).
cov: _run-cov
    @python3 scripts/cov_table.py {{cov_json}}

# Like cov, but also shows every uncovered line highlighted red.
cov-detailed: _run-cov
    @python3 scripts/cov_detailed.py {{result}} {{cov_json}}

# ── Formatting ────────────────────────────────────────────────────────────────

# Auto-format all Swift sources in-place; silently skips any tool not installed.
fmt:
    @if command -v swiftformat >/dev/null 2>&1; then swiftformat Sources Tests; fi
    @if command -v swiftlint  >/dev/null 2>&1; then swiftlint --fix --force-exclude; fi

# ── Internal ──────────────────────────────────────────────────────────────────

# Run xcodebuild with coverage enabled and write the result bundle + JSON.
_run-cov:
    rm -rf {{result}}
    mkdir -p {{result_dir}}
    xcodebuild test \
        -project {{project}} \
        -scheme {{scheme}} \
        -destination '{{sim}}' \
        -only-testing:ZhipTests \
        -enableCodeCoverage YES \
        -resultBundlePath {{result}} \
        ENABLE_USER_SCRIPT_SANDBOXING=NO \
        | xcpretty
    @xcrun xccov view --report --json {{result}} > {{cov_json}}

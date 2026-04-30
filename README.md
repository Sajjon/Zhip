[![codecov](https://codecov.io/gh/OpenZesame/Zhip/graph/badge.svg?token=QXYIVYRA0P)](https://codecov.io/gh/OpenZesame/Zhip)

# Unmaintained

> [!WARNING]
> Zhip is no longer maintained. 
> You should export your secrets and use another wallet. Find one here:
> https://www.zilliqa.com/ecosystem (click wallet)
> (e.g. Moonlet, ZilPay, Trust Wallet or Atomic Wallet)

If you see recent commits here it is for **educational purposes only**. It does NOT mean this wallet is maintained.

---

## Quick start (educational)

```sh
brew install just
just bootstrap   # brew bundle install + xcodegen generate
just test        # build + run the unit suite
```

`Zhip.xcodeproj` is generated from `project.yml` via XcodeGen and is gitignored — `just bootstrap` reproduces it. The justfile lists the rest of the recipes (`just --list`).

For the architecture overview see [`CLAUDE.md`](./CLAUDE.md); for testing patterns see [`TESTING.md`](./TESTING.md).

<div align="center">
  <h1 align="center">StarKonquest</h1>
  <p align="center">
    <a href="http://makeapullrequest.com">
      <img alt="pull requests welcome badge" src="https://img.shields.io/badge/PRs-welcome-brightgreen.svg?style=flat">
    </a>
    <a href="https://twitter.com/intent/follow?screen_name=onlydust_xyz">
        <img src="https://img.shields.io/twitter/follow/onlydust_xyz?style=social&logo=twitter"
            alt="follow on Twitter"></a>
    <a href="https://opensource.org/licenses/Apache-2.0"><img src="https://img.shields.io/badge/License-Apache%202.0-blue.svg"
            alt="License"></a>
    <a href=""><img src="https://img.shields.io/badge/semver-0.0.1-blue"
            alt="License"></a>            
  </p>
  
  <h3 align="center">StarKonquest Contracts written in Cairo for StarkNet.</h3>
</div>

## Usage

> ## ⚠️ WARNING! ⚠️
>
> This repo contains highly experimental code.
> Expect rapid iteration.
> **Use at your own risk.**

### Set up the project

#### Requirements

- [Protostar](https://github.com/software-mansion/protostar) >= 0.1.0
- [Python <=3.8](https://www.python.org/downloads/)

#### 📦 Install

```bash
protostar install
python -m venv env
source env/bin/activate
pip install -r requirements.txt
nile install
```

### ⛏️ Compile

```bash
make
```

## Goal

Implement your ship to catch as much dust as possible.

## Get started

To add your ship, compile it and deploy it

```bash
nile compile
nile deploy <my-ship-contract>
```

Keep the addresses of the contracts, you'll need them later.

## Testing

```bash
make test
pytest tests
```

Coding your ship logic can be tricky, we suggest you use tests to check your code.

You can get inspiration from the [static ship tests](https://github.com/onlydustxyz/starknet-onboarding/blob/main/tests/test_space.py#L188) and run this specific test with `pytest tests -k "test_next_turn_with_ship"`.

## CLI

```bash
make cli
```

## 📄 License

**starkonquest** is released under the [Apache-2.0](LICENSE).

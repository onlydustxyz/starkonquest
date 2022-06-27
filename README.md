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

StarKonquest is an educational game to learn Cairo, in which you implement ship AIs that fight each others in a finite 2D grid to catch as much dust as possible.

The entire game runs in a single transaction, meaning the ships cannot be controlled manually. 
Players must implement an effective ship AI that will detect and catch dust as quickly as possible.

Dust move in random directions and bounce on the borders of the grid. There can be at most one ship on a cell of the
grid, so ships can block each others.

Tournament logic is also implemented, allowing dozens of players to fight in multiple battles until only one winner remains.

## Usage

> ## ⚠️ WARNING! ⚠️
>
> This repo contains highly experimental code.
> Expect rapid iteration.
> **Use at your own risk.**

### Set up the project

#### Requirements

- [Protostar](https://github.com/software-mansion/protostar) >= 0.2.1
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
protostar build
```

## Goal

Implement your ship to catch as much dust as possible.

[Here](./contracts/ships/) are some working example of different ship implementations.

## Get started

See [instructions](./scripts/README.md) to deploy and run a tournament locally.

## Testing

```bash
protostar test
```

Coding your ship logic can be tricky, we suggest you use tests to check your code.

You can get inspiration from the [basic ship tests](./contracts/ships/basic_ship/test_basic_ship.cairo) and run this specific test with `export match=basic_ship && make test`.

## Contributing

Please read [CONTRIBUTING.md](./CONTRIBUTING.md).

## 📄 License

**starkonquest** is released under the [Apache-2.0](LICENSE).

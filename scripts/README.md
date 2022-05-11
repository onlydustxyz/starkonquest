# Deploy

## Configure

Prerequisitory: customize `.env` file to set wanted configuration.
The `PKEYADMIN` environment variable holds the primary key of the administrator.

Once you're happy with the values, export environement variables to make them available in subscripts:

```bash
set -a # automatically export all variables
source .env
set +a
```

## Run local node

```bash
nile node
```

## Setup account

```bash
nile setup "PKEYADMIN"
```

## Deploy OnlyDust ERC20

```sh
nile run ./scripts/deploy-only-dust-erc20.py
```

## Deploy Boarding Pass (ERC721)

```sh
nile run ./scripts/deploy-starkonquest-boarding-pass.py
```

## Deploy Random

```sh
nile run ./scripts/deploy-random.py
```

## Deploy Battle

```sh
nile run ./scripts/deploy-battle.py
```

## Deploy Tournament

```sh
nile run ./scripts/deploy-tournament.py
```

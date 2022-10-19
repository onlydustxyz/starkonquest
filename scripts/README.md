# Deploy

## Configure

Prerequisitory: customize `.env` file to set wanted configuration.
The `PKEYADMIN` environment variable holds the primary key of the administrator.

Once you're happy with the values, export environement variables to make them available in subscripts:

```bash
set -a # automatically export all variables
source assets/addresses.sh
source .env
source scripts/utils.sh
set +a
```

## Start application

```bash
docker-compose up -d
```

## Run any command on devnet

```bash
starknet_local ...
```

## Play a game

You can control the parameters with your env variables

```
play_game
```

## Update dump

```bash
./scripts/init-local.sh
```

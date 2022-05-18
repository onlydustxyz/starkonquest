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
unset STARKNET_NETWORK
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

# Run tournament

These scripts interact with the tournament contract. By default, the "tournament" alias is used to 
retrieve the contract address. If you wish to use a different tournament contract, set the `TOURNAMENT_ADDRESS`
environement variable to whatever you want.

```bash
export TOURNAMENT_ADDRESS=<custom-address-or-alias>
```

## Open registrations

```bash
nile run ./scripts/run/open-registrations.py
```

Define this alias which will be useful in next commands:
```bash
alias stark='starknet --gateway_url="http://127.0.0.1:5000/" --feeder_gateway_url="http://127.0.0.1:5000/"'
```

Now, get transaction details and check it has been accepted on L2 (or L1)
```bash
stark get_transaction --hash <transaction-hash>
```

## Register ships

You must register as many ships as required by the tournament settings.

```bash
export PKEYPLAYER=100
nile run ./scripts/run/setup-player.py

nile run ./scripts/deploy-basic-ship.py
export SHIP_ADDRESS=<ship-address>
nile run ./scripts/run/register-ship.py
```

```bash
export PKEYPLAYER=101
nile run ./scripts/run/setup-player.py

nile run ./scripts/deploy-basic-ship.py
export SHIP_ADDRESS=<ship-address>
nile run ./scripts/run/register-ship.py
```

Etc.

## Close registrations

```bash
nile run ./scripts/run/close-registrations.py
```

## Start tournament

```bash
nile run ./scripts/run/start-tournament.py
```

## Play battles

From now on, you should invoke the `play_next_battle` function of the tournament contract until all battles have been played.

```bash
nile run ./scripts/run/play-next-battle.py
```

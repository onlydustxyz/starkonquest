Contributing to StarKonquest
=======

We really appreciate and value contributions to StarKonquest.
Make sure you read those guidelines before starting to make sure your contributions are aligned with project's goals.

## Contribution guidelines

Before starting development, please check your contribution is listed [here](https://contributions.onlydust.xyz/starkonquest)
and is not already being done by someone else.

It is also very important to follow our [naming convention](https://github.com/onlydustxyz/development-guidelines/blob/main/starknet/README.md#naming-convention) and to understand some of our [design patterns](https://github.com/onlydustxyz/development-guidelines/blob/main/starknet/README.md#design-patterns).

You should always include tests (and documentation, if that makes sense) for the new developments.

## Creating Pull Requests (PRs)

As a contributor, you are expected to fork this repository, work on your own fork and then submit pull requests. The pull requests will be reviewed and eventually merged into the main repo. See ["Fork-a-Repo"](https://help.github.com/articles/fork-a-repo/) for how this works.

## Develop and test locally

In order to setup a local environment, please follow the instructions in the [README](./README.md).

To build all contracts, just do:
```bash
make
```

To launch all tests, just do:
```bash
make test
```

To deploy contracts locally and interact with them, follow [these instructions](./scripts/README.md).

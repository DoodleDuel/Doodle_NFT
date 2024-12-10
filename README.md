# DoodNFTs with cross-chain lockers
## NFT as key

<a href="doodu.app"> DoodleDuel </a> NFTs that offers the ability to lock tokens inderectly into the NFTs on other chains.

Change the .env file to your own values.

Change --network to your preffered network.
```shell
yarn
yarn hardhat ignition deploy ./ignition/modules/Dood.ts --network base_sepolia
yarn hardhat ignition deploy ./ignition/modules/DoodLocker.ts --network base_sepolia

yarn hardhat run ./scripts/dood.ts --network base_sepolia
yarn hardhat run ./scripts/doodLocker.ts --network base_sepolia
```

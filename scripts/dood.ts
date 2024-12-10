import { ethers } from "hardhat";

const DoodsAddress = process.env.DOODS_ADDRESS!;
const privateKey = process.env.PRIVATE_KEY!;

const chain = process.env.LOCKER_CHAIN!;
const lockerAddress = process.env.LOCKER_ADDRESS!;
const sameChainLockerAddress = process.env.SAME_CHAIN_LOCKER_ADDRESS!;

async function main() {
  const provider = ethers.provider;
  const wallet = new ethers.Wallet(privateKey, provider);

  console.log(`Using wallet address: ${wallet.address}`);

  const dood = await ethers.getContractAt("Doods", DoodsAddress, wallet);

  // 1. Mint a new Dood NFT (only owner can call this)
  console.log("Minting new token...");
  const mintTx = await dood.mint();
  await mintTx.wait();
  console.log("Minted a new token.");

  // 2. Get the current tokenId
  const tokenId = await dood.currentTokenId();
  console.log(`Current minted token ID: ${tokenId}`);

  // 3. Add a locker for the token
  console.log(`Adding locker for token ${tokenId}...`);
  const addLockerTx = await dood.addLocker(tokenId, chain, lockerAddress);
  await addLockerTx.wait();
  console.log("Locker added.");

  // 4. Prove ownership to a cross-chain locker
  console.log(`Proving ownership of token ${tokenId} to cross-chain locker...`);
  const proveOwnershipTx = await dood.proveOwnership(
    tokenId,
    chain,
    lockerAddress,
    {
      value: ethers.parseEther("0.003"), // Adjust the amount as needed for gas
    }
  );
  await proveOwnershipTx.wait();
  console.log(
    `Proved ownership of token ${tokenId} (tx: ${proveOwnershipTx.hash})`
  );

  // 5. Set same chain locker address (onlyOwner)
  console.log("Setting same chain locker address...");
  const setSameChainLockerTx = await dood.setSameChainLockerAddress(
    sameChainLockerAddress
  );
  await setSameChainLockerTx.wait();
  console.log("Same chain locker address set.");

  // 6. Mark locker as on the same chain for this token
  console.log(`Setting locker on same chain for token ${tokenId}...`);
  const setOnSameChainTx = await dood.setLockerOnSameChain(tokenId, true);
  await setOnSameChainTx.wait();
  console.log("Locker marked as on the same chain.");

  // 7. Prove ownership to a locker on the same chain
  console.log(`Proving ownership of token ${tokenId} on the same chain...`);
  const proveSameChainTx = await dood.proveOwnershipSameChain(tokenId);
  await proveSameChainTx.wait();
  console.log("Proved ownership on the same chain.");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

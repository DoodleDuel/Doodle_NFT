import { ethers } from "hardhat";
import { env } from "process";

const DoodleLockerAddress = env.LOCKER_ADDRESS!;
const privateKey = env.PRIVATE_KEY!;
const tokenId = 1;

async function main() {
  const provider = ethers.provider;
  const wallet = new ethers.Wallet(privateKey, provider);
  console.log(`Using wallet address: ${wallet.address}`);

  const doodleLocker = await ethers.getContractAt(
    "DoodleLocker",
    DoodleLockerAddress
  );

  const asd = await doodleLocker.ownershipProved(tokenId);
  if (asd !== wallet.address) {
    console.error("Ownership not proved yet. Cannot proceed with withdrawals.");
    return;
  }

  const ethLockedBalance2 = await doodleLocker.tokenBalances(
    tokenId,
    ethers.ZeroAddress
  );
  console.log(
    `Locked ETH balance for tokenId ${tokenId}: ${ethers.formatEther(
      ethLockedBalance2
    )} ETH`
  );

  /*********************************
   * 1. Deposit ETH
   *********************************/
  const depositEthAmount = ethers.parseEther("0.001");
  const depositEthTx = await doodleLocker.connect(wallet).depositETH(tokenId, {
    value: depositEthAmount,
  });
  await depositEthTx.wait();
  console.log(
    `Deposited ${ethers.formatEther(
      depositEthAmount
    )} ETH into DoodleLocker for tokenId ${tokenId}`
  );

  // Check locked ETH balance
  const ethLockedBalance = await doodleLocker.tokenBalances(
    tokenId,
    ethers.ZeroAddress
  );
  console.log(
    `Locked ETH balance for tokenId ${tokenId}: ${ethers.formatEther(
      ethLockedBalance
    )} ETH`
  );

  /*********************************
   * 5. Prove Ownership
   *********************************/
  // Check if ownership is proved:
  const ownerOfTokenId = await doodleLocker.ownershipProved(tokenId);
  if (ownerOfTokenId !== wallet.address) {
    console.error("Ownership not proved yet. Cannot proceed with withdrawals.");
    return;
  }
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

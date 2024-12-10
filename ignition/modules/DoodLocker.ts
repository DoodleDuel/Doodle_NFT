import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

// Axelar Gateway address
const gatewayAddress = process.env.LOCKER_AXELAR_GATEWAY_ADDRESS;

const DoodLockerModule = buildModule("DoodLockerModule", (m) => {
  const sourceChain = process.env.DOOD_CHAIN;
  const sourceContract = process.env.DOOD_ADDRESS;

  const doodLocker = m.contract("DoodleLocker", [
    gatewayAddress,
    sourceChain,
    sourceContract,
  ]);

  return { doodLocker };
});

export default DoodLockerModule;

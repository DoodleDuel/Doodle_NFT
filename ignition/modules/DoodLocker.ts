import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

// Axelar Gateway address
const gatewayAddress = "0xe432150cce91c13a887f7D836923d5597adD8E31";

const DoodLockerModule = buildModule("DoodLockerModule", (m) => {
  const sourceChain = "base-sepolia";
  const sourceContract = "0x090Bb81a3464c8dEc88DCE5F5AfbEc65F2747Ce3";

  const doodLocker = m.contract("DoodleLocker", [
    gatewayAddress,
    sourceChain,
    sourceContract,
  ]);

  return { doodLocker };
});

export default DoodLockerModule;

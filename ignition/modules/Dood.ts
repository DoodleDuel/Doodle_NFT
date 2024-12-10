import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

// Axelar Gateway address
const gatewayAddress = process.env.DOOD_AXELAR_GATEWAY_ADDRESS;
const gasPayer = process.env.DOOD_AXELAR_GAS_ADDRESS;

// Base Token URI for Doods NFT
const baseTokenURI = "test.com/api";

const DoodModule = buildModule("DoodModule", (m) => {
  const dood = m.contract("Doods", [gatewayAddress, gasPayer, baseTokenURI]);

  return { dood };
});

export default DoodModule;

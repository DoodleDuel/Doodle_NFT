import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

// Axelar Gateway address
const gatewayAddress = "0xe432150cce91c13a887f7D836923d5597adD8E31";
const gasPayer = "0xbE406F0189A0B4cf3A05C286473D23791Dd44Cc6";

// Base Token URI for Doods NFT
const baseTokenURI = "https://railway-backend-production-8d2b.up.railway.app/doods";

const DoodModule = buildModule("DoodModule", (m) => {
  const dood = m.contract("Doods", [gatewayAddress, gasPayer, baseTokenURI]);

  return { dood };
});

export default DoodModule;

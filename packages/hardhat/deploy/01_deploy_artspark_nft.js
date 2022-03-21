// deploy/00_deploy_your_contract.js

const { ethers, upgrades } = require("hardhat");

const localChainId = "31337";

// const sleep = (ms) =>
//   new Promise((r) =>
//     setTimeout(() => {
//       console.log(`waited for ${(ms / 1000).toFixed(3)} seconds`);
//       r();
//     }, ms)
//   );

// 0x5FC8d32690cc91D4c39d9d3abcBD16989F875707
const signerAddress = "0x1753a6d1617cec011a1032f3ea6172e92679d9bd"

module.exports = async ({ getNamedAccounts, deployments, getChainId }) => {
  const { deploy, save } = deployments;
  const { deployer } = await getNamedAccounts();
  const chainId = await getChainId();
  const ArtsparkFactory = await ethers.getContractFactory("Artspark");
  // 500000 = linear curve
  // 476190
  //const ratio = 476190;
  const ratio = 500000;
  const reserveInit = 10000000000000;
  //const reserveInit = 150000000000000;
  const Artspark = await upgrades.deployProxy(ArtsparkFactory, ['Artspark', 'ARTS', ratio, reserveInit, signerAddress]);
  await Artspark.deployed();
  console.log(`deployed proxy at ${Artspark.address}`);

  //const signer = await Artspark.setSigner(signerAddress);
  //console.log(`set signer to ${signerAddress}`);
  //console.log({signer})

  const artifact = await deployments.getExtendedArtifact('Artspark');
  await save('Artspark', {address: Artspark.address, ...artifact});
};

module.exports.tags = ["Artspark"];

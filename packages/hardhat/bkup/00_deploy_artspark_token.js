//const { ethers, upgrades } = require("hardhat");
//const SuperfluidSDK = require("@superfluid-finance/js-sdk");
//const localChainId = "31337";
//
//module.exports = async ({ getNamedAccounts, deployments, getChainId }) => {
//  const { deploy, save } = deployments;
//  const { deployer } = await getNamedAccounts();
//  const chainId = await getChainId();
//  const ArtsparkToken = await ethers.getContractFactory("ArtsparkToken");
//  const sf = new SuperfluidSDK.Framework({
//    ethers: ethers.provider,
//  })
//
//  const stf = await sf.host.getSuperTokenFactory()
//  console.log({stf})
//
//
//};
//
//module.exports.tags = ["ArtsparkToken"];

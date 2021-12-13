const { assert, expect } = require("chai");
const { ethers } = require("hardhat");

describe("This is our main Faucet testing scope", function () {
   let faucet, signer;

   beforeEach("Deploy the contract instance first", async function () {
      const Faucet = await ethers.getContractFactory("Faucet");
      faucet = await Faucet.deploy({
         value: ethers.utils.parseUnits("10", "ether"),
      });
      await faucet.deployed();
      [signer] = await ethers.provider.listAccounts();
   });
});
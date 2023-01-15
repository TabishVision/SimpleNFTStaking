const { ethers } = require("hardhat");
const { expect, assert } = require("chai");
const helpers = require("@nomicfoundation/hardhat-network-helpers");

describe("EXO unit test", async function () {
  let ERCToken, NFTContract;
  let Alice, Bob, Charlie;

  before(async function () {
    [Alice, Bob, Charlie] = await ethers.getSigners();

    const TaskToken = await ethers.getContractFactory("TaskToken");
    const TaskNFT = await ethers.getContractFactory("TaskNFT");

    // Deploying Erc20 Contract
    ERCToken = await TaskToken.deploy();
    await ERCToken.deployed();

    //Deploying Erc721 Contract
    NFTContract = await TaskNFT.deploy();
    await NFTContract.deployed();
  });

  describe("Creation", () => {
    it("Test correct setting of vanity information (ERC20)", async () => {
      const name = await ERCToken.name();
      assert.strictEqual(name, "TaskToken");

      const symbol = await ERCToken.symbol();
      assert.strictEqual(symbol, "TTK");
    });

    it("Test correct setting of vanity information (ERC721)", async () => {
      const name = await NFTContract.name();
      assert.strictEqual(name, "TaskNFT");

      const symbol = await NFTContract.symbol();
      assert.strictEqual(symbol, "TTK");
    });
  });

  describe("Mint Tokens", () => {
    it("Mint ERC Tokens", async () => {
      const amount = ethers.utils.parseUnits("100", "ether");
      await ERCToken.mint(Bob.address, amount);

      const bobNewBalance = await ERCToken.balanceOf(Bob.address);

      expect(amount.toString()).to.be.equal(bobNewBalance.toString());
    });

    it("Mint ERC721 Tokens", async () => {
      await NFTContract.safeMint(Bob.address);
      await NFTContract.safeMint(Bob.address);
      await NFTContract.safeMint(Charlie.address);

      const bobNewBalance = await NFTContract.balanceOf(Bob.address);
      const charlieNewBalance = await NFTContract.balanceOf(Charlie.address);

      expect(bobNewBalance.toString()).to.be.equal("2");
      expect(charlieNewBalance.toString()).to.be.equal("1");
    });
  });

  describe("Stake", () => {
    it("Stake Nft ", async () => {
      await NFTContract.connect(Bob).approve(ERCToken.address, 0);

      await ERCToken.connect(Bob).stake(NFTContract.address, 0);

      expect(await NFTContract.ownerOf(0)).to.be.equal(ERCToken.address);
    });
  });

  describe("UnStake", () => {
    it("UnStake Nft", async () => {
      await helpers.time.increase(60 * 60 * 24 * 37);

      const reward = await ERCToken.connect(Bob).unstake(
        NFTContract.address,
        0
      );
    });
  });
});

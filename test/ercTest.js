const { ethers } = require("hardhat");
const { expect, assert } = require("chai");
const helpers = require("@nomicfoundation/hardhat-network-helpers");
const { MerkleTree } = require("merkletreejs");

describe("EXO unit test", async function () {
  let ERCToken, NFTContract;
  let Alice, Bob, Charlie, Carol, Dave;
  let whiteList = [];

  function getMerkleRoot(_whitelist) {
    let leaves = _whitelist.map((addr) => ethers.utils.keccak256(addr));
    const merkleTree = new MerkleTree(leaves, ethers.utils.keccak256, {
      sortPairs: true,
    });
    return merkleTree.getHexRoot();
  }

  function getProof(userWalletAddress) {
    if (whiteList.includes(userWalletAddress)) {
      let leaves = whiteList.map((addr) => ethers.utils.keccak256(addr));
      const merkleTree = new MerkleTree(leaves, ethers.utils.keccak256, {
        sortPairs: true,
      });
      let hashedAddress = ethers.utils.keccak256(userWalletAddress);
      return merkleTree.getHexProof(hashedAddress);
    }
    return false;
  }

  before(async function () {
    [Alice, Bob, Charlie, Carol, Dave] = await ethers.getSigners();

    whiteList.push(Bob.address);

    const TaskToken = await ethers.getContractFactory("TaskToken");
    const TaskNFT = await ethers.getContractFactory("TaskNFT");

    // Deploying Erc20 Contract
    ERCToken = await TaskToken.deploy(getMerkleRoot(whiteList));
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
      const amount = ethers.utils.parseUnits("10000", "ether");
      await ERCToken.mint(Bob.address, amount);
      await ERCToken.mint(Charlie.address, amount);
      await ERCToken.mint(Carol.address, amount);
      await ERCToken.mint(Dave.address, amount);

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

      let stakeReciept = await ERCToken.connect(Bob).stake(
        NFTContract.address,
        0
      );
      stakeReciept = await stakeReciept.wait();

      expect(stakeReciept.events[1].event.toString()).to.be.equal("Stake");
      expect(stakeReciept.events[1].args._from.toString()).to.be.equal(
        Bob.address
      );
      expect(stakeReciept.events[1].args._nftId.toString()).to.be.equal("0");
    });
  });

  describe("UnStake", () => {
    it("UnStake Nft", async () => {
      await helpers.time.increase(60 * 60 * 24 * 77);

      let unstakeReciept = await ERCToken.connect(Bob).unstake(
        NFTContract.address,
        0
      );

      unstakeReciept = await unstakeReciept.wait();

      expect(unstakeReciept.events[1].event.toString()).to.be.equal("Unstake");
      expect(unstakeReciept.events[1].args._from.toString()).to.be.equal(
        Bob.address
      );
      expect(unstakeReciept.events[1].args._nftId.toString()).to.be.equal("0");
    });

    it("Check Reward", async () => {
      const amount = ethers.utils.parseUnits("9.000000001", "ether");

      let reward = await ERCToken.connect(Bob).checkReward();
      expect(reward.toString()).to.be.equal(amount.toString());
    });
  });

  describe("WhiteListing", () => {
    it("WhiteList Charlie and setHash", async () => {
      whiteList.push(Charlie.address);

      let root = getMerkleRoot(whiteList);

      await ERCToken.setMerkleRoot(root);

      expect(await ERCToken.merkleRoot()).to.be.equal(root);
    });
  });

  // describe("Transfer", () => {
  //   it("Revert : WhiteList Charlie Exceeds limt", async () => {
  //     const amount = ethers.utils.parseUnits("100", "ether");
  //     const amount2 = ethers.utils.parseUnits("1009", "ether");

  //     let proof = getProof(Charlie.address);

  //     let result = await ERCToken.transfer(Carol.address, amount, proof);
  //   });
  // });
});

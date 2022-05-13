const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("MonsterPortal", function () {
  it("Should return a ERC-1155 and check contract settings", async function () {
    const MonsterPortal = await ethers.getContractFactory("MonsterPortal");
    const monsterPortal = await MonsterPortal.deploy();
    await monsterPortal.deployed();

     //In Development

    expect(await monsterPortal.mintPack()).to.equal("");
    expect(await monsterPortal.mintFee()).to.equal("");

    // wait until the transaction is mined
    //await mintPackTx.wait();

    //expect(await monsterPortal.()).to.equal();
  });
});

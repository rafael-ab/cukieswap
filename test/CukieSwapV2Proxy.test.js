const FeeHolder = artifacts.require("FeeHolder");
const { assert, upgrades, ethers } = require("hardhat");

const ACCOUNT = "0x73BCEb1Cd57C711feaC4224D062b0F6ff338501e";

contract("CukieSwapV2 (Proxy)", () => {
  let feeholder, instance, upgraded;

  beforeEach(async () => {
    await hre.network.provider.request({
      method: "hardhat_impersonateAccount",
      params: [ACCOUNT],
    });
    feeholder = await FeeHolder.new({ from: ACCOUNT });

    const CukieSwapV1 = await ethers.getContractFactory("CukieSwapV1");
    const CukieSwapV2 = await ethers.getContractFactory("CukieSwapV2");

    instance = await upgrades.deployProxy(CukieSwapV1, [feeholder.address]);
    upgraded = await upgrades.upgradeProxy(instance.address, CukieSwapV2);

  });

  it("should retrieves a previously stored recipient", async () => {
    assert.equal(feeholder.address, await upgraded.recipient());
  }).timeout(50000);
});
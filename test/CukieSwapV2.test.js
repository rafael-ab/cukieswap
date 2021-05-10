const CukieSwapV2 = artifacts.require("CukieSwapV2");
const FeeHolder = artifacts.require("FeeHolder");
const IERC20 = artifacts.require("IERC20");
const { assert, web3 } = require("hardhat");
const { expectEvent, time } = require("@openzeppelin/test-helpers");

const WETH_ADDRESS = "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2";
const DAI_ADDRESS = "0x6B175474E89094C44Da98b954EedeAC495271d0F";
const SNX_ADDRESS = "0xC011a73ee8576Fb46F5E1c5751cA3B9Fe0af2a6F";
const BAL_ADDRESS = "0xba100000625a3754423978a60c9317c58a424e3D";

const ACCOUNT = "0x73BCEb1Cd57C711feaC4224D062b0F6ff338501e";

const toWei = (value, type) => web3.utils.toWei(String(value), type);
const fromWei = (value, type) => Number(web3.utils.fromWei(String(value), type));

contract("CukieSwapV2", () => {
  let cukieSwapV2, feeholder;

  before(async () => {
      await hre.network.provider.request({
        method: "hardhat_impersonateAccount",
        params: [ACCOUNT],
      });

      feeholder = await FeeHolder.new({from: ACCOUNT});
      cukieSwapV2 = await CukieSwapV2.new();

      cukieSwapV2.initializeV2(feeholder.address);
  });

  it("should holds fees", async () => {
    const result = await cukieSwapV2.swapEthToTokenBAL(
      DAI_ADDRESS,
      {from: ACCOUNT, value: toWei(1, "ether")}
    );
    console.log("Gas Used:", result.receipt.gasUsed);

    expectEvent(result, "LogSwap", {
      from: WETH_ADDRESS,
      to: DAI_ADDRESS,
      amount: toWei(0.999, "ether")
    });

    let balance = await feeholder.getBalance({from: ACCOUNT});
    balance = toWei(balance, "ether");
    assert(balance > 0);
  });

   it("should swap ETH to DAI", async () => {
    const result = await cukieSwapV2.swapEthToTokenBAL(
      DAI_ADDRESS,
      {from: ACCOUNT, value: toWei(1, "ether")}
    );
    console.log("Gas Used:", result.receipt.gasUsed);

    expectEvent(result, "LogSwap", {
      from: WETH_ADDRESS,
      to: DAI_ADDRESS,
      amount: toWei(0.999, "ether")
    });

    const daiToken = await IERC20.at(DAI_ADDRESS);
    const balance = await daiToken.balanceOf(ACCOUNT);
    console.log("DAI Balance:", fromWei(balance));
  });

   it("should swap ETH to BAL", async () => {
    const result = await cukieSwapV2.swapEthToTokenBAL(
      BAL_ADDRESS,
      {from: ACCOUNT, value: toWei(1, "ether")}
    );
    console.log("Gas Used:", result.receipt.gasUsed);

    expectEvent(result, "LogSwap", {
      from: WETH_ADDRESS,
      to: BAL_ADDRESS,
      amount: toWei(0.999, "ether")
    });

    const balToken = await IERC20.at(BAL_ADDRESS);
    const balance = await balToken.balanceOf(ACCOUNT);
    console.log("BAL Balance:", fromWei(balance));
  });

  it("should swap ETH to 50% DAI and 50% SNX", async () => {
    const result = await cukieSwapV2.swapEthToTokensBAL(
      [DAI_ADDRESS, SNX_ADDRESS],
      [5000, 5000],
      {from: ACCOUNT, value: toWei(1, "ether")}
    );
    console.log("Gas Used:", result.receipt.gasUsed);

    expectEvent(result, "LogSwap", {
      to: DAI_ADDRESS,
      amount: toWei(0.4995, "ether")
    });
    expectEvent(result, "LogSwap", {
      from: WETH_ADDRESS,
      to: SNX_ADDRESS,
      amount: toWei(0.4995, "ether")
    });

    const daiToken = await IERC20.at(DAI_ADDRESS);
    const daiBalance = await daiToken.balanceOf(ACCOUNT);
    console.log("DAI Balance:", Number(web3.utils.fromWei(daiBalance)));

    const snxToken = await IERC20.at(SNX_ADDRESS);
    const snxBalance = await snxToken.balanceOf(ACCOUNT);
    console.log("SNX Balance:", Number(web3.utils.fromWei(snxBalance)));
  }); 

  it("should swap ETH to 75.35% DAI and 24.65% BAL", async () => {
    const result = await cukieSwapV2.swapEthToTokensBAL(
      [DAI_ADDRESS, BAL_ADDRESS],
      [7535, 2465],
      {from: ACCOUNT, value: toWei(1, "ether")}
    );
    console.log("Gas Used:", result.receipt.gasUsed);
      
    expectEvent(result, "LogSwap", {
      from: WETH_ADDRESS,
      to: DAI_ADDRESS,
      amount: toWei(0.7527465, "ether")
    });

    expectEvent(result, "LogSwap", {
      from: WETH_ADDRESS,
      to: BAL_ADDRESS,
      amount: toWei(0.2462535, "ether")
    });

    const daiToken = await IERC20.at(DAI_ADDRESS);
    const daiBalance = await daiToken.balanceOf(ACCOUNT);
    console.log("DAI Balance:", Number(web3.utils.fromWei(daiBalance)));

    const balToken = await IERC20.at(BAL_ADDRESS);
    const balBalance = await balToken.balanceOf(ACCOUNT);
    console.log("BAL Balance:", Number(web3.utils.fromWei(balBalance)));
  });

  it("should swap ETH to DAI from Best DEX", async () => {
    const result = await cukieSwapV2.swapEthToTokenBestDEX(
      DAI_ADDRESS,
      {from: ACCOUNT, value: toWei(1, "ether")}
    );
    console.log("Gas Used:", result.receipt.gasUsed);

    expectEvent(result, "LogSwap", {
      from: WETH_ADDRESS,
      to: DAI_ADDRESS,
      amount: toWei(0.999, "ether")
    });

    const bestDEX = result.logs[1].args[0];

    expectEvent(result, "BestDexChoosed", {
      name: bestDEX,
      from: WETH_ADDRESS,
      to: DAI_ADDRESS
    });

    console.log('Best DEX:', bestDEX);
    const daiToken = await IERC20.at(DAI_ADDRESS);
    const balance = fromWei(await daiToken.balanceOf(ACCOUNT));
    console.log("DAI Balance:", balance);
  });

  it("should swap ETH to BAL from Best DEX", async () => {
    const result = await cukieSwapV2.swapEthToTokenBestDEX(
      BAL_ADDRESS,
      {from: ACCOUNT, value: toWei(1, "ether")}
    );
    console.log("Gas Used:", result.receipt.gasUsed);

    expectEvent(result, "LogSwap", {
      from: WETH_ADDRESS,
      to: BAL_ADDRESS,
      amount: toWei(0.999, "ether")
    });

    const bestDEX = result.logs[1].args[0];

    expectEvent(result, "BestDexChoosed", {
      name: bestDEX,
      from: WETH_ADDRESS,
      to: BAL_ADDRESS
    });

    console.log('Best DEX:', bestDEX);
    const balToken = await IERC20.at(BAL_ADDRESS);
    const balance = await balToken.balanceOf(ACCOUNT);
    console.log("BAL Balance:", fromWei(balance));
  });

 it("should swap ETH to 50% DAI and 50% SNX from Best DEX", async () => {
    const result = await cukieSwapV2.swapEthToTokensBestDEX(
      [DAI_ADDRESS, SNX_ADDRESS],
      [5000, 5000],
      {from: ACCOUNT, value: toWei(1, "ether")}
    );
    console.log("Gas Used:", result.receipt.gasUsed);

    expectEvent(result, "LogSwap", {
      to: DAI_ADDRESS,
      amount: toWei(0.4995, "ether")
    });
    expectEvent(result, "LogSwap", {
      from: WETH_ADDRESS,
      to: SNX_ADDRESS,
      amount: toWei(0.4995, "ether")
    });

    const bestDEXDai = result.logs[1].args[0];

    expectEvent(result, "BestDexChoosed", {
      name: bestDEXDai,
      from: WETH_ADDRESS,
      to: DAI_ADDRESS
    });

    const bestDEXSnx = result.logs[3].args[0];

    expectEvent(result, "BestDexChoosed", {
      name: bestDEXSnx,
      from: WETH_ADDRESS,
      to: SNX_ADDRESS
    });

    console.log('Best DEX:', bestDEXDai);
    const daiToken = await IERC20.at(DAI_ADDRESS);
    const daiBalance = await daiToken.balanceOf(ACCOUNT);
    console.log("DAI Balance:", Number(web3.utils.fromWei(daiBalance)));

    console.log('Best DEX:', bestDEXSnx);
    const snxToken = await IERC20.at(SNX_ADDRESS);
    const snxBalance = await snxToken.balanceOf(ACCOUNT);
    console.log("SNX Balance:", Number(web3.utils.fromWei(snxBalance)));
  }); 

  it("should swap ETH to 75.35% DAI and 24.65% BAL from Best DEX", async () => {
    const result = await cukieSwapV2.swapEthToTokensBestDEX(
      [DAI_ADDRESS, BAL_ADDRESS],
      [7535, 2465],
      {from: ACCOUNT, value: toWei(1, "ether")}
    );
    console.log("Gas Used:", result.receipt.gasUsed);
      
    expectEvent(result, "LogSwap", {
      from: WETH_ADDRESS,
      to: DAI_ADDRESS,
      amount: toWei(0.7527465, "ether")
    });

    expectEvent(result, "LogSwap", {
      from: WETH_ADDRESS,
      to: BAL_ADDRESS,
      amount: toWei(0.2462535, "ether")
    });

    const bestDEXDai = result.logs[1].args[0];

    expectEvent(result, "BestDexChoosed", {
      name: bestDEXDai,
      from: WETH_ADDRESS,
      to: DAI_ADDRESS
    });

    const bestDEXBal = result.logs[3].args[0];

    expectEvent(result, "BestDexChoosed", {
      name: bestDEXBal,
      from: WETH_ADDRESS,
      to: BAL_ADDRESS
    });

    console.log('Best DEX:', bestDEXDai);
    const daiToken = await IERC20.at(DAI_ADDRESS);
    const daiBalance = await daiToken.balanceOf(ACCOUNT);
    console.log("DAI Balance:", Number(web3.utils.fromWei(daiBalance)));

    console.log('Best DEX:', bestDEXBal);
    const balToken = await IERC20.at(BAL_ADDRESS);
    const balBalance = await balToken.balanceOf(ACCOUNT);
    console.log("BAL Balance:", Number(web3.utils.fromWei(balBalance)));
  });
})
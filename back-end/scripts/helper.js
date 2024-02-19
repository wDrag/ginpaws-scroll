const ethers = require("ethers");
const dotenv = require("dotenv");
const {
  abi: quoterAbi,
} = require("@uniswap/v3-periphery/artifacts/contracts/lens/Quoter.sol/Quoter.json");
dotenv.config();
const ERC20_ABI = require("../abi/ERC20.json");

const MAX_FEE_PER_GAS = 100_000_000_000;
const MAX_PRIORITY_FEE_PER_GAS = 100_000_000_000;
const TOKEN_AMOUNT_TO_APPROVE_FOR_TRANSFER = 2_000;
const FACTORY_ADDRESS = "0x1F98431c8aD98523631AE4a59f267346ea31F984";
const SWAP_ROUTER_ADDRESS = "0xE592427A0AEce92De3Edee1F18E0157C05861564";
const WETH_ADDRESS = "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2";
const QUOTER_ADDRESS = "0xb27308f9F90D607463bb33eA1BeBb41C27CE5AB6";
const QUOTER2_ADDRESS = "0x61fFE014bA17989E743c5F6cB21bF9697530B21e";
const RPC_URL = process.env.RPC_URL;

const READABLE_FORM_LEN = 4;

function fromReadableAmount(amount, decimals) {
  return ethers.utils.parseUnits(amount.toString(), decimals);
}

function toReadableAmount(rawAmount, decimals) {
  return ethers.utils
    .formatUnits(rawAmount, decimals)
    .slice(0, READABLE_FORM_LEN);
}

function getProvider() {
  if (!RPC_URL) {
    console.log("No RPC URL Found");
    return null;
  }
  return new ethers.providers.JsonRpcProvider(RPC_URL);
}

function getWalletAddress() {
  return process.env.WALLET_ADDRESS;
}

async function getPoolInfo(poolContract) {
  const [fee, liquidity, slot0] = await Promise.all([
    poolContract.callStatic.fee(),
    poolContract.callStatic.liquidity(),
    poolContract.callStatic.slot0(),
  ]);

  return {
    fee,
    liquidity,
    sqrtPriceX96: slot0[0],
    tick: slot0[1],
  };
}

async function getPoolStates(poolContract) {
  const slot = await poolContract.slot0();
  const state = {
    sqrtPriceX96: slot[0],
  };
  return state;
}

async function getBalanceReadable(tokenContract, walletAddress) {
  const decimals = await tokenContract.callStatic.decimals();
  return ethers.utils.formatUnits(
    await tokenContract.callStatic.balanceOf(walletAddress),
    decimals
  );
}

async function getTokenTransferApproval(token, approveAmount) {
  const provider = getProvider();
  const address = getWalletAddress();
  const wallet = new ethers.Wallet(process.env.PRIVATE_KEY, provider);
  if (!provider || !address) {
    console.log("No Provider Found");
    return;
  }

  try {
    const tokenContract = new ethers.Contract(
      token.address,
      ERC20_ABI,
      provider
    );

    const transaction = await tokenContract.populateTransaction.approve(
      SWAP_ROUTER_ADDRESS,
      fromReadableAmount(approveAmount, token.decimals).toString()
    );

    await wallet.sendTransaction(transaction);
    console.log(
      "Token Approval Transaction Sent, approved ",
      toReadableAmount(approveAmount, token.decimals),
      " ",
      token.symbol
    );
    return;
  } catch (e) {
    console.error(e);
    return;
  }
}

module.exports = {
  MAX_FEE_PER_GAS,
  MAX_PRIORITY_FEE_PER_GAS,
  TOKEN_AMOUNT_TO_APPROVE_FOR_TRANSFER,
  FACTORY_ADDRESS,
  SWAP_ROUTER_ADDRESS,
  WETH_ADDRESS,
  QUOTER_ADDRESS,
  QUOTER2_ADDRESS,
  RPC_URL,
  getWalletAddress,
  fromReadableAmount,
  toReadableAmount,
  getPoolStates,
  getBalanceReadable,
  getPoolInfo,
  getTokenTransferApproval,
};

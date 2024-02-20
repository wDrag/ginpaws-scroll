const { ethers } = require("ethers");
const {
  getProvider,
  FACTORY_ADDRESS,
  getWalletAddress,
  MAX_FEE_PER_GAS,
  MAX_PRIORITY_FEE_PER_GAS,
  WETH_ADDRESS,
  getTokenTransferApproval,
  makeToken,
} = require("./helper");
const ERC20ABI = require("../abi/ERC20.json");

const {
  NONFUNGIBLE_POSITION_MANAGER_ADDRESSES,
  Percent,
  Token,
} = require("@uniswap/sdk-core");
const {
  Position,
  Pool,
  nearestUsableTick,
  NonfungiblePositionManager,
  computePoolAddress,
} = require("@uniswap/v3-sdk");
const IUniswapV3PoolABI = require("@uniswap/v3-core/artifacts/contracts/interfaces/IUniswapV3Pool.sol/IUniswapV3Pool.json");

async function mintNewPosition(token0, token1, fee, amount0, amount1) {
  const provider = getProvider();
  const chainId = (await provider.getNetwork()).chainId;
  const tokenA = await makeToken(token0);
  const tokenB = await makeToken(token1);

  console.log(NONFUNGIBLE_POSITION_MANAGER_ADDRESSES[chainId]);

  await getTokenTransferApproval(
    tokenA,
    amount0,
    NONFUNGIBLE_POSITION_MANAGER_ADDRESSES[chainId]
  );

  await getTokenTransferApproval(
    tokenB,
    amount1,
    NONFUNGIBLE_POSITION_MANAGER_ADDRESSES[chainId]
  );

  const currentPoolAddress = computePoolAddress({
    factoryAddress: FACTORY_ADDRESS,
    tokenA: tokenA,
    tokenB: tokenB,
    fee: fee,
  });

  const poolContract = new ethers.Contract(
    currentPoolAddress,
    IUniswapV3PoolABI.abi,
    provider
  );
  const [liquidity, slot0] = await Promise.all([
    poolContract.liquidity(),
    poolContract.slot0(),
  ]);

  const configuredPool = new Pool(
    tokenA,
    tokenB,
    fee,
    slot0.sqrtPriceX96.toString(),
    liquidity.toString(),
    slot0.tick
  );

  const tickLower =
    nearestUsableTick(configuredPool.tickCurrent, configuredPool.tickSpacing) -
    configuredPool.tickSpacing * 2;

  const position = Position.fromAmounts({
    pool: configuredPool,
    tickLower:
      nearestUsableTick(
        configuredPool.tickCurrent,
        configuredPool.tickSpacing
      ) -
      configuredPool.tickSpacing * 2,
    tickUpper:
      nearestUsableTick(
        configuredPool.tickCurrent,
        configuredPool.tickSpacing
      ) +
      configuredPool.tickSpacing * 2,
    amount0: amount0,
    amount1: amount1,
    useFullPrecision: true,
  });

  const mintOptions = {
    recipient: getWalletAddress(),
    deadline: Math.floor(Date.now() / 1000) + 60 * 20,
    slippageTolerance: new Percent(50, 10_000),
  };
  const { calldata, value } = NonfungiblePositionManager.addCallParameters(
    position,
    mintOptions
  );

  const transaction = {
    data: calldata,
    to: NONFUNGIBLE_POSITION_MANAGER_ADDRESSES[chainId],
    value: value,
    from: getWalletAddress(),
    maxFeePerGas: MAX_FEE_PER_GAS,
    maxPriorityFeePerGas: MAX_PRIORITY_FEE_PER_GAS,
  };

  const wallet = new ethers.Wallet(process.env.PRIVATE_KEY, provider);
  const txRes = await wallet.sendTransaction(transaction);
  console.log("Transaction hash: ", txRes.hash);
}

async function main() {
  const provider = getProvider();
  const walletAddress = getWalletAddress();
  const WETH_Contract = new ethers.Contract(WETH_ADDRESS, ERC20ABI, provider);
  const WETH_balance = await WETH_Contract.balanceOf(walletAddress);
  const USDC_Contract = new ethers.Contract(
    "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48",
    ERC20ABI,
    provider
  );
  const USDC_balance = await USDC_Contract.balanceOf(walletAddress);
  console.log(
    "Before balance: ",
    ethers.utils.formatEther(WETH_balance),
    " / ",
    ethers.utils.formatUnits(USDC_balance, 6)
  );
  await mintNewPosition(
    WETH_ADDRESS,
    "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48", // USDC
    3000,
    ethers.utils.parseEther("0.1"),
    ethers.utils.parseEther("100")
  );
}
main();

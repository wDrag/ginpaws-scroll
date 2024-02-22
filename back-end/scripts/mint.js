const { ethers } = require("ethers");
const {
  getProvider,
  FACTORY_ADDRESS,
  getWalletAddress,
  WETH_ADDRESS,
  getTokenTransferApproval,
  makeToken,
  getBalance,
  toReadableAmount,
  MAX_FEE_PER_GAS,
  MAX_PRIORITY_FEE_PER_GAS,
} = require("./helper");
const ERC20ABI = require("../abi/ERC20.json");

const {
  NONFUNGIBLE_POSITION_MANAGER_ADDRESSES,
  Percent,
} = require("@uniswap/sdk-core");
const {
  Position,
  Pool,
  nearestUsableTick,
  computePoolAddress,
  NonfungiblePositionManager,
  TickMath,
} = require("@uniswap/v3-sdk");
const IUniswapV3PoolABI = require("@uniswap/v3-core/artifacts/contracts/interfaces/IUniswapV3Pool.sol/IUniswapV3Pool.json");
const { getOutputQuote } = require("./quoter");
const {
  abi: NonfungiblePositionManagerABI,
} = require("@uniswap/v3-periphery/artifacts/contracts/NonfungiblePositionManager.sol/NonfungiblePositionManager.json");

async function getCurrentPosition() {}

async function mintNewPosition(token0, token1, fee, amount0, amount1) {
  const provider = getProvider();
  const chainId = (await provider.getNetwork()).chainId;
  const tokenA = await makeToken(token0);
  const tokenB = await makeToken(token1);
  console.log("Minting position for: ", tokenA.symbol, tokenB.symbol, fee);
  console.log(
    "Amounts: ",
    toReadableAmount(amount0.toString(), tokenA.decimals),
    toReadableAmount(amount1.toString(), tokenB.decimals)
  );

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
  const pool = new Pool(
    tokenA,
    tokenB,
    fee,
    slot0.sqrtPriceX96.toString(),
    liquidity.toString(),
    slot0.tick
  );

  const tickSpacing = pool.tickSpacing;
  const tickLower =
    TickMath.MIN_TICK + tickSpacing - (TickMath.MIN_TICK % tickSpacing);

  const tickUpper = TickMath.MAX_TICK - (TickMath.MAX_TICK % tickSpacing);

  const params = {
    token0,
    token1,
    fee,
    tickLower,
    tickUpper,
    amount0Desired: amount0.toString(),
    amount1Desired: amount1.toString(),
    amount0Min: 0,
    amount1Min: 0,
    recipient: getWalletAddress(),
    deadline: Math.floor(Date.now() / 1000) + 60 * 20,
  };

  console.log("Minting position with params: ", params);

  const wallet = new ethers.Wallet(process.env.PRIVATE_KEY, provider);
  const nftManager = new ethers.Contract(
    NONFUNGIBLE_POSITION_MANAGER_ADDRESSES[chainId],
    NonfungiblePositionManagerABI,
    wallet
  );
  const tx = await nftManager.mint(params, {
    gasLimit: 3_000_000,
  });
  await tx.wait();
  console.log("Transaction hash: ", tx.hash);
}

async function main() {
  const provider = getProvider();
  const walletAddress = getWalletAddress();
  const WETH_Contract = new ethers.Contract(WETH_ADDRESS, ERC20ABI, provider);
  const USDC_Contract = new ethers.Contract(
    "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48",
    ERC20ABI,
    provider
  );
  console.log(
    "Before balance: ",
    ethers.utils.formatEther(await getBalance(WETH_Contract, walletAddress)),
    " / ",
    ethers.utils.formatUnits(await getBalance(USDC_Contract, walletAddress), 6)
  );
  console.log(
    "Quote: ",
    await getOutputQuote(
      WETH_ADDRESS,
      "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48",
      3000,
      ethers.utils.parseEther("0.1")
    )
  );
  await mintNewPosition(
    WETH_ADDRESS,
    "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48", // USDC
    3000,
    ethers.utils.parseEther("1"),
    ethers.utils.parseUnits("3000", 6)
  );
  console.log(
    "After balance: ",
    ethers.utils.formatEther(await getBalance(WETH_Contract, walletAddress)),
    " / ",
    ethers.utils.formatUnits(await getBalance(USDC_Contract, walletAddress), 6)
  );
}
main();

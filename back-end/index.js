const express = require("express");
const bodyParser = require("body-parser");
const cors = require("cors");
const dotenv = require("dotenv");
const helmet = require("helmet");
const morgan = require("morgan");
/* CONFIGUARATION */
dotenv.config();
const app = express();

app.use(express.json());
app.use(helmet());
app.use(helmet.crossOriginResourcePolicy({ policy: "cross-origin" }));
app.use(morgan("common"));
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: false }));
app.use(cors());

/* ROUTES */
app.get("/", (req, res) => {
  res.send("Hello World");
});

app.get("/api/v1/quote", (req, res) => {
  const { tokenIn, tokenOut, fee, amountIn } = req.query;
  const { getOutputQuote } = require("./scripts/quoter");
  getOutputQuote(tokenIn, tokenOut, fee, amountIn)
    .then((quote) => {
      res.status(200).json({ quote });
    })
    .catch((error) => {
      res.status(500).json({ error: error.message });
    });
});

app.get("/api/v1/swap", async (req, res) => {
  const {
    tokenIn,
    tokenOut,
    fee,
    amountIn,
    amountOutMinimum,
    amountOut,
    amountInMaximum,
    swapType,
  } = req.query;
  const { swap } = require("./scripts/swap");
  const params = await swap(
    tokenIn,
    tokenOut,
    parseInt(fee),
    amountIn,
    amountOutMinimum,
    amountOut,
    amountInMaximum,
    swapType
  );
  res.status(200).json({ params });
});

app.get("/api/v1/positions", async (req, res) => {
  const { fetchPostions } = require("./scripts/fetchPosition");
  const { walletAddress } = req.query;
  console.log(walletAddress);
  const positions = await fetchPostions(walletAddress);
  res.status(200).json({ positions });
});

app.get("/api/v1/addLiquidity", async (req, res) => {
  const { tokenId, amount0, amount1 } = req.query;
  const { addLiquidity } = require("./scripts/addLiquidity");
  const params = await addLiquidity(tokenId, amount0, amount1);
  res.status(200).json({ params });
});

app.get("/api/v1/removeLiquidity", async (req, res) => {
  const { tokenId, removePercent, recipient } = req.query;
  // DENOMINATOR = 10000;
  const { removeLiquidity } = require("./scripts/removeLiquidity");
  const params = await removeLiquidity(tokenId, removePercent, recipient);
  res.status(200).json({ params });
});

app.get("/api/v1/swapLP", async (req, res) => {
  const { tokenRemoveId, removePercent, tokenAddId, recipient } = req.query;
  const { swapLP } = require("./scripts/swapLP");
  const params = await swapLP(
    parseInt(tokenRemoveId),
    removePercent,
    parseInt(tokenAddId),
    recipient
  );
  res.status(200).json({ params });
});

app.listen(9000, () => {
  console.log("Server running on port 9000");
});

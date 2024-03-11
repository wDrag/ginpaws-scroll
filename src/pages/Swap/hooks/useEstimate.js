import { useState } from "react";
import { useAccount, useEstimateGas } from "wagmi";

const useEstimate = () => {
  const [estimatedGas, setEstimatedGas] = useState(undefined);
  const [estimatedTokenXAmount, setEstimatedTokenXAmount] = useState(undefined);
  const [estimatedTokenYAmount, setEstimatedTokenYAmount] = useState(undefined);

  const { address } = useAccount();

  const estimateGas = (
    tokenAAddress,
    tokenBAddress,
    tokenXAddress,
    tokenYAddress
  ) => {
    if (tokenAAddress && tokenBAddress && tokenXAddress && tokenYAddress) {
      const gas = "<0.001CFX";
      setEstimatedGas(gas);
    } else {
      setEstimatedGas(undefined);
      return;
    }
  };

  const estimateTokenAmount = (
    tokenA_Amount,
    tokenB_Amount,
    tokenX,
    tokenY,
    pairPercent
  ) => {
    if (!tokenX || !tokenY) {
      setEstimatedTokenXAmount(undefined);
      setEstimatedTokenYAmount(undefined);
      return;
    }
    if (tokenA_Amount && tokenB_Amount) {
      const tokenX_Amount = (
        ((tokenA_Amount * 95) / 100) *
        (pairPercent / 100)
      ).toFixed(4);
      const tokenY_Amount = (
        ((tokenB_Amount * 96) / 100) *
        (pairPercent / 100)
      ).toFixed(4);
      setEstimatedTokenXAmount(tokenX_Amount);
      setEstimatedTokenYAmount(tokenY_Amount);
    } else {
      setEstimatedTokenXAmount(undefined);
      setEstimatedTokenYAmount(undefined);
      return;
    }
  };

  return {
    estimatedGas,
    estimateGas,
    estimatedTokenXAmount,
    estimatedTokenYAmount,
    estimateTokenAmount,
  };
};

export default useEstimate;

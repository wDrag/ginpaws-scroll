import { useEffect, useState } from "react";
import CFXTokenList from "../../../json/CFXTokenList.json";
import ETHTokenList from "../../../json/ETHTokenList.json";
import CFXTestnetTokenList from "../../../json/CFXTestnetTokenList.json";
import GoerliTokenList from "../../../json/GoerliTokenList.json";

const useTokens = (activeChainID) => {
  const [pair_Percent, setPair_Percent] = useState(0);
  const [debouncedPair_Percent, setDebouncedPair_Percent] = useState(0);
  const [tokenE_Amount, setTokenE_Amount] = useState(undefined);
  const [tokenX_Amount, setTokenX_Amount] = useState(undefined);
  const [tokenY_Amount, setTokenY_Amount] = useState(undefined);

  const [tokenA_ListID, setTokenA_ListID] = useState(undefined);
  const [tokenB_ListID, setTokenB_ListID] = useState(undefined);
  const [tokenE_ListID, setTokenE_ListID] = useState(undefined);
  const [tokenX_ListID, setTokenX_ListID] = useState(undefined);
  const [tokenY_ListID, setTokenY_ListID] = useState(undefined);
  const [estimateFunction, setEstimateFunction] = useState(() => () => {});

  useEffect(() => {
    setTokenE_ListID(undefined);
    setTokenX_ListID(undefined);
    setTokenY_ListID(undefined);
    setPair_Percent(0);
    setTokenE_Amount(undefined);
    setTokenX_Amount(undefined);
    setTokenY_Amount(undefined);
  }, [activeChainID]);

  const changeAmount = (value, token) => {
    switch (token) {
      case "tokenE":
        setTokenE_Amount(value);
        break;
      case "tokenX":
        setTokenX_Amount(value);
        break;
      case "tokenY":
        setTokenY_Amount(value);
        break;
      default:
        break;
    }
  };

  const loadToken = ({ tokenASymbol, tokenBSymbol }) => {
    const tokenList = getTokenList();
    const tokenA = tokenList.find((token) => token.symbol === tokenASymbol);
    const tokenA_ID = tokenList.findIndex(
      (token) => token.symbol === tokenASymbol
    );
    const tokenB = tokenList.find((token) => token.symbol === tokenBSymbol);
    const tokenB_ID = tokenList.findIndex(
      (token) => token.symbol === tokenBSymbol
    );
    if (tokenA) {
      setTokenA_ListID(tokenA_ID);
    }
    if (tokenB) {
      setTokenB_ListID(tokenB_ID);
    }
  };

  const onAmountChange = (e, token) => {
    const value = e.target.value;
    const reg = /^-?\d*(\.\d*)?$/;
    if (value.match(reg) || value === "") {
      changeAmount(value, token);
    }
  };

  const onPairPercentChange = async (newValue, estimate) => {
    setPair_Percent(newValue);
    setEstimateFunction(() => estimate);
  };

  useEffect(() => {
    const timer = setTimeout(() => {
      setDebouncedPair_Percent(pair_Percent);
    }, 500);
    return () => clearTimeout(timer);
  }, [pair_Percent, 500]);

  useEffect(() => {
    console.log("estimateFunction: ", estimateFunction);
    if (estimateFunction) {
      estimateFunction();
    }
  }, [debouncedPair_Percent]);

  const handleChangeToken = (id, token) => {
    switch (token) {
      case "tokenA":
        setTokenA_ListID(id);
        break;
      case "tokenB":
        setTokenB_ListID(id);
        break;
      case "tokenE":
        setTokenE_ListID(id);
        break;
      case "tokenX":
        setTokenX_ListID(id);
        break;
      case "tokenY":
        setTokenY_ListID(id);
        break;
      default:
        break;
    }
  };

  const getTokenList = () => {
    switch (activeChainID) {
      case 1:
        return ETHTokenList;
      case 5:
        return GoerliTokenList;
      case 1030:
        return CFXTokenList;
      case 71:
        return CFXTestnetTokenList;
    }
  };

  const getToken = (token) => {
    const tokenList = getTokenList();
    switch (token) {
      case "tokenA":
        if (tokenA_ListID === undefined) return { symbol: "Select Token" };
        return tokenList[tokenA_ListID];
      case "tokenB":
        if (tokenB_ListID === undefined) return { symbol: "Select Token" };
        return tokenList[tokenB_ListID];
      case "tokenE":
        if (tokenE_ListID === undefined) return { symbol: "Select Token" };
        return tokenList[tokenE_ListID];
      case "tokenX":
        if (tokenX_ListID === undefined) return { symbol: "Select Token" };
        return tokenList[tokenX_ListID];
      case "tokenY":
        if (tokenY_ListID === undefined) return { symbol: "Select Token" };
        return tokenList[tokenY_ListID];
    }
  };

  return {
    pair_Percent,
    debouncedPair_Percent,
    tokenE_Amount,
    tokenX_Amount,
    tokenY_Amount,
    onAmountChange,
    getToken,
    handleChangeToken,
    onPairPercentChange,
    getTokenList,
    loadToken,
  };
};

export default useTokens;

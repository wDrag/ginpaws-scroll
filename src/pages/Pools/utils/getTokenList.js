import ETHTokenList from "../../../json/ETHTokenList.json";
import GoerliTokenList from "../../../json/GoerliTokenList.json";
import ScrollTokenList from "../../../json/ScrollTokenList.json";
import ScrollTestnetTokenList from "../../../json/ScrollTestnetTokenList.json";

const getTokenList = (activeChainID) => {
  switch (activeChainID) {
    case 1:
      return ETHTokenList;
    case 5:
      return GoerliTokenList;
    case 534352:
      return ScrollTokenList;
    case 534351:
      return ScrollTestnetTokenList;
  }
};

export default getTokenList;

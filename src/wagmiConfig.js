import { http, createConfig } from "wagmi";
import {
  mainnet,
  goerli,
  sepolia,
  scrollSepolia,
  scroll
} from "wagmi/chains";
import { injected } from "wagmi/connectors";

export const WagmiConfig = createConfig({
  chains: [mainnet, sepolia, goerli, scroll, scrollSepolia],
  connectors: [injected()],
  transports: {
    [mainnet.id]: http(),
    [sepolia.id]: http(),
    [goerli.id]: http(),
    [scroll.id]: http(),
    [scrollSepolia.id]: http(),
  },
});

import { useWeb3Modal } from "@web3modal/wagmi/react";
import { useAccount } from "wagmi";
import { shortenAddr } from "../utils/shortenAddr";
import { NavLink } from "react-router-dom";

const Header = () => {
  const { open } = useWeb3Modal();
  const { address, isDisconnected } = useAccount();

  return (
    <div className="container mx-auto px-10 py-2 border-b">
      <div className="flex items-center justify-between">
        <NavLink to="/">
          <div className="flex items-center text-xl">
            <img
              className="h-[60px] w-[60px]"
              alt="lightpad-logo"
              src="/lightpad-logo.png"
            />
            <h1>LIGHTPAD</h1>
          </div>
        </NavLink>
        <nav>
          <ul className="flex items-center gap-6">
            {/* <li className="hover:underline transition-all">
              <NavLink to="/projects">Projects</NavLink>
            </li> */}
            {/* <li className="hover:underline transition-all">
              <NavLink to="/dashboard">Dashboard</NavLink>
            </li> */}
            <li className="hover:underline transition-all">
              <a
                href="https://github.com/terrancrypt/lightpad?tab=readme-ov-file#lightpad"
                target="_blank"
                rel="noopener noreferrer"
              >
                Documentation
              </a>
            </li>
          </ul>
        </nav>
        <div>
          {isDisconnected ? (
            <button
              className="rounded-full px-4 py-2 bg-[#0072bc] text-white active:none hover:scale-95 transition-all"
              onClick={() => open()}
            >
              Connect Wallet
            </button>
          ) : (
            <button
              className="rounded-full px-4 py-2 bg-[#0072bc] text-white active:none hover:scale-95 transition-all"
              onClick={() => open()}
            >
              <span>{shortenAddr(address)}</span>
            </button>
          )}
        </div>
      </div>
    </div>
  );
};

export default Header;

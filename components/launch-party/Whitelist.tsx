import { useEffect, useState } from "react";
import { useConnectedContext } from "../context/connected";
import { useRecoilState, useRecoilValue } from "recoil";
import { BigNumber, utils } from "ethers";
import { TheUbiquityStickSale, TheUbiquityStickSale__factory } from "./lib/types";
import { isWhitelistedState, sticksAllowanceState } from "./lib/states";
import Vip from "../ui/vip.svg";
import { EthAccount } from "../common/types";
import { performTransaction } from "../common/utils";

// const SaleContractAddress = "0x035e4568f2738917512e4222a8837ad22d21bb1d";
const SaleContractAddress = "0x23EEe0f3fD17b25C16C712e90c77A6d165a54d2f";

// const useSaleContract = (fn: (saleContract: TheUbiquityStickSale, account: EthAccount) => any) => {
//   const { provider, account } = useConnectedContext();
//   const [saleContract, setSaleContract] = useState<TheUbiquityStickSale | null>(null);

//   useEffect(() => {
//     let newSaleContract = saleContract;

//     if (provider) {
//       const signer = provider.getSigner();

//       if (!saleContract && provider) {
//         newSaleContract = TheUbiquityStickSale__factory.connect(SaleContractAddress, provider);
//       }

//       if (newSaleContract && !newSaleContract.signer && signer) {
//         newSaleContract = newSaleContract.connect(signer);
//       }

//       console.log("NewSaleContract signer?", newSaleContract?.signer);

//       if (newSaleContract !== saleContract) {
//         setSaleContract(newSaleContract);

//         if (newSaleContract && newSaleContract?.signer) {
//           (async () => {
//             await fn(newSaleContract);
//           })();
//         }
//       }
//     }
//   }, [provider, account]);

//   return saleContract;
// };

const WhitelistContainer = () => {
  const { provider, account } = useConnectedContext();
  const [sticksAllowance, setSticksAllowance] = useRecoilState(sticksAllowanceState);
  const [isOwner, setIsOwner] = useState<boolean>(false);
  const isWhiteListed = useRecoilValue(isWhitelistedState);
  // useSaleContract((saleContract) => {
  //   console.log("Gotten sale contract!", saleContract);
  // });

  useEffect(() => {
    if (provider && account) {
      (async () => {
        const SaleContract = TheUbiquityStickSale__factory.connect(SaleContractAddress, provider);
        const allowance = await SaleContract.allowance(account.address);
        console.log(allowance);
        setSticksAllowance({ count: +allowance.count.toString() / 1e18, price: +allowance.price.toString() / 1e18 });
        const ownerAddress = await SaleContract.owner();

        setIsOwner(ownerAddress.toLowerCase() === account.address.toLowerCase());
      })();
    }
  }, [provider, account]);

  console.log("isWhiteListed", isWhiteListed);

  const status = !account ? "not-connected" : sticksAllowance ? (isWhiteListed ? "whitelisted" : "not-whitelisted") : "connected";

  return <Whitelist status={status} isOwner={isOwner} />;
};

export type WhitelistStatus = "not-connected" | "connected" | "whitelisted" | "not-whitelisted";

const AllowanceManager = () => {
  const { provider, account, updateActiveTransaction } = useConnectedContext();
  const [address, setAddress] = useState<string>(account?.address || "");
  const [count, setCount] = useState<string>("");
  const [price, setPrice] = useState<string>("");

  const setAllowance = async () => {
    if (provider && account && address && count && price) {
      const SaleContract = TheUbiquityStickSale__factory.connect(SaleContractAddress, provider);
      updateActiveTransaction({ id: "UBIQUISTICK_ALLOWANCE", title: "Setting allowance...", active: true });
      await performTransaction(SaleContract.connect(provider.getSigner()).setAllowance(address, utils.parseEther(count), utils.parseEther(price)));
      updateActiveTransaction({ id: "UBIQUISTICK_ALLOWANCE", active: false });
    }
  };

  return (
    <div>
      <h2 className="m-0 mb-2 tracking-widest uppercase text-base mt-4">Allowance management</h2>
      <input placeholder="Address" value={address} onChange={(ev) => setAddress(ev.target.value)} />
      <input placeholder="Count" type="number" value={count} onChange={(ev) => setCount(ev.target.value)} />
      <input placeholder="Price" type="number" value={price} onChange={(ev) => setPrice(ev.target.value)} />
      <button disabled={!address || count === "" || price === ""} onClick={setAllowance}>
        Apply
      </button>
    </div>
  );
};

const Whitelist = ({ status, isOwner }: { status: WhitelistStatus; isOwner: boolean }) => {
  return (
    <div className="party-container">
      <div className="flex">
        <div>
          <Vip className="fill-white h-20 px-8 py-4" />
        </div>
        <div className="flex-grow flex items-center justify-center text-center">
          {(() => {
            switch (status) {
              case "not-connected":
                return <h2 className="m-0 tracking-widest uppercase text-base">Connect your wallet to check if you are on the whitelist</h2>;
              case "connected":
                return (
                  <>
                    <div className="loader mr-4"></div>
                    <h2 className="m-0 tracking-widest uppercase text-base">
                      Checking if you are
                      <br />
                      on the whitelist
                    </h2>
                  </>
                );
              case "whitelisted":
                return (
                  <div>
                    <h2 className="m-0 mb-2 tracking-widest uppercase text-base">You are whitelisted</h2>
                    <p className="m-0 font-light tracking-wide">You may mint a UbiquiStick and use the exclusive pools</p>
                  </div>
                );
              case "not-whitelisted":
                return (
                  <div>
                    <h2 className="m-0 mb-2 tracking-widest uppercase text-base">You are not whitelisted</h2>
                    <p className="m-0 mb-4 font-light tracking-wide">In order to participate you need to be on the whitelist</p>
                    <a
                      className="btn-primary"
                      target="_blank"
                      href="https://twitter.com/intent/tweet?text=%40UbiquityDAO%20I%20want%20to%20be%20whitelisted%20for%20the%20launch%20party%20https%3A%2F%2Fuad.ubq.fi%2Flaunch-party"
                    >
                      I want in
                    </a>
                  </div>
                );
            }
          })()}
        </div>
      </div>
      {isOwner ? <AllowanceManager /> : null}
    </div>
  );
};

export default WhitelistContainer;

import { BigNumber, ethers } from "ethers";
import { memo, useState, useCallback } from "react";
import { connectedWithUserContext, useConnectedContext, UserContext } from "./context/connected";

export const DebtCoupon = () => {
  return (
    <div>
      <span>Debt Coupon</span>
      <div></div>
      <span>Burn uAD for debt coupons and help pump the price back up</span>
      <span>Pump Cycle</span>
      <div>
        <div>
          <span>Fungible (uAR)</span>
          <table>
            <tbody>
              <tr>
                <td>Deprecation rate</td>
                <td>10% / week</td>
              </tr>
              <tr>
                <td>Current reward %</td>
                <td>10%</td>
              </tr>
              <tr>
                <td>Expires?</td>
                <td>No</td>
              </tr>
            </tbody>
          </table>
          <span>Higher priority when redeeming</span>
          <a href="">Learn more</a>
        </div>
        <div>
          <span>Non-fungible (uDEBT)</span>
          <table>
            <tbody>
              <tr>
                <td>Deprecation rate</td>
                <td>0%</td>
              </tr>
              <tr>
                <td>Current reward %</td>
                <td>15%</td>
              </tr>
              <tr>
                <td>Expires?</td>
                <td>After 30 days</td>
              </tr>
            </tbody>
          </table>
          <span>convertible to fungible</span>
          <span>Can be redeemed for UBQ at 25% rate</span>
          <a href="">Learn more</a>
        </div>
      </div>
      <div className="inline-flex">
        <span>uAD</span>
        <input type="text" />
        <nav className="flex flex-col sm:flex-row">
          <button className="text-gray-600 py-4 px-6 block hover:text-blue-500 focus:outline-none text-blue-500 border-b-2 font-medium border-blue-500">
            uAR
          </button>
          <button className="text-gray-600 py-4 px-6 block hover:text-blue-500 focus:outline-none">uDEBT</button>
        </nav>
        <button>Burn</button>
      </div>
      <div>
        <span>Price will increase by an estimated of +$0.05</span>
      </div>
      <div>
        <span>Reward Cycle</span>
      </div>
      <div>
        <div className="inline-flex">
          <div>
            <span>uAD</span>
          </div>
          <div>
            <div>Total Supply</div>
            <div>233k</div>
          </div>
          <div>
            <div>Minted</div>
            <div>25k</div>
          </div>
          <div>
            <div>Mintable</div>
            <div>12k</div>
          </div>
        </div>
      </div>
      <div>
        <div className="inline-flex">
          <div>
            <span>Total debt</span>
          </div>
          <div className="inline-flex">
            <div>
              <div>uBOND</div>
              <div>10,000</div>
            </div>
            <div>
              <div>uAR</div>
              <div>30,000</div>
            </div>
            <div>
              <div>uDEBT</div>
              <div>5,000</div>
            </div>
          </div>
        </div>
      </div>
      <div>
        <div className="inline-flex">
          <div>
            <span>Redeemable</span>
          </div>
          <div className="inline-flex">
            <div>10,000</div>
            <div>27,000</div>
            <div>0</div>
          </div>
        </div>
      </div>
      <div>
        <span>Your Coupons</span>
      </div>
      <div>
        <div>
          <div className="inline-flex">
            <div>
              <span>uBOND 1,000</span>
            </div>
            <div className="inline-flex">
              <input type="text" />
              <button>Redeem</button>
            </div>
          </div>
        </div>
        <div>
          <div className="inline-flex">
            <div>
              <span>uAR 3,430 - $2,120</span>
            </div>
            <div className="inline-flex">
              <input type="text" />
              <button>Redeem</button>
            </div>
          </div>
        </div>
        <div>
          <div className="inline-flex">
            <div>
              <span>Deprecation rate 10% / week</span>
            </div>
            <div className="inline-flex">
              <span>2120 uDEBT</span>
              <button>Swap</button>
            </div>
          </div>
        </div>
      </div>
      <div>
        <table>
          <thead>
            <tr>
              <th>uDEBT</th>
              <th>Expiration</th>
              <th>Swap</th>
              <th></th>
            </tr>
          </thead>
          <tbody>
            <tr>
              <td>1,000</td>
              <td>3.2 weeks</td>
              <td>800 uAR</td>
              <td>
                <button>Redeem</button>
              </td>
            </tr>
            <tr>
              <td>500</td>
              <td>1.3 weeks</td>
              <td>125 uAR</td>
              <td>
                <button>Redeem</button>
              </td>
            </tr>
            <tr>
              <td>666</td>
              <td>Expired</td>
              <td>166.5 UBQ</td>
              <td></td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
  );
};

export default connectedWithUserContext(DebtCoupon);

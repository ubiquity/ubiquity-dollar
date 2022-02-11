import { FC } from "react";
import icons from "../components/ui/icons";

const Markets: FC = (): JSX.Element => {
  return (
    <div id="markets">
      <div>
        <aside> Primary Markets</aside>
      </div>
      <div>
        <div id="uad-market">
          <div>
            {icons.svgs.uad}
            <span>uAD</span>
          </div>
          <div>
            <a target="_blank" href="https://crv.to">
              <input type="button" value="Swap" />
            </a>
          </div>
          <div>
            <a target="_blank" href="https://crv.to/pool">
              <input type="button" value="Deposit" />
            </a>
          </div>
        </div>
        <div id="ubq-market">
          <div>
            <span>{icons.svgs.ubq}</span>
            <span>UBQ</span>
          </div>
          <div>
            <a
              target="_blank"
              href="https://app.sushi.com/swap?inputCurrency=0x4e38D89362f7e5db0096CE44ebD021c3962aA9a0&outputCurrency=0x0F644658510c95CB46955e55D7BA9DDa9E9fBEc6"
            >
              <input type="button" value="Swap" />
            </a>
          </div>
          <div>
            <a target="_blank" href="https://app.sushi.com/add/0x4e38D89362f7e5db0096CE44ebD021c3962aA9a0/0x0F644658510c95CB46955e55D7BA9DDa9E9fBEc6">
              <input type="button" value="Deposit" />
            </a>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Markets;

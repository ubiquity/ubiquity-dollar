import { FC } from "react";
import { Icon } from "../components/ui/icons";
import * as widget from "../components/ui/widget";

const Markets: FC = (): JSX.Element => {
  return (
    <widget.Container>
      <widget.Title text="Primary Markets" />
      <div className="flex justify-around">
        <div>
          <div className="flex justify-center items-center mb-2">
            <span className="text-accent">
              <Icon icon="uad" className="w-8 mr-2" />
            </span>
            <span className="leading-[28px]">uAD</span>
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
        <div>
          <div className="flex justify-center items-center mb-2">
            <span className="text-accent">
              <Icon icon="ubq" className="w-8 mr-2" />
            </span>
            <span className="leading-[28px]">UBQ</span>
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
    </widget.Container>
  );
};

export default Markets;

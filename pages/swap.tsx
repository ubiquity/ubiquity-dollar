import { ButtonLink } from "@/components/ui/Button";
import Icon, { IconsNames } from "@/components/ui/Icon";
import { FC } from "react";

const Currency = ({ name, icon }: { name: string; icon: IconsNames }) => (
  <div>
    <span>
      <Icon icon={icon} />
    </span>
    <span>{name}</span>
  </div>
);

const Markets: FC = (): JSX.Element => {
  return (
    <div>
      <h2>Primary Markets</h2>

      <div>
        <div>
          <Currency name="uAD" icon="uad" />
          <ButtonLink target="_blank" href="https://crv.to">
            Swap
          </ButtonLink>
          <ButtonLink target="_blank" href="https://crv.to/pool">
            Deposit
          </ButtonLink>
        </div>
        <div>
          <Currency name="UBQ" icon="ubq" />
          <ButtonLink
            target="_blank"
            href="https://app.sushi.com/swap?inputCurrency=0x4e38D89362f7e5db0096CE44ebD021c3962aA9a0&outputCurrency=0x0F644658510c95CB46955e55D7BA9DDa9E9fBEc6"
          >
            Swap
          </ButtonLink>
          <ButtonLink target="_blank" href="https://app.sushi.com/add/0x4e38D89362f7e5db0096CE44ebD021c3962aA9a0/0x0F644658510c95CB46955e55D7BA9DDa9E9fBEc6">
            Deposit
          </ButtonLink>
        </div>
      </div>
    </div>
  );
};

export default Markets;

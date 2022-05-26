import { FC } from "react";
import { Icon, IconsNames, Container, Title, ButtonLink } from "@/ui";

const Currency = ({ name, icon }: { name: string; icon: IconsNames }) => (
  <div className="flex items-center justify-center">
    <span className="text-accent">
      <Icon icon={icon} className="mr-2 w-8" />
    </span>
    <span>{name}</span>
  </div>
);

const Markets: FC = (): JSX.Element => {
  return (
    <Container>
      <Title text="Primary Markets" />

      <div className="grid grid-cols-2 gap-4">
        <div className="grid w-40 grid-cols-1 gap-4">
          <Currency name="uAD" icon="uad" />
          <ButtonLink fill="full" target="_blank" href="https://crv.to">
            Swap
          </ButtonLink>
          <ButtonLink fill="full" target="_blank" href="https://crv.to/pool">
            Deposit
          </ButtonLink>
        </div>
        <div className="grid w-40 grid-cols-1 gap-4">
          <Currency name="UBQ" icon="ubq" />
          <ButtonLink
            fill="full"
            target="_blank"
            href="https://app.sushi.com/swap?inputCurrency=0x4e38D89362f7e5db0096CE44ebD021c3962aA9a0&outputCurrency=0x0F644658510c95CB46955e55D7BA9DDa9E9fBEc6"
          >
            Swap
          </ButtonLink>
          <ButtonLink
            fill="full"
            target="_blank"
            href="https://app.sushi.com/add/0x4e38D89362f7e5db0096CE44ebD021c3962aA9a0/0x0F644658510c95CB46955e55D7BA9DDa9E9fBEc6"
          >
            Deposit
          </ButtonLink>
        </div>
      </div>
    </Container>
  );
};

export default Markets;

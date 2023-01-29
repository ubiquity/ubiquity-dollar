import { ButtonLink } from "old-components/ui/Button";
import Icon, { IconsNames } from "old-components/ui/Icon";

const Currency = ({ name, icon }: { name: string; icon: IconsNames }) => (
  <>
    <span>
      <Icon icon={icon} />
    </span>
    <span>{name}</span>
  </>
);

export default function Markets() {
  return (
    <div id="Markets" className="panel">
      <h2>Primary Markets</h2>

      <div>
        <div>
          <Currency name="Ubiquity Dollar 3pool (uAD-3crv)" icon="uad" />
          <ButtonLink target="_blank" href="https://crv.to/pool">
            LP
          </ButtonLink>
          <ButtonLink target="_blank" href="https://crv.to">
            Swap
          </ButtonLink>
        </div>
        <div>
          <Currency name="Ubiquity Governance (UBQ-uAD)" icon="ubq" />
          <ButtonLink target="_blank" href="https://app.sushi.com/add/0x4e38D89362f7e5db0096CE44ebD021c3962aA9a0/0x0F644658510c95CB46955e55D7BA9DDa9E9fBEc6">
            LP
          </ButtonLink>
          <ButtonLink
            target="_blank"
            href="https://app.sushi.com/swap?inputCurrency=0x4e38D89362f7e5db0096CE44ebD021c3962aA9a0&outputCurrency=0x0F644658510c95CB46955e55D7BA9DDa9E9fBEc6"
          >
            Swap
          </ButtonLink>
        </div>
      </div>
    </div>
  );
}

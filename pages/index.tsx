import FullDeployment from "../fixtures/ubiquity-dollar-deployment.json";

export const ADDRESS = {
  MANAGER: FullDeployment.contracts.UbiquityAlgorithmicDollarManager.address,
  DEBT_COUPON_MANAGER: FullDeployment.contracts.DebtCouponManager.address,
};

export { default as default } from "./price-stabilization";

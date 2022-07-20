// Utiliy functions for curve lp pool

import { BigNumber, constants, utils } from "ethers"

export const N_COINS = 2;
export const A_PRECISION = 100
export const PRECISION = utils.parseEther("1");
export const FEE_DENOMINATOR = utils.parseUnits("1", 10);
export const RATE_MULTIPLIER = utils.parseEther("1");


const get_D = (_xp: BigNumber[], _amp: BigNumber): BigNumber => {
    let S = constants.Zero;
    let Dprev = constants.Zero;

    for (const x of _xp) {
        S = S.add(x);
    }

    if (S.eq(0)) return constants.Zero;

    let D = S;
    let Ann = _amp.mul(N_COINS);
    for (let i = 0; i < 255; i++) {
        let D_P = D;
        for (const x of _xp) {
            D_P = D_P.mul(D).div(x.mul(N_COINS));
        }

        Dprev = D;
        D = (Ann.mul(S).div(A_PRECISION).add(D_P.mul(N_COINS))).mul(D).div(Ann.sub(A_PRECISION).mul(D).div(A_PRECISION).sub(D_P.mul(N_COINS + 1)));

        if (D.gt(Dprev)) {
            if (D.sub(Dprev).lte(1)) {
                return D;
            }
        } else {
            if (Dprev.sub(D).lte(1)) {
                return D;
            }
        }
    }

    return constants.Zero;

}

const _xp_mem = (_rates: BigNumber[], _balances: BigNumber[]): BigNumber[] => {
    const result: BigNumber[] = [];
    for (let i = 0; i < N_COINS; i++) {
        result[i] = _rates[i].mul(_balances[i]).div(PRECISION);
    }

    return result;
}

export const get_D_mem = (_rates: BigNumber[], _balances: BigNumber[], _amp: BigNumber): BigNumber => {
    const xp = _xp_mem(_rates, _balances);
    return get_D(xp, _amp);
}

export interface ImBalanceParam {
    amp: BigNumber;
    virtual_price: BigNumber;
    fee: BigNumber;
    balances: BigNumber[];
    totalSupply: BigNumber;
    amounts: BigNumber[];
}

export const get_burn_lp_amount = (args: ImBalanceParam): BigNumber => {
    const { amp, virtual_price, fee, balances, totalSupply, amounts } = args;
    const rates = [RATE_MULTIPLIER, virtual_price];
    const old_balances = balances;
    const D0 = get_D_mem(rates, old_balances, amp);

    let new_balances = old_balances;
    for (let i = 0; i < N_COINS; i++) {
        new_balances[i] = new_balances[i].sub(amounts[i]);
    }

    const D1 = get_D_mem(rates, new_balances, amp);
    const base_fee = fee.mul(N_COINS).div(4 * (N_COINS - 1));
    let fees: BigNumber[] = [];

    for (let i = 0; i < N_COINS; i++) {
        const ideal_balance = D1.mul(old_balances[i]).div(D0);
        let difference = constants.Zero;
        const new_balance = new_balances[i];
        if (ideal_balance > new_balance) {
            difference = ideal_balance.sub(new_balance);
        } else {
            difference = new_balance.sub(ideal_balance);
        }

        fees[i] = base_fee.mul(difference).div(FEE_DENOMINATOR);
        new_balances[i] = new_balances[i].sub(fees[i]);
    }

    const D2 = get_D_mem(rates, new_balances, amp);
    const burn_amount = (D0.sub(D2).mul(totalSupply).div(D0)).add(1);

    return burn_amount;

}
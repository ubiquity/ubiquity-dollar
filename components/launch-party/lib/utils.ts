const formatter = new Intl.NumberFormat("en-US");
const formatterFixed = new Intl.NumberFormat("en-US", { minimumFractionDigits: 2 });
export const format = (n: number) => formatter.format(n);
export const formatFixed = (n: number) => formatterFixed.format(n);
export const round = (n: number) => Math.round(n * 100) / 100;

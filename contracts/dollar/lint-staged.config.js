module.exports = {
  "*.{js,ts}": ["eslint --fix"],
  "*.{md,json,sol}": ["prettier --write"],
  "**/contracts": ["solhint --ignore-path .solhintignore"],
};

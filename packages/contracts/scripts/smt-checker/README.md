# SMT-Checker Support for Smart Contract Testing

This repository provides SMT-Checker support for testing smart contracts. Follow these steps to get started:


## Make Sure Your System Has Z3 Installed >= "4.8.11"

Ensure that your system has Z3 installed with a version number greater than or equal to the required version.

## Step 1: Download and Install Z3

Before proceeding, ensure that you have `g++` and `python3` installed on your system. To download and install Z3, enter the following commands in your terminal:

### Run script:
```
sh ./update-dependencies.sh
```

Once installed, you can verify that Z3 is correctly installed by checking the version number.

## Step 3: Use Forge to Test Contracts Using SMT

Check that you do not have a profile ready at foundry.toml you might skip this step, else run
```
npx tsx smt-checker/smt/update.ts
```

This will add a new pre-defined profile to foundry.toml for testing & compiling contracts using SMTChecker

### Export a foundry env variable to make use of the profile

```
export FOUNDRY_PROFILE=SMT
```


https://github.com/molecula451/ubiquity-dollar/assets/41552663/cdcf3982-94a4-4cf5-8962-c49982b7c83a



Ensure that your repository is up-to-date with the latest npm/yarn packages, then run the following command:

```
sh ./run-smt-setup.sh
```


https://github.com/molecula451/ubiquity-dollar/assets/41552663/a4cad18e-0686-4637-bd0e-e229159543fe



This will prompt you to select a contract. Once selected, check that the contract was updated in Foundry, then build it using forge build. Wait for the SMT-Checker results to appear after compiling.

![checker](https://github.com/molecula451/ubiquity-dollar/assets/41552663/a8e6a3de-2ccf-40bd-8d19-c1b4203c466f)
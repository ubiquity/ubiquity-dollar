import React from "react";
import Button from "../../ui/button";
import { createTestClient, http, publicActions, walletActions } from "viem";
import { foundry } from "viem/chains";
import { methodConfigs } from "./method-configs";
import Image from "next/image";
import Download from "../../../public/download.svg";

export default function AnvilRpcs() {
  const [isHidden, setIsHidden] = React.useState<boolean>(true);
  const [isVisible, setIsVisible] = React.useState<number>(0);
  const [methodArgs, setMethodArgs] = React.useState<Record<string, string>>({});

  const testClient = createTestClient({
    // Defaults to same deployer as /contracts/.env
    // Is required if you want to call sendTransaction
    // Current setup does not allow access to Anvil's 10 accounts
    // for testing I ran a standalone node and used account[0]
    // 0x70997970C51812dc3A010C7d01b50e0d17dc79C8
    account: "0x70997970C51812dc3A010C7d01b50e0d17dc79C8",
    chain: foundry,
    mode: "anvil",
    transport: http(),
  })
    .extend(walletActions)
    .extend(publicActions);

  const handleMethodCall = async (meth: string) => {
    const method = methodConfigs.find((method) => method.methodName === meth);

    if (!method) {
      console.error(`No method found for ${meth} in methodConfigs`);
      return;
    }

    const args = method.params.map((arg) => methodArgs[arg.name]);
    console.log("args", args);
    const methodArgTypes = method.params.map((arg) => arg.type);
    console.log("methodArgTypes", methodArgTypes);
    args.forEach((arg, i) => {
      try {
        arg = arg.trim();
      } catch (e) {
        /* empty */
      }
      if (methodArgTypes[i] === "number") {
        args[i] = Number(arg);
      } else if (methodArgTypes[i] === "boolean") {
        args[i] = Boolean(arg);
      } else if (methodArgTypes[i] === "bigint") {
        args[i] = BigInt(arg);
      }
    });

    let result;

    try {
      if (method.methodName === "sendTransaction" || method.methodName === "sendUnsignedTransaction") {
        throw new Error();
      }
      result = await testClient.request({
        method: method?.methodName,
        params: args,
      });
    } catch (error0) {
      const name = method?.methodName;
      console.log("error0", error0);
      try {
        name === "sendUnsignedTransaction"
          ? await testClient.sendUnsignedTransaction({
              from: args[0],
              to: args[1],
              value: args[2],
            })
          : name === "sendTransaction"
          ? await testClient.sendTransaction({
              from: args[0],
              to: args[1],
              value: args[2],
            })
          : null;
      } catch (error1) {
        console.error(`Fallback failed - Error0: ${error0} - Error1: ${error1}`);
      }
    }
    for (let i = 0; i < args.length; i++) {
      document.getElementById(`${method.methodName}-input-${i}}`).value = "";
    }

    setMethodArgs({});

    console.log(result);

    if (method.download) {
      if (!result) return console.log("No result");

      const blob = new Blob([JSON.stringify(result)], { type: "application/json" });
      const url = URL.createObjectURL(blob);
      document.getElementById(`${method.methodName}-output`)?.setAttribute("href", url);
    }
  };

  return (
    <div className="rpc-method-container">
      <div>
        <Button
          onClick={() => {
            setIsHidden(!isHidden);
            setIsVisible(0);
          }}
        >
          Custom RPC Methods
        </Button>
        <div className="table-container">
          <div style={{ display: isHidden ? "none" : "block" }}>
            <div style={{ display: "flex", flexDirection: "row" }}>
              {isVisible == 0 && (
                <>
                  <Button onClick={() => setIsVisible(1)}>Chain Methods</Button>
                  <Button onClick={() => setIsVisible(2)}>User Methods</Button>
                  <Button onClick={() => setIsVisible(3)}>Utility Methods</Button>
                </>
              )}
            </div>
            {isVisible == 1 && (
              <>
                <Button style={{ maxWidth: "250px", marginBottom: "6px" }} onClick={() => setIsVisible(0)}>
                  Back
                </Button>
                <tb>
                  <tr>
                    <th>Method</th>
                    <th>Params</th>
                    <th>Call</th>
                  </tr>
                  {methodConfigs
                    .filter((method) => method.type === "chain")
                    .map((method) => {
                      const handleInputChange = (argName, value) => {
                        setMethodArgs((prevArgs) => ({ ...prevArgs, [argName]: value }));
                      };

                      return (
                        <tr key={method.methodName}>
                          <td>
                            {method.name}
                            {"  "}
                            {method.download ? <Image src={Download} width={250} alt="logo" style={{ cursor: "pointer" }} /> : null}{" "}
                          </td>
                          <td>
                            {method.params.map((param, i) => (
                              <div key={param.name}>
                                <input
                                  id={`${method.methodName}-input-${i}}`}
                                  type="text"
                                  placeholder={param.name}
                                  onChange={(e) => handleInputChange(param.name, e.target.value)}
                                />
                              </div>
                            ))}
                          </td>
                          <td>
                            <Button onClick={() => handleMethodCall(method.methodName)}>Call</Button>
                          </td>
                        </tr>
                      );
                    })}
                </tb>
              </>
            )}

            {isVisible == 2 && (
              <>
                <Button style={{ maxWidth: "250px", marginBottom: "6px" }} onClick={() => setIsVisible(0)}>
                  Back
                </Button>
                <tb>
                  <tr>
                    <th>Method</th>
                    <th>Params</th>
                    <th>Call</th>
                  </tr>
                  {methodConfigs
                    .filter((method) => method.type === "user")
                    .map((method) => {
                      const handleInputChange = (argName, value) => {
                        setMethodArgs((prevArgs) => ({ ...prevArgs, [argName]: value }));
                      };

                      return (
                        <tr key={method.methodName}>
                          <td>
                            {method.name}
                            {"  "}
                            {method.download ? <Image src={Download} width={250} alt="logo" style={{ cursor: "pointer" }} /> : null}{" "}
                          </td>
                          <td>
                            {method.params.map((param, i) => (
                              <div key={param.name}>
                                <input
                                  id={`${method.methodName}-input-${i}}`}
                                  type="text"
                                  placeholder={param.name}
                                  onChange={(e) => handleInputChange(param.name, e.target.value)}
                                />
                              </div>
                            ))}
                          </td>
                          <td>
                            <Button onClick={() => handleMethodCall(method.methodName)}>Call</Button>
                          </td>
                        </tr>
                      );
                    })}
                </tb>
              </>
            )}

            {isVisible == 3 && (
              <>
                <Button style={{ maxWidth: "250px", marginBottom: "6px" }} onClick={() => setIsVisible(0)}>
                  Back
                </Button>
                <tb>
                  <tr>
                    <th>Method</th>
                    <th>Params</th>
                    <th>Call</th>
                  </tr>
                  {methodConfigs
                    .filter((method) => method.type === "utility")
                    .map((method) => {
                      const handleInputChange = (argName, value) => {
                        setMethodArgs((prevArgs) => ({ ...prevArgs, [argName]: value }));
                      };

                      return (
                        <tr key={method.methodName}>
                          <td>
                            {method.name}
                            {"  "}
                            {method.download ? (
                              <a id={`${method.methodName}-output`} href={method.download} download={`${method.methodName}-output`}>
                                <Image src={Download} width={250} alt="logo" style={{ cursor: "pointer" }} />
                              </a>
                            ) : null}{" "}
                          </td>
                          <td>
                            {method.params.map((param, i) => (
                              <div key={param.name}>
                                <input
                                  id={`${method.methodName}-input-${i}}`}
                                  type="text"
                                  placeholder={param.name}
                                  onChange={(e) => handleInputChange(param.name, e.target.value)}
                                />
                              </div>
                            ))}
                          </td>
                          <td>
                            <Button onClick={() => handleMethodCall(method.methodName)}>Call</Button>
                          </td>
                        </tr>
                      );
                    })}
                </tb>
              </>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}

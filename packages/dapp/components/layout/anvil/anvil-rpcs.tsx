import React from "react";
import Button from "../../ui/button";
import { createTestClient, http } from "viem";
import { foundry } from "viem/chains";
import { methodConfigs } from "./method-configs";

export default function AnvilRpcs() {
  const [isHidden, setIsHidden] = React.useState<boolean>(true);
  const [isVisible, setIsVisible] = React.useState<number>(0);
  const [methodArgs, setMethodArgs] = React.useState<Record<string, string>>({});

  const testClient = createTestClient({
    chain: foundry,
    mode: "anvil",
    transport: http(),
  });

  const handleMethodCall = async (meth: string) => {
    const method = methodConfigs.find((method) => method.methodName === meth);

    if (!method) {
      console.error("Method not found");
      return;
    }

    const args = method.params.map((arg) => methodArgs[arg.name]);

    const methodArgTypes = method.params.map((arg) => arg.type);

    args.forEach((arg, i) => {
      arg = arg.trim();
      if (methodArgTypes[i] === "number") {
        args[i] = Number(arg);
      } else if (methodArgTypes[i] === "boolean") {
        args[i] = arg === "true";
      } else if (methodArgTypes[i] === "bigint") {
        args[i] = BigInt(arg);
      }
    });

    const result = await testClient.request({
      method: method?.methodName,
      params: args,
    });
    setMethodArgs({});
    console.log(result);
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
                <Button style={{ maxWidth: "250px" }} onClick={() => setIsVisible(0)}>
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
                          <td>{method.name}</td>
                          <td>
                            {method.params.map((param) => (
                              <div key={param.name}>
                                <input type="text" placeholder={param.name} onChange={(e) => handleInputChange(param.name, e.target.value)} />
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
                <Button style={{ maxWidth: "250px" }} onClick={() => setIsVisible(0)}>
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
                          <td>{method.name}</td>
                          <td>
                            {method.params.map((param) => (
                              <div key={param.name}>
                                <input type="text" placeholder={param.name} onChange={(e) => handleInputChange(param.name, e.target.value)} />
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
                <Button style={{ maxWidth: "250px" }} onClick={() => setIsVisible(0)}>
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
                          <td>{method.name}</td>
                          <td>
                            {method.params.map((param) => (
                              <div key={param.name}>
                                <input type="text" placeholder={param.name} onChange={(e) => handleInputChange(param.name, e.target.value)} />
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

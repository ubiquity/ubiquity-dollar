import Button from "../../ui/button";
import { methodConfigs } from "./method-configs";
import useWeb3 from "@/components/lib/hooks/use-web-3";
import { LOCAL_NODE_ADDRESS } from "@/components/lib/hooks/use-web-3";
import { useState } from "react";

export default function AnvilRpcs() {
  const [isHidden, setIsHidden] = useState<boolean>(true);
  const [isVisible, setIsVisible] = useState<number>(0);
  const [methodArgs, setMethodArgs] = useState<Record<string, string>>({});
  const { signer } = useWeb3();

  const handleFetch = async (method: string, params: unknown[]) => {
    const result = await fetch(LOCAL_NODE_ADDRESS, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        jsonrpc: "2.0",
        id: 1,
        method: method,
        params: params,
      }),
    }).then((res) => res.json());

    return result;
  };

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
    const typedArgs: (string | number | bigint | boolean)[] = [];

    args.forEach((arg, i) => {
      try {
        arg = arg.trim();
      } catch (e) {
        /* empty */
      }

      function convertToArgType(arg: string, type: string) {
        let argTyped = arg as bigint | number | boolean | string;
        switch (type) {
          case "bigint":
            return (argTyped = BigInt(arg));
          case "number":
            return (argTyped = Number(arg));
          case "boolean":
            return (argTyped = Boolean(arg));
          case "string":
            return (argTyped = String(arg));
          default:
            return argTyped;
        }
      }

      const convertedArg = convertToArgType(arg, methodArgTypes[i]);
      typedArgs.push(convertedArg);
    });

    let result;

    try {
      if (method.methodName == "eth_sendTransaction") {
        const nonce = await signer?.getTransactionCount();
        let nonceToHex = nonce?.toString(16);
        nonceToHex = "0x" + nonceToHex;

        const tx = {
          to: args[1],
          from: args[0],
          nonce: nonceToHex,
        };

        const transaction = await handleFetch(method.methodName, [tx]);
        console.log("transaction: ", transaction);
        return;
      } else {
        result = await handleFetch(method.methodName, typedArgs);
      }
    } catch (error) {
      /* empty */
    }

    for (let i = 0; i < args.length; i++) {
      const ele = document.getElementById(`${method.methodName}-input-${i}}`);
      if (ele) ele.textContent = "";
    }

    setMethodArgs({});

    console.log(result);

    if (method.download) {
      if (!result) return console.log("No result");

      const blob = new Blob([JSON.stringify(result)], { type: "application/json" });
      const url = URL.createObjectURL(blob);
      const downloadButton = document.getElementById(`${method.methodName}-output`);
      if (!downloadButton) return console.log("No download button");
      downloadButton.setAttribute("href", url);
      downloadButton.setAttribute("download", `${method.methodName}-output`);
      const img = downloadButton.querySelector("img");
      if (!img) return console.log("No img");
      const replace = document.createElement("img");
      replace.width = 50;
      replace.style.cursor = "pointer";
      replace.className = "downloadButton";
      img.replaceWith(replace);
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
                <tbody>
                  <tr>
                    <th>Method</th>
                    <th>Params</th>
                    <th>Call</th>
                  </tr>
                  {methodConfigs
                    .filter((method) => method.type === "chain")
                    .map((method) => {
                      const handleInputChange = (argName: string, value: string) => {
                        setMethodArgs((prevArgs) => ({ ...prevArgs, [argName]: value }));
                      };

                      return (
                        <tr key={method.methodName}>
                          <td>
                            {method.name}
                            {"  "}
                            {method.download ? <img className="downloadButton" width={50} hidden={true} style={{ cursor: "pointer" }} /> : null}{" "}
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
                </tbody>
              </>
            )}

            {isVisible == 2 && (
              <>
                <Button style={{ maxWidth: "250px", marginBottom: "6px" }} onClick={() => setIsVisible(0)}>
                  Back
                </Button>
                <tbody>
                  <tr>
                    <th>Method</th>
                    <th>Params</th>
                    <th>Call</th>
                  </tr>
                  {methodConfigs
                    .filter((method) => method.type === "user")
                    .map((method) => {
                      const handleInputChange = (argName: string, value: string) => {
                        setMethodArgs((prevArgs) => ({ ...prevArgs, [argName]: value }));
                      };

                      return (
                        <tr key={method.methodName}>
                          <td>
                            {method.name}
                            {"  "}
                            {method.download ? <img className="downloadButton" width={50} hidden={true} style={{ cursor: "pointer" }} /> : null}{" "}
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
                </tbody>
              </>
            )}

            {isVisible == 3 && (
              <>
                <Button style={{ maxWidth: "250px", marginBottom: "6px" }} onClick={() => setIsVisible(0)}>
                  Back
                </Button>
                <tbody>
                  <tr>
                    <th>Method</th>
                    <th>Params</th>
                    <th>Call</th>
                  </tr>
                  {methodConfigs
                    .filter((method) => method.type === "utility")
                    .map((method) => {
                      const handleInputChange = (argName: string, value: string) => {
                        setMethodArgs((prevArgs) => ({ ...prevArgs, [argName]: value }));
                      };

                      return (
                        <tr key={method.methodName}>
                          <td>
                            {method.name}
                            {"  "}
                            {method.download ? (
                              <a id={`${method.methodName}-output`} download={`${method.methodName}-output`}>
                                <img className="downloadButton" width={50} hidden={true} style={{ cursor: "pointer" }} />
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
                </tbody>
              </>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}

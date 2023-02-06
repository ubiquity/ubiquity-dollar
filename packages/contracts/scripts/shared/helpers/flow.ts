export const pressAnyKey = async (msg = "Press any key to continue"): Promise<void> => {
  return new Promise((resolve) => {
    console.log(msg || "Press any key to continue");
    process.stdin.setRawMode(true);
    process.stdin.resume();
    process.stdin.on("data", (e) => {
      const byteArray = [...e];
      if (byteArray.length > 0 && byteArray[0] === 3) {
        process.stdin.destroy();
      }

      process.stdin.setRawMode(true);
      resolve(undefined);
    });
  });
};

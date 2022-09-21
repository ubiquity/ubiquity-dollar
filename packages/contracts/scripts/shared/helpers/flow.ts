export const pressAnyKey = async (msg = "Press any key to continue"): Promise<void> => {
    return new Promise((resolve) => {
        console.log(msg || "Press any key to continue");
        process.stdin.setRawMode(true);
        process.stdin.resume();
        process.stdin.on("data", () => {
            resolve(undefined);
        });
    });
}
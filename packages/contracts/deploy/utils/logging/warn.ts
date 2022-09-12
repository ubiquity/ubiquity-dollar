import { colorizeText } from "./console-colors";

export const warn = (message: string) => {
    console.warn(colorizeText(`\t⚠ ${message}`, "fgYellow"));
}
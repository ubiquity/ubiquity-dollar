import { colorizeText } from '../../tasks/utils/console-colors';

export function warn(message: string) {
  console.warn(colorizeText(`\t⚠ ${message}`, "fgYellow"));
}

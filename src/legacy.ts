export function padTitle(title: string, width: number, fill = " "): string {
  return title.padStart(width, fill);
}

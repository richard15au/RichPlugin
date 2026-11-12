import { describe, expect, it } from "vitest";
import { formatTask } from "./format";

describe("formatTask", () => {
  it("marks a done task with [x]", () => {
    expect(formatTask({ id: 1, title: "Ship it", done: true })).toBe("[x] Ship it");
  });

  it("marks a pending task with [ ]", () => {
    expect(formatTask({ id: 2, title: "Write tests", done: false })).toBe("[ ] Write tests");
  });

  it("keeps an empty title as is", () => {
    expect(formatTask({ id: 3, title: "", done: false })).toBe("[ ] ");
  });
});

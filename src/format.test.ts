import { describe, expect, it } from "vitest";
import { formatTask } from "./format";

describe("formatTask", () => {
  it("marks a done task with [x] and its priority", () => {
    expect(
      formatTask({ id: 1, title: "Ship it", done: true, priority: "high" }),
    ).toBe("[x] (high) Ship it");
  });

  it("marks a pending task with [ ] and its priority", () => {
    expect(
      formatTask({ id: 2, title: "Write tests", done: false, priority: "low" }),
    ).toBe("[ ] (low) Write tests");
  });

  it("shows a medium priority", () => {
    expect(
      formatTask({ id: 3, title: "Review", done: false, priority: "medium" }),
    ).toBe("[ ] (medium) Review");
  });

  it("keeps an empty title as is", () => {
    expect(
      formatTask({ id: 4, title: "", done: false, priority: "low" }),
    ).toBe("[ ] (low) ");
  });

  it("appends the due date after the title", () => {
    expect(
      formatTask({ id: 5, title: "Pay rent", done: false, priority: "high", due: "2026-12-01" }),
    ).toBe("[ ] (high) Pay rent (due 2026-12-01)");
  });
});

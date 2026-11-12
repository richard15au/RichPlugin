import { describe, expect, it } from "vitest";
import { formatTask } from "./format";

describe("formatTask", () => {
  it("marks a done task with [x] and its priority", () => {
    expect(
      formatTask({ id: 1, title: "Ship it", done: true, priority: "high", tags: [] }),
    ).toBe("[x] (high) Ship it");
  });

  it("marks a pending task with [ ] and its priority", () => {
    expect(
      formatTask({ id: 2, title: "Write tests", done: false, priority: "low", tags: [] }),
    ).toBe("[ ] (low) Write tests");
  });

  it("shows a medium priority", () => {
    expect(
      formatTask({ id: 3, title: "Review", done: false, priority: "medium", tags: [] }),
    ).toBe("[ ] (medium) Review");
  });

  it("shows a tag after the title", () => {
    expect(
      formatTask({ id: 5, title: "Write tests", done: false, priority: "medium", tags: ["docs"] }),
    ).toBe("[ ] (medium) Write tests #docs");
  });

  it("shows several tags after the title in order", () => {
    expect(
      formatTask({
        id: 6,
        title: "Write tests",
        done: false,
        priority: "medium",
        tags: ["docs", "urgent"],
      }),
    ).toBe("[ ] (medium) Write tests #docs #urgent");
  });

  it("keeps an empty title as is", () => {
    expect(
      formatTask({ id: 4, title: "", done: false, priority: "low", tags: [] }),
    ).toBe("[ ] (low) ");
  });
});

import { describe, expect, it } from "vitest";
import { padTitle } from "./legacy";

describe("padTitle", () => {
  it("left-pads a title with spaces to the given width", () => {
    expect(padTitle("Buy milk", 12)).toBe("    Buy milk");
  });

  it("uses a custom fill character", () => {
    expect(padTitle("7", 3, "0")).toBe("007");
  });

  it("leaves titles already at or over the width unchanged", () => {
    expect(padTitle("Long title", 4)).toBe("Long title");
  });
});

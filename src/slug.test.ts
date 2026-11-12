import { describe, expect, it } from "vitest";
import { slugify } from "./slug";

describe("slugify", () => {
  it("lowercases text", () => {
    expect(slugify("Hello World")).toBe("hello-world");
  });

  it("trims surrounding whitespace", () => {
    expect(slugify("  Padded  ")).toBe("padded");
  });

  it("collapses runs of non-alphanumeric characters into one dash", () => {
    expect(slugify("foo -- bar__baz!!")).toBe("foo-bar-baz");
  });

  it("strips leading and trailing dashes", () => {
    expect(slugify("--Hello--")).toBe("hello");
  });

  it("returns an empty string for empty or whitespace-only input", () => {
    expect(slugify("")).toBe("");
    expect(slugify("   ")).toBe("");
  });
});

import { describe, expect, it } from "vitest";
import { TaskList } from "./tasks";

describe("TaskList", () => {
  it("adds a task with a trimmed title", () => {
    const list = new TaskList();
    expect(list.add("  Write tests ")).toEqual({ id: 1, title: "Write tests", done: false });
  });

  it("rejects an empty title", () => {
    expect(() => new TaskList().add("   ")).toThrow("cannot be empty");
  });

  it("completes a task by id", () => {
    const list = new TaskList();
    const task = list.add("Ship it");
    expect(list.complete(task.id).done).toBe(true);
  });

  it("throws when completing a missing task", () => {
    expect(() => new TaskList().complete(99)).toThrow("not found");
  });

  it("returns a copy of the list", () => {
    const list = new TaskList();
    list.add("One");
    list.list().pop();
    expect(list.list()).toHaveLength(1);
  });
});

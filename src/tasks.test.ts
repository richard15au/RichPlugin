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

  it("removes a task by id", () => {
    const list = new TaskList();
    const task = list.add("Remove me");
    list.remove(task.id);
    expect(list.list()).toHaveLength(0);
  });

  it("keeps other tasks when removing one", () => {
    const list = new TaskList();
    const first = list.add("One");
    list.add("Two");
    list.remove(first.id);
    expect(list.list().map((t) => t.title)).toEqual(["Two"]);
  });

  it("throws when removing a missing task", () => {
    expect(() => new TaskList().remove(99)).toThrow("Task 99 not found");
  });

  it("returns a copy of the list", () => {
    const list = new TaskList();
    list.add("One");
    list.list().pop();
    expect(list.list()).toHaveLength(1);
  });
});

import { describe, expect, it } from "vitest";
import { TaskList } from "./tasks";

describe("TaskList", () => {
  it("adds a task with a trimmed title", () => {
    const list = new TaskList();
    expect(list.add("  Write tests ")).toEqual({
      id: 1,
      title: "Write tests",
      done: false,
      priority: "medium",
    });
  });

  it("accepts an explicit priority", () => {
    expect(new TaskList().add("Ship it", "high").priority).toBe("high");
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

  it("changes a task's priority and returns the updated task", () => {
    const list = new TaskList();
    const task = list.add("Ship it", "low");
    expect(list.setPriority(task.id, "high")).toEqual({
      id: task.id,
      title: "Ship it",
      done: false,
      priority: "high",
    });
    expect(list.list()[0]?.priority).toBe("high");
  });

  it("throws when setting the priority of a missing task", () => {
    expect(() => new TaskList().setPriority(99, "high")).toThrow("Task 99 not found");
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

  it("orders tasks by priority: high, medium, low", () => {
    const list = new TaskList();
    list.add("Low", "low");
    list.add("High", "high");
    list.add("Medium", "medium");
    expect(list.byPriority().map((t) => t.title)).toEqual(["High", "Medium", "Low"]);
  });

  it("keeps the original order of tasks with the same priority", () => {
    const list = new TaskList();
    list.add("High one", "high");
    list.add("Medium one", "medium");
    list.add("High two", "high");
    list.add("Medium two", "medium");
    list.add("Low", "low");
    expect(list.byPriority().map((t) => t.title)).toEqual([
      "High one",
      "High two",
      "Medium one",
      "Medium two",
      "Low",
    ]);
  });

  it("does not change the order returned by list", () => {
    const list = new TaskList();
    list.add("Low", "low");
    list.add("High", "high");
    list.byPriority();
    expect(list.list().map((t) => t.title)).toEqual(["Low", "High"]);
  });

  it("returns a copy from byPriority", () => {
    const list = new TaskList();
    list.add("One", "high");
    list.add("Two", "low");
    list.byPriority().pop();
    expect(list.list()).toHaveLength(2);
  });

  it("sets and clears a due date", () => {
    const list = new TaskList();
    const task = list.add("Pay rent");
    expect(list.setDue(task.id, "2026-12-01").due).toBe("2026-12-01");
    expect(list.setDue(task.id, undefined).due).toBeUndefined();
  });

  it("rejects a badly formatted or impossible due date", () => {
    const list = new TaskList();
    const task = list.add("Pay rent");
    expect(() => list.setDue(task.id, "12/01/2026")).toThrow("Invalid due date");
    expect(() => list.setDue(task.id, "2026-02-30")).toThrow("Invalid due date");
    expect(() => list.setDue(task.id, "2026-13-01")).toThrow("Invalid due date");
  });

  it("throws when setting a due date on a missing task", () => {
    expect(() => new TaskList().setDue(99, "2026-12-01")).toThrow("Task 99 not found");
  });

  it("lists overdue open tasks in original order", () => {
    const list = new TaskList();
    const a = list.add("a");
    const b = list.add("b");
    const done = list.add("done");
    const today = list.add("today");
    list.add("undated");
    list.setDue(a.id, "2026-01-02");
    list.setDue(b.id, "2026-01-01");
    list.setDue(done.id, "2026-01-01");
    list.complete(done.id);
    list.setDue(today.id, "2026-06-01");
    const result = list.overdue("2026-06-01");
    expect(result.map((t) => t.title)).toEqual(["a", "b"]);
    expect(list.list()).toHaveLength(5);
  });
});

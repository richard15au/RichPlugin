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
      tags: [],
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
      tags: [],
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

  it("adds a trimmed tag and returns the task", () => {
    const list = new TaskList();
    const task = list.add("Ship it");
    expect(list.addTag(task.id, "  docs ")).toBe(task);
    expect(task.tags).toEqual(["docs"]);
  });

  it("ignores a duplicate tag", () => {
    const list = new TaskList();
    const task = list.add("Ship it");
    list.addTag(task.id, "docs");
    list.addTag(task.id, " docs");
    expect(task.tags).toEqual(["docs"]);
  });

  it("rejects an empty tag", () => {
    const list = new TaskList();
    const task = list.add("Ship it");
    expect(() => list.addTag(task.id, "   ")).toThrow("Tag cannot be empty");
  });

  it("throws when adding a tag to a missing task", () => {
    expect(() => new TaskList().addTag(99, "docs")).toThrow("Task 99 not found");
  });

  it("removes a tag and returns the task", () => {
    const list = new TaskList();
    const task = list.add("Ship it");
    list.addTag(task.id, "docs");
    list.addTag(task.id, "urgent");
    expect(list.removeTag(task.id, "docs")).toBe(task);
    expect(task.tags).toEqual(["urgent"]);
  });

  it("does nothing when removing an absent tag", () => {
    const list = new TaskList();
    const task = list.add("Ship it");
    list.addTag(task.id, "docs");
    expect(list.removeTag(task.id, "urgent")).toBe(task);
    expect(task.tags).toEqual(["docs"]);
  });

  it("throws when removing a tag from a missing task", () => {
    expect(() => new TaskList().removeTag(99, "docs")).toThrow("Task 99 not found");
  });

  it("returns only the tasks with the tag, in original order", () => {
    const list = new TaskList();
    const first = list.add("One");
    list.add("Two");
    const third = list.add("Three");
    list.addTag(first.id, "docs");
    list.addTag(third.id, "docs");
    list.addTag(third.id, "urgent");
    expect(list.byTag("docs")).toEqual([first, third]);
    expect(list.byTag("urgent")).toEqual([third]);
  });

  it("returns an empty array when no task has the tag", () => {
    const list = new TaskList();
    list.add("One");
    expect(list.byTag("docs")).toEqual([]);
  });

  it("returns a copy from byTag and leaves list unchanged", () => {
    const list = new TaskList();
    const task = list.add("One");
    list.addTag(task.id, "docs");
    list.byTag("docs").pop();
    expect(list.list()).toHaveLength(1);
    expect(list.byTag("docs")).toHaveLength(1);
  });
});

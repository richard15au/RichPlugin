import type { Task } from "./tasks";

export function formatTask(task: Task): string {
  const base = `${task.done ? "[x]" : "[ ]"} (${task.priority}) ${task.title}`;
  return task.due ? `${base} (due ${task.due})` : base;
}

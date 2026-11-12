import type { Task } from "./tasks";

export function formatTask(task: Task): string {
  return `${task.done ? "[x]" : "[ ]"} (${task.priority}) ${task.title}`;
}

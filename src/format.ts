import type { Task } from "./tasks";

export function formatTask(task: Task): string {
  const tags = task.tags.map((tag) => ` #${tag}`).join("");
  return `${task.done ? "[x]" : "[ ]"} (${task.priority}) ${task.title}${tags}`;
}

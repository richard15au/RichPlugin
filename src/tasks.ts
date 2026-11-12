export type Priority = "low" | "medium" | "high";

export type Task = {
  id: number;
  title: string;
  done: boolean;
  priority: Priority;
  tags: string[];
};

const priorityRank: Record<Priority, number> = { high: 0, medium: 1, low: 2 };

export class TaskList {
  private tasks: Task[] = [];
  private nextId = 1;

  add(title: string, priority: Priority = "medium"): Task {
    const trimmed = title.trim();
    if (!trimmed) throw new Error("Task title cannot be empty");
    const task: Task = {
      id: this.nextId++,
      title: trimmed,
      done: false,
      priority,
      tags: [],
    };
    this.tasks.push(task);
    return task;
  }

  complete(id: number): Task {
    const task = this.tasks.find((t) => t.id === id);
    if (!task) throw new Error(`Task ${id} not found`);
    task.done = true;
    return task;
  }

  setPriority(id: number, priority: Priority): Task {
    const task = this.tasks.find((t) => t.id === id);
    if (!task) throw new Error(`Task ${id} not found`);
    task.priority = priority;
    return task;
  }

  remove(id: number): void {
    const index = this.tasks.findIndex((t) => t.id === id);
    if (index === -1) throw new Error(`Task ${id} not found`);
    this.tasks.splice(index, 1);
  }

  addTag(id: number, tag: string): Task {
    const task = this.tasks.find((t) => t.id === id);
    if (!task) throw new Error(`Task ${id} not found`);
    const trimmed = tag.trim();
    if (!trimmed) throw new Error("Tag cannot be empty");
    if (!task.tags.includes(trimmed)) task.tags.push(trimmed);
    return task;
  }

  removeTag(id: number, tag: string): Task {
    const task = this.tasks.find((t) => t.id === id);
    if (!task) throw new Error(`Task ${id} not found`);
    const index = task.tags.indexOf(tag.trim());
    if (index !== -1) task.tags.splice(index, 1);
    return task;
  }

  byTag(tag: string): Task[] {
    return this.tasks.filter((t) => t.tags.includes(tag));
  }

  list(): Task[] {
    return [...this.tasks];
  }

  byPriority(): Task[] {
    return [...this.tasks].sort(
      (a, b) => priorityRank[a.priority] - priorityRank[b.priority],
    );
  }
}

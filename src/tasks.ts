export type Priority = "low" | "medium" | "high";

export type Task = {
  id: number;
  title: string;
  done: boolean;
  priority: Priority;
};

const priorityRank: Record<Priority, number> = { high: 0, medium: 1, low: 2 };

export class TaskList {
  private tasks: Task[] = [];
  private nextId = 1;

  add(title: string, priority: Priority = "medium"): Task {
    const trimmed = title.trim();
    if (!trimmed) throw new Error("Task title cannot be empty");
    const task: Task = { id: this.nextId++, title: trimmed, done: false, priority };
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

  list(): Task[] {
    return [...this.tasks];
  }

  byPriority(): Task[] {
    return [...this.tasks].sort(
      (a, b) => priorityRank[a.priority] - priorityRank[b.priority],
    );
  }
}

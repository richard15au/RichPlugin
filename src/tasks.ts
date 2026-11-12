export type Priority = "low" | "medium" | "high";

export type Task = {
  id: number;
  title: string;
  done: boolean;
  priority: Priority;
  due?: string;
};

function isValidDate(value: string): boolean {
  if (!/^\d{4}-\d{2}-\d{2}$/.test(value)) return false;
  const date = new Date(`${value}T00:00:00Z`);
  return !Number.isNaN(date.getTime()) && date.toISOString().startsWith(value);
}

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

  setDue(id: number, due: string | undefined): Task {
    const task = this.tasks.find((t) => t.id === id);
    if (!task) throw new Error(`Task ${id} not found`);
    if (due !== undefined && !isValidDate(due)) throw new Error("Invalid due date");
    if (due === undefined) delete task.due;
    else task.due = due;
    return task;
  }

  overdue(today: string): Task[] {
    return this.tasks.filter((t) => !t.done && t.due !== undefined && t.due < today);
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

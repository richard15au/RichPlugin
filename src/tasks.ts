export type Task = {
  id: number;
  title: string;
  done: boolean;
};

export class TaskList {
  private tasks: Task[] = [];
  private nextId = 1;

  add(title: string): Task {
    const trimmed = title.trim();
    if (!trimmed) throw new Error("Task title cannot be empty");
    const task: Task = { id: this.nextId++, title: trimmed, done: false };
    this.tasks.push(task);
    return task;
  }

  complete(id: number): Task {
    const task = this.tasks.find((t) => t.id === id);
    if (!task) throw new Error(`Task ${id} not found`);
    task.done = true;
    return task;
  }

  list(): Task[] {
    return [...this.tasks];
  }
}

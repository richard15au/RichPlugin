import { defineConfig } from "vitest/config";

export default defineConfig({
  test: {
    // Parallel worker copies live in .worktrees/; don't run their tests from the main tree.
    exclude: ["**/node_modules/**", ".worktrees/**"],
  },
});

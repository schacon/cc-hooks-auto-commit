# Claude Code Hooks AutoCommit Example

This repository is a simple example of using the new Claude Code hooks to automate the creation of a new branch per session and to mostly only include changes in each session in each of those branches.

It adds files as it sees `PostToolCall` hooks of file writes, then commits to a branch under `refs/heads/claude/<session-id>` when the `Stop` hook is called.

After a few sessions, while there are no commits on your checked out branch, there are new branches with partial work from your working directory in each that looks like this:

```
❯ git branch
* main
  claude/0e7dfca8-2090-4514-ab28-0f38190d7ba3
  claude/b31327c0-63ec-44d3-bd6f-6bd744807a79
```

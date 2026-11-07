# Workspace Rules — Spec-Driven Development (`SDD` / `/speckit`)

1. **Always Use Spec-Driven Development (`/speckit`):**
   - Never dump large blocks of code in chat for the user to manually copy-paste.
   - When the user invokes `/speckit <Jira-Story-URL-or-Key>` (e.g., `/speckit https://rjcloudev.atlassian.net/browse/AGK-1` or `/speckit AGK-1`), activate the `speckit` skill (`.agents/skills/speckit/SKILL.md`).
2. **Traceability to Jira Epics & User Stories:**
   - Every implementation step must reference its Jira User Story (`AGK-1`..`AGK-5`), its parent **Jira Epic** (`EPIC-NET`, `EPIC-SEC`, `EPIC-K8S`, `EPIC-ING`, `EPIC-GITOPS`), and `.specify/memory/constitution.md`.
   - Always generate `.specify/specs/<ISSUE_KEY>/spec.md`, `plan.md`, and `tasks.md`, write the code directly in the workspace, and run automated validation (`terraform fmt`, `terraform validate`) so the user can review the validation report in their IDE.

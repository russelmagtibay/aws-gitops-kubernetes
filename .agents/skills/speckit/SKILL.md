---
name: speckit
description: >-
  Executes the Spec-Driven Development (SDD) workflow (/speckit, /speckit.specify,
  /speckit.plan, /speckit.tasks, /speckit.implement) when the user provides an
  Atlassian Jira User Story link or issue key (e.g., AGK-1 through AGK-5) or invokes
  /speckit. Reads the Confluence Architecture Constitution (.specify/memory/constitution.md
  and SPEC.md), generates the story spec, plan, and task checklist under
  .specify/specs/<ISSUE_KEY>/, writes the code directly into the IDE workspace,
  and runs automated validation commands.
---

# Spec-Kit (`/speckit`) — Spec-Driven Development (SDD) Workflow

Use this skill whenever the user types `/speckit` (or `/speckit.specify`, `/speckit.plan`, `/speckit.tasks`, `/speckit.implement`) followed by a Jira User Story URL (e.g., `https://rjcloudev.atlassian.net/browse/AGK-1`) or issue key (e.g., `AGK-1`).

## Core Rules (Strict SDD Discipline)
1. **Never ask the user to copy-paste code from chat into files.** Always write and update files directly inside the IDE workspace (`C:\Users\russel\aws-gitops-kubernetes`).
2. **Do NOT call `atlassian-mcp-server` tools if `/v1/sse` is active** (as it throws a transport deprecation error). Instead, always read `.specify/memory/constitution.md` and `SPEC.md` in `C:\Users\russel\aws-gitops-kubernetes`, which contain the complete synchronized Jira Epics, User Stories (`AGK-1` through `AGK-6`), and Confluence Architecture Blueprint.
3. **Execute the 4 Spec-Kit Stages automatically in sequence** when the user invokes `/speckit <Jira-Story-Link-or-Key>`:

---

## Stage 1: `/speckit.specify` (Read Story & Generate `spec.md`)
1. Extract the Jira Issue Key (e.g., `AGK-1`, `AGK-2`, `AGK-3`, `AGK-4`, `AGK-5`) from the URL or prompt.
2. Read `.specify/memory/constitution.md` and `SPEC.md` in `C:\Users\russel\aws-gitops-kubernetes`.
3. Create `.specify/specs/<ISSUE_KEY>/spec.md` containing:
   - **Jira Issue Key & Link** (`https://rjcloudev.atlassian.net/browse/<ISSUE_KEY>`)
   - **Parent Epic Name & Goal**
   - **User Story Statement** (*As a... I want... So that...*)
   - **Acceptance Criteria & Security/FinOps Guardrails**

## Stage 2: `/speckit.plan` (Generate Technical Blueprint `plan.md`)
1. Create `.specify/specs/<ISSUE_KEY>/plan.md` detailing:
   - Exact files/modules to create or modify in `C:\Users\russel\aws-gitops-kubernetes`.
   - AWS resource topology, IAM least-privilege boundaries, Checkov compliance rules, and FinOps cost controls (\$130 credit guardrail).

## Stage 3: `/speckit.tasks` (Generate Validation Checklist `tasks.md`)
1. Create `.specify/specs/<ISSUE_KEY>/tasks.md` with an ordered checklist of implementation and verification tasks (`[ ] Task 1...`, `[ ] Task 2...`).

## Stage 4: `/speckit.implement` (Write Code in IDE & Run Validation)
1. Write or update the production Terraform / Kubernetes / CI-CD files directly in `C:\Users\russel\aws-gitops-kubernetes` according to `plan.md`.
2. Run automated non-destructive validation in the workspace (e.g., `terraform fmt -recursive`, `terraform validate`) so the code is verified automatically without spending AWS credits prematurely.
3. Mark completed tasks as `[x]` in `.specify/specs/<ISSUE_KEY>/tasks.md` and update the status of `<ISSUE_KEY>` in `SPEC.md`.
4. Present a concise **SDD Epic & User Story Validation Summary** in chat showing:
   - Parent Epic & User Story validated
   - Spec-Kit artifacts generated (`.specify/specs/<ISSUE_KEY>/{spec,plan,tasks}.md`)
   - Code files written in the IDE
   - Automated validation result (`terraform validate` / syntax check)
   - Checklist for the user to verify and move the Jira card to **Done**.

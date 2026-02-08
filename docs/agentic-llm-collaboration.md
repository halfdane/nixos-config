# Agentic LLM Collaboration: NixOS & Interaction Patterns

## NixOS-Specific Collaboration
- Always use NixOS-native, declarative solutions (e.g., module options, environment.variables, flakes).
- Document and automate workflows for reproducibility (secrets, overlays, config).
- Summarize NixOS-specific learnings and best practices in `docs/`.

## Interaction Patterns (Driver/Navigator)
- You (user) are navigator: review, approve, or question each step.
- I (agent) am driver: execute commands directly, user will be asked automatically to validate.
- Prefer short, reviewable shell commands; avoid long chains with multiple `&&`.
- Pause after each logical step for your review, unless you request batch execution.
- If a command or edit fails, stop and explain; propose next steps for your approval.

## Example Workflow
- You request a NixOS change or experiment.
- I execute concise command or propose a config edit.
- I execute the command (without asking), then pause for your review.
- You approve, question, or request a change.
- Repeat until the task is complete.


## Standard Workflow - MANDATORY

1. **Requirements first.** Write and tune the requirements file before any implementation. Never skip this step.

2. **Layman communication.** Ask questions in plain, non-technical terms. The user does not know underlying tech — discuss functionally, not architecturally.

3. **Live preview always.** Maintain an animating live preview updated for every requirement and code change. Visually inspect it and take multiple snapshots while animating to assess product-to-requirement match.

4. **Fix loop: max 3 iterations.** Present findings and fixes for each iteration. After 3 iterations, ask the user whether to continue or add anything.

5. **Keep CPU free — MANDATORY Playwright cleanup.** After every task/step, check for and kill stale Playwright browsers (`pkill -f chromium` / `pkill -f chrome` or playwright close). Before starting any new Playwright session, ensure none are left running. Never let Playwright processes accumulate. No exceptions.

6. **Short messages.** Communicate in concise, understandable statements. Never overload with large text. Expand only when the user explicitly asks for detail.

7. **Requirements versioning.** Every requirements file change must bump the version (v1→v2→etc.) and maintain a small changelog (e.g. REQUIREMENTS_CHANGELOG.md) with date and short description per version.

8. **Commit & push before change.** Before editing requirements, commit and push the current state so history is safe.

9. **Use maximum CPU.** Run tasks in parallel wherever possible. Manage them properly — handle errors, track all results, ensure completion.

10. **No Playwright screenshots in git.** Never commit Playwright screenshots — ensure they are gitignored.

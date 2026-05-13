---
course: "34722"
course-name: "Linear Control Design 1"
type: handoff
tags: [LCD, regbot, handoff, audit, notebooklm, crosscheck]
date: 2026-05-13
---
# REGBOT Balance Assignment — Audit Cross-Check Handoff

> [!abstract] Goal
> The user has had one or more AI auditors review the report PDF for
> course 34722 "Linear Control Design 1". Each audit follows the
> structured format defined in `docs/PROMPT-audit-pdf.md`. Your job is
> to cross-check the non-trivial audit findings against the user's
> NotebookLM lecture material for course 34722, then produce a triaged
> response telling the user which findings to act on, which to dismiss,
> and which are outside the lecture scope.

> [!warning] Hard rules
> 1. **Read-only pass.** Do not edit the report, the design scripts,
>    `regbot_mg.m`, or any other source file. Acting on findings happens
>    in a separate session; this one is triage only.
> 2. **No AI attribution in commits.** If you do commit anything (you
>    probably won't — this session writes a chat response, not files),
>    no `Co-Authored-By` lines, no "Generated with Claude".
> 3. **Don't touch the Report submodule's `.git` symlink quirk.** The
>    `Report/.git` file has a stale relative path (7 ups instead of 4)
>    that was deliberately not fixed. Read Report source files directly;
>    do not run git commands inside `Report/` without env-var overrides
>    (`GIT_DIR` + `GIT_WORK_TREE`), and you probably won't need to.
> 4. **Use the `notebooklm` skill** to consult the lecture material —
>    don't invent course-material citations. The skill is documented as
>    triggering on "check my notes / verify against the lecture / look
>    this up in my course material" plus mention of DTU course code
>    34722.
> 5. **Don't pad findings.** If an audit point is trivial (typo,
>    formatting), pass it through to the user unchanged. Cross-check
>    only where the lecture material can actually adjudicate.
> 6. **`git add -A` is forbidden** project-wide (CRLF + stray-file
>    risk). Stage selectively if you ever stage anything.

---

## Inputs

The user will paste one or more audit reports. Each follows the
structure defined in `docs/PROMPT-audit-pdf.md`:

```
### CRITICAL (would lose marks)
### MAJOR (substantive but graders might miss)
### MINOR (typos, formatting, nice-to-fix)
### CONSISTENCY MATRIX
### VERIFIED-CORRECT
### OUTSIDE SCOPE     (optional — when auditor couldn't evaluate)
```

You do **not** need the PDF itself — the audit text is self-contained.
If something in the audit is too vague to act on, ask the user a
focused clarifying question rather than guessing.

## Source-of-truth files

When you need to verify what the report actually says (vs. what the
audit quotes):

- `Report/main.tex` — top-level LaTeX
- `Report/sections/*.tex` — body sections (introduction, control-architecture,
  wheel-speed-controller, balance-controller, velocity-controller,
  position-controller, conclusion, appendix)
- `Report/images/*.png` — figures actually used in the rendered PDF
- `Report/main.pdf` — the audited binary (you can't read it; trust the
  audit's quotes)

When you need to verify numerical claims:

- `simulink/regbot_mg.m` — committed gain values. Single source of truth
  for `Kpwv`, `tiwv`, `Kffwv`, `Kptilt`, `titilt`, `tdtilt`, `tipost`,
  `Kpvel`, `tivel`, `Kppos`, `tdpos`.
- `simulink/design_task1_wheel.m` through `design_task4_position.m` —
  produce the gains above. Comments cite achieved `wc` / PM / GM.

When you need to verify the *theory*:

- `docs/MATLAB Walkthrough.md` — the long-form pedagogical companion.
  Most audit claims about derivation have a direct answer here. §2 is
  Task 1, §3 is Task 2 (Method 2), §4 is Task 3, §5 is Task 4.
- The user's NotebookLM (course 34722) — invoke via `notebooklm` skill.
  Use this when the audit raises a point about the *correct course
  convention* (sign of K_PS, Nyquist criterion application, PI-zero
  placement rule, z/5 RHP-zero rule, cascade-separation rule, Lead
  implementation options, etc.).

## Workflow

1. Read this handoff in full.
2. Read `docs/PROMPT-audit-pdf.md` so you know what audit format to
   expect.
3. Skim `docs/MATLAB Walkthrough.md` §1–§5 (high level — full read not
   needed). This grounds you in what each task is doing.
4. Optionally skim `Report/sections/*.tex` so you have rough familiarity
   with the report's structure.
5. Tell the user you're ready. Wait for them to paste audit text.
6. Triage each audit finding using the decision tree below.
7. Produce one structured response per audit (or a combined response if
   audits are short / overlapping).

## Triage decision tree

For each audit finding, ask:

1. **Is it a typo / formatting / minor stylistic issue?**
   → Pass through under `NOT-IN-COURSE-MATERIAL`. No cross-check.

2. **Is it a numerical claim (gain value, margin, frequency, settling
   time, etc.)?**
   → Verify against `simulink/regbot_mg.m` and the printed output of
   the relevant design script. The script outputs (with the cleaned
   v3 gains) are stable and reproducible. If the audit's "correct
   value" disagrees with the script, the audit is wrong.

3. **Is it a control-theory claim (Nyquist criterion, Method 2 logic,
   PI-zero placement, RHP-zero rule, cascade separation, Lead drop,
   phase-balance equation, etc.)?**
   → Invoke `notebooklm` (course 34722). Cite the lecture / chunk
   number it returns. Verdict: `SUPPORTED-BY-COURSE`,
   `CONTRADICTED-BY-COURSE`, or `NOT-IN-COURSE-MATERIAL` if the
   notebook returns nothing relevant.

4. **Is it a figure / caption consistency claim?**
   → Check the LaTeX source under `Report/sections/`. If the audit
   quotes text accurately, then the issue is real and falls under
   `SUPPORTED-BY-COURSE` *if* the audit's correction matches lecture
   conventions, otherwise `NOT-IN-COURSE-MATERIAL`. (The lecture
   doesn't dictate figure layout; only the report's internal
   self-consistency matters here.)

5. **Is it a hardware / implementation claim (firmware [cbal] sign
   flip, Simulink Transfer Fcn restrictions, REGBOT physical
   parameters)?**
   → Mostly outside lecture scope. Use `docs/MATLAB Walkthrough.md`
   and `simulink/regbot_mg.m` as authoritative; pass through under
   `NOT-IN-COURSE-MATERIAL` if neither resolves it.

## Batch your notebooklm calls

One `notebooklm` invocation per *topic*, not per audit finding. If
three findings all concern "sign convention for K_PS in Method 2", a
single lookup serves all three. Group related findings before
invoking the skill.

If a notebook query returns nothing or is ambiguous, **say so** —
write "lecture material insufficient; defer to engineering
judgement" rather than fabricating a citation.

## Output format

For each audit produce one block in this shape:

```
## Cross-check — <audit identifier or "Audit 1">

### SUPPORTED-BY-COURSE
- <audit finding>. Lecture: <citation from notebooklm>.
  Recommendation: act on this.

### CONTRADICTED-BY-COURSE
- <audit finding>. Lecture: <citation>. The audit is wrong because
  <reason>. Recommendation: dismiss.

### NOT-IN-COURSE-MATERIAL
- <audit finding>. Out of scope for course material; user decides
  whether to act based on engineering judgement.

### CONSISTENCY-MATRIX VERIFIED
For each row of the audit's matrix: VERIFIED-MATCH / VERIFIED-MISMATCH
/ AUDIT-HALLUCINATED (if the cited value doesn't appear where the
audit claims it does — check Report/sections/*.tex).

### USER ACTION SUMMARY
Ranked list, highest priority first:
  1. Numerical inconsistencies (likely lost marks).
  2. Control-theory errors confirmed by lecture material.
  3. Figure/caption consistency confirmed by report source.
  4. Math typesetting issues.
  5. Stylistic only — skip unless trivially easy.
```

## Constraints on the response

- Quote the audit's text when you make a verdict. Don't paraphrase
  into ambiguity.
- Cite NotebookLM responses with whatever source identifier the skill
  returns (lecture number, slide number, chunk index, etc.). The user
  uses this to defend the verdict back to the original audit AI.
- If you commit anything: selective `git add`, no AI attribution in
  message. But you almost certainly won't commit in this session.
- Don't push. The previous session already pushed all three layers
  (Report → REGBOT-Balance → DTU).

## Pointers to read

- `docs/HANDOFF.md` — master project handoff (rules, scope, project
  state).
- `docs/HANDOFF-matlab-cleanup.md` — the MATLAB cleanup pass (now
  complete; all five commits + Nyquist figure fix shipped to all
  three remotes).
- `docs/MATLAB Walkthrough.md` — pedagogical companion. §1 background,
  §2 Task 1, §3 Task 2 (Method 2), §4 Task 3, §5 Task 4.
- `docs/PROMPT-audit-pdf.md` — the prompt that generated the audits
  you'll receive.
- `Report/main.tex`, `Report/sections/*.tex` — report source.
- `simulink/regbot_mg.m` — committed canonical gains.

---

## Open questions for the user (optional)

If unclear after reading, ask before guessing:

- *Is there a course rubric you want me to weight findings against?*
  (If yes, the USER ACTION SUMMARY can be re-ranked by rubric weight.)
- *How many audits will you give me, and do you want one cross-check
  per audit or a single merged cross-check?*
- *Are some audit findings already known to be false-positives that
  you want me to skip?*

---

*Written 2026-05-13, immediately after the Nyquist figure fix shipped
to all three remotes (`Report` 481c56e, `REGBOT-Balance-Assignment`
4da608a, `DTU` b96dea8). The MATLAB cleanup pass and the report's
final-figure update are both complete; this audit pass is the
quality gate before submission.*

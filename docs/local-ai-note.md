# Local AI note

## Planned feature: Draft Assist

Draft Assist will accept an input such as:

> Need a guitar capo for rehearsal near Somaiya today.

It will suggest three editable fields:

- Need or Offer
- A short title
- One approved category

The planned path is:

```text
Create screen
→ LocalAiService
→ Gemma implementation
→ deterministic fallback
→ strict output validation
→ editable form
→ explicit user confirmation
```

Draft Assist is **not implemented in Section 1**. No hosted AI will be used.
Model output will never publish directly; it must pass strict field and enum
validation, remain editable, and require explicit confirmation. Model files
will not be casually committed to Git and their licensing and distribution
requirements must be reviewed.

A deterministic fallback must support the expected demo flow when the model
is absent, still loading, incompatible, or unable to produce valid output.
The fallback is also not implemented yet.

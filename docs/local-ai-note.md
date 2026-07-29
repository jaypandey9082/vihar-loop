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

Draft Assist is **not implemented in Section 4**. No hosted AI will be used.
Its future suggestions will populate the editable fields on the existing
create screen and become a `ListingDraft`. The result must still pass
`ListingDraftValidator` in the form and repository before explicit user
confirmation.

AI will never generate the persisted ID, status, ownership/origin, creation
time, or private markers, and it will never write to storage directly. Those
protected values remain repository-owned. Model files will not be casually
committed to Git and their licensing and distribution requirements must be
reviewed.

A deterministic fallback must support the expected demo flow when the model
is absent, still loading, incompatible, or unable to produce valid output.
The fallback is also not implemented yet. A future `LocalAiService` remains an
independent boundary and does not depend on the Hive persistence choice.

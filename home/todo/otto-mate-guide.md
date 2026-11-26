This is the interface for agents that extract todos from Microsoft 365, for example the otto-mate skills.
The command `todo` works from any directory.
Use only the `todo otto-mate` commands below.

## Line format

One item is one line.

```
(A) 2026-11-18 Item text +project due:2026-11-20 url:https://example.com/page
```

- `(A)` is the optional priority.
- The date is the creation date.
`todo otto-mate add` sets it when it is missing.
- `+project` is an optional project tag.
- `due:YYYY-MM-DD` is an optional due date.
- `url:` is an optional link to useful information for the item.
No tool reads it.

## Steps for an extraction run

1. Run `todo otto-mate since`.
It prints a UTC timestamp, for example `2026-11-13T08:30:00Z`.
It is the time of the last successful extraction and never more than 7 days in the past.
2. Read the messages that are newer than this time with the otto-mate skill.
3. Propose the candidates to the user.
The user decides which candidates count.
Never add a candidate without the decision of the user.
4. Run `todo otto-mate add "LINE"` for each accepted candidate.
5. Run `todo otto-mate finish` only after a successful pass.
Do not run it after a failed pass.

## Rules

- The item text keeps the language of the source message.
- Put the link to the source message into `url:`.
- `todo otto-mate add` appends the line to the inbox.
It rejects empty lines and done lines.
It keeps a leading priority.
- `todo otto-mate finish` removes inbox lines that are older than 7 days.
It keeps lines without a creation date.
It records the time of this successful extraction for `todo otto-mate since`.
- Do not compare candidates with existing lines.
A run that overlaps an earlier run can add a duplicate.
The user drops duplicates during the review.

## For the user

Review the inbox with these commands.

- `todo otto-mate inbox` prints the candidates that wait for review.
Each line starts with its number `N`.
- `todo otto-mate accept N` moves candidate `N` to the open items.
- `todo otto-mate reject N` deletes candidate `N`.

The numbers of the other candidates stay the same after `accept` or `reject`.
`todo otto-mate inbox` skips the blank line that remains in place of a moved or deleted candidate.

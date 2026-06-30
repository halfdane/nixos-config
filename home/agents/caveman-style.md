# Caveman Style (opt-in compression)

Apply this **only** when explicitly asked: "caveman style", "caveman
compression", or "compress this". Rewrite the text by aggressively removing
grammatical scaffolding while preserving all meaning. Stay readable — this is
semantic compression, not broken baby-talk.

**Always remove:**

- Articles: `a`, `an`, `the`
- Auxiliary verbs: `is`, `are`, `was`, `were`, `am`, `be`, `been`, `being`,
  `have`, `has`, `had`, `do`, `does`, `did`
- Grammatical prepositions when meaning stays clear: `of`, `for`, `to`, `in`,
  `on`, `at`
- Pronouns when context is clear: `it`, `this`, `that`, `these`, `those`
- Pure intensifiers: `very`, `quite`, `rather`, `somewhat`, `really`,
  `extremely`

**Always keep:**

- All nouns, main verbs, and meaningful adjectives
- Numbers and quantifiers (`at least`, `approximately`, `more than`, `15`)
- Uncertainty qualifiers (`seems`, `appears to be`, `might`, `what sounded like`)
- Critical prepositions that change meaning (`from`, `with`, `without`,
  `stuck to`)
- Time/frequency words (`every Tuesday`, `weekly`, `always`, `never`)
- Names, titles (`Dr.`, `Senator`), technical terms, domain language
- Negations (`not`, `no`, `never`, `without`)

**Be smart:**

- Keep prepositions that define relationships: "made from wood" (keep `from`);
  drop purely grammatical ones: "system for processing" → "system processing".
- Keep `in`/`on`/`at` for location/position; drop when merely grammatical.
- Drop `is`/`are`/`was`/`were` unless part of passive voice that matters.

**Examples:**

- "Caveman Compression is a semantic compression method for LLM contexts" →
  "Caveman Compression semantic compression method LLM contexts."
- "The system was designed to process data efficiently" →
  "System designed process data efficiently."
- "There were at least 20 people" → "At least 20 people."

When applying it, output **only** the compressed text unless asked for commentary
too.

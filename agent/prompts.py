"""Prompt templates for the agent nodes.

The GENERATE_SQL_* prompts are consumed by the worked-example
`generate_sql_node` in graph.py via `.format(schema=..., question=...)`, so
keep those placeholders intact. The VERIFY_* and REVISE_* prompts are yours to
design alongside their nodes - pick whatever placeholders your nodes pass in.
"""

GENERATE_SQL_SYSTEM = """You are a SQLite expert. Given a database schema and a question, write a single SQLite SQL query that answers the question.

Rules:
- Output ONLY the SQL query inside a ```sql code block. No explanations, no prose.
- Use only tables and columns that exist in the schema provided.
- Use table aliases for clarity in joins.
- Prefer INNER JOIN over implicit joins.
- Use LIMIT when the question asks for top N or a single result."""

# Available placeholders: {schema}, {question}
GENERATE_SQL_USER = """Database schema:
{schema}

Question: {question}

Write the SQL query."""


VERIFY_SYSTEM = """You are a SQL result evaluator. Given a question, the SQL that was run, and its execution result, decide whether the result plausibly answers the question.

Mark ok=false if ANY of these are true:
- The result is an ERROR
- The result has 0 rows but the question implies rows should exist (e.g. "list", "what are", "how many" expecting a non-zero count)
- The columns returned clearly do not match what the question asks for

Output ONLY a JSON object, no prose, no fences:
{"ok": true} or {"ok": false, "issue": "brief description of the problem"}"""

# Available placeholders: {question}, {sql}, {result}
VERIFY_USER = """Question: {question}

SQL:
{sql}

Execution result:
{result}

Does this result plausibly answer the question? Reply with JSON only."""


REVISE_SYSTEM = """You are a SQLite expert. A SQL query failed or returned a wrong result. Fix it.

Rules:
- Output ONLY the corrected SQL query inside a ```sql code block. No explanations.
- Use only tables and columns that exist in the schema provided.
- Address the specific problem described."""

# Available placeholders: {schema}, {question}, {sql}, {result}, {issue}
REVISE_USER = """Database schema:
{schema}

Question: {question}

Previous SQL:
{sql}

Execution result:
{result}

Problem: {issue}

Write a corrected SQL query."""

import os
import re
import secrets

import psycopg2
from flask import Flask, render_template, request
from flask_wtf.csrf import CSRFProtect

# Length bounds for the search term.
MIN_LEN = 3
MAX_LEN = 50

# OWASP Proactive Control C3: validate input against an allowlist of what is
# expected, rather than trying to blocklist known attack strings. A search term
# only ever needs letters, digits and single spaces, so anything else (quotes,
# angle brackets, semicolons, parentheses) is rejected. That removes the
# character set both SQL injection and XSS depend on. A single quantifier, no
# nesting, so matching is linear and cannot be used for a ReDoS.
SEARCH_RE = re.compile(r"[A-Za-z0-9 ]+")

app = Flask(__name__)

# Signing key for the session that carries the CSRF token. Generated per start
# when none is supplied, so there is no secret committed to the repository.
app.secret_key = os.environ.get("SECRET_KEY") or secrets.token_hex(32)

# The search form is a state-changing POST, so it needs CSRF protection.
# CSRFProtect rejects any POST without a valid token from this session.
csrf = CSRFProtect(app)


def connect():
    return psycopg2.connect(
        host=os.environ.get("DB_HOST", "db"),
        dbname=os.environ.get("DB_NAME", "ssd"),
        user=os.environ.get("DB_USER", "ssd"),
        password=os.environ.get("DB_PASSWORD", ""),
    )


def init_db():
    """Create the log table. Named 2400639, so it must be quoted."""
    with connect() as conn, conn.cursor() as cur:
        cur.execute(
            'CREATE TABLE IF NOT EXISTS "2400639" ('
            "  id SERIAL PRIMARY KEY,"
            "  search_query TEXT NOT NULL,"
            "  query_time TIMESTAMPTZ NOT NULL DEFAULT now()"
            ")"
        )


def log_query(term):
    """Store a validated term. Parameterised, so the value is never parsed
    as SQL even if validation is ever loosened."""
    with connect() as conn, conn.cursor() as cur:
        cur.execute('INSERT INTO "2400639" (search_query) VALUES (%s)', (term,))


def validate(term):
    """Backend validation. Returns an error message, or None if the term is
    acceptable. Mirrors the checks done in the browser, because client-side
    validation is a usability feature and can always be bypassed."""
    if not term:
        return "Please enter a search term."
    if len(term) < MIN_LEN or len(term) > MAX_LEN:
        return f"Search term must be {MIN_LEN}-{MAX_LEN} characters."
    if not SEARCH_RE.fullmatch(term) or "  " in term:
        return "Invalid input detected. Letters, digits and single spaces only."
    return None


@app.route("/", methods=["GET", "POST"])
def home():
    if request.method == "GET":
        return render_template("index.html")

    term = request.form.get("q", "").strip()
    error = validate(term)
    if error:
        # Rejected: re-render the empty form so the input is cleared.
        return render_template("index.html", error=error), 400

    log_query(term)
    # Jinja2 autoescapes, so the term is rendered as text, never as markup.
    return render_template("result.html", term=term)


@app.route("/healthz", methods=["GET"])
def healthz():
    return "ok"


init_db()

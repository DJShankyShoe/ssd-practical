"""Integration tests: drive the running app over HTTP and check that the
backend validation and the result page behave as specified."""
import os

import requests

BASE = os.environ.get("BASE_URL", "http://127.0.0.1:8000")


def search(term):
    return requests.post(f"{BASE}/", data={"q": term}, timeout=10)


def test_home_page_serves_the_form():
    r = requests.get(f"{BASE}/", timeout=10)
    assert r.status_code == 200
    assert 'name="q"' in r.text


def test_valid_term_reaches_the_result_page():
    r = search("hello world")
    assert r.status_code == 200
    assert "You searched for" in r.text
    assert "hello world" in r.text


def test_sql_injection_is_rejected():
    r = search("' OR 1=1--")
    assert r.status_code == 400
    assert "Invalid input detected" in r.text
    assert "You searched for" not in r.text


def test_xss_is_rejected():
    r = search("<script>alert(1)</script>")
    assert r.status_code == 400
    assert "Invalid input detected" in r.text
    # the payload must never come back as live markup
    assert "<script>alert(1)</script>" not in r.text


def test_term_below_minimum_length_is_rejected():
    assert "3-50 characters" in search("ab").text


def test_term_above_maximum_length_is_rejected():
    assert "3-50 characters" in search("a" * 51).text


def test_empty_term_is_rejected():
    assert "Please enter a search term" in search("").text

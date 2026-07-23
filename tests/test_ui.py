"""UI tests: drive a real browser over HTTP to confirm the frontend
validation and page navigation behave as specified."""
import os

import pytest
from playwright.sync_api import expect

BASE = os.environ.get("BASE_URL", "http://127.0.0.1:8000")


@pytest.fixture(autouse=True)
def home(page):
    page.goto(BASE)


def test_home_page_shows_the_search_form(page):
    expect(page.locator("#q")).to_be_visible()
    expect(page.locator("button[type=submit]")).to_be_visible()


def test_valid_search_shows_result_and_can_return_home(page):
    page.fill("#q", "hello world")
    page.click("button[type=submit]")

    expect(page.locator("body")).to_contain_text("You searched for")
    expect(page.locator("body")).to_contain_text("hello world")

    page.click("text=Back to home")
    expect(page.locator("#q")).to_be_visible()


@pytest.mark.parametrize("payload", ["' OR 1=1--", "<script>alert(1)</script>"])
def test_attack_clears_the_field_and_stays_on_home(page, payload):
    page.fill("#q", payload)
    page.click("button[type=submit]")

    # still on the home page, with the input cleared
    expect(page.locator("#q")).to_be_visible()
    expect(page.locator("#q")).to_have_value("")
    expect(page.locator("body")).not_to_contain_text("You searched for")


def test_short_term_is_blocked_in_the_browser(page):
    page.fill("#q", "ab")
    page.click("button[type=submit]")
    expect(page.locator("#q")).to_be_visible()
    expect(page.locator("body")).not_to_contain_text("You searched for")

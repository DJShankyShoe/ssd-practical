// Frontend validation for the search form. Mirrors validate() in app.py;
// the server remains authoritative, since anything here can be bypassed.
(function () {
  "use strict";

  var MIN_LEN = 3;
  var MAX_LEN = 50;

  // Allowlist: letters, digits and spaces only. Quotes, angle brackets,
  // semicolons and parentheses are simply not allowed, which is what SQL
  // injection and XSS payloads depend on. Deliberately kept to a single
  // quantifier - no nesting - so it runs in linear time and cannot be used
  // for a ReDoS. Runs of spaces are rejected separately below.
  var ALLOWED = /^[A-Za-z0-9 ]+$/;

  // Returns an error message, or null when the term is acceptable.
  function validateTerm(term) {
    if (!term) {
      return "Please enter a search term.";
    }
    if (term.length < MIN_LEN || term.length > MAX_LEN) {
      return "Search term must be " + MIN_LEN + "-" + MAX_LEN + " characters.";
    }
    if (!ALLOWED.test(term) || term.indexOf("  ") !== -1) {
      return "Invalid input detected. Letters, digits and single spaces only.";
    }
    return null;
  }

  document.getElementById("search-form").addEventListener("submit", function (e) {
    var field = document.getElementById("q");
    var error = validateTerm(field.value.trim());
    if (!error) {
      return; // valid, let it submit
    }

    e.preventDefault();
    document.getElementById("js-error").textContent = error;
    field.value = ""; // clear the input, stay on the home page
    field.focus();
  });
})();

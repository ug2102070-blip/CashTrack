const test = require("node:test");
const assert = require("node:assert/strict");

const {_test} = require("../src/index.js");

const {deleteAccountPreconditionError: check} = _test;
const NOW = 1_800_000_000;

function auth({uid = "u1", provider = "password", authTime = NOW} = {}) {
  return {uid, token: {auth_time: authTime, firebase: {sign_in_provider: provider}}};
}

test("rejects unauthenticated callers", () => {
  assert.equal(check(null, NOW).code, "unauthenticated");
  assert.equal(check({token: {}}, NOW).code, "unauthenticated");
});

test("allows a recently signed-in registered user", () => {
  assert.equal(check(auth({authTime: NOW - 60}), NOW), null);
  assert.equal(check(auth({provider: "google.com", authTime: NOW - 299}), NOW), null);
});

test("requires recent login for registered users", () => {
  const err = check(auth({authTime: NOW - 301}), NOW);
  assert.equal(err.code, "failed-precondition");
  assert.equal(err.message, "requires-recent-login");
});

test("rejects a missing or malformed auth_time", () => {
  const noAuthTime = {uid: "u1", token: {firebase: {sign_in_provider: "password"}}};
  assert.equal(check(noAuthTime, NOW).code, "failed-precondition");
  assert.equal(check(auth({authTime: "abc"}), NOW).code, "failed-precondition");
});

test("guests may delete without re-authentication", () => {
  assert.equal(check(auth({provider: "anonymous", authTime: NOW - 86_400}), NOW), null);
});

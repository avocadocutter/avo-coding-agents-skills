# Solid Test Criteria

Reference checklist for evaluating test quality. Loaded on-demand during Phase 3.

---

## A test is solid if

- [ ] The test name describes the scenario, not the implementation (`'rejects expired tokens'` not `'token expiry test'`)
- [ ] It would catch a real bug — ask: "if I deleted the guard this test covers, would it fail?" If no, it's not testing anything
- [ ] It asserts on response body fields, not just status code
- [ ] It tests the failure case (the guard works) AND the success case (the happy path works)
- [ ] It runs in isolation — no shared state with other tests, no dependency on execution order
- [ ] No hardcoded waits (`setTimeout`, `sleep`) — if timing matters, mock the clock

---

## Weak assertions (flag these)

```ts
// Weak — passes even if the response body is wrong
expect(response.statusCode).toBe(200)

// Solid — fails if the shape changes
expect(response.statusCode).toBe(200)
expect(response.json()).toMatchObject({ id: expect.any(String), email: 'test@example.com' })
```

```ts
// Weak — doesn't prove the error is the right error
expect(response.statusCode).toBe(401)

// Solid — proves the error is specific
expect(response.statusCode).toBe(401)
expect(response.json()).toMatchObject({ code: 'INVALID_TOKEN' })
```

---

## Error path checklist per category

### Auth
- [ ] Missing token → 401
- [ ] Expired token → 401 (not 500)
- [ ] Token signed with wrong secret → 401
- [ ] Token for project A used on project B → 401
- [ ] Valid token, wrong role → 403

### Input validation (query parser)
- [ ] Unknown operator (`?col=foo.bar`) → 400 with message
- [ ] `in` with empty list (`?col=in.()`) → 400 or valid empty result, not SQL error
- [ ] Negative offset → 400
- [ ] Limit above cap (1001) → capped at 1000, not rejected
- [ ] Column name with SQL injection attempt → sanitized, not executed

### Data integrity
- [ ] DELETE with no filters → rejected before SQL runs
- [ ] PATCH with no filters → rejected before SQL runs
- [ ] INSERT with missing required column → DB error surfaced correctly, not 500

### Multi-tenant isolation
- [ ] User can only see their own project's data
- [ ] API key from project A cannot access project B
- [ ] RLS role is set correctly per request (not leaked between requests)

---

## Boundary values to always test

- Empty string `""`
- Null / undefined
- Zero `0`
- Negative numbers
- The exact limit (`limit=1000`) and one over (`limit=1001`)
- Empty array `[]`
- Array with one item
- Unicode in string fields

---

## Fastify-specific patterns for this project

```ts
// Test setup — use buildApp() helper, not raw Fastify
import { buildApp } from '../../test-helpers/build-app.js'

describe('auth routes', () => {
  let app: FastifyInstance

  beforeAll(async () => {
    app = await buildApp()
  })

  afterAll(async () => {
    await app.close()
  })

  it('rejects requests with no token', async () => {
    const response = await app.inject({
      method: 'GET',
      url: '/rest/v1/some_table',
      headers: { apikey: 'invalid-key' },
    })

    expect(response.statusCode).toBe(401)
    expect(response.json()).toMatchObject({
      code: expect.any(String),
      message: expect.any(String),
    })
  })
})
```

---

## Red flags in existing tests

- `expect(true).toBe(true)` — placeholder, tests nothing
- `try/catch` that swallows errors silently
- Test that only runs in a specific environment (hardcoded localhost ports)
- `beforeEach` that inserts rows without `afterEach` cleanup — causes order-dependent failures
- Asserting on `response.body` as a string instead of `response.json()`

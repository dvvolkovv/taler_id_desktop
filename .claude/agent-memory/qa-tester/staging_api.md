---
name: Staging API Testing Patterns
description: Known behaviors, working endpoints, and bugs on staging.id.taler.tirol backend
type: project
---

## Staging API (staging.id.taler.tirol)

### Route prefix
- No prefix needed. Endpoints are at root: `/auth/login`, `/profile`, etc.
- `/api/...` prefix does NOT work (returns 404).

### Known Issues (as of 2026-03-12)
- **POST /voice/rooms returns 500** regardless of payload (empty, `{type:"ai"}`, `{roomName:"..."}`)
  - Likely LiveKit server connection issue on staging or missing configuration
  - POST /voice/session works fine (returns OpenAI client secret), so it's specifically the room creation

### Working Endpoints
- POST /auth/register - 201
- POST /auth/login - 200
- POST /auth/refresh - 200 (refresh token rotation works)
- GET /profile - 200
- GET /messenger/conversations - 200 (returns array)
- GET /messenger/users/search?q=... - 200 (returns array)
- GET /kyc/status - 200
- GET /tenant - 200
- POST /voice/session - 201 (OpenAI ephemeral key)

### Security/Validation Observations
- Duplicate registration returns 409 with clear message
- Missing auth returns 401
- Invalid token returns 401
- Empty registration body returns 400 with field-level validation messages
- Weak password validation: min 8 chars, must contain letter + number
- Password validation does NOT require special characters (e.g. "Test1234" would pass without "!")

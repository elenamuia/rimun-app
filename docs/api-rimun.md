# RIMUN FastAPI Gateway (Client Contract)

Base URL: http://127.0.0.1:8081

## Endpoints
- GET /health → { status: "ok" }
- GET /forums → [ { id, acronym, name, description, image_path, created_at, updated_at } ]
- GET /committees?limit&offset → Committee[]
- GET /sessions?active&limit&offset → Session[]
- GET /posts?limit&offset → Post[]
- GET /delegates → Delegate[]
  - Query params:
    - session_id (number, internal session id)
    - delegation_id (number)
    - committee_id (number)
    - country_code (string, e.g. "IT")
    - school_id (number)
    - status_application (string: accepted|refused|hold)
    - status_housing (string: accepted|refused|hold|not-required)
    - is_ambassador (boolean)
    - updated_since (ISO datetime, e.g. 2025-01-01T00:00:00Z)
    - limit (1..1000), offset (>=0)
  - Returns fields:
    - person_id, name, surname, full_name, birthday, gender, picture_path, phone_number, allergies
    - country_code, country_name
    - session_id, session_edition
    - committee_id, committee_name
    - forum_acronym
    - delegation_id, delegation_name
    - school_id, school_name
    - role_confirmed, role_requested
    - group_confirmed, group_requested
    - status_application, status_housing, is_ambassador
    - housing_is_available, housing_n_guests
    - updated_at, created_at
- GET /delegates/{person_id} → one Delegate or {}

## Examples
- List: GET /delegates?limit=20
- Filtered: GET /delegates?session_id=10000&country_code=IT&committee_id=10000
- Updates since: GET /delegates?updated_since=2025-01-01T00:00:00Z
- By ID: GET /delegates/10000

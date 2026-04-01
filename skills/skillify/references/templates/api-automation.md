# API Automation Domain Guide

## Common Patterns
- Repeated HTTP calls to REST/GraphQL endpoints
- Authentication: API keys, Bearer tokens, OAuth2
- Data transformation: JSON parsing, CSV conversion, field mapping
- Pagination handling: offset-based, cursor-based, link-header
- Rate limiting: respect `Retry-After`, implement backoff
- Batch processing: iterate over a list of inputs, call API for each

## Common Tools and Commands

**curl:**
```bash
# GET with auth
curl -H "Authorization: Bearer $TOKEN" https://api.example.com/resource

# POST with JSON body
curl -X POST -H "Content-Type: application/json" \
  -d '{"key": "value"}' https://api.example.com/resource

# Save response
curl -s https://api.example.com/data | jq '.' > output.json
```

**jq (JSON processing):**
```bash
# Extract field
cat response.json | jq '.data[].name'

# Filter
cat response.json | jq '.items | map(select(.status == "active"))'

# Transform to CSV
cat response.json | jq -r '.data[] | [.id, .name, .email] | @csv'
```

## Common Step Patterns

- **Authentication step**: Obtain/verify token, store for subsequent calls
- **Fetch step**: Make API call, validate response status (200/201)
- **Pagination step**: Loop through pages until no more data
- **Transform step**: Parse response, extract needed fields, convert format
- **Output step**: Save results to file (JSON, CSV) or pass to next step
- **Error handling step**: Check for rate limits (429), auth failures (401), server errors (5xx)

## Recommended allowed-tools

```yaml
allowed-tools:
  - Bash(curl:*)
  - Bash(jq:*)
  - WebFetch
  - Read
  - Write
  - Bash(python:*)   # for complex transformations
```

## Common Pitfalls

- **Secrets in skills**: Never hardcode API keys or tokens in SKILL.md — use arguments or environment variables
- **Rate limits**: Always respect rate limits; add delays between batch calls
- **Pagination**: APIs may return empty pages or change cursor format — handle gracefully
- **Response format changes**: APIs evolve — validate response structure before processing
- **Large responses**: Some APIs return megabytes of data — use streaming or pagination
- **Idempotency**: POST/PUT calls may create duplicates if retried — check for existing resources first

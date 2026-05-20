# AI Provider Security

Future AI provider integrations must run from backend/server environments.

## Rules

- Store provider keys only in backend secret management.
- Never expose provider keys, service-role keys, or signed privileged URLs in mobile.
- Keep provider request logs free of unnecessary personal data.
- Document model/provider, expected cost, rate limits, fallback logic, and retention behavior before release.

Mobile may request analysis through SnapGrub backend APIs only after contracts exist.

# Mobile Architecture

The Flutter app uses feature-first modules with Riverpod controllers, repositories/services, generated API contracts, and Drift local persistence.

## How It Works

- UI screens read Riverpod controllers and render state.
- Controllers coordinate user intent and navigation state.
- Repositories own local-first persistence, remote calls, and outbox behavior.
- Services wrap Supabase, device identity, and platform dependencies.
- Drift stores profile, goals, body measurements, devices, feature flags, sync state, and outbox commands.

## Safe Change Rules

- Keep platform and Supabase calls out of widgets.
- Pass authenticated `userId` into local profile/goal reads.
- Save profile/goal locally before attempting remote settings sync.
- Use generated API DTOs from `snapgrub_api_contracts` for function payloads.
- Do not introduce camera/SnapStrip modules before Phase 2 readiness is green.

Current app source starts in `apps/mobile/lib/main.dart`.

# Conversational journal interaction spec

## Product model

SnapGrub opens on a user-local calendar day. Every day is a durable thread that
interleaves the user's notes, assistant responses, reviewable meal proposals,
and confirmed ledger meals. The existing meal ledger remains authoritative;
historical meals appear as synthetic events and require no backfill.

## Day thread

- Horizontal paging moves through past days and stops at today. The header has
  explicit previous/next, calendar, atlas, progress, and profile controls.
- Today initially settles near the latest event. Historical days prioritize the
  first meal. Vertical conversation scrolling always wins after a vertical drag.
- Empty days use a quiet personal invitation. They do not show dashboard cards.
- Local user messages render immediately with queued or failed delivery state.
  Assistant activity is described in human terms and streaming text settles in
  place without exposing provider terminology.

## Composer and capture

The persistent composer accepts multiline text. Its attachment tray routes to
camera/photo analysis, barcode capture, voice capture, and the manual editor.
Keyboard dismissal is interactive and the composer stays above safe areas.

Provider, authentication, and connectivity failures become concise in-thread
recovery copy. The original message remains visible and safe in the outbox.

## Proposal-only mutation

Assistant tools can read the selected day, goal, recent meals, and catalog
results. They can only stage create/update/delete proposals. A pending proposal
shows Confirm, Edit, and reject controls. Confirm writes through
`MealRepository.saveDraft`, then acknowledges the remote proposal. Offline
confirmation is valid because the local ledger and outbox are authoritative.

Confirmed meal cards expose details, correction, duplicate, and delete. The
detail sheet identifies generated images as “AI artwork.”

## Meal atlas

The atlas is available from the catalog control and by a two-finger pinch on the
thread. Meals are grouped by month and day in an editorial 4:5 mosaic. It uses
two columns on iPhone, three on iPad, and a readable single-column fallback at
large text sizes. Selecting a meal returns to its day and meal anchor through a
shared artwork transition.

## Offline and accessibility

- Meals can always be created, edited, or deleted locally.
- Messages remain visibly queued and replay as idempotent runs after reconnect.
- Reduce Motion replaces shader reveals and movement with immediate state
  changes. Increased Contrast uses opaque navigation surfaces.
- All icon-only controls have semantic labels and minimum practical hit areas.
- Dates are stored as user-local days with their IANA timezone.


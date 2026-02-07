---
title: "Example: Notification Preferences"
parent: Feature Pod
grand_parent: Topologies
nav_order: 1
---

# Feature Pod: User Notification Preferences

## Scenario
A B2B SaaS platform called TeamPulse needs a notification preferences feature. Users currently receive all notifications by email with no way to customize. The product spec calls for:
- A REST API to read and update notification preferences per user
- A React settings page where users toggle notification categories (mentions, assignments, due dates, weekly digest) across channels (email, in-app, Slack)
- Integration tests covering the full flow, plus edge cases like a user with no existing preferences (first-time setup) and bulk updates

The stack is Rails 7 API-only backend, React 18 + TypeScript frontend with Tailwind CSS, and RSpec for backend tests with Playwright for E2E. The team wants this shipped by end of sprint.

## Why This Topology
This is a textbook three-layer feature: backend API, frontend UI, and test coverage. Each layer can be built independently once the API contract is defined. A single agent could do this sequentially, but a Feature Pod cuts wall-clock time by parallelizing across layers. The contract-first approach prevents integration surprises.

## Setup

### Team Creation
```text
Create an agent team to implement user notification preferences.
Spawn:
- Frontend teammate: build the notification preferences settings page in React
  with TypeScript. Use the existing SettingsLayout component. Support toggling
  notifications per category (mentions, assignments, due_dates, weekly_digest)
  per channel (email, in_app, slack).
- Backend teammate: build the REST API endpoints for notification preferences.
  Create the database migration, model, controller, and serializer. Endpoints:
  GET /api/v1/notification_preferences, PUT /api/v1/notification_preferences.
- QA teammate: write RSpec request specs for the API endpoints and Playwright
  E2E tests for the settings page. Cover happy paths, edge cases (no existing
  preferences, invalid payloads, unauthorized access), and bulk updates.
First task: define the API contract (endpoints, request/response shapes,
error codes). Then parallelize implementation by layer.
```

### Task Breakdown
| Task | Owner | Blocked By | Deliverable |
|------|-------|------------|-------------|
| Define API contract | Lead + all | -- | Contract doc with endpoints, payloads, response schemas |
| Create migration + model | BE | Contract | `notification_preferences` table + model with validations |
| Build API endpoints | BE | Migration | Controller, serializer, routes |
| Build settings page UI | FE | Contract | React component with toggle grid |
| Wire UI to API | FE | API endpoints | RTK Query hooks + error handling |
| Write API request specs | QA | API endpoints | RSpec specs for GET/PUT endpoints |
| Write E2E tests | QA | UI + API | Playwright tests for settings flow |
| Integration verification | Lead | All above | Full flow test, review |

## What Happened

### [0:00] Contract definition
The lead created the contract as the first task. All three teammates reviewed it before implementation began:

```json
{
  "GET /api/v1/notification_preferences": {
    "response": {
      "preferences": [
        {
          "category": "mentions",
          "channels": {
            "email": true,
            "in_app": true,
            "slack": false
          }
        }
      ]
    }
  },
  "PUT /api/v1/notification_preferences": {
    "request": {
      "preferences": [
        {
          "category": "mentions",
          "channels": {
            "email": true,
            "in_app": false
          }
        }
      ]
    },
    "response": { "same as GET" },
    "errors": {
      "422": "invalid category or channel",
      "401": "unauthorized"
    }
  }
}
```

### [0:08] Backend starts building
The BE agent created the migration and model first:

> "Created `db/migrate/20260207_create_notification_preferences.rb` with a `notification_preferences` table: `user_id` (foreign key), `category` (string enum), `channel` (string enum), `enabled` (boolean), with a unique composite index on `[user_id, category, channel]`. Added model validations for category inclusion in `%w[mentions assignments due_dates weekly_digest]` and channel inclusion in `%w[email in_app slack]`."

The BE agent then built the controller with a clean `preferences_params` permit pattern and a bulk upsert strategy for the PUT endpoint using `upsert_all`.

### [0:10] Frontend starts building the UI
The FE agent began scaffolding the settings page, building against the contract:

> "Created `NotificationPreferences.tsx` inside `client/src/features/settings/`. Using a grid layout with categories as rows and channels as columns. Each cell is a toggle switch component. Loading state shows skeleton placeholders."

The FE agent used the existing `Toggle` component from the design system and wired up local state to track pending changes before submission.

### [0:18] The file conflict
The FE agent needed to add a route for the new settings page. It opened `client/src/utils/apiClient.ts` to add a new API helper function for the preferences endpoint. At the same time, the BE agent was modifying `client/src/utils/apiClient.ts` to add the OpenAPI type definitions that the auto-generator had produced.

The lead caught this through the task list when both agents reported working in the same file:

> **Lead to FE:** "Hold off on modifying `apiClient.ts` -- BE is currently updating the auto-generated types in that file. Once BE finishes the API endpoints and the type generation runs, you'll have typed API hooks available through RTK Query. Use a placeholder type for now and wire up the real types after BE completes."

> **FE agent:** "Understood. I'll define a local `NotificationPreference` type interface for now and swap it out once the generated types are available."

The lead then added an explicit dependency: the FE "wire to API" task was blocked on BE completing the API endpoints. This sequenced the shared-file access cleanly.

### [0:35] QA begins writing specs
With the API contract in hand, the QA agent had started writing RSpec request specs against the contract even before the API was fully built. Once the BE agent finished, QA ran them:

> "14 request specs written. 12 passing, 2 failing. The failing specs are for the 422 error case -- the controller returns a 400 status instead of 422 for invalid category values. Flagging to BE."

The BE agent fixed the status code in `NotificationPreferencesController#update` in under a minute.

### [0:50] Frontend wires up to the real API
With BE finished and types generated, the FE agent replaced the placeholder types and connected to the actual endpoints:

> "Swapped local types for generated `NotificationPreference` types from `api/generated/`. Added RTK Query hooks: `useGetNotificationPreferencesQuery` and `useUpdateNotificationPreferencesMutation`. Added optimistic update on toggle so the UI feels instant, with rollback on error."

### [1:05] QA writes E2E tests
The QA agent wrote 8 Playwright tests covering:
- First-time user sees all defaults (everything enabled)
- Toggle a single preference and verify it persists on reload
- Toggle all preferences for a category at once
- Unauthorized user gets redirected to login
- Network error shows a retry toast
- Bulk update of all preferences in one save

> "8 E2E tests written. 7 passing. One flaky: the 'persist on reload' test sometimes fails because the optimistic update returns before the server write completes. Added a `waitForResponse` assertion to stabilize it."

### [1:20] Integration verification
The lead ran the full test suite and reviewed the implementation:

> "All 14 RSpec specs passing. All 8 Playwright tests passing (including the stabilized reload test). The notification preferences page renders correctly, toggles update the backend, and error states are handled. Total test coverage for new code: 94%."

### [1:30] Final review and cleanup
The lead flagged one minor issue: the FE agent had left a `console.log` debugging statement in the mutation hook. The FE agent removed it. The lead also asked BE to add an index on `user_id` alone (in addition to the composite index) for the common query pattern of "get all preferences for a user."

## What Went Wrong
**The shared file conflict on `apiClient.ts`** was the main coordination failure. Both agents reached for the same utility file at roughly the same time. The lead caught it within a few minutes, but if both had committed changes, one would have overwritten the other. The fix was simple (sequence the access) but this is exactly the kind of problem the Feature Pod pattern warns about. The spawn prompt should have explicitly stated: "FE should not modify any files in `utils/` until BE completes API work."

**QA's early spec failures** were a minor issue. Writing specs against the contract before the implementation exists is a Feature Pod strength, but the 400-vs-422 status code mismatch shows that contracts need to be precise about HTTP status codes, not just payload shapes.

## Results
| Metric | Value |
|--------|-------|
| Duration | 1.5 hours |
| Token Cost | ~$8.00 |
| Key Deliverables | REST API (2 endpoints), React settings page, 14 RSpec specs, 8 E2E tests |
| Test Coverage | 94% on new code |

## Retrospective
- **What worked:** The contract-first approach was essential. Having the API shape defined before implementation meant FE and QA could start immediately without waiting for BE. The QA agent writing specs against the contract caught a real bug (wrong status code) early.
- **What didn't:** File ownership boundaries were not explicit enough. The shared `apiClient.ts` conflict was avoidable with clearer spawn instructions. Next time, the contract should include a "file ownership" section listing which agent owns which directories.
- **Would use again?** Yes, for any multi-layer feature. The parallelism saved roughly 40 minutes compared to sequential implementation, and the contract-first approach caught integration issues before they became expensive.
- **Tip:** When defining the contract, include HTTP status codes, not just payload shapes. And add a "file ownership" section to the spawn prompt that explicitly lists which directories each agent can modify. Shared utility files should be assigned to one owner.

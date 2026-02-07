# Example: Processing a Backlog of Deprecation Fixes

## Scenario

Your project upgraded from React Router v5 to v6, and the migration tool flagged 47 files that use deprecated APIs: `useHistory` (23 files), `<Switch>` component (15 files), and `<Redirect>` component (9 files). Each fix is mechanical and self-contained -- replace the deprecated API with its v6 equivalent -- but doing them one at a time in a single agent session would take forever. No file requires changes from multiple categories, and no fix depends on another.

## Why This Topology

This is the textbook Task Queue scenario: many small, independent, structurally similar work items with no dependencies between them. Each fix is self-contained (one file, one pattern), so workers can operate completely independently. The volume (47 items) means parallelism has a massive throughput advantage over sequential execution.

## Setup

```text
Create an agent team to process our React Router v6 migration backlog.

Here are the migration rules:
- useHistory() -> useNavigate() (history.push becomes navigate, history.replace
  becomes navigate with { replace: true })
- <Switch> -> <Routes>, and children <Route> elements need element prop instead
  of component/render props
- <Redirect> -> <Navigate replace>

Break the 47 flagged files into individual tasks. Each task: apply the migration
to one file, verify it compiles, and run that file's tests if they exist.
Let teammates self-claim the next unblocked task after finishing each one.
I want a brief status line per completed task and a final summary with any
files that needed manual attention.
```

**Team:** Lead + 5 Workers
**Estimated duration:** ~12 minutes

## What Happened

The lead created 47 individual tasks from the migration report, grouping them by category for easier tracking but not blocking any task on another. Each task description included the file path, the deprecated API found, and the expected replacement pattern.

**Five workers** started self-claiming tasks immediately. The `useHistory` fixes went fastest -- most were straightforward replacements. Workers completed these at a rate of roughly one per 15 seconds: read the file, apply the pattern, verify the import changed, and check for TypeScript errors.

The `<Switch>` to `<Routes>` conversions were slightly slower because they required restructuring the child `<Route>` elements. Workers needed to convert `component={Foo}` to `element={<Foo />}` and handle cases where routes used `render` props with inline functions.

**Worker 3** hit a complex case at task 28: `src/pages/admin/routes.tsx` had nested `<Switch>` components with `<Redirect>` inside conditional logic. The mechanical replacement did not work because the redirect condition needed to be expressed as a layout route in v6. The worker flagged it for manual attention and moved on to the next task.

**Worker 1** found that 3 `useHistory` files also used `useLocation` in a pattern that combined `history.listen` with location tracking. Since `useNavigate` does not support listeners, these files needed a different approach (using `useEffect` with `useLocation` instead). The worker applied the alternative pattern and noted it in the task completion message.

By minute 8, all `useHistory` and `<Switch>` tasks were complete. The remaining `<Redirect>` tasks finished by minute 10. The lead spent the final 2 minutes running the full test suite and compiling the summary.

## What Went Wrong

**Task granularity mismatch:** The lead created one task per file, which was correct for most files but wasteful for the simplest `useHistory` cases (single import, single usage). Workers spent more time reading the task description and claiming the task than doing the actual work. Batching the simplest cases (3-5 files per task) would have reduced overhead without sacrificing parallelism.

**One worker got stuck:** Worker 4 encountered a TypeScript compilation error after migrating `src/components/ProtectedRoute.tsx` because the file's type exports were consumed by 3 other files that expected the old prop shape. The fix cascaded: it needed to update the type definition and the consuming files. Since those consuming files were assigned as separate tasks to other workers, Worker 4 had to message the lead to coordinate. This took ~2 minutes to sort out -- the lead reassigned the related tasks to Worker 4 to handle as a group.

**Test flakiness:** Worker 2 reported that tests for `src/pages/dashboard/index.tsx` failed after migration, but the failure was a pre-existing flaky test (timeout on a mock API call), not related to the migration. It cost ~1 minute to diagnose before the worker moved on.

## Results

- **44 of 47 files** migrated automatically with passing tests
- **2 files** needed manual attention: the nested Switch/Redirect case and one file with a complex `history.listen` pattern that the alternative approach did not fully cover
- **1 file** had a pre-existing flaky test unrelated to the migration
- **Full test suite:** 312 passed, 2 skipped (the manual-attention files), 1 flaky (pre-existing)
- **Total time:** ~12 minutes for work that would have taken ~45 minutes sequentially

## Retrospective

**What worked:** The self-claim pattern kept all 5 workers busy continuously -- no worker waited for the lead to assign tasks. The mechanical, repetitive nature of the work was a perfect fit: workers did not need deep context, just pattern application. Having workers flag edge cases and move on (rather than getting stuck) kept throughput high.

**What to do differently:** Batch trivial tasks (3-5 files per task when the fix is a one-line import change) to reduce claim overhead. Before creating the task list, scan for files with cross-file type dependencies and group them into single tasks assigned to one worker -- this prevents the coordination issue Worker 4 hit. Add a pre-check in each task: "run the file's existing tests first to establish a baseline" so that pre-existing failures are not confused with migration regressions.

**When to reuse this pattern:** Any time you have 15+ independent, structurally similar work items: bulk API migrations, lint rule fixes, dependency updates across packages, documentation extraction from source files, or ticket triage. The key signal is: "each item is self-contained and does not depend on other items." Poor fits include work where items share state, modify the same files, or require deep sequential reasoning.

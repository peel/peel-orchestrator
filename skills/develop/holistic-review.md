# Holistic Review

Cross-domain evaluation that assesses the full system as an integrated whole. Runs after all domain evaluators have scored their individual dimensions. Produces a holistic scorecard, spec coverage matrix, and remediation beans for any gaps.

## HARD-GATE: Runtime Interaction Required

<HARD-GATE>
You MUST interact with ALL domain runtimes before scoring any holistic dimension.
Do NOT score from source code alone. Do NOT score from individual domain scorecards alone.
Every score must cite evidence gathered from live runtime interaction.
If any runtime is not running, score Runtime Health as 1 and note the failure.
</HARD-GATE>

The runtimes are started by `start-runtimes.sh` before holistic review begins. You receive runtime state for each domain including ports and domain names. Use the appropriate MCP tools (marionette for Flutter, curl for HTTP, go-dev-mcp for Go) to interact with each runtime.

### Evidence Gathering

- Launch each domain's runtime and verify it responds
- Exercise the primary user flows end-to-end across domains
- Take screenshots of frontend states reached via backend data
- Verify API calls from frontend reach backend and return correct data
- Check console output for errors, warnings, or unhandled exceptions
- Record which cross-domain flows were tested and their outcomes

## Cross-Domain Integration Check

Before scoring, verify that domains work together as a system:

- **API contract compliance:** Does the frontend send requests the backend expects? Does the backend respond with shapes the frontend can parse?
- **Data flow end-to-end:** Trace at least one full user action from UI interaction through API call to backend processing and back to UI update.
- **Error propagation:** When the backend returns an error, does the frontend display appropriate feedback?
- **State consistency:** Does the frontend state reflect backend state accurately after mutations?

Note any integration gaps in the scorecard evidence. Integration failures directly affect the Integration and Coherence dimension scores.

## Dimensions

### Integration

Do the pieces work together? Are there visible seams between domains?

**Default threshold: 7**

```
 1  Disconnected: Domains don't communicate at all. Frontend and backend
    are completely independent applications with no integration.
 2  Broken bridge: Integration attempted but fundamentally broken. API
    calls fail, data formats incompatible, endpoints missing.
 3  Partial wiring: Some connections work. Core data flow exists but
    secondary flows (error handling, edge cases) are not wired up.
 4  Fragile link: Happy path works end-to-end but any deviation breaks
    the integration. Hardcoded URLs, missing error handling across boundaries.
 5  Functional seams: Domains communicate and data flows, but the seams
    are visible. Inconsistent loading states, mismatched terminology,
    different interaction patterns across domain boundaries.
 6  Joined: Integration works reliably. Error states propagate across
    domains. Seams visible only to careful inspection (e.g., slight
    timing differences, inconsistent empty states).
 7  Smooth: Domains feel connected. Data flows correctly, errors handled
    at boundaries, terminology consistent. Minor rough edges at transitions.
 8  Seamless: No visible seams. Cross-domain flows feel like a single
    application. State synchronized, transitions smooth, errors coherent.
 9  Unified: Integration is invisible. Cross-domain operations feel
    atomic. Optimistic updates, graceful degradation when a domain is slow.
10  Organic: System feels like it was built as one piece. Cross-domain
    features work better together than they would separately.
```

### Coherence

Does the whole feel like one system or a patchwork of separate pieces?

**Default threshold: 7**

```
 1  Patchwork: Each domain looks and feels completely different. No shared
    design language, terminology, or interaction patterns.
 2  Conflicting: Domains actively contradict each other. Different names
    for the same concepts, conflicting navigation patterns, clashing styles.
 3  Disjointed: Some shared elements but applied inconsistently. Same
    data displayed differently across domains. User must learn separate
    mental models for each part.
 4  Loosely themed: A common theme exists but execution varies widely.
    Color palette shared but typography, spacing, and component styles diverge.
 5  Partially unified: Core concepts named consistently. Primary
    navigation coherent. Secondary interactions and edge cases diverge
    between domains.
 6  Mostly coherent: Shared design language applied across domains.
    Terminology consistent. Interaction patterns similar. A few areas
    feel like they were built by a different team.
 7  Coherent: System feels unified. Consistent naming, patterns, and
    visual language. User can predict behavior in one domain based on
    experience in another.
 8  Harmonious: Beyond consistency — domains complement each other.
    Information architecture flows logically. Transitions between
    domains feel intentional and guided.
 9  Holistic: System tells a single coherent story. Every part reinforces
    the whole. Navigation, terminology, and visual rhythm all aligned.
10  Inevitable: The system feels like it could only have been designed
    this way. Every piece in its right place. Removing any part would
    diminish the whole.
```

### Holistic Spec Fidelity

Does the full result match the design document's overall vision? This is distinct from per-task domain_spec_fidelity — it evaluates whether the assembled whole achieves what the spec intended.

**Default threshold: 8**

```
 1  Wrong product: What was built bears no resemblance to the design
    document's vision. Completely different application.
 2  Wrong direction: Recognizably related to the spec but the fundamental
    approach contradicts the design intent.
 3  Major gaps: Some spec elements present but the overall vision is
    unrealized. Key features or interactions missing entirely.
 4  Partial vision: ~50% of the spec's vision realized. The shape is
    visible but large pieces missing. A reviewer would say "it's a start."
 5  Incomplete: ~70% realized. Most features present but the overall
    experience doesn't yet match the spec's intended feel or flow.
 6  Functional match: All primary spec requirements met. The app does
    what the spec says but doesn't capture the spirit — feels mechanical.
 7  Good match: Spec requirements met with reasonable interpretation of
    ambiguous areas. The app matches the spec's letter and partially
    its spirit.
 8  Faithful: Implementation matches the design document in both letter
    and spirit. The intended user experience is achieved. Design intent
    preserved throughout.
 9  Complete vision: Every aspect of the spec fully realized. Ambiguities
    resolved in ways that enhance the design intent. No drift from vision.
10  Transcends spec: All spec requirements met and the implementation
    improves on the vision where the spec was underspecified. The result
    is better than what was described.
```

### Polish

Would you ship this? Or does it feel AI-generated and unfinished?

**Default threshold: 6**

```
 1  Prototype: Clearly a rough draft. Placeholder text, missing assets,
    broken layouts, debug output visible.
 2  Scaffold: Structure exists but no finishing. Default styles, Lorem
    ipsum, TODO comments visible in output, unstyled error messages.
 3  Draft: Some intentional styling but obviously incomplete. Mix of
    polished and rough areas. Console warnings visible.
 4  Rough: Works and has styling but feels unfinished. Inconsistent
    spacing, orphaned elements, generic error messages, no loading states.
 5  Adequate: Functional and styled but not refined. A developer would
    say "it works." A designer would say "needs a polish pass."
 6  Presentable: Could show to stakeholders. Minor rough edges but
    nothing embarrassing. Loading states present, errors handled,
    spacing consistent.
 7  Polished: Feels finished. Attention to detail visible — proper
    empty states, transitions, consistent iconography, no console errors.
 8  Refined: Details that most people wouldn't notice are right. Micro-
    interactions, hover states, focus management, accessible labels.
 9  Crafted: Every pixel intentional. Animations enhance understanding.
    Error states are helpful. Performance is snappy. Feels hand-made.
10  Delightful: Exceeds expectations. Surprise-and-delight moments.
    The kind of quality that makes people ask "how did they do this?"
```

### Runtime Health

App launches cleanly, no console errors, responsive under interaction.

**Default threshold: 9**

```
 1  Won't start: Application fails to launch. Build errors, missing
    dependencies, crash on startup.
 2  Crashes immediately: Launches but crashes within seconds. Fatal
    errors on first interaction.
 3  Unstable: Launches but crashes frequently during normal use.
    Multiple console errors on startup.
 4  Limping: Runs but with persistent issues. Significant console
    errors, slow startup, memory warnings.
 5  Shaky: Core functionality works but secondary features cause
    errors. Console warnings present. Occasional hangs.
 6  Functional: Runs without crashes. Some console warnings but no
    errors. Startup takes reasonable time. Responds to interactions.
 7  Stable: No crashes, no console errors. Startup clean. All
    interactions responsive. Minor performance hiccups under load.
 8  Healthy: Clean startup, no warnings, responsive interactions.
    Memory stable over time. No network errors.
 9  Solid: Fast startup, zero console output (no errors, no warnings).
    All interactions instant. Smooth scrolling, no jank. Handles rapid
    interaction without degradation.
10  Exemplary: Sub-second startup. Zero console noise. Handles stress
    testing (rapid clicks, large data, resize). Performance metrics
    all green. Could run in production.
```

## Spec Coverage Matrix Protocol

After scoring all dimensions, produce a spec coverage matrix. Extract every
requirement from the design document and classify each:

| Coverage | Meaning |
|---|---|
| **Full** | Requirement implemented and verified via runtime evidence |
| **Weak** | Requirement partially implemented or implemented but not fully verified |
| **Missing** | Requirement not implemented or no evidence of implementation |

### Format

Produce the matrix as a JSON array in the scorecard output:

```json
{
  "spec_coverage_matrix": [
    {
      "requirement": "Radial spoke layout",
      "coverage": "Full",
      "evidence": "Screenshot shows 6 spokes radiating from center"
    },
    {
      "requirement": "Camera zoom 0.3x-2.0x",
      "coverage": "Weak",
      "evidence": "Zoom works but bounds not tested at extremes"
    },
    {
      "requirement": "Seed elements in empty districts",
      "coverage": "Missing",
      "evidence": "Not visible in any screenshot or interaction"
    }
  ]
}
```

### Rules

- Every requirement in the design document must appear in the matrix — do not skip requirements
- "Full" requires runtime evidence (screenshot, curl response, interaction log)
- "Weak" means evidence exists but is incomplete — flag for human judgment
- "Missing" means no evidence found — these become remediation tasks automatically

## Remediation Bean Generation

For each **Missing** entry in the spec coverage matrix and each holistic dimension that scores **below its threshold**, generate a remediation bean.

### Format

Produce remediation beans as a JSON array in the scorecard output:

```json
{
  "remediation_beans": [
    {
      "title": "Fix: Seed elements not visible in empty districts",
      "description": "The design spec requires seed elements to appear in empty districts to guide the user. No evidence of this feature was found during holistic review.",
      "source": "spec_coverage:Missing",
      "eval": {
        "criteria": [
          {
            "id": "seed_elements_visible",
            "description": "Empty districts display seed elements as specified in design doc",
            "threshold": 8
          }
        ]
      }
    },
    {
      "title": "Fix: Runtime Health below threshold (scored 6, needs 9)",
      "description": "Console errors present during runtime interaction. Multiple warnings on startup. Holistic reviewer observed degraded responsiveness during cross-domain flows.",
      "source": "dimension:runtime_health",
      "eval": {
        "criteria": [
          {
            "id": "runtime_clean_startup",
            "description": "Application starts with zero console errors or warnings",
            "threshold": 9
          },
          {
            "id": "runtime_responsive",
            "description": "All interactions respond without jank or delay",
            "threshold": 9
          }
        ]
      }
    }
  ]
}
```

### Rules

- Every "Missing" spec coverage entry produces exactly one remediation bean
- Every dimension below threshold produces one remediation bean (combine related issues)
- "Weak" entries do NOT automatically produce remediation beans — flag them for human review
- Each remediation bean must have an `eval` block with criteria specific to the gap
- The `source` field traces back to the coverage matrix entry or dimension that triggered it
- Bean titles start with "Fix:" to distinguish remediation from original tasks

## Scorecard Output

The holistic reviewer outputs a single JSON scorecard. The domain key is `holistic` and dimension keys are snake_case.

```json
{
  "domain": "holistic",
  "dimensions": {
    "integration": {
      "score": 7,
      "threshold": 7,
      "evidence": "Frontend correctly calls backend API endpoints. Data flows end-to-end for primary user flow. Error propagation works — backend 422 shows validation message in frontend. Minor: loading state inconsistent between create and update flows."
    },
    "coherence": {
      "score": 8,
      "threshold": 7,
      "evidence": "Consistent naming throughout. Navigation patterns match across domains. Visual language unified. Interaction patterns predictable."
    },
    "holistic_spec_fidelity": {
      "score": 7,
      "threshold": 8,
      "evidence": "Primary spec requirements met. Camera zoom and radial layout working. Missing: seed elements in empty districts. Weak: district zone gradients not as soft as spec describes."
    },
    "polish": {
      "score": 6,
      "threshold": 6,
      "evidence": "Loading states present. Error handling adequate. No console errors in normal flow. Empty states handled. Minor: hover states inconsistent on secondary buttons."
    },
    "runtime_health": {
      "score": 9,
      "threshold": 9,
      "evidence": "All runtimes start cleanly. Zero console errors or warnings. Frontend renders in under 2 seconds. Backend responds to all endpoints within 100ms. No memory growth observed during 5-minute interaction session."
    }
  },
  "cross_domain_integration": {
    "api_contract_compliance": "Frontend sends expected request shapes. Backend responds with parseable JSON. All status codes handled.",
    "data_flow_verified": true,
    "integration_gaps": []
  },
  "spec_coverage_matrix": [],
  "remediation_beans": []
}
```

## Red Flags

- **Never** score without launching and interacting with all runtimes
- **Never** skip the spec coverage matrix — every spec requirement must be classified
- **Never** leave a "Missing" coverage entry without generating a remediation bean
- **Never** generate remediation beans for "Weak" entries — those are flagged for human review
- **Never** score Holistic Spec Fidelity based on individual task specs — use the overall design document
- **Never** copy domain evaluator scores — holistic dimensions evaluate the whole, not individual parts

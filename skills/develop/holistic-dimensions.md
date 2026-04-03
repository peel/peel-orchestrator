# Holistic Dimensions — Scoring Scales

## Integration

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

## Coherence

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

## Holistic Spec Fidelity

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

## Polish

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

## Runtime Health

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

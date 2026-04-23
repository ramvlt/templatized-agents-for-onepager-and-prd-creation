# Templatized Agents for Retail SDLC (One-Pager → PRD → Arch → Stories → Tests → Launch)

A chain of **12 opinionated Claude Code subagents** that take a raw retail idea and drive it through the full pre-code SDLC — producing enterprise-grade, traceable, compliance-aware artifacts at every stage. Plus a top-level orchestrator that sequences the whole thing with gate checks and state persistence.

**Scope:** full omnichannel retail — ecom, mobile, in-store / POS, loyalty, fulfillment, supply chain, merchandising, marketing.
**Rigor:** enterprise — named personas with volumes, omnichannel journeys with error + empty + abandonment states, Gherkin ACs with coverage matrices, tactical ADRs with real trade-offs, NFRs with numeric targets, phased rollout with feature-flag guardrails and peak-season freeze awareness, and a formal launch-readiness gate.
**Modes:** interactive (guided Q&A) and batch (JSON input) for every authoring agent; review agents produce structured verdicts; the orchestrator adds resume / status / rerun / update modes.

---

## The 12 agents

```
┌───────────────────────────────────────────────────────────────────────────┐
│  retail-sdlc-orchestrator  (top-level: create | resume | status | rerun)  │
└──────────────┬────────────────────────────────────────────────────────────┘
               │ delegates to ↓
               ▼
  Stage 0   retail-onepager-creator        →  one-pager.v{N}.md
  Stage 0.5 retail-onepager-reviewer       →  review.md  (verdict)
               │ PASS
               ▼
  Stage 1   retail-prd-creator             →  prd.v{N}.md + ACs + BRs + Scope + NFRs
  Stage 1.5 retail-prd-reviewer            →  review.md  (verdict + traceability)
               │ PASS
               ▼
  Stage 2   retail-arch-designer           →  arch.v{N}.md + diagrams + ADRs + contracts
  Stage 2.5 retail-arch-reviewer           →  review.md  (NFR→mechanism, retail resilience)
               │ PASS                            ↑
               ▼                                  │
  Stage 3   retail-story-decomposer   Stage 4    retail-adr-creator (invoked on demand)
  Stage 3.5 retail-story-reviewer     retail-testplan-creator
               │                                  │
               └───────────→ (engineering execution) ←────┘
                                     │
                                     ▼
  Stage 5   retail-launch-readiness-auditor   →  GO | GO_WITH_CONDITIONS | NO_GO
```

### Authoring agents

| Agent | Stage | Purpose |
|---|---|---|
| [`retail-onepager-creator`](agents/retail-onepager-creator.md) | 0 | Idea → 12-section retail one-pager (interactive / batch / update) |
| [`retail-prd-creator`](agents/retail-prd-creator.md) | 1 | One-pager → 17-section enterprise PRD with Gherkin ACs, BRs, NFRs, rollout |
| [`retail-arch-designer`](agents/retail-arch-designer.md) | 2 | PRD → component diagram, sequence diagrams, deployment, integration contracts, NFR→mechanism map, ADRs |
| [`retail-story-decomposer`](agents/retail-story-decomposer.md) | 3 | PRD + Arch → Epics / Stories / Sub-tasks with INVEST ACs, DoD, dependency DAG, Jira CSV |
| [`retail-testplan-creator`](agents/retail-testplan-creator.md) | 4 | Enterprise QE test plan (functional, perf, chaos, a11y, security, localization) tied to every AC + NFR |
| [`retail-adr-creator`](agents/retail-adr-creator.md) | cross-stage | MADR-format Architecture Decision Records with ≥ 2 real options |

### Review / gate agents

| Agent | Stage | Purpose |
|---|---|---|
| [`retail-onepager-reviewer`](agents/retail-onepager-reviewer.md) | 0.5 | 12-dimension rubric — blocking vs non-blocking findings |
| [`retail-prd-reviewer`](agents/retail-prd-reviewer.md) | 1.5 | 16-dimension rubric + full traceability matrices (Goal→AC, BR→AC, Capability→AC, Channel→AC) |
| [`retail-arch-reviewer`](agents/retail-arch-reviewer.md) | 2.5 | 16-dimension rubric — PRD traceability, NFR mechanism coverage, retail-specific resilience (peak, POS offline, omnichannel) |
| [`retail-story-reviewer`](agents/retail-story-reviewer.md) | 3.5 | INVEST, sizing, ownership, dependency DAG acyclicity, retail-pattern completeness |
| [`retail-launch-readiness-auditor`](agents/retail-launch-readiness-auditor.md) | 5 | 33-item go/no-go audit with evidence links, peak-season gate, sign-offs |

### Orchestration

| Agent | Purpose |
|---|---|
| [`retail-sdlc-orchestrator`](agents/retail-sdlc-orchestrator.md) | Drives the full chain with gate-then-delegate, persistent state (`sdlc-state.json`), resume / status / rerun / update modes |

---

## What "enterprise rigor" means here

Every agent enforces retail-specific quality gates the moment they become relevant:

- **Personas** — named archetypes with volumes, channels, accessibility notes. Associate personas *required* if in-store scope.
- **Journeys** — every capability × persona needs happy + error + empty + abandonment + handoff.
- **Acceptance criteria** — Gherkin GIVEN-WHEN-THEN, numeric thresholds, `test_type` tagged, mapped to goals/BRs, with coverage matrix.
- **Business rules** — retail categories (loyalty, tax, pricing, fulfillment, returns, inventory, payments, customer-data, compliance) prompted by default.
- **NFRs** — performance (peak TPS + steady-state p95), availability SLO, PCI scope (SAQ tier), privacy (CCPA-CPRA + GDPR flags), **WCAG 2.2 AA + Section 508**, localization, observability, rollback — each mapped in arch to a concrete mechanism with a validation approach.
- **Architecture** — PRD-traceable, retail-resilience checks (peak load ≥ 2×, POS offline, omnichannel consistency, oversell prevention, graceful degradation), MADR ADRs for real trade-offs.
- **Stories** — INVEST, ≤ 5 day each, single-team ownership, acyclic dep DAG, retail patterns (feature-flag scaffolding, shadow mode, expand+contract migrations, chaos tests, accessibility audit cycle, runbook, training).
- **Test plan** — every AC → ≥ 1 test case; every NFR → a named strategy; explicit perf / chaos / accessibility / PCI / privacy strategies.
- **Rollout** — phased with feature flags, guardrail metrics per phase, explicit rollback triggers, **peak-season freeze awareness** (default Nov 1 – Jan 5; configurable).
- **Launch readiness** — 33-item audit, evidence-linked, scored PASS/FAIL/N/A/CONDITIONAL, formal go/no-go.
- **Architecture hygiene** — PRD/one-pager creators block tech keywords; arch captures all tech choices with rationale in ADRs.

---

## Repository layout

```
.
├── README.md
├── agents/
│   ├── retail-onepager-creator.md
│   ├── retail-onepager-reviewer.md
│   ├── retail-prd-creator.md
│   ├── retail-prd-reviewer.md
│   ├── retail-arch-designer.md
│   ├── retail-arch-reviewer.md
│   ├── retail-adr-creator.md
│   ├── retail-story-decomposer.md
│   ├── retail-story-reviewer.md
│   ├── retail-testplan-creator.md
│   ├── retail-launch-readiness-auditor.md
│   └── retail-sdlc-orchestrator.md
├── templates/
│   ├── retail-onepager-template.md
│   └── retail-prd-template.md
├── schemas/
│   ├── onepager-creator-input.schema.json
│   ├── onepager-creator-output.schema.json
│   ├── prd-creator-input.schema.json
│   ├── prd-creator-output.schema.json
│   ├── reviewer-input.schema.json
│   ├── reviewer-output.schema.json
│   ├── arch-designer-input.schema.json
│   ├── arch-designer-output.schema.json
│   ├── story-decomposer-input.schema.json
│   ├── story-decomposer-output.schema.json
│   ├── testplan-creator-input.schema.json
│   ├── testplan-creator-output.schema.json
│   ├── launch-readiness-input.schema.json
│   ├── launch-readiness-output.schema.json
│   ├── adr-creator-input.schema.json
│   ├── adr-creator-output.schema.json
│   ├── sdlc-orchestrator-input.schema.json
│   └── sdlc-orchestrator-output.schema.json
└── examples/
    ├── inputs/
    │   └── bopis-v2.onepager-creator-input.json
    └── outputs/bopis-v2/
        ├── onepager.v1.md
        ├── onepager.v1.run.json
        ├── prd.v1.md
        ├── acceptance-criteria.v1.json
        ├── architecture/
        │   ├── architecture.v1.md
        │   ├── architecture.v1.components.mmd
        │   ├── architecture.v1.sequences.mmd
        │   └── adrs/
        │       ├── ADR-001-inventory-read-path.md
        │       └── ADR-003-payment-tokenization.md
        ├── stories/
        │   ├── epics.v1.md
        │   └── stories.v1.json
        ├── qe/
        │   └── test-plan.v1.md
        └── launch/
            └── launch-readiness.v1.md
```

---

## Install

**Option 1 — Per-project (recommended)**

```bash
# from your retail project root
mkdir -p .claude/agents
cp /path/to/this/repo/agents/*.md .claude/agents/
cp -r /path/to/this/repo/templates /path/to/this/repo/schemas .claude/
```

**Option 2 — Globally for all projects**

```bash
cp agents/*.md ~/.claude/agents/
mkdir -p ~/.claude/retail-artifacts
cp -r templates schemas ~/.claude/retail-artifacts/
```

Claude Code auto-discovers `.claude/agents/*.md` and surfaces them by `name` to the Task tool / orchestrating agent.

---

## Usage — orchestrator (recommended entry)

```
Run retail-sdlc-orchestrator in create mode.
Initiative slug: bopis-v2
Sponsor: Dana K.  Product lead: Priya R.
Seed idea: "Fix the 9% BOPIS pickup failure rate — real-time inventory + reservations."
```

The orchestrator:
1. Scaffolds the working dir and `sdlc-state.json`.
2. Delegates Stage 0 → `retail-onepager-creator` (interactive).
3. Gates before delegating 0.5 → `retail-onepager-reviewer`.
4. Continues through Stages 1 → 4, asking for your approval at each gate.
5. Yields at "engineering execution".
6. When you return for GA prep, delegates Stage 5 → `retail-launch-readiness-auditor`.

Any time: `Run retail-sdlc-orchestrator in status mode` for a snapshot.
To resume from where you left off: `Run retail-sdlc-orchestrator in resume mode for bopis-v2`.

## Usage — individual agent (stage-by-stage)

You can also invoke any agent directly:

```
Run retail-onepager-creator interactively for initiative bopis-v2.
```
```
Run retail-prd-creator create mode with one_pager_path=retail-initiatives/bopis-v2/onepager.v1.md
```
```
Run retail-arch-designer create mode with prd_path=retail-initiatives/bopis-v2/prd.v1.md
```
```
Run retail-adr-creator interactively for decision "Event backbone: queue vs stream"
```
```
Run retail-launch-readiness-auditor for bopis-v2, target phase ga, window 2026-09-15..2026-10-30
```

## Usage — batch mode

Pass a JSON file matching the input schema:

```
Run retail-onepager-creator batch mode with examples/inputs/bopis-v2.onepager-creator-input.json
```

See the worked BOPIS v2 artifacts in `examples/outputs/bopis-v2/`.

## Usage — update / rerun

After a one-pager change mid-flight:

```
Run retail-sdlc-orchestrator in update mode for bopis-v2,
reason="Scope added international (UK) — GDPR now required",
change_scope=["onepager"]
```

The orchestrator cascades the update through all affected downstream stages, preserving prior versions with delta headers.

---

## Compliance defaults (scope-driven mandatory matrix)

| Scope includes | Mandatory at review-time |
|---|---|
| Any customer-facing UI | WCAG 2.2 AA |
| Payments / tokenization / POS | PCI-DSS SAQ scope stated + ADR |
| New PII collection | CCPA-CPRA (+ GDPR if EU) + consent journey + retention BR |
| POS / Associate App / in-store | Section 508 + offline resilience + training Story |
| Multi-region | Localization (language, currency, tax, date-format) |
| Loyalty | Loyalty BRs (earn, burn, tier, expiry) |
| Fulfillment (BOPIS / SFS / SDD) | Fulfillment BRs (radius, SLA, eligibility) + oversell-prevention arch |
| Peak season launch | 2× peak sizing + chaos test + peak-freeze check |

If scope triggers a mandatory item and the artifact is silent, the reviewer emits a **blocking** finding.

---

## Peak-season freeze

Retail has launch freeze windows. Default: `2026-11-01..2027-01-05` (US holiday).

- One-pager creator prompts if any rollout phase overlaps.
- PRD reviewer flags as blocking if GA is inside freeze.
- Launch readiness auditor marks NO_GO if target GA window overlaps freeze.
- Override via `peak_season_freezes` in reviewer or launch-readiness input.

---

## Design principles

1. **Ask, don't fabricate.** Unknown persona volume, baseline, or BR → `AskUserQuestion`, never invention.
2. **Gate before writing.** Every major artifact passes an approval gate before hitting disk.
3. **No architecture at PRD time.** PRD creator blocks tech keywords; Arch stage owns all tech choices via ADRs.
4. **Traceability is a hard gate.** Every stage reviewer computes coverage (Goal→AC, BR→AC, AC→Story, AC→TC, NFR→Mechanism→Strategy). Anything < 0.95 fails.
5. **Omnichannel means multi-persona.** Any in-store scope requires an associate persona + journey; agents enforce this.
6. **Preserve prior versions.** Update mode writes v{N+1} with a delta header; v{N} is never overwritten.
7. **Evidence at launch.** Launch readiness requires linked artifact / run-id for every checklist item.

---

## Worked example

See `examples/outputs/bopis-v2/` — a complete BOPIS v2 initiative:
- One-pager → PRD → 14 Gherkin ACs with coverage matrix
- Architecture (component + sequence diagrams + 2 ADRs including PCI tokenization decision)
- Epics + Stories (sampled, with dependency + DoD patterns)
- Test plan (88 test cases + 12 NFR strategies)
- Launch readiness audit (GO_WITH_CONDITIONS + evidence table)

Use it as a sanity check your installation produces comparable quality on similar inputs.

---

## Extending

- **Industry variant** (grocery, luxury, QSR, travel retail) → fork templates + tighten the scope-driven mandatory matrix in reviewers.
- **New NFR category** (e.g., sustainability) → add to template + add dimension in the relevant reviewer rubrics.
- **Org-specific governance** (PCI SAQ-D tenants, EU-first orgs) → tighten mandatory matrices.
- **Additional stages** (e.g., `retail-deployment-agent`) → follow the same YAML-frontmatter pattern and register in the orchestrator chain.

---

## Versioning

All 12 agents and both templates are at **v1.0**. Semver major bumps mean breaking input/output schema changes.

---

## License

Use, fork, and adapt for your org. No warranty — review every artifact before handing to engineering.

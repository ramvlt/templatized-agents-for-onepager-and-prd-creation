# Templatized Agents for Retail One-Pager & PRD Creation

Four opinionated, interactive-or-batch Claude Code subagents that take a raw retail idea and produce enterprise-grade, PRD-ready artifacts — with traceability, Gherkin acceptance criteria, compliance coverage (PCI / CCPA / WCAG / Section 508 / localization), and realistic omnichannel rollout plans.

**Scope:** full omnichannel retail — ecom, mobile, in-store / POS, loyalty, fulfillment, supply chain, merchandising, marketing.
**Rigor:** enterprise — personas with volumes, user journeys with error + empty states, NFRs with numeric targets, phased rollout with feature-flag guardrails and peak-season awareness.
**Modes:** interactive (guided Q&A) and batch (JSON input file) for every authoring agent.

---

## The 4 Agents

```
   ┌────────────────────────────┐
   │ retail-onepager-creator    │  One-pager.v1.md
   │  interactive | batch       │  + run.json
   └──────────────┬─────────────┘
                  │
                  ▼
   ┌────────────────────────────┐
   │ retail-onepager-reviewer   │  Review report + verdict
   │  review                    │  (PASS / PASS_WITH_MINOR / REVISE)
   └──────────────┬─────────────┘
                  │ PASS
                  ▼
   ┌────────────────────────────┐
   │ retail-prd-creator         │  PRD.v1.md
   │  create | update           │  + acceptance-criteria.v1.json
   │  interactive | batch       │  + business-rules.v1.md
   │                            │  + scope-boundary.v1.md
   │                            │  + nfrs.v1.md
   └──────────────┬─────────────┘
                  │
                  ▼
   ┌────────────────────────────┐
   │ retail-prd-reviewer        │  Review report + traceability matrices
   │  review                    │  ready_for_architecture: true/false
   └────────────────────────────┘
```

| Agent | Stage | Purpose |
|---|---|---|
| [`retail-onepager-creator`](agents/retail-onepager-creator.md) | 0 | Turn an idea / VOC / competitive trigger into a structured 12-section retail one-pager |
| [`retail-onepager-reviewer`](agents/retail-onepager-reviewer.md) | 0.5 | 12-dimension rubric review; catches issues before they reach the PRD |
| [`retail-prd-creator`](agents/retail-prd-creator.md) | 1 | Convert an approved one-pager into a 17-section enterprise PRD with Gherkin ACs, BRs, NFRs, rollout |
| [`retail-prd-reviewer`](agents/retail-prd-reviewer.md) | 1.5 | 16-dimension rubric with traceability matrices; gate before architecture design |

---

## What "enterprise rigor" means here

Each agent enforces retail-specific quality gates the moment they become relevant:

- **Personas** — named archetypes with volumes, channels, and accessibility notes. Associate personas are *required* if in-store scope exists.
- **Journeys** — every capability × persona needs happy + error + empty + abandonment + handoff.
- **Acceptance criteria** — Gherkin GIVEN-WHEN-THEN, numeric thresholds, test_type tagged, mapped to goals and business rules, with a coverage matrix.
- **Business rules** — retail categories (loyalty, tax, pricing, fulfillment, returns, inventory, payments, customer-data, compliance) surfaced by default.
- **NFRs** — performance (peak TPS + steady-state p95), availability SLO, PCI scope (SAQ tier), privacy (CCPA-CPRA + GDPR flags), **WCAG 2.2 AA + Section 508**, localization, observability, rollback.
- **Rollout** — phased with feature flags, guardrail metrics per phase, explicit rollback triggers, and **peak-season freeze awareness** (US default Nov 1 – Jan 5; configurable).
- **Architecture hygiene** — authoring agents block tech/stack keywords; describing WHAT, not HOW.

---

## Repository layout

```
.
├── README.md
├── agents/
│   ├── retail-onepager-creator.md
│   ├── retail-onepager-reviewer.md
│   ├── retail-prd-creator.md
│   └── retail-prd-reviewer.md
├── templates/
│   ├── retail-onepager-template.md
│   └── retail-prd-template.md
├── schemas/
│   ├── onepager-creator-input.schema.json
│   ├── onepager-creator-output.schema.json
│   ├── prd-creator-input.schema.json
│   ├── prd-creator-output.schema.json
│   ├── reviewer-input.schema.json
│   └── reviewer-output.schema.json
└── examples/
    ├── inputs/
    │   └── bopis-v2.onepager-creator-input.json
    └── outputs/bopis-v2/
        ├── onepager.v1.md
        ├── onepager.v1.run.json
        ├── prd.v1.md
        └── acceptance-criteria.v1.json
```

---

## Install

These agents follow the Claude Code subagent convention: a markdown file with YAML frontmatter (`name`, `description`, `tools`).

**Option 1 — Use per-project (recommended)**

```bash
# from your retail project root
mkdir -p .claude/agents
cp /path/to/this/repo/agents/*.md .claude/agents/
cp -r /path/to/this/repo/templates /path/to/this/repo/schemas .claude/
```

**Option 2 — Install globally for all projects**

```bash
cp agents/*.md ~/.claude/agents/
mkdir -p ~/.claude/retail-artifacts
cp -r templates schemas ~/.claude/retail-artifacts/
```

Claude Code auto-discovers `.claude/agents/*.md` and surfaces them to the Task tool (or orchestrating agent) by `name`.

---

## Usage — interactive mode

Just invoke the agent. Examples (wording will vary by orchestrator):

```
Run retail-onepager-creator in interactive mode.
Initiative slug: bopis-v2.
```

The agent will:
1. Ask for identity + retail domain + channels
2. Walk through 9 question blocks (problem, why now, solution, audience, scope, KPIs, rollout & compliance, dependencies & risk, cost)
3. Present a rendered preview
4. Write `retail-initiatives/bopis-v2/onepager.v1.md` on your approval

Then:
```
Run retail-onepager-reviewer on retail-initiatives/bopis-v2/onepager.v1.md
(strictness: standard)
```

If PASS or PASS_WITH_MINOR:
```
Run retail-prd-creator in create mode with:
one_pager_path = retail-initiatives/bopis-v2/onepager.v1.md
initiative_slug = bopis-v2
```

---

## Usage — batch mode

Drop a JSON file matching the input schema, then run:

```
Run retail-onepager-creator in batch mode with input
examples/inputs/bopis-v2.onepager-creator-input.json
```

See the full worked example in `examples/outputs/bopis-v2/`.

---

## Usage — update mode

After the PRD is in-flight and the one-pager changes (scope shift, new compliance requirement, new KPI):

```
Run retail-prd-creator in update mode:
prior_prd_path = retail-initiatives/bopis-v2/prd.v1.md
updated_one_pager_path = retail-initiatives/bopis-v2/onepager.v2.md
update_reason = "Added international scope (UK) requiring GDPR coverage"
```

The creator:
1. Diffs old → new one-pager
2. Maps diff to PRD sections to revise
3. Interactively re-runs just the affected sections
4. Writes `prd.v2.md` with a delta header (keeps v1 intact)
5. Emits `requires_rework[]` for downstream stages (arch, stories, tests)

---

## Compliance Defaults

Every agent uses scope to determine *which* compliance dimensions are **mandatory** vs optional:

| Scope includes | Mandatory |
|---|---|
| Any customer-facing UI | WCAG 2.2 AA |
| Payments / tokenization / POS | PCI-DSS SAQ scope |
| New PII collection | CCPA-CPRA (+ GDPR if EU) |
| POS / Associate App / in-store | Section 508 + offline-resilience edge cases |
| Multi-region | Localization (language, currency, tax, date-format) |
| Loyalty | Loyalty BRs (earn, burn, tier, expiry) |
| Fulfillment (BOPIS / SFS / SDD) | Fulfillment BRs (radius, SLA, eligibility) |

If a scope triggers a mandatory dimension and the artifact is silent, the reviewer emits a **blocking** finding.

---

## Peak-Season Freeze

Retail has launch freeze windows. Default: `2026-11-01..2027-01-05` (US holiday).

- One-pager creator prompts if any rollout phase overlaps the freeze.
- Reviewer flags GA-inside-freeze as blocking unless explicitly justified.
- You can override via `peak_season_freezes` in reviewer input.

---

## Design principles behind the agents

1. **Ask, don't fabricate.** If a persona volume, metric baseline, or BR is unknown, the agent asks via `AskUserQuestion` — it never invents.
2. **Gate before writing.** Every major artifact (ACs, scope boundary, business rules, final PRD) passes through a `AskUserQuestion` approval gate before hitting disk. No silent artifact creation.
3. **No architecture at PRD time.** Creator agents block tech keywords. The reviewer flags leaks. Architecture is a later stage.
4. **Traceability is a hard gate.** The PRD reviewer computes Goal→AC, BR→AC, Capability→AC, and Channel→AC coverage. Anything < 0.95 fails.
5. **Omnichannel means multi-persona.** Any scope touching in-store requires an associate persona + journey; the agents enforce this.
6. **Preserve prior versions.** Update mode never overwrites v{N}; it writes v{N+1} with a delta header.

---

## Extending

- **Industry variant** (grocery, luxury, QSR) → fork the template + add/remove mandatory-compliance rows in the reviewer rubric.
- **New NFR category** (e.g., sustainability) → add to the NFR table in `templates/retail-prd-template.md` and a dimension in `retail-prd-reviewer.md`.
- **Org-specific governance** (e.g., PCI SAQ-D tenants, EU-first orgs) → tighten the scope-driven mandatory matrix.
- **Additional agents** (e.g., `retail-story-decomposer`, `retail-arch-designer`) → follow the same YAML-frontmatter pattern and chain via `next_recommended_agent`.

---

## Worked Example

See `examples/outputs/bopis-v2/` — a complete BOPIS v2 initiative:
- Input JSON → one-pager → (reviewer pass) → PRD → 14 Gherkin ACs with coverage matrix.

Use it as a sanity check that your installation produces comparable quality on similar inputs.

---

## Versioning

All four agents and both templates are at **v1.0**. Semver major bumps mean breaking changes to input/output schemas.

---

## License

Use, fork, and adapt for your org. No warranty — review every artifact before handing to engineering.

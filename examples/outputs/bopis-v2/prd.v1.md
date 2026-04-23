# BOPIS v2 — Real-time Inventory & 90-min Reservation — PRD

> **PRD Version:** v1 &nbsp;•&nbsp; **Last Updated:** 2026-04-23 &nbsp;•&nbsp; **Status:** Draft
> **Author:** Priya R. &nbsp;•&nbsp; **Source One-Pager:** `examples/outputs/bopis-v2/onepager.v1.md`
> **Retail Domain(s):** Ecom, In-Store/POS, Fulfillment, Loyalty
> **Channels:** Web, iOS, Android, Store-POS, Associate App, Kiosk

---

## 0. Executive Summary

Customers who reserve items for store pickup currently find them out of stock ~9% of the time, costing $14.6M/yr in revenue and 11pt of NPS. BOPIS v2 introduces real-time store inventory, immediate inventory decrement on a 90-min reservation, and associate notifications — so the promise we make on PDP matches what's on the shelf when the customer arrives. Primary success metric: BOPIS fulfillment rate 91.0% → ≥ 97.5% within 90 days post-GA. Pilot Q3 2026 (5 stores, 2% web), ramp to GA before the Nov 1 peak freeze.

---

## 1. Problem Statement

### 1.1 What's broken today
Our BOPIS reservation relies on a nightly inventory snapshot plus a coarse safety-stock buffer. The snapshot is stale by the time a customer reserves, and the buffer isn't tuned per-store or per-category. Customers are told "available" on PDP, arrive at the store, and find the item isn't actually pickable.

### 1.2 Who is affected
- **Loyalty Tier-2 + Tier-3 shoppers within 25 mi of a store** — 4.2M annually, 54% of BOPIS revenue
- **Store associates** — 22K users, forced into apology-and-substitution loops
- **Fulfillment managers** — no signal to rebalance

### 1.3 Cost of inaction (quantified)
| Dimension | Today | 12-month trajectory if we do nothing |
|---|---|---|
| Revenue (BOPIS orders abandoned at pickup) | $14.6M/yr at risk | $18–22M (trend + competitor share-shift) |
| Contact center cost | $1.8M/yr | $2.4M |
| NPS (BOPIS users) | 47 (−11 vs non-BOPIS) | 42 |

### 1.4 Evidence
- **Analytics:** `oms.bopis_reservation_fulfillment` Q1 2026 = 91.0% (BigQuery dashboard `bopis-health`)
- **VOC:** Survey S-412 — 73 verbatims citing "item not there when I arrived"
- **Store-ops:** Zendesk tag `bopis-oos` — 40,114 tickets L12M
- **Competitive:** Competitor A real-time store inventory teardown (internal link)

---

## 2. Goals & Non-Goals

### 2.1 Goals
- **G1 — Reduce OOS surprise:** Fulfillment rate 91.0% → ≥ 97.5%
- **G2 — Reduce cycle time:** Reservation → ready 42 min → ≤ 25 min
- **G3 — Never block browse:** Graceful degradation when OMS unavailable
- **G4 — Loyalty value capture:** 100% of eligible pickups accrue within 24h
- **G5 — Accessible to all:** WCAG 2.2 AA on every customer surface
- **G6 — Privacy-respectful:** Location signal only with explicit consent

### 2.2 Non-Goals
- Same-day delivery orchestration (separate initiative)
- Locker hardware deployment (RFP in flight)
- International rollout
- Grocery/perishables

---

## 3. User Personas

| Persona | Role | Channel(s) | Key Actions | Frequency | Current Pain | Tech Comfort | Accessibility |
|---|---|---|---|---|---|---|---|
| **Tier-2/3 Loyalty Shopper "Maya"** | Repeat customer, 2.4×/mo | Web, iOS | Browse, reserve, pickup | Weekly | Arrives, item missing, frustrated | High | 6% of segment uses AT — must support VO/TB |
| **Store Associate "Alex"** | Shift FT associate | Associate App, POS | Pick, prepare, hand off, substitute | 20–40×/shift | App misses notifications under peak load | Medium | Section 508; one-handed operation common |
| **Fulfillment Manager "Maya K."** | DC/ops supervisor | Ops console, email | Balance store loads, reroute, report | Hourly | No signal on SFS queue health | High | — |

---

## 4. User Journeys

### 4.1 Primary — Tier-2/3 Shopper reserves and picks up

**Preconditions:** Signed in, within 25 mi of a store, store preference set OR location consent granted.

| Step | Actor action | System response | Channel | Notes |
|---|---|---|---|---|
| 1 | Opens PDP | "3 available at Store #042 — ready in ~20 min" | Web / iOS | Inventory call to OMS, p95 ≤ 400ms |
| 2 | Taps "Pick up in store" | Reserves item; decrements inventory; confirms 90-min window | Web → OMS | TTL = 90 min |
| 3 | (Optional) Pays now or at pickup | Per BR-07 auth flow | Web | |
| 4 | Receives confirmation | Email + push within 60s | iOS, email | Includes QR code |
| 5 | Arrives, scans QR at kiosk | Verifies; notifies Associate App | Kiosk → App | |
| 6 | Receives item from associate (or self-locker) | POS closes order; loyalty credits | POS | Per BR-01 |

**Happy path success state:** Customer leaves with item in ≤ 5 min of arrival.
**Error path:** If item is OOS at pick-time (rare after real-time inventory), AC-013 partial-fulfillment flow; customer sees "just sold out — try Store #051 (2 mi) with 4 in stock" with 1-tap re-reserve.
**Empty state:** First-time BOPIS user — explainer card on how pickup works, link to FAQ.
**Abandonment points:** Between reservation and arrival (~22% today); SMS reminder at T+45min and T+80min; cancel self-service available.
**Handoff points:** Web → Email (confirmation) → iOS push (reminder) → Kiosk (arrival) → Associate App (fulfill) → POS (close) → App (loyalty).

### 4.2 Secondary — Associate fulfills reservation

**Preconditions:** Associate on shift, app logged in, role = picker.

| Step | Actor action | System response | Channel | Notes |
|---|---|---|---|---|
| 1 | Receives reservation push | Shows SKU, location in store, deadline | Associate App | Respects quiet hours |
| 2 | Picks item, scans | Marks as ready; notifies customer | Associate App | |
| 3 | On customer arrival scan | "Alex arrived at kiosk — locker 7" | Associate App | |
| 4 | Hand-off at kiosk or counter | Closes order in POS | POS | |

**Error path:** If item is actually missing (shrinkage), associate marks "can't find" → customer offered near-store alternate or cancel (AC-013).
**Empty state:** No active reservations — app shows today's pickup queue health.

### 4.3 Tertiary — Graceful degradation (OMS unavailable)
**Preconditions:** OMS inventory API returning 5xx or timing out.
| Step | Actor action | System response | Channel | Notes |
|---|---|---|---|---|
| 1 | Customer loads PDP | Product content renders; inventory module shows "Check availability in-store" | Web / iOS | Circuit-breaker open 30s |
| 2 | Customer taps "Pick up in store" | Flow is hidden or disabled with explainer; "ship to me" remains available | Web / iOS | No customer-visible error |

---

## 5. Proposed Solution (capability-level)

### 5.1 Capability map

| Capability | Customer-facing? | Channel | Depends on | Priority |
|---|---|---|---|---|
| Real-time store inventory on PDP/cart/checkout | Y | Web, iOS, Android | OMS, Inventory Service | P0 |
| 90-min reservation with immediate decrement | Y | Web, iOS, Android | OMS, Payments (auth) | P0 |
| Associate reservation + arrival notification | N | Associate App | Notification Service, Store IoT | P0 |
| Kiosk self-pickup with QR scan | Y | Kiosk | Kiosk firmware, Associate App | P0 |
| Loyalty accrual at pickup completion | Y | POS, App | Loyalty Platform | P1 |
| Graceful degradation when OMS unavailable | Y | All customer channels | — | P0 |
| Reservation expiry + re-reserve | Y | Email, Push | Notification Service | P1 |
| Partial fulfillment flow | Y | App, Associate App | OMS | P1 |

---

## 6. Acceptance Criteria

See `acceptance-criteria.v1.json` — 14 ACs, all Gherkin, all testable, prioritized P0/P1.

**AC counts:** 10 P0, 4 P1, 0 P2
**Coverage:** Goal→AC 100%, BR→AC 100%, Capability→AC with ≥1 happy + ≥2 edge + ≥1 error = 100%

Key samples inline (full set in JSON artifact):

```gherkin
# AC-001 (P0) — Real-time inventory accuracy
GIVEN a product with inventory = 3 at Store #042
  AND the customer's preferred store is #042
WHEN the customer loads the PDP
THEN the page displays "3 available at {storeName}" within p95 ≤ 400ms
  AND the displayed count matches OMS inventory within a ≤ 30s staleness window
```

```gherkin
# AC-005 (P0) — Concurrent reservation on last unit
GIVEN Store #042 has inventory = 1 for SKU X
  AND Customer A and Customer B attempt to reserve simultaneously
WHEN both confirmations are submitted within 2s of each other
THEN exactly one reservation succeeds
  AND the losing customer sees "Sorry, just sold out — here are 2 nearby stores with availability"
  AND inventory is atomically decremented; no oversell
```

---

## 7. Business Rules

See `business-rules.v1.md`. Summary:

| ID | Rule | Source | Impact if broken |
|---|---|---|---|
| BR-01 | Loyalty points credit within 24h of pickup | Loyalty Program Guide §4.2 | Customer trust, program integrity |
| BR-02 | Tax calculated at pickup-store jurisdiction | Tax Policy 2024 | Audit / legal |
| BR-03 | Reservation expires at 90 min if uncollected | Store-Ops Playbook | Stock availability, sellthrough |
| BR-04 | BOPIS eligible only within 25 mi of selected store | Fulfillment Policy | Ops feasibility |
| BR-05 | Inventory staleness ≤ 30s in displayed availability | This PRD | Promise reliability |
| BR-06 | No oversell: last-unit reservation atomic | Ops Policy | Customer trust |
| BR-07 | Payment auth voided/refunded within 10s on cancel | Payments Policy | Financial integrity |
| BR-08 | Location signal consent required, scope-limited, 30-day retention | Privacy Policy | Regulatory |
| BR-09 | Partial fulfillment offers customer 5-min choice window | Ops Playbook | Customer control |

---

## 8. Scope

See `scope-boundary.v1.md`. Summary:

**In Scope (V1):** Real-time inventory, 90-min reservation, Associate App notifications, Kiosk QR, Loyalty accrual, Graceful degradation — US only.

**Explicitly Out of Scope:** SDD orchestration, locker hardware, international, grocery/perishables.

**Deferred V2+:** Curbside UI, reservation extension self-service, multi-store split reservation.

**Scope-Creep Risks:** "Just add curbside" pressure from store ops; "just add frozen food" pressure from merch. Guardrail: any V1 addition requires sponsor re-approval + arch re-review.

---

## 9. Dependencies

| Type | Dependency | Owner | Needed by | If not ready → |
|---|---|---|---|---|
| Platform | OMS v3 inventory API | OMS team | 2026-Q2 week 6 | Delay pilot 2 wks; V1.1 fallback cache+poll |
| Platform | Notification Service priority queue | Notifications team | 2026-Q2 week 8 | Associate notifications degrade; ship w/ degraded SLA |
| Platform | Kiosk firmware v4.1 | Store IoT | 2026-Q2 week 10 | Pilot stores use associate-only handoff (no kiosk) |
| Data | Store master with geo-coords validated | Data Eng | 2026-Q2 week 4 | Radius logic degraded; fall back to zip-only |
| Vendor | Push vendor uplift contract | Payments legal | 2026-Q2 week 8 | Associate notifications use email fallback |
| Org | Associate training content + e-learning | Retail Ops | 1 wk before pilot | Pilot delayed |
| Compliance | CCPA-CPRA DPIA sign-off | Privacy | 2026-Q2 week 10 | Launch blocker |

---

## 10. Success Metrics & Measurement Plan

### 10.1 Primary KPIs
| Metric | Baseline | Target | Window | Source | Owner |
|---|---|---|---|---|---|
| BOPIS fulfillment rate | 91.0% | ≥ 97.5% | 90 days post-GA steady-state | BigQuery `oms.order_events` | PM |
| BOPIS attach rate (PDP sessions <25 mi) | 7.2% | 12.0% | 90 days post-GA | Adobe + CDP | PM |
| Cycle time (reservation → ready) | 42 min | ≤ 25 min | Steady-state month | OMS order_events | Ops |
| Loyalty accrual latency | 48h avg | ≤ 24h p95 | 90 days | Loyalty Platform | Loyalty PM |

### 10.2 Guardrails (must not regress)
- PDP p95 load ≤ 2.2s
- Checkout error rate ≤ 0.8%
- Store NPS ≥ 47 (BOPIS segment)
- Refund rate delta ≤ +0.2 pt

### 10.3 Instrumentation
- Events: `reservation_created`, `reservation_confirmed`, `reservation_expired`, `pickup_arrived`, `pickup_completed`, `pickup_cancelled`, `degradation_activated` (see AC-014)
- Dashboard: `bopis-v2-health` (to be created in discovery)
- A/B: 50/50 by session within ramp % for 4 wks; decision: uplift ≥ 3pt on attach rate at p<0.05

---

## 11. Non-Functional Requirements

See `nfrs.v1.md`. Summary (partial):

| Category | Requirement | Target | Measured By |
|---|---|---|---|
| Performance | PDP inventory call p95 | ≤ 400ms | Synthetic + RUM |
| Performance | Peak sustained RPS | 12,000 RPS for 60 min w/ ≤ 0.1% error | Load test |
| Availability | Customer-facing SLO | 99.95% (99.99% peak-season) | SLO dashboard |
| Availability | Graceful degradation | Browse never blocked when OMS 5xx | Chaos test |
| Security / PCI | PAN scope | Unchanged; tokenize at edge | PCI QSA review |
| Privacy | Location signal | Consent-gated, 30-day retention, scoped | Privacy review |
| Privacy | PII in logs | None; redact at source | Log scanner |
| Accessibility | WCAG 2.2 AA | 100% critical customer flows | Axe + manual VO/TB |
| Accessibility | Associate App Section 508 | Verified | Manual audit |
| Scalability | Inventory cache | 10× normal peak headroom | Load test |
| Localization | Languages | en-US only V1 | — |
| Observability | Events | See AC-014 | Event contract tests |
| Rollback | Safe rollback | ≤ 15 min via flag | Runbook drill |
| Compliance | PCI-DSS 4.0 scope | SAQ-A maintained | QSA |
| Compliance | CCPA-CPRA | DPIA complete pre-launch | Privacy sign-off |

---

## 12. Error Handling & Edge Cases

| Flow | Failure | User sees | System does | Log level |
|---|---|---|---|---|
| PDP inventory | OMS timeout > 800ms | "Check availability in-store" | Circuit-breaker 30s | WARN |
| Reserve | Inventory lost race | "Just sold out — try Store #051" + 1-tap re-reserve | Release partial hold | INFO |
| Reserve | Payment auth 5xx | Retry once; then "Try another method" | No PAN captured | ERROR |
| Kiosk | 3 failed QR scans | "Please see an associate" + help beacon | Associate push | INFO |
| Pickup | Customer no-show | Auto-expire at 90 min + re-reserve email | Inventory returned | INFO |
| Partial | 1 of 2 items unavailable | 5-min choice: proceed / cancel | Await decision, then act | INFO |

**Retail edges covered explicitly:**
- Store closes between reserve & pickup → auto-cancel + refund + notify
- Customer crosses tax jurisdiction → tax fixed at pickup-store per BR-02
- Concurrent last-unit reservation → atomic decrement (AC-005)
- Loyalty account merge mid-transaction → queue accrual, resolve post-merge
- Refund of BOPIS before pickup → AC-011
- POS offline at pickup → fallback to paper slip + reconcile when online
- Price change between reserve & pickup → honor reserve-time price (BR extension pending)

---

## 13. Rollout Plan

| Phase | Window | Audience | Feature flag | Guardrails | Rollback trigger |
|---|---|---|---|---|---|
| Internal dogfood | 2026-Q2 wk 11 | Employees at 1 store | `bopis_v2_internal` | Manual smoke only | Any P0 |
| Closed pilot | 2026-Q3 wk 1-4 | 5 stores, 2% web | `bopis_v2_pilot` | Fulfillment ≥ 95%; err ≤ 1% | > 2% err for 1h; fulfillment < 90% for 24h |
| Ramp 10% | 2026-Q3 wk 5-6 | 10% traffic + 50 stores | `bopis_v2_ramp_10` | PDP p95 ≤ 2.2s; guardrails green | p95 regression 20%; err > 1% |
| Ramp 50% | 2026-Q3 wk 7-9 | 50% traffic + 600 stores | `bopis_v2_ramp_50` | Same | Same |
| GA | 2026-Q3 wk 10 → Q4 wk 4 | 100% + all 1,200 stores | `bopis_v2_ga` | All guardrails | Any P0 > 2h |
| Hypercare | 2 wks post-GA (then flag-only monitor into freeze) | — | — | Daily review | — |

**Peak-season freeze (Nov 1 – Jan 5):** No new ramp changes. Hypercare continues in monitor-only mode; rollback capability retained.
**Training:** 30-min e-learning for all associates + launch-day huddle deck; ships Q2 wk 10.
**Customer-care:** CSR macros updated; Zendesk articles published 1 wk pre-pilot.

---

## 14. Launch Readiness Checklist

- [ ] PRD approved (PM, Eng, UX, Privacy, Security)
- [ ] Architecture design approved
- [ ] All P0 ACs implemented & automated
- [ ] PCI QSA sign-off (scope unchanged)
- [ ] CCPA-CPRA DPIA completed
- [ ] WCAG 2.2 AA audit passed
- [ ] Load test passed at 2× peak
- [ ] Chaos test (OMS outage) passed
- [ ] Runbook + on-call rotation confirmed
- [ ] Feature flag + kill switch verified in prod
- [ ] Associate training 100% completion in pilot stores
- [ ] Customer-care macros updated
- [ ] Legal & tax sign-off
- [ ] Observability: `bopis-v2-health` dashboard + alerts live

---

## 15. Open Questions & Risks

| # | Question / Risk | Owner | Needed by |
|---|---|---|---|
| Q1 | Reserve-before-auth vs reserve-after-auth ordering | PM + Payments | Discovery end |
| Q2 | Kiosk QR token source (device vs server) | Eng + Security | Discovery end |
| R1 | OMS v3 API slip past Q2 wk 6 | OMS PM | Now (weekly sync) |
| R2 | Inventory accuracy < 99% would undermine promise | Ops | Pre-pilot |

---

## 16. Related Work

- Related PRDs: SFS v3, Order Management Modernization
- Historical incidents: 2024 Black Friday OMS saturation post-mortem — informs peak sizing
- Competitor teardowns: Competitor A real-time inventory (internal link)

---

## 17. Revision History

| Version | Date | Author | Change |
|---|---|---|---|
| v1.0 | 2026-04-23 | Priya R. | Initial PRD from one-pager v1 |

---

*Generated by `retail-prd-creator` v1.0 • Template v1.0*

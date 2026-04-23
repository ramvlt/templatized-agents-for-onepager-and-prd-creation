# BOPIS v2 — Real-time Inventory & 90-min Reservation — One-Pager

> **Owner:** Priya R. &nbsp;•&nbsp; **Sponsor:** VP Omnichannel — Dana K. &nbsp;•&nbsp; **Date:** 2026-04-23 &nbsp;•&nbsp; **Status:** Draft
> **Retail Domain(s):** Ecom, In-Store/POS, Fulfillment, Loyalty
> **Channels Impacted:** Web, iOS, Android, Store-POS, Associate App, Kiosk

---

## 1. Problem / Opportunity

Customers reserve items for in-store pickup, arrive, and the item is out of stock ~9% of the time. This breaks trust and drives ~40k support contacts per month.

**Customer pain:** Arriving to pickup an item that isn't actually there.
**Business cost today:** $14.6M/yr revenue at risk from abandoned BOPIS orders + $1.8M/yr contact-center cost + 11pt NPS drop among pickup users.
**Evidence:**
- BigQuery: `oms.bopis_reservation_fulfillment` Q1 2026 = 91.0%
- VOC survey S-412: 73 verbatim responses citing "item not there"
- Zendesk tag `bopis-oos`: 40,114 tickets last 12 months
- Competitor A launched real-time store inventory in Q4 2025 (teardown link internal)

## 2. Why Now

- Competitor A's real-time inventory launch is converting our BOPIS customers; traffic study shows 6% share loss.
- OMS v3 ships in Q2 with the inventory API we need; if we don't consume it this cycle, platform roadmap reprioritizes.
- Store associate union contract renegotiation in Q4 — training changes must ship before it.

## 3. Proposed Solution

Surface real-time store-level inventory on PDP, cart, and checkout. Reserve picked items for 90 minutes with immediate inventory decrement. Notify store associates via Associate App when a reservation is created and again when the customer arrives. Gracefully degrade to "check availability in-store" when OMS is unreachable so browse is never blocked.

## 4. Target Audience

| Segment | Channel | Volume (annual) | Why they matter |
|---|---|---|---|
| Loyalty Tier-2 + Tier-3 shoppers within 25 mi of a store | Web, iOS, Android | 4.2M shoppers | 54% of BOPIS revenue; highest retention tier |
| Store associates at ~1,200 US stores | Associate App, POS | 22,000 users | Fulfillment quality directly drives customer NPS |
| Fulfillment managers | Ops console | 1,200 users | Load balancing across stores |

**Regions:** US

## 5. Scope

**In scope (V1):**
- Real-time store inventory on PDP, cart, and checkout (web/iOS/Android)
- 90-min reservation with immediate inventory decrement
- Associate App reservation + arrival notification
- Kiosk self-pickup with QR scan
- Loyalty points accrual at pickup completion
- Graceful degradation when OMS unavailable

**Out of scope (explicitly):**
- Same-day delivery orchestration (separate initiative)
- Locker hardware deployment (hardware RFP in flight)
- International rollout (US only in V1)
- Grocery/perishables (different fulfillment physics)

**Deferred (V2+):**
- Curbside pickup UI
- Reservation extension self-service
- Multi-store reservation (split pickup)

## 6. Success Metrics

| Metric | Baseline | Target | Measurement Window | Source of Truth |
|---|---|---|---|---|
| BOPIS fulfillment rate (reserved → picked up) | 91.0% | ≥ 97.5% | 90 days post-GA, steady state | BigQuery `oms.order_events` |
| BOPIS attach rate on PDP sessions within 25 mi of a store | 7.2% | 12.0% | 90 days post-GA | Adobe Analytics + CDP |
| Store fulfillment cycle time (reservation → ready) | 42 min | ≤ 25 min | Steady-state month | OMS `order_events` |

**Guardrail metrics (must NOT regress):**
- PDP p95 load time ≤ 2.2s
- Checkout error rate ≤ 0.8%
- Store NPS (BOPIS segment) ≥ current 47
- Refund rate must not increase > 0.2 pt

## 7. High-Level Rollout & Timeline

| Phase | Window | Scope | Exit criteria |
|---|---|---|---|
| Discovery / Design | 2026-Q2 weeks 1-3 | PRD + arch + Figma + OMS spike | Arch review passed, OMS contract signed off |
| Build | 2026-Q2 weeks 4-12 | MVP code-complete, flag-gated | All P0 ACs automated |
| Pilot | 2026-Q3 weeks 1-4 | 5 pilot stores + 2% web traffic | Guardrails green, pilot fulfillment ≥ 95% |
| GA (ramp) | 2026-Q3 week 5 → Q4 week 4 (10→50→100%) | All stores + 100% web | KPI targets met or trending |
| Hypercare | 2 weeks post-GA completion | Monitoring + hotfix | No P0/P1 open |

**Peak-season freeze awareness:** No launches 2026-11-01 through 2027-01-05. Ramp plan is designed to complete the 50→100% step before Nov 1, with hypercare extending into the freeze in a feature-flag-only monitoring mode.

## 8. High-Level Cost & LOE

| Dimension | Estimate |
|---|---|
| Engineering LOE | L (~3 pod-quarters) |
| 3rd-party / Vendor | $120K/yr (push notification + inventory messaging) |
| Infra / Cloud run-rate | $18K/mo |
| Total CAPEX (yr1) | $2.4M |
| Annual OPEX | $336K |

## 9. Dependencies & Risks

**Dependencies:**
- Platform teams: OMS, Inventory Service, Payments, Loyalty, Associate App, Store IoT, Notifications
- 3rd parties: Push-notification vendor, address/geo verification, receipt email service
- Data: Store master w/ geo-coords, product catalog, live inventory feed

**Top risks:**
| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| OMS v3 inventory API slips past Q2 week 6 | M | H | Weekly sync w/ OMS PM; V1.1 fallback = cache + polling |
| Inventory accuracy < 99% undermines real-time promise | M | H | Data audit + shrinkage compensation + 30s staleness flag |
| Store associate training not ready before pilot | L | M | Training plan locked in discovery; e-learning ships Q2 wk 10 |

## 10. Compliance & Non-Functional Expectations (flag only — details go in PRD)

- **PCI-DSS:** Flag only — no change to payment scope; BOPIS reservation flows do not touch PAN. Tokenization boundary unchanged.
- **Privacy:** Material — new PII collection: pickup-time location signal and device push token. Requires CCPA-CPRA review; 30-day retention for location, consent-gated.
- **Accessibility:** Showstopper — WCAG 2.2 AA across all customer-facing surfaces; Associate App Section 508. Screen-reader verification on PDP inventory module and kiosk QR flow.
- **Performance:** PDP inventory call p95 ≤ 400ms; peak TPS target 12,000 sustained.
- **Availability:** Customer-facing SLO 99.95% (99.99% peak); graceful degradation when OMS unreachable.
- **Localization:** Flag only — US English only in V1.

## 11. Open Questions

1. Do we reserve inventory before payment auth or after? (leaning: reserve → auth → confirm)
2. Kiosk QR token: device-generated or server-generated?

## 12. Approvals

| Role | Name | Decision | Date |
|---|---|---|---|
| Business Sponsor | Dana K. | | |
| Product Lead | Priya R. | | |
| Engineering Lead | | | |
| UX Lead | | | |
| Compliance / Security | | | |

---

*Generated by `retail-onepager-creator` v1.0 (batch mode) • Template v1.0*

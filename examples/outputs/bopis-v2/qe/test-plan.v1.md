# BOPIS v2 — Test Plan v1

> **Source:** PRD v1 • Arch v1 • Stories v1 • **Date:** 2026-05-01
> **Automation target:** 92% of P0 test cases
> **Test case count:** 88 • **Channels covered:** 6 • **NFR strategies:** 12

---

## 1. Strategy at a glance

| Level | Tool | Owner | CI | Gate |
|---|---|---|---|---|
| Unit | JUnit, Vitest | Each pod | PR | ≥ 80% branch |
| Contract | Pact + Spectral | BOPIS + integrators | PR + nightly | 100% producers/consumers |
| Integration | JUnit + Testcontainers, Postman | BOPIS pod | CI | P0 green |
| E2E | Playwright (web, mobile-web), XCUITest/Espresso (native), RobotFW (kiosk) | QE | Nightly stage | P0 green |
| Performance | k6 | SRE + QE | Weekly stage-perf | p95/p99 per NFR |
| Chaos | Toxiproxy, AWS FIS | SRE | Pre-pilot + pre-GA | Graceful degrade validated |
| Accessibility | Axe CI + manual VO/TB/TalkBack | QE + A11y lead | CI + pre-pilot | 0 critical/major |
| Security | SAST (CodeQL), DAST (ZAP), SCA (Snyk), secret scan | Sec | PR + weekly | 0 criticals |
| Localization | Locale matrix smoke | QE | Pre-GA | Smoke green for en-US (v1) |
| UAT | Guided script w/ stakeholders | PM | Pre-GA | Sign-off |

---

## 2. Test case coverage (summary)

| AC | Test cases | Levels |
|---|---|---|
| AC-001 Real-time inventory | TC-0001, TC-0002, TC-0003 (perf), TC-0004 (accessibility), TC-0005 (cross-channel) | int, e2e, perf, a11y |
| AC-002 Reservation + decrement | TC-0010..0015 | unit, int, e2e, contract |
| AC-003 Graceful degradation | TC-0020..0023 (incl. chaos) | chaos, e2e |
| AC-004 Associate notification | TC-0030, 0031 | int, e2e |
| AC-005 Concurrent last-unit | TC-0040, 0041 (concurrency stress) | int |
| AC-006 Loyalty accrual | TC-0050, 0051 | int |
| AC-007 Kiosk QR | TC-0060..0063 | e2e (kiosk) |
| AC-008 Accessibility | TC-0070..0077 | a11y (auto + manual) |
| AC-009 Performance peak | TC-0080 (60-min 12K RPS) | perf |
| AC-010 Reservation expiry | TC-0081, 0082 | int |
| AC-011 Pre-pickup refund | TC-0083, 0084 | int, e2e |
| AC-012 Privacy consent | TC-0085, 0086 | security, e2e |
| AC-013 Partial fulfillment | TC-0087 | e2e |
| AC-014 Observability events | TC-0088 | contract |

**AC → TC coverage: 100%.**

---

## 3. Non-functional strategies

| NFR | Strategy | Tool | Environment | Exit |
|---|---|---|---|---|
| PDP inventory p95 ≤ 400ms | 60-min ramp + soak @ 12K RPS | k6 | stage-perf | p95 ≤ 400ms, err ≤ 0.1% |
| Peak 12K RPS sustained | Same as above | k6 | stage-perf | Same |
| Graceful degradation | OMS-kill chaos + payments-5xx chaos | Toxiproxy + AWS FIS | stage-chaos | Browse unblocked, breaker open < 10s |
| SLO 99.95% | Error-budget burn-rate + synthetic probes | Grafana SLO | prod-canary | Alerting verified |
| Oversell = 0 | 1000 parallel reserves on qty=5 | k6 concurrency harness | stage-perf | Exactly 5 wins |
| PCI SAQ-A | DFD review + PAN-scan test | Manual + log scanner | stage | QSA letter |
| WCAG 2.2 AA | Axe CI + manual VO/TB | Axe + AT devices | CI + device lab | 0 crit/major |
| Section 508 | Manual audit | Human | Device lab | Signed-off |
| Privacy — consent | End-to-end consent path + PII log scan | Manual + scanner | stage | Clean |
| Right-to-erasure | End-to-end erasure within 30 days | Automated | stage | ≤ 30 days |
| Rollback ≤ 15 min | Flag flip drill + migration rollback drill | Manual drill | stage + prod | ≤ 15 min to zero traffic |
| Observability events | Contract tests + dashboard smoke | Pact + manual | prod | All AC-014 events present |

---

## 4. Environments

- **dev:** per-dev, feature-branch
- **CI:** ephemeral Testcontainers + stubbed OMS
- **stage:** full integrations, prod-lookalike
- **stage-perf:** isolated, scaled-up, locked for k6 runs
- **stage-chaos:** isolated, chaos toolkit whitelisted
- **UAT:** stakeholder-visible, stable data
- **prod-canary:** 1% slice, flag-gated

See `environments.v1.md` for data seeds and fixtures.

---

## 5. Risk-based prioritization (excerpt)

| Area | Impact | Complexity | Coverage |
|---|---|---|---|
| Reservation atomic decrement | H | H | Deep (unit + int + concurrency stress + chaos) |
| Inventory cache staleness | H | M | Deep + 1-wk shadow pre-pilot |
| Graceful degradation | H | M | Chaos mandatory |
| Accessibility | H (legal) | L | Deep (auto + manual) |
| Kiosk QR | M | M | Deep (e2e on kiosk hw) |
| Loyalty accrual | M | L | Standard |
| Partial fulfillment | M | M | Standard |

---

## 6. Exit gates by phase

| Phase | Exit criteria |
|---|---|
| PR | Unit ≥ 80%, lint clean, CodeQL clean |
| CI | Contract + integration green, Axe CI clean |
| Pre-stage | Full P0 automated suite green |
| Pre-pilot | Load test green, chaos green, WCAG audit signed, 1-wk shadow report approved |
| Pre-GA | 2× peak load green, regional chaos green, PCI QSA letter, CCPA DPIA, rollback drill, runbook, on-call staffed |
| Post-GA | Synthetic probes green, SLO burn < 1× for 72h |

---

## 7. UAT

Scripted walk-through with Retail Ops + Loyalty PM + Store Manager proxy covering 3 personas × 4 journeys. Sign-off required before GA.

---

## 8. Traceability

See `traceability.v1.md`. Summary: AC→TC 100%, NFR→Strategy 100%, Story→TC 100%, Channel→TC 100%.

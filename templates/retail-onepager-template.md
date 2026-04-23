# {{Initiative Name}} — One-Pager

> **Owner:** {{Product Lead}} &nbsp;•&nbsp; **Sponsor:** {{Business Sponsor}} &nbsp;•&nbsp; **Date:** {{YYYY-MM-DD}} &nbsp;•&nbsp; **Status:** Draft | In Review | Approved
> **Retail Domain(s):** Ecom | In-Store/POS | Loyalty | Fulfillment | Supply Chain | Merchandising | Marketing
> **Channels Impacted:** Web | iOS | Android | Store-POS | Associate App | Kiosk | Contact Center | Email/SMS

---

## 1. Problem / Opportunity (≤ 5 sentences)

<!--
Describe the customer pain, business problem, or market opportunity in plain language.
Anchor to evidence: VOC, NPS, analytics, store-ops reports, competitor move, regulatory change.
Avoid solutions here. Just the "what" and "why it hurts today".
-->

**Customer pain:** {{…}}
**Business cost today:** {{$ revenue at risk / operational cost / NPS drop / churn}}
**Evidence:** {{analytics query, VOC quote, store-ops ticket volume, mystery-shop score}}

## 2. Why Now

<!-- Competitive move, regulatory deadline (PCI 4.0, state privacy laws, accessibility lawsuits), peak-season window, vendor contract renewal, platform EOL. -->

- {{Trigger 1}}
- {{Trigger 2}}

## 3. Proposed Solution (≤ 5 sentences, NO architecture)

<!--
WHAT we will do for the customer/associate, not HOW we will build it.
Name the core capability and the channels it lands in.
-->

{{1-paragraph solution pitch}}

## 4. Target Audience

| Segment | Channel | Volume (annual) | Why they matter |
|---|---|---|---|
| {{e.g., Loyalty Tier-3 shoppers}} | Web, iOS | {{2.4M}} | {{62% of revenue}} |
| {{e.g., Store associates}} | Associate App | {{18K users}} | {{Conversion assist}} |

**Regions:** {{US | CA | EU | APAC | Global}}

## 5. Scope

**In scope (V1):**
- {{Capability 1}}
- {{Capability 2}}

**Out of scope (explicitly):**
- {{Thing we are NOT doing and why}}

**Deferred (V2+):**
- {{Thing}}

## 6. Success Metrics (KPIs with baseline + target)

| Metric | Baseline | Target | Measurement Window | Source of Truth |
|---|---|---|---|---|
| {{Conversion rate (PDP→ATC)}} | {{3.2%}} | {{3.8% (+60bps)}} | {{90 days post-launch}} | {{Adobe Analytics / BigQuery `events.add_to_cart`}} |
| {{Store fulfillment cycle time}} | {{42 min}} | {{≤ 25 min}} | {{Steady-state month}} | {{OMS `order_events`}} |
| {{Loyalty enrollment rate at POS}} | {{11%}} | {{18%}} | {{First 60 days}} | {{CDP `loyalty_signup`}} |

**Guardrail metrics (must NOT regress):** {{cart abandon rate, checkout error rate, store NPS, refund rate}}

## 7. High-Level Rollout & Timeline

| Phase | Window | Scope | Exit criteria |
|---|---|---|---|
| Discovery / Design | {{Q1}} | PRD + Figma + tech spike | Arch review passed |
| Build | {{Q2}} | MVP code-complete | Feature flagged on internal |
| Pilot | {{Q3 weeks 1-4}} | {{5 stores / 2% web traffic}} | Guardrails green, success KPIs trending |
| GA Rollout | {{Q3 week 5+}} | {{All stores / 100% web}} | KPI targets hit or trajectory |
| Hypercare | {{2 weeks post-GA}} | Monitor + patch | No P0/P1 open |

**Peak-season freeze awareness:** {{e.g., no launches Nov 1 – Jan 5}}

## 8. High-Level Cost & LOE

| Dimension | Estimate |
|---|---|
| Engineering LOE | {{T-shirt: S / M / L / XL}} — {{~pod-quarters}} |
| 3rd-party / Vendor | {{$}} |
| Infra / Cloud run-rate | {{$/mo}} |
| Total CAPEX (yr1) | {{$}} |
| Annual OPEX | {{$}} |

## 9. Dependencies & Risks

**Dependencies:**
- Platform teams: {{OMS, CDP, Payments, Loyalty, Search, POS}}
- 3rd parties: {{payment processor, tax service, address verification, fraud}}
- Data: {{product catalog, inventory feed, customer profile}}

**Top risks:**
| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| {{PCI scope expansion}} | {{M}} | {{H}} | {{Tokenize at edge}} |
| {{OMS throughput at peak}} | {{M}} | {{H}} | {{Load-test at 2x peak}} |

## 10. Compliance & Non-Functional Expectations (flag only — details go in PRD)

- **PCI-DSS:** {{in scope? which SAQ? tokenization plan?}}
- **Privacy:** {{GDPR / CCPA-CPRA / state laws — PII handling}}
- **Accessibility:** WCAG 2.2 AA (customer-facing); Section 508 if applicable
- **Performance:** {{peak TPS, p95 latency targets}}
- **Availability:** {{SLO, peak-season 99.99 expectations}}
- **Localization:** {{languages, currencies, tax jurisdictions}}

## 11. Open Questions

1. {{…}}
2. {{…}}

## 12. Approvals

| Role | Name | Decision | Date |
|---|---|---|---|
| Business Sponsor | {{}} | Approve / Reject / Revise | |
| Product Lead | {{}} | | |
| Engineering Lead | {{}} | | |
| UX Lead | {{}} | | |
| Compliance / Security | {{}} | | |

---

*Template version: 1.0 — omnichannel retail, enterprise rigor*

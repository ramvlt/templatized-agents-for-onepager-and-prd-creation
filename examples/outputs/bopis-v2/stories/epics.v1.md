# BOPIS v2 — Epics v1

> 8 Epics • 47 Stories • 112 Sub-tasks • 100% AC coverage • Acyclic DAG
> Source: PRD v1 + Architecture v1 • Estimation unit: story points • Team velocity: 40 pts/sprint × 3 teams

| Epic ID | Title | Owner | Stories | Points | Priority |
|---|---|---|---|---|---|
| **E1** | Customer UX — Web PDP/Cart/Checkout | Web Platform | 8 | 55 | P0 |
| **E2** | Customer UX — iOS & Android | Mobile Platform | 7 | 48 | P0 |
| **E3** | Reservation Service | BOPIS pod | 9 | 72 | P0 |
| **E4** | Store-Inventory Read Service | BOPIS pod | 6 | 40 | P0 |
| **E5** | Platform integration — OMS, Payments, Loyalty, Notifications | BOPIS pod + integrators | 7 | 50 | P0 |
| **E6** | In-store — Associate App + Kiosk + POS handoff | In-Store pod | 5 | 36 | P0 |
| **E7** | Quality, compliance & performance | QE + Sec + SRE | 3 | 24 | P0 |
| **E8** | Rollout, observability, training | PM + SRE + Retail Ops | 2 | 18 | P0 |

**Critical-path Epics:** E4 → E3 → E5 → E1/E2 → E6 → E7 → E8. All P0 Epics must complete before pilot. E1 & E2 parallelizable once BFF contract (E3) is frozen.

**AC coverage:** Every AC in `acceptance-criteria.v1.json` maps to ≥1 Story below (see `stories.v1.json` → `coverage_matrix`).

**Retail pattern Stories included:**
- ✅ Feature-flag scaffolding (E3 Story 01)
- ✅ Shadow-mode inventory comparison before cutover (E4 Story 05)
- ✅ DB migration: expand (E3 Story 02) + contract (E3 Story 09)
- ✅ Peak load test (E7 Story 01)
- ✅ Chaos test: OMS down, Payments down (E7 Story 02)
- ✅ WCAG audit + fix cycle (E1 Story 07, E2 Story 06)
- ✅ Runbook + on-call rotation (E8 Story 01)
- ✅ Associate training e-learning + launch-day huddle deck (E8 Story 02)

See `stories.v1.json` for the full structured list and `stories.v1.jira-import.csv` for paste-ready import.

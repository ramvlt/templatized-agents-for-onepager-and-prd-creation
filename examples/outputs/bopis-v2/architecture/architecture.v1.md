# BOPIS v2 — Architecture Design v1

> **Source PRD:** `../prd.v1.md` (PASS_WITH_MINOR verdict)
> **Author:** Arch team &nbsp;•&nbsp; **Date:** 2026-04-24 &nbsp;•&nbsp; **Status:** Draft for review

---

## 1. Scope & assumptions

**Scope:** Real-time store inventory on PDP/cart/checkout; 90-min reservation with immediate decrement; Associate App notifications; Kiosk QR pickup; loyalty accrual at completion; graceful degradation when OMS unreachable.
**Platform baseline:** AWS us-east-1 primary, us-west-2 warm-standby (RPO 5 min, RTO 30 min). Java/Spring-Boot golden path; org eventing = Kafka; org observability = OTel → Grafana/Loki/Tempo; org feature flags = LaunchDarkly.

---

## 2. Component diagram

See `architecture.v1.components.mmd`.

**Components (owners):**

| Component | Owner | Build / Buy | Responsibility | State |
|---|---|---|---|---|
| Web BFF (existing) | Web Platform | Build | Thin aggregator for web PDP/cart flows | Stateless |
| Mobile BFF (existing) | Mobile Platform | Build | Thin aggregator for iOS/Android | Stateless |
| **Reservation Service** (new) | BOPIS pod | Build | 90-min hold, atomic decrement, expiry orchestration | OLTP (Postgres) + Redis for hot reservations |
| **Store-Inventory Read Service** (new) | BOPIS pod | Build | Read-through cache fronting OMS inventory API; staleness flagging | Redis (30s TTL) + in-process LRU |
| Associate Notification Adapter (new) | BOPIS pod | Build | Publishes `reservation.created`/`arrived`/`expired` to Notifications platform | Stateless |
| Kiosk QR Verifier (new) | BOPIS pod | Build | Verifies QR, emits `pickup.arrived` | Stateless |
| POS Handoff Adapter (new) | BOPIS pod | Build | Receives `order.picked_up` from POS, emits loyalty accrual | Stateless |
| OMS Inventory API (existing) | OMS team | Reuse | Source of truth inventory | — |
| OMS Order API (existing) | OMS team | Reuse | Reservation persistence mirror; fulfillment state | — |
| Payments Vault (existing) | Payments | Reuse | Tokenization; no PAN in our code path | — |
| Loyalty Platform (existing) | Loyalty team | Reuse | Point accrual | — |
| Notifications Platform (existing) | Notifications | Reuse | Push / email fan-out | — |
| Feature Flags (existing) | Platform | Reuse | LaunchDarkly | — |
| Observability (existing) | SRE | Reuse | OTel pipeline | — |

**New-vs-reuse ratio:** 6 new services + 7 reuse platforms — reuse-first design.

---

## 3. Sequence diagrams

See `architecture.v1.sequences.mmd`. Includes:
1. **PDP inventory read (happy)** — BFF → Store-Inventory Read Svc → cache (hit) → respond in ~80ms p95; cache miss → OMS + populate, ≤ 400ms p95.
2. **Reservation (happy)** — BFF → Reservation Svc: atomic Redis check + Postgres upsert in a tx; async `reservation.created` → Associate App; confirmation email via Notifications.
3. **Concurrent last-unit reservation** — Two BFF requests → Reservation Svc → Redis WATCH/MULTI (or Postgres row-lock fallback) → one succeeds, one gets 409 + alternates.
4. **Graceful degradation (OMS down)** — Store-Inventory Read Svc → circuit breaker opens on 3 consecutive 5xx or > 800ms p95 for 10s → returns sentinel "unknown, check-in-store"; BFF renders fallback UI; reservation writes paused; degraded state broadcast via feature-flag.

---

## 4. Deployment topology

See `architecture.v1.deployment.mmd`.

- **Compute:** EKS (Reservation Svc, Store-Inventory Read Svc, adapters). Min-3 replicas per AZ. HPA on CPU + custom RPS metric.
- **Datastores:** Aurora Postgres (reservations, multi-AZ). ElastiCache Redis cluster (reservations hot-state + inventory cache, multi-AZ). Cross-region replicas in us-west-2 for warm standby (RPO 5 min).
- **Networking:** Private VPC; internal-only for Reservation Svc & Inventory Read Svc; egress through API gateway for OMS calls.
- **CDN/Edge:** CloudFront already fronts PDP; no change.
- **Scaling for peak:** Pre-warm 2× replicas starting T-2h on forecasted peak days. Cache warming job seeds top-10k SKUs hourly.
- **Multi-region posture:** Active-passive. us-east-1 primary; us-west-2 capable of failover within RTO 30 min. Data: aurora global database + Redis cross-region replication.

---

## 5. Data model sketch

See `data-model.v1.md`. Key entities:
- **Reservation** (PII-linked; customer_hash, not raw) — id, sku, store_id, qty, status, created_at, expires_at, cancelled_at, completed_at. Retention 13 months active + 25 months cold.
- **InventoryCacheEntry** (public) — store_id, sku, qty, fetched_at, staleness_ms.
- **PickupEvent** (PII-linked) — reservation_id, event_type (arrived/completed/cancelled/expired), ts, associate_id, channel.

**Consistency:** Reservation is strong consistency (Aurora). Inventory cache is bounded staleness (≤ 30s). Events are at-least-once + idempotent consumers.

**Partition key:** Reservation by `store_id` (co-locates store reads/writes). Inventory cache by `store_id:sku`.

**Classification:** No PCI data in this service. PII: customer_hash only (SHA-256 of customer_id + rotating salt; reversible only via Identity service with consent).

---

## 6. Integration contracts

See `integration-contracts.v1.json`. Summary:

| Integration | Style | Contract | Idempotency | Error model |
|---|---|---|---|---|
| BFF ↔ Store-Inventory Read Svc | REST | OpenAPI v1 | GET idempotent by (store, sku) | Fallback sentinel on upstream fail |
| BFF ↔ Reservation Svc | REST | OpenAPI v1 | Idempotency-Key header required on POST | 4xx for client, 5xx retried at BFF w/ exponential backoff |
| Store-Inventory Read Svc ↔ OMS Inventory API | REST | OMS v3 OpenAPI | GET idempotent | Circuit breaker; 800ms timeout; 3-strike open 10s |
| Reservation Svc ↔ OMS Order API | REST | OMS v3 OpenAPI | Idempotency by reservation_id | Saga with compensating release on mirror-failure |
| Reservation Svc → Kafka `reservation.events` | Event | AsyncAPI v1 | Idempotent key = reservation_id + event_type + version | At-least-once; consumer de-dup window 24h |
| POS Handoff Adapter ↔ POS bridge | REST (inbound) | Internal | Idempotency by pickup_id | 202 + async processing |
| Loyalty Platform ← Accrual Adapter | Event | Loyalty AsyncAPI | Idempotency by pickup_id | DLQ + alert after 3 fails |
| Notifications Platform ← Associate Adapter | Event | Notifications AsyncAPI | Idempotency by (reservation_id, event_type) | Best-effort; no retry on customer-side notification |

**Versioning:** SemVer on OpenAPI/AsyncAPI; BFF pins minor versions; consumers handle additive backward-compat without redeploy.

---

## 7. NFR → mechanism map

See `nfr-mechanism-map.v1.md`. Every PRD NFR mapped. Coverage = 100%. Sample:

| PRD NFR | Target | Mechanism | Validation |
|---|---|---|---|
| PDP inventory call p95 | ≤ 400ms | Read-through Redis cache (30s TTL) + request coalescing at BFF; OMS circuit-broken at 800ms | Synthetic + RUM + load test |
| Peak RPS | 12K sustained | EKS HPA (CPU + RPS), warm-pool pre-scale, Redis pipelining, cache hit ≥ 95% | Load test 60 min @ 12K |
| SLO customer-facing | 99.95% (99.99% peak) | Multi-AZ; circuit breakers; graceful degradation; warm us-west-2 | Error-budget burn-rate alert |
| Graceful degradation | Browse never blocked | Circuit-breaker + static fallback + flag-gated write-pause | Chaos test (kill OMS) |
| PCI SAQ-A maintained | SAQ-A | Never handle PAN; redirect to Vault for tokenize; verified DFD | QSA review |
| WCAG 2.2 AA | 100% critical flows | Design system components; Axe in CI; ARIA on inventory live-region | Axe CI + manual AT |
| Privacy — location | Consent-gated, 30d retention | Consent service gate; TTL job; scope-limited column | Compliance test |
| Oversell = 0 | 0 oversells | Redis WATCH/MULTI w/ Postgres row-lock fallback; audit on divergence | Concurrency load test @ 100 parallel |
| Rollback ≤ 15 min | 15 min | LaunchDarkly kill-switch + schema-backward-compat DB migrations | Runbook drill |
| Observability | Events per AC-014 | Kafka `reservation.events`; OTel trace IDs; `bopis-v2-health` dashboard | Contract tests on events |

---

## 8. Tactical ADRs

See `adrs/`. Six ADRs in v1:

| ID | Title | Status |
|---|---|---|
| ADR-001 | Inventory read-path: read-through cache w/ 30s staleness | Accepted |
| ADR-002 | Reservation store: Aurora Postgres + Redis hot-state | Accepted |
| ADR-003 | Payment scope: tokenize-at-edge; SAQ-A preserved | Accepted |
| ADR-004 | Event backbone: Kafka (reuse org standard) | Accepted |
| ADR-005 | Concurrency: Redis WATCH/MULTI with Postgres fallback | Accepted |
| ADR-006 | Multi-region posture: active-passive us-east-1 → us-west-2 | Accepted |

---

## 9. Cost & capacity

- **EKS:** ~18 pods steady, 60 at peak. ~$3,200/mo.
- **Aurora Postgres:** db.r6g.xlarge primary + replica. ~$1,400/mo.
- **Redis cluster:** cache.r6g.large × 3 shards. ~$900/mo.
- **Kafka topic usage:** within existing org allocation — $0 incremental.
- **Egress + misc:** ~$400/mo.
- **Total infra run-rate:** ~$5,900/mo. Within PRD estimate of $18K/mo (includes vendor uplift and HQ infra allocation) — variance explainable.

Capacity sized for **2× forecasted peak** per NFR; Black-Friday posture pre-scales 3×.

---

## 10. Risks & open questions

| # | Risk / Question | Likelihood | Impact | Mitigation / Next step |
|---|---|---|---|---|
| R1 | OMS inventory accuracy < 99% could undermine cache strategy | M | H | Shadow-compare week 1; 30s TTL + staleness flag; ADR revisit |
| R2 | Cross-region replication lag during failover | L | H | Failover drill in hypercare; documented RPO = 5 min |
| Q1 | Should we use Aurora Global or DMS-based replication? | — | — | Defer to infra team; ADR pending |
| Q2 | Consent signal propagation latency — real-time or near-real-time? | — | — | Align with Privacy team |

---

## 11. Traceability

- Every capability in PRD §5 → component in §2 ✅
- Every PRD NFR → mechanism in §7 ✅ (100%)
- Every ADR → PRD req cited in decision drivers ✅

---

*Generated by `retail-arch-designer` v1.0 (interactive mode) • Status: Ready for `retail-arch-reviewer`*

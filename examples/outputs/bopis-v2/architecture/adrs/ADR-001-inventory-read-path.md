# ADR-001 — Inventory read-path: read-through cache with 30s staleness window

**Status:** Accepted &nbsp;•&nbsp; **Date:** 2026-04-24 &nbsp;•&nbsp; **Deciders:** BOPIS pod, OMS team, SRE
**PRD drivers:** NFR perf p95 ≤ 400ms, NFR peak 12K RPS, BR-05 (staleness ≤ 30s), G1 (reduce OOS surprise), AC-001

## Context

PDP surfaces "qty available at {store}". Underlying source of truth is OMS Inventory API with current p95 ≈ 650ms under normal load and spikes to 2–3s under peak. The PRD requires p95 ≤ 400ms at 12K RPS while BR-05 mandates displayed staleness ≤ 30s (so true real-time is not required — bounded staleness is acceptable).

## Decision drivers

- Performance NFR p95 ≤ 400ms is not achievable by proxying OMS directly.
- Peak 12K RPS would saturate OMS (current capacity ~2K RPS) unless we absorb 85%+ via cache.
- BR-05 allows up to 30s staleness — gives us a TTL budget.
- Inventory accuracy must still be ≥ 99% at the shelf (ops concern beyond cache TTL).
- Graceful degradation is a hard requirement when OMS is unreachable.

## Options considered

### Option A — Proxy directly to OMS (no cache)

- **Pros:** Simplest; always fresh.
- **Cons:** Violates p95 NFR (650ms); cannot sustain 12K RPS; couples our availability to OMS's.

### Option B — Async hydrated store (OMS → Kafka → our store)

- **Pros:** Decouples read path; resilient to OMS outage for reads.
- **Cons:** Requires OMS event emission (not available in v3 contract); staleness harder to bound at 30s; operational complexity higher; duplicates source of truth.

### Option C — Read-through cache with 30s TTL + request coalescing ✅

- **Pros:** Meets p95 easily (cache hits ~80ms); natural peak absorption (≥ 95% hit ratio target); TTL bounds staleness to BR-05 limit; circuit breaker cleanly wraps OMS calls for graceful degradation; minimal new operational surface.
- **Cons:** Cache miss p95 still tied to OMS; brief windows where inventory shown differs from shelf by up to 30s (within BR-05); cache warming required for top SKUs.

### Option D — Hybrid (short TTL + push-based invalidation via OMS events)

- **Pros:** Best freshness/performance trade-off.
- **Cons:** OMS events not yet available; adds coupling & complexity; defer until platform supports it.

## Decision

**Option C — Read-through cache with 30s TTL + request coalescing at BFF.**

- Redis ElastiCache, 3-shard cluster, multi-AZ.
- 30s TTL per `(store_id, sku)` key.
- Single-flight coalescing at BFF: concurrent misses for the same key issue one OMS call.
- Response includes `staleness_ms` so downstream UX can hint (e.g., "as of 12s ago").
- Circuit breaker on OMS: 800ms timeout, 3-strike open for 10s → fallback sentinel response.
- Hourly warm job seeds top-10k SKUs × top-100 stores before open-hours.

## Consequences

### Positive
- Meets p95, peak RPS, and staleness NFRs in a single mechanism.
- Graceful degradation is natural (breaker-open → fallback UI).
- Low operational new surface; Redis is an org standard.

### Negative
- Adds a cache layer to reason about during incidents.
- Staleness window (≤ 30s) means rare edge cases of "just sold last one" — partially addressed by atomic reservation decrement (ADR-005).

### Neutral
- If OMS later emits events, we can migrate to Option D as an additive evolution without changing the read contract.

## Revisit triggers

- Inventory accuracy < 99% at shelf after launch → revisit TTL or move toward Option D.
- OMS v4 ships with event support → evaluate D.
- Peak forecast exceeds 20K RPS → revisit cache sharding.

# ADR-003 — Payment tokenization: edge-only; SAQ-A scope preserved

**Status:** Accepted &nbsp;•&nbsp; **Date:** 2026-04-25 &nbsp;•&nbsp; **Deciders:** Payments team, Security, BOPIS pod, PCI QSA (advisory)
**PRD drivers:** NFR Security/PCI (SAQ-A target), AC-011 (refund flow), BR-07 (auth void/refund ≤ 10s)
**Retail domain impact:** ecom (web/ios/android checkout), in-store (POS — unchanged), fulfillment
**Compliance implications:** PCI-DSS 4.0 scope target, refund audit trail, tax compliance unchanged

## Context

BOPIS v2 adds reservation + pickup flows that may require payment authorization at reservation time and capture at pickup (per Q1 open question). We do not want to expand PCI scope. Today we are SAQ-A (fully outsourced: our code never touches PAN; iframes and redirects to the Payments Vault handle all cardholder data). Any new handling that causes PAN to pass through our infrastructure would upgrade us to SAQ-A-EP or SAQ-D, with material cost and ongoing audit burden.

## Problem statement

Where and how do we tokenize/authorize card data during the BOPIS reservation flow without changing PCI scope?

## Decision drivers

- NFR: PCI scope must remain **SAQ-A** after BOPIS v2 GA.
- BR-07: payment auth must be void/refunded within 10 seconds on cancel.
- AC-011: refund path works for pre-pickup cancellations across web, iOS, Android, and Associate App.
- Developer experience: minimize SDK complexity per channel.
- Operational: existing Vault ownership and runbooks remain with Payments team.

## Considered options

### Option A — Tokenize at the edge (Vault iframe/redirect) ✅

- **Description:** Customer card data is entered directly into a Vault-hosted iframe (web) or Vault SDK-managed view (iOS/Android). Our app only ever sees an opaque token. Token → auth/capture via server-to-server Vault API.
- **Pros:**
  - SAQ-A preserved: our services never see PAN.
  - Lowest ongoing compliance cost.
  - Mature Vault iframe/SDK; reuses existing checkout surface with minor extension.
  - Refund flow (AC-011) already supported via Vault API; our code only needs token + idempotency key.
- **Cons:**
  - Slight UX compromise: iframe styling constraints.
  - SDK version management across mobile channels.
  - Cannot capture device fingerprinting at checkout without a separate SDK.
- **Retail implications:**
  - In-store POS path unchanged; no new PCI exposure in physical stores.
  - Peak behavior unchanged: Vault already sized for BF traffic.

### Option B — Handle PAN in our BFF (tokenize server-side)

- **Description:** Customer card data posts to our BFF; BFF forwards to Vault for tokenization and auth.
- **Pros:**
  - Full UX control; any styling, any validation.
  - Richer telemetry possible (careful with PAN).
- **Cons:**
  - **PCI scope expands to SAQ-D.** Network segmentation, quarterly ASV scans, annual pen-test, staff training, vendor management — material cost and delay.
  - Any accidental log of PAN is a reportable incident.
  - Rebuilds what Vault already provides.
- **Retail implications:**
  - Store systems potentially swept into broader scope.
  - Cost forecast adds ~$400K/yr audit + tooling.

### Option C — Hybrid: iframe for web, native field for mobile

- **Description:** Web uses Vault iframe; mobile captures in our own view and posts to Vault.
- **Pros:**
  - Native-feeling mobile UX.
- **Cons:**
  - Mobile path alone triggers SAQ-A-EP at minimum (app handling data in transit even briefly).
  - Mixed scope hard to audit.
  - Two code paths to maintain.
- **Retail implications:**
  - Opens argument about whether kiosk QR entry could handle PAN someday (it should not).

## Decision

**Option A — Tokenize at the edge using the Vault iframe (web) and Vault SDK (iOS/Android). SAQ-A preserved.**

- Auth at reservation confirmation (optional per Q1, leaning toward `reserve → auth → confirm`).
- Capture at pickup via POS handoff (existing flow, token-based).
- Refund / void via Vault API with idempotency key = `reservation_id:operation`.
- No PAN ever reaches our application logs, databases, or tracing pipelines.

## Consequences

### Positive
- PCI scope unchanged; no audit uplift; no launch delay for compliance.
- Refund SLO (BR-07) achievable using existing Vault APIs.
- One tokenization pattern across all customer-facing channels (consistent audit posture).

### Negative
- Web UX has iframe styling limits; requires design-system adaptation.
- Mobile SDK version management overhead.
- We cannot directly store any card detail (BIN info only via Vault).

### Neutral
- In-store PCI posture unchanged; POS already segmented.
- Future card-on-file experiences continue to use Vault token vault.

### Reversibility
**Hard.** Moving away from edge tokenization would re-expand PCI scope and require 6–9 months for SAQ upgrade and network re-segmentation.

## Validation / Revisit triggers

- Annual PCI review cycle (next: Q1 2027).
- Introduction of any payment method requiring device-level data we cannot pass through Vault (e.g., a new in-app wallet without Vault support).
- Any Vault downtime pattern that threatens our availability SLO — would revisit redundancy, not tokenization location.

## References

- PRD: `../prd.v1.md` §11 NFR table (Security / PCI row); AC-011; BR-07
- Related ADRs: ADR-001 (inventory read-path), ADR-005 (concurrency)
- External: PCI-DSS 4.0 SAQ-A definition; Vault integration guide (internal)

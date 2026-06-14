# 1. Record architecture decisions

Date: 2026-06-14

## Status

Accepted

## Context

We need to track the architectural decisions that shape `lsm` over time. The
project is positioned as a long-lived community tool, which means future
contributors and maintainers will inherit choices whose context will not be
obvious from the code alone.

## Decision

We will use Architecture Decision Records (ADRs), as described by Michael
Nygard in
[*Documenting architecture decisions*](https://cognitect.com/blog/2011/11/15/documenting-architecture-decisions).

ADRs live in `docs/adr/` and are named `NNNN-<slug>.md`, where `NNNN` is a
zero-padded sequence number. The first ADR is this one.

## Consequences

- Every architectural decision is recorded as a small markdown file that
  explains the context, the decision, and the consequences.
- Pull requests that introduce architectural changes must include the
  corresponding ADR.
- Superseded ADRs are not deleted. They are marked `Superseded by NNNN` and
  remain in the repository for historical context.

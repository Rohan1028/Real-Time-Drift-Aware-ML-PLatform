# Contributing Guide

1. Fork and create feature branches from `main`.
2. Install tooling via `make bootstrap`.
3. Run `make lint test` (subset of `make smoke`) before pushing.
4. Submit PRs with context and dashboard screenshots when relevant.
5. For docs-only changes, add `[skip ci]` in the commit subject.

This repo uses conventional commits, pre-commit hooks, and Poetry. No secrets should ever be committed.

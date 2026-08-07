# HSMC 2026 A Q1 — MATLAB V0 Data Audit

Environment: MATLAB R2016a (9.0), Windows.

From the project root, run:

```matlab
setup_project
run('scripts/run_data_audit.m')
```

The script reads `data/attachment.xlsx` without modifying it, validates the
expected 12/49/535 record counts, and writes geometry, direction-family,
boundary-contact, periodic-pairing-candidate, summary, and length-distribution
diagnostics to `output/`.

Only V0 Data Audit is implemented. Pairing rows are diagnostic candidates and
are not merged into physical media. A candidate translation is applied to
Record B's endpoint to overlap Record A's endpoint. V1 and later stages are not
implemented.

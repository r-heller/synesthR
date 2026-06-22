"""Optional Python enrichment helpers for synesthR.

Invoked (not imported at build) by R/python.R via reticulate::source_python().
Uses only light, well-behaved modules (numpy). These ENRICH a prosody score in
a clearly separated slot; they never replace the deterministic core features.
"""


def valence_dynamics(values):
    """Return gradient and cumulative trajectory of a valence series."""
    import numpy as np

    a = np.array(values, dtype=float)
    if a.size == 0:
        return {"gradient": [], "cumulative": []}
    grad = np.gradient(a) if a.size > 1 else np.zeros_like(a)
    return {"gradient": grad.tolist(), "cumulative": np.cumsum(a).tolist()}

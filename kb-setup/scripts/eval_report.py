#!/usr/bin/env python3
"""Aggregate a kb-setup token/time/quality eval into a Markdown report (stdlib only).

Inputs in --dir:
  runs.jsonl          one line per answering subagent: run, config, question, type, tokens, duration_ms, tool_uses
  grades.json         list: run, config, question, accuracy (0-2), citation (0-2), hallucination (bool), note
  volume_subset.json  output of `kb.py volume --json` (or filtered) for the evaluated subset
  volume_all.json     output of `kb.py volume --json` for the whole workspace (optional, for projection)
  build_costs.jsonl   optional: kind, config (kb|graphify|both|eval), tokens (null = not logged), duration_ms, scope
  overhead.jsonl      optional: one line per trivial subagent ("reply ok", no tools): tokens, duration_ms
                      → fixed cost of an answering subagent; enables "context added" and the inline-KB estimate
Usage: uv run eval_report.py --dir <eval dir> --out kb/evals/<date>/report.md
"""
from __future__ import annotations

import argparse
import json
import statistics as st
from collections import defaultdict
from pathlib import Path

CONFIGS = ["baseline", "graphify", "kb", "kb-inline"]
NAMES = {"baseline": "no KB / no graphify", "graphify": "graphify only", "kb": "KB + graphify",
         "kb-inline": "KB in the main context (no subagent)"}
NO_SUBAGENT = {"kb-inline"}  # tokens = context added (measured from command outputs + answer), no subagent overhead


def load_jsonl(p: Path) -> list[dict]:
    if not p.exists():
        return []
    return [json.loads(line) for line in p.read_text(encoding="utf-8").splitlines() if line.strip()]


def ms(values: list[float]) -> str:
    if not values:
        return "-"
    m = st.mean(values)
    sd = st.stdev(values) if len(values) > 1 else 0.0
    return f"{m:,.0f} ± {sd:,.0f}"


def totals(vol: dict) -> dict:
    return (vol or {}).get("totals", {}) if isinstance(vol, dict) else {}


def paired_saving(base_rs: list[dict], rs: list[dict]) -> tuple[float, float, int] | None:
    """Mean per-question saving (baseline − config) paired by (run, question), its standard error and n."""
    b = {(r["run"], r["question"]): r["tokens"] for r in base_rs}
    diffs = [b[(r["run"], r["question"])] - r["tokens"] for r in rs if (r["run"], r["question"]) in b]
    if len(diffs) < 3:
        return None
    return st.mean(diffs), st.stdev(diffs) / len(diffs) ** 0.5, len(diffs)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--dir", required=True)
    ap.add_argument("--out", required=True)
    a = ap.parse_args()
    d = Path(a.dir)
    runs = load_jsonl(d / "runs.jsonl")
    grades = json.loads((d / "grades.json").read_text(encoding="utf-8")) if (d / "grades.json").exists() else []
    vol_sub = json.loads((d / "volume_subset.json").read_text(encoding="utf-8")) if (d / "volume_subset.json").exists() else {}
    vol_all = json.loads((d / "volume_all.json").read_text(encoding="utf-8")) if (d / "volume_all.json").exists() else {}
    builds = load_jsonl(d / "build_costs.jsonl")
    ovh_rs = load_jsonl(d / "overhead.jsonl")
    overhead_measured = st.mean(r["tokens"] for r in ovh_rs) if ovh_rs else None

    by_cfg = defaultdict(list)
    by_cfg_type = defaultdict(lambda: defaultdict(list))
    per_q = defaultdict(lambda: defaultdict(list))
    for r in runs:
        by_cfg[r["config"]].append(r)
        by_cfg_type[r["config"]][r.get("type", "?")].append(r)
        per_q[r["question"]][r["config"]].append(r)
    g_cfg = defaultdict(list)
    g_type = defaultdict(lambda: defaultdict(list))
    qtype = {r["question"]: r.get("type", "?") for r in runs}
    for g in grades:
        g_cfg[g["config"]].append(g)
        g_type[g["config"]][qtype.get(g["question"], "?")].append(g)

    ts, ta = totals(vol_sub), totals(vol_all)
    words_sub = ts.get("words") or 0
    lines = ["# Eval report — tokens, time and quality", ""]
    lines += ["## Data volume", "",
              "| scope | files | MB | pages | words | est. tokens of text |", "|---|---|---|---|---|---|"]
    for name, t in (("evaluated subset", ts), ("whole workspace", ta)):
        if t:
            lines.append(f"| {name} | {t.get('files', 0)} | {t.get('bytes', 0) / 1e6:.1f} | {t.get('pages', 0)} | "
                         f"{t.get('words', 0):,} | {t.get('est_tokens', 0):,} |")
    n_runs = len({r["run"] for r in runs}) or 1
    spread = "sd over runs × questions" if n_runs > 1 else "spread across questions (1 run)"
    added_hdr = " context added/question |" if overhead_measured else ""
    lines += ["", f"## Per question (mean ± {spread})", "",
              "| configuration | tokens/question |" + added_hdr + " seconds/question | tool calls/question | "
              "tokens per 1k words of subset | accuracy | citation | hallucinations |",
              "|---|---|" + ("---|" if overhead_measured else "") + "---|---|---|---|---|---|"]
    summary = {}
    for c in CONFIGS:
        rs = by_cfg.get(c, [])
        if not rs:
            continue
        tok = [r["tokens"] for r in rs]
        sec = [r["duration_ms"] / 1000 for r in rs]
        calls = [r.get("tool_uses", 0) for r in rs]
        gs = g_cfg.get(c, [])
        acc = sum(g["accuracy"] for g in gs)
        cit = sum(g["citation"] for g in gs)
        hal = sum(1 for g in gs if g.get("hallucination"))
        maxp = 2 * len(gs) or 1
        per1k = f"{st.mean(tok) / (words_sub / 1000):,.0f}" if words_sub else "-"
        added = (f" {ms(tok if c in NO_SUBAGENT else [t - overhead_measured for t in tok])} |"
                 if overhead_measured else "")
        lines.append(f"| {NAMES[c]} | {ms(tok)} |{added} {ms(sec)} | {ms(calls)} | {per1k} | {acc}/{maxp} ({acc / maxp:.0%}) | "
                     f"{cit}/{maxp} ({cit / maxp:.0%}) | {hal} |")
        summary[c] = {"tokens_mean": st.mean(tok), "seconds_mean": st.mean(sec), "calls_mean": st.mean(calls),
                      "accuracy": acc / maxp, "citation": cit / maxp, "hallucinations": hal, "n": len(rs)}

    lines += ["", "## By question type (mean tokens · accuracy)", ""]
    types = sorted({t for c in by_cfg_type for t in by_cfg_type[c]})
    lines += ["| type | " + " | ".join(NAMES[c] for c in CONFIGS if c in by_cfg) + " |",
              "|---|" + "---|" * len([c for c in CONFIGS if c in by_cfg])]
    for t in types:
        cells = []
        for c in CONFIGS:
            if c not in by_cfg:
                continue
            rs = by_cfg_type[c].get(t, [])
            gs = g_type[c].get(t, [])
            acc = (sum(g["accuracy"] for g in gs) / (2 * len(gs))) if gs else None
            cells.append(f"{st.mean([r['tokens'] for r in rs]):,.0f} · {acc:.0%}" if rs and acc is not None else
                         (f"{st.mean([r['tokens'] for r in rs]):,.0f}" if rs else "-"))
        lines.append(f"| {t} | " + " | ".join(cells) + " |")

    lines += ["", "## Questions with high variance (sd > 50% of mean tokens)", ""]
    flagged = []
    for q, cfgs in sorted(per_q.items()):
        for c, rs in cfgs.items():
            tok = [r["tokens"] for r in rs]
            if len(tok) > 1 and st.mean(tok) and st.stdev(tok) / st.mean(tok) > 0.5:
                flagged.append(f"- {q} ({NAMES.get(c, c)}): {ms(tok)} tokens")
    lines += flagged or ["- none"]

    if overhead_measured:
        lines += ["", f"_Context added = tokens − fixed cost of an answering subagent (measured: {overhead_measured:,.0f} "
                      f"tokens, {len(ovh_rs)} trivial subagents). It is what the configuration puts into a context._"]

    lines += ["", "## Build cost and break-even", ""]
    bc = defaultdict(lambda: {"tokens": 0, "ms": 0, "unknown": []})
    for b in builds:
        if b.get("config") == "eval":
            continue  # answer key / grader: eval overhead, not build cost
        for c in (["kb", "graphify"] if b.get("config") == "both" else [b.get("config", "kb")]):
            if b.get("tokens") is None:
                bc[c]["unknown"].append(b.get("kind", "?"))
            else:
                bc[c]["tokens"] += b["tokens"]
                bc[c]["ms"] += b.get("duration_ms") or 0
    if not builds:
        lines.append("- build costs not recorded (log them with `kb.py log-cost` when building).")
    base = summary.get("baseline", {}).get("tokens_mean")
    for c in ("graphify", "kb", "kb-inline"):
        if c not in summary:
            continue
        src = "kb" if c == "kb-inline" else c  # the inline KB reuses the KB build
        if src not in bc:
            lines.append(f"- {NAMES[c]}: build cost not recorded.")
            continue
        unk = bc[src]["unknown"]
        prefix = "≥ " if unk else "≈ "
        line = f"- {NAMES[c]}: build {prefix}{bc[src]['tokens']:,} tokens, {bc[src]['ms'] / 60000:.1f} min"
        if unk:
            line += f" (not logged: {', '.join(unk)})"
        ps = paired_saving(by_cfg.get("baseline", []), by_cfg[c]) if base else None
        if ps:
            mean_s, se, n = ps
            if mean_s > 2 * se and mean_s > 0:
                line += f"; saves {mean_s:,.0f} ± {se:,.0f} tokens/question (paired, n={n})"
                line += (f"; break-even after ≈ {bc[src]['tokens'] / mean_s:,.0f} questions" if not unk else
                         "; break-even unknown (build cost incomplete)")
            elif mean_s < -2 * se:
                line += f"; costs {-mean_s:,.0f} ± {se:,.0f} more tokens/question than baseline (no break-even)"
            else:
                line += (f"; no significant per-question difference vs. baseline ({mean_s:+,.0f} ± {se:,.0f}, "
                         f"paired, n={n}) — no break-even in subagents")
        scopes = {b.get("scope", "?") for b in builds if b.get("config") in (src, "both")}
        if len(scopes) > 1 or "?" in scopes:
            line += f" (scopes: {', '.join(sorted(scopes))} — compare only builds over the same scope)"
        lines.append(line)

    if base and "kb-inline" in summary:
        inl = summary["kb-inline"]["tokens_mean"]
        lines += ["", "## KB queried in the main context (measured)", "",
                  "Under the rule *documents only in subagents*, the baseline must always pay an answering subagent; "
                  "the compact output of `KB ask/show/query/page-text` may be read in the main context.",
                  f"- KB inline ≈ {inl:,.0f} tokens/question (context added: command outputs + answer) vs. baseline in a "
                  f"subagent ≈ {base:,.0f} → ≈ {base / inl:.1f}× fewer tokens",
                  "- Caveats: inline output stays in the main conversation and is re-read on later turns (cached); "
                  "the answerer also saw the question list (not the answer key)."]
    elif overhead_measured and base and "kb" in summary:
        kb_inline = summary["kb"]["tokens_mean"] - overhead_measured
        lines += ["", "## KB queried in the main context (estimate)", "",
                  "Under the rule *documents only in subagents*, the baseline must always pay an answering subagent; "
                  "the compact output of `KB ask/show/query/page-text` may be read in the main context.",
                  f"- KB inline ≈ {kb_inline:,.0f} tokens/question (context added by the kb configuration) vs. "
                  f"baseline in a subagent ≈ {base:,.0f} → ≈ {base / kb_inline:.1f}× fewer tokens"
                  if kb_inline > 0 else "- KB inline: not estimable (kb context added ≤ 0).",
                  "- Caveats: inline output stays in the main conversation and is re-read on later turns (cached); "
                  "the saving comes from avoiding the subagent, not from cheaper retrieval — compare the "
                  "*context added* column to see retrieval efficiency."]

    if ta.get("words") and words_sub and base:
        f = ta["words"] / words_sub
        overhead = overhead_measured or min(v["tokens_mean"] for v in summary.values())
        variable = max(base - overhead, 0)
        src = "measured" if overhead_measured else "rough: cheapest configuration"
        lines += ["", "## Projection to the whole workspace (assumption-based)", "",
                  f"- Whole workspace has {f:.1f}× the words of the subset.",
                  f"- Fixed per-question overhead ({src}) ≈ {overhead:,.0f} tokens; baseline context added ≈ {variable:,.0f}.",
                  f"- Baseline if questions spread over all documents ≤ {overhead + variable * f:,.0f} tokens/question "
                  "(upper bound: assumes reading grows with words; Grep narrows reading).",
                  "- Graph-based configurations query an index: per-question cost grows slowly with volume (assumed ~constant)."]
    if words_sub and words_sub < 20000:
        lines += ["", f"> ⚠️ The evaluated subset has only {words_sub:,} words: fixed subagent overhead dominates and cost "
                  "differences are not meaningful. Use ≥ 20k words, 3 runs and the 12 question types for decisions."]
    lines += ["", "## Caveats", "",
              "- Indicative: few runs, grader from the same model family, answer key produced by an LLM from the sources.",
              "- Never prefer a cheaper configuration that loses accuracy or citations."]
    out = Path(a.out)
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text("\n".join(lines) + "\n", encoding="utf-8")
    (out.parent / "summary.json").write_text(json.dumps({"configs": summary, "volume_subset": ts, "volume_all": ta,
                                                         "build": bc, "subagent_overhead": overhead_measured},
                                                        indent=1, default=str), encoding="utf-8")
    print(f"report written: {out}")


if __name__ == "__main__":
    main()

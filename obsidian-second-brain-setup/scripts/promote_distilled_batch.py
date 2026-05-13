#!/usr/bin/env python3
"""
One-off / batch helper: promote inbox `distilled-*.md` notes to PARA folders.
Folds ## Distilled content into body, strips migration YAML, rewrites follow-up.
Routes `distilled_category: project-ideas` to 02-Projects; others default to 04-Resources.
"""
from __future__ import annotations

import re
import sys
import subprocess
import unicodedata
from pathlib import Path

VAULT = Path("/home/maccalsa/SecondBrain")
INBOX = VAULT / "00-Inbox"
RES = VAULT / "04-Resources"
PROJ = VAULT / "02-Projects"

STOPWORDS = frozenset(
    "a an the and or for to of in on at by with from into distilled how setup "
    "using use your my app web when what setting up down out off over into "
    "accessing retrieve optional integrating deploying installing creating "
    "building fixing troubleshooting updating adding getting running making "
    "copying referencing downloading securing configuring".split()
)


def slugify(title: str) -> str:
    s = unicodedata.normalize("NFKD", title)
    s = s.encode("ascii", "ignore").decode("ascii")
    s = re.sub(r"[^a-zA-Z0-9]+", "-", s.lower()).strip("-")
    return re.sub(r"-{2,}", "-", s) or "note"


def tags_from_title(title: str, extra: list[str]) -> list[str]:
    words = re.findall(r"[a-zA-Z][a-zA-Z0-9+.#]*", title.lower())
    out: list[str] = []
    for w in words:
        if w in STOPWORDS or len(w) < 2:
            continue
        if w not in out:
            out.append(w)
    for e in extra:
        if e not in out:
            out.append(e)
    return out[:8]


def parse_source_block(rest: str) -> tuple[str, str]:
    """Return (conversations_file, uuid) from 'source: ... | conversations-00N.json | uuid'."""
    m = re.search(
        r"## Source / context\n+(?:source:\s*)?([^\n|]+)\s*\|\s*(conversations-[^\s|]+\.json)\s*\|\s*([0-9a-f-]{36})",
        rest,
        re.IGNORECASE,
    )
    if m:
        return m.group(2), m.group(3)
    m2 = re.search(r"(conversations-[^\s|]+\.json)\s*\|\s*([0-9a-f-]{36})", rest)
    if m2:
        return m2.group(1), m2.group(2)
    return "", ""


def first_distilled_title(distilled: str) -> str | None:
    for line in distilled.splitlines():
        if line.startswith("# "):
            return line[2:].strip()
    return None


def strip_leading_h1(distilled: str, title: str) -> str:
    lines = distilled.splitlines()
    if not lines:
        return distilled
    if lines[0].startswith("# "):
        inner = lines[0][2:].strip()
        if inner.lower() == title.lower() or not title:
            return "\n".join(lines[1:]).lstrip("\n")
    return distilled


def first_summary_paragraph(distilled: str) -> str:
    """Heuristic: first substantive prose or bullet glosses, skipping code fences."""
    in_code = False
    parts: list[str] = []
    for line in distilled.splitlines():
        st = line.strip()
        if st.startswith("```"):
            in_code = not in_code
            continue
        if in_code or st.startswith("|"):
            continue
        if line.startswith("#"):
            continue
        if st.startswith(("-", "*")):
            txt = re.sub(r"^[-*]\s*", "", st)
            txt = re.sub(r"^\*\*([^*]+)\*\*\s*", r"\1: ", txt)
            txt = re.sub(r"^`[^`]+`\s*", "", txt)
            if len(txt) > 25:
                parts.append(txt)
            if sum(len(p) for p in parts) > 420:
                break
            continue
        if st and not st.startswith("["):
            parts.append(st)
        if sum(len(p) for p in parts) > 500:
            break
    text = " ".join(parts[:8]).strip()
    if len(text) > 650:
        text = text[:647].rsplit(" ", 1)[0] + "…"
    text = re.sub(r" (\d+\. \*\*)", r"\n\n\1", text)
    return text


def why_line(title: str, is_project: bool = False) -> str:
    if is_project:
        return "Idea-backlog note—use when scoping a build, comparing options, or deciding what to commit to next."
    return "Bookmark for the next time this shows up in implementation, debugging, or design discussion."


def fix_kubectl_markdown_fence(body: str) -> str:
    """Unwrap ```markdown ... ``` wrappers (e.g. crib-sheet tables)."""
    if "```markdown" not in body:
        return body
    out: list[str] = []
    i = 0
    while True:
        j = body.find("```markdown", i)
        if j == -1:
            out.append(body[i:])
            break
        out.append(body[i:j])
        k = body.find("\n```", j + 11)
        if k == -1:
            out.append(body[j:])
            break
        inner = body[j + len("```markdown") : k].strip("\n")
        out.append(inner)
        i = k + len("\n```")
    return "".join(out)


def rename_inner_summary_heading(body: str) -> str:
    """Rename a second '## Summary' inside the body to avoid clashing with top Summary."""
    n = body.count("\n## Summary\n")
    if n < 2:
        return body
    first = body.find("\n## Summary\n")
    rest = body[first + len("\n## Summary\n") :]
    second = rest.find("\n## Summary\n")
    if second == -1:
        return body
    abs_second = first + len("\n## Summary\n") + second
    return body[: abs_second] + "\n## At a glance\n" + body[abs_second + len("\n## Summary\n") :]


def extra_tags_from_slug(slug: str) -> list[str]:
    parts = [p for p in slug.split("-") if len(p) > 2 and p not in STOPWORDS]
    return parts[:3]


def promote_one(src: Path, dest_dir: Path | None = None, tag_extra: list[str] | None = None) -> Path:
    raw = src.read_text(encoding="utf-8")
    m = re.match(r"^---\s*\n(.*?)\n---\s*\n", raw, re.DOTALL)
    if not m:
        raise ValueError(f"No front matter: {src}")
    fm_text = m.group(1)
    body = raw[m.end() :]
    is_project = bool(
        re.search(r"^distilled_category:\s*project-ideas\s*$", fm_text, re.MULTILINE)
    )
    if dest_dir is None:
        dest_dir = PROJ if is_project else RES
    created = "2026-05-13"
    if re.search(r"^created:\s*(\S+)", fm_text, re.MULTILINE):
        created = re.search(r"^created:\s*(\S+)", fm_text, re.MULTILINE).group(1)

    dm = re.search(
        r"## Distilled content\s*\n+(.*)\n## Source / context",
        body,
        re.DOTALL,
    )
    if not dm:
        raise ValueError(f"No Distilled content: {src}")
    distilled = dm.group(1).rstrip()
    tail = body[dm.end() - len("## Source / context") :]
    conv_file, uuid = parse_source_block(body)

    inbox_h1 = None
    m1 = re.search(r"^# (.+)$", body, re.MULTILINE)
    if m1:
        inbox_h1 = m1.group(1).strip()

    dtitle = first_distilled_title(distilled)
    title = dtitle or inbox_h1 or src.stem.replace("distilled-how-to-", "").replace("-", " ").title()

    distilled_body = strip_leading_h1(distilled, title)
    distilled_body = fix_kubectl_markdown_fence(distilled_body)
    distilled_body = rename_inner_summary_heading(distilled_body)

    summary = first_summary_paragraph(distilled)
    if not summary:
        summary = f"Structured notes on {title.lower()}—distilled from an exported chat."

    tags = tags_from_title(title, tag_extra or [])
    if is_project:
        for t in ("product-ideas", "backlog"):
            if t not in tags:
                tags.append(t)
    for t in extra_tags_from_slug(slugify(title)):
        if t not in tags:
            tags.append(t)

    slug = slugify(title)
    base_slug = f"project-{slug}" if is_project else slug
    dest = dest_dir / f"{base_slug}.md"
    if dest.exists():
        i = 2
        while True:
            cand = dest_dir / f"{base_slug}-from-distilled-import-{i}.md"
            if not cand.exists():
                dest = cand
                break
            i += 1

    audit_lines = []
    if conv_file and uuid:
        audit_lines.append(f"- Chat distiller: `{conv_file}` · `{uuid}`")
    else:
        audit_lines.append("- Chat distiller: export reference not parsed; see archived inbox export if needed.")
    cat_m = re.search(r"^distilled_category:\s*(\S+)", fm_text, re.MULTILINE)
    if cat_m:
        audit_lines.append(f"- Prior import category: {cat_m.group(1)}")

    tags_yaml = "\n".join(f"  - {t}" for t in tags[:8])

    out = f"""---
type: note
source: human
status: ready
created: {created}
updated: 2026-05-13
confidence: medium
tags:
{tags_yaml}
---

# {title}

## Summary

{summary}

## Why this matters

{why_line(title, is_project)}

{distilled_body}

## Source / context

{chr(10).join(audit_lines)}

## Links


## Follow-up

- [ ] Review this note
"""
    dest.write_text(out, encoding="utf-8")
    src.unlink()
    return dest


def shortest_n(n: int) -> list[Path]:
    proc = subprocess.run(
        ["bash", "-c", f"wc -l {INBOX}/distilled-how-to-*.md 2>/dev/null | grep -v ' total$' | sort -n | head -{n} | awk '{{print $2}}'"],
        capture_output=True,
        text=True,
        check=True,
    )
    paths = [Path(p) for p in proc.stdout.splitlines() if p.strip()]
    return paths


def shortest_n_all(n: int) -> list[Path]:
    """Shortest `distilled-*.md` in Inbox by line count (any category)."""
    inbox_files = sorted(INBOX.glob("distilled-*.md"))
    scored: list[tuple[int, Path]] = []
    for p in inbox_files:
        try:
            nlines = sum(1 for _ in p.open(encoding="utf-8", errors="replace"))
        except OSError:
            continue
        scored.append((nlines, p))
    scored.sort(key=lambda x: x[0])
    return [p for _, p in scored[:n]]


def main() -> None:
    # (src stem fragment, dest PROJ vs RES, optional extra tags)
    projects: dict[str, tuple[str, list[str] | None]] = {}

    n = 50
    if len(sys.argv) > 1:
        n = max(1, int(sys.argv[1]))
    paths = shortest_n_all(n)
    done: list[tuple[str, str]] = []
    for src in paths:
        dest_dir: Path | None = None
        extra = None
        for frag, (folder, xt) in projects.items():
            if frag in src.name:
                dest_dir = PROJ if folder == "proj" else RES
                extra = xt
                break
        dest = promote_one(src, dest_dir, extra)
        done.append((src.name, str(dest.relative_to(VAULT))))

    print(f"Promoted {len(done)} notes")
    for old, new in done:
        print(f"  {old} -> {new}")


if __name__ == "__main__":
    main()

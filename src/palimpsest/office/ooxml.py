"""Translate Office files by editing the OOXML in place, never rebuilding them.

Why this exists
----------------
A naive approach -- load each workbook with a library like openpyxl and
save it again -- treats that library as an editor when it is actually a
reader/writer: it reconstructs the file from the subset of the format it
models, and silently drops every part it does not. Measured against a set
of real Office source documents this project was built against, that
approach lost every `xl/drawings/*` part (every shape, text box, and
image in the workbook), `xl/metadata`, several sheets' `.rels`, all
`webextensions/*` parts, and `calcChain.xml`; `xl/workbook.xml` itself
shrank by more than two-thirds, dropping `fileVersion`, revision pointers,
and calc features.

An .xlsx/.docx/.pptx is a zip of XML parts. This module opens that zip,
rewrites ONLY the text nodes inside the parts that carry human-readable
text, and copies every other entry through byte-for-byte with its
original compression and timestamp. Anything the translator does not
understand is preserved precisely because it is never parsed.
"""

from __future__ import annotations

import logging
import os
import re
import zipfile
from collections.abc import Callable

from lxml import etree

log = logging.getLogger(__name__)

# Namespaces
NS_MAIN = "http://schemas.openxmlformats.org/spreadsheetml/2006/main"
NS_A = "http://schemas.openxmlformats.org/drawingml/2006/main"
NS_W = "http://schemas.openxmlformats.org/wordprocessingml/2006/main"

# Mirror pdf/render.py MIN_SCALE: below ~72% shrinking disfigures more than
# a slight overflow, so proportional font shrink floors there.
MIN_SCALE = 0.72

# Text that is never prose and must not be sent to a translator.
_SKIP_RE = re.compile(r"^[\s\d.,:;%$/()\-+*=<>#&@'\"\[\]{}|\\^~`!?]*$")
_FORMULA_RE = re.compile(r"^[=+\-@]")


def _translatable(s: str | None) -> bool:
    if not s or not s.strip():
        return False
    t = s.strip()
    if _SKIP_RE.match(t) or _FORMULA_RE.match(t):
        return False
    # Needs at least one run of letters to be worth translating.
    # Unicode letter class (not Latin-only): Chinese/Japanese/Korean and
    # every other script count, so pure-CJK paragraphs are translated.
    # ponytail: single regex, no per-script ranges to maintain.
    return bool(re.search(r"[^\W\d_]{2,}", t))


def _iter_text_nodes(tree, part_name: str):
    """Yield elements whose .text should be translated, for a given part."""
    root = tree.getroot()
    lname = part_name.lower()

    if "sharedstrings" in lname:
        # <si><t> and rich-text <si><r><t>
        yield from root.iter("{%s}t" % NS_MAIN)
    elif lname.startswith("xl/worksheets/") and lname.endswith(".xml"):
        # inline strings, plus header/footer text
        yield from root.iter("{%s}t" % NS_MAIN)
        for tag in (
            "oddHeader", "oddFooter", "evenHeader", "evenFooter",
            "firstHeader", "firstFooter",
        ):
            yield from root.iter("{%s}%s" % (NS_MAIN, tag))
    elif "/drawings/" in lname or "/charts/" in lname or lname.startswith("ppt/"):
        yield from root.iter("{%s}t" % NS_A)
    elif lname.startswith("word/"):
        yield from root.iter("{%s}t" % NS_W)
    elif "comments" in lname or "threadedcomment" in lname:
        yield from root.iter("{%s}t" % NS_MAIN)
        yield from root.iter("{%s}t" % NS_A)


def _is_text_part(name: str) -> bool:
    n = name.lower()
    if not n.endswith(".xml"):
        return False
    return (
        "sharedstrings" in n
        or (n.startswith("xl/worksheets/") and "_rels" not in n)
        or "/drawings/" in n
        or "/charts/" in n
        or n.startswith("word/document")
        or n.startswith("word/header")
        or n.startswith("word/footer")
        or n.startswith("ppt/slides/slide")
        or n.startswith("ppt/notesslides/")
        or "comments" in n
    )


def collect_strings(path: str) -> list[str]:
    """Every translatable string in the file, in stable order."""
    out: list[str] = []
    seen: set[str] = set()
    with zipfile.ZipFile(path) as z:
        for name in z.namelist():
            if not _is_text_part(name):
                continue
            try:
                tree = etree.fromstring(z.read(name)).getroottree()
            except etree.XMLSyntaxError:
                continue
            for el in _iter_text_nodes(tree, name):
                s = el.text
                if _translatable(s) and s not in seen:
                    seen.add(s)
                    out.append(s)
    return out


def sheet_names(path: str) -> list[str]:
    names = []
    with zipfile.ZipFile(path) as z:
        if "xl/workbook.xml" not in z.namelist():
            return names
        root = etree.fromstring(z.read("xl/workbook.xml"))
        for sh in root.iter("{%s}sheet" % NS_MAIN):
            n = sh.get("name")
            if n:
                names.append(n)
    return names


def _ensure_shrink_autofit(t_el) -> None:
    """Pin a pptx/drawing textbox to shrink-to-fit: the a:t's txBody gets a
    bodyPr holding <a:shrinkTxOnOverflow/>, competing modes removed. Box
    geometry (xfrm/spPr) is never touched, so layout doesn't reflow -- the
    renderer shrinks overflowing CJK-expanded text inside the fixed box."""
    for anc in t_el.iterancestors():
        if etree.QName(anc).localname != "txBody":
            continue
        body_pr = anc.find("{%s}bodyPr" % NS_A)
        if body_pr is None:
            body_pr = etree.Element("{%s}bodyPr" % NS_A)
            anc.insert(0, body_pr)  # bodyPr is always txBody's first child
        else:
            for child in list(body_pr):
                if etree.QName(child).localname in ("noAutofit", "spAutoFit"):
                    body_pr.remove(child)
        if body_pr.find("{%s}shrinkTxOnOverflow" % NS_A) is None:
            etree.SubElement(body_pr, "{%s}shrinkTxOnOverflow" % NS_A)
        return


def _shrink_docx_run(t_el, src: str, dst: str) -> None:
    """Proportionally shrink a docx run's w:sz/w:szCs when the translation
    is longer than the source (zh compact -> longer ko/en), floored at
    MIN_SCALE. Only shrinks explicitly-sized runs; unsized runs (styled by
    the stylesheet) are left alone. Never grows text."""
    if len(dst) <= len(src):
        return
    scale = max(MIN_SCALE, len(src) / len(dst))
    if scale >= 1.0:
        return
    r = t_el.getparent()
    while r is not None and etree.QName(r).localname != "r":
        r = r.getparent()
    if r is None:
        return
    rPr = r.find("{%s}rPr" % NS_W)
    if rPr is None:
        return
    for tag in ("sz", "szCs"):
        sz_el = rPr.find("{%s}%s" % (NS_W, tag))
        if sz_el is None:
            continue
        try:
            old = int(sz_el.get("{%s}val" % NS_W))
        except (TypeError, ValueError):
            continue
        sz_el.set("{%s}val" % NS_W, str(max(1, round(old * scale))))


def _rewrite_part(
    data: bytes, name: str, lookup: Callable[[str], str | None], stats: dict
) -> bytes | None:
    tree = etree.fromstring(data).getroottree()
    changed = False
    lname = name.lower()
    is_shape_text = (
        lname.startswith("ppt/") or "/drawings/" in lname or "/charts/" in lname
    )
    is_word = lname.startswith("word/")
    for el in _iter_text_nodes(tree, name):
        s = el.text
        if not _translatable(s):
            continue
        en = lookup(s)
        if en and en != s:
            el.text = en
            changed = True
            stats["nodes"] += 1
            if is_shape_text:
                _ensure_shrink_autofit(el)
            elif is_word:
                _shrink_docx_run(el, s, en)
    # Shape/picture alt-text (p:cNvPr, xdr:cNvPr, wp:docPr @descr) is the
    # figure text screen readers and search see -- translate it too
    # (no shrink: alt-text has no visible box to overflow).
    if is_shape_text or is_word:
        for el in tree.iter():
            d = el.get("descr")
            if not _translatable(d):
                continue
            en = lookup(d)
            if en and en != d:
                el.set("descr", en)
                changed = True
                stats["nodes"] += 1
    if not changed:
        return None
    return etree.tostring(tree, xml_declaration=True, encoding="UTF-8", standalone=True)


def _rename_sheets(data: bytes, mapping: dict[str, str]) -> bytes | None:
    """Rewrite sheet tab names in xl/workbook.xml."""
    root = etree.fromstring(data)
    changed = False
    for sh in root.iter("{%s}sheet" % NS_MAIN):
        n = sh.get("name")
        if n in mapping and mapping[n] != n:
            sh.set("name", mapping[n])
            changed = True
    if not changed:
        return None
    return etree.tostring(
        root.getroottree(), xml_declaration=True, encoding="UTF-8", standalone=True
    )


def _retarget_refs(data: bytes, mapping: dict[str, str]) -> bytes | None:
    """Update sheet-name references inside formulas and defined names.

    Renaming a tab without this would break every cross-sheet formula.
    Both the quoted ('Sheet One'!A1) and bare (Sheet1!A1) forms are
    handled.
    """
    text = data.decode("utf-8")
    original = text
    for old, new in mapping.items():
        if old == new:
            continue
        text = text.replace(f"'{old}'!", f"'{new}'!")
        # Bare form only applies when the name needs no quoting.
        if re.fullmatch(r"[A-Za-z_][A-Za-z0-9_.]*", old):
            text = re.sub(rf"(?<![A-Za-z0-9_'!]){re.escape(old)}!", f"{new}!", text)
    if text == original:
        return None
    return text.encode("utf-8")


def translate_office(
    src: str,
    out: str,
    lookup: Callable[[str], str | None],
    translate_sheet_names: bool = True,
) -> dict:
    """Copy `src` to `out`, translating only its text nodes.

    `lookup(spanish) -> english_or_None` supplies translations; returning
    None leaves the original text untouched.
    """
    stats = {"nodes": 0, "parts": 0, "copied": 0, "sheets_renamed": 0}
    os.makedirs(os.path.dirname(out) or ".", exist_ok=True)

    name_map: dict[str, str] = {}
    if translate_sheet_names:
        for n in sheet_names(src):
            if _translatable(n):
                en = lookup(n)
                if en:
                    # Excel tab names: 31 chars max, and : \ / ? * [ ] are illegal.
                    en = re.sub(r"[:\\/?*\[\]]", " ", en).strip()[:31]
                    if en and en != n:
                        name_map[n] = en
    ref_parts = {"xl/workbook.xml"}

    with zipfile.ZipFile(src) as zin:
        names = zin.namelist()
        # Formula-bearing parts that must follow a sheet rename.
        if name_map:
            ref_parts |= {n for n in names if n.startswith("xl/worksheets/") and n.endswith(".xml")}
            ref_parts |= {n for n in names if "/charts/" in n.lower()}

        with zipfile.ZipFile(out, "w", zipfile.ZIP_DEFLATED) as zout:
            for info in zin.infolist():
                data = zin.read(info.filename)
                new: bytes | None = None

                if _is_text_part(info.filename):
                    try:
                        new = _rewrite_part(data, info.filename, lookup, stats)
                    except etree.XMLSyntaxError:
                        new = None
                    if new is not None:
                        stats["parts"] += 1

                if name_map and info.filename in ref_parts:
                    base = new if new is not None else data
                    if info.filename == "xl/workbook.xml":
                        renamed = _rename_sheets(base, name_map)
                        if renamed is not None:
                            base = renamed
                            stats["sheets_renamed"] = len(name_map)
                    retargeted = _retarget_refs(base, name_map)
                    if retargeted is not None:
                        new = retargeted
                    elif base is not data:
                        new = base

                if new is None:
                    stats["copied"] += 1
                # Preserve the entry's original compression and timestamp.
                zinfo = zipfile.ZipInfo(info.filename, date_time=info.date_time)
                zinfo.compress_type = info.compress_type
                zinfo.external_attr = info.external_attr
                zinfo.internal_attr = info.internal_attr
                zinfo.create_system = info.create_system
                zout.writestr(zinfo, new if new is not None else data)

    log.info(
        "parts rewritten=%d text nodes=%d copied verbatim=%d sheets renamed=%d",
        stats["parts"], stats["nodes"], stats["copied"], stats["sheets_renamed"],
    )
    return stats


def verify(src: str, out: str) -> dict:
    """Confirm no zip part was lost and only text parts changed."""
    with zipfile.ZipFile(src) as a, zipfile.ZipFile(out) as b:
        na, nb = set(a.namelist()), set(b.namelist())
        lost = sorted(na - nb)
        added = sorted(nb - na)
        changed = [n for n in sorted(na & nb) if a.read(n) != b.read(n)]
    return {"lost": lost, "added": added, "changed": changed}

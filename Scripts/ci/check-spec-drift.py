#!/usr/bin/env python3
"""Compare docs/feature-inventory.md code anchors against the Swift tree."""

from __future__ import annotations

import re
import sys
from dataclasses import dataclass
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
INVENTORY = REPO / "docs" / "feature-inventory.md"
CODE_DIRS = (REPO / "Sources", REPO / "Tests")
TABLE_ROW = re.compile(
    r"^\|\s*([^|]+)\|\s*([^|]+)\|\s*([^|]+)\|\s*([^|]+)\|\s*([^|]+)\s*\|"
)
BACKTICK_TOKEN = re.compile(r"`([^`]+)`")


@dataclass
class InventoryRow:
    area: str
    feature: str
    status: str
    build: str
    code_anchor: str


def load_swift_corpus() -> str:
    chunks: list[str] = []
    for root in CODE_DIRS:
        if not root.is_dir():
            continue
        for path in root.rglob("*.swift"):
            try:
                chunks.append(path.read_text(encoding="utf-8", errors="replace"))
            except OSError:
                continue
    return "\n".join(chunks)


def is_swift_symbol(token: str) -> bool:
    return re.match(r"^[A-Z][A-Za-z0-9]*$", token) is not None


def path_exists(token: str) -> bool:
    candidate = token.strip()
    path = REPO / candidate
    if path.is_file():
        return True
    if candidate.startswith("./"):
        return (REPO / candidate[2:]).is_file()
    return False


def scheme_exists(name: str) -> bool:
    scheme = (
        REPO / "MixStack.xcodeproj" / "xcshareddata" / "xcschemes" / f"{name}.xcscheme"
    )
    return scheme.is_file()


def swift_symbol_exists(symbol: str, corpus: str) -> bool:
    token = symbol.strip().split(".")[0].split("(")[0]
    if not token:
        return True
    pattern = re.compile(
        rf"\b(?:enum|struct|class|actor|protocol|func|typealias)\s+{re.escape(token)}\b"
    )
    if pattern.search(corpus):
        return True
    return re.search(rf"\b{re.escape(token)}\b", corpus) is not None


def validate_token(token: str, corpus: str) -> bool:
    cleaned = token.strip()
    if cleaned.endswith(".sh") or cleaned.endswith(".yml") or cleaned.startswith("."):
        return path_exists(cleaned)
    if scheme_exists(cleaned):
        return True
    if not is_swift_symbol(cleaned):
        return True
    return swift_symbol_exists(cleaned, corpus)


def parse_inventory() -> list[InventoryRow]:
    rows: list[InventoryRow] = []
    if not INVENTORY.is_file():
        return rows
    in_table = False
    for line in INVENTORY.read_text(encoding="utf-8").splitlines():
        if line.startswith("| Area |"):
            in_table = True
            continue
        if not in_table:
            continue
        if line.startswith("|---"):
            continue
        if not line.startswith("|"):
            break
        match = TABLE_ROW.match(line)
        if not match:
            continue
        area, feature, status, build, code = [cell.strip() for cell in match.groups()]
        rows.append(InventoryRow(area, feature, status, build, code))
    return rows


def extract_symbols(anchor: str) -> list[str]:
    return BACKTICK_TOKEN.findall(anchor)


def main() -> int:
    rows = parse_inventory()
    if not rows:
        print("NO   Missing or empty docs/feature-inventory.md table")
        return 1

    corpus = load_swift_corpus()
    missing_symbols: list[str] = []
    status_mismatches: list[str] = []

    for row in rows:
        for symbol in extract_symbols(row.code_anchor):
            if not validate_token(symbol, corpus):
                missing_symbols.append(f"{row.feature}: `{symbol}`")

        if "⛔" in row.status and "✅" in row.build:
            status_mismatches.append(
                f"{row.feature} marked not started but Build column is ✅"
            )

    print("Spec / code drift report")
    print(f"Inventory rows: {len(rows)}")
    print("")

    if missing_symbols:
        print("Missing code symbols:")
        for item in missing_symbols:
            print(f"  NO   {item}")
    else:
        print("Code anchors: OK")

    if status_mismatches:
        print("")
        print("Status / build mismatches:")
        for item in status_mismatches:
            print(f"  NO   {item}")
    else:
        print("Status vs build column: OK")

    failed = bool(missing_symbols or status_mismatches)
    print("")
    print("RESULT:", "FAIL" if failed else "PASS")
    return 1 if failed else 0


if __name__ == "__main__":
    raise SystemExit(main())

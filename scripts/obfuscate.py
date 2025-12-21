#!/usr/bin/env python3
import argparse
import json
import random
import re
from pathlib import Path
from typing import Optional

SWIFT_KEYWORDS = {
    "associatedtype",
    "class",
    "deinit",
    "enum",
    "extension",
    "fileprivate",
    "func",
    "import",
    "init",
    "inout",
    "internal",
    "let",
    "open",
    "operator",
    "private",
    "protocol",
    "public",
    "static",
    "struct",
    "subscript",
    "typealias",
    "var",
    "break",
    "case",
    "continue",
    "default",
    "defer",
    "do",
    "else",
    "fallthrough",
    "for",
    "guard",
    "if",
    "in",
    "repeat",
    "return",
    "switch",
    "where",
    "while",
    "as",
    "Any",
    "catch",
    "false",
    "is",
    "nil",
    "rethrows",
    "super",
    "self",
    "Self",
    "throw",
    "throws",
    "true",
    "try",
}

IDENT_RE = re.compile(r"\b[A-Za-z_][A-Za-z0-9_]*\b")
DECL_RE = re.compile(r"\b(struct|class|enum|protocol|typealias|func|var|let)\s+([A-Za-z_][A-Za-z0-9_]*)")
PUBLIC_DECL_RE = re.compile(
    r"\b(public|open)\s+(?:static\s+|class\s+)?"
    r"(struct|class|enum|protocol|typealias|func|var|let)\s+([A-Za-z_][A-Za-z0-9_]*)"
)


def split_segments(code: str):
    segments = []
    i = 0
    n = len(code)

    while i < n:
        if code.startswith("//", i):
            j = code.find("\n", i)
            if j == -1:
                j = n
            segments.append(("comment", code[i:j]))
            i = j
            continue

        if code.startswith("/*", i):
            j = code.find("*/", i + 2)
            if j == -1:
                j = n
            else:
                j += 2
            segments.append(("comment", code[i:j]))
            i = j
            continue

        if code.startswith('"""', i):
            j = i + 3
            while True:
                k = code.find('"""', j)
                if k == -1:
                    j = n
                    break
                j = k + 3
                break
            segments.append(("string", code[i:j]))
            i = j
            continue

        if code[i] == '"':
            j = i + 1
            while j < n:
                if code[j] == "\\":
                    j += 2
                    continue
                if code[j] == '"':
                    j += 1
                    break
                j += 1
            segments.append(("string", code[i:j]))
            i = j
            continue

        if code[i] == "#":
            hash_count = 0
            while i + hash_count < n and code[i + hash_count] == "#":
                hash_count += 1
            if i + hash_count < n and code[i + hash_count] == '"':
                if code.startswith('"""', i + hash_count):
                    end = consume_raw_string(code, i, hash_count, multiline=True)
                else:
                    end = consume_raw_string(code, i, hash_count, multiline=False)
                segments.append(("string", code[i:end]))
                i = end
                continue

        j = i
        while j < n:
            if code.startswith("//", j) or code.startswith("/*", j):
                break
            if code.startswith('"""', j) or code[j] == '"':
                break
            if code[j] == "#":
                hash_count = 0
                while j + hash_count < n and code[j + hash_count] == "#":
                    hash_count += 1
                if j + hash_count < n and code[j + hash_count] == '"':
                    break
            j += 1
        segments.append(("code", code[i:j]))
        i = j

    return segments


def consume_raw_string(code: str, start: int, hash_count: int, multiline: bool) -> int:
    n = len(code)
    if multiline:
        delim = '"""'
    else:
        delim = '"'

    i = start + hash_count + len(delim)
    while i < n:
        k = code.find(delim, i)
        if k == -1:
            return n
        end = k + len(delim)
        if code.startswith("#" * hash_count, end):
            return end + hash_count
        i = end
    return n


def collect_identifiers(segments, regex):
    names = set()
    for kind, text in segments:
        if kind != "code":
            continue
        for match in regex.finditer(text):
            if regex.groups:
                names.add(match.group(match.lastindex))
            else:
                names.add(match.group(0))
    return names


def collect_public_names(segments):
    names = set()
    for kind, text in segments:
        if kind != "code":
            continue
        for match in PUBLIC_DECL_RE.finditer(text):
            names.add(match.group(3))
    return names


def replace_identifiers(text: str, mapping: dict) -> str:
    out = []
    i = 0
    n = len(text)
    while i < n:
        c = text[i]
        if c == "_" or c.isalpha():
            j = i + 1
            while j < n and (text[j] == "_" or text[j].isalnum()):
                j += 1
            token = text[i:j]
            out.append(mapping.get(token, token))
            i = j
        else:
            out.append(c)
            i += 1
    return "".join(out)

def obfuscate_string_literal(text: str, mapping: dict) -> str:
    n = len(text)
    if n == 0:
        return text

    i = 0
    hash_count = 0
    while i < n and text[i] == "#":
        hash_count += 1
        i += 1

    delim = None
    if text.startswith('"""', i):
        delim = '"""'
    elif i < n and text[i] == '"':
        delim = '"'
    else:
        return text

    if not text.endswith("#" * hash_count + delim):
        return text

    content_start = i + len(delim)
    content_end = n - (len(delim) + hash_count)
    content = text[content_start:content_end]

    marker = "\\" + ("#" * hash_count) + "("
    if marker not in content:
        return text

    def skip_string_in_code(src: str, idx: int) -> Optional[int]:
        length = len(src)
        j = idx
        local_hashes = 0
        while j < length and src[j] == "#":
            local_hashes += 1
            j += 1
        if j >= length or src[j] != '"':
            return None

        if src.startswith('"""', j):
            local_delim = '"""'
        else:
            local_delim = '"'

        k = j + len(local_delim)
        while k < length:
            if local_delim == '"' and src[k] == "\\":
                k += 2
                continue
            if src.startswith(local_delim, k):
                end = k + len(local_delim)
                if src.startswith("#" * local_hashes, end):
                    return end + local_hashes
                k = end
                continue
            k += 1
        return length

    def find_interpolation_end(src: str, idx: int) -> Optional[int]:
        depth = 1
        k = idx
        length = len(src)
        while k < length:
            if src.startswith("//", k):
                k = src.find("\n", k)
                if k == -1:
                    return None
                continue
            if src.startswith("/*", k):
                end = src.find("*/", k + 2)
                if end == -1:
                    return None
                k = end + 2
                continue

            string_end = skip_string_in_code(src, k)
            if string_end is not None:
                k = string_end
                continue

            c = src[k]
            if c == "(":
                depth += 1
            elif c == ")":
                depth -= 1
                if depth == 0:
                    return k
            k += 1
        return None

    out = []
    idx = 0
    while idx < len(content):
        if content.startswith(marker, idx):
            out.append(marker)
            idx += len(marker)
            end = find_interpolation_end(content, idx)
            if end is None:
                out.append(content[idx:])
                idx = len(content)
                break
            expr = content[idx:end]
            out.append(replace_identifiers(expr, mapping))
            out.append(")")
            idx = end + 1
            continue
        out.append(content[idx])
        idx += 1

    return text[:content_start] + "".join(out) + text[content_end:]


def build_mapping(names, preserve, all_identifiers, prefix, seed):
    if seed is not None:
        random.seed(seed)
        names = list(names)
        random.shuffle(names)
    else:
        names = sorted(names)

    reserved = set(SWIFT_KEYWORDS) | set(preserve) | set(all_identifiers)
    mapping = {}
    counter = 0

    for name in names:
        if name in preserve:
            continue
        while True:
            candidate = f"{prefix}{counter:03d}"
            counter += 1
            if candidate not in reserved and candidate not in mapping.values():
                mapping[name] = candidate
                reserved.add(candidate)
                break

    return mapping


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Obfuscate Swift identifiers while keeping a readable source of truth."
    )
    parser.add_argument("input", type=Path, help="Path to the Swift file to obfuscate")
    parser.add_argument("--out", type=Path, required=True, help="Output path for obfuscated file")
    parser.add_argument(
        "--preserve",
        default="",
        help="Comma-separated identifiers to preserve (in addition to public/open names)",
    )
    parser.add_argument("--prefix", default="x", help="Prefix for generated identifiers")
    parser.add_argument("--seed", type=int, default=None, help="Shuffle mapping with a seed")
    parser.add_argument("--map-out", type=Path, help="Write identifier mapping JSON")

    args = parser.parse_args()

    code = args.input.read_text(encoding="utf-8")
    segments = split_segments(code)

    declared = collect_identifiers(segments, DECL_RE)
    public_names = collect_public_names(segments)
    all_identifiers = collect_identifiers(segments, IDENT_RE)

    preserve = {name for name in args.preserve.split(",") if name}
    preserve |= public_names

    to_obfuscate = {name for name in declared if name not in preserve}
    mapping = build_mapping(
        to_obfuscate,
        preserve=preserve,
        all_identifiers=all_identifiers,
        prefix=args.prefix,
        seed=args.seed,
    )

    output_parts = []
    for kind, text in segments:
        if kind == "code":
            output_parts.append(replace_identifiers(text, mapping))
        elif kind == "string":
            output_parts.append(obfuscate_string_literal(text, mapping))
        else:
            output_parts.append(text)
    obfuscated = "".join(output_parts)

    args.out.parent.mkdir(parents=True, exist_ok=True)
    args.out.write_text(obfuscated, encoding="utf-8")

    if args.map_out:
        args.map_out.parent.mkdir(parents=True, exist_ok=True)
        args.map_out.write_text(json.dumps(mapping, indent=2, sort_keys=True), encoding="utf-8")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())

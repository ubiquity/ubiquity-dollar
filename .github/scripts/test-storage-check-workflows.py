#!/usr/bin/env python3
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]

WORKFLOW_EXPECTATIONS = (
    (
        ".github/workflows/core-contracts-storage-check.yml",
        "contracts_modified_files != ''",
        "contracts_modified_files",
        "contracts_all_changed_files",
    ),
    (
        ".github/workflows/diamond-storage-check.yml",
        "libraries_modified_files != ''",
        "libraries_modified_files",
        "libraries_all_changed_files",
    ),
)


def main() -> int:
    failures = []

    for workflow_path, expected_gate, expected_files, forbidden_files in WORKFLOW_EXPECTATIONS:
        text = (ROOT / workflow_path).read_text()

        if expected_gate not in text:
            failures.append(f"{workflow_path}: missing gate {expected_gate!r}")
        if expected_files not in text:
            failures.append(f"{workflow_path}: missing modified-file output {expected_files!r}")
        if forbidden_files in text:
            failures.append(f"{workflow_path}: still uses added-file-inclusive output {forbidden_files!r}")

    if failures:
        print("Storage workflow checks failed:")
        for failure in failures:
            print(f" - {failure}")
        return 1

    print("Storage workflow checks passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

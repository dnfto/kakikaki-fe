#!/usr/bin/env python3
"""Generate sequenced git commits with AUTHOR/COMMITTER dates (local helper; not run in CI)."""
from __future__ import annotations

import json
import shlex
import subprocess
import sys
import tempfile
from collections import defaultdict
from datetime import datetime, timedelta
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

# Feature order for stable, dependency-friendly batches (domain → UI per feature).
FEATURES_ORDER = [
    "grammar",
    "home",
    "auth",
    "my",
    "diary",
    "study",
    "vocabulary",
    "ai_agent",
]


def feat_rank(name: str) -> int:
    try:
        return FEATURES_ORDER.index(name)
    except ValueError:
        return 999


def get_worktree_paths() -> list[str]:
    r = subprocess.run(
        ["git", "status", "--porcelain=v1", "-u"],
        cwd=ROOT,
        capture_output=True,
        text=True,
        check=True,
    )
    paths: list[str] = []
    for line in r.stdout.splitlines():
        if len(line) < 4:
            continue
        path = line[3:]
        if path.startswith('"'):
            path = json.loads(path)
        elif " -> " in path:
            path = path.split(" -> ")[-1]
        ign = subprocess.run(["git", "check-ignore", "-q", path], cwd=ROOT)
        if ign.returncode == 0:
            continue
        paths.append(path)
    return paths


def bucket_core(p: str) -> str:
    if p.startswith("lib/core/config/"):
        return "core_config"
    if p.startswith("lib/core/base/"):
        return "core_base"
    if p.startswith("lib/core/domain/"):
        return "core_domain"
    if p.startswith("lib/core/error/"):
        return "core_error"
    if p.startswith("lib/core/extension/"):
        return "core_extension"
    if p.startswith("lib/core/mixin/"):
        return "core_mixin"
    if p.startswith("lib/core/storage/"):
        return "core_storage"
    if p.startswith("lib/core/utils/"):
        return "core_utils"
    if p.startswith("lib/core/onboarding/"):
        return "core_onboarding"
    if p.startswith("lib/core/network/"):
        return "core_network"
    return "core_misc"


def classify(p: str) -> tuple[tuple[int, int, str], str, str]:
    """(sort_key, conventional_type, message). sort_key = (phase, sub, label_for_tiebreak)."""
    z = (0, 0, "")

    if p == ".gitignore":
        return ((0, 0, ""), "chore", "chore: tighten ignore rules for Flutter and secrets")
    if p == ".env.example":
        return ((1, 0, ""), "chore", "chore: document environment variables")
    if p in ("pubspec.yaml", "pubspec.lock"):
        return ((2, 0, ""), "chore", "chore: add dependencies and lockfile")
    if p == ".metadata":
        return ((3, 0, ""), "chore", "chore: update Flutter project metadata")
    if p in (
        "Makefile",
        "devtools_options.yaml",
        "firebase.json",
        "flutter_native_splash.yaml",
        "l10n.yaml",
    ):
        return (
            (4, 0, ""),
            "chore",
            "chore: add build, splash, i18n, and Firebase config files",
        )
    if p.startswith("tool/"):
        return ((5, 0, ""), "chore", "chore: add internal Dart tooling scripts")
    if p.startswith("scripts/"):
        return ((6, 0, ""), "chore", "chore: add shell helpers for iOS env")
    if p.startswith(".github/"):
        return ((7, 0, ""), "ci", "ci: add GitHub Actions workflows")
    if p.startswith("supabase/"):
        return ((8, 0, ""), "feat", "feat(supabase): add edge functions and local config")
    if p == "README.md":
        return ((9, 0, ""), "docs", "docs: refresh project readme")
    if p.startswith("assets/"):
        return ((10, 0, ""), "feat", "feat(assets): add images and bundled data")
    if p.startswith("lib/core/"):
        b = bucket_core(p)
        sub = {
            "core_config": 0,
            "core_base": 1,
            "core_domain": 2,
            "core_error": 3,
            "core_extension": 4,
            "core_mixin": 5,
            "core_storage": 6,
            "core_utils": 7,
            "core_onboarding": 8,
            "core_network": 9,
            "core_misc": 10,
        }[b]
        messages = {
            "core_config": "feat(core): add dependency injection and runtime config",
            "core_base": "feat(core): add shared base types, DTO, and pagination",
            "core_domain": "feat(core): add core domain models",
            "core_error": "feat(core): add error reporting and routed error UI",
            "core_extension": "feat(core): add Dart context and collection extensions",
            "core_mixin": "feat(core): add reusable UI and BLoC mixins",
            "core_storage": "feat(core): add local and secure storage helpers",
            "core_utils": "feat(core): add formatting, date, and Supabase utilities",
            "core_onboarding": "feat(core): add tutorial coach mark helper",
            "core_network": "feat(core): add Dio client, interceptors, and API layer",
            "core_misc": "feat(core): add remaining core helpers",
        }
        return ((20, sub, b), "feat", messages[b])
    if p.startswith("lib/l10n/") or p.endswith("untranslated_messages.json"):
        return ((30, 0, p), "feat", "feat(l10n): add ARB catalogs and translation inputs")
    if p.startswith("lib/app/constants/"):
        return ((40, 0, ""), "feat", "feat(app): add shared app constants and theme tokens")
    if p.startswith("lib/app/enums/"):
        return ((41, 0, ""), "feat", "feat(app): add shared enumerations")
    if p.startswith("lib/app/domain/entity/"):
        return ((42, 0, ""), "feat", "feat(app): add user domain entity")
    if p.startswith("lib/app/domain/repository/"):
        return ((43, 0, ""), "feat", "feat(app): add auth repository contract")

    if p.startswith("lib/features/"):
        rest = p[len("lib/features/") :]
        feat, _, sub = rest.partition("/")
        parts = sub.split("/")
        first = parts[0]
        second = parts[1] if len(parts) > 1 else ""
        fr = feat_rank(feat)
        if first == "domain":
            if second in ("model", "entity", "enums", "enum"):
                return (
                    (50, fr, feat),
                    "feat",
                    f"feat({feat}): add domain models and types",
                )
            if second in ("repository", "usecase"):
                return (
                    (60, fr, feat),
                    "feat",
                    f"feat({feat}): add repository contracts and use cases",
                )
        if first == "data":
            if second == "dto":
                return ((70, fr, feat), "feat", f"feat({feat}): add API DTOs")
            if second in ("source", "repository"):
                return (
                    (85, fr, feat),
                    "feat",
                    f"feat({feat}): add remote sources and repository implementation",
                )
        if first == "presentation":
            if second == "bloc":
                return (
                    (100, fr, feat),
                    "feat",
                    f"feat({feat}): add presentation blocs",
                )
            return ((110, fr, feat), "feat", f"feat({feat}): add screens and widgets")
        raise RuntimeError(f"unclassified feature path: {p}")

    if p.startswith("lib/app/data/"):
        return ((80, 0, ""), "feat", "feat(app): add app-level data layer")
    if p.startswith("lib/app/service/"):
        return ((90, 0, ""), "feat", "feat(app): add app services")
    if p.startswith("lib/app/bloc/"):
        return ((95, 0, ""), "feat", "feat(app): add global app bloc")
    if p.startswith("lib/app/widget/"):
        return ((105, 0, ""), "feat", "feat(app): add shared presentation widgets")
    if p.startswith("lib/app/router/") or p == "lib/app/app.dart":
        return ((115, 0, ""), "feat", "feat(app): wire app shell and router")
    if p.startswith("lib/router/"):
        return ((120, 0, ""), "feat", "feat(router): add route table and navigation")
    if p == "lib/main.dart":
        return ((125, 0, ""), "feat", "feat: initialize entrypoint and bootstrap")

    if p.startswith("test/"):
        return ((130, 0, ""), "test", "test: align widget smoke test with app")

    if p.startswith("android/"):
        if p.startswith("android/app/"):
            return (
                (200, 1, ""),
                "chore",
                "chore(android): configure application sources and assets",
            )
        return ((200, 0, ""), "chore", "chore(android): migrate root Gradle build setup")

    if p.startswith("ios/"):
        segments = p.split("/")
        is_runner_tree = len(segments) > 1 and segments[1] == "Runner"
        if (
            any(
                x in p
                for x in (
                    "Podfile",
                    ".xcconfig",
                    "/Flutter/",
                    "Debug-dev",
                    "Release-prod",
                )
            )
            or (len(segments) > 1 and segments[1] == "Flutter")
        ) and not is_runner_tree:
            return (
                (210, 0, ""),
                "chore",
                "chore(ios): add CocoaPods and flavor xcconfigs",
            )
        if is_runner_tree:
            return (
                (210, 1, ""),
                "chore",
                "chore(ios): update Runner assets, plist, and entitlements",
            )
        return (
            (210, 2, ""),
            "chore",
            "chore(ios): update Xcode project and workspace",
        )

    if p.startswith("web/"):
        return ((220, 0, ""), "chore", "chore(web): update web shell and splash assets")
    if p.startswith("linux/"):
        return ((230, 0, ""), "chore", "chore(linux): sync desktop embedding")
    if p.startswith("windows/"):
        return ((240, 0, ""), "chore", "chore(windows): sync Windows runner")
    if p.startswith("macos/"):
        return ((250, 0, ""), "chore", "chore(macos): sync macOS project")
    if p.startswith(".vscode/"):
        return ((260, 0, ""), "chore", "chore: add VS Code workspace settings")

    raise RuntimeError(f"unclassified path: {p}")


def main() -> None:
    paths = get_worktree_paths()
    groups: dict[tuple[tuple, str, str], list[str]] = defaultdict(list)
    for p in paths:
        key, typ, msg = classify(p)
        groups[(key, typ, msg)].append(p)

    items = []
    for (key, typ, msg), files in groups.items():
        items.append((key, typ, msg, sorted(files)))
    items.sort(key=lambda x: (x[0], x[2]))

    n = len(items)
    start = datetime(2026, 3, 8, 9, 0, 0)
    end = datetime(2026, 3, 31, 18, 0, 0)
    if n <= 1:
        times = [start] * max(1, n)
    else:
        delta = (end - start).total_seconds() / (n - 1)
        times = [start + timedelta(seconds=delta * i) for i in range(n)]

    script_lines = [
        "#!/usr/bin/env bash",
        "set -euo pipefail",
        f"cd {shlex.quote(str(ROOT))}",
        "",
    ]
    for i, (_, typ, msg, files) in enumerate(items):
        ts = times[i].strftime("%Y-%m-%d %H:%M:%S")
        for f in files:
            script_lines.append(f"git add -- {shlex.quote(f)}")
        script_lines.append(
            f'GIT_AUTHOR_DATE="{ts}" GIT_COMMITTER_DATE="{ts}" git commit -m {shlex.quote(msg)}'
        )
        script_lines.append("")

    fd, tmp_name = tempfile.mkstemp(prefix="kakikaki_git_history_", suffix=".sh", text=True)
    with open(fd, "w", encoding="utf-8") as fh:
        fh.write("\n".join(script_lines))
    Path(tmp_name).chmod(0o755)
    print(f"Wrote {n} commits to {tmp_name}")
    if "--run" in sys.argv:
        subprocess.run(["bash", tmp_name], cwd=ROOT, check=True)


if __name__ == "__main__":
    main()

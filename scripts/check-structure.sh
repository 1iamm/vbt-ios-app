#!/usr/bin/env bash
# Project structure checks for VBTrainer.
#
# Enforces invariants about WHERE code lives and WHAT it may import, so the
# AI-driven dev loop can't accidentally pull iOS-only frameworks into Watch
# code, mix Views into Services, etc. Cheap to run (pure grep) — runs on
# Linux in CI as a fast-fail before the expensive macOS build job.
#
# Exit non-zero on any violation. Emit human-readable messages.

set -u

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT" || exit 1

RED='\033[0;31m'
GREEN='\033[0;32m'
BOLD='\033[1m'
NC='\033[0m'

FAIL=0

fail() {
    echo -e "${RED}  ✗${NC} $1"
    FAIL=1
}

ok() {
    echo -e "${GREEN}  ✓${NC} $1"
}

# ────────────────────────────────────────────────────────────────────────────
# Rule 1: Shared/Models — pure data, no UI / platform UI frameworks.
# Allowed: Foundation, SwiftData, SwiftUI's Color is OK (lightweight token).
# ────────────────────────────────────────────────────────────────────────────
echo -e "${BOLD}[1/5] Shared/Models — no UI/platform imports${NC}"
violations=$(grep -lE "^import (UIKit|WatchKit|HealthKit|CoreMotion|WatchConnectivity)$" Shared/Models/*.swift 2>/dev/null || true)
if [ -n "$violations" ]; then
    for f in $violations; do
        fail "$f imports a UI/platform framework (Models should be pure data)"
    done
else
    ok "all Models files clean"
fi

# ────────────────────────────────────────────────────────────────────────────
# Rule 2: Shared/Algorithms — pure logic, no UI, no platform frameworks.
# Allowed: Foundation, simd. Forbidden: SwiftUI, UIKit, WatchKit, HealthKit,
# CoreMotion (sensor input lives in Watch App/Sensors, not in Algorithms).
# ────────────────────────────────────────────────────────────────────────────
echo -e "${BOLD}[2/5] Shared/Algorithms — pure logic only${NC}"
violations=$(grep -lE "^import (SwiftUI|UIKit|WatchKit|HealthKit|CoreMotion|WatchConnectivity|SwiftData)$" Shared/Algorithms/*.swift 2>/dev/null || true)
if [ -n "$violations" ]; then
    for f in $violations; do
        fail "$f imports a UI/platform/persistence framework (Algorithms must be pure)"
    done
else
    ok "all Algorithms files clean"
fi

# ────────────────────────────────────────────────────────────────────────────
# Rule 3: VBTrainer (iOS target) — no WatchKit (Watch-only framework).
# ────────────────────────────────────────────────────────────────────────────
echo -e "${BOLD}[3/5] iOS target — no WatchKit imports${NC}"
violations=$(grep -rlE "^import WatchKit$" VBTrainer 2>/dev/null || true)
if [ -n "$violations" ]; then
    for f in $violations; do
        fail "$f imports WatchKit (iOS target can't use it)"
    done
else
    ok "iOS target free of WatchKit"
fi

# ────────────────────────────────────────────────────────────────────────────
# Rule 4: Watch App — no UIKit (iOS-only framework).
# Note: SwiftUI is fine, ditto WatchKit. UIKit is the line.
# ────────────────────────────────────────────────────────────────────────────
echo -e "${BOLD}[4/5] Watch target — no UIKit imports${NC}"
violations=$(grep -rlE "^import UIKit$" "VBTrainerWatch Watch App" 2>/dev/null || true)
if [ -n "$violations" ]; then
    for f in $violations; do
        fail "$f imports UIKit (watchOS doesn't have UIKit)"
    done
else
    ok "Watch target free of UIKit"
fi

# ────────────────────────────────────────────────────────────────────────────
# Rule 5: View files must live under */Views/ — not under Services/ or App/.
# A "View file" = SwiftUI struct that imports SwiftUI and `struct …: View`.
# Heuristic: filename ends in View/Card/Sheet/Row/Section AND file contains
# `: View` somewhere.
# ────────────────────────────────────────────────────────────────────────────
echo -e "${BOLD}[5/5] View files live under Views/${NC}"
# Search all .swift in iOS + Watch targets excluding Views/ subtrees
candidates=$(find VBTrainer "VBTrainerWatch Watch App" \
    -name "*.swift" \
    -not -path "*/Views/*" \
    \( -name "*View.swift" -o -name "*Card.swift" -o -name "*Sheet.swift" -o -name "*Row.swift" \) \
    2>/dev/null)

view_violations=""
for f in $candidates; do
    if grep -q ": View$\|: View {" "$f" 2>/dev/null; then
        view_violations="$view_violations $f"
    fi
done

if [ -n "$view_violations" ]; then
    for f in $view_violations; do
        fail "$f looks like a SwiftUI View but is not under */Views/ (move it or rename)"
    done
else
    ok "no misplaced View files"
fi

echo
if [ "$FAIL" -eq 0 ]; then
    echo -e "${GREEN}${BOLD}✓ project structure checks passed${NC}"
    exit 0
else
    echo -e "${RED}${BOLD}✗ project structure violations detected${NC}"
    echo
    echo "How to fix:"
    echo "  - UI/platform import in Models/Algorithms → move the file or remove the import"
    echo "  - View file outside Views/ → move into the appropriate Views/ subfolder"
    echo "  - If a rule is wrong, edit scripts/check-structure.sh + explain in commit message"
    exit 1
fi

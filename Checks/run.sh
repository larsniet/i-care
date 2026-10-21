#!/bin/sh
# Compiles the date-logic checks against the app's own sources and runs them in
# several time zones, including one with a 45-minute offset.
set -e
cd "$(dirname "$0")/.."
out="$(mktemp -d)/date-checks"
swiftc -o "$out" \
    Shared/Models/ReminderSettings.swift \
    Shared/Models/DailySummary.swift \
    Shared/Models/BreakRecord.swift \
    Shared/Services/ReminderEngine.swift \
    Shared/Services/CompletionTracker.swift \
    Checks/main.swift
for tz in Europe/Amsterdam America/New_York Asia/Tokyo Pacific/Chatham UTC; do
    TZ="$tz" "$out"
done

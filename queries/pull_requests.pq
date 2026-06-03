let
    // Depends on: source.pq (or organization_metrics.pq / enterprise_metrics.pq)
    // One row per day with pull request metrics. Days with no PR data are excluded.
    NonNull = Table.SelectRows(source, each [pull_requests] <> null),
    Expanded = Table.ExpandRecordColumn(NonNull, "pull_requests", {
        "total_created",
        "total_merged",
        "total_reviewed",
        "total_suggestions",
        "total_applied_suggestions",
        "total_created_by_copilot",
        "total_reviewed_by_copilot",
        "total_merged_created_by_copilot",
        "total_merged_reviewed_by_copilot",
        "total_copilot_suggestions",
        "total_copilot_applied_suggestions",
        "median_minutes_to_merge",
        "median_minutes_to_merge_copilot_authored",
        "median_minutes_to_merge_copilot_reviewed"
    }),
    Typed = Table.TransformColumnTypes(Expanded, {{"day", type date}})
in
    Typed

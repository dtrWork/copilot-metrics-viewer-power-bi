let
    // Depends on: source.pq (or organization_metrics.pq / enterprise_metrics.pq)
    // One row per day per IDE (vscode, jetbrains, vim, etc.) for code completion metrics.
    Expanded = Table.ExpandListColumn(source, "totals_by_ide"),
    Fields = Table.ExpandRecordColumn(Expanded, "totals_by_ide", {
        "ide",
        "user_initiated_interaction_count",
        "code_acceptance_activity_count",
        "code_generation_activity_count",
        "loc_added_sum",
        "loc_suggested_to_add_sum",
        "loc_deleted_sum"
    }),
    Typed = Table.TransformColumnTypes(Fields, {{"day", type date}})
in
    Typed

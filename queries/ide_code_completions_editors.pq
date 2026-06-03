let
    // Depends on: source query (organization_metrics.pq or enterprise_metrics.pq)
    // One row per day per IDE (vscode, jetbrains, vim, etc.).
    // totals_by_ide items have the same field names as day-level totals,
    // so they are renamed here with an "ide_" prefix to avoid conflicts.
    Expanded = Table.ExpandListColumn(source, "totals_by_ide"),
    Fields = Table.ExpandRecordColumn(Expanded, "totals_by_ide",
        {
            "ide",
            "user_initiated_interaction_count",
            "code_acceptance_activity_count",
            "code_generation_activity_count",
            "loc_added_sum",
            "loc_suggested_to_add_sum",
            "loc_deleted_sum"
        },
        {
            "ide",
            "ide_user_initiated_interaction_count",
            "ide_code_acceptance_activity_count",
            "ide_code_generation_activity_count",
            "ide_loc_added_sum",
            "ide_loc_suggested_to_add_sum",
            "ide_loc_deleted_sum"
        }
    ),
    Typed = Table.TransformColumnTypes(Fields, {{"day", type date}})
in
    Typed

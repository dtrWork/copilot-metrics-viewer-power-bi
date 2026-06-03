let
    // Depends on: source query (organization_metrics.pq or enterprise_metrics.pq)
    // One row per day per language per feature (all features, not just code_completion).
    // Use ide_code_completions_editors.pq for code-completion-specific visuals with old column names.
    Expanded = Table.ExpandListColumn(source, "totals_by_language_feature"),
    Fields = Table.ExpandRecordColumn(Expanded, "totals_by_language_feature",
        {
            "language",
            "feature",
            "code_acceptance_activity_count",
            "code_generation_activity_count",
            "loc_added_sum",
            "loc_suggested_to_add_sum",
            "loc_deleted_sum"
        },
        {
            "language",
            "feature",
            "lang_code_acceptance_activity_count",
            "lang_code_generation_activity_count",
            "lang_loc_added_sum",
            "lang_loc_suggested_to_add_sum",
            "lang_loc_deleted_sum"
        }
    ),
    Typed = Table.TransformColumnTypes(Fields, {{"day", type date}})
in
    Typed

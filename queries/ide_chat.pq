let
    // Depends on: source.pq (or organization_metrics.pq / enterprise_metrics.pq)
    // One row per day for IDE chat usage only.
    Expanded = Table.ExpandListColumn(source, "totals_by_feature"),
    Fields = Table.ExpandRecordColumn(Expanded, "totals_by_feature", {
        "feature",
        "user_initiated_interaction_count",
        "code_acceptance_activity_count",
        "code_generation_activity_count",
        "loc_added_sum",
        "loc_suggested_to_add_sum"
    }, {
        "feature",
        "chat_user_initiated_interaction_count",
        "chat_code_acceptance_activity_count",
        "chat_code_generation_activity_count",
        "chat_loc_added_sum",
        "chat_loc_suggested_to_add_sum"
    }),
    Filtered = Table.SelectRows(Fields, each [feature] = "ide_chat"),
    Typed = Table.TransformColumnTypes(Filtered, {{"day", type date}})
in
    Typed

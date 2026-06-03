let
    // Depends on: source query (organization_metrics.pq or enterprise_metrics.pq)
    // One row per day for GitHub.com (dotcom) chat usage only.
    // totals_by_feature items have the same field names as day-level totals,
    // so they are renamed here with a "dotcom_chat_" prefix to avoid conflicts.
    Expanded = Table.ExpandListColumn(source, "totals_by_feature"),
    Fields = Table.ExpandRecordColumn(Expanded, "totals_by_feature",
        {
            "feature",
            "user_initiated_interaction_count",
            "code_acceptance_activity_count",
            "code_generation_activity_count",
            "loc_added_sum",
            "loc_suggested_to_add_sum"
        },
        {
            "feature",
            "dotcom_chat_user_initiated_interaction_count",
            "dotcom_chat_code_acceptance_activity_count",
            "dotcom_chat_code_generation_activity_count",
            "dotcom_chat_loc_added_sum",
            "dotcom_chat_loc_suggested_to_add_sum"
        }
    ),
    Filtered = Table.SelectRows(Fields, each [feature] = "dotcom_chat"),
    Typed = Table.TransformColumnTypes(Filtered, {{"day", type date}})
in
    Typed

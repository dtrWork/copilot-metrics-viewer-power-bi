let
    // Depends on: source.pq (or organization_metrics.pq / enterprise_metrics.pq)
    // One row per day for GitHub.com (dotcom) chat usage only.
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
        "dotcom_user_initiated_interaction_count",
        "dotcom_code_acceptance_activity_count",
        "dotcom_code_generation_activity_count",
        "dotcom_loc_added_sum",
        "dotcom_loc_suggested_to_add_sum"
    }),
    Filtered = Table.SelectRows(Fields, each [feature] = "dotcom_chat"),
    Typed = Table.TransformColumnTypes(Filtered, {{"day", type date}})
in
    Typed

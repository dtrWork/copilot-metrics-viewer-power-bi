let
    // Depends on: source query (organization_metrics.pq or enterprise_metrics.pq)
    // One row per day for GitHub.com (dotcom) chat usage only.
    // Column names use underscores (Power BI does not support dots in new column names).
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
            "dotcom_chat_interactions",
            "dotcom_chat_acceptance_count",
            "dotcom_chat_generation_count",
            "dotcom_chat_loc_added",
            "dotcom_chat_loc_suggested"
        }
    ),
    Filtered = Table.SelectRows(Fields, each [feature] = "dotcom_chat"),
    WithRate = Table.AddColumn(Filtered, "dotcom_chat_acceptance_rate",
        each if [dotcom_chat_generation_count] = null or [dotcom_chat_generation_count] = 0 then null
             else [dotcom_chat_acceptance_count] / [dotcom_chat_generation_count],
        type number),
    Typed = Table.TransformColumnTypes(WithRate, {{"day", type date}})
in
    Typed

let
    // Depends on: source query (organization_metrics.pq or enterprise_metrics.pq)
    // One row per day per model for IDE chat usage.
    // Column names use underscores (Power BI does not support dots in new column names).
    Expanded = Table.ExpandListColumn(source, "totals_by_model_feature"),
    Fields = Table.ExpandRecordColumn(Expanded, "totals_by_model_feature",
        {"model", "feature", "user_initiated_interaction_count", "code_acceptance_activity_count", "code_generation_activity_count"},
        {"model_name", "feature", "total_chats", "chat_acceptance_count", "chat_generation_count"}
    ),
    Filtered = Table.SelectRows(Fields, each [feature] = "ide_chat"),
    WithRate = Table.AddColumn(Filtered, "chat_acceptance_rate",
        each if [chat_generation_count] = null or [chat_generation_count] = 0 then null
             else [chat_acceptance_count] / [chat_generation_count],
        type number),
    Result = Table.SelectColumns(WithRate, {
        "day",
        "model_name",
        "total_chats",
        "chat_acceptance_count",
        "chat_acceptance_rate"
    }),
    Typed = Table.TransformColumnTypes(Result, {{"day", type date}})
in
    Typed

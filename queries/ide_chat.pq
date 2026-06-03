let
    // Depends on: source query (organization_metrics.pq or enterprise_metrics.pq)
    // One row per day per model for IDE chat usage.
    // Column names match the old PBIX schema so existing visuals keep working.
    // NOTE: "editors.models.name" = Copilot model name (new API has no per-editor breakdown).
    Expanded = Table.ExpandListColumn(source, "totals_by_model_feature"),
    Fields = Table.ExpandRecordColumn(Expanded, "totals_by_model_feature",
        {"model", "feature", "user_initiated_interaction_count", "code_acceptance_activity_count", "code_generation_activity_count"},
        {"editors.models.name", "feature", "editors.models.total_chats", "chat.acceptance.total", "chat_code_generation"}
    ),
    Filtered = Table.SelectRows(Fields, each [feature] = "ide_chat"),
    WithRate = Table.AddColumn(Filtered, "chat.acceptance.rate",
        each if [chat_code_generation] = null or [chat_code_generation] = 0 then null
             else [#"chat.acceptance.total"] / [chat_code_generation],
        type number),
    Renamed = Table.RenameColumns(WithRate, {{"day", "date"}}),
    Result = Table.SelectColumns(Renamed, {
        "date",
        "editors.models.name",
        "editors.models.total_chats",
        "chat.acceptance.total",
        "chat.acceptance.rate"
    }),
    Typed = Table.TransformColumnTypes(Result, {{"date", type date}})
in
    Typed

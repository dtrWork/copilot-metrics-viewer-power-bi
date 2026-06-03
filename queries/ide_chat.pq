let
    // Depends on: source query (organization_metrics.pq or enterprise_metrics.pq)
    // One row per day per model for IDE chat usage.
    // Column names match the old PBIX schema so existing visuals keep working.
    // NOTE: "editors.models.name" = Copilot model name (new API has no per-editor breakdown).
    // Use safe internal names during expansion to avoid "already exists" errors, then rename at the end.
    Expanded = Table.ExpandListColumn(source, "totals_by_model_feature"),
    Fields = Table.ExpandRecordColumn(Expanded, "totals_by_model_feature",
        {"model", "feature", "user_initiated_interaction_count", "code_acceptance_activity_count", "code_generation_activity_count"},
        {"_model_name", "_feature", "_total_chats", "_acceptance_count", "_generation_count"}
    ),
    Filtered = Table.SelectRows(Fields, each [_feature] = "ide_chat"),
    WithRate = Table.AddColumn(Filtered, "_acceptance_rate",
        each if [_generation_count] = null or [_generation_count] = 0 then null
             else [_acceptance_count] / [_generation_count],
        type number),
    // Rename to the old PBIX column names expected by existing visuals
    FinalNames = Table.RenameColumns(WithRate, {
        {"day", "date"},
        {"_model_name", "editors.models.name"},
        {"_total_chats", "editors.models.total_chats"},
        {"_acceptance_count", "chat.acceptance.total"},
        {"_acceptance_rate", "chat.acceptance.rate"}
    }),
    Result = Table.SelectColumns(FinalNames, {
        "date",
        "editors.models.name",
        "editors.models.total_chats",
        "chat.acceptance.total",
        "chat.acceptance.rate"
    }),
    Typed = Table.TransformColumnTypes(Result, {{"date", type date}})
in
    Typed

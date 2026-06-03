let
    // Depends on: source query (organization_metrics.pq or enterprise_metrics.pq)
    // Produces one row per day using OLD column names so existing PBIX visuals keep working.
    // Engagement columns (copilot_ide_chat.total_engaged_users, etc.) are extracted from
    // the totals_by_feature list and represented as interaction counts (best available proxy).

    // Helper: extract one field value from the totals_by_feature list for a given feature name.
    GetFeatureValue = (featureList as list, featureName as text, fieldName as text) =>
        let
            matching = List.Select(featureList, each _[feature] = featureName),
            rec = if List.Count(matching) > 0 then matching{0} else null,
            val = if rec <> null and Record.HasFields(rec, fieldName) then Record.Field(rec, fieldName) else null
        in val,

    // Base: one row per day; rename to old column names.
    Base = Table.SelectColumns(source, {
        "day",
        "daily_active_users",
        "monthly_active_users",
        "total_code_acceptance_activity_count",
        "total_code_generation_activity_count",
        "total_loc_added_sum",
        "total_loc_suggested_to_add_sum",
        "totals_by_feature",
        "pull_requests"
    }),
    Renamed = Table.RenameColumns(Base, {
        {"day", "date"},
        {"daily_active_users", "total_active_users"},
        {"monthly_active_users", "total_engaged_users"}
    }),

    // Per-feature engaged-user proxies (interaction counts) using dotted old column names.
    WithIdeChat = Table.AddColumn(Renamed, "copilot_ide_chat.total_engaged_users",
        each GetFeatureValue([totals_by_feature], "ide_chat", "user_initiated_interaction_count"),
        Int64.Type),
    WithIdeCode = Table.AddColumn(WithIdeChat, "copilot_ide_code_completions.total_engaged_users",
        each GetFeatureValue([totals_by_feature], "code_completion", "code_acceptance_activity_count"),
        Int64.Type),
    WithDotcomChat = Table.AddColumn(WithIdeCode, "copilot_dotcom_chat.total_engaged_users",
        each GetFeatureValue([totals_by_feature], "dotcom_chat", "user_initiated_interaction_count"),
        Int64.Type),
    WithPR = Table.AddColumn(WithDotcomChat, "copilot_dotcom_pull_requests.total_engaged_users",
        each if [pull_requests] <> null and Record.HasFields([pull_requests], "total_created")
             then [pull_requests][total_created] else null,
        Int64.Type),

    Result = Table.SelectColumns(WithPR, {
        "date",
        "total_active_users",
        "total_engaged_users",
        "copilot_ide_chat.total_engaged_users",
        "copilot_ide_code_completions.total_engaged_users",
        "copilot_dotcom_chat.total_engaged_users",
        "copilot_dotcom_pull_requests.total_engaged_users",
        "total_code_acceptance_activity_count",
        "total_code_generation_activity_count",
        "total_loc_added_sum",
        "total_loc_suggested_to_add_sum"
    }),
    Typed = Table.TransformColumnTypes(Result, {{"date", type date}})
in
    Typed

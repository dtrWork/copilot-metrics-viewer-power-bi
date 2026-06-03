let
    // Depends on: source query (organization_metrics.pq or enterprise_metrics.pq)
    // Produces one row per day with high-level engagement totals.
    // Column names use underscores (Power BI does not support dots in new column names).

    GetFeatureValue = (featureList as list, featureName as text, fieldName as text) =>
        let
            matching = List.Select(featureList, each _[feature] = featureName),
            rec = if List.Count(matching) > 0 then matching{0} else null,
            val = if rec <> null and Record.HasFields(rec, fieldName) then Record.Field(rec, fieldName) else null
        in val,

    Base = Table.SelectColumns(source, {
        "day",
        "daily_active_users",
        "monthly_active_users",
        "total_code_acceptance_activity_count",
        "total_code_generation_activity_count",
        "total_loc_added_sum",
        "total_loc_suggested_to_add_sum",
        "total_loc_deleted_sum",
        "totals_by_feature",
        "pull_requests"
    }),

    WithIdeChat = Table.AddColumn(Base, "ide_chat_interactions",
        each GetFeatureValue([totals_by_feature], "ide_chat", "user_initiated_interaction_count"),
        Int64.Type),
    WithIdeCode = Table.AddColumn(WithIdeChat, "code_completion_acceptances",
        each GetFeatureValue([totals_by_feature], "code_completion", "code_acceptance_activity_count"),
        Int64.Type),
    WithDotcomChat = Table.AddColumn(WithIdeCode, "dotcom_chat_interactions",
        each GetFeatureValue([totals_by_feature], "dotcom_chat", "user_initiated_interaction_count"),
        Int64.Type),
    WithPR = Table.AddColumn(WithDotcomChat, "pr_created",
        each if [pull_requests] <> null and Record.HasFields([pull_requests], "total_created")
             then [pull_requests][total_created] else null,
        Int64.Type),
    WithLocChanged = Table.AddColumn(WithPR, "total_loc_changed_sum",
        each
            let a = if [total_loc_added_sum] = null then 0 else [total_loc_added_sum],
                d = if [total_loc_deleted_sum] = null then 0 else [total_loc_deleted_sum]
            in a + d,
        Int64.Type),
    WithLineRate = Table.AddColumn(WithLocChanged, "line_acceptance_rate",
        each if [total_loc_suggested_to_add_sum] = null or [total_loc_suggested_to_add_sum] = 0 then null
             else [total_loc_added_sum] / [total_loc_suggested_to_add_sum],
        type number),

    Result = Table.SelectColumns(WithLineRate, {
        "day",
        "daily_active_users",
        "monthly_active_users",
        "total_code_acceptance_activity_count",
        "total_code_generation_activity_count",
        "total_loc_added_sum",
        "total_loc_suggested_to_add_sum",
        "total_loc_deleted_sum",
        "total_loc_changed_sum",
        "line_acceptance_rate",
        "ide_chat_interactions",
        "code_completion_acceptances",
        "dotcom_chat_interactions",
        "pr_created"
    }),
    Typed = Table.TransformColumnTypes(Result, {{"day", type date}})
in
    Typed

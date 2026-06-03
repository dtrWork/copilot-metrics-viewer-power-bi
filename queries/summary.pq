let
    // Depends on: source query (organization_metrics.pq or enterprise_metrics.pq)
    // One row per day with high-level engagement totals.
    // Fields from day_totals are prefixed "total_" in source to avoid name conflicts.
    Typed = Table.TransformColumnTypes(source, {{"day", type date}}),
    Result = Table.SelectColumns(Typed, {
        "day",
        "daily_active_users",
        "weekly_active_users",
        "monthly_active_users",
        "monthly_active_agent_users",
        "monthly_active_chat_users",
        "total_user_initiated_interaction_count",
        "total_code_acceptance_activity_count",
        "total_code_generation_activity_count",
        "total_loc_added_sum",
        "total_loc_suggested_to_add_sum"
    })
in
    Result

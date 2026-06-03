let
    // Depends on: source.pq (or organization_metrics.pq / enterprise_metrics.pq)
    // One row per day with high-level engagement totals.
    Typed = Table.TransformColumnTypes(source, {{"day", type date}}),
    Result = Table.SelectColumns(Typed, {
        "day",
        "daily_active_users",
        "weekly_active_users",
        "monthly_active_users",
        "user_initiated_interaction_count",
        "code_acceptance_activity_count",
        "code_generation_activity_count",
        "loc_added_sum",
        "loc_suggested_to_add_sum",
        "monthly_active_agent_users",
        "monthly_active_chat_users"
    })
in
    Result

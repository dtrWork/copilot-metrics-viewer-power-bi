let
    // Replace <YOUR-TOKEN> and <ENTERPRISE> with your actual token and enterprise slug.
    // Required token scopes: manage_billing:copilot or read:enterprise
    token = "<YOUR-TOKEN>",
    enterprise = "<ENTERPRISE>",

    url = "https://api.github.com/enterprises/" & enterprise & "/copilot/metrics/reports/enterprise-28-day/latest",
    headers = [
        #"Accept" = "application/vnd.github+json",
        #"Authorization" = "Bearer " & token,
        #"X-GitHub-Api-Version" = "2026-03-10"
    ],
    ApiResponse = Json.Document(Web.Contents(url, [Headers = headers])),
    DownloadLinks = ApiResponse[download_links],

    ParseNdjson = (link as text) =>
        let
            raw = Text.FromBinary(Web.Contents(link)),
            lines = Lines.FromText(raw),
            nonEmpty = List.Select(lines, each _ <> ""),
            records = List.Transform(nonEmpty, Json.Document)
        in records,

    AllRecords = List.Combine(List.Transform(DownloadLinks, ParseNdjson)),
    RawTable = Table.FromList(AllRecords, Splitter.SplitByNothing(), {"Record"}),
    TopLevel = Table.ExpandRecordColumn(RawTable, "Record",
        {"enterprise_id", "report_start_day", "report_end_day", "day_totals"}),
    DayRows = Table.ExpandListColumn(TopLevel, "day_totals"),

    // Expand day_totals fields. Conflicting field names (also present inside totals_by_* items)
    // are prefixed with "total_" to avoid "already exists" errors in downstream queries.
    Source = Table.ExpandRecordColumn(DayRows, "day_totals",
        {
            "day",
            "daily_active_users", "weekly_active_users", "monthly_active_users",
            "monthly_active_agent_users", "monthly_active_chat_users", "daily_active_cli_users",
            "user_initiated_interaction_count",
            "code_acceptance_activity_count", "code_generation_activity_count",
            "loc_added_sum", "loc_suggested_to_add_sum", "loc_deleted_sum",
            "pull_requests",
            "totals_by_ide", "totals_by_feature", "totals_by_language_feature", "totals_by_model_feature"
        },
        {
            "day",
            "daily_active_users", "weekly_active_users", "monthly_active_users",
            "monthly_active_agent_users", "monthly_active_chat_users", "daily_active_cli_users",
            "total_user_initiated_interaction_count",
            "total_code_acceptance_activity_count", "total_code_generation_activity_count",
            "total_loc_added_sum", "total_loc_suggested_to_add_sum", "total_loc_deleted_sum",
            "pull_requests",
            "totals_by_ide", "totals_by_feature", "totals_by_language_feature", "totals_by_model_feature"
        }
    )
in
    Source
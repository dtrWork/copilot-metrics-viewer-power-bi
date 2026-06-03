let
    // Replace <YOUR-TOKEN> and <ORG> with your actual token and organization name.
    // Required token scope: read:org
    token = "<YOUR-TOKEN>",
    org = "<ORG>",

    // Step 1: Get signed NDJSON download links from the new API.
    url = "https://api.github.com/orgs/" & org & "/copilot/metrics/reports/organization-28-day/latest",
    headers = [
        #"Accept" = "application/vnd.github+json",
        #"Authorization" = "Bearer " & token,
        #"X-GitHub-Api-Version" = "2026-03-10"
    ],
    ApiResponse = Json.Document(Web.Contents(url, [Headers = headers])),
    DownloadLinks = ApiResponse[download_links],

    // Step 2: Download and parse each NDJSON file (one JSON record per line).
    ParseNdjson = (link as text) =>
        let
            raw = Text.FromBinary(Web.Contents(link)),
            lines = Lines.FromText(raw),
            nonEmpty = List.Select(lines, each _ <> ""),
            records = List.Transform(nonEmpty, Json.Document)
        in records,

    AllRecords = List.Combine(List.Transform(DownloadLinks, ParseNdjson)),

    // Step 3: Flatten to one row per day.
    // Each NDJSON record has a top-level "day_totals" list (one entry per day)
    // plus metadata fields (organization_id, report_start_day, report_end_day).
    RawTable = Table.FromList(AllRecords, Splitter.SplitByNothing(), {"Record"}),
    TopLevel = Table.ExpandRecordColumn(RawTable, "Record",
        {"organization_id", "report_start_day", "report_end_day", "day_totals"}),
    DayRows = Table.ExpandListColumn(TopLevel, "day_totals"),
    Source = Table.ExpandRecordColumn(DayRows, "day_totals", {
        "day", "daily_active_users", "weekly_active_users", "monthly_active_users",
        "user_initiated_interaction_count", "code_acceptance_activity_count",
        "code_generation_activity_count", "loc_added_sum", "loc_suggested_to_add_sum",
        "loc_deleted_sum", "totals_by_ide", "totals_by_feature",
        "totals_by_language_feature", "totals_by_model_feature", "pull_requests",
        "monthly_active_agent_users", "monthly_active_chat_users", "daily_active_cli_users"
    })
in
    Source
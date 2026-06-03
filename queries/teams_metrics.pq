let
    // Replace <YOUR-TOKEN>, <ORG> and <DAY> (YYYY-MM-DD) with your actual values.
    // Required token scope: read:org
    // Reports are available from 2025-10-10 and for up to 1 year of history.
    //
    // NOTE: Team-level metrics are no longer pre-aggregated by GitHub.
    // This query fetches the user-teams membership report for a specific day.
    // Join these results with the organization_usage query (per-user metrics) to
    // compute team-level aggregations. See:
    // https://docs.github.com/en/enterprise-cloud@latest/copilot/reference/copilot-usage-metrics/team-level-metrics
    token = "<YOUR-TOKEN>",
    org = "<ORG>",
    day = "<DAY>",

    // Step 1: Call the new Copilot Usage Metrics API to obtain signed NDJSON download links.
    url = "https://api.github.com/orgs/" & org & "/copilot/metrics/reports/user-teams-1-day",
    headers = [
        #"Accept" = "application/vnd.github+json",
        #"Authorization" = "Bearer " & token,
        #"X-GitHub-Api-Version" = "2026-03-10"
    ],
    ApiResponse = Json.Document(Web.Contents(url, [Headers = headers, Query = [day = day]])),
    DownloadLinks = ApiResponse[download_links],

    // Step 2: Download each NDJSON file and parse every line as a JSON record.
    ParseNdjson = (link as text) =>
        let
            raw = Text.FromBinary(Web.Contents(link)),
            lines = Lines.FromText(raw),
            nonEmpty = List.Select(lines, each _ <> ""),
            records = List.Transform(nonEmpty, Json.Document)
        in
            records,

    AllRecords = List.Combine(List.Transform(DownloadLinks, ParseNdjson)),
    Source = Table.FromList(AllRecords, Splitter.SplitByNothing(), {"Record"}),
    ExpandedSource = Table.ExpandRecordColumn(Source, "Record", Record.FieldNames(Source{0}[Record]))
in
    ExpandedSource
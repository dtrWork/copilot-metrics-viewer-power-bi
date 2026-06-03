let
    // Replace <YOUR-TOKEN> and <ENTERPRISE> with your actual token and enterprise slug.
    // Required token scopes: manage_billing:copilot or read:enterprise
    // This query replaces the deprecated /copilot/usage endpoint.
    // It retrieves the latest 28-day per-user Copilot metrics for the enterprise.
    token = "<YOUR-TOKEN>",
    enterprise = "<ENTERPRISE>",

    // Step 1: Call the new Copilot Usage Metrics API to obtain signed NDJSON download links.
    url = "https://api.github.com/enterprises/" & enterprise & "/copilot/metrics/reports/users-28-day/latest",
    headers = [
        #"Accept" = "application/vnd.github+json",
        #"Authorization" = "Bearer " & token,
        #"X-GitHub-Api-Version" = "2026-03-10"
    ],
    ApiResponse = Json.Document(Web.Contents(url, [Headers = headers])),
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
let
    // Replace <YOUR-TOKEN> and <ORG> with your actual token and organization name.
    // Required token scope: read:org
    // The Copilot Usage Metrics policy must be enabled in your organization settings.
    token = "<YOUR-TOKEN>",
    org = "<ORG>",

    // Step 1: Call the new Copilot Usage Metrics API to obtain signed NDJSON download links.
    // Returns the latest 28-day aggregated organization metrics report.
    url = "https://api.github.com/orgs/" & org & "/copilot/metrics/reports/organization-28-day/latest",
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
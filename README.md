# GitHub Copilot Metrics Viewer for Power BI

With the release of the [GitHub Copilot Usage Metrics API](https://docs.github.com/en/enterprise-cloud@latest/rest/copilot/copilot-usage-metrics?apiVersion=2026-03-10) many teams are looking to leverage this data to help monitor usage against their KPIs. For some, the Copilot Metrics Viewer ([github-copilot-resources/copilot-metrics-viewer](https://github.com/github-copilot-resources/copilot-metrics-viewer)) might be a great option. 

However, many organizations that we work with already have established Power BI teams. If your organization is **already using Power BI, please read on!**

> **⚠️ API Migration Notice:** The legacy `/copilot/metrics` and `/copilot/usage` endpoints are deprecated. This project now uses the **Copilot Usage Metrics API** (`apiVersion=2026-03-10`). See the [endpoint mapping table](#endpoint-mapping) below for details.

## Table of Contents
- [Endpoint Mapping](#endpoint-mapping)
- [Metrics Dashboard Setup](#metrics-dashboard-setup)
  - [Connect to Metrics API](#connect-to-metrics-api)
  - [Connect to local JSON data source](#connect-to-local-json-data-source)
- [Collect Feedback on GitHub Copilot Usage](#collect-feedback-on-github-copilot-usage)
- [KPI - Savings Dashboard](#kpi---savings-dashboard)
- [Publishing](#publishing)
- [Maintainers](#maintainers)
- [Support](#support)

## Endpoint Mapping

The new API returns **signed download links** to NDJSON files instead of JSON directly. The Power Query code handles this two-step retrieval automatically.

| Query file | Old endpoint (deprecated) | New endpoint (2026-03-10) |
|:-----------|:--------------------------|:--------------------------|
| `enterprise_metrics.pq` | `GET /enterprises/{e}/copilot/metrics` | `GET /enterprises/{e}/copilot/metrics/reports/enterprise-28-day/latest` |
| `enterprise_usage.pq` | `GET /enterprises/{e}/copilot/usage` | `GET /enterprises/{e}/copilot/metrics/reports/users-28-day/latest` |
| `enterprise_team_metrics.pq` | `GET /enterprises/{e}/team/{t}/copilot/metrics` | `GET /enterprises/{e}/copilot/metrics/reports/user-teams-1-day?day=YYYY-MM-DD` ¹ |
| `organization_metrics.pq` | `GET /orgs/{o}/copilot/metrics` | `GET /orgs/{o}/copilot/metrics/reports/organization-28-day/latest` |
| `organization_usage.pq` | `GET /orgs/{o}/copilot/usage` | `GET /orgs/{o}/copilot/metrics/reports/users-28-day/latest` |
| `teams_metrics.pq` | `GET /orgs/{o}/team/{t}/copilot/metrics` | `GET /orgs/{o}/copilot/metrics/reports/user-teams-1-day?day=YYYY-MM-DD` ¹ |

> ¹ Team-level metrics are no longer pre-aggregated. Join the `user-teams-1-day` report with the per-user metrics report to construct team-level aggregations. See [Team-level Copilot usage metrics](https://docs.github.com/en/enterprise-cloud@latest/copilot/reference/copilot-usage-metrics/team-level-metrics).

## Metrics Dashboard Setup

Located in the `./samples` directory you'll find sample JSON and PBIX files used to create the dashboard below.

![Image of the Power BI dashboard with sample GitHub Copilot Metrics API data displayed.](./assets/Sample_Metrics_PBI.png)

### Connect to Metrics API

> **Notes:**
> - The REST API provides metrics for the previous 28 days, refreshed daily.
> - Reports are available from **2025-10-10** and for up to **1 year** of history.
> - The **Copilot usage metrics** policy must be set to **Enabled everywhere** in your [enterprise](https://docs.github.com/en/enterprise-cloud@latest/copilot/managing-copilot/managing-copilot-for-your-enterprise/managing-policies-and-features-for-copilot-in-your-enterprise) or [organization](https://docs.github.com/en/enterprise-cloud@latest/copilot/managing-copilot/managing-github-copilot-in-your-organization/managing-policies-for-copilot-in-your-organization) settings.

In order to connect we'll need to generate a token and link to your metrics data:
1. Download and open the sample `GitHub Copilot - Telemetry Sample (Metrics with KPI).pbix` file.
2. Determine if you'll be using the `Enterprise` or `Organization` scope.
3. Generate a token with the required permissions:
   - **Enterprise**: classic PAT with `manage_billing:copilot` or `read:enterprise` scope.
   - **Organization**: classic PAT with `read:org` scope.
   - See [REST API endpoints for Copilot usage metrics](https://docs.github.com/en/enterprise-cloud@latest/rest/copilot/copilot-usage-metrics?apiVersion=2026-03-10) for fine-grained token options.

> **IMPORTANT: Do not share this token and ensure you follow your organization's security policies.**

> **SAML SSO:** If your organization enforces SAML Single Sign-On, you must also authorize the token for that organization after creating it:
> 1. Go to **GitHub.com → Settings → Developer settings → Personal access tokens**
> 2. Find the token you just created and click **"Configure SSO"**
> 3. Click **"Authorize"** next to your organization name and complete the SSO login
>
> Without this step, API calls will return a `403` error even with correct scopes.

4. The file contains the following data sources:

    | Name                               | Description                                                   |
    | :--------------------------------- | :------------------------------------------------------------ |
    | config                             | Configuration used to display date of refresh and KPI dashboard |
    | source                             | Base source used to connect to the API or local JSON files.   |
    | GH Copilot - dotcom chat           | Detailed metrics for chat on GitHub.com.                      |
    | GH Copilot - ide chat              | Detailed metrics for chat within the IDE.                     |
    | GH Copilot - ide code completions editors  | Detailed metrics for code completions in the IDE.      |
    | GH Copilot - ide code completions languages  | Engaged users by language in the IDE.                |
    | GH Copilot - pull requests         | Detailed metrics for pull requests.                           |
    | GH Copilot - summary               | Daily summary of active and engaged users.                    |

5. Open the **Power Query Editor** by clicking **Transform data** in the top menu.
6. Click on **source** in the left panel and select **Advanced editor**.
   ![Image of Power Query Advanced Editor.](./assets/Advanced_editor.png)
7. Replace the entire query with one of the following blocks, substituting the placeholder values.

> **How it works:** The new API returns signed download URLs (NDJSON files) instead of JSON directly. The query automatically fetches those links and downloads + parses every line into a table row.

**Enterprise (28-day aggregated)**
```powerquery
let
    // Replace <YOUR-TOKEN> and <ENTERPRISE> with your actual token and enterprise slug.
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
    Source = Table.FromList(AllRecords, Splitter.SplitByNothing(), {"Record"}),
    ExpandedSource = Table.ExpandRecordColumn(Source, "Record", Record.FieldNames(Source{0}[Record]))
in
    ExpandedSource
```

**Enterprise per-user (28-day)**
```powerquery
let
    // Replace <YOUR-TOKEN> and <ENTERPRISE> with your actual token and enterprise slug.
    token = "<YOUR-TOKEN>",
    enterprise = "<ENTERPRISE>",

    url = "https://api.github.com/enterprises/" & enterprise & "/copilot/metrics/reports/users-28-day/latest",
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
    Source = Table.FromList(AllRecords, Splitter.SplitByNothing(), {"Record"}),
    ExpandedSource = Table.ExpandRecordColumn(Source, "Record", Record.FieldNames(Source{0}[Record]))
in
    ExpandedSource
```

**Organization (28-day aggregated)**
```powerquery
let
    // Replace <YOUR-TOKEN> and <ORG> with your actual token and organization name.
    token = "<YOUR-TOKEN>",
    org = "<ORG>",

    url = "https://api.github.com/orgs/" & org & "/copilot/metrics/reports/organization-28-day/latest",
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
    Source = Table.FromList(AllRecords, Splitter.SplitByNothing(), {"Record"}),
    ExpandedSource = Table.ExpandRecordColumn(Source, "Record", Record.FieldNames(Source{0}[Record]))
in
    ExpandedSource
```

**Organization per-user (28-day)**
```powerquery
let
    // Replace <YOUR-TOKEN> and <ORG> with your actual token and organization name.
    token = "<YOUR-TOKEN>",
    org = "<ORG>",

    url = "https://api.github.com/orgs/" & org & "/copilot/metrics/reports/users-28-day/latest",
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
    Source = Table.FromList(AllRecords, Splitter.SplitByNothing(), {"Record"}),
    ExpandedSource = Table.ExpandRecordColumn(Source, "Record", Record.FieldNames(Source{0}[Record]))
in
    ExpandedSource
```

**Team-level (user-teams membership for a specific day)**
> Join with the per-user query above to compute team-level aggregations.
```powerquery
let
    // Replace <YOUR-TOKEN>, <ORG> and <DAY> (YYYY-MM-DD) with your actual values.
    token = "<YOUR-TOKEN>",
    org = "<ORG>",
    day = "2025-10-15",

    url = "https://api.github.com/orgs/" & org & "/copilot/metrics/reports/user-teams-1-day",
    headers = [
        #"Accept" = "application/vnd.github+json",
        #"Authorization" = "Bearer " & token,
        #"X-GitHub-Api-Version" = "2026-03-10"
    ],
    ApiResponse = Json.Document(Web.Contents(url, [Headers = headers, Query = [day = day]])),
    DownloadLinks = ApiResponse[download_links],

    ParseNdjson = (link as text) =>
        let
            raw = Text.FromBinary(Web.Contents(link)),
            lines = Lines.FromText(raw),
            nonEmpty = List.Select(lines, each _ <> ""),
            records = List.Transform(nonEmpty, Json.Document)
        in records,

    AllRecords = List.Combine(List.Transform(DownloadLinks, ParseNdjson)),
    Source = Table.FromList(AllRecords, Splitter.SplitByNothing(), {"Record"}),
    ExpandedSource = Table.ExpandRecordColumn(Source, "Record", Record.FieldNames(Source{0}[Record]))
in
    ExpandedSource
```

8. Click **OK** to close the Advanced editor and select `Anonymous` authentication if prompted.
   ![Image of Power Query Advanced Editor.](./assets/Advanced_editor_metrics_query.png)
9. Click **Close and Apply** in the top-left of the **Power Query Editor**.
10. On the **Report View** page click **Refresh** to load the new data into your dashboard.

### Connect to local JSON data source
> Note: This example provides a proof of concept for loading metrics data and requires an exported JSON file. If you have access to the REST API you can configure the **source** query accordingly.

1. Download and open the sample `GitHub Copilot - Telemetry Sample (Metrics with KPIs).pbix` file.
2. Open the **Power Query Editor** by clicking **Transform data** in the top menu.
3. Click on **source** query in the left panel.
4. In the right panel under **APPLIED STEPS**, click the gear (settings) icon, select your JSON file and click **OK**.
   ![Image of a data source selector in Power Query Editor.](./assets/Modify_JSON_source.png)
5. Click **Close and Apply** in the top-left of the **Power Query Editor**.
6. On the **Report View** page click **Refresh** to load the new data into your dashboard.
7. **Happy Customizing!**

## Collect Feedback on GitHub Copilot Usage

To better understand how GitHub Copilot is being used in your organization and to help determine accurate time and cost savings, we recommend collecting direct feedback from your developers. This information can be used to refine the values in the KPI dashboard and ensure your savings estimates reflect real-world usage.

You can use the following **Microsoft Forms** template to gather feedback. Simply duplicate the form and customize it for your organization:

[GitHub Copilot Usage Feedback – Microsoft Forms Template](https://forms.office.com/Pages/ShareFormPage.aspx?id=v4j5cvGGr0GRqy180BHbR6zql0pB1xhIi5wwWWSq6RVUQ0JQSkZOMElYOFdHWUFWWVhPRllTQ1ZRUi4u&sharetoken=Gb49retb5qghvCQiQILO)

Gathering this feedback will help you:
- Validate or adjust the average weekly hour savings.
- Understand adoption and satisfaction.
- Support your ROI calculations with real user data.

Feel free to adapt the form to include any additional questions relevant to your team.

## KPI - Savings Dashboard
A new KPI tab has been added to the dashboard to help you estimate savings. The KPI tab is configured to display the potential time and cost savings. You can configure the KPI tab to display these details by modifying the following fields in the `config` data source from the **Table view**:

| Name                       | Description                                      |
| :------------------------- | :----------------------------------------------- |
| total_devs                 | Total number of developers at your organization. |
| avg_hourly_salary          | Average hourly salary of developers.             |
| annual_work_weeks          | Total number of work weeks in a year.            |
| average_weekly_hour_savings| Average number of hours developers saved per week. The default is 3.5 hours and assumed a 10% time saving, but this can be updated based on customer survey data or other measurements. |

These values can be modified in the `config` data source below:
![Image of the KPI config table in the Power BI.](./assets/KPI_config.png)

Once configured, the KPI dashboard will display this potential savings against current usage pulled from the Metrics API:
![Image of the KPI tab in the Power BI.](./assets/Sample_KPI_PBI.png)


## Publishing
If you need help deploying or publishing this script, please see: [Publish README](/publish/README.md)

## Maintainers

@jasonmoodie, @Eldrick19

## Support

These are just files for you to download and use as you see fit. If you have questions about how to use them, please reach out to the maintainers, but we cannot guarantee a response with SLAs.
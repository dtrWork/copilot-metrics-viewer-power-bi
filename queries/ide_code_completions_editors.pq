let
    // Depends on: source query (organization_metrics.pq or enterprise_metrics.pq)
    // One row per day per language for code completion usage.
    // Column names use underscores (Power BI does not support dots in new column names).
    Expanded = Table.ExpandListColumn(source, "totals_by_language_feature"),
    Fields = Table.ExpandRecordColumn(Expanded, "totals_by_language_feature",
        {
            "language",
            "feature",
            "code_acceptance_activity_count",
            "code_generation_activity_count",
            "loc_added_sum",
            "loc_suggested_to_add_sum"
        },
        {
            "language_name",
            "feature",
            "code_acceptance_count",
            "code_generation_count",
            "lines_accepted",
            "lines_suggested"
        }
    ),
    Filtered = Table.SelectRows(Fields, each [feature] = "code_completion"),
    WithCodeRate = Table.AddColumn(Filtered, "code_acceptance_rate",
        each if [code_generation_count] = null or [code_generation_count] = 0 then null
             else [code_acceptance_count] / [code_generation_count],
        type number),
    WithLineRate = Table.AddColumn(WithCodeRate, "line_acceptance_rate",
        each if [lines_suggested] = null or [lines_suggested] = 0 then null
             else [lines_accepted] / [lines_suggested],
        type number),
    Result = Table.SelectColumns(WithLineRate, {
        "day",
        "language_name",
        "code_acceptance_count",
        "code_generation_count",
        "lines_accepted",
        "lines_suggested",
        "code_acceptance_rate",
        "line_acceptance_rate"
    }),
    Typed = Table.TransformColumnTypes(Result, {{"day", type date}})
in
    Typed

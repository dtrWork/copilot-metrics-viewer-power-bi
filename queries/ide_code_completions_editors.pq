let
    // Depends on: source query (organization_metrics.pq or enterprise_metrics.pq)
    // One row per day per language for code completion usage.
    // Column names match the old PBIX schema (editors.models.languages.*) so existing visuals keep working.
    // NOTE: The new API does not provide an ide × model × language cross product.
    //       "editors.name" and "editors.models.name" are set to null (no per-IDE language breakdown available).
    //       Visuals that slice by language (editors.models.languages.name) will work correctly.
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
            "editors.models.languages.name",
            "feature",
            "editors.models.languages.total_code_acceptances",
            "editors.models.languages.total_code_suggestion",
            "editors.models.languages.total_code_lines_accepted",
            "editors.models.languages.total_code_lines_suggested"
        }
    ),
    Filtered = Table.SelectRows(Fields, each [feature] = "code_completion"),
    WithRate = Table.AddColumn(Filtered, "code.acceptance.rate",
        each if [#"editors.models.languages.total_code_suggestion"] = null or [#"editors.models.languages.total_code_suggestion"] = 0 then null
             else [#"editors.models.languages.total_code_acceptances"] / [#"editors.models.languages.total_code_suggestion"],
        type number),
    WithLineRate = Table.AddColumn(WithRate, "line.acceptance.rate",
        each if [#"editors.models.languages.total_code_lines_suggested"] = null or [#"editors.models.languages.total_code_lines_suggested"] = 0 then null
             else [#"editors.models.languages.total_code_lines_accepted"] / [#"editors.models.languages.total_code_lines_suggested"],
        type number),
    WithEditor = Table.AddColumn(WithLineRate, "editors.name", each null, type text),
    WithModel = Table.AddColumn(WithEditor, "editors.models.name", each null, type text),
    Renamed = Table.RenameColumns(WithModel, {{"day", "date"}}),
    Result = Table.SelectColumns(Renamed, {
        "date",
        "editors.name",
        "editors.models.name",
        "editors.models.languages.name",
        "editors.models.languages.total_code_acceptances",
        "editors.models.languages.total_code_suggestion",
        "editors.models.languages.total_code_lines_accepted",
        "editors.models.languages.total_code_lines_suggested",
        "code.acceptance.rate",
        "line.acceptance.rate"
    }),
    Typed = Table.TransformColumnTypes(Result, {{"date", type date}})
in
    Typed

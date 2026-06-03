let
    // Depends on: source query (organization_metrics.pq or enterprise_metrics.pq)
    // One row per day per language for code completion usage.
    // Column names match the old PBIX schema (editors.models.languages.*) so existing visuals keep working.
    // NOTE: The new API does not provide an ide × model × language cross product.
    //       "editors.name" and "editors.models.name" are set to null (no per-IDE language breakdown available).
    // Use safe internal names during expansion, rename to dotted names at the end.
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
            "_language",
            "_feature",
            "_acceptance_count",
            "_generation_count",
            "_lines_accepted",
            "_lines_suggested"
        }
    ),
    Filtered = Table.SelectRows(Fields, each [_feature] = "code_completion"),
    WithCodeRate = Table.AddColumn(Filtered, "_code_acceptance_rate",
        each if [_generation_count] = null or [_generation_count] = 0 then null
             else [_acceptance_count] / [_generation_count],
        type number),
    WithLineRate = Table.AddColumn(WithCodeRate, "_line_acceptance_rate",
        each if [_lines_suggested] = null or [_lines_suggested] = 0 then null
             else [_lines_accepted] / [_lines_suggested],
        type number),
    WithEditor = Table.AddColumn(WithLineRate, "_editor_name", each null, type text),
    WithModel = Table.AddColumn(WithEditor, "_model_name", each null, type text),
    // Rename to the old PBIX column names expected by existing visuals
    FinalNames = Table.RenameColumns(WithModel, {
        {"day", "date"},
        {"_language", "editors.models.languages.name"},
        {"_acceptance_count", "editors.models.languages.total_code_acceptances"},
        {"_generation_count", "editors.models.languages.total_code_suggestion"},
        {"_lines_accepted", "editors.models.languages.total_code_lines_accepted"},
        {"_lines_suggested", "editors.models.languages.total_code_lines_suggested"},
        {"_code_acceptance_rate", "code.acceptance.rate"},
        {"_line_acceptance_rate", "line.acceptance.rate"},
        {"_editor_name", "editors.name"},
        {"_model_name", "editors.models.name"}
    }),
    Result = Table.SelectColumns(FinalNames, {
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

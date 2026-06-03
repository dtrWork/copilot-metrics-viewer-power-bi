let
    // Depends on: source query (organization_metrics.pq or enterprise_metrics.pq)
    // One row per day per IDE for code completion (vscode, jetbrains, vim, etc.).
    // Use this query when you want to build visuals that break down by editor/IDE.
    // The old "GH Copilot - ide code completions editors" table now uses language
    // as the primary dimension; use THIS table for editor-level breakdowns instead.
    Expanded = Table.ExpandListColumn(source, "totals_by_ide"),
    Fields = Table.ExpandRecordColumn(Expanded, "totals_by_ide",
        {
            "ide",
            "code_acceptance_activity_count",
            "code_generation_activity_count",
            "loc_added_sum",
            "loc_suggested_to_add_sum",
            "loc_deleted_sum"
        },
        {
            "ide",
            "ide_code_acceptance_activity_count",
            "ide_code_generation_activity_count",
            "ide_loc_added_sum",
            "ide_loc_suggested_to_add_sum",
            "ide_loc_deleted_sum"
        }
    ),
    WithCodeRate = Table.AddColumn(Fields, "ide_code_acceptance_rate",
        each if [ide_code_generation_activity_count] = null or [ide_code_generation_activity_count] = 0 then null
             else [ide_code_acceptance_activity_count] / [ide_code_generation_activity_count],
        type number),
    WithLineRate = Table.AddColumn(WithCodeRate, "ide_line_acceptance_rate",
        each if [ide_loc_suggested_to_add_sum] = null or [ide_loc_suggested_to_add_sum] = 0 then null
             else [ide_loc_added_sum] / [ide_loc_suggested_to_add_sum],
        type number),
    Renamed = Table.RenameColumns(WithLineRate, {{"day", "date"}}),
    Typed = Table.TransformColumnTypes(Renamed, {{"date", type date}})
in
    Typed

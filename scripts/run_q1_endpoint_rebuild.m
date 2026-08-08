%RUN_Q1_ENDPOINT_REBUILD Independent one-row/two-endpoint Q1 experiment.

clearvars;
close all;
scriptPath = mfilename('fullpath');
projectRoot = fileparts(fileparts(scriptPath));
addpath(projectRoot);
projectRoot = setup_project();

cfg.L = 10000;
cfg.HALF_L = 5000;
cfg.mediumALength = 5000;
cfg.mediumARadius = 30;
cfg.conductionDistance = 1.8;
cfg.broadPhaseDistance = 61.8;
cfg.endpointLengthTolerance = 1e-3;
cfg.lengthTolerance = cfg.endpointLengthTolerance;
cfg.geometryTolerance = 1e-6;
cfg.gjkTolerance = 1e-8;
cfg.gjkMaxIterations = 100;

outputDir = fullfile(projectRoot, 'output', 'Q1_endpoint_rebuild');
figureDir = fullfile(outputDir, 'figures');
tableDir = fullfile(outputDir, 'tables');
logDir = fullfile(outputDir, 'logs');
directories = {outputDir, figureDir, tableDir, logDir};
for index = 1:numel(directories)
    if exist(directories{index}, 'dir') ~= 7, mkdir(directories{index}); end
end
cleanupPatterns = {fullfile(figureDir, '*.png'), ...
    fullfile(figureDir, '*.fig'), fullfile(tableDir, '*.csv')};
for patternIndex = 1:numel(cleanupPatterns)
    files = dir(cleanupPatterns{patternIndex});
    parent = fileparts(cleanupPatterns{patternIndex});
    for fileIndex = 1:numel(files)
        delete(fullfile(parent, files(fileIndex).name));
    end
end

[~, branchName] = system('git branch --show-current');
branchName = strtrim(branchName);
baseCommit = 'd9b4517063b9f499d71f7b5efbe60f81dd6bf6a5';
if ~strcmp(branchName, 'q1-endpoint-unfold-final')
    error('run_q1_endpoint_rebuild:WrongBranch', ...
        'Run only on q1-endpoint-unfold-final, current=%s.', branchName);
end

fprintf('[1/14] Setup complete on %s.\n', branchName);
excelPath = fullfile(projectRoot, 'data', 'attachment.xlsx');
fprintf('[2/14] Reading attachment.xlsx...\n');
groups = loadGroupData(excelPath);
expectedCounts = [12 49 535];
actualCounts = zeros(1, numel(groups));
for groupIndex = 1:numel(groups)
    actualCounts(groupIndex) = numel(groups(groupIndex).RecordID);
end
assert(numel(groups) == 3 && isequal(actualCounts, expectedCounts), ...
    'Attachment record counts do not equal [12 49 535].');

fprintf('[3/14] Validating Excel schema...\n');
schemaLog = fullfile(logDir, 'excel_schema_audit.txt');
writeExcelSchemaAudit(excelPath, groups, schemaLog);
analyses = cell(1, 3);
for groupIndex = 1:3
    analyses{groupIndex} = analyzeGroupData(groups(groupIndex), cfg);
end

fprintf('[4/14] Running endpoint reverse tests...\n');
[endpointPassed, endpointLines] = testEndpointReverseReconstruction();
fprintf('[5/14] Endpoint 729/27 artificial consistency is included above.\n');
fprintf('[6/14] Running 1/2/3/4 Piece boundary tests...\n');
[boundaryPassed, boundaryLines] = testBoundaryPieceCounts();
[fourPiecePassed, fourPieceLines] = testFourPieceMultiBoundary();
fprintf('[7/14] Running segment and GJK tests...\n');
[segmentPassed, segmentLines] = testSegmentSegmentDistance();
[gjkPassed, gjkLines] = testGJKCylinderDistance( ...
    fullfile(logDir, 'gjk_test_details.txt'));
fprintf('[8/14] Running Charged/Connected graph tests...\n');
[sameMediumPassed, sameMediumLines] = testSameMediumDoesNotCreateConductEdge();
[chargePassed, chargeLines] = testThreePieceChargeInheritance();
[bridgePassed, bridgeLines] = testSplitMediumBridgePath();
[insulatingPassed, insulatingLines] = testInsulatingFaceDoesNotDirectlyCharge();
[periodicPassed, periodicLines] = testNoGlobalPeriodicFalseEdge();

testLines = [{sprintf('Excel schema PASS=1')}; endpointLines(:); ...
    boundaryLines(:); fourPieceLines(:); segmentLines(:); gjkLines(:); ...
    sameMediumLines(:); chargeLines(:); bridgeLines(:); ...
    insulatingLines(:); periodicLines(:)];
testPath = fullfile(logDir, 'q1_endpoint_test_results.txt');
fileID = fopen(testPath, 'w');
if fileID < 0, error('Cannot write endpoint test log.'); end
for index = 1:numel(testLines)
    fprintf(1, '%s\n', testLines{index});
    fprintf(fileID, '%s\r\n', testLines{index});
end
fclose(fileID);
allTestsPassed = endpointPassed && boundaryPassed && fourPiecePassed && ...
    segmentPassed && gjkPassed && sameMediumPassed && chargePassed && ...
    bridgePassed && insulatingPassed && periodicPassed;
assert(allTestsPassed, 'A core endpoint/geometry/electrical test failed.');

fprintf('[9/14] Processing all 596 rows with both 27 and 729 searches...\n');
relativeResults = cell(1, 3);
explicitResults = cell(1, 3);
consistencyByGroup = cell(1, 3);
for groupIndex = 1:3
    recordCount = analyses{groupIndex}.Records;
    relativeResults{groupIndex} = cell(recordCount, 1);
    explicitResults{groupIndex} = cell(recordCount, 1);
    consistencyByGroup{groupIndex} = false(recordCount, 1);
    for mediumID = 1:recordCount
        p1 = groups(groupIndex).P1(mediumID, :);
        p2 = groups(groupIndex).P2(mediumID, :);
        relative = unwrapMediumEndpoints(p1, p2, cfg);
        explicit = enumerateEndpointImagePairs(p1, p2, cfg);
        equivalent = sameWrappedGeometrySets(relative.WrappedPieces, ...
            explicit.PhysicalGeometries, cfg.geometryTolerance);
        relativeResults{groupIndex}{mediumID} = relative;
        explicitResults{groupIndex}{mediumID} = explicit;
        consistencyByGroup{groupIndex}(mediumID) = equivalent;
    end
    fprintf('  Group%d processed: %d/%d.\n', groupIndex, recordCount, recordCount);
end
consistencyPassCount = sum(cellfun(@sum, consistencyByGroup));

fprintf('[10/14] Running tolerance sensitivity...\n');
tolerances = [1e-6 1e-4 1e-3 1e-2];
sensitivityRows = repmat(struct('Group', 0, 'Tolerance', 0, ...
    'Unique', 0, 'AmbiguousPeriodic', 0, 'Unresolved', 0), 12, 1);
rowIndex = 0;
for toleranceIndex = 1:numel(tolerances)
    sensitivityCfg = cfg;
    sensitivityCfg.endpointLengthTolerance = tolerances(toleranceIndex);
    for groupIndex = 1:3
        statuses = cell(analyses{groupIndex}.Records, 1);
        for mediumID = 1:analyses{groupIndex}.Records
            item = unwrapMediumEndpoints(groups(groupIndex).P1(mediumID, :), ...
                groups(groupIndex).P2(mediumID, :), sensitivityCfg);
            statuses{mediumID} = item.Status;
        end
        rowIndex = rowIndex + 1;
        sensitivityRows(rowIndex).Group = groupIndex;
        sensitivityRows(rowIndex).Tolerance = tolerances(toleranceIndex);
        sensitivityRows(rowIndex).Unique = sum(strcmp(statuses, 'UNIQUE'));
        sensitivityRows(rowIndex).AmbiguousPeriodic = ...
            sum(strcmp(statuses, 'AMBIGUOUS_PERIODIC'));
        sensitivityRows(rowIndex).Unresolved = sum(strcmp(statuses, 'UNRESOLVED'));
    end
end

fprintf('[11/14] Building UNIQUE endpoint GeometryPieces...\n');
emptyStats = struct('Records', 0, 'Raw5000', 0, 'Unique', 0, ...
    'AmbiguousPeriodic', 0, 'Unresolved', 0, ...
    'ShiftTypeCounts', zeros(1, 4), ...
    'PieceCountByMedium', zeros(1, 4), 'TotalPieces', 0);
groupStats = repmat(emptyStats, 1, 3);
piecesByGroup = cell(1, 3);
for groupIndex = 1:3
    stats = emptyStats;
    stats.Records = analyses{groupIndex}.Records;
    stats.Raw5000 = sum(abs(analyses{groupIndex}.SegmentLength - ...
        cfg.mediumALength) <= cfg.endpointLengthTolerance);
    for mediumID = 1:stats.Records
        item = relativeResults{groupIndex}{mediumID};
        if strcmp(item.Status, 'UNIQUE')
            stats.Unique = stats.Unique + 1;
            selected = item.SelectedIndex;
            shiftAxes = sum(item.CandidatesK(selected, :) ~= 0);
            stats.ShiftTypeCounts(shiftAxes + 1) = ...
                stats.ShiftTypeCounts(shiftAxes + 1) + 1;
            pieceCount = item.PieceCount(selected);
            stats.PieceCountByMedium(pieceCount) = ...
                stats.PieceCountByMedium(pieceCount) + 1;
        elseif strcmp(item.Status, 'AMBIGUOUS_PERIODIC')
            stats.AmbiguousPeriodic = stats.AmbiguousPeriodic + 1;
        else
            stats.Unresolved = stats.Unresolved + 1;
        end
    end
    piecesByGroup{groupIndex} = buildReconstructedPieces(groupIndex, ...
        groups(groupIndex), relativeResults{groupIndex}, cfg);
    stats.TotalPieces = numel(piecesByGroup{groupIndex}.MediumID);
    groupStats(groupIndex) = stats;
end

fprintf('[12/14] Writing complete endpoint diagnostics...\n');
writeEndpointRebuildTables(groups, analyses, relativeResults, ...
    explicitResults, consistencyByGroup, sensitivityRows, ...
    piecesByGroup, tableDir);
if consistencyPassCount ~= 596
    error('run_q1_endpoint_rebuild:ENDPOINT_ENUMERATION_INCONSISTENT', ...
        'Only %d/596 records agree between 729 and 27 searches.', ...
        consistencyPassCount);
end

fprintf('[13/14] Applying endpoint completeness hard gate...\n');
endpointComplete = sum([groupStats.Unique]) == 596 && ...
    sum([groupStats.AmbiguousPeriodic]) == 0 && ...
    sum([groupStats.Unresolved]) == 0;
graphs = cell(1, 3);
charges = cell(1, 3);
if endpointComplete
    for groupIndex = 1:3
        graphs{groupIndex} = buildPieceConductGraph(piecesByGroup{groupIndex}, cfg);
        charges{groupIndex} = computeChargeState(piecesByGroup{groupIndex}, ...
            graphs{groupIndex}.GeometryEdges, graphs{groupIndex}.LeftContact, ...
            graphs{groupIndex}.RightContact);
        groupStats(groupIndex).PhysicalEdgeCount = ...
            size(graphs{groupIndex}.GeometryEdges, 1);
        groupStats(groupIndex).LeftContactPieces = ...
            sum(graphs{groupIndex}.LeftContact);
        groupStats(groupIndex).RightContactPieces = ...
            sum(graphs{groupIndex}.RightContact);
        groupStats(groupIndex).ChargedMediumCount = ...
            sum(charges{groupIndex}.MediumCharged);
        groupStats(groupIndex).ChargedPieceCount = ...
            sum(charges{groupIndex}.PieceCharged);
        groupStats(groupIndex).Conducting = graphs{groupIndex}.Conducting;
        groupStats(groupIndex).BFSPath = graphs{groupIndex}.BFSPath;
    end
    writeQ1Tables(piecesByGroup, graphs, charges, groupStats, tableDir);
end

fprintf('[14/14] Generating figures and summary...\n');
generateEndpointRebuildFigures(piecesByGroup, groupStats, cfg, ...
    figureDir, endpointComplete, graphs);
summaryPath = fullfile(outputDir, 'q1_endpoint_summary.txt');
writeEndpointRebuildSummary(summaryPath, branchName, baseCommit, version, ...
    groupStats, sensitivityRows, consistencyPassCount, endpointComplete, ...
    relativeResults, graphs);

required = {schemaLog, testPath, summaryPath, ...
    fullfile(tableDir, 'endpoint_pair_diagnostics.csv'), ...
    fullfile(tableDir, 'endpoint_relative_shift_diagnostics.csv'), ...
    fullfile(tableDir, 'endpoint_reconstruction_audit.csv'), ...
    fullfile(tableDir, 'endpoint_enumerator_consistency.csv'), ...
    fullfile(tableDir, 'tolerance_sensitivity.csv'), ...
    fullfile(tableDir, 'reconstructed_pieces.csv'), ...
    fullfile(tableDir, 'piece_count_audit.csv'), ...
    fullfile(figureDir, 'endpoint_multi_axis_recovery.png'), ...
    fullfile(figureDir, 'boundary_piece_examples.png'), ...
    fullfile(figureDir, 'charge_vs_conduction.png'), ...
    fullfile(figureDir, 'endpoint_model_status.png')};
for index = 1:numel(required)
    assert(exist(required{index}, 'file') == 2, ...
        'Missing endpoint rebuild output: %s.', required{index});
end
fprintf('Q1 ENDPOINT REBUILD COMPLETE\n');

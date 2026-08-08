%RUN_Q1_RETAINED_PART Independent retained-original-part Q1 validation.

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
cfg.lengthTolerance = 1e-3;
cfg.geometryTolerance = 1e-6;
cfg.replayTolerance = 1e-4;
cfg.gjkTolerance = 1e-8;
cfg.gjkMaxIterations = 100;

outputDir = fullfile(projectRoot, 'output', 'Q1_retained_part');
figureDir = fullfile(outputDir, 'figures');
tableDir = fullfile(outputDir, 'tables');
logDir = fullfile(outputDir, 'logs');
directories = {outputDir, figureDir, tableDir, logDir};
for index = 1:numel(directories)
    if exist(directories{index}, 'dir') ~= 7, mkdir(directories{index}); end
end
cleanupPatterns = {fullfile(figureDir, '*.png'), fullfile(figureDir, '*.fig'), ...
    fullfile(tableDir, '*.csv'), fullfile(logDir, '*.txt')};
for patternIndex = 1:numel(cleanupPatterns)
    files = dir(cleanupPatterns{patternIndex});
    parent = fileparts(cleanupPatterns{patternIndex});
    for fileIndex = 1:numel(files)
        delete(fullfile(parent, files(fileIndex).name));
    end
end

logPath = fullfile(logDir, 'matlab_q1_retained_part.log');
if exist(logPath, 'file') == 2, delete(logPath); end
diary(logPath);
diaryCleanup = onCleanup(@() diary('off'));

[~, branchName] = system('git branch --show-current');
branchName = strtrim(branchName);
baseCommit = '3924096dee6179646832da725ab74c71200b8039';
if ~strcmp(branchName, 'q1-retained-part-rebuild')
    error('run_q1_retained_part:WrongBranch', ...
        'Run only on q1-retained-part-rebuild, current=%s.', branchName);
end
fprintf('[1/14] Setup and branch check complete: %s.\n', branchName);

excelPath = fullfile(projectRoot, 'data', 'attachment.xlsx');
fprintf('[2/14] Reading Excel schema and 596 independent rows...\n');
groups = loadGroupData(excelPath);
expectedCounts = [12 49 535];
actualCounts = zeros(1, numel(groups));
for groupIndex = 1:numel(groups)
    actualCounts(groupIndex) = numel(groups(groupIndex).RecordID);
end
assert(numel(groups) == 3 && isequal(actualCounts, expectedCounts), ...
    'Attachment record counts do not equal [12 49 535].');
schemaLog = fullfile(logDir, 'excel_schema_audit.txt');
writeExcelSchemaAudit(excelPath, groups, schemaLog);
analyses = cell(1, 3);
for groupIndex = 1:3
    analyses{groupIndex} = analyzeGroupData(groups(groupIndex), cfg);
end

fprintf('[3/14] Auditing data structure with formal +/-5000 boundaries only...\n');
fprintf('[4/14] Running retained-part artificial tests...\n');
[retainedPassed, retainedLines] = testRetainedPartReconstruction();
fprintf('[5/14] Running boundary, GJK, and Charged/Connected regressions...\n');
[boundaryPassed, boundaryLines] = testBoundaryPieceCounts();
[fourPiecePassed, fourPieceLines] = testFourPieceMultiBoundary();
[segmentPassed, segmentLines] = testSegmentSegmentDistance();
[gjkPassed, gjkLines] = testGJKCylinderDistance( ...
    fullfile(logDir, 'gjk_test_details.txt'));
[sameMediumPassed, sameMediumLines] = testSameMediumDoesNotCreateConductEdge();
[chargePassed, chargeLines] = testThreePieceChargeInheritance();
[bridgePassed, bridgeLines] = testSplitMediumBridgePath();
[insulatingPassed, insulatingLines] = testInsulatingFaceDoesNotDirectlyCharge();
[periodicPassed, periodicLines] = testNoGlobalPeriodicFalseEdge();
testLines = [retainedLines(:); boundaryLines(:); fourPieceLines(:); ...
    segmentLines(:); gjkLines(:); sameMediumLines(:); chargeLines(:); ...
    bridgeLines(:); insulatingLines(:); periodicLines(:)];
testPath = fullfile(logDir, 'q1_retained_test_results.txt');
fileID = fopen(testPath, 'w');
if fileID < 0, error('Cannot write retained test log.'); end
for index = 1:numel(testLines)
    fprintf(1, '%s\n', testLines{index});
    fprintf(fileID, '%s\r\n', testLines{index});
end
fclose(fileID);
allTestsPassed = retainedPassed && boundaryPassed && fourPiecePassed && ...
    segmentPassed && gjkPassed && sameMediumPassed && chargePassed && ...
    bridgePassed && insulatingPassed && periodicPassed;
assert(allTestsPassed, 'A retained-part or core regression test failed.');

fprintf('[6/14] Processing every attachment row independently...\n');
resultsByGroup = cell(1, 3);
for groupIndex = 1:3
    recordCount = analyses{groupIndex}.Records;
    resultsByGroup{groupIndex} = cell(recordCount, 1);
    for mediumID = 1:recordCount
        resultsByGroup{groupIndex}{mediumID} = reconstructFromRetainedPart( ...
            groups(groupIndex).P1(mediumID, :), ...
            groups(groupIndex).P2(mediumID, :), cfg);
    end
    fprintf('  Group%d processed: %d/%d.\n', groupIndex, recordCount, recordCount);
end

fprintf('[7/14] Computing forward-replay and classification statistics...\n');
emptyStats = struct('Records', 0, 'Direct', 0, ...
    'SingleBoundaryShort', 0, 'SingleBoundaryRecovered', 0, ...
    'TwoBoundaryShort', 0, 'NoBoundaryShort', 0, 'ReplayFailed', 0, ...
    'HasAbs500', 0, 'NoBoundaryHasAbs500', 0, 'Unique', 0, ...
    'Ambiguous', 0, 'Unresolved', 0, ...
    'Invalid', 0, 'PieceCountByMedium', zeros(1, 4), 'TotalPieces', 0, ...
    'PhysicalEdgeCount', 0, 'LeftContactPieces', 0, ...
    'RightContactPieces', 0, 'ChargedMediumCount', 0, ...
    'ChargedPieceCount', 0, 'UniqueOnlyConducting', false, ...
    'FinalStatus', 'Q1_UNRESOLVED', 'BFSPath', 'NO_PATH');
groupStats = repmat(emptyStats, 1, 3);
piecesByGroup = cell(1, 3);
for groupIndex = 1:3
    stats = emptyStats;
    stats.Records = analyses{groupIndex}.Records;
    for mediumID = 1:stats.Records
        item = resultsByGroup{groupIndex}{mediumID};
        if strcmp(item.Classification, 'DIRECT_FULL')
            stats.Direct = stats.Direct + 1;
        elseif strcmp(item.Classification, 'RETAINED_SINGLE_BOUNDARY_UNIQUE')
            stats.SingleBoundaryShort = stats.SingleBoundaryShort + 1;
        elseif strcmp(item.Classification, 'AMBIGUOUS_TWO_BOUNDARY_RETAINED')
            stats.TwoBoundaryShort = stats.TwoBoundaryShort + 1;
        elseif strcmp(item.Classification, 'UNRESOLVED_NO_FORMAL_BOUNDARY')
            stats.NoBoundaryShort = stats.NoBoundaryShort + 1;
        end
        if strcmp(item.Status, 'RETAINED_SINGLE_BOUNDARY_UNIQUE')
            stats.SingleBoundaryRecovered = stats.SingleBoundaryRecovered + 1;
        elseif strcmp(item.Status, 'REJECTED_FORWARD_REPLAY')
            stats.ReplayFailed = stats.ReplayFailed + 1;
        elseif strcmp(item.Status, 'INVALID_LENGTH')
            stats.Invalid = stats.Invalid + 1;
        end
        stats.HasAbs500 = stats.HasAbs500 + item.HasAbs500Coordinate;
        if strcmp(item.Classification, 'UNRESOLVED_NO_FORMAL_BOUNDARY') && ...
                item.HasAbs500Coordinate
            stats.NoBoundaryHasAbs500 = stats.NoBoundaryHasAbs500 + 1;
        end
        if item.IsUniquelyReconstructed
            stats.Unique = stats.Unique + 1;
            pieceCount = item.ForwardPieceCount;
            if pieceCount < 1 || pieceCount > 4
                error('Unexpected Piece count for Group%d A%d.', groupIndex, mediumID);
            end
            stats.PieceCountByMedium(pieceCount) = ...
                stats.PieceCountByMedium(pieceCount) + 1;
        elseif strcmp(item.Status, 'AMBIGUOUS_TWO_BOUNDARY_RETAINED')
            stats.Ambiguous = stats.Ambiguous + 1;
        end
    end
    stats.Unresolved = stats.Records - stats.Unique - stats.Ambiguous;
    piecesByGroup{groupIndex} = buildRetainedPartPieces(groupIndex, ...
        groups(groupIndex), resultsByGroup{groupIndex}, cfg);
    stats.TotalPieces = numel(piecesByGroup{groupIndex}.MediumID);
    groupStats(groupIndex) = stats;
end

fprintf('[8/14] Building GeometryPieces for unique reconstructions only...\n');
modelComplete = sum([groupStats.Unique]) == 596 && ...
    sum([groupStats.Ambiguous]) == 0 && sum([groupStats.Unresolved]) == 0;

fprintf('[9/14] Applying full-reconstruction hard gate: complete=%d.\n', modelComplete);
fprintf('[10/14] Building physical graph or strict unique-only lower bound...\n');
graphs = cell(1, 3);
charges = cell(1, 3);
for groupIndex = 1:3
    graphs{groupIndex} = buildPieceConductGraph(piecesByGroup{groupIndex}, cfg);
    charges{groupIndex} = computeChargeState(piecesByGroup{groupIndex}, ...
        graphs{groupIndex}.GeometryEdges, graphs{groupIndex}.LeftContact, ...
        graphs{groupIndex}.RightContact);
    groupStats(groupIndex).PhysicalEdgeCount = ...
        size(graphs{groupIndex}.GeometryEdges, 1);
    groupStats(groupIndex).LeftContactPieces = sum(graphs{groupIndex}.LeftContact);
    groupStats(groupIndex).RightContactPieces = sum(graphs{groupIndex}.RightContact);
    groupStats(groupIndex).ChargedMediumCount = ...
        sum(charges{groupIndex}.MediumCharged);
    groupStats(groupIndex).ChargedPieceCount = sum(charges{groupIndex}.PieceCharged);
    groupStats(groupIndex).UniqueOnlyConducting = graphs{groupIndex}.Conducting;
    groupStats(groupIndex).BFSPath = graphs{groupIndex}.BFSPath;
    if modelComplete
        if graphs{groupIndex}.Conducting
            groupStats(groupIndex).FinalStatus = 'FINAL_CONDUCTING';
        else
            groupStats(groupIndex).FinalStatus = 'FINAL_NON_CONDUCTING';
        end
    elseif graphs{groupIndex}.Conducting
        groupStats(groupIndex).FinalStatus = ...
            'DEFINITELY_CONDUCTING_FROM_UNIQUE_SUBSET';
    else
        groupStats(groupIndex).FinalStatus = 'Q1_UNRESOLVED';
    end
end

fprintf('[11/14] Writing retained reconstruction and physical tables...\n');
writeRetainedPartTables(groups, resultsByGroup, piecesByGroup, graphs, ...
    charges, groupStats, tableDir, modelComplete);

fprintf('[12/14] Generating retained-part paper figures...\n');
generateRetainedPartFigures(groups, resultsByGroup, piecesByGroup, ...
    graphs, groupStats, cfg, figureDir, modelComplete);

fprintf('[13/14] Running MATLAB checkcode and writing summary...\n');
checkcodePath = fullfile(logDir, 'checkcode.log');
issueCount = runRetainedCheckcode(projectRoot, checkcodePath);
fprintf('  checkcode issues=%d (see checkcode.log).\n', issueCount);
summaryPath = fullfile(outputDir, 'q1_retained_summary.txt');
writeRetainedPartSummary(summaryPath, branchName, baseCommit, version, ...
    groups, resultsByGroup, groupStats, modelComplete);

fprintf('[14/14] Verifying required outputs...\n');
required = {schemaLog, testPath, checkcodePath, summaryPath, ...
    fullfile(tableDir, 'retained_reconstruction_audit.csv'), ...
    fullfile(tableDir, 'reconstructed_pieces.csv'), ...
    fullfile(tableDir, 'retained_classification_summary.csv'), ...
    fullfile(tableDir, 'single_boundary_replay_summary.csv'), ...
    fullfile(tableDir, 'piece_count_audit.csv'), ...
    fullfile(tableDir, 'physical_edges.csv'), ...
    fullfile(tableDir, 'charge_state_audit.csv'), ...
    fullfile(tableDir, 'q1_results.csv'), ...
    fullfile(figureDir, 'retained_part_inverse_principle.png'), ...
    fullfile(figureDir, 'single_boundary_real_examples.png'), ...
    fullfile(figureDir, 'retained_model_status.png'), ...
    fullfile(figureDir, 'piece_count_distribution.png'), ...
    fullfile(figureDir, 'charge_vs_conduction.png')};
for index = 1:numel(required)
    assert(exist(required{index}, 'file') == 2, ...
        'Missing retained-part output: %s.', required{index});
end
fprintf('Q1 RETAINED-PART VALIDATION COMPLETE\n');
diary('off');
clear diaryCleanup;

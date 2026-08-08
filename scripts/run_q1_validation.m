%RUN_Q1_VALIDATION Formal Q1 theory, geometry, charge, and graph validation.

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
cfg.broadPhaseDistance = 2 * cfg.mediumARadius + cfg.conductionDistance;
cfg.lengthTolerance = 1e-3;
cfg.reconstructionTolerance = 1e-6;
cfg.gjkTolerance = 1e-8;
cfg.gjkMaxIterations = 100;

outputDir = fullfile(projectRoot, 'output', 'Q1');
figureDir = fullfile(outputDir, 'figures');
tableDir = fullfile(outputDir, 'tables');
logDir = fullfile(outputDir, 'logs');
directories = {outputDir, figureDir, tableDir, logDir};
for index = 1:numel(directories)
    if exist(directories{index}, 'dir') ~= 7, mkdir(directories{index}); end
end

fprintf('[1/9] Loading attachment and checking one-row-one-Medium invariants...\n');
groups = loadGroupData(fullfile(projectRoot, 'data', 'attachment.xlsx'));
expectedCounts = [12 49 535];
actualCounts = zeros(1, numel(groups));
for groupIndex = 1:numel(groups)
    actualCounts(groupIndex) = numel(groups(groupIndex).RecordID);
end
if numel(groups) ~= 3 || ~isequal(actualCounts, expectedCounts)
    error('run_q1_validation:RecordCountFailed', ...
        'Expected [12 49 535], read [%s].', sprintf('%d ', actualCounts));
end

fprintf('[2/9] Running raw-coordinate and length sanity checks...\n');
analyses = cell(1, 3);
for groupIndex = 1:3
    analyses{groupIndex} = analyzeGroupData(groups(groupIndex), cfg);
    coordinates = [groups(groupIndex).P1; groups(groupIndex).P2];
    assert(all(coordinates(:) >= -cfg.HALF_L - cfg.reconstructionTolerance) && ...
        all(coordinates(:) <= cfg.HALF_L + cfg.reconstructionTolerance), ...
        'Group %d contains a coordinate outside the nominal box.', groupIndex);
end

fprintf('[3/9] Applying the unified observed-Medium reconstruction...\n');
reconstructions = cell(1, 3);
for groupIndex = 1:3
    reconstructions{groupIndex} = cell(analyses{groupIndex}.Records, 1);
    for mediumID = 1:analyses{groupIndex}.Records
        reconstructions{groupIndex}{mediumID} = reconstructObservedMedium( ...
            analyses{groupIndex}.P1(mediumID, :), ...
            analyses{groupIndex}.P2(mediumID, :), cfg);
    end
end

fprintf('[4/9] Running geometry, boundary, charge, and graph gate tests...\n');
[segmentPassed, segmentLines] = testSegmentSegmentDistance();
[gjkPassed, gjkLines] = testGJKCylinderDistance( ...
    fullfile(logDir, 'gjk_test_details.txt'));
[reconstructionPassed, reconstructionLines] = testObservedMediumReconstruction();
[boundaryPassed, boundaryLines] = testBoundaryPieceCounts();
[fourPiecePassed, fourPieceLines] = testFourPieceMultiBoundary();
[sameMediumPassed, sameMediumLines] = testSameMediumDoesNotCreateConductEdge();
[threePieceChargePassed, threePieceChargeLines] = testThreePieceChargeInheritance();
[bridgePassed, bridgeLines] = testSplitMediumBridgePath();
[insulatingPassed, insulatingLines] = testInsulatingFaceDoesNotDirectlyCharge();
[periodicPassed, periodicLines] = testNoGlobalPeriodicFalseEdge();

testLines = [{sprintf('Segment distance tests PASS=%d', segmentPassed)}; ...
    segmentLines(:); {sprintf('GJK tests PASS=%d', gjkPassed)}; gjkLines(:); ...
    reconstructionLines(:); boundaryLines(:); fourPieceLines(:); ...
    sameMediumLines(:); threePieceChargeLines(:); bridgeLines(:); ...
    insulatingLines(:); periodicLines(:)];
testPath = fullfile(logDir, 'q1_test_results.txt');
fileID = fopen(testPath, 'w');
if fileID < 0, error('Cannot write Q1 test log.'); end
for index = 1:numel(testLines)
    fprintf(1, '%s\n', testLines{index});
    fprintf(fileID, '%s\r\n', testLines{index});
end
fclose(fileID);
allTestsPassed = segmentPassed && gjkPassed && reconstructionPassed && ...
    boundaryPassed && fourPiecePassed && sameMediumPassed && ...
    threePieceChargePassed && bridgePassed && insulatingPassed && periodicPassed;
if ~allTestsPassed
    error('run_q1_validation:TestsFailed', ...
        'At least one formal Q1 gate failed; production outputs stopped.');
end

fprintf('[5/9] Building only uniquely reconstructed GeometryPieces...\n');
piecesByGroup = cell(1, 3);
for groupIndex = 1:3
    piecesByGroup{groupIndex} = buildReconstructedPieces(groupIndex, ...
        groups(groupIndex), reconstructions{groupIndex}, cfg);
end

fprintf('[6/9] Building real Piece-level physical graphs and Charge State...\n');
graphs = cell(1, 3);
charges = cell(1, 3);
emptyStats = struct('Records', 0, 'Unique', 0, 'Ambiguous', 0, ...
    'Unresolved', 0, 'PieceCountByMedium', zeros(1, 4), ...
    'TotalPieces', 0, 'ChargedMediums', 0, 'ChargedPieces', 0, ...
    'Q1Status', '', 'BFSPath', '');
groupStats = repmat(emptyStats, 1, 3);
for groupIndex = 1:3
    stats = emptyStats;
    pieces = piecesByGroup{groupIndex};
    graphs{groupIndex} = buildPieceConductGraph(pieces, cfg);
    charges{groupIndex} = computeChargeState(pieces, ...
        graphs{groupIndex}.GeometryEdges, graphs{groupIndex}.LeftContact, ...
        graphs{groupIndex}.RightContact);

    statuses = cell(analyses{groupIndex}.Records, 1);
    pieceCounts = zeros(analyses{groupIndex}.Records, 1);
    for mediumID = 1:analyses{groupIndex}.Records
        item = reconstructions{groupIndex}{mediumID};
        statuses{mediumID} = item.Status;
        if strcmp(item.Status, 'UNIQUE')
            pieceCounts(mediumID) = size( ...
                item.WrappedPieces{item.SelectedIndex}.Start, 1);
        end
    end
    stats.Records = analyses{groupIndex}.Records;
    stats.Unique = sum(strcmp(statuses, 'UNIQUE'));
    stats.Ambiguous = sum(strcmp(statuses, 'AMBIGUOUS'));
    stats.Unresolved = sum(strcmp(statuses, 'UNRESOLVED'));
    stats.PieceCountByMedium = zeros(1, 4);
    for count = 1:4
        stats.PieceCountByMedium(count) = sum(pieceCounts == count);
    end
    stats.TotalPieces = numel(pieces.MediumID);
    stats.ChargedMediums = sum(charges{groupIndex}.MediumCharged);
    stats.ChargedPieces = sum(charges{groupIndex}.PieceCharged);
    if stats.Ambiguous > 0 || stats.Unresolved > 0
        stats.Q1Status = 'UNRESOLVED_MODEL';
        stats.BFSPath = '';
    elseif graphs{groupIndex}.Conducting
        stats.Q1Status = 'CONDUCTING';
        stats.BFSPath = graphs{groupIndex}.BFSPath;
    else
        stats.Q1Status = 'NON_CONDUCTING';
        stats.BFSPath = '';
    end
    groupStats(groupIndex) = stats;
end

fprintf('[7/9] Writing formal Q1 tables and paper figures...\n');
writeQ1Tables(groups, analyses, reconstructions, piecesByGroup, graphs, ...
    charges, groupStats, tableDir);
generateQ1Figures(analyses, reconstructions, piecesByGroup, graphs, ...
    groupStats, cfg, figureDir);

fprintf('[8/9] Writing concise Q1 summary...\n');
summaryLines = { ...
    'HSMC 2026 A - Formal Q1 Validation'; ...
    sprintf('MATLAB %s', version); ...
    sprintf('Box=10000 nm, MediumLength=5000 nm, Radius=30 nm, d0=1.8 nm'); ...
    'One Excel row = one independent PhysicalMedium.'; ...
    'Charge State never changes Piece-level physical adjacency.'; ...
    sprintf('Charge State tests PASS=%d', sameMediumPassed && ...
        threePieceChargePassed && insulatingPassed); ...
    sprintf('Physical graph tests PASS=%d', bridgePassed && periodicPassed)};
for groupIndex = 1:3
    stats = groupStats(groupIndex);
    summaryLines{end + 1, 1} = sprintf( ...
        ['Group%d Records=%d Unique=%d Ambiguous=%d Unresolved=%d ' ...
        'PieceMediumCounts=[1:%d 2:%d 3:%d 4:%d] TotalPieces=%d ' ...
        'Q1=%s'], groupIndex, stats.Records, stats.Unique, stats.Ambiguous, ...
        stats.Unresolved, stats.PieceCountByMedium, stats.TotalPieces, ...
        stats.Q1Status); %#ok<AGROW>
end
summaryLines{end + 1, 1} = ...
    'UNRESOLVED_MODEL is not NON_CONDUCTING; no candidate was forced.';
summaryPath = fullfile(outputDir, 'q1_summary.txt');
fileID = fopen(summaryPath, 'w');
if fileID < 0, error('Cannot write Q1 summary.'); end
for index = 1:numel(summaryLines)
    fprintf(1, '%s\n', summaryLines{index});
    fprintf(fileID, '%s\r\n', summaryLines{index});
end
fclose(fileID);

fprintf('[9/9] Verifying the formal output contract...\n');
required = {fullfile(tableDir, 'medium_reconstruction.csv'), ...
    fullfile(tableDir, 'reconstructed_pieces.csv'), ...
    fullfile(tableDir, 'piece_count_audit.csv'), ...
    fullfile(tableDir, 'charge_state_audit.csv'), ...
    fullfile(tableDir, 'physical_edges.csv'), ...
    fullfile(tableDir, 'q1_results.csv'), ...
    fullfile(figureDir, 'boundary_piece_examples.png'), ...
    fullfile(figureDir, 'charge_vs_conduction.png'), ...
    fullfile(figureDir, 'capsule_vs_gjk_example.png'), ...
    fullfile(figureDir, 'reconstruction_status.png'), ...
    fullfile(figureDir, 'q1_group1_piece_network.png'), ...
    fullfile(figureDir, 'q1_group2_piece_network.png'), ...
    fullfile(figureDir, 'q1_group3_piece_network.png'), testPath, summaryPath};
for index = 1:numel(required)
    assert(exist(required{index}, 'file') == 2, ...
        'Missing formal Q1 output: %s', required{index});
end
fprintf('Formal Q1 output verification passed: %d files.\n', numel(required));

%RUN_Q1_PAPER_COMPUTE Compute Q1 proof state without creating figures.

clearvars;
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

outputDir = fullfile(projectRoot, 'output', 'Q1_paper_final');
tableDir = fullfile(outputDir, 'tables');
logDir = fullfile(outputDir, 'logs');
directories = {outputDir, tableDir, logDir};
for index = 1:numel(directories)
    if exist(directories{index}, 'dir') ~= 7, mkdir(directories{index}); end
end
logPath = fullfile(logDir, 'compute.log');
if exist(logPath, 'file') == 2, delete(logPath); end
diary(logPath);
diaryCleanup = onCleanup(@() diary('off'));

[~, branchName] = system('git branch --show-current');
branchName = strtrim(branchName);
baseCommit = '5deed2fb8b5b285d47301b529736931ef8b6b218';
if ~strcmp(branchName, 'q1-paper-final-redo')
    error('run_q1_paper_compute:WrongBranch', ...
        'Run only on q1-paper-final-redo, current=%s.', branchName);
end
fprintf('[COMPUTE 1/8] Setup complete. No figures will be created.\n');

excelPath = fullfile(projectRoot, 'data', 'attachment.xlsx');
groups = loadGroupData(excelPath);
expectedCounts = [12 49 535];
actualCounts = zeros(1, numel(groups));
for groupIndex = 1:numel(groups)
    actualCounts(groupIndex) = numel(groups(groupIndex).RecordID);
end
assert(numel(groups) == 3 && isequal(actualCounts, expectedCounts), ...
    'Attachment record counts do not equal [12 49 535].');
writeExcelSchemaAudit(excelPath, groups, ...
    fullfile(logDir, 'excel_schema_audit.txt'));
fprintf('[COMPUTE 2/8] Excel schema validated.\n');

[retainedPassed, retainedLines] = testRetainedPartReconstruction();
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
fprintf('[COMPUTE 3/8] Core regression tests executed.\n');

resultsByGroup = cell(1, 3);
for groupIndex = 1:3
    recordCount = numel(groups(groupIndex).RecordID);
    resultsByGroup{groupIndex} = cell(recordCount, 1);
    for mediumID = 1:recordCount
        resultsByGroup{groupIndex}{mediumID} = reconstructFromRetainedPart( ...
            groups(groupIndex).P1(mediumID, :), ...
            groups(groupIndex).P2(mediumID, :), cfg);
    end
    fprintf('  Group%d reconstructed: %d/%d.\n', ...
        groupIndex, recordCount, recordCount);
end
fprintf('[COMPUTE 4/8] All 596 rows reconstructed or classified.\n');

emptyStats = struct('Records', 0, 'Direct', 0, ...
    'SingleBoundaryShort', 0, 'SingleBoundaryRecovered', 0, ...
    'TwoBoundaryShort', 0, 'NoBoundaryShort', 0, 'ReplayFailed', 0, ...
    'Unique', 0, 'Ambiguous', 0, 'Unresolved', 0, ...
    'PieceCountByMedium', zeros(1, 4), 'TotalPieces', 0, ...
    'PhysicalEdgeCount', 0, 'LeftContactPieces', 0, ...
    'RightContactPieces', 0, 'LowerBoundConducting', false, ...
    'UpperBoundChecked', false, 'UpperBoundConducting', false, ...
    'ProofType', '', 'FinalConducting', false, 'FinalStatus', '', ...
    'BFSPath', '');
groupStats = repmat(emptyStats, 1, 3);
piecesByGroup = cell(1, 3);
graphs = cell(1, 3);
for groupIndex = 1:3
    stats = emptyStats;
    stats.Records = numel(resultsByGroup{groupIndex});
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
        end
        if item.IsUniquelyReconstructed
            stats.Unique = stats.Unique + 1;
            stats.PieceCountByMedium(item.ForwardPieceCount) = ...
                stats.PieceCountByMedium(item.ForwardPieceCount) + 1;
        elseif strcmp(item.Status, 'AMBIGUOUS_TWO_BOUNDARY_RETAINED')
            stats.Ambiguous = stats.Ambiguous + 1;
        end
    end
    stats.Unresolved = stats.Records - stats.Unique - stats.Ambiguous;
    piecesByGroup{groupIndex} = buildRetainedPartPieces(groupIndex, ...
        groups(groupIndex), resultsByGroup{groupIndex}, cfg);
    graphs{groupIndex} = buildPieceConductGraph(piecesByGroup{groupIndex}, cfg);
    stats.TotalPieces = numel(piecesByGroup{groupIndex}.MediumID);
    stats.PhysicalEdgeCount = size(graphs{groupIndex}.GeometryEdges, 1);
    stats.LeftContactPieces = sum(graphs{groupIndex}.LeftContact);
    stats.RightContactPieces = sum(graphs{groupIndex}.RightContact);
    stats.LowerBoundConducting = graphs{groupIndex}.Conducting;
    stats.BFSPath = graphs{groupIndex}.BFSPath;
    groupStats(groupIndex) = stats;
end
fprintf('[COMPUTE 5/8] Lower-bound graphs built.\n');

upper = buildGroup1OptimisticUpperBound(groups(1), resultsByGroup{1}, ...
    piecesByGroup{1}, graphs{1}, cfg);
[upperTestPassed, upperTestLines] = testOptimisticUpperBound(groups(1), ...
    resultsByGroup{1}, piecesByGroup{1}, graphs{1}, upper, cfg);
testLines = [retainedLines(:); boundaryLines(:); fourPieceLines(:); ...
    segmentLines(:); gjkLines(:); sameMediumLines(:); chargeLines(:); ...
    bridgeLines(:); insulatingLines(:); periodicLines(:); upperTestLines(:)];
testPath = fullfile(logDir, 'q1_paper_final_test_results.txt');
fileID = fopen(testPath, 'w');
if fileID < 0, error('Cannot write paper-final test log.'); end
for index = 1:numel(testLines), fprintf(fileID, '%s\r\n', testLines{index}); end
fclose(fileID);
allTestsPassed = retainedPassed && boundaryPassed && fourPiecePassed && ...
    segmentPassed && gjkPassed && sameMediumPassed && chargePassed && ...
    bridgePassed && insulatingPassed && periodicPassed && upperTestPassed;
assert(allTestsPassed, 'A Q1 paper-final regression test failed.');
fprintf('[COMPUTE 6/8] Group1 optimistic upper bound built and tested.\n');

group1Certificate = ~upper.Conducting && ...
    upper.MinEnvelopeToKnownAxisDistance > cfg.broadPhaseDistance && ...
    upper.MinEnvelopeToEnvelopeAxisDistance > cfg.broadPhaseDistance;
if ~group1Certificate || ~graphs{2}.Conducting || ~graphs{3}.Conducting
    error('run_q1_paper_compute:FinalHardGateFailed', ...
        ['Hard gate failed: G1Upper=%d minEK=%.15g minEE=%.15g ' ...
        'G2Lower=%d G3Lower=%d.'], upper.Conducting, ...
        upper.MinEnvelopeToKnownAxisDistance, ...
        upper.MinEnvelopeToEnvelopeAxisDistance, ...
        graphs{2}.Conducting, graphs{3}.Conducting);
end
groupStats(1).UpperBoundChecked = true;
groupStats(1).UpperBoundConducting = upper.Conducting;
groupStats(1).ProofType = 'OPTIMISTIC_GEOMETRIC_UPPER_BOUND';
groupStats(1).FinalConducting = false;
groupStats(1).FinalStatus = 'FINAL_NON_CONDUCTING_BY_UPPER_BOUND';
for groupIndex = 2:3
    groupStats(groupIndex).ProofType = 'UNIQUE_RECONSTRUCTION_LOWER_BOUND';
    groupStats(groupIndex).FinalConducting = true;
    groupStats(groupIndex).FinalStatus = 'FINAL_CONDUCTING_BY_LOWER_BOUND';
end
fprintf('[COMPUTE 7/8] Final lower/upper-bound hard gate passed.\n');

writePaperFinalOutputs(outputDir, tableDir, branchName, baseCommit, ...
    version, groupStats, upper, cfg);
paperState.Branch = branchName;
paperState.BaseCommit = baseCommit;
paperState.MATLABVersion = version;
paperState.cfg = cfg;
paperState.groups = groups;
paperState.resultsByGroup = resultsByGroup;
paperState.piecesByGroup = piecesByGroup;
paperState.graphs = graphs;
paperState.groupStats = groupStats;
paperState.upper = upper;
paperState.AllTestsPassed = allTestsPassed;
paperState.FinalAnswers = [false true true];
statePath = fullfile(outputDir, 'paper_state.mat');
save(statePath, 'paperState', '-v7');
assert(exist(statePath, 'file') == 2, 'paper_state.mat was not created.');
fprintf('[COMPUTE 8/8] Tables, summary, and paper_state.mat written.\n');
fprintf('Q1 PAPER COMPUTE COMPLETE\n');
diary('off');
clear diaryCleanup;

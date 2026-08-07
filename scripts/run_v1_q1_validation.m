%RUN_V1_Q1_VALIDATION V1 parent reconstruction and exact Q1 validation.
% No global periodic images are used. Graph nodes are PhysicalMedium parents.

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
cfg.directionTolerance = 1e-6;
cfg.boundaryTolerance = 1e-6;
% 1e-8 nm is eight orders below the 1.8 nm conduction threshold. A real
% Group3 curved-support case converges at this value with the same distance
% (to 15 digits) as a 1000-iteration 1e-9 run that only missed termination.
cfg.gjkTolerance = 1e-8;
cfg.gjkMaxIterations = 100;

v1Dir = fullfile(projectRoot, 'output', 'V1');
tableDir = fullfile(v1Dir, 'tables');
figureDir = fullfile(v1Dir, 'figures');
logDir = fullfile(v1Dir, 'logs');
directories = {v1Dir, tableDir, figureDir, logDir};
for index = 1:numel(directories)
    if exist(directories{index}, 'dir') ~= 7
        mkdir(directories{index});
    end
end

fprintf('[1/9] Reading V0 data and pairing candidates...\n');
groups = loadGroupData(fullfile(projectRoot, 'data', 'attachment.xlsx'));
expectedCounts = [12 49 535];
actualCounts = zeros(1, numel(groups));
for groupIndex = 1:numel(groups)
    actualCounts(groupIndex) = numel(groups(groupIndex).RecordID);
end
if numel(groups) ~= 3 || ~isequal(actualCounts, expectedCounts)
    error('run_v1_q1_validation:V0SanityFailed', ...
        'Expected [12 49 535], read [%s].', sprintf('%d ', actualCounts));
end
candidates = loadBoundaryPairCandidates( ...
    fullfile(projectRoot, 'output', 'boundary_pair_candidates.csv'));

fprintf('[2/9] Reconstructing M0/M1/M2 parents and direction audits...\n');
analyses = cell(1, 3);
familyIDs = cell(1, 3);
contacts = cell(1, 3);
directionAudit = cell(1, 3);
parentMaps = cell(3, 3);
modelNames = {'M0', 'M1', 'M2'};
for groupIndex = 1:3
    analyses{groupIndex} = analyzeGroupData(groups(groupIndex), cfg);
    canonical = canonicalDirection(analyses{groupIndex}.UnitDirection, ...
        cfg.directionTolerance);
    [familyIDs{groupIndex}, representatives] = clusterDirections( ...
        canonical, cfg.directionTolerance);
    [contacts{groupIndex}, ~] = findBoundaryCandidates(groupIndex, ...
        analyses{groupIndex}, canonical, cfg);
    familyCount = size(representatives, 1);
    item.DirectionFamily = (1:familyCount)';
    item.PieceCount = zeros(familyCount, 1);
    item.TotalAxisLength = zeros(familyCount, 1);
    for familyIndex = 1:familyCount
        mask = familyIDs{groupIndex} == familyIndex;
        item.PieceCount(familyIndex) = sum(mask);
        item.TotalAxisLength(familyIndex) = sum(analyses{groupIndex}.SegmentLength(mask));
    end
    item.LengthError = item.TotalAxisLength - cfg.mediumALength;
    item.IsNear5000 = abs(item.LengthError) <= cfg.lengthTolerance;
    directionAudit{groupIndex} = item;
    for modelIndex = 1:3
        parentMaps{groupIndex, modelIndex} = buildParentMap(modelNames{modelIndex}, ...
            analyses{groupIndex}.Records, familyIDs{groupIndex}, candidates, groupIndex);
    end
end

fprintf('[3/9] Running finite-segment tests...\n');
[segmentTestsPassed, segmentTestLines] = testSegmentSegmentDistance();
for index = 1:numel(segmentTestLines)
    fprintf('%s\n', segmentTestLines{index});
end
if ~segmentTestsPassed
    error('run_v1_q1_validation:SegmentTestsFailed', ...
        'Finite-segment tests failed. Formal Q1 calculation stopped.');
end

fprintf('[4/9] Running finite-cylinder GJK tests...\n');
[gjkTestsPassed, ~] = testGJKCylinderDistance( ...
    fullfile(logDir, 'gjk_test_results.txt'));
if ~gjkTestsPassed
    error('run_v1_q1_validation:GJKTestsFailed', ...
        'GJK tests failed. Formal Q1 calculation stopped.');
end

fprintf('[5/9] Computing broad-phase and exact finite-cylinder distances...\n');
geometryPairs = cell(1, 3);
for groupIndex = 1:3
    fprintf('  Group %d: %d GeometryPieces\n', groupIndex, analyses{groupIndex}.Records);
    geometryPairs{groupIndex} = computeGeometryPairs(analyses{groupIndex}, cfg);
    fprintf('  Group %d: %d broad-phase candidates\n', groupIndex, ...
        numel(geometryPairs{groupIndex}.PieceA));
end

fprintf('[6/9] Building nine PhysicalMedium graphs and running BFS...\n');
modelResults = cell(3, 3);
for groupIndex = 1:3
    for modelIndex = 1:3
        modelResults{groupIndex, modelIndex} = buildConductGraph( ...
            analyses{groupIndex}, parentMaps{groupIndex, modelIndex}, ...
            geometryPairs{groupIndex}, cfg);
        fprintf('  Group %d %s: Parents=%d Conducting=%d Path=%s\n', ...
            groupIndex, modelNames{modelIndex}, ...
            modelResults{groupIndex, modelIndex}.ParentCount, ...
            modelResults{groupIndex, modelIndex}.Conducting, ...
            formatBFSPath(modelResults{groupIndex, modelIndex}.Conducting, ...
            modelResults{groupIndex, modelIndex}.PathParents));
    end
end

fprintf('[7/9] Writing V1 tables and optional Excel workbook...\n');
[comparison, disagreementCount, excelWritten] = writeV1Tables( ...
    analyses, familyIDs, contacts, parentMaps, modelResults, geometryPairs, ...
    directionAudit, cfg, tableDir, v1Dir); %#ok<NASGU>
disagreementMask = comparison.CapsuleConnected ~= comparison.ExactConnected;
uniqueDisagreementCount = size(unique([comparison.Group(disagreementMask) ...
    comparison.PieceA(disagreementMask) comparison.PieceB(disagreementMask)], 'rows'), 1);

fprintf('[8/9] Generating paper figures...\n');
generateV1Figures(groups, analyses, familyIDs, parentMaps, modelResults, ...
    candidates, directionAudit, cfg, figureDir);

fprintf('[9/9] Writing V1 summary and verifying required outputs...\n');
summaryLines = cell(0, 1);
summaryLines{end + 1} = '============================================================';
summaryLines{end + 1} = 'HSMC 2026 A - Q1 V1 Validation Summary';
summaryLines{end + 1} = 'MATLAB R2016a (9.0.0.341360)';
summaryLines{end + 1} = '============================================================';
summaryLines{end + 1} = 'V0 record review: Group1=12, Group2=49, Group3=535.';
summaryLines{end + 1} = sprintf('GJK all unit tests passed: %d', gjkTestsPassed);
summaryLines{end + 1} = sprintf( ...
    'Capsule/GJK disagreements: %d model rows; %d unique GeometryPiece pairs.', ...
    disagreementCount, uniqueDisagreementCount);
summaryLines{end + 1} = sprintf('Optional q1_results.xlsx written: %d', excelWritten);
for groupIndex = 1:3
    summaryLines{end + 1} = '------------------------------------------------------------';
    summaryLines{end + 1} = sprintf('Group %d', groupIndex);
    summaryLines{end + 1} = sprintf('Direction families: %d; near 5000 nm: %d', ...
        numel(directionAudit{groupIndex}.DirectionFamily), ...
        sum(directionAudit{groupIndex}.IsNear5000));
    for modelIndex = 1:3
        result = modelResults{groupIndex, modelIndex};
        summaryLines{end + 1} = sprintf( ...
            '%s Parents=%d Conducting=%d DirectParent=%d Path=%s', ...
            modelNames{modelIndex}, result.ParentCount, result.Conducting, ...
            result.DirectParent, formatBFSPath(result.Conducting, result.PathParents));
    end
end
summaryLines{end + 1} = '------------------------------------------------------------';
summaryLines{end + 1} = ['Model uncertainty: M0 is record-independent; M1 uses only V0 boundary ' ...
    'pair candidates; M2 groups complete direction families.'];
summaryLines{end + 1} = ['No model is declared the unique attachment interpretation. No global ' ...
    'periodic geometry images were used.'];
summaryLines{end + 1} = '============================================================';
summaryLines{end + 1} = 'V1 Q1 VALIDATION COMPLETE';

summaryPath = fullfile(v1Dir, 'v1_summary.txt');
fileID = fopen(summaryPath, 'w');
if fileID < 0
    error('run_v1_q1_validation:SummaryOpenFailed', 'Cannot write: %s', summaryPath);
end
for index = 1:numel(summaryLines)
    fprintf(1, '%s\n', summaryLines{index});
    fprintf(fileID, '%s\r\n', summaryLines{index});
end
fclose(fileID);

requiredOutputs = {fullfile(tableDir, 'parent_reconstruction_summary.csv'), ...
    fullfile(tableDir, 'piece_parent_map_M0.csv'), ...
    fullfile(tableDir, 'piece_parent_map_M1.csv'), ...
    fullfile(tableDir, 'piece_parent_map_M2.csv'), ...
    fullfile(tableDir, 'direction_family_length_audit.csv'), ...
    fullfile(tableDir, 'gjk_capsule_comparison.csv'), ...
    fullfile(tableDir, 'gjk_capsule_disagreement.csv'), ...
    fullfile(tableDir, 'q1_model_comparison.csv'), ...
    fullfile(tableDir, 'q1_results_for_paper.csv'), ...
    fullfile(figureDir, 'direction_family_total_length.png'), ...
    fullfile(figureDir, 'q1_model_comparison.png'), ...
    fullfile(figureDir, 'q1_model_comparison.fig'), ...
    fullfile(figureDir, 'parent_count_comparison.png'), ...
    fullfile(figureDir, 'parent_count_comparison.fig'), ...
    fullfile(figureDir, 'boundary_reconstruction_examples.png'), ...
    fullfile(figureDir, 'q1_group1_3d.png'), ...
    fullfile(figureDir, 'q1_group1_3d.fig'), ...
    fullfile(figureDir, 'q1_group2_3d.png'), ...
    fullfile(figureDir, 'q1_group2_3d.fig'), ...
    fullfile(figureDir, 'q1_group3_3d.png'), ...
    fullfile(figureDir, 'q1_group3_3d.fig'), ...
    fullfile(logDir, 'gjk_test_results.txt'), summaryPath};
for index = 1:numel(requiredOutputs)
    assert(exist(requiredOutputs{index}, 'file') == 2, ...
        'Required V1 output missing: %s', requiredOutputs{index});
end
fprintf('V1 required output verification passed: %d files verified.\n', ...
    numel(requiredOutputs));

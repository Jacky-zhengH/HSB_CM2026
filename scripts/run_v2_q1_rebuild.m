%RUN_V2_Q1_REBUILD One-row-one-medium boundary encoding validation for Q1.
% Electrical graph nodes are GeometryPieces. There are no hidden Medium edges.

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
cfg.reconstructionTolerance = 1e-6;
cfg.gjkTolerance = 1e-8;
cfg.gjkMaxIterations = 100;

outputDir = fullfile(projectRoot, 'output', 'Q1_rebuild');
tableDir = fullfile(outputDir, 'tables');
figureDir = fullfile(outputDir, 'figures');
logDir = fullfile(outputDir, 'logs');
directories = {outputDir, tableDir, figureDir, logDir};
for index = 1:numel(directories)
    if exist(directories{index}, 'dir') ~= 7, mkdir(directories{index}); end
end

fprintf('[1/9] Loading attachment under the one-row-one-medium rule...\n');
groups = loadGroupData(fullfile(projectRoot, 'data', 'attachment.xlsx'));
expectedCounts = [12 49 535];
actualCounts = zeros(1, numel(groups));
for groupIndex = 1:numel(groups), actualCounts(groupIndex) = numel(groups(groupIndex).RecordID); end
if numel(groups) ~= 3 || ~isequal(actualCounts, expectedCounts)
    error('run_v2_q1_rebuild:RecordCountFailed', ...
        'Expected [12 49 535], read [%s].', sprintf('%d ', actualCounts));
end

fprintf('[2/9] Computing R0 raw audit and coordinate anomaly counts...\n');
analyses = cell(1, 3);
coordinateCounts = zeros(3, 4); % +500,-500,+5000,-5000
for groupIndex = 1:3
    analyses{groupIndex} = analyzeGroupData(groups(groupIndex), cfg);
    coordinates = [groups(groupIndex).P1 groups(groupIndex).P2];
    coordinateCounts(groupIndex, :) = [sum(coordinates(:) == 500), ...
        sum(coordinates(:) == -500), sum(coordinates(:) == 5000), ...
        sum(coordinates(:) == -5000)];
end
anomalyPath = fullfile(logDir, 'coordinate_boundary_anomaly.txt');
fileID = fopen(anomalyPath, 'w');
if fileID < 0, error('Cannot write coordinate anomaly log.'); end
fprintf(fileID, 'Coordinate boundary anomaly audit (exact numeric equality)\r\n');
fprintf(fileID, 'The theoretical BOX_HALF remains 5000 nm; +/-500 is not treated as a boundary.\r\n');
for groupIndex = 1:3
    fprintf(fileID, ['Group %d: +500=%d, -500=%d, exact +/-500 total=%d; ' ...
        '+5000=%d, -5000=%d, exact +/-5000 total=%d\r\n'], groupIndex, ...
        coordinateCounts(groupIndex, 1), coordinateCounts(groupIndex, 2), ...
        sum(coordinateCounts(groupIndex, 1:2)), coordinateCounts(groupIndex, 3), ...
        coordinateCounts(groupIndex, 4), sum(coordinateCounts(groupIndex, 3:4)));
end
fclose(fileID);

fprintf('[3/9] Enumerating R1 same-row endpoint unwrap candidates...\n');
r1Results = cell(1, 3);
for groupIndex = 1:3
    r1Results{groupIndex} = cell(analyses{groupIndex}.Records, 1);
    for mediumID = 1:analyses{groupIndex}.Records
        r1Results{groupIndex}{mediumID} = enumerateEndpointUnwrap( ...
            analyses{groupIndex}.P1(mediumID, :), analyses{groupIndex}.P2(mediumID, :), ...
            cfg.L, cfg.mediumALength, cfg.reconstructionTolerance);
    end
end

fprintf('[4/9] Testing R2 finite same-row reconstructions by forward wrapping...\n');
r2Results = cell(1, 3);
for groupIndex = 1:3
    r2Results{groupIndex} = cell(analyses{groupIndex}.Records, 1);
    for mediumID = 1:analyses{groupIndex}.Records
        r2Results{groupIndex}{mediumID} = reconstructRowR2( ...
            analyses{groupIndex}.P1(mediumID, :), analyses{groupIndex}.P2(mediumID, :), cfg);
    end
end

fprintf('[5/9] Running reconstruction, geometry, and no-hidden-wire tests...\n');
[segmentPassed, segmentLines] = testSegmentSegmentDistance();
[unwrapPassed, unwrapLines] = testEndpointUnwrap();
[wrapPassed, wrapLines] = testWrapSegmentToBox();
[rowPassed, rowLines] = testRowReconstruction();
[hiddenPassed, hiddenLines, noHiddenResult, noHiddenPieces] = testNoHiddenParentConnection();
[gjkPassed, gjkLines] = testGJKCylinderDistance(fullfile(logDir, 'gjk_test_results.txt'));
allLines = [segmentLines(:); unwrapLines(:); wrapLines(:); rowLines(:); ...
    hiddenLines(:); gjkLines(:)];
testLogPath = fullfile(logDir, 'v2_test_results.txt');
fileID = fopen(testLogPath, 'w');
if fileID < 0, error('Cannot write V2 test log.'); end
for index = 1:numel(allLines)
    fprintf(1, '%s\n', allLines{index}); fprintf(fileID, '%s\r\n', allLines{index});
end
fclose(fileID);
if ~(segmentPassed && unwrapPassed && wrapPassed && rowPassed && hiddenPassed && gjkPassed)
    error('run_v2_q1_rebuild:TestsFailed', ...
        'At least one V2 gate test failed. Formal piece graph calculation stopped.');
end

fprintf('[6/9] Generating resolved GeometryPieces for R0/R1/R2...\n');
modelNames = {'R0','R1','R2'};
modelPieces = cell(3, 3);
modelStats = cell(3, 3);
for groupIndex = 1:3
    for modelIndex = 1:3
        modelName = modelNames{modelIndex};
        modelPieces{groupIndex, modelIndex} = buildModelPieces(groupIndex, ...
            groups(groupIndex), analyses{groupIndex}, modelName, ...
            r1Results{groupIndex}, r2Results{groupIndex}, cfg);
        stats.Records = analyses{groupIndex}.Records;
        if modelIndex == 1
            stats.Resolved = stats.Records; stats.Unresolved = 0; stats.Ambiguous = 0;
        elseif modelIndex == 2
            statuses = cell(stats.Records, 1);
            for mediumID = 1:stats.Records, statuses{mediumID} = r1Results{groupIndex}{mediumID}.Status; end
            stats.Resolved = sum(strcmp(statuses, 'DIRECT_5000')) + ...
                sum(strcmp(statuses, 'UNIQUE_ENDPOINT_UNWRAP'));
            stats.Unresolved = sum(strcmp(statuses, 'NO_ENDPOINT_UNWRAP'));
            stats.Ambiguous = sum(strcmp(statuses, 'AMBIGUOUS_ENDPOINT_UNWRAP'));
        else
            statuses = cell(stats.Records, 1);
            for mediumID = 1:stats.Records, statuses{mediumID} = r2Results{groupIndex}{mediumID}.Status; end
            stats.Resolved = sum(strcmp(statuses, 'UNIQUE_RECONSTRUCTION'));
            stats.Unresolved = sum(strcmp(statuses, 'UNRESOLVED'));
            stats.Ambiguous = sum(strcmp(statuses, 'AMBIGUOUS'));
        end
        stats.ConductingStatus = 'UNRESOLVED_MODEL';
        modelStats{groupIndex, modelIndex} = stats;
    end
end

fprintf('[7/9] Building complete Piece-level graphs with exact cylinder distance...\n');
modelResults = cell(3, 3);
for groupIndex = 1:3
    for modelIndex = 1:3
        stats = modelStats{groupIndex, modelIndex};
        if stats.Unresolved > 0 || stats.Ambiguous > 0
            fprintf('  Group%d %s: UNRESOLVED_MODEL (%d unresolved, %d ambiguous)\n', ...
                groupIndex, modelNames{modelIndex}, stats.Unresolved, stats.Ambiguous);
            continue;
        end
        modelResults{groupIndex, modelIndex} = buildPieceConductGraph( ...
            modelPieces{groupIndex, modelIndex}, cfg);
        if modelResults{groupIndex, modelIndex}.Conducting
            modelStats{groupIndex, modelIndex}.ConductingStatus = 'CONDUCTING';
        else
            modelStats{groupIndex, modelIndex}.ConductingStatus = 'NON_CONDUCTING';
        end
        fprintf('  Group%d %s: %s | %s\n', groupIndex, modelNames{modelIndex}, ...
            modelStats{groupIndex, modelIndex}.ConductingStatus, ...
            modelResults{groupIndex, modelIndex}.BFSPath);
    end
end

fprintf('[8/9] Writing Q1 rebuild tables, logs, and paper figures...\n');
writeV2Tables(groups, analyses, r1Results, r2Results, modelPieces, ...
    modelStats, modelResults, tableDir, cfg);
generateV2Figures(groups, analyses, r1Results, r2Results, modelPieces, ...
    modelResults, noHiddenResult, noHiddenPieces, cfg, figureDir);

fprintf('[9/9] Writing V2 summary and verifying outputs...\n');
summaryLines = {'============================================================'; ...
    'HSMC 2026 A - V2 Q1 One-Row-One-Medium Rebuild'; ...
    'MATLAB R2016a'; ...
    'No cross-row Parent merge; no hidden same-Medium electrical edge.'; ...
    '============================================================'};
for groupIndex = 1:3
    rawFull = sum(abs(analyses{groupIndex}.SegmentLength - cfg.mediumALength) <= cfg.lengthTolerance);
    summaryLines{end + 1} = sprintf('Group %d: Records=%d Raw5000=%d RawShort=%d', ...
        groupIndex, analyses{groupIndex}.Records, rawFull, analyses{groupIndex}.Records - rawFull); %#ok<AGROW>
    for modelIndex = 1:3
        stats = modelStats{groupIndex, modelIndex};
        pathText = '';
        if ~isempty(modelResults{groupIndex, modelIndex}), pathText = modelResults{groupIndex, modelIndex}.BFSPath; end
        summaryLines{end + 1} = sprintf('%s Resolved=%d Unresolved=%d Ambiguous=%d Pieces=%d Status=%s Path=%s', ...
            modelNames{modelIndex}, stats.Resolved, stats.Unresolved, stats.Ambiguous, ...
            numel(modelPieces{groupIndex, modelIndex}.MediumID), stats.ConductingStatus, pathText); %#ok<AGROW>
    end
    summaryLines{end + 1} = '------------------------------------------------------------'; %#ok<AGROW>
end
summaryLines{end + 1} = ['Finding: endpoint +/-10000 unwrap alone is insufficient ' ...
    'to explain the many short records.'];
summaryLines{end + 1} = ['UNRESOLVED_MODEL means the data interpretation is incomplete; ' ...
    'it is not NON_CONDUCTING.'];
summaryLines{end + 1} = 'V2 Q1 REBUILD COMPLETE';
summaryPath = fullfile(outputDir, 'v2_summary.txt');
fileID = fopen(summaryPath, 'w');
if fileID < 0, error('Cannot write V2 summary.'); end
for index = 1:numel(summaryLines), fprintf(1, '%s\n', summaryLines{index}); fprintf(fileID, '%s\r\n', summaryLines{index}); end
fclose(fileID);

required = {fullfile(tableDir,'raw_record_audit.csv'), ...
    fullfile(tableDir,'endpoint_unwrap_candidates.csv'), ...
    fullfile(tableDir,'reconstruction_summary.csv'), ...
    fullfile(tableDir,'reconstructed_pieces.csv'), ...
    fullfile(tableDir,'q1_model_results.csv'), ...
    fullfile(figureDir,'raw_length_distribution.png'), ...
    fullfile(figureDir,'r1_endpoint_unwrap_success.png'), ...
    fullfile(figureDir,'row_reconstruction_examples.png'), ...
    fullfile(figureDir,'no_hidden_connection_demo.png'), ...
    fullfile(logDir,'coordinate_boundary_anomaly.txt'), ...
    fullfile(logDir,'v2_test_results.txt'), summaryPath};
for index = 1:numel(required), assert(exist(required{index},'file') == 2, 'Missing output: %s', required{index}); end
fprintf('V2 required output verification passed: %d files verified.\n', numel(required));

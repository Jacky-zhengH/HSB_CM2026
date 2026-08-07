%RUN_DATA_AUDIT V0 data audit for HSMC 2026 Problem A, Question 1.
% MATLAB R2016a-compatible script. This script does not merge records or
% determine electrical conduction.

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
cfg.lengthTolerance = 1e-3;
% Unit-vector Euclidean tolerance. 1e-6 is approximately 5.7e-5 degrees
% for small angles and accommodates decimal endpoint roundoff.
cfg.directionTolerance = 1e-6;
% Coordinate tolerance in nm. Excel boundary values are expected to be
% exact or nearly exact; 1e-6 nm allows only floating-point serialization.
cfg.boundaryTolerance = 1e-6;

excelPath = fullfile(projectRoot, 'data', 'attachment.xlsx');
outputDir = fullfile(projectRoot, 'output');

fprintf('[1/6] Loading Excel and checking record counts...\n');
groups = loadGroupData(excelPath);
expectedCounts = [12 49 535];
actualCounts = zeros(1, numel(groups));
for groupIndex = 1:numel(groups)
    actualCounts(groupIndex) = numel(groups(groupIndex).RecordID);
end
if numel(groups) ~= 3 || ~isequal(actualCounts, expectedCounts)
    error('run_data_audit:SanityCheckFailed', ...
        ['Expected three data groups with counts [12 49 535], but read ' ...
         '%d group(s) with counts [%s]. Analysis stopped.'], ...
        numel(groups), sprintf('%d ', actualCounts));
end

fprintf('[2/6] Checking segment geometry and invariants...\n');
analyses = cell(1, 3);
canonicalDirections = cell(1, 3);
for groupIndex = 1:3
    analyses{groupIndex} = analyzeGroupData(groups(groupIndex), cfg);
    unitNorm = sqrt(sum(analyses{groupIndex}.UnitDirection.^2, 2));
    assert(all(abs(unitNorm - 1) <= 1e-12), ...
        'Unit direction norm validation failed for Group %d.', groupIndex);
    allCoordinates = [groups(groupIndex).P1; groups(groupIndex).P2];
    assert(all(allCoordinates(:) >= -cfg.HALF_L - cfg.boundaryTolerance) && ...
        all(allCoordinates(:) <= cfg.HALF_L + cfg.boundaryTolerance), ...
        'Coordinate range validation failed for Group %d.', groupIndex);
    canonicalDirections{groupIndex} = canonicalDirection( ...
        analyses{groupIndex}.UnitDirection, cfg.directionTolerance);
    oppositeCanonical = canonicalDirection( ...
        -analyses{groupIndex}.UnitDirection, cfg.directionTolerance);
    assert(max(max(abs(canonicalDirections{groupIndex} - oppositeCanonical))) <= ...
        10 * eps, 'Canonical sign validation failed for Group %d.', groupIndex);
end

fprintf('[3/6] Clustering canonical direction families...\n');
familyIDs = cell(1, 3);
familyRepresentatives = cell(1, 3);
familyCounts = cell(1, 3);
familyAssignmentErrors = cell(1, 3);
for groupIndex = 1:3
    [familyIDs{groupIndex}, familyRepresentatives{groupIndex}, ...
        familyCounts{groupIndex}, familyAssignmentErrors{groupIndex}] = ...
        clusterDirections(canonicalDirections{groupIndex}, ...
        cfg.directionTolerance);
end

fprintf('[4/6] Finding boundary contacts and periodic pairing candidates...\n');
contacts = cell(1, 3);
endpointCounts = cell(1, 3);
groupCandidates = cell(1, 3);
allCandidates.Group = zeros(0, 1);
allCandidates.RecordA = zeros(0, 1);
allCandidates.RecordB = zeros(0, 1);
allCandidates.Translation = zeros(0, 3);
allCandidates.DirectionError = zeros(0, 1);
allCandidates.EndpointError = zeros(0, 1);
allCandidates.BoundaryDescription = cell(0, 1);
for groupIndex = 1:3
    [contacts{groupIndex}, endpointCounts{groupIndex}, ...
        groupCandidates{groupIndex}] = findBoundaryCandidates(groupIndex, ...
        analyses{groupIndex}, canonicalDirections{groupIndex}, cfg);
    fields = fieldnames(allCandidates);
    for fieldIndex = 1:numel(fields)
        fieldName = fields{fieldIndex};
        allCandidates.(fieldName) = [allCandidates.(fieldName); ...
            groupCandidates{groupIndex}.(fieldName)];
    end
end

fprintf('[5/6] Writing audit CSV files and summary...\n');
for groupIndex = 1:3
    csvPath = fullfile(outputDir, sprintf('group%d_audit.csv', groupIndex));
    fileID = fopen(csvPath, 'w');
    if fileID < 0
        error('run_data_audit:OutputOpenFailed', 'Cannot write: %s', csvPath);
    end
    fprintf(fileID, ['RecordID,OriginalExcelRow,x1,y1,z1,x2,y2,z2,' ...
        'SegmentLength,ux,uy,uz,DirectionFamily,TouchXMin,TouchXMax,' ...
        'TouchYMin,TouchYMax,TouchZMin,TouchZMax\n']);
    analysis = analyses{groupIndex};
    contact = contacts{groupIndex};
    for recordIndex = 1:analysis.Records
        fprintf(fileID, ['%d,%d,%.15g,%.15g,%.15g,%.15g,%.15g,%.15g,' ...
            '%.15g,%.15g,%.15g,%.15g,%d,%d,%d,%d,%d,%d,%d\n'], ...
            analysis.RecordID(recordIndex), ...
            analysis.OriginalExcelRow(recordIndex), ...
            analysis.P1(recordIndex, :), analysis.P2(recordIndex, :), ...
            analysis.SegmentLength(recordIndex), ...
            analysis.UnitDirection(recordIndex, :), ...
            familyIDs{groupIndex}(recordIndex), ...
            contact.TouchXMin(recordIndex), contact.TouchXMax(recordIndex), ...
            contact.TouchYMin(recordIndex), contact.TouchYMax(recordIndex), ...
            contact.TouchZMin(recordIndex), contact.TouchZMax(recordIndex));
    end
    fclose(fileID);
end

candidatePath = fullfile(outputDir, 'boundary_pair_candidates.csv');
fileID = fopen(candidatePath, 'w');
if fileID < 0
    error('run_data_audit:OutputOpenFailed', 'Cannot write: %s', candidatePath);
end
fprintf(fileID, ['Group,RecordA,RecordB,TranslationX,TranslationY,' ...
    'TranslationZ,DirectionError,EndpointError,BoundaryDescription\n']);
for candidateIndex = 1:numel(allCandidates.Group)
    fprintf(fileID, '%d,%d,%d,%.15g,%.15g,%.15g,%.15g,%.15g,%s\n', ...
        allCandidates.Group(candidateIndex), ...
        allCandidates.RecordA(candidateIndex), ...
        allCandidates.RecordB(candidateIndex), ...
        allCandidates.Translation(candidateIndex, :), ...
        allCandidates.DirectionError(candidateIndex), ...
        allCandidates.EndpointError(candidateIndex), ...
        allCandidates.BoundaryDescription{candidateIndex});
end
fclose(fileID);

summaryLines = cell(0, 1);
summaryLines{end + 1} = '==============================================';
summaryLines{end + 1} = 'HSMC 2026 A - Q1 Data Audit';
summaryLines{end + 1} = 'MATLAB R2016a';
summaryLines{end + 1} = '==============================================';
for groupIndex = 1:3
    analysis = analyses{groupIndex};
    count = endpointCounts{groupIndex};
    summaryLines{end + 1} = '';
    summaryLines{end + 1} = sprintf('Group %d', groupIndex);
    summaryLines{end + 1} = sprintf('Worksheet: %s', groups(groupIndex).SheetName);
    summaryLines{end + 1} = sprintf('Records: %d', analysis.Records);
    summaryLines{end + 1} = sprintf('Full-length records: %d', ...
        analysis.FullLengthRecords);
    summaryLines{end + 1} = sprintf('Short records: %d', analysis.ShortRecords);
    summaryLines{end + 1} = sprintf('Minimum length: %.15g', ...
        analysis.MinimumLength);
    summaryLines{end + 1} = sprintf('Maximum length: %.15g', ...
        analysis.MaximumLength);
    summaryLines{end + 1} = sprintf('Mean length: %.15g', analysis.MeanLength);
    summaryLines{end + 1} = sprintf('Median length: %.15g', ...
        analysis.MedianLength);
    summaryLines{end + 1} = sprintf('Direction families: %d', ...
        size(familyRepresentatives{groupIndex}, 1));
    summaryLines{end + 1} = sprintf('XMin contacts: %d', count.XMin);
    summaryLines{end + 1} = sprintf('XMax contacts: %d', count.XMax);
    summaryLines{end + 1} = sprintf('YMin contacts: %d', count.YMin);
    summaryLines{end + 1} = sprintf('YMax contacts: %d', count.YMax);
    summaryLines{end + 1} = sprintf('ZMin contacts: %d', count.ZMin);
    summaryLines{end + 1} = sprintf('ZMax contacts: %d', count.ZMax);
    summaryLines{end + 1} = sprintf('Boundary pairing candidates: %d', ...
        numel(groupCandidates{groupIndex}.Group));
    if groupIndex < 3
        summaryLines{end + 1} = '----------------------------------------------';
    end
end
summaryLines{end + 1} = '';
summaryLines{end + 1} = '==============================================';
summaryLines{end + 1} = 'V0 DATA AUDIT COMPLETE';

summaryPath = fullfile(outputDir, 'audit_summary.txt');
summaryFileID = fopen(summaryPath, 'w');
if summaryFileID < 0
    error('run_data_audit:OutputOpenFailed', 'Cannot write: %s', summaryPath);
end
for lineIndex = 1:numel(summaryLines)
    fprintf(1, '%s\n', summaryLines{lineIndex});
    fprintf(summaryFileID, '%s\r\n', summaryLines{lineIndex});
end
fclose(summaryFileID);

fprintf('[6/6] Creating segment-length distribution figure and verifying outputs...\n');
figureHandle = figure('Visible', 'off', 'Color', 'w');
for groupIndex = 1:3
    subplot(3, 1, groupIndex);
    binCount = max(5, min(30, ceil(sqrt(analyses{groupIndex}.Records))));
    hist(analyses{groupIndex}.SegmentLength, binCount);
    hold on;
    verticalLimits = get(gca, 'YLim');
    plot([cfg.mediumALength cfg.mediumALength], verticalLimits, 'r--', ...
        'LineWidth', 1.5);
    hold off;
    xlabel('Segment Length / nm');
    ylabel('Count');
    title(sprintf('Group %d', groupIndex));
    grid on;
end
figurePath = fullfile(outputDir, 'segment_length_distribution.png');
print(figureHandle, figurePath, '-dpng', '-r150');
close(figureHandle);

requiredOutputs = { ...
    fullfile(outputDir, 'group1_audit.csv'), ...
    fullfile(outputDir, 'group2_audit.csv'), ...
    fullfile(outputDir, 'group3_audit.csv'), ...
    candidatePath, summaryPath, figurePath};
for outputIndex = 1:numel(requiredOutputs)
    assert(exist(requiredOutputs{outputIndex}, 'file') == 2, ...
        'Expected output was not generated: %s', requiredOutputs{outputIndex});
end
fprintf('Required output verification passed: %d files verified.\n', ...
    numel(requiredOutputs));

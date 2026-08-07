%RUN_V11_PAPER_POLISH V1.1 paper-material polish; core V1 model unchanged.

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
cfg.lengthTolerance = 1e-3;
cfg.directionTolerance = 1e-6;
cfg.boundaryTolerance = 1e-6;
cfg.gjkTolerance = 1e-8;
cfg.gjkMaxIterations = 100;

figureDir = fullfile(projectRoot, 'output', 'V1', 'figures');
logDir = fullfile(projectRoot, 'output', 'V1', 'logs');
if exist(figureDir, 'dir') ~= 7, mkdir(figureDir); end
if exist(logDir, 'dir') ~= 7, mkdir(logDir); end

fprintf('[1/4] Loading verified V0/V1 data...\n');
groups = loadGroupData(fullfile(projectRoot, 'data', 'attachment.xlsx'));
candidates = loadBoundaryPairCandidates( ...
    fullfile(projectRoot, 'output', 'boundary_pair_candidates.csv'));
analyses = cell(1, 3);
familyIDs = cell(1, 3);
parentMaps = cell(3, 3);
modelNames = {'M0', 'M1', 'M2'};
for groupIndex = 1:3
    analyses{groupIndex} = analyzeGroupData(groups(groupIndex), cfg);
    canonical = canonicalDirection(analyses{groupIndex}.UnitDirection, cfg.directionTolerance);
    familyIDs{groupIndex} = clusterDirections(canonical, cfg.directionTolerance);
    for modelIndex = 1:3
        parentMaps{groupIndex, modelIndex} = buildParentMap(modelNames{modelIndex}, ...
            analyses{groupIndex}.Records, familyIDs{groupIndex}, candidates, groupIndex);
    end
end

fprintf('[2/4] Selecting Group1 M1 paper path and generating figures...\n');
selection = generateV11PaperFigures(groups, analyses, parentMaps, ...
    candidates, cfg, figureDir);
fprintf('  Selected ParentID=P%d, RecordIDs=%s, TotalAxisLength=%.15g nm\n', ...
    selection.ParentID, sprintf('%d;', selection.RecordIDs), selection.TotalAxisLength);
assert(any(selection.ParentID == [2 3]) && numel(selection.RecordIDs) == 2 && ...
    abs(selection.TotalAxisLength - cfg.mediumALength) <= cfg.lengthTolerance, ...
    'Unexpected Group1 selected DirectParent.');

fprintf('[3/4] Auditing Group3 electrode-contact difference...\n');
analysis = analyses{3};
v0Contact = abs(analysis.P1(:, 1) + cfg.HALF_L) <= cfg.boundaryTolerance | ...
    abs(analysis.P2(:, 1) + cfg.HALF_L) <= cfg.boundaryTolerance;
v1Contact = false(analysis.Records, 1);
leftDistance = zeros(analysis.Records, 1);
axisDistance = zeros(analysis.Records, 1);
radialXExtent = zeros(analysis.Records, 1);
for recordIndex = 1:analysis.Records
    [leftDistance(recordIndex), ~] = cylinderPlaneDistance( ...
        analysis.P1(recordIndex, :), analysis.P2(recordIndex, :), ...
        cfg.mediumARadius, cfg.HALF_L);
    axisDistance(recordIndex) = min(analysis.P1(recordIndex, 1), ...
        analysis.P2(recordIndex, 1)) + cfg.HALF_L;
    ux = analysis.UnitDirection(recordIndex, 1);
    radialXExtent(recordIndex) = cfg.mediumARadius * sqrt(max(0, 1 - ux^2));
    v1Contact(recordIndex) = leftDistance(recordIndex) <= cfg.conductionDistance;
end
extraRecords = find(v1Contact & ~v0Contact);
assert(sum(v0Contact) == 91 && sum(v1Contact) == 92 && isequal(extraRecords, 92), ...
    'Unexpected Group3 XMin/LEFT contact difference.');

logPath = fullfile(logDir, 'electrode_contact_difference.txt');
fileID = fopen(logPath, 'w');
if fileID < 0, error('run_v11_paper_polish:LogOpenFailed', 'Cannot write: %s', logPath); end
recordID = extraRecords(1);
lines = { ...
    'Group3 V0 XMin contact versus V1 LEFT contact audit', ...
    sprintf('V0 XMin endpoint-contact records: %d', sum(v0Contact)), ...
    sprintf('V1 finite-cylinder LEFT-contact records: %d', sum(v1Contact)), ...
    sprintf('Extra RecordID: %d', recordID), ...
    sprintf('P1 = [%.15g, %.15g, %.15g] nm', analysis.P1(recordID, :)), ...
    sprintf('P2 = [%.15g, %.15g, %.15g] nm', analysis.P2(recordID, :)), ...
    sprintf('Axis endpoint-to-LEFT distance = %.15g nm', axisDistance(recordID)), ...
    sprintf('Radius projection along x = %.15g nm', radialXExtent(recordID)), ...
    sprintf('Finite-cylinder solid-to-LEFT distance = %.15g nm', leftDistance(recordID)), ...
    sprintf('Conduction threshold D0 = %.15g nm', cfg.conductionDistance), ...
    ['Conclusion: the axis does not meet the 1.8 nm electrode threshold, but the ' ...
     '30 nm cylinder radius extends the solid to/across LEFT; the 91-to-92 difference ' ...
     'is caused by finite radius, not an extra endpoint on x=-5000.']};
for index = 1:numel(lines)
    fprintf(1, '%s\n', lines{index});
    fprintf(fileID, '%s\r\n', lines{index});
end
fclose(fileID);

fprintf('[4/4] Verifying V1.1 paper outputs...\n');
required = {fullfile(figureDir, 'q1_group1_3d.png'), ...
    fullfile(figureDir, 'q1_group1_3d.fig'), ...
    fullfile(figureDir, 'boundary_reconstruction_examples.png'), ...
    fullfile(figureDir, 'capsule_vs_gjk_example.png'), ...
    fullfile(figureDir, 'capsule_vs_gjk_example.fig'), logPath};
for index = 1:numel(required)
    assert(exist(required{index}, 'file') == 2, 'Missing V1.1 output: %s', required{index});
end
fprintf('V1.1 PAPER MATERIAL POLISH COMPLETE\n');

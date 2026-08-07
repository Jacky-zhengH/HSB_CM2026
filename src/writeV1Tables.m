function [comparison, disagreementCount, excelWritten] = writeV1Tables( ...
        analyses, familyIDs, contacts, parentMaps, modelResults, ...
        geometryPairs, directionAudit, cfg, tableDir, v1Dir)
%WRITEV1TABLES Write all standard V1 CSV tables and optional workbook.

modelNames = {'M0', 'M1', 'M2'};

% Piece-to-parent maps.
for modelIndex = 1:3
    path = fullfile(tableDir, sprintf('piece_parent_map_%s.csv', modelNames{modelIndex}));
    fileID = openOutput(path);
    fprintf(fileID, 'Group,RecordID,ParentID,DirectionFamily\n');
    for groupIndex = 1:3
        for recordIndex = 1:analyses{groupIndex}.Records
            fprintf(fileID, '%d,%d,%d,%d\n', groupIndex, recordIndex, ...
                parentMaps{groupIndex, modelIndex}(recordIndex), ...
                familyIDs{groupIndex}(recordIndex));
        end
    end
    fclose(fileID);
end

% Parent audit, with group totals repeated for machine-friendly filtering.
parentPath = fullfile(tableDir, 'parent_reconstruction_summary.csv');
fileID = openOutput(parentPath);
fprintf(fileID, ['Group,Model,GroupPieceCount,ParentCount,ParentID,' ...
    'ParentPieceCount,RecordIDs,TotalAxisLength,TouchesXMin,TouchesXMax,' ...
    'TouchesYMin,TouchesYMax,TouchesZMin,TouchesZMax\n']);
parentCells = {'Group','Model','GroupPieceCount','ParentCount','ParentID', ...
    'ParentPieceCount','RecordIDs','TotalAxisLength','TouchesXMin','TouchesXMax', ...
    'TouchesYMin','TouchesYMax','TouchesZMin','TouchesZMax'};
for groupIndex = 1:3
    for modelIndex = 1:3
        map = parentMaps{groupIndex, modelIndex};
        parentCount = max(map);
        for parentID = 1:parentCount
            records = find(map == parentID);
            recordText = sprintf('%d;', records);
            if ~isempty(recordText), recordText(end) = []; end
            totalLength = sum(analyses{groupIndex}.SegmentLength(records));
            flags = [any(contacts{groupIndex}.TouchXMin(records)) ...
                any(contacts{groupIndex}.TouchXMax(records)) ...
                any(contacts{groupIndex}.TouchYMin(records)) ...
                any(contacts{groupIndex}.TouchYMax(records)) ...
                any(contacts{groupIndex}.TouchZMin(records)) ...
                any(contacts{groupIndex}.TouchZMax(records))];
            fprintf(fileID, '%d,%s,%d,%d,%d,%d,%s,%.15g,%d,%d,%d,%d,%d,%d\n', ...
                groupIndex, modelNames{modelIndex}, analyses{groupIndex}.Records, ...
                parentCount, parentID, numel(records), recordText, totalLength, flags);
            parentCells(end + 1, :) = {groupIndex, modelNames{modelIndex}, ...
                analyses{groupIndex}.Records, parentCount, parentID, numel(records), ...
                recordText, totalLength, flags(1), flags(2), flags(3), flags(4), flags(5), flags(6)}; %#ok<AGROW>
        end
    end
end
fclose(fileID);

% Direction-family integrity audit.
path = fullfile(tableDir, 'direction_family_length_audit.csv');
fileID = openOutput(path);
fprintf(fileID, 'Group,DirectionFamily,PieceCount,TotalAxisLength,LengthError,IsNear5000\n');
for groupIndex = 1:3
    item = directionAudit{groupIndex};
    for familyIndex = 1:numel(item.DirectionFamily)
        fprintf(fileID, '%d,%d,%d,%.15g,%.15g,%d\n', groupIndex, ...
            item.DirectionFamily(familyIndex), item.PieceCount(familyIndex), ...
            item.TotalAxisLength(familyIndex), item.LengthError(familyIndex), ...
            item.IsNear5000(familyIndex));
    end
end
fclose(fileID);

% Capsule versus exact GJK for distinct Parent pairs in each model.
comparison.Group = zeros(0, 1);
comparison.Model = cell(0, 1);
comparison.ParentA = zeros(0, 1);
comparison.ParentB = zeros(0, 1);
comparison.PieceA = zeros(0, 1);
comparison.PieceB = zeros(0, 1);
comparison.AxisDistance = zeros(0, 1);
comparison.CapsuleDistance = zeros(0, 1);
comparison.ExactDistance = zeros(0, 1);
comparison.CapsuleConnected = false(0, 1);
comparison.ExactConnected = false(0, 1);
for groupIndex = 1:3
    pairs = geometryPairs{groupIndex};
    for modelIndex = 1:3
        map = parentMaps{groupIndex, modelIndex};
        for pairIndex = 1:numel(pairs.PieceA)
            parentA = map(pairs.PieceA(pairIndex));
            parentB = map(pairs.PieceB(pairIndex));
            if parentA == parentB
                continue;
            end
            next = numel(comparison.Group) + 1;
            comparison.Group(next, 1) = groupIndex;
            comparison.Model{next, 1} = modelNames{modelIndex};
            comparison.ParentA(next, 1) = parentA;
            comparison.ParentB(next, 1) = parentB;
            comparison.PieceA(next, 1) = pairs.PieceA(pairIndex);
            comparison.PieceB(next, 1) = pairs.PieceB(pairIndex);
            comparison.AxisDistance(next, 1) = pairs.AxisDistance(pairIndex);
            comparison.CapsuleDistance(next, 1) = pairs.CapsuleDistance(pairIndex);
            comparison.ExactDistance(next, 1) = pairs.ExactDistance(pairIndex);
            comparison.CapsuleConnected(next, 1) = pairs.CapsuleDistance(pairIndex) <= cfg.conductionDistance;
            comparison.ExactConnected(next, 1) = pairs.ExactDistance(pairIndex) <= cfg.conductionDistance;
        end
    end
end

comparisonHeader = ['Group,Model,ParentA,ParentB,PieceA,PieceB,AxisDistance,' ...
    'CapsuleDistance,ExactDistance,CapsuleConnected,ExactConnected\n'];
comparisonPath = fullfile(tableDir, 'gjk_capsule_comparison.csv');
fileID = openOutput(comparisonPath);
fprintf(fileID, comparisonHeader);
writeComparisonRows(fileID, comparison, true(size(comparison.Group)));
fclose(fileID);
disagreement = comparison.CapsuleConnected ~= comparison.ExactConnected;
disagreementCount = sum(disagreement);
fileID = openOutput(fullfile(tableDir, 'gjk_capsule_disagreement.csv'));
fprintf(fileID, comparisonHeader);
writeComparisonRows(fileID, comparison, disagreement);
fclose(fileID);

% Nine model results.
modelPath = fullfile(tableDir, 'q1_model_comparison.csv');
fileID = openOutput(modelPath);
fprintf(fileID, ['Group,Model,PieceCount,ParentCount,CandidateGeometryPairs,' ...
    'ExactEdges,LeftContactParents,RightContactParents,Conducting,PathLength,Path\n']);
modelCells = {'Group','Model','PieceCount','ParentCount','CandidateGeometryPairs', ...
    'ExactEdges','LeftContactParents','RightContactParents','Conducting','PathLength','Path'};
for groupIndex = 1:3
    for modelIndex = 1:3
        result = modelResults{groupIndex, modelIndex};
        pathText = formatBFSPath(result.Conducting, result.PathParents);
        fprintf(fileID, '%d,%s,%d,%d,%d,%d,%d,%d,%d,%d,%s\n', groupIndex, ...
            modelNames{modelIndex}, analyses{groupIndex}.Records, result.ParentCount, ...
            result.CandidateGeometryPairs, result.ExactEdges, ...
            result.LeftContactParents, result.RightContactParents, ...
            result.Conducting, result.PathLength, pathText);
        modelCells(end + 1, :) = {groupIndex, modelNames{modelIndex}, ...
            analyses{groupIndex}.Records, result.ParentCount, ...
            result.CandidateGeometryPairs, result.ExactEdges, ...
            result.LeftContactParents, result.RightContactParents, ...
            result.Conducting, result.PathLength, pathText}; %#ok<AGROW>
    end
end
fclose(fileID);

% Concise paper table.
paperPath = fullfile(tableDir, 'q1_results_for_paper.csv');
fileID = openOutput(paperPath);
fprintf(fileID, ['Group,Records,M1Parents,M2Parents,M0Conducting,' ...
    'M1Conducting,M2Conducting,SelectedPath\n']);
paperCells = {'Group','Records','M1Parents','M2Parents','M0Conducting', ...
    'M1Conducting','M2Conducting','SelectedPath'};
for groupIndex = 1:3
    pathText = formatBFSPath(modelResults{groupIndex, 2}.Conducting, ...
        modelResults{groupIndex, 2}.PathParents);
    fprintf(fileID, '%d,%d,%d,%d,%d,%d,%d,%s\n', groupIndex, ...
        analyses{groupIndex}.Records, max(parentMaps{groupIndex, 2}), ...
        max(parentMaps{groupIndex, 3}), modelResults{groupIndex, 1}.Conducting, ...
        modelResults{groupIndex, 2}.Conducting, modelResults{groupIndex, 3}.Conducting, pathText);
    paperCells(end + 1, :) = {groupIndex, analyses{groupIndex}.Records, ...
        max(parentMaps{groupIndex, 2}), max(parentMaps{groupIndex, 3}), ...
        modelResults{groupIndex, 1}.Conducting, modelResults{groupIndex, 2}.Conducting, ...
        modelResults{groupIndex, 3}.Conducting, pathText}; %#ok<AGROW>
end
fclose(fileID);

% Optional legacy Excel workbook. CSV files remain authoritative.
excelWritten = false;
excelPath = fullfile(v1Dir, 'q1_results.xlsx');
try
    if exist(excelPath, 'file') == 2
        delete(excelPath);
    end
    capsuleCells = {'Group','Model','ParentA','ParentB','PieceA','PieceB', ...
        'AxisDistance','CapsuleDistance','ExactDistance','CapsuleConnected','ExactConnected'};
    for row = 1:numel(comparison.Group)
        capsuleCells(end + 1, :) = {comparison.Group(row), comparison.Model{row}, ...
            comparison.ParentA(row), comparison.ParentB(row), comparison.PieceA(row), ...
            comparison.PieceB(row), comparison.AxisDistance(row), ...
            comparison.CapsuleDistance(row), comparison.ExactDistance(row), ...
            comparison.CapsuleConnected(row), comparison.ExactConnected(row)}; %#ok<AGROW>
    end
    xlswrite(excelPath, paperCells, 'Summary');
    xlswrite(excelPath, parentCells, 'ParentReconstruction');
    xlswrite(excelPath, modelCells, 'ModelComparison');
    xlswrite(excelPath, capsuleCells, 'CapsuleVsGJK');
    excelWritten = true;
catch excelError
    warning('writeV1Tables:ExcelSkipped', ...
        'q1_results.xlsx was not written; CSV outputs remain valid: %s', excelError.message);
end
end

function fileID = openOutput(path)
fileID = fopen(path, 'w');
if fileID < 0
    error('writeV1Tables:OutputOpenFailed', 'Cannot write: %s', path);
end
end

function writeComparisonRows(fileID, comparison, mask)
indices = find(mask);
for index = 1:numel(indices)
    row = indices(index);
    fprintf(fileID, '%d,%s,%d,%d,%d,%d,%.15g,%.15g,%.15g,%d,%d\n', ...
        comparison.Group(row), comparison.Model{row}, comparison.ParentA(row), ...
        comparison.ParentB(row), comparison.PieceA(row), comparison.PieceB(row), ...
        comparison.AxisDistance(row), comparison.CapsuleDistance(row), ...
        comparison.ExactDistance(row), comparison.CapsuleConnected(row), ...
        comparison.ExactConnected(row));
end
end

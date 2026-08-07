function groups = loadGroupData(excelPath)
%LOADGROUPDATA Read all coordinate-bearing sheets without changing Excel.
%   Each returned group contains RecordID, OriginalExcelRow, P1 and P2.

if exist(excelPath, 'file') ~= 2
    error('loadGroupData:MissingFile', 'Excel input not found: %s', excelPath);
end

[excelStatus, sheetNames] = xlsfinfo(excelPath);
if isempty(excelStatus) || isempty(sheetNames)
    error('loadGroupData:UnreadableWorkbook', ...
        'xlsfinfo could not read any worksheets from: %s', excelPath);
end

groups = struct('SheetName', {}, 'CoordinateColumns', {}, ...
    'RecordID', {}, 'OriginalExcelRow', {}, 'P1', {}, 'P2', {});

for sheetIndex = 1:numel(sheetNames)
    sheetName = sheetNames{sheetIndex};
    [~, ~, raw] = xlsread(excelPath, sheetName);
    if isempty(raw)
        continue;
    end

    [coordinateColumns, numericValues, numericMask] = ...
        locateCoordinateColumns(raw, sheetName);
    validRows = all(numericMask(:, coordinateColumns), 2);
    excelRows = find(validRows);
    if isempty(excelRows)
        continue;
    end

    coordinates = numericValues(excelRows, coordinateColumns);
    finiteRows = all(isfinite(coordinates), 2);
    coordinates = coordinates(finiteRows, :);
    excelRows = excelRows(finiteRows);
    if isempty(excelRows)
        continue;
    end

    groupIndex = numel(groups) + 1;
    groups(groupIndex).SheetName = sheetName;
    groups(groupIndex).CoordinateColumns = coordinateColumns;
    groups(groupIndex).RecordID = (1:size(coordinates, 1))';
    groups(groupIndex).OriginalExcelRow = excelRows(:);
    groups(groupIndex).P1 = coordinates(:, 1:3);
    groups(groupIndex).P2 = coordinates(:, 4:6);
end

if isempty(groups)
    error('loadGroupData:NoCoordinateData', ...
        'No worksheet contained six usable finite numeric coordinate columns.');
end
end

function [coordinateColumns, numericValues, numericMask] = ...
        locateCoordinateColumns(raw, sheetName)
% Prefer explicit x1...z2 headers. Fall back to the strongest six-column
% numeric block so the reader does not depend on worksheet names.

[rowCount, columnCount] = size(raw);
numericValues = NaN(rowCount, columnCount);
numericMask = false(rowCount, columnCount);

for rowIndex = 1:rowCount
    for columnIndex = 1:columnCount
        value = raw{rowIndex, columnIndex};
        if isnumeric(value) && isscalar(value) && isfinite(value)
            numericValues(rowIndex, columnIndex) = double(value);
            numericMask(rowIndex, columnIndex) = true;
        end
    end
end

requiredHeaders = {'x1', 'y1', 'z1', 'x2', 'y2', 'z2'};
for rowIndex = 1:rowCount
    foundColumns = zeros(1, 6);
    for columnIndex = 1:columnCount
        value = raw{rowIndex, columnIndex};
        if ischar(value)
            normalized = lower(regexprep(value, '[^a-zA-Z0-9]', ''));
            for headerIndex = 1:6
                if strcmp(normalized, requiredHeaders{headerIndex})
                    foundColumns(headerIndex) = columnIndex;
                end
            end
        end
    end
    if all(foundColumns > 0) && numel(unique(foundColumns)) == 6
        coordinateColumns = foundColumns;
        return;
    end
end

numericColumns = find(sum(numericMask, 1) > 0);
if numel(numericColumns) < 6
    error('loadGroupData:InsufficientNumericColumns', ...
        'Worksheet "%s" has fewer than six numeric columns.', sheetName);
end

% Candidate sets comprise contiguous windows in the used numeric columns.
% This covers ordinary spreadsheets with leading ID or comment columns.
candidateSets = zeros(0, 6);
for startIndex = 1:(numel(numericColumns) - 5)
    candidateSets(end + 1, :) = numericColumns(startIndex:startIndex + 5); %#ok<AGROW>
end

bestScore = [-1 -1 -Inf];
coordinateColumns = [];
for candidateIndex = 1:size(candidateSets, 1)
    columns = candidateSets(candidateIndex, :);
    completeRows = all(numericMask(:, columns), 2);
    completeCount = sum(completeRows);
    if completeCount == 0
        continue;
    end
    values = numericValues(completeRows, columns);
    inNominalBox = sum(all(abs(values) <= 5000.001, 2));
    segmentLengths = sqrt(sum((values(:, 4:6) - values(:, 1:3)).^2, 2));
    plausibleSegments = sum(segmentLengths > 0 & segmentLengths <= 5000.001);
    score = [completeCount inNominalBox plausibleSegments];
    if lexicographicallyGreater(score, bestScore)
        bestScore = score;
        coordinateColumns = columns;
    end
end

if isempty(coordinateColumns)
    error('loadGroupData:NoCompleteRows', ...
        'Worksheet "%s" has no row with six finite numeric coordinates.', sheetName);
end
end

function result = lexicographicallyGreater(left, right)
result = false;
for index = 1:numel(left)
    if left(index) > right(index)
        result = true;
        return;
    elseif left(index) < right(index)
        return;
    end
end
end

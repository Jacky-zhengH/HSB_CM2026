function result = reconstructRowR3(p1, p2, cfg)
%RECONSTRUCTROWR3 Multi-boundary same-row reconstruction.
%   Candidate allocations a,b satisfy a+b=5000-Lraw. Candidate a values
%   come only from periodic boundary events and the finite intervals those
%   events induce; there is no continuous length scan.

rawVector = p2 - p1;
rawLength = norm(rawVector);
if rawLength <= 0
    error('reconstructRowR3:ZeroLength', 'Raw record length must be positive.');
end

result.RawLength = rawLength;
result.A = zeros(0, 1);
result.B = zeros(0, 1);
result.CandidateType = cell(0, 1);
result.OriginalStart = zeros(0, 3);
result.OriginalEnd = zeros(0, 3);
result.WrappedPieces = cell(0, 1);
result.Valid = false(0, 1);
result.MatchedPieceIndex = zeros(0, 1);

if abs(rawLength - cfg.mediumALength) <= cfg.reconstructionTolerance
    allocations = 0;
    types = {'DIRECT'};
elseif rawLength > cfg.mediumALength
    allocations = zeros(0, 1);
    types = cell(0, 1);
else
    unitDirection = rawVector / rawLength;
    missingLength = cfg.mediumALength - rawLength;
    p1Boundary = boundaryAxes(p1, cfg.HALF_L, cfg.reconstructionTolerance);
    p2Boundary = boundaryAxes(p2, cfg.HALF_L, cfg.reconstructionTolerance);
    critical = [0; missingLength];
    if any(p1Boundary)
        critical = [critical; boundaryDistances(p1, -unitDirection, ...
            missingLength, cfg.HALF_L, cfg.L, cfg.reconstructionTolerance)]; %#ok<AGROW>
    end
    if any(p2Boundary)
        forwardEvents = boundaryDistances(p2, unitDirection, missingLength, ...
            cfg.HALF_L, cfg.L, cfg.reconstructionTolerance);
        critical = [critical; missingLength - forwardEvents]; %#ok<AGROW>
    end
    critical = uniqueWithTolerance(critical, cfg.reconstructionTolerance);
    allocations = critical;
    types = repmat({'BOUNDARY_EVENT'}, numel(critical), 1);
    for index = 1:(numel(critical) - 1)
        if critical(index + 1) - critical(index) > cfg.reconstructionTolerance
            allocations(end + 1, 1) = (critical(index) + critical(index + 1)) / 2; %#ok<AGROW>
            types{end + 1, 1} = 'EVENT_INTERVAL_REPRESENTATIVE'; %#ok<AGROW>
        end
    end
    [allocations, order] = sort(allocations);
    types = types(order);

    % If an observed endpoint is not a boundary event it must be an original
    % endpoint; extending through it would not reproduce a complete Piece.
    keep = true(size(allocations));
    for index = 1:numel(allocations)
        a = allocations(index);
        b = missingLength - a;
        if a > cfg.reconstructionTolerance && ~any(p1Boundary), keep(index) = false; end
        if b > cfg.reconstructionTolerance && ~any(p2Boundary), keep(index) = false; end
    end
    allocations = allocations(keep);
    types = types(keep);
end

if ~isempty(allocations)
    unitDirection = rawVector / rawLength;
end
for candidateIndex = 1:numel(allocations)
    if abs(rawLength - cfg.mediumALength) <= cfg.reconstructionTolerance
        a = 0; b = 0;
    else
        a = allocations(candidateIndex);
        b = cfg.mediumALength - rawLength - a;
    end
    originalStart = p1 - a * unitDirection;
    originalEnd = p2 + b * unitDirection;
    wrapped = wrapSegmentToBox(originalStart, originalEnd, cfg.HALF_L, ...
        cfg.L, cfg.reconstructionTolerance);
    [valid, matchedIndex] = containsObservedPiece(wrapped, p1, p2, ...
        cfg.reconstructionTolerance);
    next = numel(result.A) + 1;
    result.A(next, 1) = a;
    result.B(next, 1) = b;
    result.CandidateType{next, 1} = types{candidateIndex};
    result.OriginalStart(next, :) = originalStart;
    result.OriginalEnd(next, :) = originalEnd;
    result.WrappedPieces{next, 1} = wrapped;
    result.Valid(next, 1) = valid;
    result.MatchedPieceIndex(next, 1) = matchedIndex;
end

result.ValidIndices = find(result.Valid);
result.CandidateCount = numel(result.ValidIndices);
if result.CandidateCount == 0
    result.Status = 'UNRESOLVED';
    result.SelectedIndex = [];
elseif result.CandidateCount == 1
    result.Status = 'UNIQUE_RECONSTRUCTION';
    result.SelectedIndex = result.ValidIndices(1);
else
    result.Status = 'AMBIGUOUS';
    result.SelectedIndex = [];
end
end

function axesMask = boundaryAxes(point, halfBox, tolerance)
axesMask = abs(abs(point) - halfBox) <= tolerance;
end

function distances = boundaryDistances(point, direction, maximumDistance, ...
        halfBox, boxLength, tolerance)
distances = zeros(0, 1);
for axisIndex = 1:3
    component = direction(axisIndex);
    if abs(component) <= tolerance, continue; end
    endValue = point(axisIndex) + maximumDistance * component;
    lower = min(point(axisIndex), endValue);
    upper = max(point(axisIndex), endValue);
    nMinimum = ceil((lower - halfBox) / boxLength);
    nMaximum = floor((upper - halfBox) / boxLength);
    for n = nMinimum:nMaximum
        boundary = halfBox + n * boxLength;
        distance = (boundary - point(axisIndex)) / component;
        if distance > tolerance && distance < maximumDistance - tolerance
            distances(end + 1, 1) = distance; %#ok<AGROW>
        end
    end
end
end

function values = uniqueWithTolerance(values, tolerance)
values = sort(values(:));
output = values(1);
for index = 2:numel(values)
    if abs(values(index) - output(end)) > tolerance
        output(end + 1, 1) = values(index); %#ok<AGROW>
    end
end
values = output;
end

function [matched, pieceIndex] = containsObservedPiece(pieces, p1, p2, tolerance)
matched = false; pieceIndex = 0;
for index = 1:size(pieces.Start, 1)
    forwardError = max([abs(pieces.Start(index, :) - p1) abs(pieces.End(index, :) - p2)]);
    reverseError = max([abs(pieces.Start(index, :) - p2) abs(pieces.End(index, :) - p1)]);
    if min(forwardError, reverseError) <= tolerance
        matched = true; pieceIndex = index; return;
    end
end
end

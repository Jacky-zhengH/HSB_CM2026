function result = reconstructObservedMedium(p1, p2, cfg)
%RECONSTRUCTOBSERVEDMEDIUM Unified one-row-one-Medium reconstruction.
%   Exact endpoint unwrap candidates and finite boundary-event extension
%   candidates are combined without a continuous scan or nearest fallback.

rawVector = p2 - p1;
rawLength = norm(rawVector);
if rawLength <= 0
    error('reconstructObservedMedium:ZeroLength', ...
        'Observed record length must be positive.');
end

candidateType = cell(0, 1);
kValues = zeros(0, 3);
aValues = zeros(0, 1);
bValues = zeros(0, 1);
originalStart = zeros(0, 3);
originalEnd = zeros(0, 3);
wrappedPieces = cell(0, 1);
matchedPieceIndex = zeros(0, 1);

% A complete in-box 5000 nm row is already the direct Medium. For every
% other row preserve the complete endpoint unwrap capability: 27 cases.
if abs(rawLength - cfg.mediumALength) <= cfg.reconstructionTolerance
    kRange = 0;
else
    kRange = -1:1;
end
for kx = kRange
    for ky = kRange
        for kz = kRange
            k = [kx ky kz];
            candidateEnd = p2 + cfg.L * k;
            if abs(norm(candidateEnd - p1) - cfg.mediumALength) > ...
                    cfg.reconstructionTolerance
                continue;
            end
            next = numel(candidateType) + 1;
            if all(k == 0), candidateType{next, 1} = 'DIRECT';
            else, candidateType{next, 1} = 'ENDPOINT_UNWRAP'; end
            kValues(next, :) = k;
            aValues(next, 1) = NaN;
            bValues(next, 1) = NaN;
            originalStart(next, :) = p1;
            originalEnd(next, :) = candidateEnd;
            wrappedPieces{next, 1} = wrapSegmentToBox(p1, candidateEnd, ...
                cfg.HALF_L, cfg.L, cfg.reconstructionTolerance);
            [~, matchedPieceIndex(next, 1)] = containsObservedPiece( ...
                wrappedPieces{next, 1}, p1, p2, cfg.reconstructionTolerance);
        end
    end
end

% A short row may be any complete first, middle, or last GeometryPiece.
if rawLength < cfg.mediumALength - cfg.reconstructionTolerance
    unitDirection = rawVector / rawLength;
    missingLength = cfg.mediumALength - rawLength;
    p1Boundary = boundaryAxes(p1, cfg.HALF_L, cfg.reconstructionTolerance);
    p2Boundary = boundaryAxes(p2, cfg.HALF_L, cfg.reconstructionTolerance);

    critical = [0; missingLength];
    if any(p1Boundary)
        critical = [critical; boundaryDistances(p1, -unitDirection, ...
            missingLength, cfg)]; %#ok<AGROW>
    end
    if any(p2Boundary)
        forwardEvents = boundaryDistances(p2, unitDirection, ...
            missingLength, cfg);
        critical = [critical; missingLength - forwardEvents]; %#ok<AGROW>
    end
    critical = uniqueWithTolerance(critical, cfg.reconstructionTolerance);
    allocations = critical;
    allocationType = repmat({'BOUNDARY_EVENT'}, numel(critical), 1);
    for index = 1:(numel(critical) - 1)
        if critical(index + 1) - critical(index) > ...
                cfg.reconstructionTolerance
            allocations(end + 1, 1) = ...
                (critical(index) + critical(index + 1)) / 2; %#ok<AGROW>
            allocationType{end + 1, 1} = ...
                'EVENT_INTERVAL_REPRESENTATIVE'; %#ok<AGROW>
        end
    end
    [allocations, order] = sort(allocations);
    allocationType = allocationType(order);

    for allocationIndex = 1:numel(allocations)
        a = allocations(allocationIndex);
        b = missingLength - a;
        if a > cfg.reconstructionTolerance && ~any(p1Boundary), continue; end
        if b > cfg.reconstructionTolerance && ~any(p2Boundary), continue; end

        candidateStart = p1 - a * unitDirection;
        candidateEnd = p2 + b * unitDirection;
        wrapped = wrapSegmentToBox(candidateStart, candidateEnd, ...
            cfg.HALF_L, cfg.L, cfg.reconstructionTolerance);
        [valid, matchedIndex] = containsObservedPiece(wrapped, p1, p2, ...
            cfg.reconstructionTolerance);
        if ~valid, continue; end
        if containsCandidate(originalStart, originalEnd, candidateStart, ...
                candidateEnd, cfg.reconstructionTolerance)
            continue;
        end

        next = numel(candidateType) + 1;
        candidateType{next, 1} = allocationType{allocationIndex};
        kValues(next, :) = [NaN NaN NaN];
        aValues(next, 1) = a;
        bValues(next, 1) = b;
        originalStart(next, :) = candidateStart;
        originalEnd(next, :) = candidateEnd;
        wrappedPieces{next, 1} = wrapped;
        matchedPieceIndex(next, 1) = matchedIndex;
    end
end

candidateCount = numel(candidateType);
if candidateCount == 0
    status = 'UNRESOLVED';
    selectedIndex = [];
elseif candidateCount == 1
    status = 'UNIQUE';
    selectedIndex = 1;
else
    status = 'AMBIGUOUS';
    selectedIndex = [];
end

result.RawLength = rawLength;
result.Status = status;
result.CandidateCount = candidateCount;
result.SelectedIndex = selectedIndex;
result.CandidateType = candidateType;
result.K = kValues;
result.A = aValues;
result.B = bValues;
result.OriginalStart = originalStart;
result.OriginalEnd = originalEnd;
result.WrappedPieces = wrappedPieces;
result.MatchedPieceIndex = matchedPieceIndex;
end

function axesMask = boundaryAxes(point, halfBox, tolerance)
axesMask = abs(abs(point) - halfBox) <= tolerance;
end

function distances = boundaryDistances(point, direction, maximumDistance, cfg)
distances = zeros(0, 1);
for axisIndex = 1:3
    component = direction(axisIndex);
    if abs(component) <= cfg.reconstructionTolerance, continue; end
    endValue = point(axisIndex) + maximumDistance * component;
    lower = min(point(axisIndex), endValue);
    upper = max(point(axisIndex), endValue);
    nMinimum = ceil((lower - cfg.HALF_L) / cfg.L);
    nMaximum = floor((upper - cfg.HALF_L) / cfg.L);
    for n = nMinimum:nMaximum
        boundary = cfg.HALF_L + n * cfg.L;
        distance = (boundary - point(axisIndex)) / component;
        if distance > cfg.reconstructionTolerance && ...
                distance < maximumDistance - cfg.reconstructionTolerance
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

function present = containsCandidate(starts, ends, candidateStart, ...
        candidateEnd, tolerance)
present = false;
for index = 1:size(starts, 1)
    if max(abs(starts(index, :) - candidateStart)) <= tolerance && ...
            max(abs(ends(index, :) - candidateEnd)) <= tolerance
        present = true;
        return;
    end
end
end

function [matched, pieceIndex] = containsObservedPiece(pieces, p1, p2, tolerance)
matched = false;
pieceIndex = 0;
for index = 1:size(pieces.Start, 1)
    forwardError = max([abs(pieces.Start(index, :) - p1) ...
        abs(pieces.End(index, :) - p2)]);
    reverseError = max([abs(pieces.Start(index, :) - p2) ...
        abs(pieces.End(index, :) - p1)]);
    if min(forwardError, reverseError) <= tolerance
        matched = true;
        pieceIndex = index;
        return;
    end
end
end

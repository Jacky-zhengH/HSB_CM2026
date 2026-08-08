function result = reconstructRowR2(p1, p2, cfg)
%RECONSTRUCTROWR2 Test finite same-row extension hypotheses A and B.
%   A valid candidate must reproduce the observed row after forward wrapping.

rawVector = p2 - p1;
rawLength = norm(rawVector);
if rawLength <= 0
    error('reconstructRowR2:ZeroLength', 'Raw record length must be positive.');
end

hypotheses = cell(0, 1);
starts = zeros(0, 3);
ends = zeros(0, 3);
if abs(rawLength - cfg.mediumALength) <= cfg.reconstructionTolerance
    hypotheses{1, 1} = 'DIRECT';
    starts(1, :) = p1;
    ends(1, :) = p2;
elseif rawLength < cfg.mediumALength
    unitDirection = rawVector / rawLength;
    missingLength = cfg.mediumALength - rawLength;
    hypotheses{1, 1} = 'A_EXTEND_AFTER_P2';
    starts(1, :) = p1;
    ends(1, :) = p2 + missingLength * unitDirection;
    hypotheses{2, 1} = 'B_EXTEND_BEFORE_P1';
    starts(2, :) = p1 - missingLength * unitDirection;
    ends(2, :) = p2;
end

candidateCount = numel(hypotheses);
valid = false(candidateCount, 1);
wrappedPieces = cell(candidateCount, 1);
matchedPieceIndex = zeros(candidateCount, 1);
for candidateIndex = 1:candidateCount
    wrappedPieces{candidateIndex} = wrapSegmentToBox( ...
        starts(candidateIndex, :), ends(candidateIndex, :), ...
        cfg.HALF_L, cfg.L, cfg.reconstructionTolerance);
    [valid(candidateIndex), matchedPieceIndex(candidateIndex)] = ...
        containsObservedPiece(wrappedPieces{candidateIndex}, p1, p2, ...
        cfg.reconstructionTolerance);
end

validIndices = find(valid);
if isempty(validIndices)
    status = 'UNRESOLVED';
    selectedIndex = [];
elseif numel(validIndices) == 1
    status = 'UNIQUE_RECONSTRUCTION';
    selectedIndex = validIndices(1);
else
    status = 'AMBIGUOUS';
    selectedIndex = [];
end

result.RawLength = rawLength;
result.Hypothesis = hypotheses;
result.OriginalStart = starts;
result.OriginalEnd = ends;
result.WrappedPieces = wrappedPieces;
result.Valid = valid;
result.ValidIndices = validIndices;
result.CandidateCount = numel(validIndices);
result.MatchedPieceIndex = matchedPieceIndex;
result.Status = status;
result.SelectedIndex = selectedIndex;
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

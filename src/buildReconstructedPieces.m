function pieces = buildReconstructedPieces(groupIndex, group, ...
        endpointResults, cfg)
%BUILDRECONSTRUCTEDPIECES Flatten only UNIQUE endpoint reconstructions.

pieces.Group = zeros(0, 1);
pieces.MediumID = zeros(0, 1);
pieces.PieceIndex = zeros(0, 1);
pieces.SourceExcelRow = zeros(0, 1);
pieces.WrappedInputP1 = zeros(0, 3);
pieces.WrappedInputP2 = zeros(0, 3);
pieces.UnwrappedStart = zeros(0, 3);
pieces.UnwrappedEnd = zeros(0, 3);
pieces.RelativeShiftK = zeros(0, 3);
pieces.PieceStart = zeros(0, 3);
pieces.PieceEnd = zeros(0, 3);
pieces.PieceLength = zeros(0, 1);
pieces.Translation = zeros(0, 3);
pieces.TStart = zeros(0, 1);
pieces.TEnd = zeros(0, 1);
pieces.BoundaryEventSequence = cell(0, 1);

for mediumID = 1:numel(endpointResults)
    item = endpointResults{mediumID};
    if ~strcmp(item.Status, 'UNIQUE'), continue; end
    selected = item.SelectedIndex;
    wrapped = item.WrappedPieces{selected};
    if size(wrapped.Start, 1) > 4 || ...
            any(wrapped.Length <= cfg.geometryTolerance) || ...
            abs(sum(wrapped.Length) - cfg.mediumALength) > ...
            cfg.endpointLengthTolerance
        error('buildReconstructedPieces:InvalidBoundaryPieces', ...
            'Group%d A%d violates Piece count/length invariants.', ...
            groupIndex, mediumID);
    end
    for pieceIndex = 1:size(wrapped.Start, 1)
        next = numel(pieces.MediumID) + 1;
        pieces.Group(next, 1) = groupIndex;
        pieces.MediumID(next, 1) = mediumID;
        pieces.PieceIndex(next, 1) = pieceIndex;
        pieces.SourceExcelRow(next, 1) = group.OriginalExcelRow(mediumID);
        pieces.WrappedInputP1(next, :) = group.P1(mediumID, :);
        pieces.WrappedInputP2(next, :) = group.P2(mediumID, :);
        pieces.UnwrappedStart(next, :) = item.UnwrappedStart(selected, :);
        pieces.UnwrappedEnd(next, :) = item.UnwrappedEnd(selected, :);
        pieces.RelativeShiftK(next, :) = item.CandidatesK(selected, :);
        pieces.PieceStart(next, :) = wrapped.Start(pieceIndex, :);
        pieces.PieceEnd(next, :) = wrapped.End(pieceIndex, :);
        pieces.PieceLength(next, 1) = wrapped.Length(pieceIndex);
        pieces.Translation(next, :) = wrapped.Translation(pieceIndex, :);
        pieces.TStart(next, 1) = wrapped.TStart(pieceIndex);
        pieces.TEnd(next, 1) = wrapped.TEnd(pieceIndex);
        pieces.BoundaryEventSequence{next, 1} = ...
            item.BoundaryEventSequence{selected};
    end
end
end

function pieces = buildRetainedPartPieces(groupIndex, group, results, cfg)
%BUILDRETAINEDPARTPIECES Flatten uniquely reconstructed retained-part media.

pieces.Group = zeros(0, 1);
pieces.MediumID = zeros(0, 1);
pieces.PieceIndex = zeros(0, 1);
pieces.SourceExcelRow = zeros(0, 1);
pieces.ObservedP1 = zeros(0, 3);
pieces.ObservedP2 = zeros(0, 3);
pieces.OriginalStart = zeros(0, 3);
pieces.OriginalEnd = zeros(0, 3);
pieces.PieceStart = zeros(0, 3);
pieces.PieceEnd = zeros(0, 3);
pieces.PieceLength = zeros(0, 1);
pieces.Translation = zeros(0, 3);
pieces.TStart = zeros(0, 1);
pieces.TEnd = zeros(0, 1);
pieces.BoundarySequence = cell(0, 1);
pieces.ReconstructionType = cell(0, 1);

for mediumID = 1:numel(results)
    item = results{mediumID};
    if ~item.IsUniquelyReconstructed, continue; end
    wrapped = item.ForwardPieces;
    if size(wrapped.Start, 1) > 4 || any(wrapped.Length <= cfg.geometryTolerance) || ...
            abs(sum(wrapped.Length) - cfg.mediumALength) > cfg.lengthTolerance
        error('buildRetainedPartPieces:InvariantFailed', ...
            'Group%d A%d violates Piece count/length invariants.', ...
            groupIndex, mediumID);
    end
    for pieceIndex = 1:size(wrapped.Start, 1)
        next = numel(pieces.MediumID) + 1;
        pieces.Group(next, 1) = groupIndex;
        pieces.MediumID(next, 1) = mediumID;
        pieces.PieceIndex(next, 1) = pieceIndex;
        pieces.SourceExcelRow(next, 1) = group.OriginalExcelRow(mediumID);
        pieces.ObservedP1(next, :) = group.P1(mediumID, :);
        pieces.ObservedP2(next, :) = group.P2(mediumID, :);
        pieces.OriginalStart(next, :) = item.ReconstructedOriginalStart;
        pieces.OriginalEnd(next, :) = item.ReconstructedOriginalEnd;
        pieces.PieceStart(next, :) = wrapped.Start(pieceIndex, :);
        pieces.PieceEnd(next, :) = wrapped.End(pieceIndex, :);
        pieces.PieceLength(next, 1) = wrapped.Length(pieceIndex);
        pieces.Translation(next, :) = wrapped.Translation(pieceIndex, :);
        pieces.TStart(next, 1) = wrapped.TStart(pieceIndex);
        pieces.TEnd(next, 1) = wrapped.TEnd(pieceIndex);
        pieces.BoundarySequence{next, 1} = item.BoundaryEventSequence;
        pieces.ReconstructionType{next, 1} = item.Classification;
    end
end
end

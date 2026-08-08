function pieces = buildReconstructedPieces(groupIndex, group, ...
        reconstructionResults, cfg)
%BUILDRECONSTRUCTEDPIECES Flatten only uniquely reconstructed Mediums.

pieces.Group = zeros(0, 1);
pieces.MediumID = zeros(0, 1);
pieces.PieceIndex = zeros(0, 1);
pieces.SourceExcelRow = zeros(0, 1);
pieces.OriginalStart = zeros(0, 3);
pieces.OriginalEnd = zeros(0, 3);
pieces.PieceStart = zeros(0, 3);
pieces.PieceEnd = zeros(0, 3);
pieces.PieceLength = zeros(0, 1);
pieces.Translation = zeros(0, 3);
pieces.CrossedAxisEvent = cell(0, 1);

for mediumID = 1:numel(reconstructionResults)
    item = reconstructionResults{mediumID};
    if ~strcmp(item.Status, 'UNIQUE'), continue; end
    selected = item.SelectedIndex;
    wrapped = item.WrappedPieces{selected};
    if size(wrapped.Start, 1) > 4 || ...
            any(wrapped.Length <= cfg.reconstructionTolerance) || ...
            abs(sum(wrapped.Length) - cfg.mediumALength) > ...
            cfg.reconstructionTolerance
        error('buildReconstructedPieces:InvalidBoundaryPieces', ...
            'Group%d A%d violates the formal Piece count/length invariants.', ...
            groupIndex, mediumID);
    end
    [~, events] = extractBoundaryEvents(wrapped.Translation);
    for pieceIndex = 1:size(wrapped.Start, 1)
        next = numel(pieces.MediumID) + 1;
        pieces.Group(next, 1) = groupIndex;
        pieces.MediumID(next, 1) = mediumID;
        pieces.PieceIndex(next, 1) = pieceIndex;
        pieces.SourceExcelRow(next, 1) = group.OriginalExcelRow(mediumID);
        pieces.OriginalStart(next, :) = item.OriginalStart(selected, :);
        pieces.OriginalEnd(next, :) = item.OriginalEnd(selected, :);
        pieces.PieceStart(next, :) = wrapped.Start(pieceIndex, :);
        pieces.PieceEnd(next, :) = wrapped.End(pieceIndex, :);
        pieces.PieceLength(next, 1) = wrapped.Length(pieceIndex);
        pieces.Translation(next, :) = wrapped.Translation(pieceIndex, :);
        pieces.CrossedAxisEvent{next, 1} = events{pieceIndex};
    end
end
end

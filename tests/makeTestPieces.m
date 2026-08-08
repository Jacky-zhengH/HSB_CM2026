function pieces = makeTestPieces(starts, ends, mediumIDs)
%MAKETESTPIECES Build the minimal production-compatible Piece structure.

pieceCount = size(starts, 1);
if size(ends, 1) ~= pieceCount || numel(mediumIDs) ~= pieceCount
    error('makeTestPieces:SizeMismatch', 'Test Piece inputs must have equal sizes.');
end
mediumIDs = mediumIDs(:);
pieceIndices = zeros(pieceCount, 1);
for index = 1:pieceCount
    pieceIndices(index) = sum(mediumIDs(1:index) == mediumIDs(index));
end

pieces.Group = ones(pieceCount, 1);
pieces.MediumID = mediumIDs;
pieces.PieceIndex = pieceIndices;
pieces.SourceExcelRow = mediumIDs;
pieces.OriginalStart = starts;
pieces.OriginalEnd = ends;
pieces.PieceStart = starts;
pieces.PieceEnd = ends;
pieces.PieceLength = sqrt(sum((ends - starts).^2, 2));
pieces.Translation = zeros(pieceCount, 3);
pieces.CrossedAxisEvent = repmat({'NONE'}, pieceCount, 1);
end

function pieces = buildModelPieces(groupIndex, group, analysis, modelName, r1Results, r2Results, cfg)
%BUILDMODELPIECES Create resolved GeometryPieces without cross-row sharing.

pieces.Group = zeros(0, 1);
pieces.Model = cell(0, 1);
pieces.MediumID = zeros(0, 1);
pieces.PieceIndex = zeros(0, 1);
pieces.SourceExcelRow = zeros(0, 1);
pieces.OriginalStart = zeros(0, 3);
pieces.OriginalEnd = zeros(0, 3);
pieces.PieceStart = zeros(0, 3);
pieces.PieceEnd = zeros(0, 3);
pieces.PieceLength = zeros(0, 1);
pieces.Translation = zeros(0, 3);

for mediumID = 1:analysis.Records
    if strcmp(modelName, 'R0')
        originalStart = analysis.P1(mediumID, :);
        originalEnd = analysis.P2(mediumID, :);
        wrapped.Start = originalStart;
        wrapped.End = originalEnd;
        wrapped.Length = analysis.SegmentLength(mediumID);
        wrapped.Translation = [0 0 0];
    elseif strcmp(modelName, 'R1')
        item = r1Results{mediumID};
        if isempty(item.SelectedIndex)
            continue;
        end
        originalStart = analysis.P1(mediumID, :);
        originalEnd = analysis.P2(mediumID, :) + ...
            cfg.L * item.K(item.SelectedIndex, :);
        wrapped = wrapSegmentToBox(originalStart, originalEnd, ...
            cfg.HALF_L, cfg.L, cfg.reconstructionTolerance);
    elseif strcmp(modelName, 'R2')
        item = r2Results{mediumID};
        if isempty(item.SelectedIndex)
            continue;
        end
        originalStart = item.OriginalStart(item.SelectedIndex, :);
        originalEnd = item.OriginalEnd(item.SelectedIndex, :);
        wrapped = item.WrappedPieces{item.SelectedIndex};
    else
        error('buildModelPieces:UnknownModel', 'Unknown model: %s', modelName);
    end

    for pieceIndex = 1:size(wrapped.Start, 1)
        next = numel(pieces.MediumID) + 1;
        pieces.Group(next, 1) = groupIndex;
        pieces.Model{next, 1} = modelName;
        pieces.MediumID(next, 1) = mediumID;
        pieces.PieceIndex(next, 1) = pieceIndex;
        pieces.SourceExcelRow(next, 1) = group.OriginalExcelRow(mediumID);
        pieces.OriginalStart(next, :) = originalStart;
        pieces.OriginalEnd(next, :) = originalEnd;
        pieces.PieceStart(next, :) = wrapped.Start(pieceIndex, :);
        pieces.PieceEnd(next, :) = wrapped.End(pieceIndex, :);
        pieces.PieceLength(next, 1) = wrapped.Length(pieceIndex);
        pieces.Translation(next, :) = wrapped.Translation(pieceIndex, :);
    end
end
end

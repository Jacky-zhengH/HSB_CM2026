function writeQ1Tables(groups, analyses, reconstructions, piecesByGroup, ...
        graphs, charges, groupStats, tableDir)
%WRITEQ1TABLES Write the formal, non-versioned Q1 audit tables.

fileID = openOutput(fullfile(tableDir, 'medium_reconstruction.csv'));
fprintf(fileID, ['Group,MediumID,RawLength,Status,CandidateCount,' ...
    'SelectedCandidate,PieceCount\n']);
for groupIndex = 1:3
    for mediumID = 1:analyses{groupIndex}.Records
        item = reconstructions{groupIndex}{mediumID};
        if isempty(item.SelectedIndex)
            selected = 0; pieceCount = 0;
        else
            selected = item.SelectedIndex;
            pieceCount = size(item.WrappedPieces{selected}.Start, 1);
        end
        fprintf(fileID, '%d,A%d,%.15g,%s,%d,%d,%d\n', groupIndex, ...
            mediumID, item.RawLength, item.Status, item.CandidateCount, ...
            selected, pieceCount);
    end
end
fclose(fileID);

fileID = openOutput(fullfile(tableDir, 'reconstructed_pieces.csv'));
fprintf(fileID, ['Group,MediumID,PieceIndex,SourceExcelRow,' ...
    'OriginalStartX,OriginalStartY,OriginalStartZ,OriginalEndX,' ...
    'OriginalEndY,OriginalEndZ,PieceStartX,PieceStartY,PieceStartZ,' ...
    'PieceEndX,PieceEndY,PieceEndZ,PieceLength,TranslationX,' ...
    'TranslationY,TranslationZ,CrossedAxisEvent\n']);
for groupIndex = 1:3
    pieces = piecesByGroup{groupIndex};
    for pieceIndex = 1:numel(pieces.MediumID)
        fprintf(fileID, ['%d,A%d,%d,%d,%.15g,%.15g,%.15g,%.15g,' ...
            '%.15g,%.15g,%.15g,%.15g,%.15g,%.15g,%.15g,%.15g,' ...
            '%.15g,%.15g,%.15g,%.15g,%s\n'], groupIndex, ...
            pieces.MediumID(pieceIndex), pieces.PieceIndex(pieceIndex), ...
            pieces.SourceExcelRow(pieceIndex), ...
            pieces.OriginalStart(pieceIndex, :), ...
            pieces.OriginalEnd(pieceIndex, :), ...
            pieces.PieceStart(pieceIndex, :), pieces.PieceEnd(pieceIndex, :), ...
            pieces.PieceLength(pieceIndex), pieces.Translation(pieceIndex, :), ...
            pieces.CrossedAxisEvent{pieceIndex});
    end
end
fclose(fileID);

fileID = openOutput(fullfile(tableDir, 'piece_count_audit.csv'));
fprintf(fileID, ['Group,MediumID,ReconstructionStatus,PieceCount,' ...
    'OriginalStartX,OriginalStartY,OriginalStartZ,OriginalEndX,' ...
    'OriginalEndY,OriginalEndZ,TotalPieceLength,CrossedAxisSequence,' ...
    'TouchesLEFT,TouchesRIGHT,DirectElectrodePieceCount,ChargedPieceCount\n']);
for groupIndex = 1:3
    pieces = piecesByGroup{groupIndex};
    graph = graphs{groupIndex};
    charge = charges{groupIndex};
    for mediumID = 1:analyses{groupIndex}.Records
        item = reconstructions{groupIndex}{mediumID};
        if strcmp(item.Status, 'UNIQUE')
            selected = item.SelectedIndex;
            wrapped = item.WrappedPieces{selected};
            [sequence, ~] = extractBoundaryEvents(wrapped.Translation);
            indices = find(pieces.MediumID == mediumID);
            pieceCount = numel(indices);
            totalLength = sum(pieces.PieceLength(indices));
            touchesLeft = any(graph.LeftContact(indices));
            touchesRight = any(graph.RightContact(indices));
            directCount = sum(charge.DirectElectrodeCharged(indices));
            chargedCount = sum(charge.PieceCharged(indices));
            startPoint = item.OriginalStart(selected, :);
            endPoint = item.OriginalEnd(selected, :);
        else
            pieceCount = 0; totalLength = NaN;
            sequence = 'NOT_RECONSTRUCTED';
            touchesLeft = false; touchesRight = false;
            directCount = 0; chargedCount = 0;
            startPoint = [NaN NaN NaN]; endPoint = [NaN NaN NaN];
        end
        fprintf(fileID, ['%d,A%d,%s,%d,%.15g,%.15g,%.15g,%.15g,' ...
            '%.15g,%.15g,%.15g,%s,%d,%d,%d,%d\n'], groupIndex, mediumID, ...
            item.Status, pieceCount, startPoint, endPoint, totalLength, ...
            sequence, touchesLeft, touchesRight, directCount, chargedCount);
    end
end
fclose(fileID);

fileID = openOutput(fullfile(tableDir, 'charge_state_audit.csv'));
fprintf(fileID, ['Group,MediumID,PieceIndex,LeftContact,RightContact,' ...
    'DirectElectrodeCharged,ActivatedByGeometry,InheritedFromSameMedium,' ...
    'PieceCharged,ChargeSource\n']);
for groupIndex = 1:3
    pieces = piecesByGroup{groupIndex}; graph = graphs{groupIndex};
    charge = charges{groupIndex};
    for pieceIndex = 1:numel(pieces.MediumID)
        fprintf(fileID, '%d,A%d,%d,%d,%d,%d,%d,%d,%d,%s\n', ...
            groupIndex, pieces.MediumID(pieceIndex), ...
            pieces.PieceIndex(pieceIndex), graph.LeftContact(pieceIndex), ...
            graph.RightContact(pieceIndex), ...
            charge.DirectElectrodeCharged(pieceIndex), ...
            charge.ActivatedByGeometry(pieceIndex), ...
            charge.InheritedFromSameMedium(pieceIndex), ...
            charge.PieceCharged(pieceIndex), charge.ChargeSource{pieceIndex});
    end
end
fclose(fileID);

fileID = openOutput(fullfile(tableDir, 'physical_edges.csv'));
fprintf(fileID, 'Group,EdgeType,NodeA,NodeB,AxisDistance,ExactDistance\n');
for groupIndex = 1:3
    pieces = piecesByGroup{groupIndex}; graph = graphs{groupIndex};
    for edgeIndex = 1:size(graph.GeometryEdges, 1)
        a = graph.GeometryEdges(edgeIndex, 1);
        b = graph.GeometryEdges(edgeIndex, 2);
        fprintf(fileID, '%d,PIECE_PIECE,%s,%s,%.15g,%.15g\n', ...
            groupIndex, pieceLabel(pieces, a), pieceLabel(pieces, b), ...
            graph.GeometryAxisDistance(edgeIndex), ...
            graph.GeometryExactDistance(edgeIndex));
    end
    for pieceIndex = find(graph.LeftContact(:))'
        fprintf(fileID, '%d,ELECTRODE,LEFT,%s,NaN,%.15g\n', groupIndex, ...
            pieceLabel(pieces, pieceIndex), graph.LeftDistance(pieceIndex));
    end
    for pieceIndex = find(graph.RightContact(:))'
        fprintf(fileID, '%d,ELECTRODE,%s,RIGHT,NaN,%.15g\n', groupIndex, ...
            pieceLabel(pieces, pieceIndex), graph.RightDistance(pieceIndex));
    end
end
fclose(fileID);

fileID = openOutput(fullfile(tableDir, 'q1_results.csv'));
fprintf(fileID, ['Group,Records,UniqueReconstruction,Ambiguous,Unresolved,' ...
    'PieceCount,ChargedMediumCount,ChargedPieceCount,Q1Status,BFSPath\n']);
for groupIndex = 1:3
    stats = groupStats(groupIndex);
    fprintf(fileID, '%d,%d,%d,%d,%d,%d,%d,%d,%s,%s\n', groupIndex, ...
        stats.Records, stats.Unique, stats.Ambiguous, stats.Unresolved, ...
        stats.TotalPieces, stats.ChargedMediums, stats.ChargedPieces, ...
        stats.Q1Status, stats.BFSPath);
end
fclose(fileID);
end

function label = pieceLabel(pieces, pieceIndex)
label = sprintf('A%d-%d', pieces.MediumID(pieceIndex), ...
    pieces.PieceIndex(pieceIndex));
end

function fileID = openOutput(path)
fileID = fopen(path, 'w');
if fileID < 0
    error('writeQ1Tables:OutputOpenFailed', 'Cannot write: %s', path);
end
end

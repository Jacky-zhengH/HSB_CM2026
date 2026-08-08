function writeQ1Tables(piecesByGroup, graphs, charges, groupStats, tableDir)
%WRITEQ1TABLES Write electrical results only after the endpoint hard gate.

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

fileID = openOutput(fullfile(tableDir, 'q1_final_results.csv'));
fprintf(fileID, ['Group,MediumCount,PieceCount,PhysicalEdgeCount,' ...
    'LeftContactPieces,RightContactPieces,ChargedMediumCount,' ...
    'ChargedPieceCount,Conducting,BFSPath\n']);
for groupIndex = 1:3
    stats = groupStats(groupIndex);
    fprintf(fileID, '%d,%d,%d,%d,%d,%d,%d,%d,%d,%s\n', groupIndex, ...
        stats.Records, stats.TotalPieces, stats.PhysicalEdgeCount, ...
        stats.LeftContactPieces, stats.RightContactPieces, ...
        stats.ChargedMediumCount, stats.ChargedPieceCount, ...
        stats.Conducting, stats.BFSPath);
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
    error('writeQ1Tables:OpenFailed', 'Cannot write %s.', path);
end
end

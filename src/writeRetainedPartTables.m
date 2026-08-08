function writeRetainedPartTables(groups, resultsByGroup, piecesByGroup, ...
        graphs, charges, groupStats, tableDir, modelComplete)
%WRITERETAINEDPARTTABLES Write retained-part, Piece, and graph diagnostics.

fileID = openOutput(fullfile(tableDir, 'retained_reconstruction_audit.csv'));
fprintf(fileID, ['Group,MediumID,ExcelRow,RawLength,BoundaryEndpointCount,' ...
    'P1BoundaryAxes,P2BoundaryAxes,HasAbs500Coordinate,Classification,Status,' ...
    'InteriorPointXYZ,BoundaryPointXYZ,ObservedDirectionXYZ,MissingLength,' ...
    'OriginalStartXYZ,OriginalEndXYZ,ForwardPieceCount,BoundaryEventSequence,' ...
    'ObservedPieceMatched,MatchedPieceIndex,MatchedPieceTranslationXYZ,' ...
    'ReplayError,PhysicalCandidateCount,IsUniquelyReconstructed,Reason\n']);
for groupIndex = 1:3
    group = groups(groupIndex);
    for mediumID = 1:numel(resultsByGroup{groupIndex})
        item = resultsByGroup{groupIndex}{mediumID};
        fprintf(fileID, '%d,A%d,%d,%.15g,%d,', groupIndex, mediumID, ...
            group.OriginalExcelRow(mediumID), item.RawLength, ...
            item.BoundaryEndpointCount);
        writeText(fileID, item.P1BoundaryAxes); fprintf(fileID, ',');
        writeText(fileID, item.P2BoundaryAxes); fprintf(fileID, ',%d,', ...
            item.HasAbs500Coordinate);
        writeText(fileID, item.Classification); fprintf(fileID, ',');
        writeText(fileID, item.Status); fprintf(fileID, ',');
        writeText(fileID, vectorText(item.InteriorPoint)); fprintf(fileID, ',');
        writeText(fileID, vectorText(item.BoundaryPoint)); fprintf(fileID, ',');
        writeText(fileID, vectorText(item.ObservedDirection));
        fprintf(fileID, ',%.15g,', item.MissingLength);
        writeText(fileID, vectorText(item.ReconstructedOriginalStart));
        fprintf(fileID, ',');
        writeText(fileID, vectorText(item.ReconstructedOriginalEnd));
        fprintf(fileID, ',%d,', item.ForwardPieceCount);
        writeText(fileID, item.BoundaryEventSequence);
        fprintf(fileID, ',%d,%d,', item.ObservedPieceMatched, ...
            item.MatchedPieceIndex);
        writeText(fileID, vectorText(item.MatchedPieceTranslation));
        fprintf(fileID, ',%.15g,%.15g,%d,', item.MaxReplayError, ...
            item.PhysicalCandidateCount, item.IsUniquelyReconstructed);
        writeText(fileID, item.Reason); fprintf(fileID, '\n');
    end
end
fclose(fileID);

fileID = openOutput(fullfile(tableDir, 'reconstructed_pieces.csv'));
fprintf(fileID, ['Group,MediumID,PieceIndex,SourceExcelRow,ObservedP1,' ...
    'ObservedP2,OriginalStart,OriginalEnd,PieceStart,PieceEnd,PieceLength,' ...
    'Translation,BoundarySequence,ReconstructionType\n']);
for groupIndex = 1:3
    pieces = piecesByGroup{groupIndex};
    for pieceIndex = 1:numel(pieces.MediumID)
        fprintf(fileID, '%d,A%d,%d,%d,', groupIndex, ...
            pieces.MediumID(pieceIndex), pieces.PieceIndex(pieceIndex), ...
            pieces.SourceExcelRow(pieceIndex));
        fields = {pieces.ObservedP1(pieceIndex, :), ...
            pieces.ObservedP2(pieceIndex, :), pieces.OriginalStart(pieceIndex, :), ...
            pieces.OriginalEnd(pieceIndex, :), pieces.PieceStart(pieceIndex, :), ...
            pieces.PieceEnd(pieceIndex, :)};
        for fieldIndex = 1:numel(fields)
            writeText(fileID, vectorText(fields{fieldIndex})); fprintf(fileID, ',');
        end
        fprintf(fileID, '%.15g,', pieces.PieceLength(pieceIndex));
        writeText(fileID, vectorText(pieces.Translation(pieceIndex, :)));
        fprintf(fileID, ','); writeText(fileID, pieces.BoundarySequence{pieceIndex});
        fprintf(fileID, ','); writeText(fileID, pieces.ReconstructionType{pieceIndex});
        fprintf(fileID, '\n');
    end
end
fclose(fileID);

fileID = openOutput(fullfile(tableDir, 'retained_classification_summary.csv'));
fprintf(fileID, ['Group,Records,Direct5000,SingleBoundaryShort,' ...
    'SingleBoundaryRecovered,TwoBoundaryShort,NoBoundaryShort,ReplayFailed,' ...
    'HasAbs500Coordinate,NoBoundaryHasAbs500,UniqueReconstructed,' ...
    'Ambiguous,Unresolved,Invalid\n']);
for groupIndex = 1:3
    writeStatsRow(fileID, groupIndex, groupStats(groupIndex));
end
totalStats = sumStats(groupStats);
writeStatsRow(fileID, 0, totalStats);
fclose(fileID);

fileID = openOutput(fullfile(tableDir, 'single_boundary_replay_summary.csv'));
fprintf(fileID, 'Group,SingleBoundaryTotal,Recovered,ReplayFailed,RecoveryRate\n');
for groupIndex = 1:3
    stats = groupStats(groupIndex);
    rate = stats.SingleBoundaryRecovered / max(1, stats.SingleBoundaryShort);
    fprintf(fileID, '%d,%d,%d,%d,%.15g\n', groupIndex, ...
        stats.SingleBoundaryShort, stats.SingleBoundaryRecovered, ...
        stats.ReplayFailed, rate);
end
rate = totalStats.SingleBoundaryRecovered / max(1, totalStats.SingleBoundaryShort);
fprintf(fileID, '0,%d,%d,%d,%.15g\n', totalStats.SingleBoundaryShort, ...
    totalStats.SingleBoundaryRecovered, totalStats.ReplayFailed, rate);
fclose(fileID);

fileID = openOutput(fullfile(tableDir, 'piece_count_audit.csv'));
fprintf(fileID, 'Group,UniqueMediums,OnePiece,TwoPieces,ThreePieces,FourPieces,TotalPieces\n');
for groupIndex = 1:3
    stats = groupStats(groupIndex);
    fprintf(fileID, '%d,%d,%d,%d,%d,%d,%d\n', groupIndex, stats.Unique, ...
        stats.PieceCountByMedium(1), stats.PieceCountByMedium(2), ...
        stats.PieceCountByMedium(3), stats.PieceCountByMedium(4), ...
        stats.TotalPieces);
end
fprintf(fileID, '0,%d,%d,%d,%d,%d,%d\n', totalStats.Unique, ...
    totalStats.PieceCountByMedium(1), totalStats.PieceCountByMedium(2), ...
    totalStats.PieceCountByMedium(3), totalStats.PieceCountByMedium(4), ...
    totalStats.TotalPieces);
fclose(fileID);

if modelComplete
    scope = 'FULL_RECONSTRUCTION';
else
    scope = 'UNIQUE_ONLY_LOWER_BOUND';
end
fileID = openOutput(fullfile(tableDir, 'physical_edges.csv'));
fprintf(fileID, 'Scope,Group,EdgeType,NodeA,NodeB,AxisDistance,ExactDistance\n');
for groupIndex = 1:3
    pieces = piecesByGroup{groupIndex}; graph = graphs{groupIndex};
    for edgeIndex = 1:size(graph.GeometryEdges, 1)
        a = graph.GeometryEdges(edgeIndex, 1); b = graph.GeometryEdges(edgeIndex, 2);
        fprintf(fileID, '%s,%d,PIECE_PIECE,%s,%s,%.15g,%.15g\n', ...
            scope, groupIndex, pieceLabel(pieces, a), pieceLabel(pieces, b), ...
            graph.GeometryAxisDistance(edgeIndex), graph.GeometryExactDistance(edgeIndex));
    end
    for pieceIndex = find(graph.LeftContact(:))'
        fprintf(fileID, '%s,%d,ELECTRODE,LEFT,%s,NaN,%.15g\n', scope, ...
            groupIndex, pieceLabel(pieces, pieceIndex), graph.LeftDistance(pieceIndex));
    end
    for pieceIndex = find(graph.RightContact(:))'
        fprintf(fileID, '%s,%d,ELECTRODE,%s,RIGHT,NaN,%.15g\n', scope, ...
            groupIndex, pieceLabel(pieces, pieceIndex), graph.RightDistance(pieceIndex));
    end
end
fclose(fileID);

fileID = openOutput(fullfile(tableDir, 'charge_state_audit.csv'));
fprintf(fileID, ['Scope,Group,MediumID,PieceIndex,LeftContact,RightContact,' ...
    'DirectElectrodeCharged,ActivatedByGeometry,InheritedFromSameMedium,' ...
    'PieceCharged,ChargeSource\n']);
for groupIndex = 1:3
    pieces = piecesByGroup{groupIndex}; graph = graphs{groupIndex};
    charge = charges{groupIndex};
    for pieceIndex = 1:numel(pieces.MediumID)
        fprintf(fileID, '%s,%d,A%d,%d,%d,%d,%d,%d,%d,%d,%s\n', scope, ...
            groupIndex, pieces.MediumID(pieceIndex), pieces.PieceIndex(pieceIndex), ...
            graph.LeftContact(pieceIndex), graph.RightContact(pieceIndex), ...
            charge.DirectElectrodeCharged(pieceIndex), ...
            charge.ActivatedByGeometry(pieceIndex), ...
            charge.InheritedFromSameMedium(pieceIndex), ...
            charge.PieceCharged(pieceIndex), charge.ChargeSource{pieceIndex});
    end
end
fclose(fileID);

fileID = openOutput(fullfile(tableDir, 'q1_results.csv'));
fprintf(fileID, ['Group,Q1ModelComplete,GraphScope,UniqueMediums,TotalRecords,' ...
    'PieceCount,PhysicalEdgeCount,LeftContactPieces,RightContactPieces,' ...
    'UniqueOnlyConducting,FinalStatus,BFSPath\n']);
for groupIndex = 1:3
    stats = groupStats(groupIndex);
    fprintf(fileID, '%d,%d,%s,%d,%d,%d,%d,%d,%d,%d,%s,', groupIndex, ...
        modelComplete, scope, stats.Unique, stats.Records, stats.TotalPieces, ...
        stats.PhysicalEdgeCount, stats.LeftContactPieces, ...
        stats.RightContactPieces, stats.UniqueOnlyConducting, stats.FinalStatus);
    writeText(fileID, stats.BFSPath); fprintf(fileID, '\n');
end
fclose(fileID);
end

function writeStatsRow(fileID, groupIndex, stats)
fprintf(fileID, '%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d\n', ...
    groupIndex, stats.Records, stats.Direct, stats.SingleBoundaryShort, ...
    stats.SingleBoundaryRecovered, stats.TwoBoundaryShort, ...
    stats.NoBoundaryShort, stats.ReplayFailed, stats.HasAbs500, ...
    stats.NoBoundaryHasAbs500, stats.Unique, stats.Ambiguous, ...
    stats.Unresolved, stats.Invalid);
end

function total = sumStats(stats)
names = {'Records','Direct','SingleBoundaryShort','SingleBoundaryRecovered', ...
    'TwoBoundaryShort','NoBoundaryShort','ReplayFailed','HasAbs500', ...
    'NoBoundaryHasAbs500', ...
    'Unique','Ambiguous','Unresolved','Invalid','TotalPieces'};
for index = 1:numel(names)
    total.(names{index}) = sum([stats.(names{index})]);
end
total.PieceCountByMedium = sum(vertcat(stats.PieceCountByMedium), 1);
end

function label = pieceLabel(pieces, pieceIndex)
label = sprintf('A%d-%d', pieces.MediumID(pieceIndex), pieces.PieceIndex(pieceIndex));
end

function value = vectorText(vector)
value = sprintf('%.15g;%.15g;%.15g', vector(1), vector(2), vector(3));
end

function writeText(fileID, value)
value = strrep(value, '"', '""');
fprintf(fileID, '"%s"', value);
end

function fileID = openOutput(path)
fileID = fopen(path, 'w');
if fileID < 0
    error('writeRetainedPartTables:OpenFailed', 'Cannot write %s.', path);
end
end

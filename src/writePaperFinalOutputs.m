function writePaperFinalOutputs(outputDir, tableDir, branchName, baseCommit, ...
        matlabVersion, groupStats, upper, cfg)
%WRITEPAPERFINALOUTPUTS Write final Q1 proof tables and summary.

fileID = openOutput(fullfile(tableDir, 'q1_final_results.csv'));
fprintf(fileID, ['Group,MediumCount,UniqueMediums,AmbiguousMediums,' ...
    'UnresolvedMediums,PieceCount,PhysicalEdges,LeftContacts,RightContacts,' ...
    'LowerBoundConducting,UpperBoundChecked,UpperBoundConducting,ProofType,' ...
    'FinalConducting,FinalStatus,BFSPath\n']);
for groupIndex = 1:3
    stats = groupStats(groupIndex);
    fprintf(fileID, '%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,', ...
        groupIndex, stats.Records, stats.Unique, stats.Ambiguous, ...
        stats.Unresolved, stats.TotalPieces, stats.PhysicalEdgeCount, ...
        stats.LeftContactPieces, stats.RightContactPieces, ...
        stats.LowerBoundConducting, stats.UpperBoundChecked, ...
        stats.UpperBoundConducting);
    writeText(fileID, stats.ProofType); fprintf(fileID, ',%d,', ...
        stats.FinalConducting);
    writeText(fileID, stats.FinalStatus); fprintf(fileID, ',');
    writeText(fileID, stats.BFSPath); fprintf(fileID, '\n');
end
fclose(fileID);

fileID = openOutput(fullfile(tableDir, 'group1_upper_bound_audit.csv'));
fprintf(fileID, ['RecordType,MediumID,ExcelRow,ObservedP1,ObservedP2,' ...
    'ObservedLength,MissingLength,EnvelopeStart,EnvelopeEnd,EnvelopeLength,' ...
    'EnvelopePieceCount,BoundarySequence,MetricValue,Threshold,Pass,Details\n']);
for index = 1:numel(upper.Envelopes)
    item = upper.Envelopes(index);
    fprintf(fileID, 'ENVELOPE,A%d,%d,', item.MediumID, item.SourceExcelRow);
    writeText(fileID, vectorText(item.ObservedP1)); fprintf(fileID, ',');
    writeText(fileID, vectorText(item.ObservedP2));
    fprintf(fileID, ',%.15g,%.15g,', item.ObservedLength, item.MissingLength);
    writeText(fileID, vectorText(item.EnvelopeStart)); fprintf(fileID, ',');
    writeText(fileID, vectorText(item.EnvelopeEnd));
    fprintf(fileID, ',%.15g,%d,', item.EnvelopeLength, item.PieceCount);
    writeText(fileID, item.BoundarySequence);
    fprintf(fileID, ',NaN,%.15g,1,', cfg.broadPhaseDistance);
    writeText(fileID, 'Proof-only optimistic envelope; not a physical reconstruction.');
    fprintf(fileID, '\n');
end
writeMetric(fileID, 'MIN_ENVELOPE_KNOWN_AXIS_DISTANCE', ...
    upper.MinEnvelopeToKnownAxisDistance, cfg.broadPhaseDistance, ...
    upper.MinEnvelopeToKnownAxisDistance > cfg.broadPhaseDistance, ...
    pairText(upper.Pieces, upper.MinEnvelopeToKnownPair));
writeMetric(fileID, 'MIN_ENVELOPE_ENVELOPE_AXIS_DISTANCE', ...
    upper.MinEnvelopeToEnvelopeAxisDistance, cfg.broadPhaseDistance, ...
    upper.MinEnvelopeToEnvelopeAxisDistance > cfg.broadPhaseDistance, ...
    pairText(upper.Pieces, upper.MinEnvelopeToEnvelopePair));
writeMetric(fileID, 'UPPER_BOUND_CONDUCTING', double(upper.Conducting), 0, ...
    ~upper.Conducting, '0 certifies no LEFT-RIGHT path in optimistic supergraph.');
fclose(fileID);

fileID = openOutput(fullfile(tableDir, 'q1_reconstruction_summary.csv'));
fprintf(fileID, ['Group,Records,Direct,SingleBoundary,Recovered,ReplayFailed,' ...
    'TwoBoundary,NoBoundaryShort,Unique,Ambiguous,Unresolved,' ...
    'OnePiece,TwoPieces,ThreePieces,FourPieces\n']);
for groupIndex = 1:3
    stats = groupStats(groupIndex);
    fprintf(fileID, '%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d\n', ...
        groupIndex, stats.Records, stats.Direct, stats.SingleBoundaryShort, ...
        stats.SingleBoundaryRecovered, stats.ReplayFailed, ...
        stats.TwoBoundaryShort, stats.NoBoundaryShort, stats.Unique, ...
        stats.Ambiguous, stats.Unresolved, stats.PieceCountByMedium(1), ...
        stats.PieceCountByMedium(2), stats.PieceCountByMedium(3), ...
        stats.PieceCountByMedium(4));
end
fclose(fileID);

summaryPath = fullfile(outputDir, 'q1_final_summary.txt');
fileID = openOutput(summaryPath);
fprintf(fileID, 'Q1 PAPER FINAL\r\nBranch=%s\r\nBaseCommit=%s\r\n', ...
    branchName, baseCommit);
fprintf(fileID, 'MATLABVersion=%s\r\n\r\n', matlabVersion);
fprintf(fileID, 'Group1UpperBoundConducting=%d\r\n', upper.Conducting);
fprintf(fileID, 'MinEnvelopeToKnownAxisDistance=%.15g nm\r\n', ...
    upper.MinEnvelopeToKnownAxisDistance);
fprintf(fileID, 'MinEnvelopeToEnvelopeAxisDistance=%.15g nm\r\n', ...
    upper.MinEnvelopeToEnvelopeAxisDistance);
fprintf(fileID, 'AxisThreshold=%.15g nm\r\n\r\n', cfg.broadPhaseDistance);
for groupIndex = 1:3
    stats = groupStats(groupIndex);
    fprintf(fileID, ['Group%d LowerBoundConducting=%d UpperBoundChecked=%d ' ...
        'UpperBoundConducting=%d FinalConducting=%d\r\n'], groupIndex, ...
        stats.LowerBoundConducting, stats.UpperBoundChecked, ...
        stats.UpperBoundConducting, stats.FinalConducting);
    fprintf(fileID, 'Group%d ProofType=%s\r\n', groupIndex, stats.ProofType);
    fprintf(fileID, 'Group%d FinalStatus=%s\r\n', groupIndex, stats.FinalStatus);
    fprintf(fileID, 'Group%d BFS=%s\r\n', groupIndex, stats.BFSPath);
    fprintf(fileID, ['Group%d Mediums=%d Pieces=%d PhysicalEdges=%d ' ...
        'LeftContacts=%d RightContacts=%d\r\n\r\n'], groupIndex, ...
        stats.Records, stats.TotalPieces, stats.PhysicalEdgeCount, ...
        stats.LeftContactPieces, stats.RightContactPieces);
end
fprintf(fileID, 'FINAL_Q1=Group1 NON_CONDUCTING; Group2 CONDUCTING; Group3 CONDUCTING\r\n');
fclose(fileID);
end

function writeMetric(fileID, name, value, threshold, pass, details)
fprintf(fileID, 'METRIC,,,,,NaN,NaN,,,NaN,0,');
writeText(fileID, name);
fprintf(fileID, ',%.15g,%.15g,%d,', value, threshold, pass);
writeText(fileID, details); fprintf(fileID, '\n');
end

function value = pairText(pieces, pair)
if any(pair == 0)
    value = 'NONE';
else
    value = sprintf('A%d-%d vs A%d-%d', ...
        pieces.MediumID(pair(1)), pieces.PieceIndex(pair(1)), ...
        pieces.MediumID(pair(2)), pieces.PieceIndex(pair(2)));
end
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
    error('writePaperFinalOutputs:OpenFailed', 'Cannot write %s.', path);
end
end

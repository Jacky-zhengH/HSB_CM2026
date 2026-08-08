function writeV2Tables(groups, analyses, r1Results, r2Results, r3Results, modelPieces, ...
        modelStats, modelResults, tableDir, cfg)
%WRITEV2TABLES Write standard Q1 rebuild CSV diagnostics.

modelNames = {'R0','R1','R2','R3'};

fileID = openOutput(fullfile(tableDir, 'raw_record_audit.csv'));
fprintf(fileID, 'Group,MediumID,ExcelRow,RawLength,LengthErrorFrom5000\n');
for groupIndex = 1:3
    for mediumID = 1:analyses{groupIndex}.Records
        rawLength = analyses{groupIndex}.SegmentLength(mediumID);
        fprintf(fileID, '%d,A%d,%d,%.15g,%.15g\n', groupIndex, mediumID, ...
            groups(groupIndex).OriginalExcelRow(mediumID), rawLength, ...
            rawLength - cfg.mediumALength);
    end
end
fclose(fileID);

fileID = openOutput(fullfile(tableDir, 'endpoint_unwrap_candidates.csv'));
fprintf(fileID, 'Group,MediumID,kx,ky,kz,CandidateLength,LengthError,Valid\n');
for groupIndex = 1:3
    for mediumID = 1:analyses{groupIndex}.Records
        item = r1Results{groupIndex}{mediumID};
        for candidateIndex = 1:size(item.K, 1)
            fprintf(fileID, '%d,A%d,%d,%d,%d,%.15g,%.15g,%d\n', ...
                groupIndex, mediumID, item.K(candidateIndex, :), ...
                item.CandidateLength(candidateIndex), item.LengthError(candidateIndex), ...
                item.Valid(candidateIndex));
        end
    end
end
fclose(fileID);

fileID = openOutput(fullfile(tableDir, 'reconstruction_summary.csv'));
fprintf(fileID, ['Group,MediumID,RawLength,R1CandidateCount,R1Status,' ...
    'R2CandidateCount,R2Status,R3CandidateCount,R3Status,' ...
    'SelectedForVisualization\n']);
selectedR1 = false; selectedR2 = false; selectedUnresolved = false;
for groupIndex = 1:3
    for mediumID = 1:analyses{groupIndex}.Records
        r1 = r1Results{groupIndex}{mediumID};
        r2 = r2Results{groupIndex}{mediumID};
        r3 = r3Results{groupIndex}{mediumID};
        selected = false;
        if ~selectedR1 && ~strcmp(r1.Status, 'NO_ENDPOINT_UNWRAP') && ...
                ~strcmp(r1.Status, 'AMBIGUOUS_ENDPOINT_UNWRAP')
            selected = true; selectedR1 = true;
        elseif ~selectedR2 && strcmp(r1.Status, 'NO_ENDPOINT_UNWRAP') && ...
                strcmp(r2.Status, 'UNIQUE_RECONSTRUCTION')
            selected = true; selectedR2 = true;
        elseif ~selectedUnresolved && strcmp(r2.Status, 'UNRESOLVED')
            selected = true; selectedUnresolved = true;
        end
        fprintf(fileID, '%d,A%d,%.15g,%d,%s,%d,%s,%d,%s,%d\n', groupIndex, mediumID, ...
            analyses{groupIndex}.SegmentLength(mediumID), r1.CandidateCount, ...
            r1.Status, r2.CandidateCount, r2.Status, r3.CandidateCount, ...
            r3.Status, selected);
    end
end
fclose(fileID);

fileID = openOutput(fullfile(tableDir, 'r3_reconstruction_candidates.csv'));
fprintf(fileID, ['Group,MediumID,CandidateIndex,CandidateType,a,b,' ...
    'OriginalStartX,OriginalStartY,OriginalStartZ,OriginalEndX,' ...
    'OriginalEndY,OriginalEndZ,Valid,MatchedPieceIndex\n']);
for groupIndex = 1:3
    for mediumID = 1:analyses{groupIndex}.Records
        item = r3Results{groupIndex}{mediumID};
        for candidateIndex = 1:numel(item.CandidateType)
            fprintf(fileID, ['%d,A%d,%d,%s,%.15g,%.15g,%.15g,%.15g,' ...
                '%.15g,%.15g,%.15g,%.15g,%d,%d\n'], groupIndex, mediumID, ...
                candidateIndex, item.CandidateType{candidateIndex}, ...
                item.A(candidateIndex), item.B(candidateIndex), ...
                item.OriginalStart(candidateIndex, :), ...
                item.OriginalEnd(candidateIndex, :), item.Valid(candidateIndex), ...
                item.MatchedPieceIndex(candidateIndex));
        end
    end
end
fclose(fileID);

fileID = openOutput(fullfile(tableDir, 'r2_reconstruction_candidates.csv'));
fprintf(fileID, ['Group,MediumID,CandidateIndex,Hypothesis,OriginalStartX,' ...
    'OriginalStartY,OriginalStartZ,OriginalEndX,OriginalEndY,OriginalEndZ,' ...
    'Valid,MatchedPieceIndex\n']);
for groupIndex = 1:3
    for mediumID = 1:analyses{groupIndex}.Records
        item = r2Results{groupIndex}{mediumID};
        for candidateIndex = 1:numel(item.Hypothesis)
            fprintf(fileID, '%d,A%d,%d,%s,%.15g,%.15g,%.15g,%.15g,%.15g,%.15g,%d,%d\n', ...
                groupIndex, mediumID, candidateIndex, item.Hypothesis{candidateIndex}, ...
                item.OriginalStart(candidateIndex, :), item.OriginalEnd(candidateIndex, :), ...
                item.Valid(candidateIndex), item.MatchedPieceIndex(candidateIndex));
        end
    end
end
fclose(fileID);

fileID = openOutput(fullfile(tableDir, 'reconstructed_pieces.csv'));
fprintf(fileID, ['Group,Model,MediumID,PieceIndex,SourceExcelRow,' ...
    'OriginalStartX,OriginalStartY,OriginalStartZ,OriginalEndX,OriginalEndY,' ...
    'OriginalEndZ,PieceStartX,PieceStartY,PieceStartZ,PieceEndX,PieceEndY,' ...
    'PieceEndZ,PieceLength,TranslationX,TranslationY,TranslationZ\n']);
for groupIndex = 1:3
    for modelIndex = 1:4
        pieces = modelPieces{groupIndex, modelIndex};
        for pieceIndex = 1:numel(pieces.MediumID)
            fprintf(fileID, ['%d,%s,A%d,%d,%d,%.15g,%.15g,%.15g,' ...
                '%.15g,%.15g,%.15g,%.15g,%.15g,%.15g,%.15g,%.15g,' ...
                '%.15g,%.15g,%.15g,%.15g,%.15g\n'], ...
                groupIndex, modelNames{modelIndex}, pieces.MediumID(pieceIndex), ...
                pieces.PieceIndex(pieceIndex), pieces.SourceExcelRow(pieceIndex), ...
                pieces.OriginalStart(pieceIndex, :), pieces.OriginalEnd(pieceIndex, :), ...
                pieces.PieceStart(pieceIndex, :), pieces.PieceEnd(pieceIndex, :), ...
                pieces.PieceLength(pieceIndex), pieces.Translation(pieceIndex, :));
        end
    end
end
fclose(fileID);

fileID = openOutput(fullfile(tableDir, 'q1_model_results.csv'));
fprintf(fileID, ['Group,Model,Records,ResolvedMediums,UnresolvedMediums,' ...
    'AmbiguousMediums,PieceCount,ConductingStatus,BFSPath\n']);
for groupIndex = 1:3
    for modelIndex = 1:4
        stats = modelStats{groupIndex, modelIndex};
        if isempty(modelResults{groupIndex, modelIndex})
            pathText = '';
        else
            pathText = modelResults{groupIndex, modelIndex}.BFSPath;
        end
        fprintf(fileID, '%d,%s,%d,%d,%d,%d,%d,%s,%s\n', groupIndex, ...
            modelNames{modelIndex}, analyses{groupIndex}.Records, stats.Resolved, ...
            stats.Unresolved, stats.Ambiguous, ...
            numel(modelPieces{groupIndex, modelIndex}.MediumID), ...
            stats.ConductingStatus, pathText);
    end
end
fclose(fileID);
end

function fileID = openOutput(path)
fileID = fopen(path, 'w');
if fileID < 0, error('writeV2Tables:OutputOpenFailed', 'Cannot write: %s', path); end
end

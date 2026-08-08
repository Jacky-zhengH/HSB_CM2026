function writeEndpointRebuildSummary(summaryPath, branchName, baseCommit, ...
        matlabVersion, groupStats, sensitivityRows, consistencyPassCount, ...
        endpointComplete, relativeResults, graphs)
%WRITEENDPOINTREBUILDSUMMARY Write the complete endpoint experiment result.

fileID = fopen(summaryPath, 'w');
if fileID < 0
    error('writeEndpointRebuildSummary:OpenFailed', ...
        'Cannot write %s.', summaryPath);
end
fprintf(fileID, 'Q1 Endpoint Reconstruction Rebuild\r\n');
fprintf(fileID, 'GitBranch=%s\r\n', branchName);
fprintf(fileID, 'BaseCommit=%s\r\n', baseCommit);
fprintf(fileID, 'MATLAB=%s\r\n', matlabVersion);
fprintf(fileID, 'RecordCount=596\r\n');
fprintf(fileID, 'EnumeratorConsistency=%d/596\r\n', consistencyPassCount);
for groupIndex = 1:3
    stats = groupStats(groupIndex);
    fprintf(fileID, ['Group%d Records=%d DirectRaw5000=%d Unique=%d ' ...
        'AmbiguousPeriodic=%d Unresolved=%d Shift=[None:%d Single:%d ' ...
        'Two:%d Three:%d] Pieces=[1:%d 2:%d 3:%d 4:%d] TotalPieces=%d\r\n'], ...
        groupIndex, stats.Records, stats.Raw5000, stats.Unique, ...
        stats.AmbiguousPeriodic, stats.Unresolved, stats.ShiftTypeCounts, ...
        stats.PieceCountByMedium, stats.TotalPieces);
end
fprintf(fileID, '\r\nToleranceSensitivity:\r\n');
for row = 1:numel(sensitivityRows)
    item = sensitivityRows(row);
    fprintf(fileID, ['Group%d Tolerance=%.15g Unique=%d ' ...
        'AmbiguousPeriodic=%d Unresolved=%d\r\n'], item.Group, ...
        item.Tolerance, item.Unique, item.AmbiguousPeriodic, item.Unresolved);
end
fprintf(fileID, '\r\nUnresolvedRecords:\r\n');
for groupIndex = 1:3
    fprintf(fileID, 'Group%d=', groupIndex);
    first = true;
    for mediumID = 1:numel(relativeResults{groupIndex})
        if strcmp(relativeResults{groupIndex}{mediumID}.Status, 'UNRESOLVED')
            if ~first, fprintf(fileID, ','); end
            fprintf(fileID, 'A%d', mediumID);
            first = false;
        end
    end
    fprintf(fileID, '\r\n');
end
fprintf(fileID, '\r\nAmbiguousCandidates:\r\n');
for groupIndex = 1:3
    for mediumID = 1:numel(relativeResults{groupIndex})
        item = relativeResults{groupIndex}{mediumID};
        if strcmp(item.Status, 'AMBIGUOUS_PERIODIC')
            fprintf(fileID, 'Group%d A%d:', groupIndex, mediumID);
            for candidate = 1:item.PhysicalCandidateCount
                fprintf(fileID, ' k=[%d %d %d]', item.CandidatesK(candidate, :));
            end
            fprintf(fileID, '\r\n');
        end
    end
end
fprintf(fileID, '\r\nEndpointModelComplete=%d\r\n', endpointComplete);
if endpointComplete
    for groupIndex = 1:3
        fprintf(fileID, 'Group%d Conducting=%d BFSPath=%s\r\n', ...
            groupIndex, graphs{groupIndex}.Conducting, ...
            graphs{groupIndex}.BFSPath);
    end
else
    fprintf(fileID, ['No final Q1 conduction result is asserted under ' ...
        'this endpoint model.\r\n']);
end
fprintf(fileID, 'Q1 ENDPOINT REBUILD COMPLETE\r\n');
fclose(fileID);
end

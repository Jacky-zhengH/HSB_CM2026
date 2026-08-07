function analysis = analyzeGroupData(group, cfg)
%ANALYZEGROUPDATA Compute basic segment geometry and length statistics.

vectors = group.P2 - group.P1;
segmentLength = sqrt(sum(vectors.^2, 2));
if any(~isfinite(segmentLength)) || any(segmentLength <= 0)
    badRows = find(~isfinite(segmentLength) | segmentLength <= 0);
    error('analyzeGroupData:InvalidLength', ...
        'Nonpositive or nonfinite segment length at RecordID(s): %s', ...
        sprintf('%d ', group.RecordID(badRows)));
end

unitDirection = bsxfun(@rdivide, vectors, segmentLength);
fullLengthMask = abs(segmentLength - cfg.mediumALength) <= cfg.lengthTolerance;

analysis.RecordID = group.RecordID;
analysis.OriginalExcelRow = group.OriginalExcelRow;
analysis.P1 = group.P1;
analysis.P2 = group.P2;
analysis.SegmentLength = segmentLength;
analysis.UnitDirection = unitDirection;
analysis.FullLengthMask = fullLengthMask;
analysis.Records = numel(segmentLength);
analysis.FullLengthRecords = sum(fullLengthMask);
analysis.ShortRecords = sum(~fullLengthMask);
analysis.MinimumLength = min(segmentLength);
analysis.MaximumLength = max(segmentLength);
analysis.MeanLength = mean(segmentLength);
analysis.MedianLength = median(segmentLength);
end

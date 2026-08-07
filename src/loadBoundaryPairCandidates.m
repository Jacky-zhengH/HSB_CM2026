function candidates = loadBoundaryPairCandidates(csvPath)
%LOADBOUNDARYPAIRCANDIDATES Read the V0 pairing CSV using legacy textscan.

fileID = fopen(csvPath, 'r');
if fileID < 0
    error('loadBoundaryPairCandidates:MissingFile', 'Cannot open: %s', csvPath);
end
cleanup = onCleanup(@() fclose(fileID)); %#ok<NASGU>
fgetl(fileID);
data = textscan(fileID, '%f%f%f%f%f%f%f%f%s', 'Delimiter', ',', ...
    'CollectOutput', false, 'ReturnOnError', false);
candidates.Group = data{1};
candidates.RecordA = data{2};
candidates.RecordB = data{3};
candidates.Translation = [data{4} data{5} data{6}];
candidates.DirectionError = data{7};
candidates.EndpointError = data{8};
candidates.BoundaryDescription = data{9};
end

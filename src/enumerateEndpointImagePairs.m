function result = enumerateEndpointImagePairs(p1Wrapped, p2Wrapped, cfg)
%ENUMERATEENDPOINTIMAGEPAIRS Audit all 27-by-27 endpoint image pairs.

persistent allN1 allN2
if isempty(allN1)
    images = zeros(27, 3);
    row = 0;
    for nx = -1:1
        for ny = -1:1
            for nz = -1:1
                row = row + 1;
                images(row, :) = [nx ny nz];
            end
        end
    end
    allN1 = zeros(729, 3);
    allN2 = zeros(729, 3);
    row = 0;
    for first = 1:27
        for second = 1:27
            row = row + 1;
            allN1(row, :) = images(first, :);
            allN2(row, :) = images(second, :);
        end
    end
end

p1Candidate = bsxfun(@plus, p1Wrapped, cfg.L * allN1);
p2Candidate = bsxfun(@plus, p2Wrapped, cfg.L * allN2);
relativeK = allN2 - allN1;
delta = p2Candidate - p1Candidate;
candidateLength = sqrt(sum(delta.^2, 2));
lengthError = candidateLength - cfg.mediumALength;
valid5000 = abs(lengthError) <= cfg.endpointLengthTolerance;
geometryClassID = zeros(729, 1);
allWrapped = cell(729, 1);
representativeRows = zeros(0, 1);

for row = find(valid5000(:))'
    [valid, wrapped] = forwardValidateEndpointCandidate( ...
        p1Candidate(row, :), p2Candidate(row, :), ...
        p1Wrapped, p2Wrapped, cfg);
    if ~valid
        valid5000(row) = false;
        continue;
    end
    allWrapped{row} = wrapped;
    classID = 0;
    for classIndex = 1:numel(representativeRows)
        if sameWrappedGeometry(wrapped, allWrapped{representativeRows(classIndex)}, ...
                cfg.geometryTolerance)
            classID = classIndex;
            break;
        end
    end
    if classID == 0
        representativeRows(end + 1, 1) = row; %#ok<AGROW>
        classID = numel(representativeRows);
    end
    geometryClassID(row) = classID;
end

physicalGeometries = cell(numel(representativeRows), 1);
representativeK = zeros(numel(representativeRows), 3);
for classIndex = 1:numel(representativeRows)
    row = representativeRows(classIndex);
    physicalGeometries{classIndex} = allWrapped{row};
    representativeK(classIndex, :) = relativeK(row, :);
end

result.AllN1 = allN1;
result.AllN2 = allN2;
result.P1Candidate = p1Candidate;
result.P2Candidate = p2Candidate;
result.RelativeK = relativeK;
result.CandidateLength = candidateLength;
result.LengthError = lengthError;
result.Valid5000 = valid5000;
result.GeometryClassID = geometryClassID;
result.ValidCandidateCount = sum(valid5000);
result.PhysicalCandidateCount = numel(representativeRows);
result.PhysicalGeometries = physicalGeometries;
result.RepresentativeRows = representativeRows;
result.RepresentativeK = representativeK;
end

function result = unwrapMediumEndpoints(p1Wrapped, p2Wrapped, cfg)
%UNWRAPMEDIUMENDPOINTS Formal 27-relative-shift endpoint reconstruction.
%   P2u-P1u=(P2w-P1w)+L*(n2-n1). A common box translation changes no
%   wrapped geometry, so k=n2-n1 in {-1,0,1}^3 is the formal search space.

persistent allK
if isempty(allK)
    allK = zeros(27, 3);
    row = 0;
    for kx = -1:1
        for ky = -1:1
            for kz = -1:1
                row = row + 1;
                allK(row, :) = [kx ky kz];
            end
        end
    end
end

deltaWrapped = p2Wrapped - p1Wrapped;
recoveredDelta = bsxfun(@plus, deltaWrapped, cfg.L * allK);
recoveredLength = sqrt(sum(recoveredDelta.^2, 2));
lengthError = recoveredLength - cfg.mediumALength;
valid5000 = abs(lengthError) <= cfg.endpointLengthTolerance;
geometryClassID = zeros(27, 1);
pieceCountByK = zeros(27, 1);
consistencyErrorByK = NaN(27, 1);
allWrapped = cell(27, 1);
representativeRows = zeros(0, 1);

for row = find(valid5000(:))'
    candidateStart = p1Wrapped;
    candidateEnd = p1Wrapped + recoveredDelta(row, :);
    [valid, wrapped, endpointError] = forwardValidateEndpointCandidate( ...
        candidateStart, candidateEnd, p1Wrapped, p2Wrapped, cfg);
    if ~valid
        valid5000(row) = false;
        continue;
    end
    allWrapped{row} = wrapped;
    pieceCountByK(row) = size(wrapped.Start, 1);
    consistencyErrorByK(row) = endpointError;
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

physicalCount = numel(representativeRows);
candidatesK = zeros(physicalCount, 3);
unwrappedStart = zeros(physicalCount, 3);
unwrappedEnd = zeros(physicalCount, 3);
unwrappedLength = zeros(physicalCount, 1);
wrappedPieces = cell(physicalCount, 1);
pieceCount = zeros(physicalCount, 1);
boundarySequence = cell(physicalCount, 1);
maximumConsistencyError = zeros(physicalCount, 1);
for classIndex = 1:physicalCount
    row = representativeRows(classIndex);
    candidatesK(classIndex, :) = allK(row, :);
    unwrappedStart(classIndex, :) = p1Wrapped;
    unwrappedEnd(classIndex, :) = p1Wrapped + recoveredDelta(row, :);
    unwrappedLength(classIndex) = recoveredLength(row);
    wrappedPieces{classIndex} = allWrapped{row};
    pieceCount(classIndex) = pieceCountByK(row);
    [boundarySequence{classIndex}, ~] = ...
        extractBoundaryEvents(allWrapped{row}.Translation, ...
        cfg.geometryTolerance);
    maximumConsistencyError(classIndex) = consistencyErrorByK(row);
end

if physicalCount == 0
    status = 'UNRESOLVED'; selectedIndex = [];
elseif physicalCount == 1
    status = 'UNIQUE'; selectedIndex = 1;
else
    status = 'AMBIGUOUS_PERIODIC'; selectedIndex = [];
end

result.RawDelta = deltaWrapped;
result.RawLength = norm(deltaWrapped);
result.AllK = allK;
result.RecoveredDelta = recoveredDelta;
result.RecoveredLength = recoveredLength;
result.LengthError = lengthError;
result.Valid5000 = valid5000;
result.GeometryClassID = geometryClassID;
result.PieceCountByK = pieceCountByK;
result.ConsistencyErrorByK = consistencyErrorByK;
result.MathematicalCandidateCount = sum(valid5000);
result.PhysicalCandidateCount = physicalCount;
result.Status = status;
result.SelectedIndex = selectedIndex;
result.CandidatesK = candidatesK;
result.UnwrappedStart = unwrappedStart;
result.UnwrappedEnd = unwrappedEnd;
result.UnwrappedLength = unwrappedLength;
result.WrappedPieces = wrappedPieces;
result.PieceCount = pieceCount;
result.BoundaryEventSequence = boundarySequence;
result.MaxConsistencyError = maximumConsistencyError;
result.RepresentativeRows = representativeRows;
end

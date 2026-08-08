function result = reconstructFromRetainedPart(p1Observed, p2Observed, cfg)
%RECONSTRUCTFROMRETAINEDPART Test the retained-original-part hypothesis.
%   A short observed segment with exactly one formal boundary endpoint is
%   oriented InteriorPoint -> BoundaryPoint.  Its entire missing length is
%   appended beyond BoundaryPoint, then wrapSegmentToBox is used as a hard
%   forward-replay check.  No endpoint-image search or free a/b split is
%   performed here.

p1Observed = reshape(double(p1Observed), 1, 3);
p2Observed = reshape(double(p2Observed), 1, 3);
geometryTolerance = cfg.geometryTolerance;
lengthTolerance = cfg.lengthTolerance;
directionTolerance = max(1e-12, geometryTolerance / cfg.mediumALength);

result.RawLength = norm(p2Observed - p1Observed);
result.BoundaryMaskP1 = abs(abs(p1Observed) - cfg.HALF_L) <= geometryTolerance;
result.BoundaryMaskP2 = abs(abs(p2Observed) - cfg.HALF_L) <= geometryTolerance;
result.BoundaryEndpointCount = double(any(result.BoundaryMaskP1)) + ...
    double(any(result.BoundaryMaskP2));
result.P1BoundaryAxes = boundaryAxesLabel(p1Observed, result.BoundaryMaskP1);
result.P2BoundaryAxes = boundaryAxesLabel(p2Observed, result.BoundaryMaskP2);
result.HasAbs500Coordinate = any(abs(abs([p1Observed p2Observed]) - 500) ...
    <= geometryTolerance);
result.Classification = 'INVALID_LENGTH';
result.Status = 'INVALID_LENGTH';
result.ObservedStart = p1Observed;
result.ObservedEnd = p2Observed;
result.BoundaryPoint = [NaN NaN NaN];
result.InteriorPoint = [NaN NaN NaN];
result.ObservedDirection = [NaN NaN NaN];
result.MissingLength = NaN;
result.RemainingLength = NaN;
result.ReconstructedOriginalStart = [NaN NaN NaN];
result.ReconstructedOriginalEnd = [NaN NaN NaN];
result.ForwardPieces = emptyPieces();
result.ForwardPieceCount = 0;
result.BoundaryEventSequence = 'NONE';
result.ObservedPieceMatched = false;
result.MatchedPieceIndex = 0;
result.MatchedPieceTranslation = [NaN NaN NaN];
result.MaxReplayError = Inf;
result.CandidateCount = 0;
result.PhysicalCandidateCount = 0;
result.IsUniquelyReconstructed = false;
result.ActiveBoundaryAxes = 'NONE';
result.Reason = 'Length must be finite and in (0,5000] nm.';

if ~isfinite(result.RawLength) || result.RawLength <= geometryTolerance || ...
        result.RawLength > cfg.mediumALength + lengthTolerance
    return;
end

if abs(result.RawLength - cfg.mediumALength) <= lengthTolerance
    result.Classification = 'DIRECT_FULL';
    result.Status = 'DIRECT_FULL';
    result.ObservedDirection = (p2Observed - p1Observed) / result.RawLength;
    result.MissingLength = 0;
    result.RemainingLength = 0;
    result.ReconstructedOriginalStart = p1Observed;
    result.ReconstructedOriginalEnd = p2Observed;
    result.CandidateCount = 1;
    result = replayCandidate(result, cfg);
    if result.ObservedPieceMatched
        result.PhysicalCandidateCount = 1;
        result.IsUniquelyReconstructed = true;
        result.Reason = 'Observed segment is already a complete 5000 nm Medium.';
    else
        result.Status = 'REJECTED_FORWARD_REPLAY';
        result.PhysicalCandidateCount = 0;
        result.Reason = 'Direct full segment did not replay as a zero-translation Piece.';
    end
    return;
end

result.MissingLength = cfg.mediumALength - result.RawLength;
result.RemainingLength = result.MissingLength;
if result.BoundaryEndpointCount == 0
    result.Classification = 'UNRESOLVED_NO_FORMAL_BOUNDARY';
    result.Status = 'UNRESOLVED_NO_FORMAL_BOUNDARY';
    result.Reason = 'Short record has no endpoint on a formal +/-5000 face.';
    return;
elseif result.BoundaryEndpointCount == 2
    result.Classification = 'AMBIGUOUS_TWO_BOUNDARY_RETAINED';
    result.Status = 'AMBIGUOUS_TWO_BOUNDARY_RETAINED';
    result.ObservedDirection = (p2Observed - p1Observed) / result.RawLength;
    result.Reason = 'Missing length may lie on both sides; no unique a/b split is selected.';
    return;
end

result.Classification = 'RETAINED_SINGLE_BOUNDARY_UNIQUE';
if any(result.BoundaryMaskP1)
    result.BoundaryPoint = p1Observed;
    result.InteriorPoint = p2Observed;
    boundaryMask = result.BoundaryMaskP1;
else
    result.BoundaryPoint = p2Observed;
    result.InteriorPoint = p1Observed;
    boundaryMask = result.BoundaryMaskP2;
end
result.ObservedDirection = (result.BoundaryPoint - result.InteriorPoint) / ...
    result.RawLength;

boundarySigns = sign(result.BoundaryPoint);
outward = boundaryMask & ...
    (boundarySigns .* result.ObservedDirection > directionTolerance);
result.ActiveBoundaryAxes = activeAxesLabel(outward);
if ~any(outward)
    result.Status = 'REJECTED_FORWARD_REPLAY';
    result.Reason = 'Direction does not continue outward through any formal boundary face.';
    return;
end

result.ReconstructedOriginalStart = result.InteriorPoint;
result.ReconstructedOriginalEnd = result.BoundaryPoint + ...
    result.MissingLength * result.ObservedDirection;
result.CandidateCount = 1;
if abs(norm(result.ReconstructedOriginalEnd - ...
        result.ReconstructedOriginalStart) - cfg.mediumALength) > lengthTolerance
    result.Status = 'INVALID_LENGTH';
    result.Reason = 'Recovered segment does not have the required 5000 nm length.';
    return;
end

result.Status = 'RETAINED_SINGLE_BOUNDARY_UNIQUE';
result = replayCandidate(result, cfg);
if result.ObservedPieceMatched
    result.PhysicalCandidateCount = 1;
    result.IsUniquelyReconstructed = true;
    result.Reason = 'Unique retained part replayed as a zero-translation GeometryPiece.';
else
    result.Status = 'REJECTED_FORWARD_REPLAY';
    result.PhysicalCandidateCount = 0;
    result.Reason = 'Recovered candidate failed zero-translation forward replay.';
end
end

function result = replayCandidate(result, cfg)
try
    wrapped = wrapSegmentToBox(result.ReconstructedOriginalStart, ...
        result.ReconstructedOriginalEnd, cfg.HALF_L, cfg.L, ...
        cfg.geometryTolerance);
catch replayError
    result.Reason = replayError.message;
    return;
end
result.ForwardPieces = wrapped;
result.ForwardPieceCount = size(wrapped.Start, 1);
[result.BoundaryEventSequence, ~] = extractBoundaryEvents( ...
    wrapped.Translation, cfg.geometryTolerance);

bestError = Inf;
bestIndex = 0;
for pieceIndex = 1:result.ForwardPieceCount
    if max(abs(wrapped.Translation(pieceIndex, :))) > cfg.geometryTolerance
        continue;
    end
    directError = max([norm(wrapped.Start(pieceIndex, :) - result.ObservedStart), ...
        norm(wrapped.End(pieceIndex, :) - result.ObservedEnd)]);
    reverseError = max([norm(wrapped.Start(pieceIndex, :) - result.ObservedEnd), ...
        norm(wrapped.End(pieceIndex, :) - result.ObservedStart)]);
    pieceError = min(directError, reverseError);
    if pieceError < bestError
        bestError = pieceError;
        bestIndex = pieceIndex;
    end
end
result.MaxReplayError = bestError;
if bestIndex > 0 && bestError <= cfg.replayTolerance
    result.ObservedPieceMatched = true;
    result.MatchedPieceIndex = bestIndex;
    result.MatchedPieceTranslation = wrapped.Translation(bestIndex, :);
end
end

function label = boundaryAxesLabel(point, mask)
axisNames = {'X','Y','Z'};
label = 'NONE';
for axisIndex = 1:3
    if mask(axisIndex)
        token = sprintf('%s%+d', axisNames{axisIndex}, ...
            sign(point(axisIndex)) * 5000);
        if strcmp(label, 'NONE')
            label = token;
        else
            label = [label '|' token]; %#ok<AGROW>
        end
    end
end
end

function label = activeAxesLabel(mask)
axisNames = {'X','Y','Z'};
label = 'NONE';
for axisIndex = 1:3
    if mask(axisIndex)
        if strcmp(label, 'NONE')
            label = axisNames{axisIndex};
        else
            label = [label axisNames{axisIndex}]; %#ok<AGROW>
        end
    end
end
end

function pieces = emptyPieces()
pieces.Start = zeros(0, 3);
pieces.End = zeros(0, 3);
pieces.Length = zeros(0, 1);
pieces.Translation = zeros(0, 3);
pieces.TStart = zeros(0, 1);
pieces.TEnd = zeros(0, 1);
end

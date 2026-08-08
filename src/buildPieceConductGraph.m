function result = buildPieceConductGraph(pieces, cfg)
%BUILDPIECECONDUCTGRAPH Exact Piece-level graph with no hidden Medium edges.

pieceCount = numel(pieces.MediumID);
leftNode = 1;
rightNode = pieceCount + 2;
adjacency = cell(pieceCount + 2, 1);
geometryEdges = zeros(0, 2);
axisCandidateCount = 0;

for pieceA = 1:(pieceCount - 1)
    for pieceB = (pieceA + 1):pieceCount
        axisDistance = segmentSegmentDistance(pieces.PieceStart(pieceA, :), ...
            pieces.PieceEnd(pieceA, :), pieces.PieceStart(pieceB, :), ...
            pieces.PieceEnd(pieceB, :));
        if axisDistance > cfg.broadPhaseDistance
            continue;
        end
        axisCandidateCount = axisCandidateCount + 1;
        [exactDistance, ~, ~, ~, converged] = gjkCylinderDistance( ...
            pieces.PieceStart(pieceA, :), pieces.PieceEnd(pieceA, :), ...
            cfg.mediumARadius, pieces.PieceStart(pieceB, :), ...
            pieces.PieceEnd(pieceB, :), cfg.mediumARadius, ...
            cfg.gjkTolerance, cfg.gjkMaxIterations);
        if ~converged
            error('buildPieceConductGraph:GJKNotConverged', ...
                'GJK failed for Piece nodes %d and %d.', pieceA, pieceB);
        end
        if exactDistance <= cfg.conductionDistance
            geometryEdges(end + 1, :) = [pieceA pieceB]; %#ok<AGROW>
            adjacency = addUndirected(adjacency, pieceA + 1, pieceB + 1);
        end
    end
end

leftContact = false(pieceCount, 1);
rightContact = false(pieceCount, 1);
for pieceIndex = 1:pieceCount
    [leftDistance, rightDistance] = cylinderPlaneDistance( ...
        pieces.PieceStart(pieceIndex, :), pieces.PieceEnd(pieceIndex, :), ...
        cfg.mediumARadius, cfg.HALF_L);
    if leftDistance <= cfg.conductionDistance
        leftContact(pieceIndex) = true;
        adjacency = addUndirected(adjacency, leftNode, pieceIndex + 1);
    end
    if rightDistance <= cfg.conductionDistance
        rightContact(pieceIndex) = true;
        adjacency = addUndirected(adjacency, pieceIndex + 1, rightNode);
    end
end

[conducting, nodePath] = findBFSPath(adjacency, leftNode, rightNode);
pathPieces = zeros(0, 1);
if conducting && numel(nodePath) > 2
    pathPieces = nodePath(2:end - 1) - 1;
end

result.PieceCount = pieceCount;
result.AxisCandidateCount = axisCandidateCount;
result.GeometryEdges = geometryEdges;
result.LeftContact = leftContact;
result.RightContact = rightContact;
result.Adjacency = adjacency;
result.Conducting = conducting;
result.NodePath = nodePath;
result.PathPieces = pathPieces;
result.BFSPath = formatPieceBFSPath(conducting, pathPieces, pieces);
end

function adjacency = addUndirected(adjacency, a, b)
if ~any(adjacency{a} == b), adjacency{a}(end + 1) = b; end
if ~any(adjacency{b} == a), adjacency{b}(end + 1) = a; end
end

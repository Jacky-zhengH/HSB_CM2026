function upper = buildGroup1OptimisticUpperBound(group, results, ...
        knownPieces, lowerGraph, cfg)
%BUILDGROUP1OPTIMISTICUPPERBOUND Construct a non-conduction supergraph.
%   Each unresolved collinear Medium is replaced by an intentionally
%   enlarged axis envelope.  Edges involving an envelope use the permissive
%   capsule necessary condition d_axis <= 2R+d0.  This object is a proof
%   device only; it is not a reconstructed physical Medium.

unresolvedIDs = zeros(0, 1);
for mediumID = 1:numel(results)
    if strcmp(results{mediumID}.Status, 'UNRESOLVED_NO_FORMAL_BOUNDARY')
        unresolvedIDs(end + 1, 1) = mediumID; %#ok<AGROW>
    end
end

pieces = initializeCombinedPieces(knownPieces);
envelopes = repmat(struct('MediumID', 0, 'SourceExcelRow', 0, ...
    'ObservedP1', zeros(1, 3), 'ObservedP2', zeros(1, 3), ...
    'ObservedLength', 0, 'MissingLength', 0, ...
    'EnvelopeStart', zeros(1, 3), 'EnvelopeEnd', zeros(1, 3), ...
    'EnvelopeLength', 0, 'FirstPieceIndex', 0, 'PieceCount', 0, ...
    'BoundarySequence', 'NONE'), numel(unresolvedIDs), 1);

for unresolvedIndex = 1:numel(unresolvedIDs)
    mediumID = unresolvedIDs(unresolvedIndex);
    p1 = group.P1(mediumID, :);
    p2 = group.P2(mediumID, :);
    observedLength = norm(p2 - p1);
    direction = (p2 - p1) / observedLength;
    missingLength = cfg.mediumALength - observedLength;
    envelopeStart = p1 - missingLength * direction;
    envelopeEnd = p2 + missingLength * direction;
    wrapped = wrapSegmentToBox(envelopeStart, envelopeEnd, ...
        cfg.HALF_L, cfg.L, cfg.geometryTolerance);
    [sequence, ~] = extractBoundaryEvents(wrapped.Translation, ...
        cfg.geometryTolerance);
    firstPiece = numel(pieces.MediumID) + 1;
    for pieceIndex = 1:size(wrapped.Start, 1)
        next = numel(pieces.MediumID) + 1;
        pieces.Group(next, 1) = 1;
        pieces.MediumID(next, 1) = mediumID;
        pieces.PieceIndex(next, 1) = pieceIndex;
        pieces.SourceExcelRow(next, 1) = group.OriginalExcelRow(mediumID);
        pieces.PieceStart(next, :) = wrapped.Start(pieceIndex, :);
        pieces.PieceEnd(next, :) = wrapped.End(pieceIndex, :);
        pieces.PieceLength(next, 1) = wrapped.Length(pieceIndex);
        pieces.Translation(next, :) = wrapped.Translation(pieceIndex, :);
        pieces.IsEnvelope(next, 1) = true;
    end
    envelopes(unresolvedIndex).MediumID = mediumID;
    envelopes(unresolvedIndex).SourceExcelRow = group.OriginalExcelRow(mediumID);
    envelopes(unresolvedIndex).ObservedP1 = p1;
    envelopes(unresolvedIndex).ObservedP2 = p2;
    envelopes(unresolvedIndex).ObservedLength = observedLength;
    envelopes(unresolvedIndex).MissingLength = missingLength;
    envelopes(unresolvedIndex).EnvelopeStart = envelopeStart;
    envelopes(unresolvedIndex).EnvelopeEnd = envelopeEnd;
    envelopes(unresolvedIndex).EnvelopeLength = norm(envelopeEnd - envelopeStart);
    envelopes(unresolvedIndex).FirstPieceIndex = firstPiece;
    envelopes(unresolvedIndex).PieceCount = size(wrapped.Start, 1);
    envelopes(unresolvedIndex).BoundarySequence = sequence;
end

knownCount = numel(knownPieces.MediumID);
pieceCount = numel(pieces.MediumID);
leftNode = 1;
rightNode = pieceCount + 2;
adjacency = cell(pieceCount + 2, 1);
edgeA = zeros(0, 1);
edgeB = zeros(0, 1);
edgeAxisDistance = zeros(0, 1);
edgeType = cell(0, 1);

% Preserve all formal lower-graph Piece edges exactly.
for edgeIndex = 1:size(lowerGraph.GeometryEdges, 1)
    a = lowerGraph.GeometryEdges(edgeIndex, 1);
    b = lowerGraph.GeometryEdges(edgeIndex, 2);
    adjacency = addUndirected(adjacency, a + 1, b + 1);
    edgeA(end + 1, 1) = a; %#ok<AGROW>
    edgeB(end + 1, 1) = b; %#ok<AGROW>
    edgeAxisDistance(end + 1, 1) = ...
        lowerGraph.GeometryAxisDistance(edgeIndex); %#ok<AGROW>
    edgeType{end + 1, 1} = 'FORMAL_GJK'; %#ok<AGROW>
end
for pieceIndex = find(lowerGraph.LeftContact(:))'
    adjacency = addUndirected(adjacency, leftNode, pieceIndex + 1);
end
for pieceIndex = find(lowerGraph.RightContact(:))'
    adjacency = addUndirected(adjacency, pieceIndex + 1, rightNode);
end

minEnvelopeKnown = Inf;
minEnvelopeKnownPair = [0 0];
minEnvelopeEnvelope = Inf;
minEnvelopeEnvelopePair = [0 0];
for pieceA = 1:(pieceCount - 1)
    for pieceB = (pieceA + 1):pieceCount
        if ~pieces.IsEnvelope(pieceA) && ~pieces.IsEnvelope(pieceB)
            continue;
        end
        if pieces.MediumID(pieceA) == pieces.MediumID(pieceB)
            continue;
        end
        axisDistance = segmentSegmentDistance(pieces.PieceStart(pieceA, :), ...
            pieces.PieceEnd(pieceA, :), pieces.PieceStart(pieceB, :), ...
            pieces.PieceEnd(pieceB, :));
        if xor(pieces.IsEnvelope(pieceA), pieces.IsEnvelope(pieceB)) && ...
                axisDistance < minEnvelopeKnown
            minEnvelopeKnown = axisDistance;
            minEnvelopeKnownPair = [pieceA pieceB];
        elseif pieces.IsEnvelope(pieceA) && pieces.IsEnvelope(pieceB) && ...
                axisDistance < minEnvelopeEnvelope
            minEnvelopeEnvelope = axisDistance;
            minEnvelopeEnvelopePair = [pieceA pieceB];
        end
        if axisDistance <= cfg.broadPhaseDistance
            adjacency = addUndirected(adjacency, pieceA + 1, pieceB + 1);
            edgeA(end + 1, 1) = pieceA; %#ok<AGROW>
            edgeB(end + 1, 1) = pieceB; %#ok<AGROW>
            edgeAxisDistance(end + 1, 1) = axisDistance; %#ok<AGROW>
            edgeType{end + 1, 1} = 'OPTIMISTIC_CAPSULE'; %#ok<AGROW>
        end
    end
end

leftContact = false(pieceCount, 1);
rightContact = false(pieceCount, 1);
leftContact(1:knownCount) = lowerGraph.LeftContact;
rightContact(1:knownCount) = lowerGraph.RightContact;
axisPlaneThreshold = cfg.mediumARadius + cfg.conductionDistance;
for pieceIndex = (knownCount + 1):pieceCount
    leftAxisDistance = min(abs(pieces.PieceStart(pieceIndex, 1) + cfg.HALF_L), ...
        abs(pieces.PieceEnd(pieceIndex, 1) + cfg.HALF_L));
    rightAxisDistance = min(abs(pieces.PieceStart(pieceIndex, 1) - cfg.HALF_L), ...
        abs(pieces.PieceEnd(pieceIndex, 1) - cfg.HALF_L));
    if leftAxisDistance <= axisPlaneThreshold
        leftContact(pieceIndex) = true;
        adjacency = addUndirected(adjacency, leftNode, pieceIndex + 1);
    end
    if rightAxisDistance <= axisPlaneThreshold
        rightContact(pieceIndex) = true;
        adjacency = addUndirected(adjacency, pieceIndex + 1, rightNode);
    end
end

[conducting, nodePath] = findBFSPath(adjacency, leftNode, rightNode);
pathPieces = zeros(0, 1);
if conducting && numel(nodePath) > 2
    pathPieces = nodePath(2:end - 1) - 1;
end
leftReachableNodes = reachableNodes(adjacency, leftNode);
rightReachableNodes = reachableNodes(adjacency, rightNode);

upper.Pieces = pieces;
upper.Envelopes = envelopes;
upper.UnresolvedMediumIDs = unresolvedIDs;
upper.KnownPieceCount = knownCount;
upper.EnvelopePieceCount = pieceCount - knownCount;
upper.Adjacency = adjacency;
upper.EdgeA = edgeA;
upper.EdgeB = edgeB;
upper.EdgeAxisDistance = edgeAxisDistance;
upper.EdgeType = edgeType;
upper.LeftContact = leftContact;
upper.RightContact = rightContact;
upper.Conducting = conducting;
upper.NodePath = nodePath;
upper.PathPieces = pathPieces;
upper.BFSPath = formatPieceBFSPath(conducting, pathPieces, pieces);
upper.LeftReachablePieces = find(leftReachableNodes(2:end - 1));
upper.RightReachablePieces = find(rightReachableNodes(2:end - 1));
upper.MinEnvelopeToKnownAxisDistance = minEnvelopeKnown;
upper.MinEnvelopeToKnownPair = minEnvelopeKnownPair;
upper.MinEnvelopeToEnvelopeAxisDistance = minEnvelopeEnvelope;
upper.MinEnvelopeToEnvelopePair = minEnvelopeEnvelopePair;
upper.AxisThreshold = cfg.broadPhaseDistance;
upper.AxisPlaneThreshold = axisPlaneThreshold;
end

function pieces = initializeCombinedPieces(known)
pieces.Group = known.Group;
pieces.MediumID = known.MediumID;
pieces.PieceIndex = known.PieceIndex;
pieces.SourceExcelRow = known.SourceExcelRow;
pieces.PieceStart = known.PieceStart;
pieces.PieceEnd = known.PieceEnd;
pieces.PieceLength = known.PieceLength;
pieces.Translation = known.Translation;
pieces.IsEnvelope = false(numel(known.MediumID), 1);
end

function adjacency = addUndirected(adjacency, a, b)
if ~any(adjacency{a} == b), adjacency{a}(end + 1) = b; end
if ~any(adjacency{b} == a), adjacency{b}(end + 1) = a; end
end

function visited = reachableNodes(adjacency, startNode)
nodeCount = numel(adjacency);
visited = false(nodeCount, 1);
queue = zeros(nodeCount, 1);
head = 1;
tail = 1;
queue(1) = startNode;
visited(startNode) = true;
while head <= tail
    node = queue(head);
    head = head + 1;
    neighbors = adjacency{node};
    for index = 1:numel(neighbors)
        neighbor = neighbors(index);
        if ~visited(neighbor)
            tail = tail + 1;
            queue(tail) = neighbor;
            visited(neighbor) = true;
        end
    end
end
end

function result = buildConductGraph(analysis, parentMap, geometryPairs, cfg)
%BUILDCONDUCTGRAPH Build PhysicalMedium adjacency and find LEFT-RIGHT path.

parentCount = max(parentMap);
leftNode = 1;
rightNode = parentCount + 2;
adjacency = cell(parentCount + 2, 1);
exactEdges = zeros(0, 2);

validPairMask = parentMap(geometryPairs.PieceA) ~= parentMap(geometryPairs.PieceB);
candidateIndices = find(validPairMask);
for index = 1:numel(candidateIndices)
    pairIndex = candidateIndices(index);
    if geometryPairs.ExactDistance(pairIndex) <= cfg.conductionDistance
        parentA = parentMap(geometryPairs.PieceA(pairIndex));
        parentB = parentMap(geometryPairs.PieceB(pairIndex));
        if ~hasEdge(exactEdges, parentA, parentB)
            exactEdges(end + 1, :) = [parentA parentB]; %#ok<AGROW>
            adjacency = addUndirected(adjacency, parentA + 1, parentB + 1);
        end
    end
end

leftContact = false(parentCount, 1);
rightContact = false(parentCount, 1);
for pieceIndex = 1:analysis.Records
    [leftDistance, rightDistance] = cylinderPlaneDistance( ...
        analysis.P1(pieceIndex, :), analysis.P2(pieceIndex, :), ...
        cfg.mediumARadius, cfg.HALF_L);
    parentID = parentMap(pieceIndex);
    if leftDistance <= cfg.conductionDistance
        leftContact(parentID) = true;
    end
    if rightDistance <= cfg.conductionDistance
        rightContact(parentID) = true;
    end
end
for parentID = 1:parentCount
    if leftContact(parentID)
        adjacency = addUndirected(adjacency, leftNode, parentID + 1);
    end
    if rightContact(parentID)
        adjacency = addUndirected(adjacency, parentID + 1, rightNode);
    end
end

[conducting, nodePath] = findBFSPath(adjacency, leftNode, rightNode);
pathParents = zeros(0, 1);
if conducting && numel(nodePath) > 2
    pathParents = nodePath(2:end - 1) - 1;
end

result.ParentCount = parentCount;
result.CandidateGeometryPairs = numel(candidateIndices);
result.ExactEdges = size(exactEdges, 1);
result.LeftContact = leftContact;
result.RightContact = rightContact;
result.LeftContactParents = sum(leftContact);
result.RightContactParents = sum(rightContact);
result.DirectParent = any(leftContact & rightContact);
result.Conducting = conducting;
result.NodePath = nodePath;
result.PathParents = pathParents;
result.PathLength = max(0, numel(nodePath) - 1);
result.Adjacency = adjacency;
end

function present = hasEdge(edges, a, b)
if isempty(edges)
    present = false;
else
    present = any((edges(:, 1) == a & edges(:, 2) == b) | ...
        (edges(:, 1) == b & edges(:, 2) == a));
end
end

function adjacency = addUndirected(adjacency, a, b)
if ~any(adjacency{a} == b)
    adjacency{a}(end + 1) = b;
end
if ~any(adjacency{b} == a)
    adjacency{b}(end + 1) = a;
end
end

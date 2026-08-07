function parentMap = buildParentMap(modelName, recordCount, directionFamily, candidates, groupIndex)
%BUILDPARENTMAP Construct M0, M1 or M2 GeometryPiece-to-Parent mapping.

if strcmp(modelName, 'M0')
    parentMap = (1:recordCount)';
elseif strcmp(modelName, 'M1')
    roots = (1:recordCount)';
    groupMask = candidates.Group == groupIndex;
    recordsA = candidates.RecordA(groupMask);
    recordsB = candidates.RecordB(groupMask);
    for edgeIndex = 1:numel(recordsA)
        rootA = findRoot(roots, recordsA(edgeIndex));
        rootB = findRoot(roots, recordsB(edgeIndex));
        if rootA ~= rootB
            roots(rootB) = rootA;
        end
    end
    raw = zeros(recordCount, 1);
    for recordIndex = 1:recordCount
        raw(recordIndex) = findRoot(roots, recordIndex);
    end
    parentMap = renumberStable(raw);
elseif strcmp(modelName, 'M2')
    parentMap = renumberStable(directionFamily(:));
else
    error('buildParentMap:UnknownModel', 'Unknown parent model: %s', modelName);
end
end

function root = findRoot(parents, node)
root = node;
while parents(root) ~= root
    root = parents(root);
end
end

function numbered = renumberStable(values)
numbered = zeros(size(values));
seen = zeros(0, 1);
for index = 1:numel(values)
    match = find(seen == values(index), 1, 'first');
    if isempty(match)
        seen(end + 1, 1) = values(index); %#ok<AGROW>
        match = numel(seen);
    end
    numbered(index) = match;
end
end

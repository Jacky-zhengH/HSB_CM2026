function same = sameWrappedGeometrySets(leftSet, rightSet, tolerance)
%SAMEWRAPPEDGEOMETRYSETS Compare two sets of physical endpoint candidates.

if numel(leftSet) ~= numel(rightSet)
    same = false;
    return;
end
matched = false(numel(rightSet), 1);
for leftIndex = 1:numel(leftSet)
    found = false;
    for rightIndex = 1:numel(rightSet)
        if ~matched(rightIndex) && sameWrappedGeometry(leftSet{leftIndex}, ...
                rightSet{rightIndex}, tolerance)
            matched(rightIndex) = true;
            found = true;
            break;
        end
    end
    if ~found
        same = false;
        return;
    end
end
same = true;
end

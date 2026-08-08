function canonical = canonicalizeWrappedGeometry(pieces, tolerance)
%CANONICALIZEWRAPPEDGEOMETRY Orientation/order-independent Piece matrix.

if nargin < 2 || isempty(tolerance)
    tolerance = 1e-6;
end
pieceCount = size(pieces.Start, 1);
canonical = zeros(pieceCount, 6);
for pieceIndex = 1:pieceCount
    first = pieces.Start(pieceIndex, :);
    second = pieces.End(pieceIndex, :);
    if lexicographicallyGreater(first, second, tolerance)
        temporary = first; first = second; second = temporary;
    end
    canonical(pieceIndex, :) = [first second];
end
if ~isempty(canonical)
    canonical = sortrows(canonical, 1:6);
end
end

function result = lexicographicallyGreater(left, right, tolerance)
result = false;
for index = 1:numel(left)
    if left(index) > right(index) + tolerance
        result = true;
        return;
    elseif left(index) < right(index) - tolerance
        return;
    end
end
end

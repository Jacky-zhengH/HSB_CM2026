function same = sameWrappedGeometry(leftPieces, rightPieces, tolerance)
%SAMEWRAPPEDGEOMETRY Compare wrapped Piece sets independent of orientation.

left = canonicalizeWrappedGeometry(leftPieces, tolerance);
right = canonicalizeWrappedGeometry(rightPieces, tolerance);
same = isequal(size(left), size(right));
if same && ~isempty(left)
    same = max(abs(left(:) - right(:))) <= tolerance;
end
end

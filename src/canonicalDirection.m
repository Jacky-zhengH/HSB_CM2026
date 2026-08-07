function canonical = canonicalDirection(direction, tolerance)
%CANONICALDIRECTION Give u and -u the same deterministic axis direction.

if size(direction, 2) ~= 3
    error('canonicalDirection:InvalidSize', 'Direction input must be N-by-3.');
end
if any(~isfinite(direction(:)))
    error('canonicalDirection:NonfiniteInput', 'Directions must be finite.');
end
if tolerance < 0
    error('canonicalDirection:InvalidTolerance', 'Tolerance must be nonnegative.');
end

canonical = direction;
for rowIndex = 1:size(canonical, 1)
    firstIndex = find(abs(canonical(rowIndex, :)) > tolerance, 1, 'first');
    if isempty(firstIndex)
        error('canonicalDirection:ZeroDirection', ...
            'Direction row %d is zero within the supplied tolerance.', rowIndex);
    end
    if canonical(rowIndex, firstIndex) < 0
        canonical(rowIndex, :) = -canonical(rowIndex, :);
    end
end
end

function [x, y, z] = buildNaNSeparatedPolyline(starts, ends)
%BUILDNANSEPARATEDPOLYLINE Batch N disjoint 3-D segments into one polyline.

pieceCount = size(starts, 1);
if size(ends, 1) ~= pieceCount || size(starts, 2) ~= 3 || size(ends, 2) ~= 3
    error('buildNaNSeparatedPolyline:SizeMismatch', ...
        'Starts and ends must be equally sized N-by-3 arrays.');
end
separator = NaN(pieceCount, 1);
x = reshape([starts(:, 1) ends(:, 1) separator].', [], 1);
y = reshape([starts(:, 2) ends(:, 2) separator].', [], 1);
z = reshape([starts(:, 3) ends(:, 3) separator].', [], 1);
end

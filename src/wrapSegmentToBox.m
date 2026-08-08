function pieces = wrapSegmentToBox(originalStart, originalEnd, halfBox, boxLength, tolerance)
%WRAPSEGMENTTOBOX Apply the stated periodic boundary truncation to a segment.
%   Breakpoints are computed parametrically at every periodic boundary. Each
%   interval is translated as a whole into [-halfBox,halfBox]^3.

if nargin < 5 || isempty(tolerance)
    tolerance = 1e-9;
end
direction = originalEnd - originalStart;
if norm(direction) <= tolerance
    error('wrapSegmentToBox:ZeroLength', 'Original segment must have positive length.');
end

tBreaks = [0; 1];
for axisIndex = 1:3
    delta = direction(axisIndex);
    if abs(delta) <= tolerance
        continue;
    end
    lower = min(originalStart(axisIndex), originalEnd(axisIndex));
    upper = max(originalStart(axisIndex), originalEnd(axisIndex));
    nMinimum = ceil((lower - halfBox) / boxLength);
    nMaximum = floor((upper - halfBox) / boxLength);
    for n = nMinimum:nMaximum
        boundary = halfBox + n * boxLength;
        t = (boundary - originalStart(axisIndex)) / delta;
        if t > tolerance && t < 1 - tolerance
            tBreaks(end + 1, 1) = t; %#ok<AGROW>
        end
    end
end

tBreaks = sort(tBreaks);
uniqueBreaks = tBreaks(1);
for index = 2:numel(tBreaks)
    if abs(tBreaks(index) - uniqueBreaks(end)) > tolerance
        uniqueBreaks(end + 1, 1) = tBreaks(index); %#ok<AGROW>
    end
end

pieceCount = numel(uniqueBreaks) - 1;
pieces.Start = zeros(pieceCount, 3);
pieces.End = zeros(pieceCount, 3);
pieces.Length = zeros(pieceCount, 1);
pieces.Translation = zeros(pieceCount, 3);
pieces.TStart = zeros(pieceCount, 1);
pieces.TEnd = zeros(pieceCount, 1);

for pieceIndex = 1:pieceCount
    t0 = uniqueBreaks(pieceIndex);
    t1 = uniqueBreaks(pieceIndex + 1);
    midpoint = originalStart + ((t0 + t1) / 2) * direction;
    cellIndex = floor((midpoint + halfBox) / boxLength);
    translation = -boxLength * cellIndex;
    startPoint = originalStart + t0 * direction + translation;
    endPoint = originalStart + t1 * direction + translation;
    startPoint = snapBoundary(startPoint, halfBox, tolerance);
    endPoint = snapBoundary(endPoint, halfBox, tolerance);
    if any(startPoint < -halfBox - tolerance) || any(startPoint > halfBox + tolerance) || ...
            any(endPoint < -halfBox - tolerance) || any(endPoint > halfBox + tolerance)
        error('wrapSegmentToBox:OutsideBox', ...
            'A generated piece lies outside the target box.');
    end
    pieces.Start(pieceIndex, :) = startPoint;
    pieces.End(pieceIndex, :) = endPoint;
    pieces.Length(pieceIndex) = norm(endPoint - startPoint);
    pieces.Translation(pieceIndex, :) = translation;
    pieces.TStart(pieceIndex) = t0;
    pieces.TEnd(pieceIndex) = t1;
end
end

function point = snapBoundary(point, halfBox, tolerance)
for axisIndex = 1:3
    if abs(point(axisIndex) - halfBox) <= tolerance
        point(axisIndex) = halfBox;
    elseif abs(point(axisIndex) + halfBox) <= tolerance
        point(axisIndex) = -halfBox;
    end
end
end

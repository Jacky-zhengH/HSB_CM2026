function [contacts, endpointCounts, candidates] = findBoundaryCandidates( ...
        groupIndex, analysis, canonicalDirections, cfg)
%FINDBOUNDARYCANDIDATES Diagnose boundary contacts and periodic pairings.
%   Translation is the vector applied to RecordB's endpoint so it overlaps
%   RecordA's endpoint. Candidates are evidence only; records are not merged.

points1 = analysis.P1;
points2 = analysis.P2;
tolerance = cfg.boundaryTolerance;
halfLength = cfg.HALF_L;

contacts.TouchXMin = abs(points1(:, 1) + halfLength) <= tolerance | ...
    abs(points2(:, 1) + halfLength) <= tolerance;
contacts.TouchXMax = abs(points1(:, 1) - halfLength) <= tolerance | ...
    abs(points2(:, 1) - halfLength) <= tolerance;
contacts.TouchYMin = abs(points1(:, 2) + halfLength) <= tolerance | ...
    abs(points2(:, 2) + halfLength) <= tolerance;
contacts.TouchYMax = abs(points1(:, 2) - halfLength) <= tolerance | ...
    abs(points2(:, 2) - halfLength) <= tolerance;
contacts.TouchZMin = abs(points1(:, 3) + halfLength) <= tolerance | ...
    abs(points2(:, 3) + halfLength) <= tolerance;
contacts.TouchZMax = abs(points1(:, 3) - halfLength) <= tolerance | ...
    abs(points2(:, 3) - halfLength) <= tolerance;

endpointCounts.XMin = sum(abs(points1(:, 1) + halfLength) <= tolerance) + ...
    sum(abs(points2(:, 1) + halfLength) <= tolerance);
endpointCounts.XMax = sum(abs(points1(:, 1) - halfLength) <= tolerance) + ...
    sum(abs(points2(:, 1) - halfLength) <= tolerance);
endpointCounts.YMin = sum(abs(points1(:, 2) + halfLength) <= tolerance) + ...
    sum(abs(points2(:, 2) + halfLength) <= tolerance);
endpointCounts.YMax = sum(abs(points1(:, 2) - halfLength) <= tolerance) + ...
    sum(abs(points2(:, 2) - halfLength) <= tolerance);
endpointCounts.ZMin = sum(abs(points1(:, 3) + halfLength) <= tolerance) + ...
    sum(abs(points2(:, 3) + halfLength) <= tolerance);
endpointCounts.ZMax = sum(abs(points1(:, 3) - halfLength) <= tolerance) + ...
    sum(abs(points2(:, 3) - halfLength) <= tolerance);

candidates.Group = zeros(0, 1);
candidates.RecordA = zeros(0, 1);
candidates.RecordB = zeros(0, 1);
candidates.Translation = zeros(0, 3);
candidates.DirectionError = zeros(0, 1);
candidates.EndpointError = zeros(0, 1);
candidates.BoundaryDescription = cell(0, 1);

recordCount = analysis.Records;
for recordA = 1:(recordCount - 1)
    for recordB = (recordA + 1):recordCount
        directionError = norm(canonicalDirections(recordA, :) - ...
            canonicalDirections(recordB, :));
        if directionError > cfg.directionTolerance
            continue;
        end

        endpointsA = [points1(recordA, :); points2(recordA, :)];
        endpointsB = [points1(recordB, :); points2(recordB, :)];
        for endpointA = 1:2
            for endpointB = 1:2
                delta = endpointsA(endpointA, :) - endpointsB(endpointB, :);
                translation = cfg.L * round(delta / cfg.L);
                if all(translation == 0) || any(abs(translation) > cfg.L)
                    continue;
                end

                endpointError = norm(delta - translation);
                if endpointError > tolerance
                    continue;
                end

                [oppositeBoundary, description] = verifyOppositeBoundaries( ...
                    endpointsA(endpointA, :), endpointsB(endpointB, :), ...
                    translation, halfLength, tolerance);
                if ~oppositeBoundary
                    continue;
                end

                duplicate = false;
                if ~isempty(candidates.Group)
                    duplicate = any(candidates.RecordA == analysis.RecordID(recordA) & ...
                        candidates.RecordB == analysis.RecordID(recordB) & ...
                        all(bsxfun(@eq, candidates.Translation, translation), 2));
                end
                if duplicate
                    continue;
                end

                next = numel(candidates.Group) + 1;
                candidates.Group(next, 1) = groupIndex;
                candidates.RecordA(next, 1) = analysis.RecordID(recordA);
                candidates.RecordB(next, 1) = analysis.RecordID(recordB);
                candidates.Translation(next, :) = translation;
                candidates.DirectionError(next, 1) = directionError;
                candidates.EndpointError(next, 1) = endpointError;
                candidates.BoundaryDescription{next, 1} = description;
            end
        end
    end
end
end

function [valid, description] = verifyOppositeBoundaries( ...
        endpointA, endpointB, translation, halfLength, tolerance)
axisNames = {'X', 'Y', 'Z'};
parts = cell(0, 1);
valid = true;

for axisIndex = 1:3
    if translation(axisIndex) == 0
        continue;
    end
    side = sign(translation(axisIndex));
    if abs(endpointA(axisIndex) - side * halfLength) > tolerance || ...
            abs(endpointB(axisIndex) + side * halfLength) > tolerance
        valid = false;
        description = '';
        return;
    end
    if side > 0
        parts{end + 1, 1} = sprintf('%sMax(A)<->%sMin(B)', ...
            axisNames{axisIndex}, axisNames{axisIndex}); %#ok<AGROW>
    else
        parts{end + 1, 1} = sprintf('%sMin(A)<->%sMax(B)', ...
            axisNames{axisIndex}, axisNames{axisIndex}); %#ok<AGROW>
    end
end

description = parts{1};
for partIndex = 2:numel(parts)
    description = [description ';' parts{partIndex}]; %#ok<AGROW>
end
end

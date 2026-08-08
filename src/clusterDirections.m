function [familyID, representatives, familyCounts, assignmentError] = ...
        clusterDirections(canonicalDirections, tolerance)
%CLUSTERDIRECTIONS Deterministically group nearly equal canonical axes.
% LEGACY_DIAGNOSTIC_ONLY: V2 never merges rows by DirectionFamily.
%   The first record encountered in a family remains its representative.

if size(canonicalDirections, 2) ~= 3
    error('clusterDirections:InvalidSize', ...
        'Canonical directions must be N-by-3.');
end

recordCount = size(canonicalDirections, 1);
familyID = zeros(recordCount, 1);
assignmentError = zeros(recordCount, 1);
representatives = zeros(0, 3);

for recordIndex = 1:recordCount
    direction = canonicalDirections(recordIndex, :);
    if isempty(representatives)
        representatives(1, :) = direction;
        familyID(recordIndex) = 1;
        continue;
    end

    differences = bsxfun(@minus, representatives, direction);
    errors = sqrt(sum(differences.^2, 2));
    [minimumError, nearestFamily] = min(errors);
    if minimumError <= tolerance
        familyID(recordIndex) = nearestFamily;
        assignmentError(recordIndex) = minimumError;
    else
        representatives(end + 1, :) = direction; %#ok<AGROW>
        familyID(recordIndex) = size(representatives, 1);
    end
end

familyCounts = zeros(size(representatives, 1), 1);
for familyIndex = 1:numel(familyCounts)
    familyCounts(familyIndex) = sum(familyID == familyIndex);
end
end

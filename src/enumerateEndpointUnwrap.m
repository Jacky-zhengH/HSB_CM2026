function result = enumerateEndpointUnwrap(p1, p2, boxLength, targetLength, tolerance)
%ENUMERATEENDPOINTUNWRAP Test all same-row P2 + L*k endpoint interpretations.
%   k is restricted to {-1,0,1}^3. No nearest invalid candidate is selected.

kValues = -1:1;
K = zeros(27, 3);
candidateLength = zeros(27, 1);
lengthError = zeros(27, 1);
valid = false(27, 1);
next = 0;
for kx = kValues
    for ky = kValues
        for kz = kValues
            next = next + 1;
            K(next, :) = [kx ky kz];
            unwrappedP2 = p2 + boxLength * K(next, :);
            candidateLength(next) = norm(unwrappedP2 - p1);
            lengthError(next) = candidateLength(next) - targetLength;
            valid(next) = abs(lengthError(next)) <= tolerance;
        end
    end
end

rawLength = norm(p2 - p1);
validIndices = find(valid);
if abs(rawLength - targetLength) <= tolerance
    status = 'DIRECT_5000';
    selectedIndex = find(all(K == 0, 2), 1, 'first');
elseif isempty(validIndices)
    status = 'NO_ENDPOINT_UNWRAP';
    selectedIndex = [];
elseif numel(validIndices) == 1
    status = 'UNIQUE_ENDPOINT_UNWRAP';
    selectedIndex = validIndices(1);
else
    status = 'AMBIGUOUS_ENDPOINT_UNWRAP';
    selectedIndex = [];
end

result.RawLength = rawLength;
result.K = K;
result.CandidateLength = candidateLength;
result.LengthError = lengthError;
result.Valid = valid;
result.ValidIndices = validIndices;
result.CandidateCount = numel(validIndices);
result.Status = status;
result.SelectedIndex = selectedIndex;
result.P1 = p1;
result.P2 = p2;
end

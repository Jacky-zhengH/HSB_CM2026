function [passed, lines] = testEndpointReverseReconstruction()
%TESTENDPOINTREVERSERECONSTRUCTION Endpoint images, dedup, and invariance.

cfg.L = 10000;
cfg.HALF_L = 5000;
cfg.mediumALength = 5000;
cfg.endpointLengthTolerance = 1e-6;
cfg.geometryTolerance = 1e-6;
passed = true;
lines = cell(0, 1);

% Case 1: direct length is still tested against every periodic candidate.
[relative, explicit, equivalent] = runBoth([-2500 0 0], [2500 0 0], cfg);
ok = size(relative.AllK, 1) == 27 && size(explicit.AllN1, 1) == 729 && ...
    any(relative.Valid5000 & all(bsxfun(@eq, relative.AllK, [0 0 0]), 2)) && ...
    equivalent;
[passed, lines] = record(passed, lines, ok, ...
    'CASE 1 direct 5000 still checks 27/729');

% Case 2: only X1 uses a nonzero image, so relative k=[-1,0,0].
p1 = [-3000 -2000 0]; p2 = [4000 2000 0];
[relative, explicit, equivalent] = runBoth(p1, p2, cfg);
hasExplicit = any(explicit.Valid5000 & ...
    all(bsxfun(@eq, explicit.AllN1, [1 0 0]), 2) & ...
    all(bsxfun(@eq, explicit.AllN2, [0 0 0]), 2));
ok = isUniqueK(relative, [-1 0 0]) && hasExplicit && equivalent;
[passed, lines] = record(passed, lines, ok, ...
    'CASE 2 X1-only image shift');

% Case 3: only X2 uses a nonzero image, so relative k=[1,0,0].
p1 = [4000 -2000 0]; p2 = [-3000 2000 0];
[relative, explicit, equivalent] = runBoth(p1, p2, cfg);
hasExplicit = any(explicit.Valid5000 & ...
    all(bsxfun(@eq, explicit.AllN1, [0 0 0]), 2) & ...
    all(bsxfun(@eq, explicit.AllN2, [1 0 0]), 2));
ok = isUniqueK(relative, [1 0 0]) && hasExplicit && equivalent;
[passed, lines] = record(passed, lines, ok, ...
    'CASE 3 X2-only image shift');

% Case 4: X1 shifts in X while X2 shifts in Z.
p1 = [-3000 0 -3000]; p2 = [4000 0 3000];
[relative, explicit, equivalent] = runBoth(p1, p2, cfg);
hasExplicit = any(explicit.Valid5000 & ...
    all(bsxfun(@eq, explicit.AllN1, [1 0 0]), 2) & ...
    all(bsxfun(@eq, explicit.AllN2, [0 0 -1]), 2));
ok = isUniqueK(relative, [-1 0 -1]) && hasExplicit && equivalent;
[passed, lines] = record(passed, lines, ok, ...
    'CASE 4 X1-X and X2-Z shifts');

% Case 5: X2 itself needs simultaneous X/Z recovery and creates 3 Pieces.
p1 = [-3000 0 -3000]; p2 = [3000 0 4000];
[relative, ~, equivalent] = runBoth(p1, p2, cfg);
selected = relative.SelectedIndex;
ok = isUniqueK(relative, [-1 0 -1]) && equivalent && ...
    relative.PieceCount(selected) == 3 && ...
    strcmp(relative.BoundaryEventSequence{selected}, 'X>Z') && ...
    abs(sum(relative.WrappedPieces{selected}.Length) - 5000) <= 1e-6;
[passed, lines] = record(passed, lines, ok, ...
    'CASE 5 simultaneous X/Z inverse then X>Z 3 Pieces');

% Case 6: all three components of k are nonzero.
dz = sqrt(5000^2 - 2000^2 - 3000^2);
wrappedDz = 10000 - dz;
p1 = [-4000 -3500 -wrappedDz/2];
p2 = [4000 3500 wrappedDz/2];
[relative, ~, equivalent] = runBoth(p1, p2, cfg);
ok = isUniqueK(relative, [-1 -1 -1]) && equivalent;
[passed, lines] = record(passed, lines, ok, ...
    'CASE 6 XYZ inverse shift');

% Case 7: many explicit (n1,n2) expressions collapse to one geometry.
p1 = [-3000 -2000 0]; p2 = [4000 2000 0];
[relative, explicit, equivalent] = runBoth(p1, p2, cfg);
ok = explicit.ValidCandidateCount > 1 && ...
    explicit.PhysicalCandidateCount == 1 && ...
    relative.PhysicalCandidateCount == 1 && equivalent;
[passed, lines] = record(passed, lines, ok, ...
    'CASE 7 explicit image expressions physically deduplicate');

% Case 8: antipodal endpoints define two genuinely different half-box arcs.
[relative, explicit, equivalent] = runBoth([-2500 0 0], [2500 0 0], cfg);
ok = strcmp(relative.Status, 'AMBIGUOUS_PERIODIC') && ...
    relative.PhysicalCandidateCount == 2 && ...
    explicit.PhysicalCandidateCount == 2 && equivalent;
[passed, lines] = record(passed, lines, ok, ...
    'CASE 8 distinct physical candidates remain ambiguous');

% Case 9: unresolved is data, not an exception; the next case still runs.
[relative, explicit, equivalent] = runBoth([0 0 0], [1000 0 0], cfg);
ok = strcmp(relative.Status, 'UNRESOLVED') && ...
    explicit.PhysicalCandidateCount == 0 && equivalent;
[passed, lines] = record(passed, lines, ok, ...
    'CASE 9 invalid endpoints remain unresolved');

% Case 10: reversing endpoint order preserves the physical geometry set.
forward = unwrapMediumEndpoints([-3000 -2000 0], [4000 2000 0], cfg);
reverse = unwrapMediumEndpoints([4000 2000 0], [-3000 -2000 0], cfg);
ok = sameWrappedGeometrySets(forward.WrappedPieces, reverse.WrappedPieces, ...
    cfg.geometryTolerance);
[passed, lines] = record(passed, lines, ok, ...
    'CASE 10 endpoint reversal invariance');
end

function [relative, explicit, equivalent] = runBoth(p1, p2, cfg)
relative = unwrapMediumEndpoints(p1, p2, cfg);
explicit = enumerateEndpointImagePairs(p1, p2, cfg);
equivalent = sameWrappedGeometrySets(relative.WrappedPieces, ...
    explicit.PhysicalGeometries, cfg.geometryTolerance);
end

function result = isUniqueK(item, expectedK)
result = strcmp(item.Status, 'UNIQUE') && ...
    all(item.CandidatesK(item.SelectedIndex, :) == expectedK);
end

function [passed, lines] = record(passed, lines, ok, name)
passed = passed && ok;
lines{end + 1, 1} = sprintf('%s PASS=%d', name, ok);
end

function [passed, lines] = testRetainedPartReconstruction()
%TESTRETAINEDPARTRECONSTRUCTION Thirteen retained-part model gates.

cfg.L = 10000;
cfg.HALF_L = 5000;
cfg.mediumALength = 5000;
cfg.lengthTolerance = 1e-6;
cfg.geometryTolerance = 1e-8;
cfg.replayTolerance = 1e-6;
passed = true;
lines = cell(0, 1);

caseIndex = 0;
checkCase([-2500 0 0], [2500 0 0], 'DIRECT_FULL', 1, 'NONE', true, []);
checkCase([1000 0 0], [5000 0 0], ...
    'RETAINED_SINGLE_BOUNDARY_UNIQUE', 2, 'X', true, [6000 0 0]);
forward = reconstructFromRetainedPart([1000 0 0], [5000 0 0], cfg);
reverse = reconstructFromRetainedPart([5000 0 0], [1000 0 0], cfg);
caseIndex = caseIndex + 1;
ok = reverse.IsUniquelyReconstructed && ...
    max(abs(forward.ReconstructedOriginalStart - reverse.ReconstructedOriginalStart)) < 1e-7 && ...
    max(abs(forward.ReconstructedOriginalEnd - reverse.ReconstructedOriginalEnd)) < 1e-7;
record(ok, 'CASE 3 endpoint reversal is physically equivalent');
checkCase([4000 0 0], [5000 0 0], ...
    'RETAINED_SINGLE_BOUNDARY_UNIQUE', 2, 'X', true, [9000 0 0]);
checkCase([-4000 0 0], [-5000 0 0], ...
    'RETAINED_SINGLE_BOUNDARY_UNIQUE', 2, 'X', true, [-9000 0 0]);
checkCase([0 4000 0], [0 5000 0], ...
    'RETAINED_SINGLE_BOUNDARY_UNIQUE', 2, 'Y', true, [0 9000 0]);
checkCase([0 0 -4000], [0 0 -5000], ...
    'RETAINED_SINGLE_BOUNDARY_UNIQUE', 2, 'Z', true, [0 0 -9000]);

originalStart = [-3000 0 -3000];
originalEnd = [-7000 0 -6000];
tX = (-5000 - originalStart(1)) / (originalEnd(1) - originalStart(1));
observedBoundary = originalStart + tX * (originalEnd - originalStart);
checkCase(originalStart, observedBoundary, ...
    'RETAINED_SINGLE_BOUNDARY_UNIQUE', 3, 'X>Z', true, originalEnd);

dz = sqrt(5000^2 - 3000^2 - 3000^2);
originalStart = [4500 4000 3500];
originalEnd = originalStart + [3000 3000 dz];
tX = (5000 - originalStart(1)) / (originalEnd(1) - originalStart(1));
observedBoundary = originalStart + tX * (originalEnd - originalStart);
checkCase(originalStart, observedBoundary, ...
    'RETAINED_SINGLE_BOUNDARY_UNIQUE', 4, 'X>Y>Z', true, originalEnd);

step = 5000 / sqrt(2);
originalStart = [4000 4000 0];
originalEnd = originalStart + [step step 0];
tXY = (5000 - originalStart(1)) / step;
observedBoundary = originalStart + tXY * (originalEnd - originalStart);
simultaneous = reconstructFromRetainedPart(originalStart, observedBoundary, cfg);
caseIndex = caseIndex + 1;
ok = simultaneous.IsUniquelyReconstructed && ...
    strcmp(simultaneous.BoundaryEventSequence, 'XY_SIMULTANEOUS') && ...
    all(simultaneous.ForwardPieces.Length > cfg.geometryTolerance);
record(ok, 'CASE 10 simultaneous XY has no zero-length Piece');

checkCase([0 0 0], [1000 0 0], 'UNRESOLVED_NO_FORMAL_BOUNDARY', ...
    0, 'NONE', false, []);
checkCase([5000 0 0], [5000 1000 0], ...
    'AMBIGUOUS_TWO_BOUNDARY_RETAINED', 0, 'NONE', false, []);
bad = reconstructFromRetainedPart([4000 6000 0], [5000 5000 0], cfg);
caseIndex = caseIndex + 1;
ok = strcmp(bad.Status, 'REJECTED_FORWARD_REPLAY') && ...
    ~bad.ObservedPieceMatched;
record(ok, 'CASE 13 invalid observed placement fails zero-translation replay');

    function checkCase(p1, p2, expectedStatus, expectedPieces, ...
            expectedSequence, expectedUnique, expectedEnd)
        item = reconstructFromRetainedPart(p1, p2, cfg);
        caseIndex = caseIndex + 1;
        okLocal = strcmp(item.Status, expectedStatus) && ...
            item.IsUniquelyReconstructed == expectedUnique;
        if expectedUnique
            okLocal = okLocal && item.ForwardPieceCount == expectedPieces && ...
                strcmp(item.BoundaryEventSequence, expectedSequence) && ...
                item.ObservedPieceMatched && ...
                abs(norm(item.ReconstructedOriginalEnd - ...
                    item.ReconstructedOriginalStart) - 5000) <= 1e-6;
            if ~isempty(expectedEnd)
                okLocal = okLocal && ...
                    max(abs(item.ReconstructedOriginalEnd - expectedEnd)) <= 1e-6;
            end
        end
        record(okLocal, sprintf('CASE %d %s', caseIndex, expectedStatus));
    end

    function record(okLocal, label)
        passed = passed && okLocal;
        lines{end + 1, 1} = sprintf('%s PASS=%d', label, okLocal);
    end
end

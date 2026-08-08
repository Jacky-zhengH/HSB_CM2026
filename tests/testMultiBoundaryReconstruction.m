function [passed, lines] = testMultiBoundaryReconstruction()
%TESTMULTIBOUNDARYRECONSTRUCTION Three Pieces and middle-Piece R3 recovery.

cfg.L = 10000;
cfg.HALF_L = 5000;
cfg.mediumALength = 5000;
cfg.reconstructionTolerance = 1e-6;
lines = cell(0, 1);
passed = true;

originalStart = [4000 3000 0];
originalEnd = [7000 7000 0]; % displacement [3000,4000,0], length 5000
pieces = wrapSegmentToBox(originalStart, originalEnd, cfg.HALF_L, ...
    cfg.L, cfg.reconstructionTolerance);
ok = size(pieces.Start, 1) == 3 && ...
    isequal(pieces.Translation(1, :), [0 0 0]) && ...
    isequal(pieces.Translation(2, :), [-10000 0 0]) && ...
    isequal(pieces.Translation(3, :), [-10000 -10000 0]);
passed = passed && ok;
lines{end + 1, 1} = sprintf('R3 forward wrap crosses X then Y into 3 Pieces: PASS=%d', ok);

middleStart = pieces.Start(2, :);
middleEnd = pieces.End(2, :);
result = reconstructRowR3(middleStart, middleEnd, cfg);
ok = strcmp(result.Status, 'AMBIGUOUS') && result.CandidateCount >= 2 && ...
    all(abs(sqrt(sum((result.OriginalEnd(result.ValidIndices, :) - ...
    result.OriginalStart(result.ValidIndices, :)).^2, 2)) - 5000) <= 1e-6);
passed = passed && ok;
lines{end + 1, 1} = sprintf( ...
    'R3 middle Piece reverse recovery is explicitly AMBIGUOUS: candidates=%d PASS=%d', ...
    result.CandidateCount, ok);
end

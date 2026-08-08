function [passed, lines] = testObservedMediumReconstruction()
%TESTOBSERVEDMEDIUMRECONSTRUCTION Unified formal reconstruction gates.

cfg.L = 10000;
cfg.HALF_L = 5000;
cfg.mediumALength = 5000;
cfg.reconstructionTolerance = 1e-6;
passed = true;
lines = cell(0, 1);

result = reconstructObservedMedium([-2500 0 0], [2500 0 0], cfg);
ok = strcmp(result.Status, 'UNIQUE') && ...
    strcmp(result.CandidateType{result.SelectedIndex}, 'DIRECT');
passed = passed && ok;
lines{end + 1, 1} = sprintf('Direct 5000 reconstruction PASS=%d', ok);

result = reconstructObservedMedium([4000 4000 0], [-3000 -2000 0], cfg);
selectedK = result.K(result.SelectedIndex, :);
ok = strcmp(result.Status, 'UNIQUE') && all(selectedK == [1 1 0]);
passed = passed && ok;
lines{end + 1, 1} = sprintf( ...
    '27-case endpoint unwrap including simultaneous X/Y PASS=%d', ok);

result = reconstructObservedMedium([1000 0 0], [5000 0 0], cfg);
ok = strcmp(result.Status, 'UNIQUE') && ...
    max(abs(result.OriginalEnd(result.SelectedIndex, :) - [6000 0 0])) <= 1e-6;
passed = passed && ok;
lines{end + 1, 1} = sprintf('Single-boundary Piece reconstruction PASS=%d', ok);

originalStart = [4000 3000 0];
originalEnd = [7000 7000 0];
pieces = wrapSegmentToBox(originalStart, originalEnd, cfg.HALF_L, ...
    cfg.L, cfg.reconstructionTolerance);
result = reconstructObservedMedium(pieces.Start(2, :), pieces.End(2, :), cfg);
ok = strcmp(result.Status, 'AMBIGUOUS') && result.CandidateCount >= 2;
passed = passed && ok;
lines{end + 1, 1} = sprintf( ...
    'Middle GeometryPiece remains AMBIGUOUS candidates=%d PASS=%d', ...
    result.CandidateCount, ok);

result = reconstructObservedMedium([0 0 0], [1000 0 0], cfg);
ok = strcmp(result.Status, 'UNRESOLVED') && result.CandidateCount == 0;
passed = passed && ok;
lines{end + 1, 1} = sprintf('No-nearest-fallback UNRESOLVED PASS=%d', ok);
end

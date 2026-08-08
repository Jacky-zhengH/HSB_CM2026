function [passed, lines] = testWrapSegmentToBox()
%TESTWRAPSEGMENTTOBOX Periodic X and simultaneous X/Y boundary tests.

lines = cell(0, 1);
passed = true;

pieces = wrapSegmentToBox([1000 0 0], [6000 0 0], 5000, 10000, 1e-8);
ok = size(pieces.Start, 1) == 2 && ...
    max(abs(pieces.Start(1, :) - [1000 0 0])) <= 1e-8 && ...
    max(abs(pieces.End(1, :) - [5000 0 0])) <= 1e-8 && ...
    max(abs(pieces.Start(2, :) - [-5000 0 0])) <= 1e-8 && ...
    max(abs(pieces.End(2, :) - [-4000 0 0])) <= 1e-8;
passed = passed && ok;
lines{end + 1} = sprintf('Wrap X boundary into two pieces: PASS=%d', ok);

step = 5000 / sqrt(2);
pieces = wrapSegmentToBox([4000 4000 0], [4000 + step 4000 + step 0], ...
    5000, 10000, 1e-8);
totalLength = sum(pieces.Length);
ok = size(pieces.Start, 1) == 2 && abs(totalLength - 5000) <= 1e-6 && ...
    max(abs(pieces.End(1, 1:2) - [5000 5000])) <= 1e-6 && ...
    max(abs(pieces.Start(2, 1:2) - [-5000 -5000])) <= 1e-6;
passed = passed && ok;
lines{end + 1} = sprintf('Wrap simultaneous X/Y crossing: PASS=%d', ok);
end

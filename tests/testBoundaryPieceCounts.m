function [passed, lines] = testBoundaryPieceCounts()
%TESTBOUNDARYPIECECOUNTS One, two, three, and simultaneous event gates.

halfBox = 5000;
boxLength = 10000;
tolerance = 1e-8;
passed = true;
lines = cell(0, 1);

one = wrapSegmentToBox([-2500 0 0], [2500 0 0], halfBox, boxLength, tolerance);
ok = size(one.Start, 1) == 1 && abs(sum(one.Length) - 5000) <= 1e-6;
passed = passed && ok;
lines{end + 1, 1} = sprintf('1-Piece boundary PASS=%d', ok);

two = wrapSegmentToBox([1000 0 0], [6000 0 0], halfBox, boxLength, tolerance);
[sequence, ~] = extractBoundaryEvents(two.Translation, tolerance);
ok = size(two.Start, 1) == 2 && strcmp(sequence, 'X') && ...
    abs(sum(two.Length) - 5000) <= 1e-6;
passed = passed && ok;
lines{end + 1, 1} = sprintf('2-Piece boundary PASS=%d', ok);

three = wrapSegmentToBox([4000 3000 0], [7000 7000 0], ...
    halfBox, boxLength, tolerance);
[sequence, ~] = extractBoundaryEvents(three.Translation, tolerance);
ok = size(three.Start, 1) == 3 && strcmp(sequence, 'X>Y') && ...
    abs(sum(three.Length) - 5000) <= 1e-6;
passed = passed && ok;
lines{end + 1, 1} = sprintf('3-Piece boundary PASS=%d', ok);

step = 5000 / sqrt(2);
simultaneous = wrapSegmentToBox([4000 4000 0], ...
    [4000 + step 4000 + step 0], halfBox, boxLength, tolerance);
[sequence, ~] = extractBoundaryEvents(simultaneous.Translation, tolerance);
ok = size(simultaneous.Start, 1) == 2 && ...
    strcmp(sequence, 'XY_SIMULTANEOUS') && ...
    all(simultaneous.Length > tolerance) && ...
    abs(sum(simultaneous.Length) - 5000) <= 1e-6;
passed = passed && ok;
lines{end + 1, 1} = sprintf( ...
    'Simultaneous multi-axis boundary has no zero-length Piece PASS=%d', ok);
end

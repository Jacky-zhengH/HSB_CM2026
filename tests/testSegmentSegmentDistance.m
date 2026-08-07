function [passed, lines] = testSegmentSegmentDistance()
%TESTSEGMENTSEGMENTDISTANCE Deterministic finite-segment distance tests.

lines = cell(0, 1);
passed = true;
cases = cell(5, 1);
cases{1} = {[0 0 0], [2 0 0], [1 -1 0], [1 1 0], 0, '相交'};
cases{2} = {[0 0 0], [2 0 0], [0 3 0], [2 3 0], 3, '平行'};
cases{3} = {[0 0 0], [1 0 0], [0 1 2], [0 2 2], sqrt(5), '异面'};
cases{4} = {[0 0 0], [1 0 0], [3 2 0], [3 4 0], sqrt(8), '端点最近'};
cases{5} = {[0 0 0], [2 0 0], [1 0 0], [3 0 0], 0, '重合'};

for index = 1:numel(cases)
    item = cases{index};
    [distance, s, t] = segmentSegmentDistance(item{1}, item{2}, item{3}, item{4});
    ok = abs(distance - item{5}) <= 1e-10 && s >= 0 && s <= 1 && t >= 0 && t <= 1;
    passed = passed && ok;
    lines{end + 1, 1} = sprintf('Segment CASE %d (%s): d=%.12g expected=%.12g PASS=%d', ...
        index, item{6}, distance, item{5}, ok); %#ok<AGROW>
end
end

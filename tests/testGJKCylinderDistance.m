function [passed, lines] = testGJKCylinderDistance(logPath)
%TESTGJKCYLINDERDISTANCE Flat-ended finite-cylinder GJK regression tests.

radius = 30;
tolerance = 1e-9;
maximumIterations = 100;
lines = cell(0, 1);
passed = true;

caseData = cell(4, 1);
caseData{1} = {[-100 0 0], [100 0 0], [-100 61 0], [100 61 0], 1, '平行侧面间距1nm'};
caseData{2} = {[-100 0 0], [100 0 0], [150 0 0], [350 0 0], 50, '共轴平端间距50nm'};
caseData{3} = {[-100 0 0], [100 0 0], [-100 50 0], [100 50 0], 0, '真实相交'};
caseData{4} = {[-100 0 0], [100 0 0], [0 -100 0], [0 100 0], 0, '垂直交叉'};

for index = 1:numel(caseData)
    item = caseData{index};
    [distance, ~, ~, iterations, converged] = gjkCylinderDistance( ...
        item{1}, item{2}, radius, item{3}, item{4}, radius, ...
        tolerance, maximumIterations);
    allowed = 1e-6;
    ok = converged && abs(distance - item{5}) <= allowed;
    passed = passed && ok;
    lines{end + 1, 1} = sprintf( ...
        'GJK CASE %d (%s): d=%.12g expected=%.12g iter=%d converged=%d PASS=%d', ...
        index, item{6}, distance, item{5}, iterations, converged, ok); %#ok<AGROW>
end

item = caseData{1};
distanceAB = gjkCylinderDistance(item{1}, item{2}, radius, ...
    item{3}, item{4}, radius, tolerance, maximumIterations);
distanceBA = gjkCylinderDistance(item{3}, item{4}, radius, ...
    item{1}, item{2}, radius, tolerance, maximumIterations);
symmetryOK = abs(distanceAB - distanceBA) <= 1e-8;
passed = passed && symmetryOK;
lines{end + 1, 1} = sprintf( ...
    'GJK CASE 5 (交换对称性): dAB=%.12g dBA=%.12g PASS=%d', ...
    distanceAB, distanceBA, symmetryOK);
lines{end + 1, 1} = sprintf('GJK ALL TESTS PASSED=%d', passed);

fileID = fopen(logPath, 'w');
if fileID < 0
    error('testGJKCylinderDistance:LogOpenFailed', 'Cannot write: %s', logPath);
end
for index = 1:numel(lines)
    fprintf(1, '%s\n', lines{index});
    fprintf(fileID, '%s\r\n', lines{index});
end
fclose(fileID);
end

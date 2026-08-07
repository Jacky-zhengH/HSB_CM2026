function selection = generateV11PaperFigures(groups, analyses, parentMaps, ...
        candidates, cfg, figureDir)
%GENERATEV11PAPERFIGURES V1.1 explanatory figures; core results unchanged.

selection = drawSelectedGroup1Path(analyses{1}, parentMaps{1, 2}, cfg, figureDir);
drawBoundaryExamples(groups, candidates, cfg, figureDir);
drawCapsuleGJKExample(analyses{3}, cfg, figureDir);
end

function selection = drawSelectedGroup1Path(analysis, parentMap, cfg, figureDir)
parentCount = max(parentMap);
leftContact = false(parentCount, 1);
rightContact = false(parentCount, 1);
for pieceIndex = 1:analysis.Records
    [leftDistance, rightDistance] = cylinderPlaneDistance( ...
        analysis.P1(pieceIndex, :), analysis.P2(pieceIndex, :), ...
        cfg.mediumARadius, cfg.HALF_L);
    parentID = parentMap(pieceIndex);
    leftContact(parentID) = leftContact(parentID) || leftDistance <= cfg.conductionDistance;
    rightContact(parentID) = rightContact(parentID) || rightDistance <= cfg.conductionDistance;
end
directParents = find(leftContact & rightContact);
if isempty(directParents)
    error('generateV11PaperFigures:NoDirectParent', ...
        'Group1 M1 has no Parent connecting both electrodes.');
end
lengthErrors = zeros(numel(directParents), 1);
totalLengths = zeros(numel(directParents), 1);
for index = 1:numel(directParents)
    records = find(parentMap == directParents(index));
    totalLengths(index) = sum(analysis.SegmentLength(records));
    lengthErrors(index) = abs(totalLengths(index) - cfg.mediumALength);
end
[~, order] = sortrows([lengthErrors directParents], [1 2]);
selectedParent = directParents(order(1));
selectedRecords = find(parentMap == selectedParent);
selectedLength = sum(analysis.SegmentLength(selectedRecords));

figureHandle = figure('Visible', 'off', 'Color', 'w');
hold on;
drawElectrodes(cfg.HALF_L);
for pieceIndex = 1:analysis.Records
    if parentMap(pieceIndex) == selectedParent
        color = [0.85 0.05 0.05];
        width = 3.0;
    else
        color = [0.72 0.72 0.72];
        width = 0.7;
    end
    plot3([analysis.P1(pieceIndex, 1) analysis.P2(pieceIndex, 1)], ...
        [analysis.P1(pieceIndex, 2) analysis.P2(pieceIndex, 2)], ...
        [analysis.P1(pieceIndex, 3) analysis.P2(pieceIndex, 3)], ...
        '-', 'Color', color, 'LineWidth', width);
end
recordText = sprintf('%d;', selectedRecords);
recordText(end) = [];
title({sprintf('Group 1 | M1 Parents=%d | Conducting=1', parentCount), ...
    sprintf('LEFT -> P%d -> RIGHT', selectedParent), ...
    sprintf('Selected ParentID=P%d | RecordIDs=%s | TotalAxisLength=%.12g nm', ...
    selectedParent, recordText, selectedLength)});
xlabel('x / nm'); ylabel('y / nm'); zlabel('z / nm');
axis equal;
axis([-cfg.HALF_L cfg.HALF_L -cfg.HALF_L cfg.HALF_L -cfg.HALF_L cfg.HALF_L]);
grid on;
view(3);
hold off;
print(figureHandle, fullfile(figureDir, 'q1_group1_3d.png'), '-dpng', '-r300');
savefig(figureHandle, fullfile(figureDir, 'q1_group1_3d.fig'));
close(figureHandle);

selection.ParentID = selectedParent;
selection.RecordIDs = selectedRecords(:)';
selection.TotalAxisLength = selectedLength;
selection.DirectParents = directParents(:)';
end

function drawBoundaryExamples(groups, candidates, cfg, figureDir)
legendLabels = {unicodeText({'539F','59CB','7247','6BB5'}, ' A'), ...
    unicodeText({'539F','59CB','7247','6BB5'}, ' B'), ...
    unicodeText({'5E73','79FB','540E','7247','6BB5'}, ' B'), ...
    unicodeText({'5468','671F','5E73','79FB','7BAD','5934'}, ''), ...
    unicodeText({'8FB9','754C','76D2'}, '')};

figureHandle = figure('Visible', 'off', 'Color', 'w', 'Position', [100 100 1650 560]);
for groupIndex = 1:3
    subplot(1, 3, groupIndex);
    groupRows = find(candidates.Group == groupIndex);
    score = [candidates.EndpointError(groupRows) candidates.DirectionError(groupRows)];
    [~, order] = sortrows(score, [1 2]);
    selected = groupRows(order(1));
    recordA = candidates.RecordA(selected);
    recordB = candidates.RecordB(selected);
    translation = candidates.Translation(selected, :);
    p1A = groups(groupIndex).P1(recordA, :);
    p2A = groups(groupIndex).P2(recordA, :);
    p1B = groups(groupIndex).P1(recordB, :);
    p2B = groups(groupIndex).P2(recordB, :);
    translatedP1 = p1B + translation;
    translatedP2 = p2B + translation;
    midpointB = (p1B + p2B) / 2;

    hold on;
    boxHandle = drawBox(cfg.HALF_L);
    handleA = plot3([p1A(1) p2A(1)], [p1A(2) p2A(2)], [p1A(3) p2A(3)], ...
        'b-', 'LineWidth', 2.5);
    handleB = plot3([p1B(1) p2B(1)], [p1B(2) p2B(2)], [p1B(3) p2B(3)], ...
        'r-', 'LineWidth', 2.5);
    handleTranslated = plot3([translatedP1(1) translatedP2(1)], ...
        [translatedP1(2) translatedP2(2)], [translatedP1(3) translatedP2(3)], ...
        'g--', 'LineWidth', 2.5);
    arrowHandle = quiver3(midpointB(1), midpointB(2), midpointB(3), ...
        translation(1), translation(2), translation(3), 0, ...
        'Color', [0 0.55 0], 'LineWidth', 1.5, 'MaxHeadSize', 0.25);
    hold off;
    axis equal;
    grid on;
    view(3);
    xlabel('x / nm'); ylabel('y / nm'); zlabel('z / nm');
    title({sprintf('Group %d | RecordID A=%d, B=%d', groupIndex, recordA, recordB), ...
        sprintf('Translation Vector = [%g, %g, %g] nm', translation)});
    if groupIndex == 1
        legend([handleA handleB handleTranslated arrowHandle boxHandle], ...
            legendLabels, 'Location', 'SouthOutside');
    end
end
print(figureHandle, fullfile(figureDir, 'boundary_reconstruction_examples.png'), '-dpng', '-r300');
close(figureHandle);
end

function drawCapsuleGJKExample(analysis, cfg, figureDir)
pieceA = 208;
pieceB = 225;
p1A = analysis.P1(pieceA, :); p2A = analysis.P2(pieceA, :);
p1B = analysis.P1(pieceB, :); p2B = analysis.P2(pieceB, :);
[axisDistance, ~, ~, axisPointA, axisPointB] = segmentSegmentDistance( ...
    p1A, p2A, p1B, p2B);
[exactDistance, exactPointA, exactPointB, ~, converged] = gjkCylinderDistance( ...
    p1A, p2A, cfg.mediumARadius, p1B, p2B, cfg.mediumARadius, ...
    cfg.gjkTolerance, cfg.gjkMaxIterations);
if ~converged
    error('generateV11PaperFigures:GJKNotConverged', ...
        'GJK failed for the documented Piece208/Piece225 example.');
end
capsuleDistance = axisDistance - 2 * cfg.mediumARadius;

figureHandle = figure('Visible', 'off', 'Color', 'w', 'Position', [100 100 1650 720]);
falsePositiveText = unicodeText({'771F','5B9E','6709','9650','5706','67F1','4E0D','5BFC','901A'}, '');

subplot(1, 2, 1);
plotCylinderScene(p1A, p2A, p1B, p2B, cfg.mediumARadius, ...
    axisPointA, axisPointB, exactPointA, exactPointB, false);
title(sprintf('Group 3 Piece %d / Piece %d: Full Geometry', pieceA, pieceB));

subplot(1, 2, 2);
[axisAHandle, axisBHandle, axisGapHandle, exactGapHandle] = plotCylinderScene( ...
    p1A, p2A, p1B, p2B, cfg.mediumARadius, axisPointA, axisPointB, ...
    exactPointA, exactPointB, true);
focusCenter = mean([axisPointA; axisPointB; exactPointA; exactPointB], 1);
focusRadius = 90;
xlim(focusCenter(1) + [-focusRadius focusRadius]);
ylim(focusCenter(2) + [-focusRadius focusRadius]);
zlim(focusCenter(3) + [-focusRadius focusRadius]);
title({'Capsule=False Positive | Closest Region', ...
    sprintf('AxisDistance=%.6f nm | CapsuleDistance=%.6f nm', axisDistance, capsuleDistance), ...
    sprintf('ExactDistance=%.6f nm > D0=%.1f nm | %s', ...
    exactDistance, cfg.conductionDistance, falsePositiveText)});
legend([axisAHandle axisBHandle axisGapHandle exactGapHandle], ...
    {'Piece 208 axis', 'Piece 225 axis', 'AxisDistance', 'ExactDistance'}, ...
    'Location', 'SouthOutside');
print(figureHandle, fullfile(figureDir, 'capsule_vs_gjk_example.png'), '-dpng', '-r300');
savefig(figureHandle, fullfile(figureDir, 'capsule_vs_gjk_example.fig'));
close(figureHandle);
end

function [axisAHandle, axisBHandle, axisGapHandle, exactGapHandle] = ...
        plotCylinderScene(p1A, p2A, p1B, p2B, radius, ...
        axisPointA, axisPointB, exactPointA, exactPointB, zoomed)
hold on;
drawCylinder(p1A, p2A, radius, [0.20 0.45 0.90]);
drawCylinder(p1B, p2B, radius, [0.90 0.35 0.20]);
axisAHandle = plot3([p1A(1) p2A(1)], [p1A(2) p2A(2)], [p1A(3) p2A(3)], ...
    'b-', 'LineWidth', 2);
axisBHandle = plot3([p1B(1) p2B(1)], [p1B(2) p2B(2)], [p1B(3) p2B(3)], ...
    'r-', 'LineWidth', 2);
axisGapHandle = plot3([axisPointA(1) axisPointB(1)], ...
    [axisPointA(2) axisPointB(2)], [axisPointA(3) axisPointB(3)], ...
    'm--', 'LineWidth', 3);
exactGapHandle = plot3([exactPointA(1) exactPointB(1)], ...
    [exactPointA(2) exactPointB(2)], [exactPointA(3) exactPointB(3)], ...
    'k-', 'LineWidth', 4);
hold off;
axis equal;
grid on;
view(3);
xlabel('x / nm'); ylabel('y / nm'); zlabel('z / nm');
if zoomed
    set(gca, 'FontSize', 9);
end
end

function drawCylinder(p1, p2, radius, color)
u = (p2 - p1) / norm(p2 - p1);
if abs(u(1)) < 0.9
    reference = [1 0 0];
else
    reference = [0 1 0];
end
e1 = cross(u, reference); e1 = e1 / norm(e1);
e2 = cross(u, e1);
theta = linspace(0, 2 * pi, 33);
circle = radius * (e1' * cos(theta) + e2' * sin(theta));
first = bsxfun(@plus, p1', circle);
second = bsxfun(@plus, p2', circle);
surface([first(1, :); second(1, :)], [first(2, :); second(2, :)], ...
    [first(3, :); second(3, :)], 'FaceColor', color, 'FaceAlpha', 0.35, ...
    'EdgeColor', 'none', 'HandleVisibility', 'off');
patch(first(1, :), first(2, :), first(3, :), color, 'FaceAlpha', 0.35, ...
    'EdgeColor', 'none', 'HandleVisibility', 'off');
patch(second(1, :), second(2, :), second(3, :), color, 'FaceAlpha', 0.35, ...
    'EdgeColor', 'none', 'HandleVisibility', 'off');
end

function handle = drawBox(halfLength)
vertices = halfLength * [-1 -1 -1; 1 -1 -1; 1 1 -1; -1 1 -1; ...
    -1 -1 1; 1 -1 1; 1 1 1; -1 1 1];
edges = [1 2; 2 3; 3 4; 4 1; 5 6; 6 7; 7 8; 8 5; 1 5; 2 6; 3 7; 4 8];
handle = [];
for index = 1:size(edges, 1)
    item = plot3(vertices(edges(index, :), 1), vertices(edges(index, :), 2), ...
        vertices(edges(index, :), 3), '-', 'Color', [0.6 0.6 0.6]);
    if index == 1
        handle = item;
    else
        set(item, 'HandleVisibility', 'off');
    end
end
end

function drawElectrodes(halfLength)
values = [-halfLength halfLength];
[y, z] = meshgrid(values, values);
surface(-halfLength * ones(2), y, z, 'FaceColor', [0.2 0.4 0.9], ...
    'FaceAlpha', 0.18, 'EdgeColor', 'none');
surface(halfLength * ones(2), y, z, 'FaceColor', [1.0 0.5 0.1], ...
    'FaceAlpha', 0.18, 'EdgeColor', 'none');
end

function textValue = unicodeText(hexCodes, suffix)
values = zeros(1, numel(hexCodes));
for index = 1:numel(hexCodes)
    values(index) = hex2dec(hexCodes{index});
end
textValue = [char(values) suffix];
end

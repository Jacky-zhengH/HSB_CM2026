function generateQ1Figures(analyses, reconstructions, piecesByGroup, ...
        graphs, groupStats, cfg, figureDir)
%GENERATEQ1FIGURES Formal R2016a-compatible paper figures for Q1.

drawBoundaryPieceExamples(cfg, figureDir);
drawChargeVsConduction(figureDir);
drawCapsuleVsGJK(analyses, cfg, figureDir);
drawReconstructionStatus(groupStats, figureDir);
for groupIndex = 1:3
    drawPieceNetwork(groupIndex, piecesByGroup{groupIndex}, ...
        graphs{groupIndex}, groupStats(groupIndex), cfg, figureDir);
end
end

function drawBoundaryPieceExamples(cfg, figureDir)
dz = sqrt(5000^2 - 3000^2 - 3000^2);
starts = {[1000 0 0], [4000 3000 0], [4500 4000 3500]};
ends = {[6000 0 0], [7000 7000 0], ...
    [7500 7000 3500 + dz]};
labels = {'2 Pieces: X', '3 Pieces: X > Y', '4 Pieces: X > Y > Z'};
colors = lines(4);
figureHandle = figure('Visible', 'off', 'Color', 'w', ...
    'Position', [100 100 1500 500]);
for exampleIndex = 1:3
    wrapped = wrapSegmentToBox(starts{exampleIndex}, ends{exampleIndex}, ...
        cfg.HALF_L, cfg.L, cfg.reconstructionTolerance);
    subplot(1, 3, exampleIndex); hold on; drawBox(cfg.HALF_L);
    for pieceIndex = 1:size(wrapped.Start, 1)
        plot3([wrapped.Start(pieceIndex, 1) wrapped.End(pieceIndex, 1)], ...
            [wrapped.Start(pieceIndex, 2) wrapped.End(pieceIndex, 2)], ...
            [wrapped.Start(pieceIndex, 3) wrapped.End(pieceIndex, 3)], ...
            'o-', 'Color', colors(pieceIndex, :), 'LineWidth', 3, ...
            'MarkerSize', 5);
    end
    hold off; axis equal; grid on; view(3);
    axis([-5000 5000 -5000 5000 -5000 5000]);
    xlabel('x / nm'); ylabel('y / nm'); zlabel('z / nm');
    title(labels{exampleIndex});
end
savePaperFigure(figureHandle, fullfile(figureDir, 'boundary_piece_examples'));
end

function drawChargeVsConduction(figureDir)
figureHandle = figure('Visible', 'off', 'Color', 'w', ...
    'Position', [100 100 1500 600]);

subplot(1, 2, 1); hold on;
plot([0 0], [-1 1], 'b-', 'LineWidth', 8);
plot([10 10], [-1 1], 'Color', [1 .5 .1], 'LineWidth', 8);
plotNode(2, 0, 'A1-1', true); plotNode(8, 0, 'A1-2', true);
plot([2.7 7.3], [0 0], ':', 'Color', [.55 .55 .55], 'LineWidth', 2);
text(5, .35, 'NO physical edge', 'HorizontalAlignment', 'center');
plot([.2 1.3], [0 0], 'k-', 'LineWidth', 2);
plot([8.7 9.8], [0 0], 'k-', 'LineWidth', 2);
hold off; axis([-1 11 -2 2]); axis off;
title({'Charged State is inherited', 'but the physical graph is NON-CONDUCTING'});

subplot(1, 2, 2); hold on;
plot([0 0], [-1 1], 'b-', 'LineWidth', 8);
plot([10 10], [-1 1], 'Color', [1 .5 .1], 'LineWidth', 8);
x = [2 4 6 8]; labels = {'A1-1','A2','A3','A1-2'};
for index = 1:4, plotNode(x(index), 0, labels{index}, true); end
plot([.2 1.3], [0 0], 'k-', 'LineWidth', 2);
for index = 1:3
    plot([x(index)+.7 x(index+1)-.7], [0 0], 'k-', 'LineWidth', 2);
end
plot([8.7 9.8], [0 0], 'k-', 'LineWidth', 2);
text(5, -1.1, 'solid line = real finite-cylinder contact edge', ...
    'HorizontalAlignment', 'center');
hold off; axis([-1 11 -2 2]); axis off;
title({'Real Piece-level bridge', 'LEFT -> A1-1 -> A2 -> A3 -> A1-2 -> RIGHT'});

annotation(figureHandle, 'textbox', [0.35 0.01 0.3 0.06], ...
    'String', 'red fill = Charged State; solid line = Conductive Edge', ...
    'EdgeColor', 'none', 'HorizontalAlignment', 'center', 'FontWeight', 'bold');
savePaperFigure(figureHandle, fullfile(figureDir, 'charge_vs_conduction'));
end

function plotNode(x, y, label, charged)
if charged, faceColor = [0.95 .3 .25]; else, faceColor = [1 1 1]; end
plot(x, y, 'o', 'MarkerSize', 24, 'MarkerFaceColor', faceColor, ...
    'MarkerEdgeColor', 'k', 'LineWidth', 1.5);
text(x, y, label, 'HorizontalAlignment', 'center', ...
    'VerticalAlignment', 'middle', 'FontSize', 9);
end

function drawCapsuleVsGJK(analyses, cfg, figureDir)
pieceAStart = analyses{3}.P1(208, :); pieceAEnd = analyses{3}.P2(208, :);
pieceBStart = analyses{3}.P1(225, :); pieceBEnd = analyses{3}.P2(225, :);
axisDistance = segmentSegmentDistance(pieceAStart, pieceAEnd, ...
    pieceBStart, pieceBEnd);
capsuleDistance = max(0, axisDistance - 2 * cfg.mediumARadius);
[exactDistance, closestA, closestB, ~, converged] = gjkCylinderDistance( ...
    pieceAStart, pieceAEnd, cfg.mediumARadius, pieceBStart, pieceBEnd, ...
    cfg.mediumARadius, cfg.gjkTolerance, cfg.gjkMaxIterations);
if ~converged, error('generateQ1Figures:GJKNotConverged', ...
        'Capsule comparison example did not converge.'); end
if ~(capsuleDistance <= cfg.conductionDistance && ...
        exactDistance > cfg.conductionDistance)
    error('generateQ1Figures:NotCapsuleFalsePositive', ...
        'The selected A208/A225 pair is not a capsule false positive.');
end

figureHandle = figure('Visible', 'off', 'Color', 'w', ...
    'Position', [100 100 1300 520]);
subplot(1, 2, 1); hold on;
plot3([pieceAStart(1) pieceAEnd(1)], [pieceAStart(2) pieceAEnd(2)], ...
    [pieceAStart(3) pieceAEnd(3)], 'b-', 'LineWidth', 5);
plot3([pieceBStart(1) pieceBEnd(1)], [pieceBStart(2) pieceBEnd(2)], ...
    [pieceBStart(3) pieceBEnd(3)], 'r-', 'LineWidth', 5);
plot3([closestA(1) closestB(1)], [closestA(2) closestB(2)], ...
    [closestA(3) closestB(3)], 'k--', 'LineWidth', 2);
hold off; axis equal; grid on; view(3);
xlabel('x / nm'); ylabel('y / nm'); zlabel('z / nm');
title('Group3 A208 / A225 finite cylinders');
legend({'A208 axis','A225 axis','GJK closest points'}, 'Location', 'best');

subplot(1, 2, 2);
bar([axisDistance capsuleDistance exactDistance]); hold on;
plot([.5 3.5], [cfg.conductionDistance cfg.conductionDistance], ...
    'k--', 'LineWidth', 1.5); hold off; grid on;
set(gca, 'XTick', 1:3, 'XTickLabel', ...
    {'AxisDistance','CapsuleDistance','ExactDistance'});
ylabel('distance / nm');
title({'Capsule is a false positive', ...
    sprintf('threshold = %.1f nm', cfg.conductionDistance)});
for index = 1:3
    values = [axisDistance capsuleDistance exactDistance];
    text(index, values(index), sprintf(' %.3g', values(index)), ...
        'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom');
end
savePaperFigure(figureHandle, fullfile(figureDir, 'capsule_vs_gjk_example'));
end

function drawReconstructionStatus(groupStats, figureDir)
counts = zeros(3, 3);
for groupIndex = 1:3
    counts(groupIndex, :) = [groupStats(groupIndex).Unique ...
        groupStats(groupIndex).Ambiguous groupStats(groupIndex).Unresolved];
end
figureHandle = figure('Visible', 'off', 'Color', 'w');
bar(counts, 'stacked'); grid on;
set(gca, 'XTick', 1:3, 'XTickLabel', {'Group1','Group2','Group3'});
ylabel('Medium count');
legend({'Unique','Ambiguous','Unresolved'}, 'Location', 'NorthWest');
title('Unified reconstruction status');
savePaperFigure(figureHandle, fullfile(figureDir, 'reconstruction_status'));
end

function drawPieceNetwork(groupIndex, pieces, graph, stats, cfg, figureDir)
figureHandle = figure('Visible', 'off', 'Color', 'w'); hold on;
drawElectrodes(cfg.HALF_L);
for pieceIndex = 1:numel(pieces.MediumID)
    if any(graph.PathPieces == pieceIndex), color = [.85 .05 .05]; width = 2.4;
    else, color = [.72 .72 .72]; width = .6; end
    plot3([pieces.PieceStart(pieceIndex, 1) pieces.PieceEnd(pieceIndex, 1)], ...
        [pieces.PieceStart(pieceIndex, 2) pieces.PieceEnd(pieceIndex, 2)], ...
        [pieces.PieceStart(pieceIndex, 3) pieces.PieceEnd(pieceIndex, 3)], ...
        '-', 'Color', color, 'LineWidth', width);
end
hold off; axis equal; grid on; view(3);
axis([-cfg.HALF_L cfg.HALF_L -cfg.HALF_L cfg.HALF_L ...
    -cfg.HALF_L cfg.HALF_L]);
xlabel('x / nm'); ylabel('y / nm'); zlabel('z / nm');
title({sprintf('Group %d | DIAGNOSTIC / %s', groupIndex, stats.Q1Status), ...
    sprintf('Only %d uniquely reconstructed Mediums are shown', stats.Unique)});
savePaperFigure(figureHandle, fullfile(figureDir, ...
    sprintf('q1_group%d_piece_network', groupIndex)));
end

function drawBox(halfLength)
v = halfLength * [-1 -1 -1;1 -1 -1;1 1 -1;-1 1 -1; ...
    -1 -1 1;1 -1 1;1 1 1;-1 1 1];
e = [1 2;2 3;3 4;4 1;5 6;6 7;7 8;8 5;1 5;2 6;3 7;4 8];
for index = 1:size(e, 1)
    plot3(v(e(index, :), 1), v(e(index, :), 2), v(e(index, :), 3), ...
        '-', 'Color', [.7 .7 .7], 'HandleVisibility', 'off');
end
end

function drawElectrodes(halfLength)
values = [-halfLength halfLength]; [y,z] = meshgrid(values, values);
surface(-halfLength * ones(2), y, z, 'FaceColor', [.2 .4 .9], ...
    'FaceAlpha', .18, 'EdgeColor', 'none');
surface(halfLength * ones(2), y, z, 'FaceColor', [1 .5 .1], ...
    'FaceAlpha', .18, 'EdgeColor', 'none');
end

function savePaperFigure(figureHandle, basePath)
print(figureHandle, [basePath '.png'], '-dpng', '-r300');
savefig(figureHandle, [basePath '.fig']);
close(figureHandle);
end

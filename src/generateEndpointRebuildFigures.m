function generateEndpointRebuildFigures(piecesByGroup, groupStats, cfg, ...
        figureDir, endpointComplete, graphs)
%GENERATEENDPOINTREBUILDFIGURES R2016a paper figures for endpoint rebuild.

drawMultiAxisRecovery(cfg, figureDir);
drawBoundaryExamples(cfg, figureDir);
drawChargeVsConduction(figureDir);
drawEndpointStatus(groupStats, figureDir);
drawCapsuleVsGJK(cfg, figureDir);
if endpointComplete
    for groupIndex = 1:3
        drawFinalNetwork(groupIndex, piecesByGroup{groupIndex}, ...
            graphs{groupIndex}, groupStats(groupIndex), cfg, figureDir);
    end
end
end

function drawMultiAxisRecovery(cfg, figureDir)
p1Wrapped = [-3000 0 -3000];
p2Wrapped = [3000 0 4000];
k = [-1 0 -1];
p2Unwrapped = p2Wrapped + cfg.L * k;
direction = p2Unwrapped - p1Wrapped;
tX = (-5000 - p1Wrapped(1)) / direction(1);
tZ = (-5000 - p1Wrapped(3)) / direction(3);
c1 = p1Wrapped + tX * direction;
c2 = p1Wrapped + tZ * direction;
wrapped = wrapSegmentToBox(p1Wrapped, p2Unwrapped, ...
    cfg.HALF_L, cfg.L, cfg.geometryTolerance);

figureHandle = figure('Visible', 'off', 'Color', 'w', ...
    'Position', [100 100 1500 620]);
subplot(1, 2, 1); hold on;
plot([p1Wrapped(1) p2Wrapped(1)], [p1Wrapped(3) p2Wrapped(3)], ...
    'o--', 'Color', [.65 .65 .65], 'LineWidth', 1.5);
plot([p1Wrapped(1) p2Unwrapped(1)], [p1Wrapped(3) p2Unwrapped(3)], ...
    'o-', 'Color', [.1 .35 .9], 'LineWidth', 3);
plot(c1(1), c1(3), 'ks', 'MarkerFaceColor', [.95 .7 .1]);
plot(c2(1), c2(3), 'kd', 'MarkerFaceColor', [.2 .8 .5]);
plot([-5000 -5000], [-7500 5000], 'k:');
plot([-7500 5000], [-5000 -5000], 'k:');
text(p1Wrapped(1), p1Wrapped(3), '  X1');
text(p2Wrapped(1), p2Wrapped(3), '  X2 wrapped');
text(p2Unwrapped(1), p2Unwrapped(3), '  X2''');
text(c1(1), c1(3), ' C1: X boundary');
text(c2(1), c2(3), ' C2: Z boundary');
hold off; axis equal; grid on; xlabel('x / nm'); ylabel('z / nm');
title({'XZ endpoint inverse recovery', ...
    'X2''=X2+[-10000,0,-10000], full length=5000 nm'});
legend({'raw wrapped chord','unwrapped Medium','C1','C2'}, ...
    'Location', 'best');

subplot(1, 2, 2); hold on;
colors = lines(3);
for pieceIndex = 1:3
    plot([wrapped.Start(pieceIndex, 1) wrapped.End(pieceIndex, 1)], ...
        [wrapped.Start(pieceIndex, 3) wrapped.End(pieceIndex, 3)], ...
        'o-', 'Color', colors(pieceIndex, :), 'LineWidth', 3);
    midpoint = (wrapped.Start(pieceIndex, :) + wrapped.End(pieceIndex, :)) / 2;
    text(midpoint(1), midpoint(3), sprintf(' P1-%d', pieceIndex));
end
plot([-5000 5000 5000 -5000 -5000], ...
    [-5000 -5000 5000 5000 -5000], 'k-');
hold off; axis equal; grid on; axis([-5500 5500 -5500 5500]);
xlabel('x / nm'); ylabel('z / nm');
title({'Forward boundary result: X then Z', ...
    'C1/C2 are computed intersections, not attachment rows'});
savePaperFigure(figureHandle, fullfile(figureDir, ...
    'endpoint_multi_axis_recovery'));
end

function drawBoundaryExamples(cfg, figureDir)
dz = sqrt(5000^2 - 3000^2 - 3000^2);
starts = {[-2500 0 0], [1000 0 0], [-3000 0 -3000], ...
    [4500 4000 3500]};
ends = {[2500 0 0], [6000 0 0], [-7000 0 -6000], ...
    [7500 7000 3500+dz]};
labels = {'1 Piece','2 Pieces: X','3 Pieces: X then Z', ...
    '4 Pieces: X then Y then Z'};
figureHandle = figure('Visible', 'off', 'Color', 'w', ...
    'Position', [100 100 1600 950]);
colors = lines(4);
for exampleIndex = 1:4
    wrapped = wrapSegmentToBox(starts{exampleIndex}, ends{exampleIndex}, ...
        cfg.HALF_L, cfg.L, cfg.geometryTolerance);
    subplot(2, 2, exampleIndex); hold on; drawBox(cfg.HALF_L);
    for pieceIndex = 1:size(wrapped.Start, 1)
        plot3([wrapped.Start(pieceIndex, 1) wrapped.End(pieceIndex, 1)], ...
            [wrapped.Start(pieceIndex, 2) wrapped.End(pieceIndex, 2)], ...
            [wrapped.Start(pieceIndex, 3) wrapped.End(pieceIndex, 3)], ...
            'o-', 'Color', colors(pieceIndex, :), 'LineWidth', 3);
    end
    hold off; axis equal; grid on; view(3);
    axis([-5000 5000 -5000 5000 -5000 5000]);
    xlabel('x'); ylabel('y'); zlabel('z'); title(labels{exampleIndex});
end
savePaperFigure(figureHandle, fullfile(figureDir, 'boundary_piece_examples'));
end

function drawChargeVsConduction(figureDir)
figureHandle = figure('Visible', 'off', 'Color', 'w', ...
    'Position', [100 100 1400 560]);
subplot(1, 2, 1); hold on;
plot([0 0], [-1 1], 'b-', 'LineWidth', 8);
plot([10 10], [-1 1], 'Color', [1 .5 .1], 'LineWidth', 8);
plotNode(2, 0, 'A1-1'); plotNode(8, 0, 'A1-2');
plot([2.7 7.3], [0 0], ':', 'Color', [.55 .55 .55], 'LineWidth', 2);
text(5, .35, 'same Medium, NO hidden edge', 'HorizontalAlignment', 'center');
hold off; axis([-1 11 -2 2]); axis off;
title({'Charge may be inherited', 'but no physical path exists'});
subplot(1, 2, 2); hold on;
plot([0 0], [-1 1], 'b-', 'LineWidth', 8);
plot([10 10], [-1 1], 'Color', [1 .5 .1], 'LineWidth', 8);
x = [2 4 6 8]; labels = {'A1-1','A2','A3','A1-2'};
for index = 1:4, plotNode(x(index), 0, labels{index}); end
plot([.2 1.3], [0 0], 'k-', 'LineWidth', 2);
for index = 1:3
    plot([x(index)+.7 x(index+1)-.7], [0 0], 'k-', 'LineWidth', 2);
end
plot([8.7 9.8], [0 0], 'k-', 'LineWidth', 2);
hold off; axis([-1 11 -2 2]); axis off;
title({'Conducting requires real GJK edges', ...
    'LEFT -> Piece -> ... -> RIGHT'});
annotation(figureHandle, 'textbox', [0.35 .01 .3 .06], ...
    'String', 'Charged State != Conductive Edge', 'EdgeColor', 'none', ...
    'HorizontalAlignment', 'center', 'FontWeight', 'bold');
savePaperFigure(figureHandle, fullfile(figureDir, 'charge_vs_conduction'));
end

function plotNode(x, y, label)
plot(x, y, 'o', 'MarkerSize', 24, 'MarkerFaceColor', [.95 .3 .25], ...
    'MarkerEdgeColor', 'k', 'LineWidth', 1.5);
text(x, y, label, 'HorizontalAlignment', 'center', ...
    'VerticalAlignment', 'middle', 'FontSize', 9);
end

function drawEndpointStatus(groupStats, figureDir)
counts = zeros(3, 3);
for groupIndex = 1:3
    counts(groupIndex, :) = [groupStats(groupIndex).Unique ...
        groupStats(groupIndex).AmbiguousPeriodic ...
        groupStats(groupIndex).Unresolved];
end
figureHandle = figure('Visible', 'off', 'Color', 'w');
bar(counts, 'stacked'); grid on;
set(gca, 'XTick', 1:3, 'XTickLabel', {'Group1','Group2','Group3'});
ylabel('Medium count');
legend({'UNIQUE','AMBIGUOUS_PERIODIC','UNRESOLVED'}, ...
    'Location', 'NorthWest', 'Interpreter', 'none');
title('Endpoint reconstruction status after 27/729 agreement');
savePaperFigure(figureHandle, fullfile(figureDir, 'endpoint_model_status'));
end

function drawCapsuleVsGJK(cfg, figureDir)
startA = [-100 0 0]; endA = [100 0 0];
startB = [150 0 0]; endB = [350 0 0];
axisDistance = segmentSegmentDistance(startA, endA, startB, endB);
capsuleDistance = max(0, axisDistance - 2*cfg.mediumARadius);
[exactDistance, closestA, closestB, ~, converged] = ...
    gjkCylinderDistance(startA, endA, cfg.mediumARadius, startB, endB, ...
    cfg.mediumARadius, cfg.gjkTolerance, cfg.gjkMaxIterations);
assert(converged && capsuleDistance <= cfg.conductionDistance && ...
    exactDistance > cfg.conductionDistance);
figureHandle = figure('Visible', 'off', 'Color', 'w', ...
    'Position', [100 100 1300 520]);
subplot(1, 2, 1); hold on;
plot3([startA(1) endA(1)], [0 0], [0 0], 'b-', 'LineWidth', 5);
plot3([startB(1) endB(1)], [0 0], [0 0], 'r-', 'LineWidth', 5);
plot3([closestA(1) closestB(1)], [closestA(2) closestB(2)], ...
    [closestA(3) closestB(3)], 'k--', 'LineWidth', 2);
hold off; axis equal; grid on; view(3); title('Synthetic flat-end validation');
xlabel('x / nm'); ylabel('y / nm'); zlabel('z / nm');
subplot(1, 2, 2);
values = [axisDistance capsuleDistance exactDistance]; bar(values); hold on;
plot([.5 3.5], [cfg.conductionDistance cfg.conductionDistance], 'k--');
hold off; grid on; ylim([0 55]);
set(gca, 'XTick', 1:3, 'XTickLabel', ...
    {'AxisDistance','CapsuleDistance','ExactDistance'});
ylabel('distance / nm'); title('Capsule false positive; GJK is final');
savePaperFigure(figureHandle, fullfile(figureDir, 'capsule_vs_gjk'));
end

function drawFinalNetwork(groupIndex, pieces, graph, stats, cfg, figureDir)
figureHandle = figure('Visible', 'off', 'Color', 'w'); hold on;
for pieceIndex = 1:numel(pieces.MediumID)
    if any(graph.PathPieces == pieceIndex)
        color = [.85 .05 .05]; width = 2.4;
    else
        color = [.72 .72 .72]; width = .6;
    end
    plot3([pieces.PieceStart(pieceIndex, 1) pieces.PieceEnd(pieceIndex, 1)], ...
        [pieces.PieceStart(pieceIndex, 2) pieces.PieceEnd(pieceIndex, 2)], ...
        [pieces.PieceStart(pieceIndex, 3) pieces.PieceEnd(pieceIndex, 3)], ...
        '-', 'Color', color, 'LineWidth', width);
end
hold off; axis equal; grid on; view(3);
axis([-cfg.HALF_L cfg.HALF_L -cfg.HALF_L cfg.HALF_L ...
    -cfg.HALF_L cfg.HALF_L]);
title(sprintf('Group %d FINAL | Conducting=%d', groupIndex, stats.Conducting));
savePaperFigure(figureHandle, fullfile(figureDir, ...
    sprintf('q1_group%d_final_network', groupIndex)));
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

function savePaperFigure(figureHandle, basePath)
print(figureHandle, [basePath '.png'], '-dpng', '-r300');
savefig(figureHandle, [basePath '.fig']);
close(figureHandle);
end

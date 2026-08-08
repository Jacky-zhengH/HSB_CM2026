function generateRetainedPartFigures(groups, resultsByGroup, piecesByGroup, ...
        graphs, groupStats, cfg, figureDir, modelComplete)
%GENERATERETAINEDPARTFIGURES R2016a-compatible retained-model figures.

drawInversePrinciple(cfg, figureDir);
drawRealExamples(groups, resultsByGroup, cfg, figureDir);
drawStatus(groupStats, figureDir);
drawPieceCounts(groupStats, figureDir);
drawChargeVsConduction(figureDir);
for groupIndex = 1:3
    if graphs{groupIndex}.Conducting
        drawNetwork(groupIndex, piecesByGroup{groupIndex}, ...
            graphs{groupIndex}, cfg, figureDir, modelComplete);
    end
end
end

function drawInversePrinciple(cfg, figureDir)
item = reconstructFromRetainedPart([1000 0 0], [5000 0 0], cfg);
figureHandle = figure('Visible', 'off', 'Color', 'w', ...
    'Position', [100 100 1450 560]);
subplot(1, 2, 1); hold on;
plot([1000 6000], [0 0], 'k--', 'LineWidth', 2);
plot([1000 5000], [0 0], 'b-', 'LineWidth', 6);
plot([5000 6000], [0 0], 'r-', 'LineWidth', 6);
plot([5000 5000], [-1 1], 'k:', 'LineWidth', 2);
text(1000, .22, 'A / Interior');
text(4900, .30, 'C / Boundary Point', 'HorizontalAlignment', 'right');
text(6100, .22, 'B', 'HorizontalAlignment', 'left');
text(3000, -.25, 'Observed retained part', 'HorizontalAlignment', 'center');
text(5500, -.25, 'Recovered missing part', 'HorizontalAlignment', 'center');
hold off; axis([500 6800 -1 1]); axis off;
title({'Inverse principle: Lmiss = 5000 - Lobs', ...
    'all missing length continues beyond C'});

subplot(1, 2, 2); hold on;
colors = lines(item.ForwardPieceCount);
for pieceIndex = 1:item.ForwardPieceCount
    plot([item.ForwardPieces.Start(pieceIndex, 1) ...
        item.ForwardPieces.End(pieceIndex, 1)], [0 0], 'o-', ...
        'Color', colors(pieceIndex, :), 'LineWidth', 6);
end
plot([-5000 -5000], [-1 1], 'k:', 'LineWidth', 2);
plot([5000 5000], [-1 1], 'k:', 'LineWidth', 2);
text(2400, -.3, 'Observed / Translation=[0,0,0]', ...
    'HorizontalAlignment', 'center');
text(-4500, .3, 'Forward wrapped piece', 'HorizontalAlignment', 'center');
hold off; axis([-5500 5500 -1 1]); axis off;
title('Forward replay reproduces the observed zero-translation Piece');
savePaperFigure(figureHandle, fullfile(figureDir, ...
    'retained_part_inverse_principle'));
end

function drawRealExamples(groups, resultsByGroup, cfg, figureDir)
figureHandle = figure('Visible', 'off', 'Color', 'w', ...
    'Position', [100 100 1600 600]);
for groupIndex = 1:3
    selected = firstRecovered(resultsByGroup{groupIndex});
    subplot(1, 3, groupIndex); hold on; drawBox(cfg.HALF_L);
    if selected > 0
        item = resultsByGroup{groupIndex}{selected};
        plot3([item.ReconstructedOriginalStart(1) item.ReconstructedOriginalEnd(1)], ...
            [item.ReconstructedOriginalStart(2) item.ReconstructedOriginalEnd(2)], ...
            [item.ReconstructedOriginalStart(3) item.ReconstructedOriginalEnd(3)], ...
            'r--', 'LineWidth', 2);
        plot3([groups(groupIndex).P1(selected, 1) groups(groupIndex).P2(selected, 1)], ...
            [groups(groupIndex).P1(selected, 2) groups(groupIndex).P2(selected, 2)], ...
            [groups(groupIndex).P1(selected, 3) groups(groupIndex).P2(selected, 3)], ...
            'b-', 'LineWidth', 5);
        colors = lines(item.ForwardPieceCount);
        for pieceIndex = 1:item.ForwardPieceCount
            plot3([item.ForwardPieces.Start(pieceIndex, 1) ...
                item.ForwardPieces.End(pieceIndex, 1)], ...
                [item.ForwardPieces.Start(pieceIndex, 2) ...
                item.ForwardPieces.End(pieceIndex, 2)], ...
                [item.ForwardPieces.Start(pieceIndex, 3) ...
                item.ForwardPieces.End(pieceIndex, 3)], 'o-', ...
                'Color', colors(pieceIndex, :), 'LineWidth', 2);
        end
        title({sprintf('Group%d A%d / Excel row %d', groupIndex, selected, ...
            groups(groupIndex).OriginalExcelRow(selected)), ...
            sprintf('Lobs=%.3f, Lmiss=%.3f nm', item.RawLength, item.MissingLength)});
    else
        title(sprintf('Group%d: no recovered example', groupIndex));
    end
    hold off; axis equal; grid on; view(3);
    axis([-cfg.HALF_L cfg.HALF_L -cfg.HALF_L cfg.HALF_L ...
        -cfg.HALF_L cfg.HALF_L]);
    xlabel('x'); ylabel('y'); zlabel('z');
end
annotation(figureHandle, 'textbox', [0.2 .01 .6 .05], ...
    'String', 'blue=Observed, red dashed=Recovered Original, colored=Forward Pieces', ...
    'EdgeColor', 'none', 'HorizontalAlignment', 'center');
savePaperFigure(figureHandle, fullfile(figureDir, ...
    'single_boundary_real_examples'));
end

function drawStatus(stats, figureDir)
counts = zeros(3, 5);
for groupIndex = 1:3
    counts(groupIndex, :) = [stats(groupIndex).Direct ...
        stats(groupIndex).SingleBoundaryRecovered ...
        stats(groupIndex).TwoBoundaryShort stats(groupIndex).NoBoundaryShort ...
        stats(groupIndex).ReplayFailed];
end
figureHandle = figure('Visible', 'off', 'Color', 'w', ...
    'Position', [100 100 1050 650]);
bar(counts, 'stacked'); grid on;
set(gca, 'XTick', 1:3, 'XTickLabel', {'Group1','Group2','Group3'});
ylabel('Excel-row Medium count');
legend({'Direct','SingleBoundaryRecovered','TwoBoundaryAmbiguous', ...
    'NoBoundaryUnresolved','ReplayFailed'}, 'Location', 'NorthWest');
title('Retained-original-part hypothesis status');
savePaperFigure(figureHandle, fullfile(figureDir, 'retained_model_status'));
end

function drawPieceCounts(stats, figureDir)
counts = zeros(3, 4);
for groupIndex = 1:3
    counts(groupIndex, :) = stats(groupIndex).PieceCountByMedium;
end
figureHandle = figure('Visible', 'off', 'Color', 'w', ...
    'Position', [100 100 1000 620]);
bar(counts); grid on;
set(gca, 'XTick', 1:3, 'XTickLabel', {'Group1','Group2','Group3'});
ylabel('Uniquely reconstructed Medium count');
legend({'1 Piece','2 Pieces','3 Pieces','4 Pieces'}, 'Location', 'NorthWest');
title('Forward Piece-count distribution (unique reconstructions only)');
savePaperFigure(figureHandle, fullfile(figureDir, 'piece_count_distribution'));
end

function drawChargeVsConduction(figureDir)
figureHandle = figure('Visible', 'off', 'Color', 'w', ...
    'Position', [100 100 1450 560]);
subplot(1, 2, 1); hold on;
plot([0 0], [-1 1], 'b-', 'LineWidth', 8);
plot([10 10], [-1 1], 'Color', [1 .5 .1], 'LineWidth', 8);
plotNode(2, 'A1-1'); plotNode(8, 'A1-2');
plot([2.7 7.3], [0 0], ':', 'Color', [.5 .5 .5], 'LineWidth', 2);
text(5, .35, 'same Medium: charge inheritance only', ...
    'HorizontalAlignment', 'center');
hold off; axis([-1 11 -2 2]); axis off;
title({'Charged does not imply Connected', 'no hidden same-Medium edge'});
subplot(1, 2, 2); hold on;
plot([0 0], [-1 1], 'b-', 'LineWidth', 8);
plot([10 10], [-1 1], 'Color', [1 .5 .1], 'LineWidth', 8);
x = [2 4 6 8]; labels = {'A1-1','A2','A3','A1-2'};
for index = 1:4, plotNode(x(index), labels{index}); end
plot([.2 1.3], [0 0], 'k-', 'LineWidth', 2);
for index = 1:3
    plot([x(index)+.7 x(index+1)-.7], [0 0], 'k-', 'LineWidth', 2);
end
plot([8.7 9.8], [0 0], 'k-', 'LineWidth', 2);
hold off; axis([-1 11 -2 2]); axis off;
title({'Conducting requires finite-cylinder edges', 'LEFT -> Piece -> ... -> RIGHT'});
savePaperFigure(figureHandle, fullfile(figureDir, 'charge_vs_conduction'));
end

function drawNetwork(groupIndex, pieces, graph, cfg, figureDir, modelComplete)
figureHandle = figure('Visible', 'off', 'Color', 'w'); hold on;
for pieceIndex = 1:numel(pieces.MediumID)
    if any(graph.PathPieces == pieceIndex)
        color = [.85 .05 .05];
        width = 2.5;
    else
        color = [.75 .75 .75];
        width = .5;
    end
    plot3([pieces.PieceStart(pieceIndex, 1) pieces.PieceEnd(pieceIndex, 1)], ...
        [pieces.PieceStart(pieceIndex, 2) pieces.PieceEnd(pieceIndex, 2)], ...
        [pieces.PieceStart(pieceIndex, 3) pieces.PieceEnd(pieceIndex, 3)], ...
        '-', 'Color', color, 'LineWidth', width);
end
hold off; axis equal; grid on; view(3);
axis([-cfg.HALF_L cfg.HALF_L -cfg.HALF_L cfg.HALF_L ...
    -cfg.HALF_L cfg.HALF_L]);
if modelComplete
    scope = 'Full Reconstruction Graph';
else
    scope = 'Unique-Reconstruction Lower-Bound Graph';
end
title({sprintf('Group%d %s', groupIndex, scope), graph.BFSPath}, ...
    'Interpreter', 'none');
savePaperFigure(figureHandle, fullfile(figureDir, ...
    sprintf('q1_group%d_unique_subset_network', groupIndex)));
end

function selected = firstRecovered(results)
selected = 0;
for index = 1:numel(results)
    if strcmp(results{index}.Status, 'RETAINED_SINGLE_BOUNDARY_UNIQUE')
        selected = index;
        return;
    end
end
end

function plotNode(x, label)
plot(x, 0, 'o', 'MarkerSize', 24, 'MarkerFaceColor', [.95 .3 .25], ...
    'MarkerEdgeColor', 'k', 'LineWidth', 1.5);
text(x, 0, label, 'HorizontalAlignment', 'center', ...
    'VerticalAlignment', 'middle', 'FontSize', 9);
end

function drawBox(halfLength)
v = halfLength * [-1 -1 -1;1 -1 -1;1 1 -1;-1 1 -1; ...
    -1 -1 1;1 -1 1;1 1 1;-1 1 1];
e = [1 2;2 3;3 4;4 1;5 6;6 7;7 8;8 5;1 5;2 6;3 7;4 8];
for index = 1:size(e, 1)
    plot3(v(e(index, :), 1), v(e(index, :), 2), v(e(index, :), 3), ...
        '-', 'Color', [.75 .75 .75], 'HandleVisibility', 'off');
end
end

function savePaperFigure(figureHandle, basePath)
print(figureHandle, [basePath '.png'], '-dpng', '-r300');
savefig(figureHandle, [basePath '.fig']);
close(figureHandle);
end

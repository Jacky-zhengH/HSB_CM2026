function output = generateOnePaperFigure(paperState, figureID, figureDir, paperFont)
%GENERATEONEPAPERFIGURE Safely create exactly one Q1 paper PNG.

names = {'retained_part_inverse_principle', ...
    'single_boundary_real_examples', 'retained_model_status', ...
    'piece_count_distribution', 'charge_vs_conduction', ...
    'group1_upper_bound_certificate', 'q1_group1_3d', ...
    'q1_group2_3d', 'q1_group3_3d', 'q1_three_groups_overview'};
if figureID < 1 || figureID > numel(names) || figureID ~= floor(figureID)
    error('generateOnePaperFigure:InvalidID', 'Figure ID must be 1 through 10.');
end
if exist(figureDir, 'dir') ~= 7, mkdir(figureDir); end
set(0, 'DefaultAxesFontName', paperFont);
set(0, 'DefaultTextFontName', paperFont);
set(0, 'DefaultUicontrolFontName', paperFont);

switch figureID
    case 1
        fig = makeInverseFigure(paperState.cfg);
    case 2
        fig = makeRealExamplesFigure(paperState);
    case 3
        fig = makeStatusFigure(paperState.groupStats);
    case 4
        fig = makePieceCountFigure(paperState.groupStats);
    case 5
        fig = makeChargeFigure();
    case 6
        fig = makeUpperCertificateFigure(paperState);
    case 7
        fig = makeGroupFigure(1, paperState);
    case 8
        fig = makeGroupFigure(2, paperState);
    case 9
        fig = makeGroupFigure(3, paperState);
    otherwise
        fig = makeOverviewFigure(paperState);
end
cleanup = onCleanup(@() closeIfValid(fig));
set(fig, 'Renderer', 'opengl', 'PaperPositionMode', 'auto');
fontObjects = findall(fig, '-property', 'FontName');
set(fontObjects, 'FontName', paperFont);
drawnow;
path = fullfile(figureDir, [names{figureID} '.png']);
print(fig, path, '-dpng', '-r200');
if exist(path, 'file') ~= 2
    error('generateOnePaperFigure:MissingPNG', 'PNG was not created: %s.', path);
end
info = dir(path);
if info.bytes <= 10000
    error('generateOnePaperFigure:SmallPNG', ...
        'PNG is unexpectedly small (%d bytes): %s.', info.bytes, path);
end
close(fig);
clear cleanup;
drawnow;
output.Name = names{figureID};
output.Path = path;
output.FileSizeBytes = info.bytes;
end

function fig = makeInverseFigure(cfg)
item = reconstructFromRetainedPart([1000 0 0], [5000 0 0], cfg);
fig = figure('Visible', 'off', 'Color', 'w', 'Position', [100 100 1200 650]);
leftAxes = subplot(1, 2, 1);
set(leftAxes, 'Position', [.05 .12 .42 .68]);
hold on;
plot([1000 6000], [0 0], 'k--', 'LineWidth', 2);
plot([1000 5000], [0 0], 'b-', 'LineWidth', 6);
plot([5000 6000], [0 0], 'r-', 'LineWidth', 6);
plot([5000 5000], [-1 1], 'k:', 'LineWidth', 2);
text(1000, .22, paperText('interior'));
text(4900, .30, paperText('boundary'), 'HorizontalAlignment', 'right');
text(6100, .22, paperText('recovered_endpoint'));
text(3000, -.25, paperText('observed'), 'HorizontalAlignment', 'center');
text(5500, -.25, paperText('recovered_missing'), 'HorizontalAlignment', 'center');
hold off; axis([500 6900 -1 1]); axis off;
title({paperText('inverse_left_title'), paperText('inverse_left_sub')});
rightAxes = subplot(1, 2, 2);
set(rightAxes, 'Position', [.54 .12 .42 .68]);
hold on;
colors = lines(item.ForwardPieceCount);
for pieceIndex = 1:item.ForwardPieceCount
    plot([item.ForwardPieces.Start(pieceIndex, 1) ...
        item.ForwardPieces.End(pieceIndex, 1)], [0 0], 'o-', ...
        'Color', colors(pieceIndex, :), 'LineWidth', 6);
end
plot([-5000 -5000], [-1 1], 'k:', 'LineWidth', 2);
plot([5000 5000], [-1 1], 'k:', 'LineWidth', 2);
text(2400, -.3, paperText('zero_translation'), 'HorizontalAlignment', 'center');
text(-4400, .3, paperText('wrapped_piece'), 'HorizontalAlignment', 'center');
hold off; axis([-5500 5500 -1 1]); axis off;
title(paperText('forward_replay'));
annotation(fig, 'textbox', [0.25 .93 .5 .055], 'String', ...
    paperText('inverse_title'), 'EdgeColor', 'none', ...
    'HorizontalAlignment', 'center', 'FontSize', 16, 'FontWeight', 'bold');
end

function fig = makeRealExamplesFigure(state)
fig = figure('Visible', 'off', 'Color', 'w', 'Position', [60 100 1400 750]);
for groupIndex = 1:3
    selected = firstRecovered(state.resultsByGroup{groupIndex});
    subplot(1, 3, groupIndex); hold on; drawBox(state.cfg.HALF_L);
    item = state.resultsByGroup{groupIndex}{selected};
    plotBatch(item.ReconstructedOriginalStart, item.ReconstructedOriginalEnd, ...
        [.9 0 0], '--', 3);
    plotBatch(item.ForwardPieces.Start, item.ForwardPieces.End, [.15 .6 .2], '-', 2);
    plotBatch(state.groups(groupIndex).P1(selected, :), ...
        state.groups(groupIndex).P2(selected, :), [0 .25 .95], '-', 5);
    hold off; format3DAxes(state.cfg);
    title({sprintf(paperText('real_group_fmt'), groupIndex, selected, ...
        state.groups(groupIndex).OriginalExcelRow(selected)), ...
        sprintf(paperText('real_lengths_fmt'), item.RawLength, item.MissingLength)});
end
annotation(fig, 'textbox', [0.22 .93 .56 .055], 'String', ...
    paperText('real_title'), 'EdgeColor', 'none', ...
    'HorizontalAlignment', 'center', 'FontSize', 16, 'FontWeight', 'bold');
annotation(fig, 'textbox', [0.15 .01 .7 .045], 'String', ...
    paperText('real_legend'), 'EdgeColor', 'none', 'HorizontalAlignment', 'center');
end

function fig = makeStatusFigure(stats)
counts = zeros(3, 5);
for groupIndex = 1:3
    counts(groupIndex, :) = [stats(groupIndex).Direct ...
        stats(groupIndex).SingleBoundaryRecovered ...
        stats(groupIndex).TwoBoundaryShort stats(groupIndex).NoBoundaryShort ...
        stats(groupIndex).ReplayFailed];
end
fig = figure('Visible', 'off', 'Color', 'w', 'Position', [100 100 1050 650]);
bar(counts, 'stacked'); grid on;
set(gca, 'XTick', 1:3, 'XTickLabel', {paperText('structure1'), ...
    paperText('structure2'), paperText('structure3')});
ylabel(paperText('medium_count'));
legend({paperText('direct'), paperText('single'), paperText('two_amb'), ...
    paperText('no_boundary'), paperText('replay_fail')}, 'Location', 'NorthWest');
title(paperText('status_title'));
end

function fig = makePieceCountFigure(stats)
counts = zeros(3, 4);
for groupIndex = 1:3, counts(groupIndex, :) = stats(groupIndex).PieceCountByMedium; end
fig = figure('Visible', 'off', 'Color', 'w', 'Position', [100 100 1000 650]);
bar(counts); grid on;
set(gca, 'XTick', 1:3, 'XTickLabel', {paperText('structure1'), ...
    paperText('structure2'), paperText('structure3')});
ylabel(paperText('unique_count'));
legend({paperText('one_piece'), paperText('two_piece'), ...
    paperText('three_piece'), paperText('four_piece')}, 'Location', 'NorthWest');
title(paperText('piece_title'));
end

function fig = makeChargeFigure()
fig = figure('Visible', 'off', 'Color', 'w', 'Position', [100 100 1200 650]);
subplot(1, 2, 1); hold on; drawElectrodeCartoon();
plotNode(2, 'A1-1'); plotNode(8, 'A1-2');
plot([2.7 7.3], [0 0], ':', 'Color', [.5 .5 .5], 'LineWidth', 2);
text(5, .35, paperText('charge_only'), 'HorizontalAlignment', 'center');
hold off; axis([-1 11 -2 2]); axis off;
title({paperText('charged_not_connected'), paperText('no_hidden')});
subplot(1, 2, 2); hold on; drawElectrodeCartoon();
x = [2 4 6 8]; labels = {'A1-1','A2','A3','A1-2'};
for index = 1:4, plotNode(x(index), labels{index}); end
plot([.2 1.3], [0 0], 'k-', 'LineWidth', 2);
for index = 1:3, plot([x(index)+.7 x(index+1)-.7], [0 0], 'k-', 'LineWidth', 2); end
plot([8.7 9.8], [0 0], 'k-', 'LineWidth', 2);
hold off; axis([-1 11 -2 2]); axis off;
title({paperText('real_edges'), paperText('path_desc')});
annotation(fig, 'textbox', [0.25 .93 .5 .055], 'String', paperText('charge_title'), ...
    'EdgeColor', 'none', 'HorizontalAlignment', 'center', ...
    'FontSize', 16, 'FontWeight', 'bold');
end

function fig = makeUpperCertificateFigure(state)
fig = figure('Visible', 'off', 'Color', 'w', 'Position', [100 100 1200 780]);
hold on; drawBox(state.cfg.HALF_L); drawElectrodes(state.cfg.HALF_L);
known = state.piecesByGroup{1}; upper = state.upper;
plotBatch(known.PieceStart, known.PieceEnd, [.72 .72 .72], '-', 1.1);
observedStart = vertcat(upper.Envelopes.ObservedP1);
observedEnd = vertcat(upper.Envelopes.ObservedP2);
envelopeStart = vertcat(upper.Envelopes.EnvelopeStart);
envelopeEnd = vertcat(upper.Envelopes.EnvelopeEnd);
plotBatch(observedStart, observedEnd, [0 0 0], '-', 4);
plotBatch(envelopeStart, envelopeEnd, [.75 0 .75], '--', 3);
for index = 1:numel(upper.Envelopes)
    midpoint = (observedStart(index, :) + observedEnd(index, :)) / 2;
    text(midpoint(1), midpoint(2), midpoint(3), ...
        sprintf(paperText('observed_fmt'), upper.Envelopes(index).MediumID));
end
highlightPair(upper.Pieces, upper.MinEnvelopeToKnownPair, [0 .6 .2]);
highlightPair(upper.Pieces, upper.MinEnvelopeToEnvelopePair, [.9 .55 0]);
hold off; axis equal; grid on; view(3); axis([-7000 7000 -7000 7000 -7000 7000]);
axisLabels();
title({paperText('upper_title'), paperText('upper_sub')});
certificateText = sprintf(paperText('cert_fmt'), ...
    upper.MinEnvelopeToKnownAxisDistance, ...
    upper.MinEnvelopeToEnvelopeAxisDistance, state.cfg.broadPhaseDistance);
annotation(fig, 'textbox', [0.61 .64 .35 .22], 'String', certificateText, ...
    'BackgroundColor', 'w', 'EdgeColor', [.3 .3 .3]);
annotation(fig, 'textbox', [0.12 .02 .76 .055], 'String', paperText('cert_note'), ...
    'EdgeColor', 'none', 'HorizontalAlignment', 'center', 'FontWeight', 'bold');
end

function fig = makeGroupFigure(groupIndex, state)
fig = figure('Visible', 'off', 'Color', 'w', 'Position', [100 100 1050 780]);
axesHandle = axes('Parent', fig);
if groupIndex == 1
    drawGroupOneAxes(axesHandle, state.upper, state.cfg);
    title(axesHandle, {paperText('g1_title'), paperText('g1_sub')});
    annotation(fig, 'textbox', [0.10 .01 .8 .045], 'String', paperText('g1_legend'), ...
        'EdgeColor', 'none', 'HorizontalAlignment', 'center');
else
    pieces = state.piecesByGroup{groupIndex}; graph = state.graphs{groupIndex};
    drawConductingAxes(axesHandle, pieces, graph, state.cfg);
    if groupIndex == 2
        titleText = paperText('g2_title');
    else
        titleText = paperText('g3_title');
    end
    title(axesHandle, {titleText, graph.BFSPath}, 'Interpreter', 'none');
    labelPathMedia(axesHandle, pieces, graph.PathPieces);
    annotation(fig, 'textbox', [0.12 .01 .76 .045], ...
        'String', paperText('conducting_legend'), 'EdgeColor', 'none', ...
        'HorizontalAlignment', 'center');
end
end

function fig = makeOverviewFigure(state)
fig = figure('Visible', 'off', 'Color', 'w', 'Position', [20 100 1400 650]);
for groupIndex = 1:3
    axesHandle = subplot(1, 3, groupIndex);
    if groupIndex == 1
        drawGroupOneAxes(axesHandle, state.upper, state.cfg);
        title(axesHandle, paperText('overview_a'));
    else
        drawConductingAxes(axesHandle, state.piecesByGroup{groupIndex}, ...
            state.graphs{groupIndex}, state.cfg);
        if groupIndex == 2
            title(axesHandle, paperText('overview_b'));
        else
            title(axesHandle, paperText('overview_c'));
        end
    end
end
annotation(fig, 'textbox', [0.27 .93 .46 .055], 'String', ...
    paperText('overview_title'), 'EdgeColor', 'none', ...
    'HorizontalAlignment', 'center', 'FontSize', 17, 'FontWeight', 'bold');
end

function drawGroupOneAxes(axesHandle, upper, cfg)
axes(axesHandle); hold on; drawBox(cfg.HALF_L); drawElectrodes(cfg.HALF_L);
count = numel(upper.Pieces.MediumID);
envelope = upper.Pieces.IsEnvelope;
left = false(count, 1); left(upper.LeftReachablePieces) = true;
right = false(count, 1); right(upper.RightReachablePieces) = true;
left = left & ~envelope;
right = right & ~envelope & ~left;
other = ~envelope & ~left & ~right;
plotMask(upper.Pieces, other, [.72 .72 .72], '-', .9);
plotMask(upper.Pieces, left, [0 .35 .9], '-', 2);
plotMask(upper.Pieces, right, [1 .45 0], '-', 2);
plotMask(upper.Pieces, envelope, [.75 0 .75], '--', 2.5);
hold off; format3DAxes(cfg);
end

function drawConductingAxes(axesHandle, pieces, graph, cfg)
axes(axesHandle); hold on; drawBox(cfg.HALF_L); drawElectrodes(cfg.HALF_L);
count = numel(pieces.MediumID);
pathMask = false(count, 1); pathMask(graph.PathPieces) = true;
plotMask(pieces, ~pathMask, [.73 .73 .73], '-', .65);
plotMask(pieces, pathMask, [.9 0 0], '-', 3.2);
hold off; format3DAxes(cfg);
end

function plotMask(pieces, mask, color, style, width)
if ~any(mask), return; end
plotBatch(pieces.PieceStart(mask, :), pieces.PieceEnd(mask, :), ...
    color, style, width);
end

function plotBatch(starts, ends, color, style, width)
[x, y, z] = buildNaNSeparatedPolyline(starts, ends);
plot3(x, y, z, style, 'Color', color, 'LineWidth', width);
end

function labelPathMedia(axesHandle, pieces, pathPieces)
mediumIDs = unique(pieces.MediumID(pathPieces), 'stable');
for index = 1:numel(mediumIDs)
    pieceIndex = pathPieces(find(pieces.MediumID(pathPieces) == mediumIDs(index), 1));
    midpoint = (pieces.PieceStart(pieceIndex, :) + pieces.PieceEnd(pieceIndex, :)) / 2;
    text(axesHandle, midpoint(1), midpoint(2), midpoint(3), ...
        sprintf('A%d', mediumIDs(index)), 'FontWeight', 'bold');
end
end

function highlightPair(pieces, pair, color)
if any(pair == 0), return; end
plotBatch(pieces.PieceStart(pair, :), pieces.PieceEnd(pair, :), color, '-', 5);
end

function drawBox(halfLength)
v = halfLength * [-1 -1 -1;1 -1 -1;1 1 -1;-1 1 -1; ...
    -1 -1 1;1 -1 1;1 1 1;-1 1 1];
e = [1 2;2 3;3 4;4 1;5 6;6 7;7 8;8 5;1 5;2 6;3 7;4 8];
plotBatch(v(e(:, 1), :), v(e(:, 2), :), [.62 .62 .62], '-', .55);
end

function drawElectrodes(halfLength)
verticesLeft = [-halfLength -halfLength -halfLength; ...
    -halfLength halfLength -halfLength; -halfLength halfLength halfLength; ...
    -halfLength -halfLength halfLength];
verticesRight = verticesLeft; verticesRight(:, 1) = halfLength;
patch('Vertices', verticesLeft, 'Faces', [1 2 3 4], ...
    'FaceColor', [.25 .55 1], 'FaceAlpha', .10, 'EdgeColor', 'none');
patch('Vertices', verticesRight, 'Faces', [1 2 3 4], ...
    'FaceColor', [1 .55 .15], 'FaceAlpha', .10, 'EdgeColor', 'none');
end

function format3DAxes(cfg)
axis equal; grid on; view(3);
axis([-cfg.HALF_L cfg.HALF_L -cfg.HALF_L cfg.HALF_L ...
    -cfg.HALF_L cfg.HALF_L]);
axisLabels();
end

function axisLabels()
unit = paperText('nanometer');
xlabel(['x / ' unit]); ylabel(['y / ' unit]); zlabel(['z / ' unit]);
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

function drawElectrodeCartoon()
plot([0 0], [-1 1], 'b-', 'LineWidth', 8);
plot([10 10], [-1 1], 'Color', [1 .5 .1], 'LineWidth', 8);
end

function plotNode(x, label)
plot(x, 0, 'o', 'MarkerSize', 24, 'MarkerFaceColor', [.95 .3 .25], ...
    'MarkerEdgeColor', 'k', 'LineWidth', 1.5);
text(x, 0, label, 'HorizontalAlignment', 'center', ...
    'VerticalAlignment', 'middle', 'FontSize', 9);
end

function closeIfValid(fig)
if ishandle(fig), close(fig); end
end

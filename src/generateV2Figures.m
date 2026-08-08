function generateV2Figures(groups, analyses, r1Results, r2Results, ...
        modelPieces, modelResults, noHiddenResult, noHiddenPieces, cfg, figureDir)
%GENERATEV2FIGURES R2016a-compatible Q1 rebuild paper figures.

drawRawLengths(analyses, cfg, figureDir);
drawR1Counts(r1Results, figureDir);
drawReconstructionExamples(groups, analyses, r1Results, r2Results, cfg, figureDir);
drawNoHiddenDemo(noHiddenResult, noHiddenPieces, cfg, figureDir);
for groupIndex = 1:3
    if ~isempty(modelResults{groupIndex, 1})
        drawPieceNetwork(groupIndex, modelPieces{groupIndex, 1}, ...
            modelResults{groupIndex, 1}, cfg, figureDir);
    end
end
end

function drawRawLengths(analyses, cfg, figureDir)
figureHandle = figure('Visible', 'off', 'Color', 'w');
for groupIndex = 1:3
    subplot(3, 1, groupIndex);
    hist(analyses{groupIndex}.SegmentLength, ...
        max(5, min(30, ceil(sqrt(analyses{groupIndex}.Records)))));
    hold on; limits = get(gca, 'YLim');
    plot([cfg.mediumALength cfg.mediumALength], limits, 'r--', 'LineWidth', 1.5);
    hold off; grid on;
    xlabel('RawLength / nm'); ylabel('Count'); title(sprintf('Group %d', groupIndex));
end
print(figureHandle, fullfile(figureDir, 'raw_length_distribution.png'), '-dpng', '-r300');
savefig(figureHandle, fullfile(figureDir, 'raw_length_distribution.fig'));
close(figureHandle);
end

function drawR1Counts(r1Results, figureDir)
statusNames = {'DIRECT_5000','UNIQUE_ENDPOINT_UNWRAP', ...
    'NO_ENDPOINT_UNWRAP','AMBIGUOUS_ENDPOINT_UNWRAP'};
counts = zeros(3, 4);
for groupIndex = 1:3
    for recordIndex = 1:numel(r1Results{groupIndex})
        status = r1Results{groupIndex}{recordIndex}.Status;
        for statusIndex = 1:4
            counts(groupIndex, statusIndex) = counts(groupIndex, statusIndex) + ...
                strcmp(status, statusNames{statusIndex});
        end
    end
end
figureHandle = figure('Visible', 'off', 'Color', 'w');
bar(counts, 'grouped'); grid on;
set(gca, 'XTick', 1:3, 'XTickLabel', {'Group1','Group2','Group3'});
ylabel('Medium count'); title('R1 same-row endpoint unwrap results');
legend({'DIRECT 5000','UNIQUE UNWRAP','NO UNWRAP','AMBIGUOUS'}, ...
    'Location', 'NorthWest');
print(figureHandle, fullfile(figureDir, 'r1_endpoint_unwrap_success.png'), '-dpng', '-r300');
savefig(figureHandle, fullfile(figureDir, 'r1_endpoint_unwrap_success.fig'));
close(figureHandle);
end

function drawReconstructionExamples(groups, analyses, r1Results, r2Results, cfg, figureDir)
examples = zeros(0, 3); % [group, medium, type: 1 R1 success, 2 R2 rescue, 3 unresolved]
for groupIndex = 1:3
    for mediumID = 1:analyses{groupIndex}.Records
        if isempty(find(examples(:, 3) == 1, 1)) && ...
                ~strcmp(r1Results{groupIndex}{mediumID}.Status, 'NO_ENDPOINT_UNWRAP') && ...
                ~strcmp(r1Results{groupIndex}{mediumID}.Status, 'AMBIGUOUS_ENDPOINT_UNWRAP')
            examples(end + 1, :) = [groupIndex mediumID 1]; %#ok<AGROW>
        end
        if isempty(find(examples(:, 3) == 2, 1)) && ...
                strcmp(r1Results{groupIndex}{mediumID}.Status, 'NO_ENDPOINT_UNWRAP') && ...
                strcmp(r2Results{groupIndex}{mediumID}.Status, 'UNIQUE_RECONSTRUCTION')
            examples(end + 1, :) = [groupIndex mediumID 2]; %#ok<AGROW>
        end
        if isempty(find(examples(:, 3) == 3, 1)) && ...
                strcmp(r2Results{groupIndex}{mediumID}.Status, 'UNRESOLVED')
            examples(end + 1, :) = [groupIndex mediumID 3]; %#ok<AGROW>
        end
    end
end
examples = sortrows(examples, 3);
figureHandle = figure('Visible', 'off', 'Color', 'w', 'Position', [100 100 1500 500]);
for exampleIndex = 1:size(examples, 1)
    groupIndex = examples(exampleIndex, 1); mediumID = examples(exampleIndex, 2);
    subplot(1, size(examples, 1), exampleIndex); hold on; drawBox(cfg.HALF_L);
    rawHandle = plot3([analyses{groupIndex}.P1(mediumID, 1) analyses{groupIndex}.P2(mediumID, 1)], ...
        [analyses{groupIndex}.P1(mediumID, 2) analyses{groupIndex}.P2(mediumID, 2)], ...
        [analyses{groupIndex}.P1(mediumID, 3) analyses{groupIndex}.P2(mediumID, 3)], ...
        'b-', 'LineWidth', 3);
    originalHandle = [];
    pieceHandle = [];
    if examples(exampleIndex, 3) == 1
        item = r1Results{groupIndex}{mediumID};
        originalStart = analyses{groupIndex}.P1(mediumID, :);
        originalEnd = analyses{groupIndex}.P2(mediumID, :) + ...
            cfg.L * item.K(item.SelectedIndex, :);
        wrapped = wrapSegmentToBox(originalStart, originalEnd, cfg.HALF_L, cfg.L, cfg.reconstructionTolerance);
        label = 'R1 success';
    elseif examples(exampleIndex, 3) == 2
        item = r2Results{groupIndex}{mediumID};
        originalStart = item.OriginalStart(item.SelectedIndex, :);
        originalEnd = item.OriginalEnd(item.SelectedIndex, :);
        wrapped = item.WrappedPieces{item.SelectedIndex};
        label = 'R1 fail / R2 success';
    else
        wrapped.Start = zeros(0, 3); wrapped.End = zeros(0, 3);
        originalStart = []; originalEnd = []; label = 'R2 unresolved';
    end
    if ~isempty(originalStart)
        originalHandle = plot3([originalStart(1) originalEnd(1)], ...
            [originalStart(2) originalEnd(2)], [originalStart(3) originalEnd(3)], ...
            'k--', 'LineWidth', 2);
        for pieceIndex = 1:size(wrapped.Start, 1)
            pieceHandle = plot3([wrapped.Start(pieceIndex, 1) wrapped.End(pieceIndex, 1)], ...
                [wrapped.Start(pieceIndex, 2) wrapped.End(pieceIndex, 2)], ...
                [wrapped.Start(pieceIndex, 3) wrapped.End(pieceIndex, 3)], ...
                'r-', 'LineWidth', 1.5);
        end
    end
    hold off; axis equal; grid on; view(3);
    title(sprintf('%s | Group%d A%d', label, groupIndex, mediumID));
    xlabel('x'); ylabel('y'); zlabel('z');
    if ~isempty(originalHandle)
        legend([rawHandle originalHandle pieceHandle], ...
            {'Attachment row','Original 5000 axis','Forward-wrapped Pieces'}, ...
            'Location', 'SouthOutside');
    else
        legend(rawHandle, {'Attachment row'}, 'Location', 'SouthOutside');
    end
end
print(figureHandle, fullfile(figureDir, 'row_reconstruction_examples.png'), '-dpng', '-r300');
savefig(figureHandle, fullfile(figureDir, 'row_reconstruction_examples.fig'));
close(figureHandle);
end

function drawPieceNetwork(groupIndex, pieces, result, cfg, figureDir)
figureHandle = figure('Visible', 'off', 'Color', 'w'); hold on;
drawElectrodes(cfg.HALF_L);
for pieceIndex = 1:numel(pieces.MediumID)
    if any(result.PathPieces == pieceIndex), color = [0.85 0.05 0.05]; width = 2.5;
    else, color = [0.72 0.72 0.72]; width = 0.6; end
    plot3([pieces.PieceStart(pieceIndex, 1) pieces.PieceEnd(pieceIndex, 1)], ...
        [pieces.PieceStart(pieceIndex, 2) pieces.PieceEnd(pieceIndex, 2)], ...
        [pieces.PieceStart(pieceIndex, 3) pieces.PieceEnd(pieceIndex, 3)], ...
        '-', 'Color', color, 'LineWidth', width);
end
hold off; axis equal; grid on; view(3);
axis([-cfg.HALF_L cfg.HALF_L -cfg.HALF_L cfg.HALF_L -cfg.HALF_L cfg.HALF_L]);
title({sprintf('Group %d | R0 Piece-level graph | Conducting=%d', groupIndex, result.Conducting), result.BFSPath});
xlabel('x / nm'); ylabel('y / nm'); zlabel('z / nm');
path = fullfile(figureDir, sprintf('q1_group%d_piece_network', groupIndex));
print(figureHandle, [path '.png'], '-dpng', '-r300'); savefig(figureHandle, [path '.fig']);
close(figureHandle);
end

function drawNoHiddenDemo(result, pieces, cfg, figureDir)
figureHandle = figure('Visible', 'off', 'Color', 'w'); hold on;
drawElectrodes(cfg.HALF_L);
colors = [0.1 0.35 0.9; 0.9 0.25 0.1];
for index = 1:2
    plot3([pieces.PieceStart(index, 1) pieces.PieceEnd(index, 1)], ...
        [pieces.PieceStart(index, 2) pieces.PieceEnd(index, 2)], ...
        [pieces.PieceStart(index, 3) pieces.PieceEnd(index, 3)], ...
        '-', 'Color', colors(index, :), 'LineWidth', 4);
end
plot3([pieces.PieceEnd(1, 1) pieces.PieceStart(2, 1)], [0 0], [0 0], ...
    'k:', 'LineWidth', 1.5);
hold off; grid on; view(3); axis equal;
axis([-cfg.HALF_L cfg.HALF_L -1000 1000 -1000 1000]);
title({'No hidden Medium connection', ...
    'LEFT--A1-1    (no electrical edge)    A1-2--RIGHT', ...
    sprintf('Same MediumID A1, Conducting=%d', result.Conducting)});
xlabel('x / nm'); ylabel('y / nm'); zlabel('z / nm');
print(figureHandle, fullfile(figureDir, 'no_hidden_connection_demo.png'), '-dpng', '-r300');
savefig(figureHandle, fullfile(figureDir, 'no_hidden_connection_demo.fig'));
close(figureHandle);
end

function drawBox(halfLength)
v = halfLength * [-1 -1 -1;1 -1 -1;1 1 -1;-1 1 -1;-1 -1 1;1 -1 1;1 1 1;-1 1 1];
e = [1 2;2 3;3 4;4 1;5 6;6 7;7 8;8 5;1 5;2 6;3 7;4 8];
for i=1:size(e,1), plot3(v(e(i,:),1),v(e(i,:),2),v(e(i,:),3),'-','Color',[.65 .65 .65],'HandleVisibility','off'); end
end

function drawElectrodes(halfLength)
values = [-halfLength halfLength]; [y,z] = meshgrid(values,values);
surface(-halfLength*ones(2),y,z,'FaceColor',[.2 .4 .9],'FaceAlpha',.18,'EdgeColor','none');
surface(halfLength*ones(2),y,z,'FaceColor',[1 .5 .1],'FaceAlpha',.18,'EdgeColor','none');
end

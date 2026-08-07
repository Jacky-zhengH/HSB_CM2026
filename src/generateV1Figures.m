function generateV1Figures(groups, analyses, familyIDs, parentMaps, ...
        modelResults, candidates, directionAudit, cfg, figureDir)
%GENERATEV1FIGURES Create R2016a-compatible V1 paper figures.

% Direction-family total length distributions.
figureHandle = figure('Visible', 'off', 'Color', 'w');
for groupIndex = 1:3
    subplot(3, 1, groupIndex);
    values = directionAudit{groupIndex}.TotalAxisLength;
    hist(values, max(5, min(30, ceil(sqrt(numel(values))))));
    hold on;
    limits = get(gca, 'YLim');
    plot([cfg.mediumALength cfg.mediumALength], limits, 'r--', 'LineWidth', 1.5);
    hold off;
    xlabel('DirectionFamily TotalAxisLength / nm');
    ylabel('Count');
    title(sprintf('Group %d', groupIndex));
    grid on;
end
print(figureHandle, fullfile(figureDir, 'direction_family_total_length.png'), '-dpng', '-r300');
close(figureHandle);

% Conductivity model comparison.
conductivity = zeros(3, 3);
for groupIndex = 1:3
    for modelIndex = 1:3
        conductivity(groupIndex, modelIndex) = modelResults{groupIndex, modelIndex}.Conducting;
    end
end
figureHandle = figure('Visible', 'off', 'Color', 'w');
imagesc(conductivity, [0 1]);
colormap([0.85 0.25 0.20; 0.20 0.65 0.30]);
set(gca, 'XTick', 1:3, 'XTickLabel', {'M0', 'M1', 'M2'}, ...
    'YTick', 1:3, 'YTickLabel', {'Group1', 'Group2', 'Group3'});
xlabel('Parent Reconstruction Model');
ylabel('Data Group');
modelTitle = char([81 49 hex2dec('4E0D') hex2dec('540C') hex2dec('8FB9') ...
    hex2dec('754C') hex2dec('89E3') hex2dec('91CA') hex2dec('4E0B') ...
    hex2dec('7684') hex2dec('5BFC') hex2dec('901A') hex2dec('5224') ...
    hex2dec('5B9A') hex2dec('6BD4') hex2dec('8F83')]);
connectedLabel = char([hex2dec('5BFC') hex2dec('901A')]);
notConnectedLabel = char([hex2dec('4E0D') hex2dec('5BFC') hex2dec('901A')]);
title(modelTitle);
for row = 1:3
    for column = 1:3
        if conductivity(row, column)
            label = connectedLabel;
        else
            label = notConnectedLabel;
        end
        text(column, row, label, 'HorizontalAlignment', 'center', ...
            'Color', 'w', 'FontWeight', 'bold');
    end
end
print(figureHandle, fullfile(figureDir, 'q1_model_comparison.png'), '-dpng', '-r300');
savefig(figureHandle, fullfile(figureDir, 'q1_model_comparison.fig'));
close(figureHandle);

% Parent-count comparison.
counts = zeros(3, 3);
for groupIndex = 1:3
    counts(groupIndex, 1) = analyses{groupIndex}.Records;
    counts(groupIndex, 2) = max(parentMaps{groupIndex, 2});
    counts(groupIndex, 3) = max(parentMaps{groupIndex, 3});
end
figureHandle = figure('Visible', 'off', 'Color', 'w');
bar(counts, 'grouped');
set(gca, 'XTick', 1:3, 'XTickLabel', {'G1', 'G2', 'G3'});
quantityLabel = char([hex2dec('6570') hex2dec('91CF')]);
parentTitle = char([hex2dec('8FB9') hex2dec('754C') hex2dec('91CD') ...
    hex2dec('6784') hex2dec('6A21') hex2dec('578B') hex2dec('4E0B') ...
    hex2dec('7684') hex2dec('4ECB') hex2dec('8D28') hex2dec('6570') ...
    hex2dec('91CF') hex2dec('6BD4') hex2dec('8F83')]);
ylabel(quantityLabel);
title(parentTitle);
legend({'Record Count', 'M1 Parent Count', 'M2 Parent Count'}, 'Location', 'NorthWest');
grid on;
print(figureHandle, fullfile(figureDir, 'parent_count_comparison.png'), '-dpng', '-r300');
savefig(figureHandle, fullfile(figureDir, 'parent_count_comparison.fig'));
close(figureHandle);

% One strongest boundary reconstruction example per group.
figureHandle = figure('Visible', 'off', 'Color', 'w', 'Position', [100 100 1500 500]);
for groupIndex = 1:3
    subplot(1, 3, groupIndex);
    mask = find(candidates.Group == groupIndex);
    score = [candidates.EndpointError(mask) candidates.DirectionError(mask)];
    [~, order] = sortrows(score, [1 2]);
    selected = mask(order(1));
    recordA = candidates.RecordA(selected);
    recordB = candidates.RecordB(selected);
    translation = candidates.Translation(selected, :);
    hold on;
    drawBox(cfg.HALF_L);
    plot3([groups(groupIndex).P1(recordA, 1) groups(groupIndex).P2(recordA, 1)], ...
        [groups(groupIndex).P1(recordA, 2) groups(groupIndex).P2(recordA, 2)], ...
        [groups(groupIndex).P1(recordA, 3) groups(groupIndex).P2(recordA, 3)], ...
        'b-', 'LineWidth', 2);
    plot3([groups(groupIndex).P1(recordB, 1) groups(groupIndex).P2(recordB, 1)], ...
        [groups(groupIndex).P1(recordB, 2) groups(groupIndex).P2(recordB, 2)], ...
        [groups(groupIndex).P1(recordB, 3) groups(groupIndex).P2(recordB, 3)], ...
        'r-', 'LineWidth', 2);
    translatedP1 = groups(groupIndex).P1(recordB, :) + translation;
    translatedP2 = groups(groupIndex).P2(recordB, :) + translation;
    plot3([translatedP1(1) translatedP2(1)], [translatedP1(2) translatedP2(2)], ...
        [translatedP1(3) translatedP2(3)], 'g--', 'LineWidth', 2);
    hold off;
    axis equal;
    grid on;
    view(3);
    title(sprintf('Group %d: R%d-R%d', groupIndex, recordA, recordB));
    xlabel('x / nm'); ylabel('y / nm'); zlabel('z / nm');
end
print(figureHandle, fullfile(figureDir, 'boundary_reconstruction_examples.png'), '-dpng', '-r300');
close(figureHandle);

% M1 path figures. Ordinary pieces are axes only.
for groupIndex = 1:3
    figureHandle = figure('Visible', 'off', 'Color', 'w');
    hold on;
    drawElectrodes(cfg.HALF_L);
    pathParents = modelResults{groupIndex, 2}.PathParents;
    for pieceIndex = 1:analyses{groupIndex}.Records
        parentID = parentMaps{groupIndex, 2}(pieceIndex);
        if any(pathParents == parentID)
            color = [0.85 0.05 0.05];
            width = 2.5;
        else
            color = [0.70 0.70 0.70];
            width = 0.5;
        end
        plot3([analyses{groupIndex}.P1(pieceIndex, 1) analyses{groupIndex}.P2(pieceIndex, 1)], ...
            [analyses{groupIndex}.P1(pieceIndex, 2) analyses{groupIndex}.P2(pieceIndex, 2)], ...
            [analyses{groupIndex}.P1(pieceIndex, 3) analyses{groupIndex}.P2(pieceIndex, 3)], ...
            '-', 'Color', color, 'LineWidth', width);
    end
    pathText = formatBFSPath(modelResults{groupIndex, 2}.Conducting, pathParents);
    title({sprintf('Group %d | M1 Parents=%d | Conducting=%d', groupIndex, ...
        modelResults{groupIndex, 2}.ParentCount, modelResults{groupIndex, 2}.Conducting), pathText});
    xlabel('x / nm'); ylabel('y / nm'); zlabel('z / nm');
    axis equal;
    axis([-cfg.HALF_L cfg.HALF_L -cfg.HALF_L cfg.HALF_L -cfg.HALF_L cfg.HALF_L]);
    grid on;
    view(3);
    hold off;
    print(figureHandle, fullfile(figureDir, sprintf('q1_group%d_3d.png', groupIndex)), '-dpng', '-r300');
    savefig(figureHandle, fullfile(figureDir, sprintf('q1_group%d_3d.fig', groupIndex)));
    close(figureHandle);
end
end

function drawBox(halfLength)
vertices = halfLength * [-1 -1 -1; 1 -1 -1; 1 1 -1; -1 1 -1; ...
    -1 -1 1; 1 -1 1; 1 1 1; -1 1 1];
edges = [1 2; 2 3; 3 4; 4 1; 5 6; 6 7; 7 8; 8 5; 1 5; 2 6; 3 7; 4 8];
for index = 1:size(edges, 1)
    plot3(vertices(edges(index, :), 1), vertices(edges(index, :), 2), ...
        vertices(edges(index, :), 3), '-', 'Color', [0.6 0.6 0.6]);
end
end

function drawElectrodes(halfLength)
values = [-halfLength halfLength];
[y, z] = meshgrid(values, values);
x = -halfLength * ones(2);
surface(x, y, z, 'FaceColor', [0.2 0.4 0.9], 'FaceAlpha', 0.18, 'EdgeColor', 'none');
x = halfLength * ones(2);
surface(x, y, z, 'FaceColor', [1.0 0.5 0.1], 'FaceAlpha', 0.18, 'EdgeColor', 'none');
end

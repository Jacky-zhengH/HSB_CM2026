function [sequence, pieceEvents] = extractBoundaryEvents(translations, tolerance)
%EXTRACTBOUNDARYEVENTS Derive ordered axis events from Piece translations.

if nargin < 2 || isempty(tolerance), tolerance = 1e-9; end
pieceCount = size(translations, 1);
pieceEvents = repmat({'NONE'}, pieceCount, 1);
orderedEvents = cell(0, 1);
axisNames = {'X','Y','Z'};

for pieceIndex = 2:pieceCount
    changed = find(abs(translations(pieceIndex, :) - ...
        translations(pieceIndex - 1, :)) > tolerance);
    if isempty(changed)
        error('extractBoundaryEvents:MissingTranslationChange', ...
            'Adjacent Pieces must differ by at least one periodic translation.');
    end
    label = '';
    for axisIndex = changed
        label = [label axisNames{axisIndex}]; %#ok<AGROW>
    end
    if numel(changed) > 1
        label = [label '_SIMULTANEOUS'];
    end
    pieceEvents{pieceIndex} = label;
    orderedEvents{end + 1, 1} = label; %#ok<AGROW>
end

if isempty(orderedEvents)
    sequence = 'NONE';
else
    sequence = orderedEvents{1};
    for index = 2:numel(orderedEvents)
        sequence = [sequence '>' orderedEvents{index}]; %#ok<AGROW>
    end
end
end

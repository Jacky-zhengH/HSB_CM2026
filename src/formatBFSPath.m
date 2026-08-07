function text = formatBFSPath(conducting, parentPath)
%FORMATBFSPATH Render a PhysicalMedium BFS path without string arrays.

if ~conducting
    text = '';
    return;
end
text = 'LEFT';
for index = 1:numel(parentPath)
    text = [text sprintf(' -> P%d', parentPath(index))]; %#ok<AGROW>
end
text = [text ' -> RIGHT'];
end

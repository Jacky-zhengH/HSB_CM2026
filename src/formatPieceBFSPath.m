function textValue = formatPieceBFSPath(conducting, pathPieces, pieces)
%FORMATPIECEBFSPATH Render LEFT -> Ai-j -> RIGHT labels.

if ~conducting
    textValue = '';
    return;
end
textValue = 'LEFT';
for index = 1:numel(pathPieces)
    node = pathPieces(index);
    textValue = [textValue sprintf(' -> A%d-%d', ...
        pieces.MediumID(node), pieces.PieceIndex(node))]; %#ok<AGROW>
end
textValue = [textValue ' -> RIGHT'];
end

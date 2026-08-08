function writeFigureManifest(path, manifest)
%WRITEFIGUREMANIFEST Persist a checkpoint after every paper figure.

fileID = fopen(path, 'w');
if fileID < 0
    error('writeFigureManifest:OpenFailed', 'Cannot write %s.', path);
end
cleanup = onCleanup(@() fclose(fileID));
fprintf(fileID, 'Index,FigureName,Status,FileExists,FileSizeBytes,ErrorMessage\n');
for index = 1:numel(manifest)
    fprintf(fileID, '%d,%s,%s,%d,%d,', manifest(index).Index, ...
        manifest(index).FigureName, manifest(index).Status, ...
        manifest(index).FileExists, manifest(index).FileSizeBytes);
    message = strrep(manifest(index).ErrorMessage, '"', '""');
    fprintf(fileID, '"%s"\n', message);
end
clear cleanup;
end

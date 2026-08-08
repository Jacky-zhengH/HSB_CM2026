function writeExcelSchemaAudit(excelPath, groups, logPath)
%WRITEEXCELSCHEMAAUDIT Validate and record the attachment workbook schema.

[status, sheetNames] = xlsfinfo(excelPath);
expectedCounts = [12 49 535];
validSheetNames = numel(sheetNames) == 3;
for sheetIndex = 1:numel(sheetNames)
    validSheetNames = validSheetNames && ischar(sheetNames{sheetIndex}) && ...
        ~isempty(sheetNames{sheetIndex});
end
if isempty(status) || ~validSheetNames
    error('writeExcelSchemaAudit:SheetMismatch', ...
        'Expected exactly three nonempty worksheet names.');
end
fileID = fopen(logPath, 'w', 'n', 'UTF-8');
if fileID < 0
    error('writeExcelSchemaAudit:OpenFailed', 'Cannot write %s.', logPath);
end
fprintf(fileID, 'Workbook=%s\r\n', excelPath);
fprintf(fileID, 'SheetCount=%d\r\n', numel(sheetNames));
for groupIndex = 1:3
    [~, ~, raw] = xlsread(excelPath, sheetNames{groupIndex});
    header2 = cell(1, 6);
    for column = 1:6
        header2{column} = raw{2, column};
    end
    expectedHeader2 = {'X','Y','Z','X','Y','Z'};
    headerPass = size(raw, 2) == 6 && ...
        ischar(raw{1, 1}) && ischar(raw{1, 4}) && ...
        ~isempty(raw{1, 1}) && ~isempty(raw{1, 4}) && ...
        all(strcmp(header2, expectedHeader2));
    columnsPass = isequal(groups(groupIndex).CoordinateColumns, 1:6);
    countPass = numel(groups(groupIndex).RecordID) == expectedCounts(groupIndex);
    sheetOrderPass = strcmp(groups(groupIndex).SheetName, sheetNames{groupIndex});
    if ~(headerPass && columnsPass && countPass && sheetOrderPass)
        fclose(fileID);
        error('writeExcelSchemaAudit:SchemaMismatch', ...
            'Schema is ambiguous or invalid in sheet %s.', sheetNames{groupIndex});
    end
    fprintf(fileID, '\r\nSheet=%s\r\n', sheetNames{groupIndex});
    fprintf(fileID, 'HeaderRow1=%s,,,%s,,\r\n', raw{1, 1}, raw{1, 4});
    fprintf(fileID, 'HeaderRow2=X,Y,Z,X,Y,Z\r\n');
    fprintf(fileID, 'CoordinateColumns=1,2,3,4,5,6\r\n');
    fprintf(fileID, 'P1=[columns 1,2,3]; P2=[columns 4,5,6]\r\n');
    fprintf(fileID, 'RecordCount=%d\r\n', expectedCounts(groupIndex));
    fprintf(fileID, 'FirstFiveRows:\r\n');
    maximum = min(5, numel(groups(groupIndex).RecordID));
    for row = 1:maximum
        fprintf(fileID, ['ExcelRow=%d P1=[%.15g %.15g %.15g] ' ...
            'P2=[%.15g %.15g %.15g]\r\n'], ...
            groups(groupIndex).OriginalExcelRow(row), ...
            groups(groupIndex).P1(row, :), groups(groupIndex).P2(row, :));
    end
end
fprintf(fileID, '\r\nEXCEL_SCHEMA_PASS=1\r\n');
fclose(fileID);
end

function issueCount = runRetainedCheckcode(projectRoot, logPath)
%RUNRETAINEDCHECKCODE Run MATLAB Code Analyzer on retained-part code.

files = { ...
    fullfile(projectRoot, 'src', 'reconstructFromRetainedPart.m'), ...
    fullfile(projectRoot, 'src', 'buildRetainedPartPieces.m'), ...
    fullfile(projectRoot, 'src', 'writeRetainedPartTables.m'), ...
    fullfile(projectRoot, 'src', 'writeRetainedPartSummary.m'), ...
    fullfile(projectRoot, 'src', 'generateRetainedPartFigures.m'), ...
    fullfile(projectRoot, 'tests', 'testRetainedPartReconstruction.m'), ...
    fullfile(projectRoot, 'scripts', 'run_q1_retained_part.m')};
fileID = fopen(logPath, 'w');
if fileID < 0, error('runRetainedCheckcode:OpenFailed', 'Cannot write %s.', logPath); end
cleanup = onCleanup(@() fclose(fileID)); %#ok<NASGU>
issueCount = 0;
for fileIndex = 1:numel(files)
    messages = checkcode(files{fileIndex}, '-id');
    fprintf(fileID, 'FILE=%s ISSUES=%d\r\n', files{fileIndex}, numel(messages));
    issueCount = issueCount + numel(messages);
    for messageIndex = 1:numel(messages)
        message = messages(messageIndex);
        fprintf(fileID, '  line=%d id=%s message=%s\r\n', ...
            message.line, message.id, message.message);
    end
end
fprintf(fileID, 'TOTAL_ISSUES=%d\r\n', issueCount);
end

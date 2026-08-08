function [passed, lines] = testRowReconstruction()
%TESTROWRECONSTRUCTION R2 forward-reproduction test.

cfg.L = 10000;
cfg.HALF_L = 5000;
cfg.mediumALength = 5000;
cfg.reconstructionTolerance = 1e-6;
lines = cell(0, 1);
passed = true;

result = reconstructRowR2([1000 0 0], [5000 0 0], cfg);
ok = strcmp(result.Status, 'UNIQUE_RECONSTRUCTION') && ...
    strcmp(result.Hypothesis{result.SelectedIndex}, 'A_EXTEND_AFTER_P2') && ...
    max(abs(result.OriginalEnd(result.SelectedIndex, :) - [6000 0 0])) <= 1e-6;
passed = passed && ok;
lines{end + 1} = sprintf('R2 extend and forward reproduce: PASS=%d', ok);

result = reconstructRowR2([0 0 0], [1000 0 0], cfg);
ok = strcmp(result.Status, 'UNRESOLVED');
passed = passed && ok;
lines{end + 1} = sprintf('R2 unresolved remains unresolved: PASS=%d', ok);
end

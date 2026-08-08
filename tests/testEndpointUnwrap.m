function [passed, lines] = testEndpointUnwrap()
%TESTENDPOINTUNWRAP Same-row R1 tests, including a required failure case.

lines = cell(0, 1);
passed = true;

direct = enumerateEndpointUnwrap([-2500 0 0], [2500 0 0], 10000, 5000, 1e-6);
validK = direct.K(direct.ValidIndices, :);
ok = strcmp(direct.Status, 'DIRECT_5000') && ...
    any(all(bsxfun(@eq, validK, [0 0 0]), 2));
passed = passed && ok;
lines{end + 1} = sprintf('R1 direct 5000: PASS=%d', ok);

wrapped = enumerateEndpointUnwrap([1000 0 0], [-4000 0 0], 10000, 5000, 1e-6);
validK = wrapped.K(wrapped.ValidIndices, :);
ok = any(all(bsxfun(@eq, validK, [1 0 0]), 2));
passed = passed && ok;
lines{end + 1} = sprintf('R1 recognizes k=[1,0,0] candidate: PASS=%d', ok);

failure = enumerateEndpointUnwrap([0 0 0], [1000 0 0], 10000, 5000, 1e-6);
ok = strcmp(failure.Status, 'NO_ENDPOINT_UNWRAP') && failure.CandidateCount == 0;
passed = passed && ok;
lines{end + 1} = sprintf('R1 no nearest fallback: PASS=%d', ok);
end

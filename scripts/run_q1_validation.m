%RUN_Q1_VALIDATION Compatibility entry for the endpoint-unfold rebuild.
%   The formal implementation and all outputs are isolated in
%   run_q1_endpoint_rebuild.m and output/Q1_endpoint_rebuild/.

scriptDirectory = fileparts(mfilename('fullpath'));
run(fullfile(scriptDirectory, 'run_q1_endpoint_rebuild.m'));

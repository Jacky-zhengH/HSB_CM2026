function [passed, lines] = testNoGlobalPeriodicFalseEdge()
%TESTNOGLOBALPERIODICFALSEEDGE Different Mediums use current Euclidean space.

cfg.HALF_L = 5000; cfg.mediumARadius = 30;
cfg.conductionDistance = 1.8; cfg.broadPhaseDistance = 61.8;
cfg.gjkTolerance = 1e-8; cfg.gjkMaxIterations = 100;
pieces = makeTestPieces([-4990 -500 0; 4990 -500 0], ...
    [-4990 500 0; 4990 500 0], [1; 2]);
graph = buildPieceConductGraph(pieces, cfg);
passed = isempty(graph.GeometryEdges) && ~graph.Conducting;
lines = {sprintf('no global periodic false edge PASS=%d', passed)};
end

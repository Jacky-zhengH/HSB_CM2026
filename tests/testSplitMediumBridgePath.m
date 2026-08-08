function [passed, lines, conductingCase, brokenCase] = testSplitMediumBridgePath()
%TESTSPLITMEDIUMBRIDGEPATH Only a real Piece chain can bridge electrodes.

cfg = testGraphConfig();
starts = [-5000 0 0; -4499 0 0; 1 0 0; 4500 0 0];
ends = [-4500 0 0; 0 0 0; 4499 0 0; 5000 0 0];
mediumIDs = [1; 2; 3; 1];
pieces = makeTestPieces(starts, ends, mediumIDs);
conductingCase.Graph = buildPieceConductGraph(pieces, cfg);
conductingCase.Charge = computeChargeState(pieces, ...
    conductingCase.Graph.GeometryEdges, conductingCase.Graph.LeftContact, ...
    conductingCase.Graph.RightContact);
requiredEdges = hasEdge(conductingCase.Graph.GeometryEdges, 1, 2) && ...
    hasEdge(conductingCase.Graph.GeometryEdges, 2, 3) && ...
    hasEdge(conductingCase.Graph.GeometryEdges, 3, 4) && ...
    ~hasEdge(conductingCase.Graph.GeometryEdges, 1, 4);
caseA = conductingCase.Graph.Conducting && requiredEdges;

brokenStarts = starts;
brokenStarts(3, 1) = 100;
brokenPieces = makeTestPieces(brokenStarts, ends, mediumIDs);
brokenCase.Graph = buildPieceConductGraph(brokenPieces, cfg);
brokenCase.Charge = computeChargeState(brokenPieces, ...
    brokenCase.Graph.GeometryEdges, brokenCase.Graph.LeftContact, ...
    brokenCase.Graph.RightContact);
caseB = ~hasEdge(brokenCase.Graph.GeometryEdges, 2, 3) && ...
    ~brokenCase.Graph.Conducting && all(brokenCase.Charge.PieceCharged);

passed = caseA && caseB;
lines = {sprintf('split-Medium real bridge CONDUCTING PASS=%d', caseA); ...
    sprintf(['broken bridge NON_CONDUCTING while every Piece is Charged ' ...
    'PASS=%d'], caseB)};
end

function cfg = testGraphConfig()
cfg.HALF_L = 5000; cfg.mediumARadius = 30;
cfg.conductionDistance = 1.8; cfg.broadPhaseDistance = 61.8;
cfg.gjkTolerance = 1e-8; cfg.gjkMaxIterations = 100;
end

function result = hasEdge(edges, a, b)
result = any((edges(:, 1) == a & edges(:, 2) == b) | ...
    (edges(:, 1) == b & edges(:, 2) == a));
end

function [passed, lines, result, charge, pieces] = ...
        testSameMediumDoesNotCreateConductEdge()
%TESTSAMEMEDIUMDOESNOTCREATECONDUCTEDGE Charge inheritance is not a wire.

cfg = testGraphConfig();
pieces = makeTestPieces([-5000 0 0; 4500 0 0], ...
    [-4500 0 0; 5000 0 0], [1; 1]);
result = buildPieceConductGraph(pieces, cfg);
charge = computeChargeState(pieces, result.GeometryEdges, ...
    result.LeftContact, result.RightContact);
sameMediumEdge = hasEdge(result.GeometryEdges, 1, 2);
passed = result.LeftContact(1) && result.RightContact(2) && ...
    all(charge.PieceCharged) && ~sameMediumEdge && ~result.Conducting;
lines = {sprintf(['same-Medium no conduct edge: PieceCharged=[%d %d], ' ...
    'PieceEdge=%d Conducting=%d PASS=%d'], charge.PieceCharged, ...
    sameMediumEdge, result.Conducting, passed)};
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

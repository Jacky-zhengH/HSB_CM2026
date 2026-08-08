function [passed, lines] = testInsulatingFaceDoesNotDirectlyCharge()
%TESTINSULATINGFACEDOESNOTDIRECTLYCHARGE Y/Z faces are not electrodes.

cfg = testGraphConfig();
isolated = makeTestPieces([0 0 4500], [0 0 5000], 2);
isolatedGraph = buildPieceConductGraph(isolated, cfg);
isolatedCharge = computeChargeState(isolated, isolatedGraph.GeometryEdges, ...
    isolatedGraph.LeftContact, isolatedGraph.RightContact);
caseA = ~isolatedCharge.DirectElectrodeCharged && ...
    ~isolatedCharge.MediumCharged;

pieces = makeTestPieces([-5000 0 0; 0 0 4500], ...
    [-4500 0 0; 0 0 5000], [1; 1]);
graph = buildPieceConductGraph(pieces, cfg);
charge = computeChargeState(pieces, graph.GeometryEdges, ...
    graph.LeftContact, graph.RightContact);
caseB = charge.PieceCharged(2) && ...
    ~charge.DirectElectrodeCharged(2) && ...
    charge.InheritedFromSameMedium(2) && ...
    strcmp(charge.ChargeSource{2}, 'SAME_MEDIUM_INHERITANCE');

passed = caseA && caseB;
lines = {sprintf('insulating Z face no direct charge PASS=%d', caseA); ...
    sprintf('Z-boundary sibling charged only by same-Medium inheritance PASS=%d', caseB)};
end

function cfg = testGraphConfig()
cfg.HALF_L = 5000; cfg.mediumARadius = 30;
cfg.conductionDistance = 1.8; cfg.broadPhaseDistance = 61.8;
cfg.gjkTolerance = 1e-8; cfg.gjkMaxIterations = 100;
end

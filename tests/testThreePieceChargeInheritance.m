function [passed, lines] = testThreePieceChargeInheritance()
%TESTTHREEPIECECHARGEINHERITANCE Same Medium shares state, not graph edges.

cfg = testGraphConfig();
originalStart = [-4000 0 2000];
originalEnd = originalStart + [-3000 0 4000];
wrapped = wrapSegmentToBox(originalStart, originalEnd, cfg.HALF_L, ...
    10000, 1e-8);
pieces = makeTestPieces(wrapped.Start, wrapped.End, ones(3, 1));
pieces.Translation = wrapped.Translation;
graph = buildPieceConductGraph(pieces, cfg);

% Isolate the charge rule: only A1-1 is declared a direct LEFT contact.
charge = computeChargeState(pieces, graph.GeometryEdges, ...
    [true; false; false], false(3, 1));
passed = size(wrapped.Start, 1) == 3 && graph.LeftContact(1) && ...
    isempty(graph.GeometryEdges) && ~graph.Conducting && ...
    all(charge.PieceCharged) && charge.DirectElectrodeCharged(1) && ...
    all(~charge.DirectElectrodeCharged(2:3)) && ...
    all(charge.InheritedFromSameMedium(2:3));
lines = {sprintf(['three-Piece charge inheritance: PieceCount=%d ' ...
    'Inherited=[%d %d] Conducting=%d PASS=%d'], size(wrapped.Start, 1), ...
    charge.InheritedFromSameMedium(2), charge.InheritedFromSameMedium(3), ...
    graph.Conducting, passed)};
end

function cfg = testGraphConfig()
cfg.HALF_L = 5000; cfg.mediumARadius = 30;
cfg.conductionDistance = 1.8; cfg.broadPhaseDistance = 61.8;
cfg.gjkTolerance = 1e-8; cfg.gjkMaxIterations = 100;
end

function [passed, lines, result, pieces] = testNoHiddenParentConnection()
%TESTNOHIDDENPARENTCONNECTION Same MediumID must not create an electrical edge.

cfg.HALF_L = 5000;
cfg.mediumARadius = 30;
cfg.conductionDistance = 1.8;
cfg.broadPhaseDistance = 61.8;
cfg.gjkTolerance = 1e-8;
cfg.gjkMaxIterations = 100;

pieces.Group = [1; 1];
pieces.Model = {'TEST'; 'TEST'};
pieces.MediumID = [1; 1];
pieces.PieceIndex = [1; 2];
pieces.SourceExcelRow = [1; 1];
pieces.OriginalStart = [-5000 0 0; 4500 0 0];
pieces.OriginalEnd = [-4500 0 0; 5000 0 0];
pieces.PieceStart = pieces.OriginalStart;
pieces.PieceEnd = pieces.OriginalEnd;
pieces.PieceLength = [500; 500];
pieces.Translation = zeros(2, 3);

result = buildPieceConductGraph(pieces, cfg);
sameMediumEdge = any((result.GeometryEdges(:, 1) == 1 & result.GeometryEdges(:, 2) == 2) | ...
    (result.GeometryEdges(:, 1) == 2 & result.GeometryEdges(:, 2) == 1));
passed = result.LeftContact(1) && result.RightContact(2) && ...
    ~sameMediumEdge && ~result.Conducting;
lines = {sprintf(['No hidden connection: LEFT-A1-1=%d, A1-2-RIGHT=%d, ' ...
    'pieceEdge=%d, Conducting=%d, PASS=%d'], result.LeftContact(1), ...
    result.RightContact(2), sameMediumEdge, result.Conducting, passed)};
end

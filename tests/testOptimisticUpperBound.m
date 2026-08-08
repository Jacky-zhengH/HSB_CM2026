function [passed, lines] = testOptimisticUpperBound(group, results, ...
        knownPieces, lowerGraph, upper, cfg)
%TESTOPTIMISTICUPPERBOUND Validate supergraph and envelope invariants.

passed = true;
lines = cell(0, 1);
unresolvedExpected = find(cellfun(@(item) strcmp(item.Status, ...
    'UNRESOLVED_NO_FORMAL_BOUNDARY'), results));
ok = isequal(upper.UnresolvedMediumIDs(:), unresolvedExpected(:));
record(ok, 'Upper-bound unresolved Medium set');

for envelopeIndex = 1:numel(upper.Envelopes)
    envelope = upper.Envelopes(envelopeIndex);
    expectedLength = 2 * cfg.mediumALength - envelope.ObservedLength;
    ok = abs(envelope.EnvelopeLength - expectedLength) <= cfg.lengthTolerance;
    record(ok, sprintf('A%d envelope length identity', envelope.MediumID));
    item = results{envelope.MediumID};
    ok = strcmp(item.Status, 'UNRESOLVED_NO_FORMAL_BOUNDARY') && ...
        max(abs(envelope.ObservedP1 - group.P1(envelope.MediumID, :))) == 0;
    record(ok, sprintf('A%d remains unresolved and unmodified', envelope.MediumID));
end

lowerEdgePreserved = true;
for edgeIndex = 1:size(lowerGraph.GeometryEdges, 1)
    a = lowerGraph.GeometryEdges(edgeIndex, 1) + 1;
    b = lowerGraph.GeometryEdges(edgeIndex, 2) + 1;
    lowerEdgePreserved = lowerEdgePreserved && any(upper.Adjacency{a} == b);
end
record(lowerEdgePreserved, 'Every lower-bound physical edge is in upper graph');

noHiddenSameMediumEdge = true;
for edgeIndex = 1:numel(upper.EdgeA)
    a = upper.EdgeA(edgeIndex); b = upper.EdgeB(edgeIndex);
    if strcmp(upper.EdgeType{edgeIndex}, 'OPTIMISTIC_CAPSULE') && ...
            upper.Pieces.MediumID(a) == upper.Pieces.MediumID(b)
        noHiddenSameMediumEdge = false;
    end
end
record(noHiddenSameMediumEdge, 'Envelope siblings have no hidden conduct edge');

knownCountOK = upper.KnownPieceCount == numel(knownPieces.MediumID);
record(knownCountOK, 'Known Piece count is unchanged');
distanceOK = isfinite(upper.MinEnvelopeToKnownAxisDistance) && ...
    isfinite(upper.MinEnvelopeToEnvelopeAxisDistance);
record(distanceOK, 'Upper-bound certificate distances are finite');

    function record(okLocal, label)
        passed = passed && okLocal;
        lines{end + 1, 1} = sprintf('%s PASS=%d', label, okLocal);
    end
end

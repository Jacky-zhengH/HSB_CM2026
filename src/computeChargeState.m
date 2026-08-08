function state = computeChargeState(pieces, geometryEdges, leftContact, rightContact)
%COMPUTECHARGESTATE Propagate Medium charge without changing physical edges.

pieceCount = numel(pieces.MediumID);
if numel(leftContact) ~= pieceCount || numel(rightContact) ~= pieceCount
    error('computeChargeState:SizeMismatch', ...
        'Contact arrays must contain one entry per GeometryPiece.');
end

mediumIDs = unique(pieces.MediumID(:));
mediumCharged = false(numel(mediumIDs), 1);
pieceCharged = false(pieceCount, 1);
directElectrodeCharged = leftContact(:) | rightContact(:);
activatedByGeometry = false(pieceCount, 1);

for pieceIndex = find(directElectrodeCharged(:))'
    mediumIndex = find(mediumIDs == pieces.MediumID(pieceIndex), 1);
    mediumCharged(mediumIndex) = true;
end
pieceCharged = ismember(pieces.MediumID, mediumIDs(mediumCharged));

changed = true;
while changed
    changed = false;
    for edgeIndex = 1:size(geometryEdges, 1)
        pieceA = geometryEdges(edgeIndex, 1);
        pieceB = geometryEdges(edgeIndex, 2);
        mediumA = find(mediumIDs == pieces.MediumID(pieceA), 1);
        mediumB = find(mediumIDs == pieces.MediumID(pieceB), 1);
        if pieceCharged(pieceA) && ~mediumCharged(mediumB)
            mediumCharged(mediumB) = true;
            activatedByGeometry(pieceB) = true;
            changed = true;
        elseif pieceCharged(pieceB) && ~mediumCharged(mediumA)
            mediumCharged(mediumA) = true;
            activatedByGeometry(pieceA) = true;
            changed = true;
        end
    end
    pieceCharged = ismember(pieces.MediumID, mediumIDs(mediumCharged));
end

inheritedFromSameMedium = pieceCharged & ...
    ~directElectrodeCharged & ~activatedByGeometry;
chargeSource = repmat({'UNCHARGED'}, pieceCount, 1);
chargeSource(inheritedFromSameMedium) = {'SAME_MEDIUM_INHERITANCE'};
chargeSource(activatedByGeometry) = {'GEOMETRY_EDGE'};
chargeSource(directElectrodeCharged) = {'DIRECT_ELECTRODE'};

state.MediumIDs = mediumIDs;
state.MediumCharged = mediumCharged;
state.PieceCharged = pieceCharged;
state.DirectElectrodeCharged = directElectrodeCharged;
state.InheritedFromSameMedium = inheritedFromSameMedium;
state.ActivatedByGeometry = activatedByGeometry;
state.ChargeSource = chargeSource;
end

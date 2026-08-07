function pairs = computeGeometryPairs(analysis, cfg)
%COMPUTEGEOMETRYPAIRS Broad phase plus exact finite-cylinder GJK distances.
%   No periodic images are created here.

pairs.PieceA = zeros(0, 1);
pairs.PieceB = zeros(0, 1);
pairs.AxisDistance = zeros(0, 1);
pairs.CapsuleDistance = zeros(0, 1);
pairs.ExactDistance = zeros(0, 1);
pairs.GJKConverged = false(0, 1);

next = 0;
for pieceA = 1:(analysis.Records - 1)
    for pieceB = (pieceA + 1):analysis.Records
        axisDistance = segmentSegmentDistance(analysis.P1(pieceA, :), ...
            analysis.P2(pieceA, :), analysis.P1(pieceB, :), ...
            analysis.P2(pieceB, :));
        if axisDistance > cfg.broadPhaseDistance
            continue;
        end
        [exactDistance, ~, ~, ~, converged] = gjkCylinderDistance( ...
            analysis.P1(pieceA, :), analysis.P2(pieceA, :), cfg.mediumARadius, ...
            analysis.P1(pieceB, :), analysis.P2(pieceB, :), cfg.mediumARadius, ...
            cfg.gjkTolerance, cfg.gjkMaxIterations);
        if ~converged
            error('computeGeometryPairs:GJKNotConverged', ...
                'GJK did not converge for Piece %d and Piece %d.', pieceA, pieceB);
        end
        next = next + 1;
        pairs.PieceA(next, 1) = pieceA;
        pairs.PieceB(next, 1) = pieceB;
        pairs.AxisDistance(next, 1) = axisDistance;
        pairs.CapsuleDistance(next, 1) = axisDistance - 2 * cfg.mediumARadius;
        pairs.ExactDistance(next, 1) = exactDistance;
        pairs.GJKConverged(next, 1) = converged;
    end
end
end

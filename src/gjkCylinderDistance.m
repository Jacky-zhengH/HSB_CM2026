function [distance, closestPointA, closestPointB, iterations, converged] = ...
        gjkCylinderDistance(p1A, p2A, radiusA, p1B, p2B, radiusB, tolerance, maxIterations)
%GJKCYLINDERDISTANCE Distance between two solid finite flat-ended cylinders.
%   Uses GJK support mapping and an exhaustive closest-simplex reducer.

if nargin < 7 || isempty(tolerance)
    tolerance = 1e-9;
end
if nargin < 8 || isempty(maxIterations)
    maxIterations = 100;
end

centerA = (p1A + p2A) / 2;
centerB = (p1B + p2B) / 2;
direction = centerB - centerA;
if norm(direction) <= tolerance
    direction = [1 0 0];
end

[w, supportA, supportB] = minkowskiSupport(direction, ...
    p1A, p2A, radiusA, p1B, p2B, radiusB);
simplexW = w;
simplexA = supportA;
simplexB = supportB;
[closest, weights, active] = closestSimplex(simplexW);
simplexW = simplexW(active, :);
simplexA = simplexA(active, :);
simplexB = simplexB(active, :);
weights = weights(active);
converged = false;

for iterations = 1:maxIterations
    distanceSquared = dot(closest, closest);
    if distanceSquared <= tolerance^2
        distance = 0;
        closestPointA = weights' * simplexA;
        closestPointB = weights' * simplexB;
        converged = true;
        return;
    end

    direction = -closest;
    [newW, newA, newB] = minkowskiSupport(direction, ...
        p1A, p2A, radiusA, p1B, p2B, radiusB);
    improvement = distanceSquared - dot(closest, newW);
    scale = max(1, distanceSquared);
    if improvement <= tolerance * scale
        distance = sqrt(distanceSquared);
        closestPointA = weights' * simplexA;
        closestPointB = weights' * simplexB;
        converged = true;
        return;
    end

    if any(sqrt(sum(bsxfun(@minus, simplexW, newW).^2, 2)) <= tolerance)
        distance = sqrt(distanceSquared);
        closestPointA = weights' * simplexA;
        closestPointB = weights' * simplexB;
        converged = true;
        return;
    end

    simplexW(end + 1, :) = newW;
    simplexA(end + 1, :) = newA;
    simplexB(end + 1, :) = newB;
    [closest, allWeights, active] = closestSimplex(simplexW);
    simplexW = simplexW(active, :);
    simplexA = simplexA(active, :);
    simplexB = simplexB(active, :);
    weights = allWeights(active);
end

distance = norm(closest);
closestPointA = weights' * simplexA;
closestPointB = weights' * simplexB;
end

function [w, pointA, pointB] = minkowskiSupport(direction, ...
        p1A, p2A, radiusA, p1B, p2B, radiusB)
pointA = cylinderSupport(p1A, p2A, radiusA, direction);
pointB = cylinderSupport(p1B, p2B, radiusB, -direction);
w = pointA - pointB;
end

function [closest, weights, active] = closestSimplex(points)
% A standard 3-D simplex has at most four points. During a degenerate update
% it can temporarily contain the old four points plus one new support point;
% Caratheodory's theorem guarantees the closest point still has a
% representation using at most four of them.
pointCount = size(points, 1);
if pointCount > 5
    error('gjkCylinderDistance:SimplexTooLarge', ...
        'Temporary GJK candidate set exceeded five points.');
end
bestDistanceSquared = Inf;
bestWeights = zeros(pointCount, 1);
feasibilityTolerance = 1e-11;

for mask = 1:(2^pointCount - 1)
    indices = find(bitget(mask, 1:pointCount));
    if numel(indices) > 4
        continue;
    end
    subset = points(indices, :);
    subsetCount = numel(indices);
    gram = subset * subset';
    system = [2 * gram ones(subsetCount, 1); ...
        ones(1, subsetCount) 0];
    rhs = [zeros(subsetCount, 1); 1];
    if rcond(system) > 1e-14
        solution = system \ rhs;
    else
        solution = pinv(system) * rhs;
    end
    lambda = solution(1:subsetCount);
    if any(lambda < -feasibilityTolerance)
        continue;
    end
    lambda(lambda < 0) = 0;
    if sum(lambda) <= 0
        continue;
    end
    lambda = lambda / sum(lambda);
    candidate = lambda' * subset;
    candidateDistanceSquared = dot(candidate, candidate);
    if candidateDistanceSquared < bestDistanceSquared
        bestDistanceSquared = candidateDistanceSquared;
        bestWeights = zeros(pointCount, 1);
        bestWeights(indices) = lambda;
    end
end

if ~isfinite(bestDistanceSquared)
    error('gjkCylinderDistance:SimplexFailure', ...
        'Could not find a feasible closest point on the GJK simplex.');
end
active = bestWeights > 1e-12;
if ~any(active)
    [~, largest] = max(bestWeights);
    active(largest) = true;
end
weights = bestWeights;
weights(~active) = 0;
weights = weights / sum(weights);
closest = weights' * points;
end

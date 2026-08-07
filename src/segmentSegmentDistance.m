function [distance, s, t, closestPointA, closestPointB] = ...
        segmentSegmentDistance(p1, p2, q1, q2)
%SEGMENTSEGMENTDISTANCE Shortest distance between two finite 3-D segments.

u = p2 - p1;
v = q2 - q1;
w = p1 - q1;
a = dot(u, u);
b = dot(u, v);
c = dot(v, v);
d = dot(u, w);
e = dot(v, w);
small = 1e-14 * max([1 a c]);

if a <= small && c <= small
    s = 0;
    t = 0;
elseif a <= small
    s = 0;
    t = clamp01(e / c);
elseif c <= small
    t = 0;
    s = clamp01(-d / a);
else
    denominator = a * c - b * b;
    if denominator > small * max(a, c)
        s = clamp01((b * e - c * d) / denominator);
    else
        s = 0;
    end
    t = (b * s + e) / c;
    if t < 0
        t = 0;
        s = clamp01(-d / a);
    elseif t > 1
        t = 1;
        s = clamp01((b - d) / a);
    end
end

closestPointA = p1 + s * u;
closestPointB = q1 + t * v;
distance = norm(closestPointA - closestPointB);
end

function value = clamp01(value)
value = max(0, min(1, value));
end

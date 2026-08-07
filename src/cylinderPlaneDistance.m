function [leftDistance, rightDistance] = cylinderPlaneDistance(p1, p2, radius, halfBox)
%CYLINDERPLANEDISTANCE Exact support-based distance to x boundary planes.

axisVector = p2 - p1;
lengthValue = norm(axisVector);
u = axisVector / lengthValue;
center = (p1 + p2) / 2;
halfLength = lengthValue / 2;
xExtent = halfLength * abs(u(1)) + radius * sqrt(max(0, 1 - u(1)^2));
minimumX = center(1) - xExtent;
maximumX = center(1) + xExtent;
leftDistance = max(0, minimumX + halfBox);
rightDistance = max(0, halfBox - maximumX);
end

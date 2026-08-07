function point = cylinderSupport(p1, p2, radius, direction)
%CYLINDERSUPPORT Support point of a solid finite flat-ended cylinder.

axisVector = p2 - p1;
lengthValue = norm(axisVector);
if lengthValue <= 0
    error('cylinderSupport:ZeroLength', 'Cylinder axis length must be positive.');
end
u = axisVector / lengthValue;
center = (p1 + p2) / 2;
halfLength = lengthValue / 2;
axialDot = dot(direction, u);
if axialDot > 0
    axial = halfLength * u;
elseif axialDot < 0
    axial = -halfLength * u;
else
    axial = [0 0 0];
end
perpendicular = direction - axialDot * u;
perpendicularNorm = norm(perpendicular);
if perpendicularNorm > 10 * eps * max(1, norm(direction))
    radial = radius * perpendicular / perpendicularNorm;
else
    radial = [0 0 0];
end
point = center + axial + radial;
end

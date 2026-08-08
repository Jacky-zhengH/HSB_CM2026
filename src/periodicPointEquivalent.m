function [equivalent, maximumError] = periodicPointEquivalent( ...
        pointA, pointB, boxLength, tolerance)
%PERIODICPOINTEQUIVALENT Test equality modulo integer box translations.

difference = pointA - pointB;
residual = difference - boxLength * round(difference / boxLength);
maximumError = max(abs(residual));
equivalent = maximumError <= tolerance;
end

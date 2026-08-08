function fontName = getChineseFontName()
%GETCHINESEFONTNAME Select one of four known Chinese fonts only once.

candidates = {'Microsoft YaHei','SimHei','SimSun','NSimSun'};
fontName = get(0, 'DefaultAxesFontName');
try
    installed = listfonts;
    for index = 1:numel(candidates)
        if any(strcmpi(installed, candidates{index}))
            fontName = candidates{index};
            return;
        end
    end
catch
    % Retain the current MATLAB default if font enumeration is unavailable.
end
end

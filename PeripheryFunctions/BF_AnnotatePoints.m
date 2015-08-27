function BF_AnnotatePoints(xy,TimeSeries,annotateParams);
% BF_AnnotatePoints     Annotates time series/metadata to a plot
%
%---INPUTS:
% xy, a vector (or cell) of x-y co-ordinates of points on the plot
% TimeSeries, a structure array of time series making up the plot
% annotateParams, structure of custom plotting parameters

% ------------------------------------------------------------------------------
% Copyright (C) 2015, Ben D. Fulcher <ben.d.fulcher@gmail.com>,
% <http://www.benfulcher.com>
%
% If you use this code for your research, please cite:
% B. D. Fulcher, M. A. Little, N. S. Jones, "Highly comparative time-series
% analysis: the empirical structure of time series and their methods",
% J. Roy. Soc. Interface 10(83) 20130048 (2010). DOI: 10.1098/rsif.2013.0048
%
% This work is licensed under the Creative Commons
% Attribution-NonCommercial-ShareAlike 4.0 International License. To view a copy of
% this license, visit http://creativecommons.org/licenses/by-nc-sa/4.0/ or send
% a letter to Creative Commons, 444 Castro Street, Suite 900, Mountain View,
% California, 94041, USA.
% ------------------------------------------------------------------------------

numTimeSeries = length(TimeSeries);

% ------------------------------------------------------------------------------
%% Set default plotting parameters:
% ------------------------------------------------------------------------------
if isfield(annotateParams,'n')
    numAnnotate = annotateParams.n;
else
    numAnnotate = min(6,numTimeSeries);
end
if isfield(annotateParams,'maxL')
    maxL = annotateParams.maxL;
else
    maxL = 300; % length of annotated time series segments
end
if isfield(annotateParams,'userInput')
    userInput = annotateParams.userInput;
else
    userInput = 1; % user input points rather than randomly chosen
end
if isfield(annotateParams,'fdim')
    fdim = annotateParams.fdim;
else
    fdim = [0.30,0.08]; % width, height
end
if isfield(annotateParams,'textAnnotation')
    textAnnotation = annotateParams.textAnnotation; % 'Name','tsid','none'
else
    textAnnotation = 'none'; % no annotations by default
end
if isfield(annotateParams,'theLineWidth')
    theLineWidth = annotateParams.theLineWidth;
else
    theLineWidth = 0.8; % % line width for time series
end

plotCircle = 1; % circle around annotated points

%-------------------------------------------------------------------------------

% Want on a common scale for finding neighbors:
xy_std = std(xy);
xy_mean = mean(xy);
xy_zscore = zscore(xy);

% Initializing basic parameters/variables:
pxlim = get(gca,'xlim'); % plot limits
pylim = get(gca,'ylim'); % plot limits
pWidth = diff(pxlim); % plot width
pHeight = diff(pylim); % plot height
alreadyPicked = zeros(numAnnotate,1); % record those already picked

% Groups:
if isfield(TimeSeries,'Group')
    numGroups = length(unique([TimeSeries.Group]));
else
    numGroups = 1;
end

% Colors:
myColors = [BF_getcmap('set1',5,1);BF_getcmap('dark2',6,1)];
if ~isfield(annotateParams,'groupColors')
    groupColors = GiveMeGroupColors(annotateParams,numGroups); % Set colors
else
    groupColors = annotateParams.groupColors;
end

%-------------------------------------------------------------------------------
% Don't use user input to select points to annotate: instead they are selected randomly
%-------------------------------------------------------------------------------
if ~userInput
    % random set:
    rp = randperm(numTimeSeries);
    alreadyPicked = rp(1:numAnnotate);
end

% ------------------------------------------------------------------------------
% Go through and annotate selected points
%-------------------------------------------------------------------------------
fprintf(1,['Annotating time series segments to %u points in the plot, ' ...
                    'displaying %u samples from each...\n'],numAnnotate,maxL);

for j = 1:numAnnotate
    title(sprintf('%u points remaining to annotate',numAnnotate-j+1));

    % Get user to pick a point, then find closest datapoint to their input:
    if userInput % user input
        point = ginput(1);
        point_z = (point-xy_mean)./xy_std;
        iPlot = BF_ClosestPoint_ginput(xy_zscore,point_z);
        alreadyPicked(j) = iPlot;
    else
        iPlot = alreadyPicked(j);
    end

    % (x,y) co-ords of the point to plot:
    plotPoint = xy(iPlot,:);

    % Get the group index of the selected time series:
    theGroup = TimeSeries(iPlot).Group;

    if (j > 1) && any(sum(abs(alreadyPicked(1:j-1,:) - repmat(alreadyPicked(j,:),j-1,1)),2)==0)
        % Same one has already been picked, don't plot it again
        continue
    end

    % Crop the time series:
    if ~isempty(maxL)
        timeSeriesSegment = TimeSeries(iPlot).Data(1:min(maxL,end));
    end

    % Plot a circle around the annotated point:
    if numGroups==1
        % cycle through rainvow colors sequentially:
        groupColors{1} = myColors{rem(j,length(myColors))};
    end
    if plotCircle
        plot(plotPoint(1),plotPoint(2),'o','MarkerEdgeColor',groupColors{theGroup},...
                            'MarkerFaceColor',brighten(groupColors{theGroup},0.5));
    end

    % Add text annotations:
    switch textAnnotation
    case 'name'
        % Annotate text with names of datapoints:
        text(plotPoint(1),plotPoint(2)-0.01*pHeight,TimeSeries(iPlot).Name,...
                    'interpreter','none','FontSize',8,...
                    'color',brighten(groupColors{theGroup},-0.6));
    case 'ID'
        % Annotate text with ts_id:
        text(plotPoint(1),plotPoint(2)-0.01*pHeight,...
                num2str(TimeSeries(iPlot).ID),...
                    'interpreter','none','FontSize',8,...
                    'color',brighten(groupColors{theGroup},-0.6));
    case 'length'
        text(plotPoint(1),plotPoint(2)-0.01*pHeight,...
                num2str(length(TimeSeries(iPlot).Data),...
                'interpreter','none','FontSize',8,...
                'color',brighten(groupColors{theGroup},-0.6)));
    end

    % Adjust if annotation goes off axis x-limits
    px = plotPoint(1)+[-fdim(1)*pWidth/2,+fdim(1)*pWidth/2];
    if px(1) < pxlim(1), px(1) = pxlim(1); end % can't plot off left side of plot
    if px(2) > pxlim(2), px(1) = pxlim(2)-fdim(1)*pWidth; end % can't plot off right side of plot

    % Adjust if annotation goes above maximum y-limits
    py = plotPoint(2)+[0,fdim(2)*pHeight];
    if py(2) > pylim(2)
        py(1) = pylim(2)-fdim(2)*pHeight;
    end

    % Annotate the time series
    plot(px(1)+linspace(0,fdim(1)*pWidth,length(timeSeriesSegment)),...
            py(1)+fdim(2)*pHeight*(timeSeriesSegment-min(timeSeriesSegment))/(max(timeSeriesSegment)-min(timeSeriesSegment)),...
                '-','color',groupColors{theGroup},'LineWidth',theLineWidth);

end


%-------------------------------------------------------------------------------
function groupColors = GiveMeGroupColors(annotateParams,numGroups) % Set colors
    if isstruct(annotateParams) && isfield(annotateParams,'cmap')
        if ischar(annotateParams.cmap)
            groupColors = BF_getcmap(annotateParams.cmap,numGroups,1);
        else
            groupColors = annotateParams.cmap; % specify the cell itself
        end
    else
        if numGroups < 10
            groupColors = BF_getcmap('set1',numGroups,1);
        elseif numGroups <= 12
            groupColors = BF_getcmap('set3',numGroups,1);
        elseif numGroups <= 22
            groupColors = [BF_getcmap('set1',numGroups,1); ...
                        BF_getcmap('set3',numGroups,1)];
        elseif numGroups <= 50
            groupColors = mat2cell(jet(numGroups),ones(numGroups,1));
        else
            error('There aren''t enough colors in the rainbow to plot this many classes!')
        end
    end
    if (numGroups == 1)
        groupColors = {'k'}; % Just use black...
    end
end
%-------------------------------------------------------------------------------

end

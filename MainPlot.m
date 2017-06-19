function DataFig = MainPlot(Action, Data, DataFig, varargin)

global nTrialsToShow %this is for convenience
global BpodSystem
global TaskParameters

switch Action
    case 'init'
        DataFig = MainPlotInit;      
    case 'update'
        narginchk(2,4)
        if ~exist('DataFig','var') || isempty('DataFig')
            DataFig = MainPlotInit;
        end
        if ~exist('DataFig','var') || isempty('DataFig')
            nTrialsToShow = varargin{1};
        else
            nTrialsToShow = 90;
        end
        % Outcome
        iTrial = Data.nTrials+1;
        [mn, ~] = rescaleX(DataFig.Axes.OutcomePlot.MainHandle,iTrial,nTrialsToShow); % recompute xlim
        
        set(DataFig.Axes.OutcomePlot.CurrentTrialCircle, 'xdata', iTrial, 'ydata', 0.5);
        set(DataFig.Axes.OutcomePlot.CurrentTrialCross, 'xdata', iTrial, 'ydata', 0.5);
        
        %Plot past trials
        ChoiceLeft = Data.Custom.ChoiceLeft;
        Rewarded = Data.Custom.Rewarded;
        if ~isempty(Rewarded)
            indxToPlot = mn:iTrial-1;
            
            ndxRwd = Rewarded(indxToPlot) == 1;
            Xdata = indxToPlot(ndxRwd);
            Ydata = ChoiceLeft(indxToPlot); Ydata = Ydata(ndxRwd);
            set(DataFig.Axes.OutcomePlot.Rewarded, 'xdata', Xdata, 'ydata', Ydata);
            
            ndxUrwd = Rewarded(indxToPlot) == 0 & not(Data.Custom.EarlyCout(indxToPlot)|Data.Custom.EarlySout(indxToPlot));
            Xdata = indxToPlot(ndxUrwd);
            Ydata = ChoiceLeft(indxToPlot); Ydata = Ydata(ndxUrwd);
            set(DataFig.Axes.OutcomePlot.Unrewarded, 'xdata', Xdata, 'ydata', Ydata);

            ndxNocho = isnan(ChoiceLeft(indxToPlot)) & ~Data.Custom.EarlyCout(indxToPlot);
            Xdata = indxToPlot(ndxNocho);
            Ydata = ones(size(Xdata))*.5;
            set(DataFig.Axes.OutcomePlot.NoResponse, 'xdata', Xdata, 'ydata', Ydata);
            
            Ydata = [ones(sum(Data.Custom.Baited.Left(indxToPlot)),1)', zeros(sum(Data.Custom.Baited.Right(indxToPlot)),1)'];
            Xdata = [indxToPlot(Data.Custom.Baited.Left(indxToPlot)), indxToPlot(Data.Custom.Baited.Right(indxToPlot))];
            set(DataFig.Axes.OutcomePlot.Bait, 'xdata', Xdata, 'ydata', Ydata);

            Ydata = .5+log10(Data.Custom.CumpL(indxToPlot)./Data.Custom.CumpR(indxToPlot));
            Xdata = indxToPlot;
            set(DataFig.Axes.OutcomePlot.LogOdds, 'xdata', Xdata, 'ydata', Ydata);
        end
        if ~isempty(Data.Custom.EarlyCout)
            indxToPlot = mn:iTrial-1;
            ndxEarly = Data.Custom.EarlyCout(indxToPlot);
            XData = indxToPlot(ndxEarly);
            YData = 0.5*ones(1,sum(ndxEarly));
            set(DataFig.Axes.OutcomePlot.EarlyCout, 'xdata', XData, 'ydata', YData);
        end
        if ~isempty(Data.Custom.EarlySout)
            indxToPlot = mn:iTrial-1;
            ndxEarly = Data.Custom.EarlySout(indxToPlot);
            XData = indxToPlot(ndxEarly);
            YData = ChoiceLeft(indxToPlot); YData = YData(ndxEarly);
            set(DataFig.Axes.OutcomePlot.EarlySout, 'xdata', XData, 'ydata', YData);
        end
        %Cumulative Reward Amount
        R = Data.Custom.RewardMagnitude;
        ndxRwd = Data.Custom.Rewarded;
        C = zeros(size(R)); C(Data.Custom.ChoiceLeft==1&ndxRwd,1) = 1; C(Data.Custom.ChoiceLeft==0&ndxRwd,2) = 1;
        R = R.*C;
        set(DataFig.Axes.OutcomePlot.CumRwd, 'position', [iTrial+1 1], 'string', ...
            [num2str(sum(R(:))/1000) ' mL']);
        clear R C
        
        %% Trial rate
        DataFig.Axes.TrialRate.TrialRate.XData = (Data.TrialStartTimestamp-min(Data.TrialStartTimestamp))/60;
        DataFig.Axes.TrialRate.TrialRate.YData = 1:numel(DataFig.Axes.TrialRate.TrialRate.XData);
        
        %% Stimulus delay
        cla(DataFig.Axes.SampleTimes.MainHandle)
        DataFig.Axes.SampleTimes.Hist = histogram(DataFig.Axes.SampleTimes.MainHandle,...
            Data.Custom.SampleTime(~Data.Custom.EarlyCout)*1000);
        DataFig.Axes.SampleTimes.Hist.BinWidth = 50;
        DataFig.Axes.SampleTimes.Hist.EdgeColor = 'none';
        DataFig.Axes.SampleTimes.HistEarly = histogram(DataFig.Axes.SampleTimes.MainHandle,...
            Data.Custom.SampleTime(Data.Custom.EarlyCout)*1000);
        DataFig.Axes.SampleTimes.HistEarly.BinWidth = 50;
        DataFig.Axes.SampleTimes.HistEarly.EdgeColor = 'none';
        DataFig.Axes.SampleTimes.CutOff = plot(DataFig.Axes.SampleTimes.MainHandle,TaskParameters.GUI.SampleTime*1000,0,'^k');
        
        %% Feedback delay
        cla(DataFig.Axes.FeedbackTimes.MainHandle)
        DataFig.Axes.FeedbackTimes.Hist = histogram(DataFig.Axes.FeedbackTimes.MainHandle,Data.Custom.FeedbackTime*1000);
        DataFig.Axes.FeedbackTimes.Hist.BinWidth = 50;
        DataFig.Axes.FeedbackTimes.Hist.EdgeColor = 'none';
        DataFig.Axes.FeedbackTimes.HistEarly = histogram(DataFig.Axes.FeedbackTimes.MainHandle,...
            Data.Custom.FeedbackTime(Data.Custom.EarlySout)*1000);
        DataFig.Axes.FeedbackTimes.HistEarly.BinWidth = 50;
        DataFig.Axes.FeedbackTimes.HistEarly.EdgeColor = 'none';
        DataFig.Axes.FeedbackTimes.CutOff = plot(DataFig.Axes.FeedbackTimes.MainHandle,TaskParameters.GUI.FeedbackTime*1000,0,'^k');
        
end

end

function [mn,mx] = rescaleX(AxesHandle,CurrentTrial,nTrialsToShow)
FractionWindowStickpoint = .75; % After this fraction of visible trials, the trial position in the window "sticks" and the window begins to slide through trials.
mn = max(round(CurrentTrial - FractionWindowStickpoint*nTrialsToShow),1);
mx = mn + nTrialsToShow - 1;
set(AxesHandle,'XLim',[mn-1 mx+1]);
end

function GUIHandles = MainPlotInit
GUIHandles.Figs.MainFig = figure('Position', [200, 200, 1000, 400],'name','Outcome plot','numbertitle','off', 'MenuBar', 'none', 'Resize', 'off');
GUIHandles.Axes.OutcomePlot.MainHandle = axes('Position', [.06 .15 .91 .3]);
GUIHandles.Axes.TrialRate.MainHandle = axes('Position', [[1 0]*[.06;.12] .6 .12 .3]);
GUIHandles.Axes.SampleTimes.MainHandle = axes('Position', [[2 1]*[.06;.12] .6 .12 .3]);
GUIHandles.Axes.FeedbackTimes.MainHandle = axes('Position', [[3 2]*[.06;.12] .6 .12 .3]);

%% Outcome
nTrialsToShow = 90; %default number of trials to display
axes(GUIHandles.Axes.OutcomePlot.MainHandle)
GUIHandles.Axes.OutcomePlot.Bait = line(-1,1, 'LineStyle','none','Marker','o','MarkerEdge','g','MarkerFace','none', 'MarkerSize',8);
GUIHandles.Axes.OutcomePlot.CurrentTrialCircle = line(-1,0.5, 'LineStyle','none','Marker','o','MarkerEdge','k','MarkerFace',[1 1 1], 'MarkerSize',6);
GUIHandles.Axes.OutcomePlot.CurrentTrialCross = line(-1,0.5, 'LineStyle','none','Marker','+','MarkerEdge','k','MarkerFace',[1 1 1], 'MarkerSize',6);
GUIHandles.Axes.OutcomePlot.Rewarded = line(-1,1, 'LineStyle','none','Marker','o','MarkerEdge','g','MarkerFace','g', 'MarkerSize',6);
GUIHandles.Axes.OutcomePlot.Unrewarded = line(-1,1, 'LineStyle','none','Marker','o','MarkerEdge','r','MarkerFace','r', 'MarkerSize',6);
GUIHandles.Axes.OutcomePlot.NoResponse = line(-1,1, 'LineStyle','none','Marker','o','MarkerEdge','b','MarkerFace','none', 'MarkerSize',6);
GUIHandles.Axes.OutcomePlot.EarlyCout = line(-1,0, 'LineStyle','none','Marker','d','MarkerEdge','none','MarkerFace','b', 'MarkerSize',6);
GUIHandles.Axes.OutcomePlot.EarlySout = line(-1,0, 'LineStyle','none','Marker','d','MarkerEdge','none','MarkerFace','b', 'MarkerSize',6);
GUIHandles.Axes.OutcomePlot.LogOdds = line([0 1],[0 1], 'LineStyle','-','Color','k');
GUIHandles.Axes.OutcomePlot.CumRwd = text(1,1,'0mL','verticalalignment','bottom','horizontalalignment','center');
set(GUIHandles.Axes.OutcomePlot.MainHandle,'TickDir', 'out','YLim', [-1, 2],'XLim',[0,nTrialsToShow], 'YTick', [0 1],'YTickLabel', {'Right','Left'}, 'FontSize', 16);
xlabel(GUIHandles.Axes.OutcomePlot.MainHandle, 'Trial#', 'FontSize', 18);
hold(GUIHandles.Axes.OutcomePlot.MainHandle, 'on');
%% Trial rate
hold(GUIHandles.Axes.TrialRate.MainHandle,'on')
GUIHandles.Axes.TrialRate.TrialRate = line(GUIHandles.Axes.TrialRate.MainHandle,[0],[0], 'LineStyle','-','Color','k','Visible','on');
GUIHandles.Axes.TrialRate.MainHandle.XLabel.String = 'Time (min)';
GUIHandles.Axes.TrialRate.MainHandle.YLabel.String = 'nTrials';
GUIHandles.Axes.TrialRate.MainHandle.Title.String = 'Trial rate';
%% ST histogram
hold(GUIHandles.Axes.SampleTimes.MainHandle,'on')
GUIHandles.Axes.SampleTimes.MainHandle.XLabel.String = 'Time (s)';
GUIHandles.Axes.SampleTimes.MainHandle.YLabel.String = 'trial counts';
GUIHandles.Axes.SampleTimes.MainHandle.Title.String = 'Center port WT';
%% FT histogram
hold(GUIHandles.Axes.FeedbackTimes.MainHandle,'on')
GUIHandles.Axes.FeedbackTimes.MainHandle.XLabel.String = 'Time (s)';
GUIHandles.Axes.FeedbackTimes.MainHandle.YLabel.String = 'trial counts';
GUIHandles.Axes.FeedbackTimes.MainHandle.Title.String = 'Side port WT';
end
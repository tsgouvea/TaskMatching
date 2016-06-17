%{
----------------------------------------------------------------------------

This file is part of the Bpod Project
Copyright (C) 2015 Joshua I. Sanders, Cold Spring Harbor Laboratory, NY, USA

----------------------------------------------------------------------------

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, version 3.

This program is distributed  WITHOUT ANY WARRANTY and without even the
implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
%}
% function OutcomePlot(AxesHandle,TrialTypeSides, OutcomeRecord, CurrentTrial)
function Matching_PlotSideOutcome(AxesHandles, Action, varargin)
%%
% Plug in to Plot reward side and trial outcome.
% For non-sided trial types, use the TrialTypeOutcomePlot plugin.
% AxesHandle = handle of axes to plot on
% Action = specific action for plot, "init" - initialize OR "update" -  update plot

%Example usage:
% SideOutcomePlot(AxesHandle,'init',TrialTypeSides)
% SideOutcomePlot(AxesHandle,'init',TrialTypeSides,'ntrials',90)
% SideOutcomePlot(AxesHandle,'update',CurrentTrial,TrialTypeSides,OutcomeRecord)

% varargins:
% TrialTypeSides: Vector of 0's (right) or 1's (left) to indicate reward side (0,1), or 'None' to plot trial types individually
% OutcomeRecord:  Vector of trial outcomes
%                 Simplest case:
%                               1: correct trial (green)
%                               0: incorrect trial (red)
%                 Advanced case:
%                               NaN: future trial (blue)
%                                -1: withdrawal (red circle)
%                                 0: incorrect choice (red dot)
%                                 1: correct choice (green dot)
%                                 2: did not choose (green circle)
% OutcomeRecord can also be empty
% Current trial: the current trial number

% Adapted from BControl (SidesPlotSection.m)
% Kachi O. 2014.Mar.17
% Josh S. 2015.Jan.24 - optimized for speed

%% Code Starts Here
global nTrialsToShow %this is for convenience
global BpodSystem

switch Action
    case 'init'
        %% Outcome
        nTrialsToShow = 90; %default number of trials to display
        
        if nargin >= 3 %custom number of trials
            nTrialsToShow =varargin{3};
        end
        axes(AxesHandles.HandleOutcome);
        %         Xdata = 1:numel(SideList); Ydata = SideList(Xdata);
        %plot in specified axes
        BpodSystem.GUIHandles.OutcomePlot.BaitL = line(-1,1,'LineStyle','none','Marker','o','MarkerEdge','g',...
            'MarkerFace','none', 'MarkerSize',8);%
        BpodSystem.GUIHandles.OutcomePlot.BaitR = line(-1,0,'LineStyle','none','Marker','o','MarkerEdge','g',...
            'MarkerFace','none', 'MarkerSize',8);
        
        BpodSystem.GUIHandles.OutcomePlot.CurrentTrialCircle = line(1,0.5, 'LineStyle','none','Marker','o','MarkerEdge','k','MarkerFace',[1 1 1], 'MarkerSize',6);
        BpodSystem.GUIHandles.OutcomePlot.CurrentTrialCross = line(1,0.5, 'LineStyle','none','Marker','+','MarkerEdge','k','MarkerFace',[1 1 1], 'MarkerSize',6);
        BpodSystem.GUIHandles.OutcomePlot.RewardedL = line(-1,1, 'LineStyle','none','Marker','o','MarkerEdge','g','MarkerFace','g', 'MarkerSize',6);
        BpodSystem.GUIHandles.OutcomePlot.RewardedR = line(-1,0, 'LineStyle','none','Marker','o','MarkerEdge','g','MarkerFace','g', 'MarkerSize',6);
        BpodSystem.GUIHandles.OutcomePlot.UnrewardedL = line(-1,1, 'LineStyle','none','Marker','o','MarkerEdge','r','MarkerFace','r', 'MarkerSize',6);
        BpodSystem.GUIHandles.OutcomePlot.UnrewardedR = line(-1,0, 'LineStyle','none','Marker','o','MarkerEdge','r','MarkerFace','r', 'MarkerSize',6);
        BpodSystem.GUIHandles.OutcomePlot.NoResponseL = line(-1,1, 'LineStyle','none','Marker','o','MarkerEdge','b','MarkerFace','none', 'MarkerSize',6);
        BpodSystem.GUIHandles.OutcomePlot.NoResponseR = line(-1,0, 'LineStyle','none','Marker','o','MarkerEdge','b','MarkerFace','none', 'MarkerSize',6);
        BpodSystem.GUIHandles.OutcomePlot.BrokeFix = line(-1,0.5, 'LineStyle','none','Marker','d','MarkerEdge','b','MarkerFace','none', 'MarkerSize',6);
        BpodSystem.GUIHandles.OutcomePlot.LogOdds = line([0 1],[0 1], 'LineStyle','-','Color','k');
        set(AxesHandles.HandleOutcome,'TickDir', 'out','XLim',[0, nTrialsToShow],'YLim', [-1, 2], 'YTick', [0 1],'YTickLabel', {'Right','Left'}, 'FontSize', 16);
        xlabel(AxesHandles.HandleOutcome, 'Trial#', 'FontSize', 18);
        hold(AxesHandles.HandleOutcome, 'on');
        %% Waiting times
        hold(AxesHandles.HandleWait,'on')
        AxesHandles.HandleWait.XLabel.String = 'Time (s)';
        AxesHandles.HandleWait.YLabel.String = 'nTrials';
        AxesHandles.HandleWait.Title.String = 'Waiting time';
        %% Trial rate
        hold(AxesHandles.HandleTrialRate,'on')
        BpodSystem.GUIHandles.OutcomePlot.TrialRate = line(AxesHandles.HandleTrialRate,[0],[0], 'LineStyle','-','Color','k');
        AxesHandles.HandleTrialRate.XLabel.String = 'Time (s)'; % FIGURE OUT UNIT
        AxesHandles.HandleTrialRate.YLabel.String = 'nTrials';
        AxesHandles.HandleTrialRate.Title.String = 'Trial rate';
    case 'update'
        %% Outcome
        CurrentTrial = varargin{1};
        Baited = BpodSystem.Data.Custom.Baited;
        OutcomeRecord = BpodSystem.Data.Custom.OutcomeRecord;
        
        % recompute xlim
        [mn, mx] = rescaleX(AxesHandles.HandleOutcome,CurrentTrial,nTrialsToShow);
        
        %axes(AxesHandle); %cla;
        %plot future trials
        if any(Baited.Left)
            set(BpodSystem.GUIHandles.OutcomePlot.BaitL,'xdata',find(Baited.Left),'ydata',ones(1,sum(Baited.Left)));
        end
        if any(Baited.Right)
            set(BpodSystem.GUIHandles.OutcomePlot.BaitR,'xdata',find(Baited.Right),'ydata',zeros(1,sum(Baited.Right)));
        end
        
        %         FutureTrialsIndx = CurrentTrial:mx;
        %         Xdata = FutureTrialsIndx; Ydata = SideList(Xdata);
        %         set(BpodSystem.GUIHandles.OutcomePlot.FutureTrialLine, 'xdata', [Xdata,Xdata], 'ydata', [Ydata,Ydata]);
        %Plot current trial
        set(BpodSystem.GUIHandles.OutcomePlot.CurrentTrialCircle, 'xdata', CurrentTrial, 'ydata', .5);
        set(BpodSystem.GUIHandles.OutcomePlot.CurrentTrialCross, 'xdata', CurrentTrial, 'ydata', .5);
        
        %Plot past trials
        if ~isempty(OutcomeRecord)
            indxToPlot = mn:CurrentTrial-1;
            %Plot Rewarded Left
            ndxRwdL = OutcomeRecord(indxToPlot) == find(strcmp('rewarded_Lin',BpodSystem.Data.RawData.OriginalStateNamesByNumber{end}));
            Xdata = indxToPlot(ndxRwdL); Ydata = ones(1,sum(ndxRwdL));
            set(BpodSystem.GUIHandles.OutcomePlot.RewardedL, 'xdata', Xdata, 'ydata', Ydata);
            %Plot Rewarded Right
            ndxRwdR = OutcomeRecord(indxToPlot) == find(strcmp('rewarded_Rin',BpodSystem.Data.RawData.OriginalStateNamesByNumber{end}));
            Xdata = indxToPlot(ndxRwdR); Ydata = zeros(1,sum(ndxRwdR));
            set(BpodSystem.GUIHandles.OutcomePlot.RewardedR, 'xdata', Xdata, 'ydata', Ydata);
            %Plot Unrewarded Left
            ndxUrdL = OutcomeRecord(indxToPlot) == find(strcmp('unrewarded_Lin',BpodSystem.Data.RawData.OriginalStateNamesByNumber{end}));
            Xdata = indxToPlot(ndxUrdL); Ydata = ones(1,sum(ndxUrdL));
            set(BpodSystem.GUIHandles.OutcomePlot.UnrewardedL, 'xdata', Xdata, 'ydata', Ydata);
            %Plot Unrewarded Right
            ndxUrdR = OutcomeRecord(indxToPlot) == find(strcmp('unrewarded_Rin',BpodSystem.Data.RawData.OriginalStateNamesByNumber{end}));
            Xdata = indxToPlot(ndxUrdR); Ydata = zeros(1,sum(ndxUrdR));
            set(BpodSystem.GUIHandles.OutcomePlot.UnrewardedR, 'xdata', Xdata, 'ydata', Ydata);
            %Plot Broken Fixation
            ndxBroke = OutcomeRecord(indxToPlot) == find(strcmp('broke_fixation',BpodSystem.Data.RawData.OriginalStateNamesByNumber{end}));
            Xdata = indxToPlot(ndxBroke); Ydata = ones(1,sum(ndxBroke))*.5;
            set(BpodSystem.GUIHandles.OutcomePlot.BrokeFix, 'xdata', Xdata, 'ydata', Ydata);
            %Plot LogOdds of Reward
            set(BpodSystem.GUIHandles.OutcomePlot.LogOdds, 'xdata', indxToPlot, 'ydata', .5+log10(BpodSystem.Data.Custom.CumpL(1:end-1)./BpodSystem.Data.Custom.CumpR(1:end-1)));
        end
        %% Waiting times
        cla(AxesHandles.HandleWait)
        BpodSystem.GUIHandles.OutcomePlot.HistSuccess = histogram(AxesHandles.HandleWait,BpodSystem.Data.Custom.Wait(BpodSystem.Data.Custom.TrialValid));
        BpodSystem.GUIHandles.OutcomePlot.HistSuccess.EdgeColor = 'none';
        BpodSystem.GUIHandles.OutcomePlot.HistBrokeFix = histogram(AxesHandles.HandleWait,BpodSystem.Data.Custom.BrokeFixTime(BpodSystem.Data.Custom.BrokeFix));
        BpodSystem.GUIHandles.OutcomePlot.HistBrokeFix.EdgeColor = 'none';
        %% Trial rate
        BpodSystem.GUIHandles.OutcomePlot.TrialRate.XData = (BpodSystem.Data.TrialStartTimestamp-min(BpodSystem.Data.TrialStartTimestamp));
        BpodSystem.GUIHandles.OutcomePlot.TrialRate.YData = 1:numel(BpodSystem.Data.Custom.ChoiceLeft)-1;
end

end

function [mn,mx] = rescaleX(AxesHandle,CurrentTrial,nTrialsToShow)
FractionWindowStickpoint = .75; % After this fraction of visible trials, the trial position in the window "sticks" and the window begins to slide through trials.
mn = max(round(CurrentTrial - FractionWindowStickpoint*nTrialsToShow),1);
mx = mn + nTrialsToShow - 1;
set(AxesHandle,'XLim',[mn-1 mx+1]);
end



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
function Matching_PlotSideOutcome(AxesHandle, Action, varargin)
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
        %initialize pokes plot
        Baited = varargin{1};
        
        nTrialsToShow = 90; %default number of trials to display
        
        if nargin > 3 %custom number of trials
            nTrialsToShow =varargin{3};
        end
        axes(AxesHandle);
        %         Xdata = 1:numel(SideList); Ydata = SideList(Xdata);
        %plot in specified axes
        BpodSystem.GUIHandles.BaitL = line(-1,1,'LineStyle','none','Marker','o','MarkerEdge','y',...
            'MarkerFace','none', 'MarkerSize',8);%
        BpodSystem.GUIHandles.BaitR = line(-1,0,'LineStyle','none','Marker','o','MarkerEdge','y',...
            'MarkerFace','none', 'MarkerSize',8);
        
        BpodSystem.GUIHandles.CurrentTrialCircle = line(-1,0.5, 'LineStyle','none','Marker','o','MarkerEdge','k','MarkerFace',[1 1 1], 'MarkerSize',6);
        BpodSystem.GUIHandles.CurrentTrialCross = line(-1,0.5, 'LineStyle','none','Marker','+','MarkerEdge','k','MarkerFace',[1 1 1], 'MarkerSize',6);
        BpodSystem.GUIHandles.RewardedL = line(-1,1, 'LineStyle','none','Marker','o','MarkerEdge','g','MarkerFace','g', 'MarkerSize',6);
        BpodSystem.GUIHandles.RewardedR = line(-1,0, 'LineStyle','none','Marker','o','MarkerEdge','g','MarkerFace','g', 'MarkerSize',6);
        BpodSystem.GUIHandles.UnrewardedL = line(-1,1, 'LineStyle','none','Marker','o','MarkerEdge','r','MarkerFace','r', 'MarkerSize',6);
        BpodSystem.GUIHandles.UnrewardedR = line(-1,0, 'LineStyle','none','Marker','o','MarkerEdge','r','MarkerFace','r', 'MarkerSize',6);
        BpodSystem.GUIHandles.NoResponseL = line(-1,1, 'LineStyle','none','Marker','o','MarkerEdge','b','MarkerFace','none', 'MarkerSize',6);
        BpodSystem.GUIHandles.NoResponseR = line(-1,0, 'LineStyle','none','Marker','o','MarkerEdge','b','MarkerFace','none', 'MarkerSize',6);
        BpodSystem.GUIHandles.BrokeFix = line(-1,0.5, 'LineStyle','none','Marker','d','MarkerEdge','b','MarkerFace','none', 'MarkerSize',6);
        BpodSystem.GUIHandles.LogOdds = line([0 1],[0 1], 'LineStyle','--','Color','k');
        set(AxesHandle,'TickDir', 'out','YLim', [-1, 2], 'YTick', [0 1],'YTickLabel', {'Right','Left'}, 'FontSize', 16);
        xlabel(AxesHandle, 'Trial#', 'FontSize', 18);
        hold(AxesHandle, 'on');
        
    case 'update'
        CurrentTrial = varargin{1};
        Baited = BpodSystem.Data.Custom.Baited;
        OutcomeRecord = BpodSystem.Data.Custom.OutcomeRecord;
        
        % recompute xlim
        [mn, mx] = rescaleX(AxesHandle,CurrentTrial,nTrialsToShow);
        
        %axes(AxesHandle); %cla;
        %plot future trials
        if any(Baited.Left)
            set(BpodSystem.GUIHandles.BaitL,'xdata',find(Baited.Left),'ydata',ones(1,sum(Baited.Left)));
        end
        if any(Baited.Right)
            set(BpodSystem.GUIHandles.BaitR,'xdata',find(Baited.Right),'ydata',zeros(1,sum(Baited.Right)));
        end
        
        %         FutureTrialsIndx = CurrentTrial:mx;
        %         Xdata = FutureTrialsIndx; Ydata = SideList(Xdata);
        %         set(BpodSystem.GUIHandles.FutureTrialLine, 'xdata', [Xdata,Xdata], 'ydata', [Ydata,Ydata]);
        %Plot current trial
        set(BpodSystem.GUIHandles.CurrentTrialCircle, 'xdata', CurrentTrial, 'ydata', .5);
        set(BpodSystem.GUIHandles.CurrentTrialCross, 'xdata', CurrentTrial, 'ydata', .5);
        
        %Plot past trials
        if ~isempty(OutcomeRecord)
            indxToPlot = mn:CurrentTrial-1;
            %Plot Rewarded Left
            ndxRwdL = OutcomeRecord(indxToPlot) == 4;
            Xdata = indxToPlot(ndxRwdL); Ydata = ones(1,sum(ndxRwdL));
            set(BpodSystem.GUIHandles.RewardedL, 'xdata', Xdata, 'ydata', Ydata);
            %Plot Rewarded Right
            ndxRwdR = OutcomeRecord(indxToPlot) == 5;
            Xdata = indxToPlot(ndxRwdR); Ydata = zeros(1,sum(ndxRwdR));
            set(BpodSystem.GUIHandles.RewardedR, 'xdata', Xdata, 'ydata', Ydata);
            %Plot Unrewarded Left
            ndxUrdL = OutcomeRecord(indxToPlot) == 6;
            Xdata = indxToPlot(ndxUrdL); Ydata = ones(1,sum(ndxUrdL));
            set(BpodSystem.GUIHandles.UnrewardedL, 'xdata', Xdata, 'ydata', Ydata);
            %Plot Unrewarded Right
            ndxUrdR = OutcomeRecord(indxToPlot) == 7;
            Xdata = indxToPlot(ndxUrdR); Ydata = zeros(1,sum(ndxUrdR));
            set(BpodSystem.GUIHandles.UnrewardedR, 'xdata', Xdata, 'ydata', Ydata);
            %Plot Broken Fixation
            ndxBroke = OutcomeRecord(indxToPlot) == 12;
            Xdata = indxToPlot(ndxBroke); Ydata = ones(1,sum(ndxBroke))*.5;
            set(BpodSystem.GUIHandles.BrokeFix, 'xdata', Xdata, 'ydata', Ydata);
            %Plot LogOdds of Reward
            set(BpodSystem.GUIHandles.LogOdds, 'xdata', indxToPlot, 'ydata', .5+log10(BpodSystem.Data.Custom.CumpL(1:end-1)./BpodSystem.Data.Custom.CumpR(1:end-1)));
        end
end

end

function [mn,mx] = rescaleX(AxesHandle,CurrentTrial,nTrialsToShow)
FractionWindowStickpoint = .75; % After this fraction of visible trials, the trial position in the window "sticks" and the window begins to slide through trials.
mn = max(round(CurrentTrial - FractionWindowStickpoint*nTrialsToShow),1);
mx = mn + nTrialsToShow - 1;
set(AxesHandle,'XLim',[mn-1 mx+1]);
end



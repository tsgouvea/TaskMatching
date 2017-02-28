function Matching
% Reproduction on Bpod of protocol used in the PatonLab, MATCHINGvFix

global BpodSystem
%% Task parameters
TaskParameters = BpodSystem.ProtocolSettings;
if isempty(fieldnames(TaskParameters))
    % Center Port ("stimulus sampling")
    TaskParameters.GUI.MinSampleTime = 0;
    TaskParameters.GUI.MaxSampleTime = 1;
    TaskParameters.GUI.AutoIncrSample = true;
    TaskParameters.GUIMeta.AutoIncrSample.Style = 'checkbox';
    TaskParameters.GUI.EarlyCoutPenalty = 5;
    TaskParameters.GUI.SampleTime = TaskParameters.GUI.MinSampleTime;
    TaskParameters.GUIMeta.SampleTime.Style = 'text';
    TaskParameters.GUIPanels.CenterPort = {'EarlyCoutPenalty','AutoIncrSample','MinSampleTime','MaxSampleTime','SampleTime'};
    % General
    TaskParameters.GUI.Ports_LMR = '123';
    TaskParameters.GUI.ITI = 1; % (s)
    TaskParameters.GUI.VI = false; % random ITI
    TaskParameters.GUIMeta.VI.Style = 'checkbox';
    TaskParameters.GUI.ChoiceDeadline = 10;
    TaskParameters.GUI.MinCutoff = 50; % New waiting time as percentile of empirical distribution
    TaskParameters.GUIPanels.General = {'Ports_LMR','FI','VI','ChoiceDeadline','MinCutoff'};
    % Side Ports ("waiting for feedback")
    TaskParameters.GUI.MinFeedbackTime = 0;
    TaskParameters.GUI.MaxFeedbackTime = 1;
    TaskParameters.GUI.EarlySoutPenalty = 1;
    TaskParameters.GUI.AutoIncrFeedback = true;
    TaskParameters.GUIMeta.AutoIncrFeedback.Style = 'checkbox';
    TaskParameters.GUI.FeedbackTime = TaskParameters.GUI.MinFeedbackTime;
    TaskParameters.GUIMeta.FeedbackTime.Style = 'text';
    TaskParameters.GUIPanels.SidePorts = {'EarlySoutPenalty','AutoIncrFeedback','MinFeedbackTime','MaxFeedbackTime','FeedbackTime'};   
    % Reward
    TaskParameters.GUI.rewardAmount = 30;
    
    TaskParameters.GUIPanels.Reward = {'rewardAmount','Deplete','DepleteRate','Jackpot','JackpotMin','JackpotTime'};
    TaskParameters.GUI = orderfields(TaskParameters.GUI);
end
BpodParameterGUI('init', TaskParameters);

%% Initializing data (trial type) vectors

BpodSystem.Data.Custom.Baited.Left = true;
BpodSystem.Data.Custom.Baited.Right = true;
BpodSystem.Data.Custom.Wait = TaskParameters.GUI.waitMin;
BpodSystem.Data.Custom.OutcomeRecord = nan;
BpodSystem.Data.Custom.TrialValid = true;
BpodSystem.Data.Custom.BrokeFix = false;
BpodSystem.Data.Custom.BrokeFixTime = NaN;
BpodSystem.Data.Custom.BlockNumber = 1;
BpodSystem.Data.Custom.LeftHi = rand>.5;
BpodSystem.Data.Custom.BlockLen = drawBlockLen(TaskParameters);
BpodSystem.Data.Custom.ChoiceLeft = NaN;
BpodSystem.Data.Custom.Rewarded = NaN;
if BpodSystem.Data.Custom.LeftHi
    BpodSystem.Data.Custom.CumpL = TaskParameters.GUI.pHi/100;
    BpodSystem.Data.Custom.CumpR = TaskParameters.GUI.pLo/100;
else
    BpodSystem.Data.Custom.CumpL = TaskParameters.GUI.pLo/100;
    BpodSystem.Data.Custom.CumpR = TaskParameters.GUI.pHi/100;
end
BpodSystem.Data.Custom = orderfields(BpodSystem.Data.Custom);

%% Initialize plots
BpodSystem.ProtocolFigures.OutcomePlotFig = figure('Position', [200 200 1000 400],'name','Outcome plot','numbertitle','off', 'MenuBar', 'none', 'Resize', 'off');
BpodSystem.GUIHandles.OutcomePlot.HandleOutcome = axes('Position', [.075 .15 .89 .3]);
BpodSystem.GUIHandles.OutcomePlot.HandleWait = axes('Position', [.075 .6 .12 .3]);
BpodSystem.GUIHandles.OutcomePlot.HandleTrialRate = axes('Position', [2*.075+.12 .6 .12 .3]);
Matching_PlotSideOutcome(BpodSystem.GUIHandles.OutcomePlot,'init');
% BpodNotebook('init');

%% Main loop
RunSession = true;
iTrial = 1;

while RunSession
    TaskParameters = BpodParameterGUI('sync', TaskParameters);
    
    sma = stateMatrix(TaskParameters);
    SendStateMatrix(sma);
    RawEvents = RunStateMatrix;
    if ~isempty(fieldnames(RawEvents))
        BpodSystem.Data = AddTrialEvents(BpodSystem.Data,RawEvents);
        SaveBpodSessionData;
    end
    HandlePauseCondition; % Checks to see if the protocol is paused. If so, waits until user resumes.
    if BpodSystem.BeingUsed == 0
        return
    end
    
    updateCustomDataFields(TaskParameters)
    iTrial = iTrial + 1;
    Matching_PlotSideOutcome(BpodSystem.GUIHandles.OutcomePlot,'update',iTrial);
end
end

function sma = stateMatrix(TaskParameters)
global BpodSystem
ValveTimes  = GetValveTimes(TaskParameters.GUI.rewardAmount, [1 3]);
LeftValveTime = ValveTimes(1);
RightValveTime = ValveTimes(2);
clear ValveTimes

if BpodSystem.Data.Custom.Baited.Left(end)
    LeftPokeAction = 'rewarded_Lin';
else
    LeftPokeAction = 'unrewarded_Lin';
end
if BpodSystem.Data.Custom.Baited.Right(end)
    RightPokeAction = 'rewarded_Rin';
else
    RightPokeAction = 'unrewarded_Rin';
end

sma = NewStateMatrix();
sma = AddState(sma, 'Name', 'state_0',...
    'Timer', 0,...
    'StateChangeConditions', {'Tup', 'wait_Cin'},...
    'OutputActions', {});
sma = AddState(sma, 'Name', 'wait_Cin',...
    'Timer', 0,...
    'StateChangeConditions', {'Port2In', 'stay_Cin'},...
    'OutputActions', {'PWM2',255});
sma = AddState(sma, 'Name', 'wait_Sin',...
    'Timer',0,...
    'StateChangeConditions', {'Port1In',LeftPokeAction,'Port3In',RightPokeAction},...
    'OutputActions',{'PWM1',255,'PWM3',255});
sma = AddState(sma, 'Name', 'rewarded_Lin',...
    'Timer', 0,...
    'StateChangeConditions', {'Tup','water_L'},...
    'OutputActions', {});
sma = AddState(sma, 'Name', 'rewarded_Rin',...
    'Timer', 0,...
    'StateChangeConditions', {'Tup','water_R'},...
    'OutputActions', {});
sma = AddState(sma, 'Name', 'unrewarded_Lin',...
    'Timer', 0,...
    'StateChangeConditions', {'Tup','ITI'},...
    'OutputActions', {});
sma = AddState(sma, 'Name', 'unrewarded_Rin',...
    'Timer', 0,...
    'StateChangeConditions', {'Tup','ITI'},...
    'OutputActions', {});
sma = AddState(sma, 'Name', 'water_L',...
    'Timer', LeftValveTime,...
    'StateChangeConditions', {'Tup','ITI'},...
    'OutputActions', {'ValveState', 1});
sma = AddState(sma, 'Name', 'water_R',...
    'Timer', RightValveTime,...
    'StateChangeConditions', {'Tup','ITI'},...
    'OutputActions', {'ValveState', 4});
sma = AddState(sma, 'Name', 'ITI',...
    'Timer',TaskParameters.GUI.iti,...
    'StateChangeConditions',{'Tup','exit'},...
    'OutputActions',{});
sma = AddState(sma, 'Name', 'stay_Cin',...
    'Timer', BpodSystem.Data.Custom.Wait(end),...
    'StateChangeConditions', {'Port2Out','broke_fixation','Tup', 'wait_Sin'},...
    'OutputActions',{});
sma = AddState(sma, 'Name', 'broke_fixation',...
    'Timer',0,...
    'StateChangeConditions',{'Tup','time_out'},...
    'OutputActions',{'BNCState',1}); %figure out how to add a noise tone
sma = AddState(sma, 'Name', 'time_out',...
    'Timer',TaskParameters.GUI.timeOut,...
    'StateChangeConditions',{'Tup','ITI'},...
    'OutputActions',{});
%     sma = AddState(sma, 'Name', 'state_name',...
%         'Timer', 0,...
%         'StateChangeConditions', {},...
%         'OutputActions', {});
end

function updateCustomDataFields(TaskParameters)
global BpodSystem
%% OutcomeRecord
temp = BpodSystem.Data.RawData.OriginalStateData{end};
temp =  temp(temp>=4&temp<=7|temp==12);
if ~isempty(temp)
    BpodSystem.Data.Custom.OutcomeRecord(end) = temp;
end
clear temp
if BpodSystem.Data.Custom.OutcomeRecord(end) == 4 || BpodSystem.Data.Custom.OutcomeRecord(end) == 6
    BpodSystem.Data.Custom.ChoiceLeft(end) = 1;
elseif BpodSystem.Data.Custom.OutcomeRecord(end) == 5 || BpodSystem.Data.Custom.OutcomeRecord(end) == 7
    BpodSystem.Data.Custom.ChoiceLeft(end) = 0;
end
if BpodSystem.Data.Custom.OutcomeRecord(end) == 4 || BpodSystem.Data.Custom.OutcomeRecord(end) == 5
    BpodSystem.Data.Custom.Rewarded(end) = 1;
elseif BpodSystem.Data.Custom.OutcomeRecord(end) == 6 || BpodSystem.Data.Custom.OutcomeRecord(end) == 7
    BpodSystem.Data.Custom.Rewarded(end) = 0;
end
if BpodSystem.Data.Custom.OutcomeRecord(end)==12
    BpodSystem.Data.Custom.TrialValid(end) = false;
    BpodSystem.Data.Custom.BrokeFix(end) = true;
    BpodSystem.Data.Custom.BrokeFixTime(end) = diff(BpodSystem.Data.RawEvents.Trial{end}.States.stay_Cin);
end
BpodSystem.Data.Custom.OutcomeRecord(end+1) = nan;
BpodSystem.Data.Custom.ChoiceLeft(end+1) = NaN;
BpodSystem.Data.Custom.Rewarded(end+1) = NaN;
BpodSystem.Data.Custom.TrialValid(end+1) = true;
BpodSystem.Data.Custom.BrokeFix(end+1) = false;
BpodSystem.Data.Custom.BrokeFixTime(end+1) = NaN;

%% Waiting (fixation) time
if BpodSystem.Data.Custom.TrialValid(end-1)
    BpodSystem.Data.Custom.Wait(end+1) = BpodSystem.Data.Custom.Wait(end)+TaskParameters.GUI.waitIncr;
    BpodSystem.Data.Custom.Wait(end) = min(BpodSystem.Data.Custom.Wait(end),TaskParameters.GUI.waitTarget);
else
    BpodSystem.Data.Custom.Wait(end+1) = BpodSystem.Data.Custom.Wait(end)-TaskParameters.GUI.waitDecr;
    BpodSystem.Data.Custom.Wait(end) = max(BpodSystem.Data.Custom.Wait(end),TaskParameters.GUI.waitMin);
end

%% Block count
nTrialsThisBlock = sum(BpodSystem.Data.Custom.BlockNumber == BpodSystem.Data.Custom.BlockNumber(end));
if nTrialsThisBlock >= TaskParameters.GUI.blockLenMax
    % If current block len exceeds new max block size, will transition
    BpodSystem.Data.Custom.BlockLen(end) = nTrialsThisBlock;
end
if nTrialsThisBlock >= BpodSystem.Data.Custom.BlockLen(end)
    BpodSystem.Data.Custom.BlockNumber(end+1) = BpodSystem.Data.Custom.BlockNumber(end)+1;
    BpodSystem.Data.Custom.BlockLen(end+1) = drawBlockLen(TaskParameters);
    BpodSystem.Data.Custom.LeftHi(end+1) = ~BpodSystem.Data.Custom.LeftHi(end);
else
    BpodSystem.Data.Custom.BlockNumber(end+1) = BpodSystem.Data.Custom.BlockNumber(end);
    BpodSystem.Data.Custom.LeftHi(end+1) = BpodSystem.Data.Custom.LeftHi(end);
end
%display(BpodSystem.Data.RawData.OriginalStateNamesByNumber{end}(BpodSystem.Data.RawData.OriginalStateData{end}))

%% Baiting
if BpodSystem.Data.Custom.LeftHi(end)
    pL = TaskParameters.GUI.pHi/100;
    pR = TaskParameters.GUI.pLo/100;
else
    pL = TaskParameters.GUI.pLo/100;
    pR = TaskParameters.GUI.pHi/100;
end
if BpodSystem.Data.Custom.ChoiceLeft(end-1) == 1
    BpodSystem.Data.Custom.CumpL(end+1) = pL;
    BpodSystem.Data.Custom.CumpR(end+1) = BpodSystem.Data.Custom.CumpR(end) + (1-BpodSystem.Data.Custom.CumpR(end))*pR;
elseif BpodSystem.Data.Custom.ChoiceLeft(end-1) == 0
    BpodSystem.Data.Custom.CumpL(end+1) = BpodSystem.Data.Custom.CumpL(end) + (1-BpodSystem.Data.Custom.CumpL(end))*pL;
    BpodSystem.Data.Custom.CumpR(end+1) = pR;
else
    BpodSystem.Data.Custom.CumpL(end+1) = BpodSystem.Data.Custom.CumpL(end);
    BpodSystem.Data.Custom.CumpR(end+1) = BpodSystem.Data.Custom.CumpR(end);
end
if BpodSystem.Data.Custom.TrialValid(end-1) &&...
        (~BpodSystem.Data.Custom.Baited.Left(end) || BpodSystem.Data.Custom.OutcomeRecord(end-1)==4)
    BpodSystem.Data.Custom.Baited.Left(end+1) = rand<pL;
else
    BpodSystem.Data.Custom.Baited.Left(end+1) = BpodSystem.Data.Custom.Baited.Left(end);
end
if BpodSystem.Data.Custom.TrialValid(end-1) &&...
        (~BpodSystem.Data.Custom.Baited.Right(end) || BpodSystem.Data.Custom.OutcomeRecord(end-1)==5)
    BpodSystem.Data.Custom.Baited.Right(end+1) = rand<pR;
else
    BpodSystem.Data.Custom.Baited.Right(end+1) = BpodSystem.Data.Custom.Baited.Right(end);
end
end

function BlockLen = drawBlockLen(TaskParameters)
BlockLen = 0;
if TaskParameters.GUI.blockLenMax < TaskParameters.GUI.blockLenMin
    error('Bpod:Matching:blockLenMinMax','Error choosing block length: minimum is greater than maximum. Set different values and try again.')
end
iDraw = 0;
while BlockLen < TaskParameters.GUI.blockLenMin || BlockLen > TaskParameters.GUI.blockLenMax
    BlockLen = ceil(exprnd(sqrt(TaskParameters.GUI.blockLenMin*TaskParameters.GUI.blockLenMax)));
    iDraw = iDraw+1;
    if iDraw > 1000
        BlockLen = ceil(random('unif',TaskParameters.GUI.blockLenMin,TaskParameters.GUI.blockLenMax));
        warning('Bpod:Matching:blockLenDraw',['Drawing block length from exponential distribution is taking too long.'...
            'Using uniform distribution instead. If exponential is important for you, set reasonable minimum and maximum values and try again.'])
    end
end
end
function Matching
% Reproduction on Bpod of protocol used in the PatonLab, MATCHINGvFix

global BpodSystem
global TaskParameters

%% Task parameters
TaskParameters = BpodSystem.ProtocolSettings;
if isempty(fieldnames(TaskParameters))
    % Center Port ("stimulus sampling")
    TaskParameters.GUI.MinSampleTime = 0;
    TaskParameters.GUI.MaxSampleTime = 1;
    TaskParameters.GUI.AutoIncrSample = false;
    TaskParameters.GUIMeta.AutoIncrSample.Style = 'checkbox';
    TaskParameters.GUI.EarlyCoutPenalty = 5;
    TaskParameters.GUI.SampleTime = TaskParameters.GUI.MinSampleTime;
    TaskParameters.GUIMeta.SampleTime.Style = 'text';
    TaskParameters.GUIPanels.CenterPort = {'EarlyCoutPenalty','AutoIncrSample','MinSampleTime','MaxSampleTime','SampleTime'};
    % General
    TaskParameters.GUI.Ports_LMR = '123';
    TaskParameters.GUI.ITI = 5; % (s)
    TaskParameters.GUI.VI = false; % random ITI
    TaskParameters.GUIMeta.VI.Style = 'checkbox';
    TaskParameters.GUI.ChoiceDeadline = 10;
    TaskParameters.GUI.MinCutoff = 50; % New waiting time as percentile of empirical distribution
    TaskParameters.GUIPanels.General = {'Ports_LMR','ITI','VI','ChoiceDeadline','MinCutoff'};
    % Side Ports ("waiting for feedback")
    TaskParameters.GUI.MinFeedbackTime = 0;
    TaskParameters.GUI.MaxFeedbackTime = 1;
    TaskParameters.GUI.EarlySoutPenalty = 1;
    TaskParameters.GUI.AutoIncrFeedback = false;
    TaskParameters.GUIMeta.AutoIncrFeedback.Style = 'checkbox';
    TaskParameters.GUI.FeedbackTime = TaskParameters.GUI.MinFeedbackTime;
    TaskParameters.GUIMeta.FeedbackTime.Style = 'text';
    TaskParameters.GUIPanels.SidePorts = {'EarlySoutPenalty','AutoIncrFeedback','MinFeedbackTime','MaxFeedbackTime','FeedbackTime'};
    % Reward
    TaskParameters.GUI.pHi =  40; % 0-100% Higher reward probability
    TaskParameters.GUI.pLo =  5; % 0-100% Lower reward probability
    TaskParameters.GUI.blockLenMin = 100;
    TaskParameters.GUI.blockLenMax = 250;
    TaskParameters.GUI.rewardAmount = 30;
    TaskParameters.GUIPanels.Reward = {'rewardAmount','pLo','pHi','blockLenMin','blockLenMax'};
    
    TaskParameters.GUI = orderfields(TaskParameters.GUI);
end
BpodParameterGUI('init', TaskParameters);

%% Initializing data (trial type) vectors

BpodSystem.Data.Custom.Baited.Left = true;
BpodSystem.Data.Custom.Baited.Right = true;
BpodSystem.Data.Custom.BlockNumber = 1;
BpodSystem.Data.Custom.LeftHi = rand>.5;
BpodSystem.Data.Custom.BlockLen = drawBlockLen(TaskParameters);
if BpodSystem.Data.Custom.LeftHi
    BpodSystem.Data.Custom.CumpL = TaskParameters.GUI.pHi/100;
    BpodSystem.Data.Custom.CumpR = TaskParameters.GUI.pLo/100;
else
    BpodSystem.Data.Custom.CumpL = TaskParameters.GUI.pLo/100;
    BpodSystem.Data.Custom.CumpR = TaskParameters.GUI.pHi/100;
end

BpodSystem.Data.Custom.ChoiceLeft = NaN;
BpodSystem.Data.Custom.EarlyCout(1) = false;
BpodSystem.Data.Custom.EarlySout(1) = false;
BpodSystem.Data.Custom.Rewarded = false;
BpodSystem.Data.Custom.SampleTime(1) = NaN;
BpodSystem.Data.Custom.FeedbackTime(1) = NaN;
BpodSystem.Data.Custom.RewardMagnitude(1,1:2) = TaskParameters.GUI.rewardAmount;

%server data
BpodSystem.Data.Custom.Rig = getenv('computername');
[~,BpodSystem.Data.Custom.Subject] = fileparts(fileparts(fileparts(fileparts(BpodSystem.DataPath))));

BpodSystem.Data.Custom = orderfields(BpodSystem.Data.Custom);

%% Set up PulsePal
load PulsePalParamFeedback.mat
BpodSystem.Data.Custom.PulsePalParamFeedback=PulsePalParamFeedback;

%% Initialize plots

MainPlot('init');
BpodNotebook('init');

%% Main loop
RunSession = true;
iTrial = 1;

while RunSession
    TaskParameters = BpodParameterGUI('sync', TaskParameters);
    
    sma = stateMatrix();
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
    
    updateCustomDataFields(iTrial)
    iTrial = iTrial + 1;
    MainPlot('update',iTrial);
end
end
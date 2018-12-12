function Matching
% Reproduction on Bpod of protocol used in the PatonLab, MATCHINGvFix

global BpodSystem
global TaskParameters

%% Task parameters
TaskParameters = BpodSystem.ProtocolSettings;
if isempty(fieldnames(TaskParameters))
    %% Center Port ("stimulus sampling")
    TaskParameters.GUI.EarlyCoutPenalty = 0;
    TaskParameters.GUI.StimDelaySelection = 4;
    TaskParameters.GUIMeta.StimDelaySelection.Style = 'popupmenu';
    TaskParameters.GUIMeta.StimDelaySelection.String = {'Fix','AutoIncr','TruncExp','Uniform'};
    TaskParameters.GUI.StimDelayMin = 0.2;
    TaskParameters.GUI.StimDelayMax = 0.5;
    TaskParameters.GUI.StimDelayTau = 0.2;
    TaskParameters.GUI.StimDelay = TaskParameters.GUI.StimDelayMin;
    TaskParameters.GUIMeta.StimDelay.Style = 'text';
    TaskParameters.GUIPanels.StimDelay = {'EarlyCoutPenalty','StimDelaySelection','StimDelayMin','StimDelayMax','StimDelayTau','StimDelay'};
    
    %% General
    TaskParameters.GUI.Ports_LMR = '123';
    TaskParameters.GUI.ITI = 1; % (s)
    TaskParameters.GUI.VI = false; % random ITI
    TaskParameters.GUIMeta.VI.Style = 'checkbox';
    TaskParameters.GUI.ChoiceDeadline = 10;
    TaskParameters.GUI.MinCutoff = 50; % New waiting time as percentile of empirical distribution
    TaskParameters.GUIPanels.General = {'Ports_LMR','ITI','VI','ChoiceDeadline','MinCutoff'};
    % Side Ports ("waiting for feedback")
    TaskParameters.GUI.EarlySoutPenalty = 1;
    TaskParameters.GUI.FeedbackDelaySelection = 2;
    TaskParameters.GUIMeta.FeedbackDelaySelection.Style = 'popupmenu';
    TaskParameters.GUIMeta.FeedbackDelaySelection.String = {'Fix','AutoIncr','TruncExp','Uniform'};
    TaskParameters.GUI.FeedbackDelayMin = 0;
    TaskParameters.GUI.FeedbackDelayMax = 1;
    TaskParameters.GUI.FeedbackDelayTau = 0.4;
    TaskParameters.GUI.FeedbackDelay = TaskParameters.GUI.FeedbackDelayMin;
    TaskParameters.GUIMeta.FeedbackDelay.Style = 'text';
    TaskParameters.GUI.Grace = 0.2;
    TaskParameters.GUIPanels.SidePorts = {'EarlySoutPenalty','FeedbackDelaySelection','FeedbackDelayMin','FeedbackDelayMax','FeedbackDelayTau','FeedbackDelay','Grace'};
    % Reward
    TaskParameters.GUI.pHi =  50; % 0-100% Higher reward probability
    TaskParameters.GUI.pLo =  12; % 0-100% Lower reward probability
    TaskParameters.GUI.blockLenMin = 50;
    TaskParameters.GUI.blockLenMax = 100;
    TaskParameters.GUI.rewardAmount = 30;
    TaskParameters.GUIPanels.Reward = {'rewardAmount','pLo','pHi','blockLenMin','blockLenMax'};
    
    TaskParameters.GUI = orderfields(TaskParameters.GUI);
end
TaskParameters.GUI.StimDelay = TaskParameters.GUI.StimDelayMin;
TaskParameters.GUI.FeedbackDelay = TaskParameters.GUI.FeedbackDelayMin;
BpodParameterGUI('init', TaskParameters);

%% Initializing data (trial type) vectors

BpodSystem.Data.Custom.Baited.Left = true;
BpodSystem.Data.Custom.Baited.Right = true;
BpodSystem.Data.Custom.BlockNumber = 1;
BpodSystem.Data.Custom.LeftHi = rand>.5;
BpodSystem.Data.Custom.BlockLen = drawBlockLen();

BpodSystem.Data.Custom.ChoiceLeft = NaN;
BpodSystem.Data.Custom.EarlyCout(1) = false;
BpodSystem.Data.Custom.EarlySout(1) = false;
BpodSystem.Data.Custom.Rewarded = false;
BpodSystem.Data.Custom.StimDelay(1) = NaN;
BpodSystem.Data.Custom.FeedbackTime(1) = NaN;
BpodSystem.Data.Custom.RewardMagnitude(1,1:2) = TaskParameters.GUI.rewardAmount;

%server data
BpodSystem.Data.Custom.Rig = getenv('computername');
[~,BpodSystem.Data.Custom.Subject] = fileparts(fileparts(fileparts(fileparts(BpodSystem.DataPath))));

BpodSystem.Data.Custom = orderfields(BpodSystem.Data.Custom);

%% Set up PulsePal
load PulsePalParamFeedback.mat
BpodSystem.Data.Custom.PulsePalParamFeedback=PulsePalParamFeedback;
BpodSystem.SoftCodeHandlerFunction = 'SoftCodeHandler';
if ~BpodSystem.EmulatorMode
    ProgramPulsePal(BpodSystem.Data.Custom.PulsePalParamFeedback);
end

%% Initialize plots
temp = SessionSummary();
for i = fieldnames(temp)'
    BpodSystem.GUIHandles.(i{1}) = temp.(i{1});
end
clear temp
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
    BpodSystem.GUIHandles = SessionSummary(BpodSystem.Data, BpodSystem.GUIHandles, iTrial);
end
end
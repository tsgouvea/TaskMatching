function updateCustomDataFields(iTrial)
global BpodSystem
global TaskParameters

statesThisTrial = BpodSystem.Data.RawData.OriginalStateNamesByNumber{iTrial}(BpodSystem.Data.RawData.OriginalStateData{iTrial});

%% Center port
if any(strcmp('Cin',statesThisTrial))
    BpodSystem.Data.Custom.SampleTime(iTrial) = diff(BpodSystem.Data.RawEvents.Trial{iTrial}.States.Cin);    
end
%% Side ports
if any(strcmp('Lin',statesThisTrial)) || any(strcmp('Rin',statesThisTrial))
    Sin = statesThisTrial{strcmp('Lin',statesThisTrial)|strcmp('Rin',statesThisTrial)};
    BpodSystem.Data.Custom.FeedbackTime(iTrial) = diff(BpodSystem.Data.RawEvents.Trial{iTrial}.States.(Sin));
end
%%
if any(strcmp('Lin',statesThisTrial))
    BpodSystem.Data.Custom.ChoiceLeft(iTrial) = 1;
elseif any(strcmp('Rin',statesThisTrial))
    BpodSystem.Data.Custom.ChoiceLeft(iTrial) = 0;
end
BpodSystem.Data.Custom.EarlyCout(iTrial) = any(strcmp('EarlyCout',statesThisTrial));
BpodSystem.Data.Custom.EarlySout(iTrial) = any(strcmp('EarlyRout',statesThisTrial)) || any(strcmp('EarlyLout',statesThisTrial));
BpodSystem.Data.Custom.Rewarded(iTrial) = any(strncmp('water_',statesThisTrial,6));

%% initialize next trial values
BpodSystem.Data.Custom.ChoiceLeft(iTrial+1) = NaN;
BpodSystem.Data.Custom.EarlyCout(iTrial+1) = false;
BpodSystem.Data.Custom.EarlySout(iTrial+1) = false;
BpodSystem.Data.Custom.Rewarded(iTrial+1) = false;
BpodSystem.Data.Custom.SampleTime(iTrial+1) = NaN;
BpodSystem.Data.Custom.FeedbackTime(iTrial+1) = NaN;

%% Block count
nTrialsThisBlock = sum(BpodSystem.Data.Custom.BlockNumber == BpodSystem.Data.Custom.BlockNumber(iTrial));
if nTrialsThisBlock >= TaskParameters.GUI.blockLenMax
    % If current block len exceeds new max block size, will transition
    BpodSystem.Data.Custom.BlockLen(iTrial) = nTrialsThisBlock;
end
if nTrialsThisBlock >= BpodSystem.Data.Custom.BlockLen(iTrial)
    BpodSystem.Data.Custom.BlockNumber(iTrial+1) = BpodSystem.Data.Custom.BlockNumber(iTrial)+1;
    BpodSystem.Data.Custom.BlockLen(iTrial+1) = drawBlockLen(TaskParameters);
    BpodSystem.Data.Custom.LeftHi(iTrial+1) = ~BpodSystem.Data.Custom.LeftHi(iTrial);
else
    BpodSystem.Data.Custom.BlockNumber(iTrial+1) = BpodSystem.Data.Custom.BlockNumber(iTrial);
    BpodSystem.Data.Custom.LeftHi(iTrial+1) = BpodSystem.Data.Custom.LeftHi(iTrial);
end

%% Baiting

if BpodSystem.Data.Custom.LeftHi(iTrial)
    pL = TaskParameters.GUI.pHi/100;
    pR = TaskParameters.GUI.pLo/100;
else
    pL = TaskParameters.GUI.pLo/100;
    pR = TaskParameters.GUI.pHi/100;
end

if BpodSystem.Data.Custom.ChoiceLeft(iTrial) == 1
    BpodSystem.Data.Custom.CumpL(iTrial+1) = pL;
    BpodSystem.Data.Custom.CumpR(iTrial+1) = BpodSystem.Data.Custom.CumpR(iTrial) + (1-BpodSystem.Data.Custom.CumpR(iTrial))*pR;
elseif BpodSystem.Data.Custom.ChoiceLeft(iTrial) == 0
    BpodSystem.Data.Custom.CumpL(iTrial+1) = BpodSystem.Data.Custom.CumpL(iTrial) + (1-BpodSystem.Data.Custom.CumpL(iTrial))*pL;
    BpodSystem.Data.Custom.CumpR(iTrial+1) = pR;
else
    BpodSystem.Data.Custom.CumpL(iTrial+1) = BpodSystem.Data.Custom.CumpL(iTrial);
    BpodSystem.Data.Custom.CumpR(iTrial+1) = BpodSystem.Data.Custom.CumpR(iTrial);
end

if not(any(BpodSystem.Data.Custom.EarlyCout(iTrial),BpodSystem.Data.Custom.EarlySout(iTrial))) &&...
        (~BpodSystem.Data.Custom.Baited.Left(iTrial) || BpodSystem.Data.Custom.ChoiceLeft(iTrial)==1)
    BpodSystem.Data.Custom.Baited.Left(iTrial+1) = rand<pL;
else
    BpodSystem.Data.Custom.Baited.Left(iTrial+1) = BpodSystem.Data.Custom.Baited.Left(iTrial);
end
if not(any(BpodSystem.Data.Custom.EarlyCout(iTrial),BpodSystem.Data.Custom.EarlySout(iTrial))) &&...
        (~BpodSystem.Data.Custom.Baited.Right(iTrial) || BpodSystem.Data.Custom.ChoiceLeft(iTrial)==0)
    BpodSystem.Data.Custom.Baited.Right(iTrial+1) = rand<pR;
else
    BpodSystem.Data.Custom.Baited.Right(iTrial+1) = BpodSystem.Data.Custom.Baited.Right(iTrial);
end

%increase sample time
%% Center port
if TaskParameters.GUI.AutoIncrSample
    if sum(~isnan(BpodSystem.Data.Custom.SampleTime)) >= 10
        TaskParameters.GUI.SampleTime = prctile(BpodSystem.Data.Custom.SampleTime,TaskParameters.GUI.MinCutoff);
    else
        TaskParameters.GUI.SampleTime = TaskParameters.GUI.MinSampleTime;
    end
else
    TaskParameters.GUI.SampleTime = TaskParameters.GUI.MaxSampleTime;
end
TaskParameters.GUI.SampleTime = max(TaskParameters.GUI.MinSampleTime,min(TaskParameters.GUI.SampleTime,TaskParameters.GUI.MaxSampleTime));

%% Side ports
if TaskParameters.GUI.AutoIncrSample
    if sum(~isnan(BpodSystem.Data.Custom.FeedbackTime)) >= 10
        TaskParameters.GUI.FeedbackTime = prctile(BpodSystem.Data.Custom.FeedbackTime,TaskParameters.GUI.MinCutoff);
    else
        TaskParameters.GUI.FeedbackTime = TaskParameters.GUI.MinFeedbackTime;
    end
else
    TaskParameters.GUI.FeedbackTime = TaskParameters.GUI.MaxFeedbackTime;
end
TaskParameters.GUI.FeedbackTime = max(TaskParameters.GUI.MinFeedbackTime,min(TaskParameters.GUI.FeedbackTime,TaskParameters.GUI.MaxFeedbackTime));

%% send bpod status to server
try
    BpodSystem.Data.Custom.Script = 'receivebpodstatus.php';
    %create a common "outcome" vector
    outcome = BpodSystem.Data.Custom.ChoiceLeft(1:iTrial); %1=left, 0=right
    outcome(BpodSystem.Data.Custom.EarlyCout(1:iTrial))=3; %early C withdrawal=3
    outcome(BpodSystem.Data.Custom.Jackpot(1:iTrial))=4; %jackpot=4
    outcome(BpodSystem.Data.Custom.EarlySout(1:iTrial))=5; %early S withdrawal=5
    SendTrialStatusToServer(BpodSystem.Data.Custom.Script,BpodSystem.Data.Custom.Rig,outcome,BpodSystem.Data.Custom.Subject,BpodSystem.CurrentProtocolName);
catch
end
end
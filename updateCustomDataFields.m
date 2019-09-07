function updateCustomDataFields(iTrial)
global BpodSystem
global TaskParameters

statesThisTrial = BpodSystem.Data.RawData.OriginalStateNamesByNumber{iTrial}(BpodSystem.Data.RawData.OriginalStateData{iTrial});

%% Center port
if any(strcmp('Cin',statesThisTrial))
    if any(strcmp('stillSampling',statesThisTrial))
        BpodSystem.Data.Custom.StimDelay(iTrial) = BpodSystem.Data.RawEvents.Trial{iTrial}.States.stillSampling(1,2) - BpodSystem.Data.RawEvents.Trial{iTrial}.States.Cin(end,1);
    else
        BpodSystem.Data.Custom.StimDelay(iTrial) = diff(BpodSystem.Data.RawEvents.Trial{iTrial}.States.Cin);
    end
end
%% Side ports
ChoicePort = 'X';
if any(strncmp('start_L',statesThisTrial,7))
    BpodSystem.Data.Custom.ChoiceLeft(iTrial) = 1;
    ChoicePort = floor(mod(TaskParameters.GUI.Ports_LMR/100,10));
elseif any(strncmp('start_R',statesThisTrial,7))
    BpodSystem.Data.Custom.ChoiceLeft(iTrial) = 0;
    ChoicePort = mod(TaskParameters.GUI.Ports_LMR,10);
end
ChoicePortOut = strcat('Port',num2str(ChoicePort),'Out');

for n = statesThisTrial
    if  regexp(n{1},'grace')
        graceState = n{1};
        BpodSystem.Data.Custom.Grace(iTrial) = true;
    end
end

if any(strncmp('start',statesThisTrial,5))
    start_S = statesThisTrial{strncmp('start',statesThisTrial,5)};
    if any(strcmp('EarlySout',statesThisTrial))
        lastState = statesThisTrial{find(strcmp('EarlySout',statesThisTrial))-1}; % a grace period state
        BpodSystem.Data.Custom.FeedbackDelay(iTrial) = BpodSystem.Data.RawEvents.Trial{iTrial}.States.(lastState)(1,1) -  BpodSystem.Data.RawEvents.Trial{iTrial}.States.(start_S)(1,1); % 
    else
        BpodSystem.Data.Custom.FeedbackDelay(iTrial) = BpodSystem.Data.RawEvents.Trial{iTrial}.States.ITI(1,2) - BpodSystem.Data.RawEvents.Trial{iTrial}.States.(start_S)(1,1);
        if isfield(BpodSystem.Data.RawEvents.Trial{iTrial}.Events,ChoicePortOut)
            candidates = BpodSystem.Data.RawEvents.Trial{iTrial}.Events.(ChoicePortOut);
            candidates = candidates(candidates>BpodSystem.Data.RawEvents.Trial{iTrial}.States.(start_S)(1,1));
            if BpodSystem.Data.Custom.Grace(iTrial)
                candidates = candidates(candidates>BpodSystem.Data.RawEvents.Trial{iTrial}.States.(graceState)(end,end));
            end
            if ~isempty(candidates)
                BpodSystem.Data.Custom.FeedbackDelay(iTrial) = min(candidates) -  BpodSystem.Data.RawEvents.Trial{iTrial}.States.(start_S)(1,1);
            end
        end
    end
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
BpodSystem.Data.Custom.RewardMagnitude(iTrial,1:2) = TaskParameters.GUI.rewardAmount;

%% initialize next trial values
BpodSystem.Data.Custom.ChoiceLeft(iTrial+1) = NaN;
BpodSystem.Data.Custom.EarlyCout(iTrial+1) = false;
BpodSystem.Data.Custom.EarlySout(iTrial+1) = false;
BpodSystem.Data.Custom.Rewarded(iTrial+1) = false;
BpodSystem.Data.Custom.Grace(iTrial+1) = false;
BpodSystem.Data.Custom.StimDelay(iTrial+1) = NaN;
BpodSystem.Data.Custom.FeedbackDelay(iTrial+1) = NaN;

%% Block count
nTrialsThisBlock = sum(BpodSystem.Data.Custom.BlockNumber == BpodSystem.Data.Custom.BlockNumber(iTrial));
if nTrialsThisBlock >= TaskParameters.GUI.blockLenMax
    % If current block len exceeds new max block size, will transition
    BpodSystem.Data.Custom.BlockLen(end) = nTrialsThisBlock;
end
if nTrialsThisBlock >= BpodSystem.Data.Custom.BlockLen(end)
    BpodSystem.Data.Custom.BlockNumber(iTrial+1) = BpodSystem.Data.Custom.BlockNumber(iTrial)+1;
    BpodSystem.Data.Custom.BlockLen(end+1) = drawBlockLen();
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

drawL = false;
drawR = false;

if ~BpodSystem.Data.Custom.EarlyCout(iTrial) || TaskParameters.GUI.LoopbackFix
    if ~BpodSystem.Data.Custom.Baited.Left(iTrial) || (BpodSystem.Data.Custom.ChoiceLeft(iTrial)==1 && BpodSystem.Data.Custom.Rewarded(iTrial))
        drawL = true;
    end
    if ~BpodSystem.Data.Custom.Baited.Right(iTrial) || (BpodSystem.Data.Custom.ChoiceLeft(iTrial)==0 && BpodSystem.Data.Custom.Rewarded(iTrial))
        drawR = true;
    end
end

if drawL
    BpodSystem.Data.Custom.Baited.Left(iTrial+1) = rand<pL;
else
    BpodSystem.Data.Custom.Baited.Left(iTrial+1) = BpodSystem.Data.Custom.Baited.Left(iTrial);
end
if drawR
    BpodSystem.Data.Custom.Baited.Right(iTrial+1) = rand<pR;
else
    BpodSystem.Data.Custom.Baited.Right(iTrial+1) = BpodSystem.Data.Custom.Baited.Right(iTrial);
end

%increase sample time
%% Center port
switch TaskParameters.GUIMeta.StimDelaySelection.String{TaskParameters.GUI.StimDelaySelection}
    case 'Fix'
        TaskParameters.GUI.StimDelay = TaskParameters.GUI.StimDelayMax;
    case 'AutoIncr'
        if sum(~isnan(BpodSystem.Data.Custom.StimDelay)) >= 10
            TaskParameters.GUI.StimDelay = prctile(BpodSystem.Data.Custom.StimDelay,TaskParameters.GUI.MinCutoff);
        else
            TaskParameters.GUI.StimDelay = TaskParameters.GUI.StimDelayMin;
        end
    case 'TruncExp'
        TaskParameters.GUI.StimDelay = TruncatedExponential(TaskParameters.GUI.StimDelayMin,...
            TaskParameters.GUI.StimDelayMax,TaskParameters.GUI.StimDelayTau);
    case 'Uniform'
        TaskParameters.GUI.StimDelay = TaskParameters.GUI.StimDelayMin + (TaskParameters.GUI.StimDelayMax-TaskParameters.GUI.StimDelayMin)*rand(1);
end
TaskParameters.GUI.StimDelay = max(TaskParameters.GUI.StimDelayMin,min(TaskParameters.GUI.StimDelay,TaskParameters.GUI.StimDelayMax));

%% Side ports
switch TaskParameters.GUIMeta.FeedbackDelaySelection.String{TaskParameters.GUI.FeedbackDelaySelection}
    case 'Fix'
        TaskParameters.GUI.FeedbackDelay = TaskParameters.GUI.FeedbackDelayMax;
    case 'AutoIncr'
        if sum(~isnan(BpodSystem.Data.Custom.FeedbackDelay)) >= 10
            TaskParameters.GUI.FeedbackDelay = prctile(BpodSystem.Data.Custom.FeedbackDelay,TaskParameters.GUI.MinCutoff);
        else
            TaskParameters.GUI.FeedbackDelay = TaskParameters.GUI.FeedbackDelayMin;
        end
    case 'TruncExp'
        TaskParameters.GUI.FeedbackDelay = TruncatedExponential(TaskParameters.GUI.FeedbackDelayMin,...
            TaskParameters.GUI.FeedbackDelayMax,TaskParameters.GUI.FeedbackDelayTau);
    case 'Uniform'
        TaskParameters.GUI.FeedbackDelay = TaskParameters.GUI.FeedbackDelayMin + (TaskParameters.GUI.FeedbackDelayMax-TaskParameters.GUI.FeedbackDelayMin)*rand(1);
end     
TaskParameters.GUI.FeedbackDelay = max(TaskParameters.GUI.FeedbackDelayMin,min(TaskParameters.GUI.FeedbackDelay,TaskParameters.GUI.FeedbackDelayMax));

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
function updateCustomDataFields(TaskParameters)
global BpodSystem

statesThisTrial = BpodSystem.Data.RawData.OriginalStateNamesByNumber{iTrial}(BpodSystem.Data.RawData.OriginalStateData{iTrial});

%% From FI_2AFC
%% Center port

if any(strcmp('Cin',statesThisTrial))
    if any(strcmp('stillSampling',statesThisTrial))
        if any(strcmp('stillSamplingJackpot',statesThisTrial))
            BpodSystem.Data.Custom.SampleTime(iTrial) = BpodSystem.Data.RawEvents.Trial{iTrial}.States.stillSamplingJackpot(1,2) - BpodSystem.Data.RawEvents.Trial{iTrial}.States.Cin(1,1);
        else
            BpodSystem.Data.Custom.SampleTime(iTrial) = BpodSystem.Data.RawEvents.Trial{iTrial}.States.stillSampling(1,2) - BpodSystem.Data.RawEvents.Trial{iTrial}.States.Cin(1,1);
        end
    else
        BpodSystem.Data.Custom.SampleTime(iTrial) = diff(BpodSystem.Data.RawEvents.Trial{iTrial}.States.Cin);
    end
end
%% Side ports
if any(strcmp('Lin',statesThisTrial)) || any(strcmp('Rin',statesThisTrial))
    Sin = statesThisTrial{strcmp('Lin',statesThisTrial)|strcmp('Rin',statesThisTrial)};
    if any(strcmp('stillLin',statesThisTrial)) || any(strcmp('stillRin',statesThisTrial))
        stillSin = statesThisTrial{strcmp('stillLin',statesThisTrial)|strcmp('stillRin',statesThisTrial)};
        BpodSystem.Data.Custom.FeedbackTime(iTrial) = BpodSystem.Data.RawEvents.Trial{iTrial}.States.(stillSin)(1,2) - BpodSystem.Data.RawEvents.Trial{iTrial}.States.(Sin)(1,1);
    else
        BpodSystem.Data.Custom.FeedbackTime(iTrial) = diff(BpodSystem.Data.RawEvents.Trial{iTrial}.States.(Sin));
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
BpodSystem.Data.Custom.Jackpot(iTrial) = any(strcmp('water_LJackpot',statesThisTrial)) || any(strcmp('water_RJackpot',statesThisTrial));
%%

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
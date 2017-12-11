function [ mdl, logodds ] = LauGlim( Data )
%LAUGLIM Statistical model to predict single trial choice behavior as in
%Lau and Glimcher's JEAB paper (2005?)

y = Data.Custom.ChoiceLeft(:);
C = y;
C(y==0) = -1;
R = Data.Custom.Rewarded(:).*C; % hopefully vectors of same length at all times
C = repmat(C,1,5);
R = repmat(R,1,5);

for j = 1:size(C,2)
    C(:,j) = circshift(C(:,j),j);
    C(1:j,j) = 0;
    R(:,j) = circshift(R(:,j),j);
    R(1:j,j) = 0;
end

X = [C, R];
X(isnan(X)) = 0;
mdl = fitglm(X,y,'distribution','binomial');
logodds = mdl.predict(X);
logodds = log(logodds) - log(1-logodds);
end


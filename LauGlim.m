function [ mdl ] = LauGlim( Data )
%LAUGLIM Statistical model to predict single trial choice behavior as in
%Lau and Glimcher's JEAB paper (2005?)

y = Data.Custom.ChoiceLeft(:);
y(y==0) = -1;
y(isnan(y)) = 0;
C = repmat(y,1,5);
R = Data.Custom.Rewarded(:).*y; % hopefully vectors of same length at all times
R = repmat(R,1,5);
ndx = y(:,1)~=0;
C = C(ndx,:);
R = R(ndx,:);
y = y(ndx,:);
for j = 1:size(C,2)
    C(:,j) = circshift(C(:,j),j);
    C(1:j,j) = 0;
    R(:,j) = circshift(R(:,j),j);
    R(1:j,j) = 0;
end
X = [C, R];
mdl = fitglm(X,y);
end


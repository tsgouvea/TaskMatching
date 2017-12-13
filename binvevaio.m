function [ newxdata, newydata ] = binvevaio( xdata, ydata, nbins )
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

xdata = xdata(:);
ydata = ydata(:);

if nargin < 3
    nbins = ceil(numel(xdata)/10);
end

newxdata = nan(nbins,1);
newydata = nan(nbins,1);
ndx = nan(numel(xdata),1);

for ibin = 1:nbins
%     newxdata = prctile(xdata,100*ibin/nbins);
    ndx(isnan(ndx) & xdata <= prctile(xdata,100*ibin/nbins)) = ibin;
    newxdata(ibin) = mean(xdata(ndx==ibin));
    newydata(ibin) = mean(ydata(ndx==ibin));
end




end


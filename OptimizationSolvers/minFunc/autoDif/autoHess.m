function [f,g,H] = autoHess(x,type,funObj,varargin)% Numerically compute Hessian of objective function from gradient valuesp = length(x);if type == 1	% Use finite differencing	mu = 2*sqrt(1e-12)*(1+norm(x));		[f,g] = funObj(x,varargin{:});	diff = zeros(p);	for j = 1:p		e_j = zeros(p,1);		e_j(j) = 1;		[f diff(:,j)] = funObj(x + mu*e_j,varargin{:});	end	H = (diff-repmat(g,[1 p]))/mu;elseif type == 3 % Use Complex Differentials	mu = 1e-150;		diff = zeros(p);    f=zeros(p,1);	for j = 1:p		e_j = zeros(p,1);		e_j(j) = 1;		[f(j) diff(:,j)] = funObj(x + mu*1i*e_j,varargin{:});	end	f = mean(real(f));	g = mean(real(diff),2);	H = imag(diff)/mu;else % Use central differencing	mu = 2*sqrt(1e-12)*(1+norm(x));	f1 = zeros(p,1);	f2 = zeros(p,1);	diff1 = zeros(p);	diff2 = zeros(p);	for j = 1:p		e_j = zeros(p,1);		e_j(j) = 1;		[f1(j) diff1(:,j)] = funObj(x + mu*e_j,varargin{:});		[f2(j) diff2(:,j)] = funObj(x - mu*e_j,varargin{:});	end	f = mean([f1;f2]);	g = mean([diff1 diff2],2);	H = (diff1-diff2)/(2*mu);end% Make sure H is symmetricH = (H+H')/2;if 0 % DEBUG CODE	[fReal gReal HReal] = funObj(x,varargin{:});	[fReal f]	[gReal g]	[HReal H]	pause;end
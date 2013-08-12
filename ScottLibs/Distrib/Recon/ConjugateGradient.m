clc; clear all; close all;
% Define matrix math
% A = [1 -1
%      1 3];
% b = [0
%     0];

A = [1 -1
    1 3
    0 1];
b = [0
    0
    2];

x = -10:0.1:10;
nlines = size(A,1);
npts = length(x);

% Calculate y values of lines
y = zeros(nlines,npts);
for i=1:nlines
    %Plot each line
    y(i,:) = (A(i,1)*x+b(i))/A(i,2);
end

% Calculate least squared error
xy = pinv(A)*b;

% Calculate residuals at each point
nsamps = 20;
lsp = linspace(-10,10,nsamps);
[x_ y_] = meshgrid(lsp, lsp);
b_ = A*[x_(:)';y_(:)'];
R = (b_-repmat(b,[1,length(x_(:))]));
Rsq = dot(R,R);

guess = [-7;-7];

figure();
contourf(x_,y_,reshape(Rsq,size(x_)),nsamps^2,'LineStyle','none');
hold on;
plot(xy(1),xy(2),'or');
plot(guess(1),guess(2),'ow');
plot(repmat(x,[nlines 1])',y','-w');
plot(xy(1),xy(2),'or');
legend('residual','minimum residual/error','guess','lines');
colormap(jet);
colorbar

niter = 3;
for i=1:niter
    last_guess = guess;
    resid = b-A*guess;
    alpha = (resid'*resid)/((resid'*A)*resid);
    guess = guess + alpha*r;
    
end
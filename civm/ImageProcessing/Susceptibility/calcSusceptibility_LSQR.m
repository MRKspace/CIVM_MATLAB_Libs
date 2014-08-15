function [X,coeff] = calcSusceptibility_LSQR(phi,BrainMask,parameter)
%%
% input:
% phi       - filtered phase
% BrainMask - a binary mask
% parameter - structure
%             .TE (ms); .B0 (T); .FOV (1x3 mm);
%             .gamma (cycle/T); .H (e.g. [0 0 1])
% output:
% X         - apparent susceptibility map (ppm)
% Chunlei Liu, Duke University. 07/09
% Wei Li, Duke University. 5/28/10
% Chunlei Liu, 10/2011

%%
global SS D2 Mask nIters 

if isfield(parameter,'gamma')
    gamma = parameter.gamma*1e-6; % for non-proton
else
    gamma = 42.577*2*pi; % gamma/1e6
end
TE = parameter.TE*1.0e-3;%8*1.0e-3; % ms -> s
B0 = parameter.B0; %7; % T 
FOV = parameter.FOV; % mm
H = parameter.H; % e.g. [0 0 1]
if(isfield(parameter,'niter'))
    option.niter = parameter.niter;
else
    option.niter = 10;
end

coeff.X = 1/(gamma*B0*TE);
coeff.Freq=1/(2*pi*TE);


tic
Mask=double(BrainMask);
%% define coordinates
SS=size(phi);
[ry,rx,rz] = meshgrid(-SS(2)/2:SS(2)/2-1,-SS(1)/2:SS(1)/2-1,-SS(3)/2:SS(3)/2-1);

rx=rx/FOV(1);
ry=ry/FOV(2);
rz=rz/FOV(3);


r2 = rx.^2 + ry.^2 + rz.^2;
r2(r2==0) = 1e6;
%% Fourier
D2 = ((H(1)*rx+H(2)*ry+H(3)*rz).^2)./r2; 
%D2 = rz.^2./r2; 
D2 = (1/3-D2); 
%D2(end/2+1,end/2+1,end/2+1) = -2/3;

%% find b
%b = ifftnc(D2.*fftnc(QualityMap.*phi));
b = ifftn(D2.*fftn(BrainMask.*phi));

clear phi BrainMask r2 rx ry rz


%% solve it
fprintf('find susceptibility...\n');
nIters=0;  % For counting within the function
tol = 0.000001;
% [X,flag,relres]  = lsqr(D2,b);
[X,flag,relres]  = lsqr(@(x,tflag)Afun_lsqr(x,tflag),b(:),tol,option.niter,[],[]);
X = reshape(real(X),SS);

X=X.*Mask;

X = X*coeff.X; % ppm

disp([ 'The relative residual norm(b-A*x)/norm(b): ' num2str(relres) '.' ])
disp([ 'Total CPU Time: ' num2str(round(toc/60)) 'min.'])
return

function Ax = Afun_lsqr(x,~)
global SS D2 nIters Mask 

x=reshape(x,SS);
Ax=ifftn(D2.*fftn(Mask.*ifftn(D2.*fftn(x))));
Ax = Ax(:);

    disp(['  ' num2str(nIters) ' steps: ' num2str(round(toc)) ' sec;'])
    nIters=nIters+1;

return


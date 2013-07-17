% Performs a flip angle calibration by fitting 
function flipAngleCalibration(pfilename)
% Hard coded values
flip_cal_views = 20;

% Read GE revision
[revision, logo] = ge_read_basic_header(pfilename);

% Read heder and data from pfile
[header fid_data] = ge_read_pfile(pfilename, floor(revision));

% Remove baseline views
skip_frames = header.rdb.rdb_hdr_da_yres; %Changed to improve skip frames (was rdb_hdr_nframes)
npts = header.rdb.rdb_hdr_frame_size;%view points
nframes  = header.rdb.rdb_hdr_user20; %will change to header.rdb.rdb_hdr_user5 once baselines are removed;
fid_data(:, 1:skip_frames:nframes) = []; % Remove baselines (junk views)
nframes  = length(fid_data(:))/npts; %Correct number of frames
header.rdb.rdb_hdr_user20 = nframes; %Update header

% Find FID peaks
fid_peaks=max(abs(fid_data(:,1:flip_cal_views)))';  % find max amplitude in each view

% Fit cosine function in LSQR
% Fit cosine function in LSQR
fitfunction = @(a,b,x)a*cos(b).^(x-1);   % cos theta decay
init_guess=[fid_peaks(1),10*pi/180]; % just guess 10 degrees
xdata = [1:flip_cal_views]';

% Get initial crappy estimate of flip angle
[cfun,gof,output] = fit(xdata, fid_peaks, fitfunction, ...
    'StartPoint',init_guess);

for i=1:10
    % Calculate weights
    weights = (feval(cfun,xdata)/feval(cfun,0)).^2; % weights are squared error
    
    % Recalculate fit using weights
    [cfun,gof,output] = fit(xdata, fid_peaks, fitfunction, ...
        'StartPoint',init_guess,...
        'Robust','Bisquare','Weights', weights);
end

% old way
fitfunction = @(coefs,xdata)coefs(1)*cos(coefs(2)).^(xdata-1);   % cos theta decay
init_guess=[fid_peaks(1),10*pi/180]; % just guess 10 degrees
xdata = [1:flip_cal_views]';
[fitparams,resnorm,residual,exitflag,output,lambda,jacobian]  = ...
    lsqcurvefit(fitfunction,init_guess,xdata,fid_peaks);

% Estimate error
conf_intervals = nlparci(fitparams,residual,jacobian);  % returns 95% conf intervals on fitparams by default
param_err=fitparams-conf_intervals(:,1)';

% Estimate flip angle
flip_angle=fitparams(2)*180/pi;
flip_err=param_err(2)*180/pi;
flip_cal_msg = sprintf('\nFlip angle = %1.3f +-%1.3f', flip_angle, flip_err);
disp(flip_cal_msg);

% Calculate fit curve
x_fit=linspace(0,flip_cal_views,100);    % create
y_fit=fitfunction(fitparams,x_fit);

figure();
plot(x_fit, y_fit, '-g')
hold on; 
plot(cfun,'-r')
plot(xdata,fid_peaks,'+b')
hold off; 
legend('new fit','old fit','data');
 
% Calculate where to put text
xloc=round(0.6*flip_cal_views);
yloc=round(0.67*(fid_peaks(1)-fid_peaks(end))+fid_peaks(end));

% Calculate error bars from 95% conf interval
error_upper = fitfunction(conf_intervals(:,1)',x_fit);
error_lower = fitfunction(conf_intervals(:,2)',x_fit);

% Show calibration on plot
fig = figure();
plot(fid_peaks,'ks');
hold on;
plot(x_fit,y_fit,'-k');% append the fit
text(xloc,yloc,flip_cal_msg);
% plot(x_fit, error_upper,'-r');
% plot(x_fit, error_lower,'-g');
patch([x_fit fliplr(x_fit)], [error_upper fliplr(error_lower)],1,'facecolor','blue','edgecolor','blue','facealpha',0.35);
box on;
set(gca,'XMinorTick', 'on')
set(gca,'YMinorTick', 'on')
xlabel('frame');
ylabel('echo peaks');
title('Flip calibration');
hold off

% image_file = strcat(p_file,'_flipAngleCal.jpeg');
%     saveas(h,image_file,'jpeg');
end
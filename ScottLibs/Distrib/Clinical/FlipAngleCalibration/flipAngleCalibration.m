%flipAngleCalibration performs a flip angle calibration
%   flipAngleFile = flipAngleCalibration(p_file, preferences)
%
%   See also
%
%   $Author: Scott Haile Robertson $
%   $Date: 2013/09/07 07:22:45 $
function flipAngleCalibration(p_file, preferences)

% Read Pfile header
[revision, logo] = ge_read_rdb_rev_and_logo(p_file);
[data, traj, weights, header] = GE_Recon_Prep(p_file, floor(revision), p_file);

%% Get header info from calibration scan
cal_scan.tg = header.ge_header.rdb.rdb_hdr_ps_mps_tg;
cal_scan.sinct = 1040; %(us)
cal_scan.lopflip = 90; %degrees  header.ge_header.image.user4?
cal_scan.npts = header.ge_header.rdb.rdb_hdr_da_xres;
cal_scan.nframes = header.ge_header.rdb.rdb_hdr_user20;
cal_scan.loopfactor = header.ge_header.rdb.rdb_hdr_user10;
%calscan.opflip = header.ge_header.rdb.rdb_hdr_user0;
cal_scan.n_spect_frames = header.ge_header.image.user14 + 1; % WHY PLUS ONE???
cal_scan.n_cal_frames = cal_scan.nframes - cal_scan.n_spect_frames - 1; % Why extra baseline?
% cal_scan.n______frames = header.ge_header.image.user%15/13

%% Split data into calibration and spectroscopy frames
data = reshape(data,[cal_scan.npts cal_scan.nframes]);
data(:,1)=[]; % Extra junk view?
cal_scan.cal_data = data(:,1:cal_scan.n_cal_frames);
cal_scan.spect_data = data(:,cal_scan.n_cal_frames+1:end);

%% Calculate mean magnitude of DC values
rad_traj  = calc_radial_traj_distance(header.ge_header);
n_dc_points = sum(rad_traj==0);
cal_scan.dc_mean_mag = mean(abs(cal_scan.cal_data(1:n_dc_points,:)))';
cal_scan.dc_snr_weights = cal_scan.dc_mean_mag/max(cal_scan.dc_mean_mag(:));

%% Calculate the flip angle using a weighted cosine regression
x=[1:cal_scan.n_cal_frames]';
a_guess=cal_scan.dc_mean_mag(1);
b_guess=10;       % just guess 10 degrees
guess = [a_guess b_guess];
fitfunct = @(a,b,x)a*cosd(b).^(x-1);   % cos theta decay
f = fittype(fitfunct);
% fit_obj = fit(x,cal_scan.dc_mean_mag,f,'StartPoint',guess,'Robust','on','Weight',cal_scan.dc_snr_weights);
% fit_obj = fit(x,cal_scan.dc_mean_mag,f,'StartPoint',guess,'Robust','on');
fit_obj = fit(x,cal_scan.dc_mean_mag,f,'StartPoint',guess)

flip_angle = fit_obj.b;
% new_flip_error = fit_obj.confint

%% Make fitted curve
x_fit = 0:0.01:cal_scan.n_cal_frames;
y_fit =  feval(fitfunct,fit_obj.a,fit_obj.b,x_fit);
msg = sprintf('\nFlip angle = %1.3f',flip_angle);
xloc=round(0.67*cal_scan.n_cal_frames);
yloc=round(0.67*(cal_scan.dc_mean_mag(1)-cal_scan.dc_mean_mag(end))+cal_scan.dc_mean_mag(end));

figure
plot(x,cal_scan.dc_mean_mag,'k+')
box on;
set(gca,'XMinorTick', 'on')
set(gca,'YMinorTick', 'on')
xlabel('frame');
ylabel('echo peaks');
title('Flip calibration');
hold on
plot(x_fit,y_fit,'-r')               % append the fit
text(xloc,yloc,msg);
hold off;

%% Show phase of FIDs
figure();
subplot(3,1,1);
plot(real(cal_scan.cal_data(:)));
grid on;
xlabel('points');
ylabel('Real Signal');

subplot(3,1,2);
plot(imag(cal_scan.cal_data(:)));
grid on;
xlabel('points');
ylabel('Imaginary Signal');

subplot(3,1,3);
plot(abs(cal_scan.cal_data(:)));
grid on;
xlabel('points');
ylabel('Magnitude');

%% Show the magnitude of the FIDs
figure();
surf(abs(cal_scan.cal_data));
shading interp;
xlabel('Frame Number');
ylabel('Sample Point allong FID');
zlabel('Magnitude');
set(gca,'YDir','Reverse');

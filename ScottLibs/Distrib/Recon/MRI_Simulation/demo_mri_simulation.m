% Start with a clean slate
clc; clear all; close all;

%% Simulation parameters
fov = 25; %cm
s1 = 0;   % Background signal value
s2 = 100; % Interior filling
s3 = 25;  % Outer structure of phantom
s4 = 50;  % Interior structures

scale = 1;

% Make fake header
header     = struct();
header.rdb = struct();

% % Dual scan
% header.rdb.rdb_hdr_user12 = 15.63;      % Receiver bandwidth
% header.rdb.rdb_hdr_user22 = 0.064;      % Time between ADC on and start of gradient ramp
% header.rdb.rdb_hdr_user1 = 1.01;        % Time to ramp gradients
% header.rdb.rdb_hdr_frame_size = 100;	% Number of sample points per frame/ray
% header.rdb.rdb_hdr_user21 = 1600;       % NUFFT=1400, Gridding=1600
% nframes = 1001;
% primeplus = 101;
% loop_factor = 271;

% Ventilation scan
header.rdb.rdb_hdr_user12 = 15.63;      % Receiver bandwidth
header.rdb.rdb_hdr_user22 = 0.048;      % Time between ADC on and start of gradient ramp
header.rdb.rdb_hdr_user1 = 0.508;        % Time to ramp gradients
header.rdb.rdb_hdr_frame_size = 100;	% Number of sample points per frame/ray
header.rdb.rdb_hdr_user21 = 1600;       % NUFFT=1400, Gridding=1600
nframes = 4601;
primeplus = 101;
loop_factor = 1201;
flip_angle = 1.531633603295065107;

% NUFFT Reconstruction options
nNeighbors = 3;
overgridfactor = 2;
dcf_iter = 10;

% Gridding reconstruction options
overgridfactor_grid = 3;
kernel_width   = 1;
kernel_lut_size = 2000;

%% Setup simulated phantom - see mri_objects
% Cylinder Definitions
%    [xcent  ycent  zcent  xrad  depth  cyldim value]
cp = [
    % Outer shell
    0      0      0      6.95  18.4    3      (s3-s1);       % outer edge of cylinder
    0      0      0      6.31  18.4    3      (s2-s3-s1)     % Inner edge of cylinder
    0      0      9.7    6.95  1       3      (s3-s1)        % Round top
    
    % Z axis disc
    0      0      0      6.31  2.57    3      (s4-s2-s1) % Z interior slab
    
    % X 0.3cm top holes (27 total)
    -2.285 0      2.285  0.15   2.57    2      (s2-s4) % col 1
    -2.285 0      2.91   0.15   2.57    2      (s2-s4)
    -2.285 0      3.535  0.15   2.57    2      (s2-s4)
    -2.285 0      4.16   0.15   2.57    2      (s2-s4)
    -2.285 0      4.785  0.15   2.57    2      (s2-s4)
    -2.285 0      5.41   0.15   2.57    2      (s2-s4)
    -2.285 0      6.035  0.15   2.57    2      (s2-s4)
    -2.285 0      6.66   0.15   2.57    2      (s2-s4)
    -2.285 0      7.285  0.15   2.57    2      (s2-s4)
    -2.91  0      2.285  0.15   2.57    2      (s2-s4) % col 2
    -2.91  0      2.91   0.15   2.57    2      (s2-s4)
    -2.91  0      3.535  0.15   2.57    2      (s2-s4)
    -2.91  0      4.16   0.15   2.57    2      (s2-s4)
    -2.91  0      4.785  0.15   2.57    2      (s2-s4)
    -2.91  0      5.41   0.15   2.57    2      (s2-s4)
    -2.91  0      6.035  0.15   2.57    2      (s2-s4)
    -2.91  0      6.66   0.15   2.57    2      (s2-s4)
    -2.91  0      7.285  0.15   2.57    2      (s2-s4)
    -3.535 0      2.285  0.15   2.57    2      (s2-s4) % col 3
    -3.535 0      2.91   0.15   2.57    2      (s2-s4)
    -3.535 0      3.535  0.15   2.57    2      (s2-s4)
    -3.535 0      4.16   0.15   2.57    2      (s2-s4)
    -3.535 0      4.785  0.15   2.57    2      (s2-s4)
    -3.535 0      5.41   0.15   2.57    2      (s2-s4)
    -3.535 0      6.035  0.15   2.57    2      (s2-s4)
    -3.535 0      6.66   0.15   2.57    2      (s2-s4)
    -3.535 0      7.285  0.15   2.57    2      (s2-s4)
    
    % Y 0.3cm top holes (27 total)
    0      -2.285 2.285  0.15   2.57    1      (s2-s4) % col 1
    0      -2.285 2.91   0.15   2.57    1      (s2-s4)
    0      -2.285 3.535  0.15   2.57    1      (s2-s4)
    0      -2.285 4.16   0.15   2.57    1      (s2-s4)
    0      -2.285 4.785  0.15   2.57    1      (s2-s4)
    0      -2.285 5.41   0.15   2.57    1      (s2-s4)
    0      -2.285 6.035  0.15   2.57    1      (s2-s4)
    0      -2.285 6.66   0.15   2.57    1      (s2-s4)
    0      -2.285 7.285  0.15   2.57    1      (s2-s4)
    0      -2.91  2.285  0.15   2.57    1      (s2-s4) % col 2
    0      -2.91  2.91   0.15   2.57    1      (s2-s4)
    0      -2.91  3.535  0.15   2.57    1      (s2-s4)
    0      -2.91  4.16   0.15   2.57    1      (s2-s4)
    0      -2.91  4.785  0.15   2.57    1      (s2-s4)
    0      -2.91  5.41   0.15   2.57    1      (s2-s4)
    0      -2.91  6.035  0.15   2.57    1      (s2-s4)
    0      -2.91  6.66   0.15   2.57    1      (s2-s4)
    0      -2.91  7.285  0.15   2.57    1      (s2-s4)
    0      -3.535 2.285  0.15   2.57    1      (s2-s4) % col 3
    0      -3.535 2.91   0.15   2.57    1      (s2-s4)
    0      -3.535 3.535  0.15   2.57    1      (s2-s4)
    0      -3.535 4.16   0.15   2.57    1      (s2-s4)
    0      -3.535 4.785  0.15   2.57    1      (s2-s4)
    0      -3.535 5.41   0.15   2.57    1      (s2-s4)
    0      -3.535 6.035  0.15   2.57    1      (s2-s4)
    0      -3.535 6.66   0.15   2.57    1      (s2-s4)
    0      -3.535 7.285  0.15   2.57    1      (s2-s4)
    
    % X 2cm bottom holes(90 total)
    -2.285 0     -2.285  0.1    2.57    2      (s2-s4) % col 1
    -2.285 0     -2.645  0.1    2.57    2      (s2-s4)
    -2.285 0     -3.005  0.1    2.57    2      (s2-s4)
    -2.285 0     -3.365  0.1    2.57    2      (s2-s4)
    -2.285 0     -3.725  0.1    2.57    2      (s2-s4)
    -2.285 0     -4.085  0.1    2.57    2      (s2-s4)
    -2.285 0     -4.445  0.1    2.57    2      (s2-s4)
    -2.285 0     -4.805  0.1    2.57    2      (s2-s4)
    -2.285 0     -5.165  0.1    2.57    2      (s2-s4)
    -2.285 0     -5.525  0.1    2.57    2      (s2-s4)
    -2.645 0     -2.285  0.1    2.57    2      (s2-s4) % col 2
    -2.645 0     -2.645  0.1    2.57    2      (s2-s4)
    -2.645 0     -3.005  0.1    2.57    2      (s2-s4)
    -2.645 0     -3.365  0.1    2.57    2      (s2-s4)
    -2.645 0     -3.725  0.1    2.57    2      (s2-s4)
    -2.645 0     -4.085  0.1    2.57    2      (s2-s4)
    -2.645 0     -4.445  0.1    2.57    2      (s2-s4)
    -2.645 0     -4.805  0.1    2.57    2      (s2-s4)
    -2.645 0     -5.165  0.1    2.57    2      (s2-s4)
    -2.645 0     -5.525  0.1    2.57    2      (s2-s4)
    -3.005 0     -2.285  0.1    2.57    2      (s2-s4) % col 3
    -3.005 0     -2.645  0.1    2.57    2      (s2-s4)
    -3.005 0     -3.005  0.1    2.57    2      (s2-s4)
    -3.005 0     -3.365  0.1    2.57    2      (s2-s4)
    -3.005 0     -3.725  0.1    2.57    2      (s2-s4)
    -3.005 0     -4.085  0.1    2.57    2      (s2-s4)
    -3.005 0     -4.445  0.1    2.57    2      (s2-s4)
    -3.005 0     -4.805  0.1    2.57    2      (s2-s4)
    -3.005 0     -5.165  0.1    2.57    2      (s2-s4)
    -3.005 0     -5.525  0.1    2.57    2      (s2-s4)
    -3.365 0     -2.285  0.1    2.57    2      (s2-s4) % col 4
    -3.365 0     -2.645  0.1    2.57    2      (s2-s4)
    -3.365 0     -3.005  0.1    2.57    2      (s2-s4)
    -3.365 0     -3.365  0.1    2.57    2      (s2-s4)
    -3.365 0     -3.725  0.1    2.57    2      (s2-s4)
    -3.365 0     -4.085  0.1    2.57    2      (s2-s4)
    -3.365 0     -4.445  0.1    2.57    2      (s2-s4)
    -3.365 0     -4.805  0.1    2.57    2      (s2-s4)
    -3.365 0     -5.165  0.1    2.57    2      (s2-s4)
    -3.365 0     -5.525  0.1    2.57    2      (s2-s4)
    -3.725 0     -2.285  0.1    2.57    2      (s2-s4) % col 5
    -3.725 0     -2.645  0.1    2.57    2      (s2-s4)
    -3.725 0     -3.005  0.1    2.57    2      (s2-s4)
    -3.725 0     -3.365  0.1    2.57    2      (s2-s4)
    -3.725 0     -3.725  0.1    2.57    2      (s2-s4)
    -3.725 0     -4.085  0.1    2.57    2      (s2-s4)
    -3.725 0     -4.445  0.1    2.57    2      (s2-s4)
    -3.725 0     -4.805  0.1    2.57    2      (s2-s4)
    -3.725 0     -5.165  0.1    2.57    2      (s2-s4)
    -3.725 0     -5.525  0.1    2.57    2      (s2-s4)
    -4.085 0     -2.285  0.1    2.57    2      (s2-s4) % col 6
    -4.085 0     -2.645  0.1    2.57    2      (s2-s4)
    -4.085 0     -3.005  0.1    2.57    2      (s2-s4)
    -4.085 0     -3.365  0.1    2.57    2      (s2-s4)
    -4.085 0     -3.725  0.1    2.57    2      (s2-s4)
    -4.085 0     -4.085  0.1    2.57    2      (s2-s4)
    -4.085 0     -4.445  0.1    2.57    2      (s2-s4)
    -4.085 0     -4.805  0.1    2.57    2      (s2-s4)
    -4.085 0     -5.165  0.1    2.57    2      (s2-s4)
    -4.085 0     -5.525  0.1    2.57    2      (s2-s4)
    -4.445 0     -2.285  0.1    2.57    2      (s2-s4) % col 7
    -4.445 0     -2.645  0.1    2.57    2      (s2-s4)
    -4.445 0     -3.005  0.1    2.57    2      (s2-s4)
    -4.445 0     -3.365  0.1    2.57    2      (s2-s4)
    -4.445 0     -3.725  0.1    2.57    2      (s2-s4)
    -4.445 0     -4.085  0.1    2.57    2      (s2-s4)
    -4.445 0     -4.445  0.1    2.57    2      (s2-s4)
    -4.445 0     -4.805  0.1    2.57    2      (s2-s4)
    -4.445 0     -5.165  0.1    2.57    2      (s2-s4)
    -4.445 0     -5.525  0.1    2.57    2      (s2-s4)
    -4.805 0     -2.285  0.1    2.57    2      (s2-s4) % col 8
    -4.805 0     -2.645  0.1    2.57    2      (s2-s4)
    -4.805 0     -3.005  0.1    2.57    2      (s2-s4)
    -4.805 0     -3.365  0.1    2.57    2      (s2-s4)
    -4.805 0     -3.725  0.1    2.57    2      (s2-s4)
    -4.805 0     -4.085  0.1    2.57    2      (s2-s4)
    -4.805 0     -4.445  0.1    2.57    2      (s2-s4)
    -4.805 0     -4.805  0.1    2.57    2      (s2-s4)
    -4.805 0     -5.165  0.1    2.57    2      (s2-s4)
    -4.805 0     -5.525  0.1    2.57    2      (s2-s4)
    -5.165 0     -2.285  0.1    2.57    2      (s2-s4) % col 9
    -5.165 0     -2.645  0.1    2.57    2      (s2-s4)
    -5.165 0     -3.005  0.1    2.57    2      (s2-s4)
    -5.165 0     -3.365  0.1    2.57    2      (s2-s4)
    -5.165 0     -3.725  0.1    2.57    2      (s2-s4)
    -5.165 0     -4.085  0.1    2.57    2      (s2-s4)
    -5.165 0     -4.445  0.1    2.57    2      (s2-s4)
    -5.165 0     -4.805  0.1    2.57    2      (s2-s4)
    -5.165 0     -5.165  0.1    2.57    2      (s2-s4)
    -5.165 0     -5.525  0.1    2.57    2      (s2-s4)
    
    % Y 2cm bottom holes(90 total)
    0     -2.285 -2.285  0.1    2.57    1      (s2-s4) % col 1
    0     -2.285 -2.645  0.1    2.57    1      (s2-s4)
    0     -2.285 -3.005  0.1    2.57    1      (s2-s4)
    0     -2.285 -3.365  0.1    2.57    1      (s2-s4)
    0     -2.285 -3.725  0.1    2.57    1      (s2-s4)
    0     -2.285 -4.085  0.1    2.57    1      (s2-s4)
    0     -2.285 -4.445  0.1    2.57    1      (s2-s4)
    0     -2.285 -4.805  0.1    2.57    1      (s2-s4)
    0     -2.285 -5.165  0.1    2.57    1      (s2-s4)
    0     -2.285 -5.525  0.1    2.57    1      (s2-s4)
    0     -2.645 -2.285  0.1    2.57    1      (s2-s4) % col 2
    0     -2.645 -2.645  0.1    2.57    1      (s2-s4)
    0     -2.645 -3.005  0.1    2.57    1      (s2-s4)
    0     -2.645 -3.365  0.1    2.57    1      (s2-s4)
    0     -2.645 -3.725  0.1    2.57    1      (s2-s4)
    0     -2.645 -4.085  0.1    2.57    1      (s2-s4)
    0     -2.645 -4.445  0.1    2.57    1      (s2-s4)
    0     -2.645 -4.805  0.1    2.57    1      (s2-s4)
    0     -2.645 -5.165  0.1    2.57    1      (s2-s4)
    0     -2.645 -5.525  0.1    2.57    1      (s2-s4)
    0     -3.005 -2.285  0.1    2.57    1      (s2-s4) % col 3
    0     -3.005 -2.645  0.1    2.57    1      (s2-s4)
    0     -3.005 -3.005  0.1    2.57    1      (s2-s4)
    0     -3.005 -3.365  0.1    2.57    1      (s2-s4)
    0     -3.005 -3.725  0.1    2.57    1      (s2-s4)
    0     -3.005 -4.085  0.1    2.57    1      (s2-s4)
    0     -3.005 -4.445  0.1    2.57    1      (s2-s4)
    0     -3.005 -4.805  0.1    2.57    1      (s2-s4)
    0     -3.005 -5.165  0.1    2.57    1      (s2-s4)
    0     -3.005 -5.525  0.1    2.57    1      (s2-s4)
    0     -3.365 -2.285  0.1    2.57    1      (s2-s4) % col 4
    0     -3.365 -2.645  0.1    2.57    1      (s2-s4)
    0     -3.365 -3.005  0.1    2.57    1      (s2-s4)
    0     -3.365 -3.365  0.1    2.57    1      (s2-s4)
    0     -3.365 -3.725  0.1    2.57    1      (s2-s4)
    0     -3.365 -4.085  0.1    2.57    1      (s2-s4)
    0     -3.365 -4.445  0.1    2.57    1      (s2-s4)
    0     -3.365 -4.805  0.1    2.57    1      (s2-s4)
    0     -3.365 -5.165  0.1    2.57    1      (s2-s4)
    0     -3.365 -5.525  0.1    2.57    1      (s2-s4)
    0     -3.725 -2.285  0.1    2.57    1      (s2-s4) % col 5
    0     -3.725 -2.645  0.1    2.57    1      (s2-s4)
    0     -3.725 -3.005  0.1    2.57    1      (s2-s4)
    0     -3.725 -3.365  0.1    2.57    1      (s2-s4)
    0     -3.725 -3.725  0.1    2.57    1      (s2-s4)
    0     -3.725 -4.085  0.1    2.57    1      (s2-s4)
    0     -3.725 -4.445  0.1    2.57    1      (s2-s4)
    0     -3.725 -4.805  0.1    2.57    1      (s2-s4)
    0     -3.725 -5.165  0.1    2.57    1      (s2-s4)
    0     -3.725 -5.525  0.1    2.57    1      (s2-s4)
    0     -4.085 -2.285  0.1    2.57    1      (s2-s4) % col 6
    0     -4.085 -2.645  0.1    2.57    1      (s2-s4)
    0     -4.085 -3.005  0.1    2.57    1      (s2-s4)
    0     -4.085 -3.365  0.1    2.57    1      (s2-s4)
    0     -4.085 -3.725  0.1    2.57    1      (s2-s4)
    0     -4.085 -4.085  0.1    2.57    1      (s2-s4)
    0     -4.085 -4.445  0.1    2.57    1      (s2-s4)
    0     -4.085 -4.805  0.1    2.57    1      (s2-s4)
    0     -4.085 -5.165  0.1    2.57    1      (s2-s4)
    0     -4.085 -5.525  0.1    2.57    1      (s2-s4)
    0     -4.445 -2.285  0.1    2.57    1      (s2-s4) % col 7
    0     -4.445 -2.645  0.1    2.57    1      (s2-s4)
    0     -4.445 -3.005  0.1    2.57    1      (s2-s4)
    0     -4.445 -3.365  0.1    2.57    1      (s2-s4)
    0     -4.445 -3.725  0.1    2.57    1      (s2-s4)
    0     -4.445 -4.085  0.1    2.57    1      (s2-s4)
    0     -4.445 -4.445  0.1    2.57    1      (s2-s4)
    0     -4.445 -4.805  0.1    2.57    1      (s2-s4)
    0     -4.445 -5.165  0.1    2.57    1      (s2-s4)
    0     -4.445 -5.525  0.1    2.57    1      (s2-s4)
    0     -4.805 -2.285  0.1    2.57    1      (s2-s4) % col 8
    0     -4.805 -2.645  0.1    2.57    1      (s2-s4)
    0     -4.805 -3.005  0.1    2.57    1      (s2-s4)
    0     -4.805 -3.365  0.1    2.57    1      (s2-s4)
    0     -4.805 -3.725  0.1    2.57    1      (s2-s4)
    0     -4.805 -4.085  0.1    2.57    1      (s2-s4)
    0     -4.805 -4.445  0.1    2.57    1      (s2-s4)
    0     -4.805 -4.805  0.1    2.57    1      (s2-s4)
    0     -4.805 -5.165  0.1    2.57    1      (s2-s4)
    0     -4.805 -5.525  0.1    2.57    1      (s2-s4)
    0     -5.165 -2.285  0.1    2.57    1      (s2-s4) % col 9
    0     -5.165 -2.645  0.1    2.57    1      (s2-s4)
    0     -5.165 -3.005  0.1    2.57    1      (s2-s4)
    0     -5.165 -3.365  0.1    2.57    1      (s2-s4)
    0     -5.165 -3.725  0.1    2.57    1      (s2-s4)
    0     -5.165 -4.085  0.1    2.57    1      (s2-s4)
    0     -5.165 -4.445  0.1    2.57    1      (s2-s4)
    0     -5.165 -4.805  0.1    2.57    1      (s2-s4)
    0     -5.165 -5.165  0.1    2.57    1      (s2-s4)
    0     -5.165 -5.525  0.1    2.57    1      (s2-s4)
    
    % X 0.5cm diameter bottom holes
    2.785  0     -2.785  0.25    2.57    2      (s2-s4)
    2.785  0     -3.785  0.25    2.57    2      (s2-s4)
    2.785  0     -4.785  0.25    2.57    2      (s2-s4)
    2.785  0     -5.785  0.25    2.57    2      (s2-s4)
    2.785  0     -6.785  0.25    2.57    2      (s2-s4)
    2.785  0     -7.785  0.25    2.57    2      (s2-s4)
    
    % Y 0.5cm diameter bottom holes
    0      2.785  -2.785  0.25    2.57    1      (s2-s4)
    0      2.785  -3.785  0.25    2.57    1      (s2-s4)
    0      2.785  -4.785  0.25    2.57    1      (s2-s4)
    0      2.785  -5.785  0.25    2.57    1      (s2-s4)
    0      2.785  -6.785  0.25    2.57    1      (s2-s4)
    0      2.785  -7.785  0.25    2.57    1      (s2-s4)
    
    % 0.5cm diameter disc hole
    -2.035  2.035   0      0.25    2.57    3      (s2-s4)
    
    % 0.15cm diameter disc holes (total)
    -1.785 -1.785   0      0.075   2.57    3      (s2-s4) % col1
    -2.06  -1.785   0      0.075   2.57    3      (s2-s4)
    -2.335 -1.785   0      0.075   2.57    3      (s2-s4)
    -2.61  -1.785   0      0.075   2.57    3      (s2-s4)
    -2.885 -1.785   0      0.075   2.57    3      (s2-s4)
    -3.16  -1.785   0      0.075   2.57    3      (s2-s4)
    -3.435 -1.785   0      0.075   2.57    3      (s2-s4)
    -3.71  -1.785   0      0.075   2.57    3      (s2-s4)
    -3.984 -1.785   0      0.075   2.57    3      (s2-s4)
    -4.26  -1.785   0      0.075   2.57    3      (s2-s4)
    -1.785 -2.06    0      0.075   2.57    3      (s2-s4) % col2
    -2.06  -2.06    0      0.075   2.57    3      (s2-s4)
    -2.335 -2.06    0      0.075   2.57    3      (s2-s4)
    -2.61  -2.06    0      0.075   2.57    3      (s2-s4)
    -2.885 -2.06    0      0.075   2.57    3      (s2-s4)
    -3.16  -2.06    0      0.075   2.57    3      (s2-s4)
    -3.435 -2.06    0      0.075   2.57    3      (s2-s4)
    -3.71  -2.06    0      0.075   2.57    3      (s2-s4)
    -3.984 -2.06    0      0.075   2.57    3      (s2-s4)
    -4.26  -2.06    0      0.075   2.57    3      (s2-s4)
    -1.785 -2.335   0      0.075   2.57    3      (s2-s4) % col3
    -2.06  -2.335   0      0.075   2.57    3      (s2-s4)
    -2.335 -2.335   0      0.075   2.57    3      (s2-s4)
    -2.61  -2.335   0      0.075   2.57    3      (s2-s4)
    -2.885 -2.335   0      0.075   2.57    3      (s2-s4)
    -3.16  -2.335   0      0.075   2.57    3      (s2-s4)
    -3.435 -2.335   0      0.075   2.57    3      (s2-s4)
    -3.71  -2.335   0      0.075   2.57    3      (s2-s4)
    -3.984 -2.335   0      0.075   2.57    3      (s2-s4)
    -4.26  -2.335   0      0.075   2.57    3      (s2-s4)
    -1.785 -2.61    0      0.075   2.57    3      (s2-s4) % col4
    -2.06  -2.61    0      0.075   2.57    3      (s2-s4)
    -2.335 -2.61    0      0.075   2.57    3      (s2-s4)
    -2.61  -2.61    0      0.075   2.57    3      (s2-s4)
    -2.885 -2.61    0      0.075   2.57    3      (s2-s4)
    -3.16  -2.61    0      0.075   2.57    3      (s2-s4)
    -3.435 -2.61    0      0.075   2.57    3      (s2-s4)
    -3.71  -2.61    0      0.075   2.57    3      (s2-s4)
    -3.984 -2.61    0      0.075   2.57    3      (s2-s4)
    -4.26  -2.61    0      0.075   2.57    3      (s2-s4)
    -1.785 -2.885   0      0.075   2.57    3      (s2-s4) % col5
    -2.06  -2.885   0      0.075   2.57    3      (s2-s4)
    -2.335 -2.885   0      0.075   2.57    3      (s2-s4)
    -2.61  -2.885   0      0.075   2.57    3      (s2-s4)
    -2.885 -2.885   0      0.075   2.57    3      (s2-s4)
    -3.16  -2.885   0      0.075   2.57    3      (s2-s4)
    -3.435 -2.885   0      0.075   2.57    3      (s2-s4)
    -3.71  -2.885   0      0.075   2.57    3      (s2-s4)
    -3.984 -2.885   0      0.075   2.57    3      (s2-s4)
    -4.26  -2.885   0      0.075   2.57    3      (s2-s4)
    -1.785 -3.16    0      0.075   2.57    3      (s2-s4) % col6
    -2.06  -3.16    0      0.075   2.57    3      (s2-s4)
    -2.335 -3.16    0      0.075   2.57    3      (s2-s4)
    -2.61  -3.16    0      0.075   2.57    3      (s2-s4)
    -2.885 -3.16    0      0.075   2.57    3      (s2-s4)
    -3.16  -3.16    0      0.075   2.57    3      (s2-s4)
    -3.435 -3.16    0      0.075   2.57    3      (s2-s4)
    -3.71  -3.16    0      0.075   2.57    3      (s2-s4)
    -3.984 -3.16    0      0.075   2.57    3      (s2-s4)
    -4.26  -3.16    0      0.075   2.57    3      (s2-s4)
    -1.785 -3.435   0      0.075   2.57    3      (s2-s4) % col7
    -2.06  -3.435   0      0.075   2.57    3      (s2-s4)
    -2.335 -3.435   0      0.075   2.57    3      (s2-s4)
    -2.61  -3.435   0      0.075   2.57    3      (s2-s4)
    -2.885 -3.435   0      0.075   2.57    3      (s2-s4)
    -3.16  -3.435   0      0.075   2.57    3      (s2-s4)
    -3.435 -3.435   0      0.075   2.57    3      (s2-s4)
    -3.71  -3.435   0      0.075   2.57    3      (s2-s4)
    -3.984 -3.435   0      0.075   2.57    3      (s2-s4)
    -1.785 -3.71    0      0.075   2.57    3      (s2-s4) % col8
    -2.06  -3.71    0      0.075   2.57    3      (s2-s4)
    -2.335 -3.71    0      0.075   2.57    3      (s2-s4)
    -2.61  -3.71    0      0.075   2.57    3      (s2-s4)
    -2.885 -3.71    0      0.075   2.57    3      (s2-s4)
    -3.16  -3.71    0      0.075   2.57    3      (s2-s4)
    -3.435 -3.71    0      0.075   2.57    3      (s2-s4)
    -3.71  -3.71    0      0.075   2.57    3      (s2-s4)
    -1.785 -3.984   0      0.075   2.57    3      (s2-s4) % col9
    -2.06  -3.984   0      0.075   2.57    3      (s2-s4)
    -2.335 -3.984   0      0.075   2.57    3      (s2-s4)
    -2.61  -3.984   0      0.075   2.57    3      (s2-s4)
    -2.885 -3.984   0      0.075   2.57    3      (s2-s4)
    -3.16  -3.984   0      0.075   2.57    3      (s2-s4)
    -3.435 -3.984   0      0.075   2.57    3      (s2-s4)
    -1.785 -4.26    0      0.075   2.57    3      (s2-s4) % col10
    -2.06  -4.26    0      0.075   2.57    3      (s2-s4)
    -2.335 -4.26    0      0.075   2.57    3      (s2-s4)
    -2.61  -4.26    0      0.075   2.57    3      (s2-s4)
    -2.885 -4.26    0      0.075   2.57    3      (s2-s4)
    -3.16  -4.26    0      0.075   2.57    3      (s2-s4)
    
    % 0.3cm diameter disc holes (total)
    1.785   -1.785   0      0.15    2.57    3      (s2-s4) % row 1
    2.385   -1.785   0      0.15    2.57    3      (s2-s4)
    2.985   -1.785   0      0.15    2.57    3      (s2-s4)
    3.585   -1.785   0      0.15    2.57    3      (s2-s4)
    1.785   -2.385   0      0.15    2.57    3      (s2-s4) % row 2
    2.385   -2.385   0      0.15    2.57    3      (s2-s4)
    2.985   -2.385   0      0.15    2.57    3      (s2-s4)
    1.785   -2.985   0      0.15    2.57    3      (s2-s4) % row 3
    2.385   -2.985   0      0.15    2.57    3      (s2-s4)
    ];

% Rectangle Definitions
%    [xcent    ycent    zcent  xwidth  ywidth  zwidth  value]
rp = [
    % Containter edges
    0        0       -9.805 14.4    14.4    1.21    (s3-s1)        % Bottom square
    
    % Interior plasic
    0        0        5.0175 12.3555 2.57    7.465   (s4-s2-s1) % X top interior slab
    0        0       -5.0175 12.3555 2.57    7.465   (s4-s2-s1) % X bottom interior slab
    0        3.7313   5.0175 2.57    4.89277 7.465   (s4-s2-s1) % Y+ top interior slab
    0       -3.7313   5.0175 2.57    4.89277 7.465   (s4-s2-s1) % Y- top interior slab
    0        3.7313  -5.0175 2.57    4.89277 7.465   (s4-s2-s1) % Y+ top interior slab
    0       -3.7313  -5.0175 2.57    4.89277 7.465   (s4-s2-s1) % Y- bottom interior slab
    
    % X 1cm top Cuttouts (3 total)
    4.72775  0        3.285  2.9     2.57    1       (s2-s4)
    4.72775  0        5.285  2.9     2.57    1       (s2-s4)
    4.72775  0        7.285  2.9     2.57    1       (s2-s4)
    
    % Y 1cm top Cuttouts (3 total)
    0        4.72775  3.285  2.57    2.9     1       (s2-s4)
    0        4.72775  5.285  2.57    2.9     1       (s2-s4)
    0        4.72775  7.285  2.57    2.9     1       (s2-s4)
    
    % X 0.5cm bottom cuttouts (5 total)
    5.67775  0       -3.785  1       2.57    0.5     (s2-s4)
    5.67775  0       -4.785  1       2.57    0.5     (s2-s4)
    5.67775  0       -5.785  1       2.57    0.5     (s2-s4)
    5.67775  0       -6.785  1       2.57    0.5     (s2-s4)
    5.67775  0       -7.785  1       2.57    0.5     (s2-s4)
    
    % Y 0.5cm bottom cuttouts (5 total)
    0        5.67775 -3.785  2.57    1       0.5     (s2-s4)
    0        5.67775 -4.785  2.57    1       0.5     (s2-s4)
    0        5.67775 -5.785  2.57    1       0.5     (s2-s4)
    0        5.67775 -6.785  2.57    1       0.5     (s2-s4)
    0        5.67775 -7.785  2.57    1       0.5     (s2-s4)
    
    % Z disk rectangles
    2.285    3.935    0      1       2       2.57    (s2-s4)
    4.285    3.385    0      1       0.9     2.57    (s2-s4)
    ];

%% Construct phantom object
disp('Creating Object');
phantom = mri_objects('cyl3',cp,'rect3',rp);

% %% Create image domain image
disp('Creating image domain image');
sz = header.rdb.rdb_hdr_frame_size*scale; % image matrix size
lsp = linspace(-fov/2, fov/2,sz);
[x y z] = meshgrid(lsp, lsp, lsp);
% vol = phantom.image(x,y,z);
% 
% % Show phantom
% figure();
% imslice(vol,'Exact phantom');

%% Get trajectories and corresponding k-space data
ending = ['_' num2str(header.rdb.rdb_hdr_user12) ...
    '_' num2str(header.rdb.rdb_hdr_user22) ...
    '_' num2str(header.rdb.rdb_hdr_user1) ...
    '_' num2str(header.rdb.rdb_hdr_frame_size) ...
    '_' num2str(header.rdb.rdb_hdr_user21) ...
    '_' num2str(nframes) ...
    '_' num2str(primeplus) ...
    '_' num2str(loop_factor) ...
    '_fov' num2str(fov) ...
    '.mat'];
data_filename = ['data' ending];
traj_filename = ['traj' ending];
if(exist(data_filename) && exist(traj_filename))
    load(data_filename);
    load(traj_filename);
else
    %% Create k-space samplimg trajectory
    % Create simulated trajectories
    disp('Calculating trajectories');
    [rad, gradient_dist, ideal_dist] = calc_radial_traj_distance(header);
    traj = calc_archimedian_spiral_trajectories(...
        nframes, primeplus, rad); %maybe mult by (sz/fov)
%     traj = traj'*sz/(scale*fov);
    traj = traj';
    
    %% Calculate frequency data using exact fourier transform of object
    disp('Calculating kspace data');
    data = phantom.kspace(traj(:,1),...
        traj(:,2),...
        traj(:,3));
    save(data_filename,'data');
    save(traj_filename,'traj');
end

traj = traj/(sz/(2*scale*fov));

%% Apply loopfactor
old_idx = 1:nframes;
new_idx = mod((old_idx-1)*loop_factor,nframes)+1;
data = reshape(data,[header.rdb.rdb_hdr_frame_size nframes]);
data(:,old_idx) = data(:,new_idx);
traj = reshape(traj, [header.rdb.rdb_hdr_frame_size nframes 3]);
traj(:,old_idx, :) = traj(:,new_idx,:);
traj = reshape(traj,[header.rdb.rdb_hdr_frame_size*nframes 3]);

%% Apply simulated RF decay
min_val = 0.3;
flip_angle = acos(min_val^(1/(nframes-1)))
decay_weight = cos(flip_angle).^([0:(nframes-1)]);
decay_weight = repmat(decay_weight,[header.rdb.rdb_hdr_frame_size 1]);
decay_weight = decay_weight(:);
data = data(:).*decay_weight(:);

% Add noise


%% NUFFT Reconstruction
% Calculate Sample Density Corrections
disp('Reconstructing NUFFT');
N = [sz sz sz];
J = [nNeighbors nNeighbors nNeighbors];
K = ceil(N*overgridfactor);
mask = true(N);

% optimize min-max error accross volume
reconObj.G = Gmri(0.5*traj, mask, 'fov', N, 'nufft_args', {N,J,K,N/2,'minmax:kb'});
clear K J;

disp('Itteratively calculating density compensation coefficients...');
reconObj.wt.pipe = 1./abs(reconObj.G.arg.Gnufft.arg.st.p * ...
    ones(reconObj.G.arg.Gnufft.arg.st.Kd)); % Reasonable first guess
reconObj.wt.max_itter = dcf_iter;

% Calculate density compensation using Pipe method
for iter = 1:dcf_iter
    disp(['   Iteration:' num2str(iter)]);
    reconObj.wt.pipe = abs(reconObj.wt.pipe ./ ...
        ((reconObj.G.arg.Gnufft.arg.st.p * ...
        (reconObj.G.arg.Gnufft.arg.st.p'*(reconObj.wt.pipe)))));
end

% Reconstruct
disp('Reconstructing data with NUFFT...');
% Uses exp_xform_mex.c if exact recon
recon_vol = reshape(reconObj.G' * (reconObj.wt.pipe .* data(:)),reconObj.G.idim);

% Show reconstruction
figure();
imslice(abs(recon_vol),'NUFFT Reconstruction');

% %% Gridding reconstruction
% % Calculate DCF
% disp('Reconstructing Gridding');
% overgridfactor = overgridfactor_grid;
% traj = 0.5*traj;
% disp('Calculating DCF...');
% dcf_type = 4; % 1=Analytical, 2=Hitplane, 3=Voronoi, 4=Itterative, 5=Voronoi+Itterative
% im_sz_dcf = double(round(scale*N));
% numIter = 25;
% saveDCF_dir = '../DCF/precalcDCFvals/';
% while(any(traj(:)>0.5))
%     addIdx = traj(:)>0.5;
%     traj(addIdx) = traj(addIdx) - 1;
% end
% while(any(traj(:)<-0.5))
%     subIdx = traj(:)<-0.5;
%     traj(subIdx) = traj(subIdx) + 1;
% end
% dcf = calcDCF_Itterative(traj', overgridfactor,im_sz_dcf,numIter);
% clear dcf_type im_sz_dcf numIter saveDCF_dir;
% 
% % Apply DCF to data
% data = [real(data)'; -imag(data)'].*repmat(dcf,[2 1]);
% clear dcf;
% 
% %Calculate Gridding Kernel
% disp('Calculating Kernel...');
% kernel_width = kernel_width*overgridfactor; % Account overgridding
% [kernel_vals]=KaiserBesselKernelGenerator(kernel_width, overgridfactor, ...
%     kernel_lut_size);
% clear kernel_lut_size;
% 
% %Regrid the fids
% disp('Gridding...');
% output_dims  = uint32(round(scale*N));
% kspace_vol = grid_conv_mex(data, traj', ...
%     kernel_width, kernel_vals, overgridfactor*output_dims);
% 
% % Calculate IFFT to get image volume
% disp('Calculating IFFT...');
% clear coords data kernel_vals;
% kspace_vol = fftshift(kspace_vol);
% kspace_vol = ifftn(kspace_vol);
% kspace_vol = fftshift(kspace_vol);
% 
% % Crop out center of image to compensate for overgridding
% % disp('Cropping out overgridding...');
% last = (overgridfactor-1)*output_dims/2;
% image_vol = kspace_vol(last(1)+1:last(1)+output_dims(1), ...
%     last(2)+1:last(2)+output_dims(2), ...
%     last(3)+1:last(3)+output_dims(3));
% clear kspace_vol last output_dims;
% 
% % Show the volume
% figure();
% imslice(abs(image_vol),'Gridding Reconstruction');

%% Itterative Recon - no decay correction
niter = 60;
startIter = 50;
recon_pcgq = qpwls_pcg1(0.*recon_vol(:), reconObj.G, 1, ...
    data, 0, 'niter', niter, 'isave',startIter:niter);
recon_pcgq  = reshape(recon_pcgq, [N niter]);
figure();
imslice(abs(recon_pcgq));
colormap(gray);
axis image;
title('Unweighted Conj Grad with no penalty');
colorbar();

%% Itterative Recon - naive decay correction
recon_pcgq = qpwls_pcg1(0.*recon_vol(:), reconObj.G, 1, ...
    data./decay_weight(:), 0, 'niter', niter, 'isave',startIter:niter);
recon_pcgq  = reshape(recon_pcgq, [N niter-st]);
figure();
imslice(abs(recon_pcgq));
colormap(gray);
axis image;
title('Unweighted Conj Grad with no penalty');
colorbar();

%% Itterative Recon - weighted decay correction
niter = 60;
weighting = Gdiag(decay_weight);
recon_pcgq = qpwls_pcg1(0.*recon_vol(:), reconObj.G, weighting, ...
    data./decay_weight, 0, 'niter', niter, 'isave',startIter:niter);
recon_pcgq  = reshape(recon_pcgq, [N niter]);
figure();
imslice(abs(recon_pcgq));
colormap(gray);
axis image;
title('Unweighted Conj Grad with no penalty');
colorbar();
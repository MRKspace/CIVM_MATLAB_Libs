function demo_3d_model_decayCorrection()
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
% header.rdb.rdb_hdr_frame_size = 128;	% Number of sample points per frame/ray
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
loop_factor = 1; % 1201 seems good

% NUFFT Reconstruction options
nNeighbors = 3;
overgridfactor = 2;
dcf_iter = 1;
sz = header.rdb.rdb_hdr_frame_size*scale; % image matrix size
N = [sz sz sz];
J = [nNeighbors nNeighbors nNeighbors];
K = ceil(N*overgridfactor);
mask = true(N);

% Gridding reconstruction options
overgridfactor_grid = 2;
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
lsp = linspace(-fov/2, fov/2,sz);
[x y z] = meshgrid(lsp, lsp, lsp);

% % Show phantom
% vol = phantom.image(x,y,z);
% figure();
% imslice(vol,'Exact phantom');

% Make Cartesian sampled volume
disp('Simulating Cartesian recon');
ending = ['_' num2str(header.rdb.rdb_hdr_frame_size) ...
    '_fov' num2str(fov) ...
    '_cartesian.mat'];
data_filename = ['data' ending];

if(exist(data_filename))
    disp('Loading trajectories from file');
    load(data_filename);
else
    %% Create cartesian k-space data
    u1d = [-sz/2:sz/2-1] / fov; 
    [u v w] = ndgrid(u1d, u1d, u1d);
    data_cartesian = reshape(phantom.kspace(u(:), v(:), w(:)),[sz sz sz]);
    
    disp('Saving cartesian data');
    save(data_filename,'data_cartesian');
end

% Scale data for voxel size (only needed for simulated data)
% data_cartesian = data_cartesian * prod([sz sz sz]/fov);

% Create simulated cartesian recon
ideal_im = fftshift(ifftn(fftshift(data_cartesian)));
% figure();
% imslice(abs(ideal_im),'Cartesian Recon');
% title('Ideal image');
% colormap(gray);
% colorbar();
% axis image;

%% Get trajectories and corresponding k-space data
disp('Getting trajectories');
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
    disp('Loading trajectories from file');
    load(data_filename);
    load(traj_filename);
else
    %% Create k-space samplimg trajectory
    % Create simulated trajectories
    disp('Calculating trajectories');
    [rad, gradient_dist, ideal_dist] = calc_radial_traj_distance(header);
    traj = calc_archimedian_spiral_trajectories(...
        nframes, primeplus, rad); %maybe mult by (sz/fov)
    traj = traj';
    
    %% Calculate frequency data using exact fourier transform of object
    disp('Calculating kspace data');
    traj_physical = traj*(sz/fov);  % put into physical units for sampling simulated object
    data = phantom.kspace(traj_physical(:,1),...
        traj_physical(:,2),...
        traj_physical(:,3));
    
    disp('Saving trajectories');
    save(data_filename,'data');
    save(traj_filename,'traj');
end

% Scale data for voxel size (only needed for simulated data)
% % data = data * prod([sz sz sz]/fov);
% figure();
% surf(abs(reshape(data,[header.rdb.rdb_hdr_frame_size nframes])));
% colormap(jet);
% shading interp;
% title('Exact fft magnitude');

%% Calculate noise
snr = 300;
snr_db = 20*log10(snr);
noise = data - awgn(data,snr_db,'measured');

%% Apply simulated RF decay
min_val = 0.5;
flip_angle = acos(min_val^(1/(nframes-1)))
decay_weight = cos(flip_angle).^([0:(nframes-1)]);
decay_weight = repmat(decay_weight,[header.rdb.rdb_hdr_frame_size 1]);
decay_weight = decay_weight(:);

%% Apply loopfactor
old_idx = 1:nframes;
new_idx = mod((old_idx-1)*loop_factor,nframes)+1;
data = reshape(data,[header.rdb.rdb_hdr_frame_size nframes]);
data(:,old_idx) = data(:,new_idx);
data = reshape(data, [header.rdb.rdb_hdr_frame_size*nframes 1]);
traj = reshape(traj, [header.rdb.rdb_hdr_frame_size nframes 3]);
traj(:,old_idx, :) = traj(:,new_idx,:);
traj = reshape(traj,[header.rdb.rdb_hdr_frame_size*nframes 3]);
% decay_weight = reshape(decay_weight, [header.rdb.rdb_hdr_frame_size nframes]);
% decay_weight(:,old_idx) = decay_weight(:,new_idx);
% decay_weight = reshape(decay_weight, [header.rdb.rdb_hdr_frame_size*nframes 1]);

%% Add noise and decay to signal
data_ideal = data; % make backup
data = data(:).*decay_weight(:) + noise(:);
% figure();
% surf(abs(reshape(data,[header.rdb.rdb_hdr_frame_size nframes])));
% colormap(jet);
% shading interp;
% title('noisy fft magnitude');

%% NUFFT Reconstruction
% Calculate Sample Density Corrections
disp('Reconstructing NUFFT');
reconObj.G = Gmri(traj, mask, 'fov', N, 'nufft_args', {N,J,K,N/2,'minmax:kb'});
clear K J;

% disp('Itteratively calculating density compensation coefficients...');
% reconObj.wt.pipe = 1./abs(reconObj.G.arg.Gnufft.arg.st.p * ...
%     ones(reconObj.G.arg.Gnufft.arg.st.Kd)); % Reasonable first guess
% reconObj.wt.max_itter = dcf_iter;
% 
% % Calculate density compensation using Pipe method
% for iter = 1:dcf_iter
%     disp(['   Iteration:' num2str(iter)]);
%     reconObj.wt.pipe = abs(reconObj.wt.pipe ./ ...
%         ((reconObj.G.arg.Gnufft.arg.st.p * ...
%         (reconObj.G.arg.Gnufft.arg.st.p'*(reconObj.wt.pipe)))));
% end
% 
% 
% %% Conjugate phase reconstruction
% % Raw data - no weighting
% recon_conj_raw = reconObj.G' * (reconObj.wt.pipe .* data(:))*fov/prod(N);
% recon_conj_raw = embed(recon_conj_raw, mask);
% figure();
% imslice(abs(recon_conj_raw),'Conj Phase - Raw');
% colormap(gray);
% axis image;
% title('Conjugate Phase Recon - raw data');
% colorbar();
% 
% % Naive weighting
% recon_conj_naive = reconObj.G' * (reconObj.wt.pipe .* data(:) ./ decay_weight );
% recon_conj_naive = embed(recon_conj_naive, mask);
% figure();
% imslice(abs(recon_conj_naive),'Conj Phase - Naive');
% colormap(gray);
% axis image;
% title('Conjugate Phase Recon - naive weighting');
% colorbar();

%% Conjugate Gradient reconstruction
% Raw data - no weighting
niter = 30;
options.saveBaseName = 'recon_pcgq_raw_';
options.iter = 1;
options.volDims = reconObj.G.arg.Gnufft.arg.st.Nd;
options.ideal_im = ideal_im;
options.data = data;
options.A = reconObj.G;
% qpwls_precon(type, sys, C, mask, varargin)
[recon_pcgq_raw errors_raw] = qpwls_pcg1(0*mask(:), reconObj.G, ...
    1, data, 0, 'niter', niter, 'isave',niter, ...
    'userfun',@saveImageCalcError, 'userarg', {options});
recon_pcgq_raw  = reshape(recon_pcgq_raw, [size(mask)]);
clear recon_pcgq_raw;
% figure();
% imslice(abs(recon_pcgq_raw),'Iterative - Raw data');
% colormap(gray);
% axis image;
% title('Itterative reconstruction - Raw data');
% colorbar();

% Naive weighting
options.saveBaseName = 'recon_pcgq_naive_';
options.iter = 1;
[recon_pcgq_naive errors_naive] = qpwls_pcg1(0*mask(:), reconObj.G, ...
    1, data./decay_weight, 0, 'niter', niter, 'isave',niter, ...
    'userfun',@saveImageCalcError, 'userarg', {options});
clear recon_pcgq_naive;
% recon_pcgq_naive  = reshape(recon_pcgq_naive, [size(mask)]);
% figure();
% imslice(abs(recon_pcgq_naive),'Iterative - naive weighted');
% colormap(gray);
% axis image;
% title('Itterative reconstruction - naive weighting');
% colorbar();

% Model based reconstruction with RF weighting
options.saveBaseName = 'recon_pcgq_snrWeighted_';
options.iter = 1;
options.volDims = reconObj.G.arg.Gnufft.arg.st.Nd;
options.ideal_im = ideal_im;
options.w = decay_weight;
[recon_pcgq_snr errors_snr] = qpwls_pcg1_snrweighted(0*mask(:), reconObj.G, ...
    1, data, 0, decay_weight, data_ideal, 'niter', niter, 'isave',niter, ...
    'userfun',@saveImageCalcError, 'userarg', {options});
clear recon_pcgq_snr;
% recon_pcgq_snr  = reshape(recon_pcgq_snr, [size(mask)]);
% figure();
% imslice(abs(recon_pcgq_snr),'Iterative - SNR weighted');
% colormap(gray);
% axis image;
% title('Model based Itterative reconstruction - SNR weighting');
% colorbar();



% Input parameters
movieName = 'itterativeReconComparison';
im_size = reconObj.G.arg.Gnufft.arg.st.Nd(1);

% Prepare the new file.
vidObj = VideoWriter(movieName);
vidObj.FrameRate = 30;
open(vidObj);

% Set up initial figure
fig = figure();
subplot(3,4,1);raw_coronal = imagesc(zeros(im_size,im_size));
colormap(gray);axis image;set(gca,'xtick',[]);set(gca,'ytick',[]);caxis([0 3]);
subplot(3,4,2);raw_sagital = imagesc(zeros(im_size,im_size));
colormap(gray);axis image;set(gca,'xtick',[]);set(gca,'ytick',[]);caxis([0 3]);
subplot(3,4,3);raw_axial = imagesc(zeros(im_size,im_size));
colormap(gray);axis image;set(gca,'xtick',[]);set(gca,'ytick',[]);caxis([0 3]);

subplot(3,4,5);naive_coronal = imagesc(zeros(im_size,im_size));
colormap(gray);axis image;set(gca,'xtick',[]);set(gca,'ytick',[]);caxis([0 3]);
subplot(3,4,6);naive_sagital = imagesc(zeros(im_size,im_size));
colormap(gray);axis image;set(gca,'xtick',[]);set(gca,'ytick',[]);caxis([0 3]);
subplot(3,4,7);naive_axial = imagesc(zeros(im_size,im_size));
colormap(gray);axis image;set(gca,'xtick',[]);set(gca,'ytick',[]);caxis([0 3]);

subplot(3,4,9);snr_coronal = imagesc(zeros(im_size,im_size));
colormap(gray);axis image;set(gca,'xtick',[]);set(gca,'ytick',[]);caxis([0 3]);
subplot(3,4,10);snr_sagital = imagesc(zeros(im_size,im_size));
colormap(gray);axis image;set(gca,'xtick',[]);set(gca,'ytick',[]);caxis([0 3]);
subplot(3,4,11);snr_axial = imagesc(zeros(im_size,im_size));
colormap(gray);axis image;set(gca,'xtick',[]);set(gca,'ytick',[]);caxis([0 3]);


error_pcgq_raw = zeros(1,niter);
error_pcgq_naive = zeros(1,niter);
error_pcgq_snr = zeros(1,niter);
resid_pcgq_raw = zeros(1,niter);
resid_pcgq_naive = zeros(1,niter);
resid_pcgq_snr = zeros(1,niter);
for i=1:niter
    error_pcgq_raw(i) = errors_raw{i,1};
    error_pcgq_naive(i) = errors_naive{i,1};
    error_pcgq_snr(i) = errors_snr{i,1};
    resid_pcgq_raw(i) = errors_raw{i,2};
    resid_pcgq_naive(i) = errors_naive{i,2};
    resid_pcgq_snr(i) = errors_snr{i,2};
end
allerrors = [error_pcgq_raw; error_pcgq_naive; error_pcgq_snr];
allresids = [resid_pcgq_raw; resid_pcgq_naive; resid_pcgq_snr];
max_error = max(allerrors(:));
min_error = min(allerrors(:));
max_resid = max(allresids(:));
min_resid = min(allresids(:));
for i=1:niter
    i_str = sprintf('%03.3d',i);
    a=load(['recon_pcgq_raw_sagital_' i_str '.mat']);set(raw_coronal,'CData',abs(a.im));
    a=load(['recon_pcgq_raw_coronal_' i_str '.mat']);set(raw_sagital,'CData',abs(a.im));
    a=load(['recon_pcgq_raw_axial_' i_str '.mat']);set(raw_axial,'CData',abs(a.im));
    
    a=load(['recon_pcgq_naive_sagital_' i_str '.mat']);set(naive_coronal,'CData',abs(a.im));
    a=load(['recon_pcgq_naive_coronal_' i_str '.mat']);set(naive_sagital,'CData',abs(a.im));
    a=load(['recon_pcgq_naive_axial_' i_str '.mat']);set(naive_axial,'CData',abs(a.im));
    
    a=load(['recon_pcgq_snrWeighted_sagital_' i_str '.mat']);set(snr_coronal,'CData',abs(a.im));
    a=load(['recon_pcgq_snrWeighted_coronal_' i_str '.mat']);set(snr_sagital,'CData',abs(a.im));
    a=load(['recon_pcgq_snrWeighted_axial_' i_str '.mat']);set(snr_axial,'CData',abs(a.im));
    
    subplot(3,4,4);
    % Just to get legend correct
    plot(i,100*error_pcgq_raw(i),'-or');hold on;
    plot(i,100*error_pcgq_naive(i),'-og');
    plot(i,100*error_pcgq_snr(i),'-ob');
    
    % lines
    plot(1:i,100*error_pcgq_raw(1:i),'-r');
    plot(1:i,100*error_pcgq_naive(1:i),'-g');
    plot(1:i,100*error_pcgq_snr(1:i),'-b');
    
    % circles
    plot(i,100*error_pcgq_raw(i),'or');
    plot(i,100*error_pcgq_naive(i),'og');
    plot(i,100*error_pcgq_snr(i),'ob');
    hold off;
    
    axis([1 niter 100*min_error 100*max_error]);
    xlabel('Iteration number');
    ylabel('Relative Error (%)');
    legend('raw','amplified','snr weighted');
    
    subplot(3,4,8);
    % Just to get legend correct
    plot(i,100*resid_pcgq_raw(i),'-or');hold on;
    plot(i,100*resid_pcgq_naive(i),'-og');
    plot(i,100*resid_pcgq_snr(i),'-ob');
    
    % lines
    plot(1:i,100*resid_pcgq_raw(1:i),'-r');
    plot(1:i,100*resid_pcgq_naive(1:i),'-g');
    plot(1:i,100*resid_pcgq_snr(1:i),'-b');
    
    % circles
    plot(i,100*resid_pcgq_raw(i),'or');
    plot(i,100*resid_pcgq_naive(i),'og');
    plot(i,100*resid_pcgq_snr(i),'ob');
    hold off;
    
    axis([1 niter 100*min_resid 100*max_resid]);
    xlabel('Iteration number');
    ylabel('Relative Residual (%)');
    legend('raw','amplified','snr weighted');
    
    % Write each frame to the file.
    writeVideo(vidObj,getframe(fig));
end
% Close the file.
close(vidObj);

% % Model based reconstruction with RF weighting
% start_guess = recon_pcgq_naive(:,:,:,niter-startIter+1);
% % clear recon_pcgq_naive;
% % close all;
% niter = 30;
% startIter = 1;
% recon_pcgq_smart = qpwls_pcg1_snrweighted(start_guess, reconObj.G, ...
%     1, data, 0, decay_weight, data_ideal, 'niter', niter, 'isave',startIter:niter);
% recon_pcgq_smart  = reshape(recon_pcgq_smart, [size(mask) niter-startIter+1]);
% figure();
% imslice(abs(recon_pcgq_smart),'Iterative - RF weighted');
% colormap(gray);
% axis image;
% title('Model based Itterative reconstruction - RF weighting');
% colorbar();
    function error_vals = saveImageCalcError(x, options, iter)
        x = reshape(x,options.volDims);

        % Calculate squared error.
        tot_sig = options.ideal_im(:)'*options.ideal_im(:);
        error_sqr = (x - options.ideal_im);
        error_sqr = error_sqr(:)' * error_sqr(:);
        error_sqr = sqrt(error_sqr/tot_sig);
        
        if(isfield(options,'w'))
            resid_sqr = (options.data - options.w.*(options.A*x));
        else
            resid_sqr = (options.data - options.A*x);
        end
        resid_sqr = resid_sqr(:)' * resid_sqr(:);
        resid_sqr = sqrt(resid_sqr/tot_sig);
        error_vals = {error_sqr; resid_sqr};
        
        % Save image as .mat
        iter_str = sprintf('%03.3d',iter);
        im = squeeze(x(50,:,:));
        save([options.saveBaseName 'sagital_' iter_str '.mat'],'im');
        im = squeeze(x(:,66,:));
        save([options.saveBaseName 'coronal_' iter_str '.mat'],'im');
        im = squeeze(x(:,:,50));
        save([options.saveBaseName 'axial_' iter_str '.mat'],'im');
    end
end
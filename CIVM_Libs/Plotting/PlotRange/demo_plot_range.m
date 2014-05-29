number_of_lines = 40;
noise_range = 25;

% Create fake noisy data
data = repmat(1:100,[number_of_lines 1])';
noise = noise_range*rand(size(data))-0.5*noise_range;
noisy_data = data+noise;

% Calculate some statistics of all the lines
data_mean = mean(noisy_data,2);
data_std = std(noisy_data,0,2);
data_min = min(noisy_data,[],2);
data_max = max(noisy_data,[],2);

figure();
% Show all the lines... too much data!
subplot(1,2,1);
plot(noisy_data);

% Show the range of lines
subplot(1,2,2);
plot_range([1:100]',data_mean,...
    {{data_max, data_min},{data_mean+data_std,data_mean-data_std}},'b');


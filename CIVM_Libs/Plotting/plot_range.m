%
% Description:
% A function to display the variability ammong multiple lines. The funtion
% will display a single line (can be the mean, for example), as well as
% shaded ranges that are meant to illustrate variability (mean+/-std, 
% min/max, etc). 
%
% Arguments
%       x_vals      - the values that will be plotted on the x-axis
%       line_vals   - the data that will be plotted as a line on the y-axis
%       range_vals  - the data that will be plotted as a range on the
%       y-axis
%
% Example:
%       see demo_plot_range.m
%
% Author: Scott Haile Robertson
% Website: www.ScottHaileRobertson.com
% Date: February 8, 2014
%
function h_line = plot_range(x_vals,line_vals,range_vals,color_val)
% Check if hold is on. We need hold on to plot the multiple patches and
% line, but we should return the current hold state after we're done
hold_on_at_start = ishold();

num_ranges = length(range_vals);
x_vals_symmetric = padarray(x_vals,[size(x_vals,1) 0],'symmetric','post');

hold on;
for i=1:num_ranges
    current_range_vals = range_vals{i};
    current_range_vals = [current_range_vals{1}; 
        flipud(current_range_vals{2})];
    
    % Create patch
    h_range = patch(x_vals_symmetric,current_range_vals,...
        1,'facecolor',color_val,'edgecolor','none','facealpha',0.25);
    
    % Hide patch annotation from legend
    set(get(get(h_range, 'Annotation'), 'LegendInformation'), 'IconDisplayStyle', 'off');
end

h_line = plot(x_vals,line_vals,'LineStyle','-', 'Color',color_val);

% If hold was off at the start, we should be nice and turn hold off before
% finishing this function.
if(~hold_on_at_start)
    hold off;
end
end

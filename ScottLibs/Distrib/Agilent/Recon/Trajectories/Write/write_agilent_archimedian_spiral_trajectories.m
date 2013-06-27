%CALC_ARCHIMEDIAN_SPIRAL_TRAJECTORIES   Archimedian spiral trajectory
% generator for agilent system.
%
%   Authors: Gary Cofer, Sam Johnston, Scott Haile Robertson.
%   $Revision: 1.0 $  $Date: 2013/05/10 $
function write_agilent_archimedian_spiral_trajectories(filename, nviews, primeplus)
loop_Factor = nearestPrime(round(nviews/3));
nviews=floor(nviews/2)*2+1; %Must have odd number of frames
cview=floor(nviews/2)+1;     %Center frame

is = 0:nviews-1; %In Gary's code, i=acview_start
fs = 1-(is/cview); %In Gary's code f=fThing <- goes from -1 to 1
angs = primeplus.*is.*(pi/180); %Angle in radians
ds = sqrt(1-(fs.^2));
x_coords = ds.*cos(angs);
y_coords = ds.*sin(angs);
z_coords = sqrt(1-((x_coords.^2)+(y_coords.^2)));

%Handle negatives
z_coords = z_coords.*((2*(is<=cview))-1);

% figure();
% subplot(1,2,1);plot3(x_coords,y_coords,z_coords,'.-r');title('before loop factor');

% Apply loop factor
old_idx = 1:nviews-1;
new_idx = mod((old_idx-1)*loop_Factor,nviews-1)+1;
x_coords(old_idx) = 32767*x_coords(new_idx);
y_coords(old_idx) = 32767*y_coords(new_idx);
z_coords(old_idx) = 32767*z_coords(new_idx);
clear old_idx new_idx;

% subplot(1,2,2);plot3(x_coords,y_coords,z_coords,'.-r');title('after loop factor');


% Write out values
fid = fopen(filename,'w+');
fprintf(fid,'%s','t11 = ');
for i=1:nviews
    fprintf(fid,'%f ',x_coords(i));
end
fprintf(fid,'\n');
fprintf(fid,'%s','t12 = ');
for i=1:nviews
    fprintf(fid,'%f ',y_coords(i));
end
fprintf(fid,'\n');
fprintf(fid,'%s','t13 = ');
for i=1:nviews
    fprintf(fid,'%f ',z_coords(i));
end
fprintf(fid,'\n');
fclose(fid);


%normalize
% ivec_lengths = 1./sqrt((x_coords.^2) + (y_coords.^2) + (z_coords.^2));
% xs = x_coords.*ivec_lengths;
% ys = y_coords.*ivec_lengths;
% zs = z_coords.*ivec_lengths;

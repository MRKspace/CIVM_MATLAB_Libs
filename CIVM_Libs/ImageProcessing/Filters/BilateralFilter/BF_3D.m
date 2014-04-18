function [ vol ] = BF_3D( vol, radius, r_sig, d_sig )
% 3D Bilateral Filter
% Ref:
% C. Tomasi and R. Manduchi
% "Bilateral Filtering for Gray and Color Images"
% Proceedings of the 1998 IEEE International Conference on Computer Vision
%
% Inputs:
% vol: grayscale image to filter
% radius: filter radius
% r_sig: photometric standard deviation
% d_sig: geometric standard deviation
%
% Output:
% vol: filtered version of input "vol"

% Save size before converting to vector
dims = size(vol);
vol_length = length(vol(:));

% Mirror the input image to handle edges
vol2 = zeros(dims + 2*radius);
vol2(radius+1:dims(1)+radius,radius+1:dims(2)+radius,radius+1:dims(3)+radius) = vol;
vol2(1:radius,:,:) = vol2(2*radius+1:-1:radius+2,:,:);
vol2(:,1:radius,:) = vol2(:,2*radius+1:-1:radius+2,:);
vol2(:,:,1:radius) = vol2(:,:,2*radius+1:-1:radius+2);
vol2(end:-1:end-radius+1,:,:) = vol2(end-2*radius:end-radius-1,:,:);
vol2(:,end:-1:end-radius+1,:) = vol2(:,end-2*radius:end-radius-1,:);
vol2(:,:,end:-1:end-radius+1) = vol2(:,:,end-2*radius:end-radius-1);

sumD = zeros(size(vol));
out_vol = zeros(size(vol));

% Prepare a friendly waitbar since the filtering takes a bit...
h = waitbar(0,'Bilateral filtering...');
update_delta = 1./(2*radius+1)^2;

for x = -radius:radius
    for y = -radius:radius
        for z = -radius:radius
            % Spatial contribution
            D_spatial = exp(-((x^2)+(y^2)+(z^2))/(2*d_sig^2));
            
            % Intensity contribution
            shift_v=vol2(x+radius+(1:dims(1)),...
                y+radius+(1:dims(2)),z+radius+(1:dims(3)));
            D_intensity = exp(-((shift_v-vol).^2)/(2*r_sig^2));
            
            sumD = sumD + D_spatial*D_intensity;
            out_vol = out_vol + shift_v.*D_spatial.*D_intensity;
        end
        waitbar(((x+radius)*(2*radius+1)+(y+radius))*update_delta,h,'Bilateral filtering...');
    end
end
% nonZeroIdx = sumD>0;
% vol(nonZeroIdx) = out_vol(nonZeroIdx)./sumD(nonZeroIdx);
vol = out_vol./sumD;

waitbar(1,h,'Bilateral filtering finished.');
delete(h);

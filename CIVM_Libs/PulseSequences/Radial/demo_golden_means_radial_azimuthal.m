nframes = 10;
npts = 4;

total_points = npts*nframes

ray = linspace(0,1,npts)';
delta_ray = ray(2)-ray(1);

i = 0:nframes-1;

%% 2D version
golden_means_1 = calc_golden_means(1);
angle_val1 = 2*pi*mod(i*golden_means_1(1),1);
[r_mat1 ang_mat1] = meshgrid(ray,angle_val1);
[x_cart_gold1 y_cart_gold1] = pol2cart(ang_mat1,r_mat1);

golden_means_2 = calc_golden_means(2);
angle_val = 2*pi*mod(i*golden_means_2(2),1);
r_delta = delta_ray*mod(i*golden_means_2(1),1)';
[r_mat2 ang_mat2] = meshgrid(ray,angle_val);
r_mat2 = r_mat2 + repmat(r_delta,[1 npts]);
[x_cart_gold2 y_cart_gold2] = pol2cart(ang_mat2,r_mat2);
for j = 1:nframes
subplot(1,2,1);
plot(x_cart_gold1(1:j,:)',y_cart_gold1(1:j,:)','.');
title('Using just angular golden means');
axis square;
axis((1+delta_ray)*[-1 1 -1 1]);
subplot(1,2,2);

plot(x_cart_gold2(1:j,:)',y_cart_gold2(1:j,:)','.');
title('Using radial/angular golden means');
axis square;
axis((1+delta_ray)*[-1 1 -1 1]);
drawnow
end

% %% 3D version
% golden_means = calc_golden_means(3);
% x_cart = mod(i*golden_means(1),1);
% y_cart = mod(i*golden_means(2),1);
% z_cart = mod(i*golden_means(3),1);
% for j = 1:nframes
% plot3(x_cart(1:j),y_cart(1:j),z_cart(1:j),'.b');
% axis([0 1 0 1 0 1]);
% % view([0 0]);
% view([45 40]);
% % view([90 0]);
% drawnow
% 
% end

% for j = 1:nframes
% plot3(x_cart(1:j),y_cart(1:j),z_cart(1:j),'.b');
% drawnow
% end

% alpha = 2*pi .* mod (i.*golden_means_2(2),1);
% beta = acos(2*mod(i.*golden_means_2(1),1)-1);
% 
% x = ray*(cos(alpha).*sin(beta)); %x-coordinates of rays
% y = ray*(sin(alpha).*sin(beta)); %y-coordinates of rays
% z = ray*(cos(beta)); %z-coordinates of rays
% 
% plot3(x(:),y(:),z(:),'.b');




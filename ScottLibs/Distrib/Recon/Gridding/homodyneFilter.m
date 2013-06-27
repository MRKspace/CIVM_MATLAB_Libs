function filt_im = homodyneFilter(im, sigma)
% Create filter in frequency domain
dims = size(im);
lsp_kx = linspace(-1,1,dims(1)+1); lsp_kx = lsp_kx(1:end-1);
lsp_ky = linspace(-1,1,dims(2)+1); lsp_ky = lsp_ky(1:end-1);
lsp_kz = linspace(-1,1,dims(3)+1); lsp_kz = lsp_kz(1:end-1);
[kx,ky,kz] = meshgrid(lsp_kx, lsp_ky, lsp_kz);
gauss_filt = 1/(sigma*sqrt(2*pi))*exp(0.5*(kx.^2 + ky.^2 + kz.^2)/(2*sigma^2));

% Apply low pass filter
low_pass_im = fftshift(fftn(im));
figure();
showSlices(log(abs(low_pass_im)));


filt_im = 1;
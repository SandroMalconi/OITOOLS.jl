#
# Image reconstruction code with spectral regularization
# This requires a private example file at the moment
#
using OITOOLS
using FITSIO

oifitsfile = "./data/MWC480.oifits"
data = vec(readoifits(oifitsfile, filter_bad_data = true, polychromatic = true)) # vec is to get rid of degenerate (temporal) dimension

nx = 64 #number of pixels (side)
pixsize = 0.2 # mas/pixel

fftplan = setup_nfft_polychromatic(data, nx, pixsize);
nwav = length(fftplan)

# Setup regularization
regularizers = [   [ ["centering", 1e4], ["tv", 1e3] ]]  # Frame 1 is centered
for i=1:nwav-1
    push!(regularizers,[["tv",1e3]]) # Total variation for all
end


regularizers = [   [ ["centering", 1e4], ["l1l2", 1e3, 0.4] ]]  # Frame 1 is centered
for i=1:nwav-1
    push!(regularizers,[["l1l2",1e3,0.4]]) # Total variation for all
end

# Uncomment the desired transspectral regularization
# push!(regularizers,[ ["transspectral_tvsq", 1e5] ] );
push!(regularizers,[["transspectral_structnorm", 1e3], ["transspectral_tv", 1e3] ] );

 pointsource = zeros(nx,nx); pointsource[div(nx+1,2), div(nx+1,2)] = 1.0;
 x_start = zeros(nx, nx, nwav);
 for i=1:nwav
     x_start[:,:,i]=pointsource
 end
#x_start= rand(nx, nx, nwav);
x = vec(x_start);
for i=1:3
    global x = reconstruct_polychromatic(x, data, fftplan, regularizers = regularizers, maxiter = 200, verb=false);
    imdisp_polychromatic(reshape(x,nx*nx,nwav).^.25, pixscale=pixsize)
end

imdisp_polychromatic(reshape(x,nx*nx,nwav).^.25, pixscale=pixsize)

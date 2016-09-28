function mod360(x)
mod(mod(x+180,360.)+360., 360.) - 180.
end

function cvis_to_v2(cvis, indx)
  v2_model = abs2(cvis[indx]);
end

function cvis_to_t3(cvis, indx1, indx2, indx3)
  t3 = cvis[indx1].*cvis[indx2].*cvis[indx3];
  t3amp = abs(t3);
  t3phi = angle(t3)*180./pi;
  return t3, t3amp, t3phi
end

function imdisp(image)
  nx=Int64(sqrt(length(image)))
 #ax = gca()
 imshow(rotl90(reshape(image,nx,nx)), ColorMap("hot")); # uses Monnier's orientation
 #divider = axgrid.make_axes_locatable(ax)
 #cax = divider[:append_axes]("right", size="5%", pad=0.05)
 #colorbar(image, cax=cax)
end

#fig = figure("Image",figsize=(10,10));imshow(rotl90(image));PyPlot.draw();PyPlot.pause(1);

function crit_fg(x, g, dft, data, rho, x0)
nx2 = length(x)
flux = sum(x);
cvis_model = zeros(Complex{Float64},div(data.nuv,data.nw),data.nw);
cvis_model[:,1] = dft * x / flux;
# compute observables from all cvis
v2_model = cvis_to_v2(cvis_model, data.indx_v2);
t3_model, t3amp_model, t3phi_model = cvis_to_t3(cvis_model, data.indx_t3_1, data.indx_t3_2 ,data.indx_t3_3);
chi2_v2 = sum( ((v2_model - data.v2_data)./data.v2_data_err).^2);
chi2_t3amp = sum( ((t3amp_model - data.t3amp_data)./data.t3amp_data_err).^2);
chi2_t3phi = sum( (mod360(t3phi_model - data.t3phi_data)./data.t3phi_data_err).^2);
g_v2 = Array(Float64, nx2);
g_t3amp = Array(Float64, nx2);
g_t3phi = Array(Float64, nx2);

# regularization
reg = mu*sum( (x-x0).^2);
reg_der = 2*mu*sum(x-x0);

# note: this is correct but slower
#g = sum(4*((v2_model-v2_data)./v2_data_err.^2).*real(conj(cvis_model[indx_v2]).*dft[indx_v2,:]),1)
for ii = 1:nx2
g_v2[ii] = 4*sum(((v2_model-data.v2_data)./data.v2_data_err.^2).*real(conj(cvis_model[data.indx_v2]).*dft[data.indx_v2,ii]))
g_t3amp[ii] = 2*sum(((t3amp_model-data.t3amp_data)./data.t3amp_data_err.^2).*
                  (   real( conj(cvis_model[data.indx_t3_1]./abs(cvis_model[data.indx_t3_1])).*dft[data.indx_t3_1,ii]).*abs(cvis_model[data.indx_t3_2]).*abs(cvis_model[data.indx_t3_3])
                    + real( conj(cvis_model[data.indx_t3_2]./abs(cvis_model[data.indx_t3_2])).*dft[data.indx_t3_2,ii]).*abs(cvis_model[data.indx_t3_1]).*abs(cvis_model[data.indx_t3_3])
                    + real( conj(cvis_model[data.indx_t3_3]./abs(cvis_model[data.indx_t3_3])).*dft[data.indx_t3_3,ii]).*abs(cvis_model[data.indx_t3_1]).*abs(cvis_model[data.indx_t3_2]))
                   );
t3model_der = dft[data.indx_t3_1,ii].*cvis_model[data.indx_t3_2].*cvis_model[data.indx_t3_3] + dft[data.indx_t3_2,ii].*cvis_model[data.indx_t3_1].*cvis_model[data.indx_t3_3] + dft[data.indx_t3_3,ii].*cvis_model[data.indx_t3_1].*cvis_model[data.indx_t3_2];
g_t3phi[ii] = sum(2*((mod360(t3phi_model-data.t3phi_data)./data.t3phi_data_err.^2)./abs2(t3_model)).*(-imag(t3_model).*real(t3model_der)+real(t3_model).*imag(t3model_der));
);
end
g[1:end] = g_v2 + g_t3amp + g_t3phi +  rho * reg_der;

g[1:end] = (g - sum(x.*g) / flux ) / flux; # gradient correction to take into account the non-normalized image

println("V2: ", chi2_v2/data.nv2, " T3A: ", chi2_t3amp/data.nt3amp, " T3P: ", chi2_t3phi/data.nt3phi," Flux: ", flux)
#println("GV2: ", sum(abs2(g_v2))," GT3A: ", sum(abs2(g_t3amp)), " GT3P: ",sum(abs2(g_t3phi)))

return chi2_v2 + chi2_t3amp + chi2_t3phi + rho *reg
end



function proj_positivity(ztilde)
z = copy(ztilde)
z[ztilde.>0]=0
return z
end

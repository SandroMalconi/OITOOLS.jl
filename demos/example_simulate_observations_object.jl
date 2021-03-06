using Dates,OITOOLS
#Simulate an observation using an input image, given telescope parameters, and input object name and observation night
dates = collect(DateTime(2018,8,13,5,00,00):Minute(15):DateTime(2018,8,13,7,30,00))

# Object info
image_file="./data/2004true.fits";
pixsize=0.101;
out_file="./data/2004testsimulation.oifits";
obs = read_obs_file("./data/default_obs.txt"); # read defaults (for OIFITS header)

# Note: one can directly enter RA/DEC or look them up with Astroquery
obs.target[1] = "AZ Cyg"
#obs.raep0[1] =  [20, 57, 59.4437981]'*[1.0, 1/60., 1/3600] # UPDATE ra
#obs.decep0[1] = [46, 28, 00.5731825]'*[1.0, 1/60., 1/3600] # UPDATE DEC
# Next lines are using Astroquery -- see OITOOLS installation documentation
radec = ra_dec_from_simbad(obs.target[1])
obs.raep0[1], obs.decep0[1] = (radec[1]'*[1.0, 1/60., 1/3600], radec[2]'*[1.0, 1/60., 1/3600])

facility    = read_facility_file("./data/CHARA_new.txt");
combiner    = read_comb_file("./data/MIRC.txt");
wave        = read_wave_file("./data/MIRC_LOWH.txt");
v2m=1.0/100; v2a=1e-5; t3ampm=1.0/100; t3ampa=1e-6; t3phim=0.0; t3phia=0.5;
errors      = define_errors(v2m,v2a,t3ampm,t3ampa,t3phim,t3phia);

lst, hour_angles = hour_angle_calc(dates,facility.lon[1],obs.raep0[1]);
simulate_ha(facility, obs, combiner, wave, hour_angles, image_file, pixsize, errors, out_file);

#Check simulated data
data = (readoifits(out_file))[1,1]; # data can be split by wavelength, time, etc.
uvplot(data)

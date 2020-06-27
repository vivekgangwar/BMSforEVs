L = 252e-6;
I_peak = 22;
I_rms = 20;
mu0 = 4*pi*1e-7;
EL = 0.5*L*(I_peak^2);
K_w = 0.5;
K_c = 22/20;
J = 4*1e6;
Bm = 0.25;
Ap = 2*EL/(K_w*K_c*J*Bm);

fprintf('Value of inductor area product is (mm^4): %f\n', Ap*1e12);

  Ap_L=280800e-12;
	Ac_L=520e-6;
	Aw_L=540e-6;
	lm_L=156e-3;
	mur_L=1500;
  
 	%lg = (mu0*L*(I_peak^2)/(Bm^2 * (Ac_L)))*1e7
  
  

	lg = 5*1e-3; %Temporary assumption
	permeance = mu0*mur_L*Ac_L/(lm_L+(mur_L*lg))
	N = sqrt(L/permeance);
	N = ceil(N)

	a = I_rms/J; %wire cs in m2
	fprintf('Calculated wire guage of Buck inductor (mm^2): %f\n', a*1e6); 
  
  mu_g = mu0*mur_L*(lg+lm_L)/(lm_L + mur_L*lg)
  Bsat_1 = (I_peak*N/(lm_L+lg))*mu_g

%--------------------------------------------------
%DESIGN SPECIFICATIONS
%--------------------------------------------------
P_out    	 = 1200;
V_in_min 	 = 170;     %minimum input voltage (rms)
V_in_max 	 = 270;    %max input voltage (rms)
f_line 		 = 50;


I_out      = P_out/84;  %Max charger output current at max battery voltage
del_I_out  = I_out*0.2; %Output ripple, 20% of output current
  

V_dcLink 	 = 400;    %DC link voltage at the output of boost PFC stage
del_V_dcLink = 80;	   %DC Link p-p ripple, assuming 20% of DC link voltage
V_dcLink_min = V_dcLink - del_V_dcLink/2;
V_dcLink_max = V_dcLink + del_V_dcLink/2;

f_sw_frwd 	 = 50000;  %Switching frequency, forward converter
f_sw_boost 	 = 50000;  %Switching frequency, boost converter

V_out_min 	 = 60;
V_out_max 	 = 84;

eff_Boost	 = 0.9;
eff_overall	 = 0.8;
T_dcLink_holdup = 10e-3;
mu0 = 4*pi*1e-7;
Vd = 1;		%Let all diode drops be 1V



%--------------------------------------------------
%DESIGN EQUATIONS	
%--------------------------------------------------

%----------------------------------
%Design of forward converter stage
%----------------------------------
	D_max_frwd = 0.5;
	D_min_frwd = V_dcLink_min*D_max_frwd/V_dcLink_max;
	%D_min_frwd = V_out_min/(V_dcLink + del_V_dcLink/2);
	


	%Magnetic design (Forward transformer)
	tPo = 1.1*P_out;
	Kw=0.4;
	J=4e6;
	Bm=0.2;
	Ap = tPo*(1+(1/0.8))/(sqrt(2)*Kw*J*Bm*f_sw_frwd);
  fprintf('\n\n---------------------------------------')
	fprintf('\nValue of transformer area product is (mm^4): %f\n', Ap*1e12);

	%Ap = input('Enter the chosen area product (mm^4): ');
	%Ap = Ap*1e-12;
	%Ac = input('Enter the chosen core area (mm^2): ');
	%Ac = Ac*1e-6;
	%Aw = input('Enter the chosen window area (mm^2): ');
	%Aw = Aw*1e-6;
	%lm = input('Enter the chosen magnetic path length (mm): ');
	%lm = lm*1e-3;
	%mur = input('Enter the chosen relative permeability: ');

	Ap = 280800e-12;   %One EE65 core
	Ac = 520e-6;
	Aw = 540e-6;
	lm = 156e-3;
	mur= 1500;

	Np = V_dcLink_max/(2*Ac*Bm*f_sw_frwd);
	Np = ceil(Np)
	%Nd = Np;

	es = (V_out_max+Vd+0.1*V_out_max)/D_min_frwd;	%Secondary voltage
	Ns = es/(2*Ac*Bm*f_sw_frwd);
	Ns = ceil(Ns)

	n  = Ns/Np	%Turns ratio
	turn_ratio = n;

	Lm = mu0*mur*Ac*Np*Np/lm;	%Magnetizing inductance
	Im = V_dcLink_min*D_max_frwd/(Lm*f_sw_frwd);	%Magnetizing current




	  %ss1 buck side diode of forward converter
		piv_ss1 = es;
		Ipeak_ss1 = I_out + del_I_out/2;
		Iavg_ss1 = I_out*D_max_frwd;
		Irms_ss1 = I_out*sqrt(D_max_frwd);	%Assuming 50% duty
    
		%sp main switches of forward converter
		Vdsmax_sp1 = V_dcLink;	%take adequate safety margin later
		Iavg_sp1 = I_out*D_max_frwd*turn_ratio;
		Irms_sp1 = I_out*turn_ratio*sqrt(D_max_frwd);
		Ipeak_sp1 = Ipeak_ss1*turn_ratio + Im;

		%sp_d primary side diodes of forward converter
		piv_sp_d = V_dcLink;
		Iavg_sp_d = 0.5*Im*(1 - D_min_frwd);
		Irms_sp_d = Im*sqrt((1 - D_min_frwd)/3);
		Ipeak_sp_d = Ipeak_sp1;



	ap = Irms_sp1/J;
	as = Irms_ss1/J;

	fprintf('\nCalculated wire guages(mm^2) of forward transformer :\nPrimary - %f\nSecondary - %f\n', ap*1e6, as*1e6);
  
	if (Kw*Aw > Np*ap + Ns*as)
		fprintf('Window area inequality SATISFIED for forward transformer.\n');
  end

  fprintf('\nBuck side diode SS1 ratings:\nPIV = %f\nIavg = %f\nIrms = %f\nIpeak = %f\n', piv_ss1, Iavg_ss1, Irms_ss1, Ipeak_ss1);
  fprintf('\nForward MOSFET ratings:\nVdsmax = %f\nIavg = %f\nIrms = %f\nIpeak = %f\n', Vdsmax_sp1, Iavg_sp1, Irms_sp1, Ipeak_sp1);
  fprintf('\nPrimary diodes ratings:\nPIV = %f\nIavg = %f\nIrms = %f\nIpeak = %f\n', piv_sp_d, Iavg_sp_d, Irms_sp_d, Ipeak_sp_d);
  

  
  %-----------------------------------------------------------
	L_buck = (V_out_max*(1 - D_min_frwd))/(f_sw_frwd*del_I_out);
  

fprintf('\n-----------------------------------');
fprintf('\nBUCK INDUCTOR');
fprintf('\n-----------------------------------\n');

  
	%Magnetic design (Buck inductor)
	I_lpeak = I_out + del_I_out/2;
	EL = 0.5*L_buck*(I_lpeak^2);

	Kw_L = 0.5;
	Kc_L = I_lpeak/I_out;
	J = 4*1e6;
	Bm_L = 0.25;
	Ap_L = 2*EL/(Kw_L*Kc_L*J*Bm_L); 

	fprintf('\n\nValue of buck inductor area product is (mm^4): %f\n', Ap_L*1e12);

	%Ap_L = input('Enter the chosen area product (mm^4): ');
	%Ap_L = Ap_L*1e-12;
	%Ac_L = input('Enter the chosen core area (mm^2): ');
	%Ac_L = Ac_L*1e-6;
	%Aw_L = input('Enter the chosen window area (mm^2): ');
	%Aw_L = Aw_L*1e-6;
	%lm_L = input('Enter the chosen magnetic path length (mm): ');
	%lm_L = lm_L*1e-3;
	%mur_L = input('Enter the chosen relative permeability: ');


	Ap_L=280800e-12;
	Ac_L=520e-6;
	Aw_L=540e-6;
	lm_L=156e-3;
	mur_L=1500;
  
 	%lg = (mu0*L_buck*(I_lpeak^2)/(Bm_L^2 * (Ac_L)))*1e7
  
  

	lg = 3*1e-3; %Temporary assumption
	permeance = mu0*mur_L*Ac_L/(lm_L+(mur_L*lg));
	N = sqrt(L_buck/permeance);
	N = ceil(N)

	a = I_out/J; %wire cs in m2
	fprintf('Calculated wire guage of Buck inductor (mm^2): %f\n', a*1e6);
  
  if (Kw_L*Aw_L > N*a)
		fprintf('Window area inequality SATISFIED for buck inductor.\n');
  end

  mu_g_buck = mu0*mur_L*(lg+lm_L)/(lm_L + mur_L*lg);
  Bsat_buck = (I_lpeak*N/(lm_L+lg))*mu_g_buck;
  fprintf('\nBuck inductor max flux density, Bmax = %f  at airgap = %f mm\n', Bsat_buck, lg*1e3);
  
  
	%Freewheeling diode of buck side
	piv_ss2   = es;
	Ipeak_ss2 = I_out + del_I_out/2;
	Iavg_ss2  = I_out*(1 - D_min_frwd);
	Irms_ss2  =  I_out*sqrt(1 - D_min_frwd); %Assuming 50% duty
  
  fprintf('\nBuck side freewheeling diode ratings:\nPIV = %f\nIavg = %f\nIrms = %f\nIpeak = %f\n', piv_ss2, Iavg_ss2, Irms_ss2, Ipeak_ss2);




%--------------------------------
%Design of PFC Boost stage
%--------------------------------

fprintf('\n-----------------------------------');
fprintf('\nBOOST PFC STAGE');
fprintf('\n-----------------------------------\n');

  V_in_max = 226;
  V_in_min = 226;
  
	I_boost_rms = P_out/(V_in_min*eff_Boost);
	I_boost_peak = sqrt(2)*I_boost_rms;
	del_I_boost = 0.1*I_boost_peak;
	D_min_boost = 1 - V_in_max*sqrt(2)/V_dcLink_min;
	D_max_boost = 1 - V_in_min*sqrt(2)/V_dcLink_max;


	%Capacitor
	C_dcLink1 = I_boost_peak/(2*pi*f_line*del_V_dcLink*eff_Boost);
	C_dcLink2 = 2*P_out*T_dcLink_holdup/(V_dcLink^2 - V_dcLink_min^2);
	C_dcLink  = max(C_dcLink1, C_dcLink2);
	I_Cdc_rms_lf = I_out/sqrt(2);
	I_Cdc_rms_hf = I_out*sqrt((16*V_dcLink)/(3*pi*V_in_max) - 1);   %Ref: an53.pdf
	%P_cap = I_Cdc_rms_lf^2 * ESR_lf + I_Cdc_rms_hf^2 * ESR_hf;  
  

  fprintf('\nDC Link capacitance value = %f uF\n', C_dcLink*1e6);
  
  
  
  
	%Boost diode
	piv_sb2 = V_dcLink_max;
	Iavg_sb2 = 	0.637*I_boost_peak/2;
	Irms_sb2 = (I_boost_peak/sqrt(2))/sqrt(2);
	Ipeak_sb2 = I_boost_peak;
  
  fprintf('\nBoost diode ratings:\nPIV = %f\nIavg = %f\nIrms = %f\nIpeak = %f\n', piv_sb2, Iavg_sb2, Irms_sb2, Ipeak_sb2);

	%Boost switch
	Vdsmax_sb1 = V_dcLink_max;
	Iavg_sb1 = 0.637*I_boost_peak/2;
	Irms_sb1 = (I_boost_peak/sqrt(2))/sqrt(2);
 	Ipeak_sb1 = I_boost_peak;
  
  fprintf('\nBoost MOSFET ratings:\nVdsmax = %f\nIavg = %f\nIrms = %f\nIpeak = %f\n', Vdsmax_sb1, Iavg_sb1, Irms_sb1, Ipeak_sb1);
  

	%Inrush bypass/ Boost-Precharge diode
	piv_sb3 = V_dcLink_max;
	Ipeak_sb3 = 0; %Should be higher than inrush peak
	Iavg_sb3 = 	0;  %Precharge diode not required in continuous operation
	Irms_sb3 = 0;


	%Boost inductor
	I_L_boost_peak = I_boost_peak;
	L_boost =  (sqrt(2)*V_in_max*D_max_boost)/(f_sw_boost*del_I_boost);

	%Magnetic design (PFC Boost inductor)
	EL_pfc = 0.5*L_boost*(I_L_boost_peak^2);

	Kw_L_pfc = 0.5;
	Kc_L_pfc = 1.414;
	J = 4*1e6;
	Bm_L_pfc = 0.25;
	Ap_L_pfc = 2*EL_pfc/(Kw_L_pfc*Kc_L_pfc*J*Bm_L_pfc); 

	fprintf('\nValue of PFC inductor area product is (mm^4): %f\n', Ap_L_pfc*1e12);

	%Ap_L = input('Enter the chosen area product (mm^4): ');
	%Ap_L = Ap_L*1e-12;
	%Ac_L = input('Enter the chosen core area (mm^2): ');
	%Ac_L = Ac_L*1e-6;
	%Aw_L = input('Enter the chosen window area (mm^2): ');
	%Aw_L = Aw_L*1e-6;
	%lm_L = input('Enter the chosen magnetic path length (mm): ');
	%lm_L = lm_L*1e-3;
	%mur_L = input('Enter the chosen relative permeability: ');


	Ap_L_pfc=2*280800e-12;
	Ac_L_pfc=2*520e-6;
	Aw_L_pfc=540e-6;
	lm_L_pfc=156e-3;
	mur_L_pfc=1500;
  
 	%lg = (mu0*L_buck*(I_lpeak^2)/(Bm_L^2 * (Ac_L)))*1e7
  
  

	lg_pfc = 2.5*1e-3; %Temporary assumption
	permeance_pfc = mu0*mur_L_pfc*Ac_L_pfc/(lm_L_pfc+(mur_L_pfc*lg_pfc));
	N_pfc = sqrt(L_boost/permeance_pfc);
	N_pfc = ceil(N_pfc)

	a = I_boost_rms/J; %wire cs in m2
	fprintf('Calculated wire guage of PFC Boost inductor (mm^2): %f\n', a*1e6);
  
   if (Kw_L_pfc*Aw_L_pfc > N_pfc*a)
		fprintf('Window area inequality SATISFIED for PFC inductor.\n');
  end

  mu_g_pfc = mu0*mur_L_pfc*(lg_pfc+lm_L_pfc)/(lm_L_pfc + mur_L*lg_pfc);
  Bsat_pfc = (I_boost_peak*N_pfc/(lm_L_pfc+lg_pfc))*mu_g_pfc;
  fprintf('\nPFC inductor max flux density, Bmax = %f  at airgap = %f mm\n\n', Bsat_pfc, lg_pfc*1e3);
  
  
%--------------------------------------------
%Design of Full Bridge Rectifier stage diodes
%--------------------------------------------
piv_fbd = V_in_max*sqrt(2);
Ipeak_fbd = I_boost_peak;
Iavg_fbd = 0.637*I_boost_peak/2;
Irms_fbd = I_boost_rms/sqrt(2);

fprintf('\nFBR diodes ratings:\nPIV = %f\nIavg = %f\nIrms = %f\nIpeak = %f\n', piv_fbd, Iavg_fbd, Irms_fbd, Ipeak_fbd);


%--------------------------------
%Rating of fuse
%--------------------------------
I_fuse_min = (P_out/(eff_overall*V_in_min))*1.1; 	%Over-rated by 10 percent
I2t_fuse_min = 0.5*C_dcLink * (V_in_max*sqrt(2))^2; %Thermal capacity of the fuse should be higher than the energy supplied to the capacitor during startup

fprintf('\n\nMinimum ratings of input side fuse: \nCurrent rating: %f\nThermal capacity: %f\n\n\n\n\n\n\n\n', I_fuse_min, I2t_fuse_min);


%Protections required: inrush, thermal, short-circuit, EMI filter
%Power supplies for: microcontroller 

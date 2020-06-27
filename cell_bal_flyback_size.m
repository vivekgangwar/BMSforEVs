D1 = 0.5; %Fixed duty cycle of primary flyback converters
D2 = 0.5; %Fixed duty cycle of secondary flyback converter
V_nom_cell  = 4.2;	%Nominal voltage per cell
f_sw 		= linspace(20000, 80000, 7); %Switching frequemcy of flyback converter main switch 


I_bal    = 1; %Average balancing (discharge) current per cell
I_peak_p = I_bal*2/D1;	%Peak primary current for I_bal=2 and D=0.5
L_p      = V_nom_cell*D1./(I_peak_p.*f_sw);


%Magnetic design: Flyback transformer
EL = 0.5*L_p*(I_peak_p^2);
Kw = 0.4;
Kc = I_peak_p/I_bal;
J  = 3e6;
Bm = 0.2;
Ap = 2*EL/(Kw*Kc*J*Bm);

fprintf('Value of inductor area product is (mm^4): %f\n', Ap*1e12); 

  plot(f_sw, Ap*1e12)
  hold on;
  plot(f_sw, Ap*1e12, 'o')
  grid on;
  xlabel('Freq (Hz)');
  ylabel('Area prod. (mm^4)');

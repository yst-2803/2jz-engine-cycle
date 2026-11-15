% 2JZ-GE (non-VVT-i) ideal Otto cycle model
% Source: engine-specs.net, 2JZ-GE: bore 86.0 mm, stroke 86.0 mm, CR 10.0:1,
%         220 PS (162 kW) @ 5800 rpm, 284 Nm @ 4800 rpm
clear; clc;

bore   = 0.086;      % m
stroke = 0.086;      % m
r      = 10.0;       % compression ratio
cyl    = 6;          % number of cylinders

Vs = pi/4 * bore^2 * stroke;   % swept volume of one cylinder (m^3)
Vc = Vs / (r - 1);             % clearance volume(m^3)
V1 = Vs + Vc;                  % volume at BDC (m^3)
V2 = Vc;                       % volume at TDC (m^3)

printf('Swept volume per cylinder: %.4e m^3\n', Vs);
printf('Total displacement:        %.4f L\n', Vs*cyl*1000);
printf('V1 = %.4e m^3, V2 = %.4e m^3, V1/V2 = %.2f\n', V1, V2, V1/V2);

%% Block 2: air and fuel mass per cylinder per cycle
P1  = 101325;    % intake pressure (Pa), atmospheric
T1  = 300;       % intake temperature (K)
R   = 287;       % specific gas constant for air (J/kg/K)
AFR = 14.7;      % stoichiometric air-fuel ratio for petrol
LHV = 44e6;      % lower heating value of petrol (J/kg)

m_air  = (P1 * V1) / (R * T1);    % using the gas at BDC total volume
m_fuel = m_air / AFR;
Q_in   = m_fuel * LHV;    % heat released per cylinder per cycle (J)

printf('Air mass per cycle:  %.4e kg\n', m_air);
printf('Fuel mass per cycle: %.4e kg\n', m_fuel);
printf('Heat input per cycle: %.1f J\n', Q_in);

%% Block 3: compression (1->2) and combustion (2->3)
gamma = 1.4;
cv    = R / (gamma - 1);   % specific heat at constant volume (J/kg/K)

P2 = P1 * (r^gamma);
T2 = T1 * (r^(gamma - 1));
T3 = T2 + (Q_in / (m_air * cv));
P3 = P2 * (T3 / T2);

printf('P2 = %.2f bar, T2 = %.1f K\n', P2/1e5, T2);
printf('P3 = %.1f bar, T3 = %.0f K\n', P3/1e5, T3);

%% Block 4: expansion (3->4) and net work
P4 = P3 * ((1/r)^gamma);
T4 = T3 * ((1/r)^(gamma - 1));

V = linspace(V2, V1, 100);           % ONE volume vector, running from V2 up to V1 for both curves
P_exp  = P3 * (V2 ./ V).^gamma;      % expansion curve (3->4)
P_comp = P1 * (V1 ./ V).^gamma;      % compression curve (1->2)

W_exp  = trapz(V, P_exp);            % in Octave, trapz(x, y): x first
W_comp = trapz(V, P_comp);
W_net  = W_exp - W_comp;             % Net mechanical work done by one cylinder

eta      = 1 - (1 / (r^(gamma - 1))); % ideal Otto efficiency formula
W_check  = eta * Q_in;               % Analytic work verification
err_pct  = abs(W_net - W_check) / W_check * 100;

printf('P4 = %.2f bar, T4 = %.0f K\n', P4/1e5, T4);
printf('W_exp = %.1f J, W_comp = %.1f J, W_net = %.1f J\n', W_exp, W_comp, W_net);
printf('Efficiency = %.2f%%, analytic W = %.1f J, error = %.3f%%\n', eta*100, W_check, err_pct);

%% Block 5: compare with the real 2JZ-GE (engine-specs.net)
rpm_P   = 5800;    P_real = 162e3;   % rated power (W) at 5800 rpm
T_real  = 284;                       % rated torque (Nm) at 4800 rpm

P_model = W_net * (rpm_P / 120) * cyl;                       % W
T_model = P_model / ((2 * pi * rpm_P) / 60);                 % Nm
MEP     = W_net / Vs;                                        % Pa, model mean effective pressure
BMEP    = (T_real * 4 * pi) / (Vs * cyl);                    % Pa, real engine: rearrange T = BMEP*Vd/(4*pi), Vd = whole engine

printf('Power:  model %.1f kW vs real %.0f kW  (ratio %.2f)\n', P_model/1e3, P_real/1e3, P_model/P_real);
printf('Torque: model %.1f Nm vs real %.0f Nm  (ratio %.2f)\n', T_model, T_real, T_model/T_real);
printf('MEP:    model %.2f bar vs real BMEP %.2f bar\n', MEP/1e5, BMEP/1e5);
printf('Power: %.0f hp (model) vs 217 hp (real)\n', P_model/745.7);

%% Block 6: pV diagram (closed loop)
V_loop = [fliplr(V), V, V1];                 % 1->2 (V shrinks), 2->3 + 3->4 (V grows), back to 1
P_loop = [fliplr(P_comp), P_exp, P1];

figure;
plot(V_loop*1e6, P_loop/1e5, 'b-', 'LineWidth', 1.5); hold on;

% label the four state points
Vpts = [V1 V2 V2 V1]*1e6;
Ppts = [P1 P2 P3 P4]/1e5;
plot(Vpts, Ppts, 'ro', 'MarkerFaceColor', 'r');
text(Vpts+10, Ppts+4, {'1','2','3','4'});

xlabel('Volume (cm^3)'); ylabel('Pressure (bar)');
title(sprintf('Ideal Otto cycle, 2JZ-GE (one cylinder), W_{net} = %.0f J', W_net));
grid on; hold off;



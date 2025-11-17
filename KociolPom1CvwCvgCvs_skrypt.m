
clear all; close all;
%demo dla pomieszczenia z grzejnikem wodnym
model='KociolPom1CvwCvgCvs';
%model='pom1kot_ss';
aparam1;
%wartoœci nominalne
%parametry instalacji w warunkach obliczeniowych
QgN = 2000;		%[W] 
QkN = QgN;
TzewN = -20;			%[C] (temperatura na zewn¹trz)
TwewN = 20;			%[C] (zadana temperatura wewnetrzna)
TsN = 5;              % [C] oszacowanie temperatury scian
TgzN = 90;			%[C]  
TgpN = 70;			%[C] 
TkzN = TgzN;		%[C]  
TkpN = TgpN;		%[C] 

%parametry statyczne
FgN = QgN/(cpw*(TgzN-TgpN));	%[kg/s]
Kcg = QgN/(TgpN-TwewN);			%[W/K]
Kcw = QgN/(TwewN-TsN);			%[W/K]
Kcs = QgN/(TsN-TzewN);			%[W/K]

%parametry "dynamiczne" - aparam1
%==========================
%warunki pocz¹tkowe
Tzew0 = TzewN+0;	%+1
Qk0 = QkN;
Fg0 = FgN;
Fk0 = Fg0;
Qt0 = 0;
%stan równowagi
a = cpw*Fg0;
Ts0  = Qk0/Kcs + Tzew0;
Twew0  = Qk0/Kcw + Ts0;
Tgp0  = Qk0/Kcg + Twew0;
Tkz0  = Qk0/(cpw*Fk0) + Tgp0;

%do równañ stanu i r.statycznych X=Tgp, Twew
%u=[Tgz; Tz];	x=[Tw; Tgp, Ts], y=x
A = [(-Kcg-Kcw)/Cvw,   Kcg/Cvw,                   Kcw/Cvw,            0; ...
       Kcg/Cvg,                (-cpw*Fg0-Kcg)/Cvg, 0,                        cpw*Fg0/Cvg; ...
       Kcw/Cvs,               0,                               (-Kcw-Kcs)/Cvs,  0; ...
	  0,                              cpw*Fg0/Cvk,           0,                         -cpw*Fg0/Cvk];
B = [0,      0;
       0,       0; 
       0,       Kcs/Cvs;
       1/Cvk, 0];
C = [1, 0, 0, 0; 0, 1, 0, 0; 0, 0, 1, 0; 0, 0, 0, 1]; D=[0,0;0,0;0,0;0,0];

u0 = [Qk0; Tzew0];					%u=[Tgz; Tz],
x0 = -A^(-1)*B*u0;
Twew0 = x0(1);Tgp0 = x0(2);Ts0 = x0(3); Tkz0 = x0(4);			%x=[Tw; Tgp; Ts; Tkz], 
%==========================
%zak³ócenie
dQk = 0.1 * QkN;
dTzew = 0;
dFg = 0*FgN;
dTgz = 0;
dQt = 0;
%==========================
%symulacja
czas =4000;	czas_skok = 500;
%opcje = simget(model); %opcje = simset('MaxStep', tmax, 'RelTol',terr);
[t] = sim(model, czas); 
figure(1); hold on; grid on; title('Twew'); plot(t,aTwew,'m--'),
figure(2); hold on; grid on; title('Tkz, Tkp'); plot(t,aTkz,'r--'), plot(t,aTgp,'b--'), legend('Tjz', 'Tkp');



clear all; close all;
%demo dla pomieszczenia z grzejnikem wodnym
model='KociolPom1CvwCvg';
%model='pom1kot_ss';
aparam1;
%wartoœci nominalne
%parametry instalacji w warunkach obliczeniowych
QgN = 2000;		%[W] 
QkN = QgN;
TzewN = -20;			%[C] (temperatura na zewn¹trz)
TwewN = 20;			%[C] (zadana temperatura wewnetrzna)
TgzN = 90;			%[C]  
TgpN = 70;			%[C] 
TkzN = TgzN;		%[C]  
TkpN = TgpN;		%[C] 

%parametry statyczne
FgN = QgN/(cpw*(TgzN-TgpN));	%[kg/s]
Kcg = QgN/(TgpN-TwewN);			%[W/K]
Kcw = QgN/(TwewN-TzewN);			%[W/K]

%parametry "dynamiczne" - aparam1
%==========================
%warunki pocz¹tkowe
Tzew0 = TzewN+0;	%+1
%Qk0 = QkN;
Qk0 = 0;
Fg0 = FgN;
Fk0 = Fg0;
Qt0 = 0;
%stan równowagi
a = cpw*Fg0;
Twew0  = Qk0/Kcw + Tzew0;
Tgp0  = Qk0/Kcg + Twew0;
Tkz0  = Qk0/(cpw*Fk0) + Tgp0;

%do równañ stanu i r.statycznych X=Tgp, Twew
%u=[Tgz; Tz];	x=[Tw; Tgp], y=x
A = [(-Kcg-Kcw)/Cvws, Kcg/Cvws,                 0; ...
      Kcg/Cvg,                (-cpw*Fg0-Kcg)/Cvg, cpw*Fg0/Cvg; ...
	  0,                           cpw*Fg0/Cvk,             -cpw*Fg0/Cvk];
B = [0, Kcw/Cvws; 
       0, 0;  
       1/Cvk,        0];
C = [1, 0, 0; 0, 1, 0; 0, 0, 1]; D=[0,0;0,0;0,0];

u0 = [Qk0; Tzew0];					%u=[Tgz; Tz],
x0 = -A^(-1)*B*u0;
Twew0 = x0(1);Tgp0 = x0(2);Tkz0 = x0(3);			%x=[Tw; Tgp; Tkz], 
%==========================
%zak³ócenie
dQk = 0.2* QkN;
dTzew = 0;
dFg = 0*FgN;
dTgz = 0;
dQt = 0;
%==========================
%symulacja
czas =8000;	czas_skok = 500;
%opcje = simget(model); %opcje = simset('MaxStep', tmax, 'RelTol',terr);
[t] = sim(model, czas); 
figure(1); hold on; grid on; title('Porównanie modelu z orygina³em (METODA STYCZNEJ)');
%figure(2); hold on; grid on; title('Tkz, Tkp'); plot(t,aTkz,'r'), plot(t,aTgp,'b'), legend('Tjz', 'Tkp');
figure(2); hold on; grid on; title('aQk'); plot(t,aQk,'m'),
%figure(3); hold on; grid on; title('aTwew(Qk)'); plot(aQk,aTwew,'m'),

wynik_koncowy = aCalka1.Data(end);

% Wyœwietlenie wyniku
fprintf('Pole pod wykresem (ca³ka) wynosi: %.10f\n', wynik_koncowy);



wynik_koncowy2 = aCalka2.Data(end);

% Wyœwietlenie wyniku
fprintf('Pole pod wykresem (ca³ka) wynosi: %.10f\n', wynik_koncowy2);



wynik_koncowy3 = aCalka3.Data(end);

% Wyœwietlenie wyniku
fprintf('Pole pod wykresem (ca³ka) wynosi: %.10f\n', wynik_koncowy3);


wynik_koncowy4 = aCalka4.Data(end);

% Wyœwietlenie wyniku
fprintf('Pole pod wykresem (ca³ka) wynosi: %.10f\n', wynik_koncowy4);

% === KROK 1: Pobranie momentów (wyników ca³ek) z Simulinka ===

% Przypisanie wyników do zmiennych m0, m1, m2, m3
% Zak³adam, ¿e aCalka1 to moment m0, aCalka2 to m1, itd.
m0 = aCalka1.Data(end);
m1 = aCalka2.Data(end);
m2 = aCalka3.Data(end);
m3 = aCalka4.Data(end);

fprintf('--- Pobrane momenty (wyniki ca³ek) ---\n');
fprintf('m0 (z aCalka1) = %.10f\n', m0);
fprintf('m1 (z aCalka2) = %.10f\n', m1);
fprintf('m2 (z aCalka3) = %.10f\n', m2);
fprintf('m3 (z aCalka4) = %.10f\n', m3);
fprintf('\n');
% === METODA 2: Skrypt dla modelu Padé [0, 2] (3 parametry: b0, a1, a2) ===

fprintf('--- Obliczanie parametrów modelu Padé [0, 2] ---\n');

% Krok 1: Obliczenie wspó³czynników szeregu C_i
C0 = m0;
C1 = -m1;
C2 = m2 / 2.0;

fprintf('C0 = %.10f\n', C0);
fprintf('C1 = %.10f\n', C1);
fprintf('C2 = %.10f\n', C2);

% Krok 2: Rozwi¹zanie równañ
% b0 = C0
% 0 = C1 + a1*C0
% 0 = C2 + a1*C1 + a2*C0
fprintf('\nObliczanie parametrów...\n');

% Parametr b0
b0 = C0;
fprintf('1. Parametr b0 = %.10f\n', b0);

% Parametr a1
a1 = -C1 / C0;
fprintf('2. Parametr a1 = %.10f\n', a1);

% Parametr a2
a2 = (-C2 - a1*C1) / C0;
fprintf('3. Parametr a2 = %.10f\n', a2);
fprintf('\n');

% Krok 3: Zdefiniowanie transmitancji
fprintf('--- Wynikowa transmitancja (model inercyjny 2. rzêdu) ---\n');
s = tf('s');
G_aprox_0_2 = b0 / (a2*s^2 + a1*s + 1);
disp(G_aprox_0_2);

if a1 < 0 || a2 < 0
    fprintf('UWAGA: Model jest niestabilny (a1 lub a2 < 0).\n');
end
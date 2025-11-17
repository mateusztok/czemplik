 clear all; close all;
%demo dla pomieszczenia z grzejnikem wodnym
model='kociolsimulinkskok';
%model='pom1kot_ss';
aparam1;
%wartoœci nominalne
%parametry instalacji w warunkach obliczeniowych
QgN = 2000; %[W]
QkN = QgN;
TzewN = -20; %[C] (temperatura na zewn¹trz)
TwewN = 20; %[C] (zadana temperatura wewnetrzna)
TgzN = 90; %[C]
TgpN = 70; %[C]
TkzN = TgzN; %[C]
TkpN = TgpN; %[C]
%parametry statyczne
FgN = QgN/(cpw*(TgzN-TgpN)); %[kg/s]
Kcg = QgN/(TgpN-TwewN); %[W/K]
Kcw = QgN/(TwewN-TzewN); %[W/K]
%parametry "dynamiczne" - aparam1
%==========================
%warunki pocz¹tkowe
Tzew0 = TzewN+0; %+1
Qk0 = QkN;
Fg0 = FgN;
Fk0 = Fg0;
Qt0 = 0;
%stan równowagi
a = cpw*Fg0;
Twew0 = Qk0/Kcw + Tzew0;
Tgp0 = Qk0/Kcg + Twew0;
Tkz0 = Qk0/(cpw*Fk0) + Tgp0;
%do równañ stanu i r.statycznych X=Tgp, Twew
final_value=+2;
%u=[Qk; Tzew]; x=[Twew; Tgp; Tkz], y=x
A = [(-Kcg-Kcw)/Cvws, Kcg/Cvws, 0; ...
Kcg/Cvg, (-cpw*Fg0-Kcg)/Cvg, cpw*Fg0/Cvg; ...
0, cpw*Fg0/Cvk, -cpw*Fg0/Cvk];
B = [0, Kcw/Cvws;
0, 0;
1/Cvk, 0];
C = [1, 0, 0; 0, 1, 0; 0, 0, 1]; D=[0,0;0,0;0,0];
u0 = [Qk0; Tzew0]; %u=[Tgz; Tz],
x0 = -A^(-1)*B*u0;
Twew0 = x0(1);Tgp0 = x0(2);Tkz0 = x0(3); %x=[Tw; Tgp; Tkz],
%==========================
%zak³ócenie
dQk = 0.1 * QkN;
dTzew = 0;
dFg = 0*FgN;
dTgz = 0;
dQt = 0;
%==========================
K = 1; % Wartoœæ zastêpcza
T = 1; % Wartoœæ zastêpcza
T0 = 0; % Wartoœæ zastêpcza


Ki_ZN=0;
Kp_ZN=0;
Ti_ZN=0;

%symulacja
czas =6000; czas_skok = 500;
%opcje = simget(model); %opcje = simset('MaxStep', tmax, 'RelTol',terr);
[t] = sim(model, czas);
% figure(1); hold on; grid on; title('Twew'); plot(t,aTwew,'m'),
figure(1); hold on; grid on; title('Porównanie modelu z orygina³em (METODA DWUPUNKTOWA)'); 
plot(t, aTwew, 'r-', 'LineWidth', 2); % Czerwony, ci¹g³y, gruby
% figure(2); hold on; grid on; title('Tkz, Tkp'); plot(t,aTkz,'r'), plot(t,aTgp,'b'), legend('Tjz', 'Tkp');

% --- Wyznaczanie transmitancji dwupunktowej ---

% Szukamy wartoœci pocz¹tkowej i koñcowej

y_poczatkowe = aTwew(find(t >= czas_skok, 1, 'first'));
y_koncowe = aTwew(end); % Wartoœæ Twew po ustabilizowaniu
% Skok wejœcia (dQk)
wejscie_skok = dQk;

% Obliczanie wzmocnienia K
K = (y_koncowe - y_poczatkowe) / wejscie_skok;

% Wyszukanie punktów do metody dwupunktowej
% Szukamy momentu, w którym sygna³ osi¹ga 28.3% i 63.2% ca³kowitej zmiany

delta_y = y_koncowe - y_poczatkowe;

y_28_3 = y_poczatkowe + 0.283 * delta_y;

y_63_2 = y_poczatkowe + 0.632 * delta_y;

% ZnajdŸ indeksy czasów, w których osi¹gniête s¹ te wartoœci

idx_28_3 = find(aTwew >= y_28_3, 1, 'first');

idx_63_2 = find(aTwew >= y_63_2, 1, 'first');

t_28_3 = t(idx_28_3);

t_63_2 = t(idx_63_2);

% Obliczanie opóŸnienia T0 i sta³ej czasowej T

T0 = 2.33 * t_28_3 - 1.33 * t_63_2;

T = 1.5 * (t_63_2 - t_28_3);

fprintf('Parametry wyznaczone metod¹ dwupunktow¹:\n');

fprintf('Wzmocnienie K: %.4f\n', K);

fprintf('Sta³a czasowa T: %.4f s\n', T);

fprintf('OpóŸnienie T0: %.4f s\n', T0);

Kp_ZN = 0.9 * T / (K * T0);
Ti_ZN = 3.33 * T0;

if Ti_ZN == 0
    Ki_ZN = 0; 
    fprintf('UWAGA: Czas opóŸnienia T0 wynosi 0. Nastawy Z-N mog¹ byæ niepoprawne.\n');
else
    Ki_ZN = Kp_ZN / Ti_ZN;
end

% Wizualizacja punktów na wykresie

plot(t_28_3, y_28_3, 'bo', 'MarkerSize', 8, 'LineWidth', 2);

plot(t_63_2, y_63_2, 'go', 'MarkerSize', 8, 'LineWidth', 2);

text(t_28_3 + 100, y_28_3, sprintf(' t1=%.0f', t_28_3), 'Color', 'b', 'FontSize', 10);

text(t_63_2 + 100, y_63_2, sprintf(' t2=%.0f', t_63_2), 'Color', 'g', 'FontSize', 10);

plot([czas_skok, czas], [y_poczatkowe, y_poczatkowe], 'k--', 'LineWidth', 1); % Linia pocz¹tkowa

plot([czas_skok, czas], [y_koncowe, y_koncowe], 'k--', 'LineWidth', 1);

% --- KROK 4: Druga symulacja (WALIDACJA) ---

% Mamy ju¿ prawdziwe K, T, T0. Uruchamiamy symulacjê PONOWNIE,

% aby 'aTwewDwupunkt' zosta³ obliczony z poprawnymi parametrami.

fprintf('Uruchamiam drug¹ symulacjê (walidacja)...\n');

% To jest kluczowe! Ponowne uruchomienie symulacji z poprawnymi K, T, T0

[t] = sim(model, czas);

% --- KROK 5: Rysowanie modelu FOPDT ---

% Teraz rysujemy aTwewDwupunkt, który pochodzi z DRUGIEJ symulacji

% plot(t, aTwewDwupunkt, 'b--', 'LineWidth', 1.5);

plot(t, aTwewDwupunkt, 'b--', 'LineWidth', 2); % Niebieski, przerywany, gruby

% Dodanie legendy i finalizacja wykresu

legend('Orygina³ (model SS)', 'pkt 28.3%', 'pkt 63.2%', 'Poziomy y_{min}, y_{max}', '', 'Model FOPDT (dwupunktowy)', 'Location', 'southeast');

% legend('Orygina³ (model SS)', 'pkt 28.3%', 'pkt 63.2%', 'Poziomy y_{min}, y_{max}', '', 'Model FOPDT (dwupunktowy)');

% title('Porównanie modelu z orygina³em');


figure(2); hold on; grid on; title('Porównanie reakcji na modelu i na obiekcie: model 2-punktowy i ZN '); 
plot(t, aTwewDwupunkt, 'r-', 'LineWidth', 2); % Czerwony, ci¹g³y, gruby



plot(t, aTwew1, 'b-', 'LineWidth', 2); % Czerwony, ci¹g³y, gruby
hold off; % --- NOWE LINIE ---
xlabel('Czas [s]');
ylabel('Temperatura wewnêtrzna Twew [C]');
legend('Model', 'Obiekt', 'Location', 'southeast');
% --- KONIEC NOWYCH LINII ---
clear all; close all;
model='kociolsimulinkskok';
aparam1;
%Definicja parametrów i punktu pracy
QgN = 2000; QkN = QgN; TzewN = -20; TwewN = 20; TgzN = 90;
TgpN = 70; TkzN = TgzN; TkpN = TgpN;
FgN = QgN/(cpw*(TgzN-TgpN));
Kcg = QgN/(TgpN-TwewN);
Kcw = QgN/(TwewN-TzewN);
Tzew0 = TzewN+0; Qk0 = QkN; Fg0 = FgN; Fk0 = FgN; Qt0 = 0;
Twew0 = Qk0/Kcw + Tzew0;
Tgp0 = Qk0/Kcg + Twew0;
Tkz0 = Qk0/(cpw*Fk0) + Tgp0;
final_value = +2; 
dQt = 0;
dFg = 0*FgN;
dTzew = 0;
K = 1; T = 1; T0 = 0;
Ki_ZN=0; Kp_ZN=0; Ti_ZN=0;
% (Identyfikacja)
czas =6000; czas_skok = 500;
final_value_ident = final_value; 
final_value = 0; 
dQk = 0.1 * QkN; 
dFg = 0*FgN;
dTzew = 0;
dQt = 0; 
fprintf('Uruchamiam symulację #1 (Identyfikacja metodą stycznej)...\n');
[t] = sim(model, czas); 
figure(1); hold on; grid on; title('Identyfikacja obiektu (METODA STYCZNEJ)');
xlabel('Czas [s]'); ylabel('Temperatura Twew [C]');
plot(t, aTwew, 'r-', 'LineWidth', 2, 'DisplayName', 'Odpowiedź obiektu (aTwew)');
fprintf('Analizuję odpowiedź skokową metodą stycznej...\n');
idx_start = find(t >= czas_skok, 1, 'first');
y_poczatkowe = aTwew(idx_start); y_koncowe = aTwew(end);
wejscie_skok = dQk; 
K = (y_koncowe - y_poczatkowe) / wejscie_skok;
dy_dt = gradient(aTwew(idx_start:end), t(idx_start:end));
[styczna_nachylenie, idx_przegiecia_local] = max(dy_dt);
idx_przegiecia_global = idx_przegiecia_local + idx_start - 1;
t_przegiecia = t(idx_przegiecia_global); y_przegiecia = aTwew(idx_przegiecia_global);
t1_styczna = (y_poczatkowe - y_przegiecia) / styczna_nachylenie + t_przegiecia;
t2_styczna = (y_koncowe - y_przegiecia) / styczna_nachylenie + t_przegiecia;
T0_styczna = t1_styczna - czas_skok; T_styczna = t2_styczna - t1_styczna;
K = K; T = T_styczna; T0 = T0_styczna;
fprintf('Parametry wyznaczone metodą STYCZNEJ:\n');
fprintf('Wzmocnienie K: %.4f\n', K);
fprintf('Stała czasowa T: %.4f s\n', T);
fprintf('Opóźnienie T0: %.4f s\n', T0);
plot(t_przegiecia, y_przegiecia, 'go', 'MarkerSize', 10, 'LineWidth', 2, 'DisplayName', 'Punkt przegięcia');
t_styczna_rys = [t1_styczna, t2_styczna]; y_styczna_rys = [y_poczatkowe, y_koncowe];
plot(t_styczna_rys, y_styczna_rys, 'g--', 'LineWidth', 2, 'DisplayName', 'Styczna');
% skok SP, BEZ zakłócenia
final_value = final_value_ident; 
dQk = 0; 
dFg = 0*FgN;
dTzew = 0;
dQt = 0;
%  Obliczenie nastaw ZN i druga symulacja ---
Kp_ZN = 0.9 * T / (K * T0); Ti_ZN = 3.33 * T0;
if Ti_ZN == 0 || isnan(Ti_ZN) || K == 0 || T0 <= 0
    Ki_ZN = 0; Kp_ZN = 0;
    fprintf('UWAGA: Parametry T0 lub K są niepoprawne. Nastawy Z-N ustawiono na 0.\n');
else
    Ki_ZN = Kp_ZN / Ti_ZN;
end
fprintf('Obliczone nastawy Z-N (styczna):\n');
fprintf('Kp = %.4f\n', Kp_ZN); fprintf('Ki = %.4f\n', Ki_ZN);
Kp_ZN_styczna = Kp_ZN; Ki_ZN_styczna = Ki_ZN;
fprintf(' (Walidacja nastaw ZN - skok SP\n');
[t] = sim(model, czas);
% --- KROK 5: Rysowanie wyników dla ZN ---
plot(t, aTwewDwupunkt, 'b--', 'LineWidth', 2, 'DisplayName', 'Model FOPDT (styczna)');
legend('Location', 'southeast'); hold off;
figure(2); hold on; grid on; 
title('Walidacja ZN (styczna): Obiekt (URO) vs Model (URM) - Skok SP'); 
plot(t, aTwewDwupunkt, 'r-', 'LineWidth', 2, 'DisplayName', 'Model FOPDT (URM)'); 
plot(t, aTwew1, 'b-', 'LineWidth', 2, 'DisplayName', 'Obiekt nieliniowy (URO)');
xlabel('Czas [s]'); ylabel('Temperatura [C]');
legend('Location', 'southeast'); hold off;
% --- KROK 6: PORÓWNANIE Z PIDTUNE (SKOK SP) ---
fprintf('Zapisuję wyniki dla ZN (skok SP)...\n');
t_ZN_sp = t; aTwew1_ZN_sp = aTwew1; aTwewDwupunkt_ZN_sp = aTwewDwupunkt;
aCVmodel_ZN_sp = CVmodel1; aCVobiekt_ZN_sp = CVobiekt;
fprintf('Obliczam nastawy PID Tune...\n');
G_urm = tf(K, [T 1], 'InputDelay', T0); 
C_pidtune = pidtune(G_urm, 'PI');
Kp_pidtune = C_pidtune.Kp; Ki_pidtune = C_pidtune.Ki;
fprintf('Obliczone nastawy PID TUNE:\n');
fprintf('Kp (pidtune) = %.4f\n', Kp_pidtune); fprintf('Ki (pidtune) = %.4f\n', Ki_pidtune);
Kp_ZN = Kp_pidtune; Ki_ZN = Ki_pidtune;
fprintf('Uruchamiam symulację #3 (PID TUNE - skok SP)...\n');
[t] = sim(model, czas);
fprintf('Zapisuję wyniki dla PID TUNE (skok SP)...\n');
t_PID_sp = t; aTwew1_PID_sp = aTwew1; aTwewDwupunkt_PID_sp = aTwewDwupunkt;
aCVmodel_PID_sp = CVmodel1; aCVobiekt_PID_sp = CVobiekt;

% ========================================================================
% === NOWA METODA: SKOGESTAD IMC (SIMC) - DOKŁADNIE WG NAUCZANIA ===
% ========================================================================
% Wzory ze slajdu 11 "IMC -> Skogestad IMC (SIMple Control)"
% 
% Model obiektu: G(s) = k*exp(-T0*s) / (T*s + 1)  [FOPDT]
% Docelowa transmitancja UR: Gz(s) = exp(-T0*s) / (Tz*s + 1)
%
% Gdzie: Tz - zadana stała czasowa UR
%
% Po wyprowadzeniu transmitancji regulatora otrzymujemy wzór na PI:
%   R(s) = Kp * (1 + 1/(Ti*s))
%
% Nastawy regulatora PI wg Skogestada:
%   Kp = (T + T0) / (k * Tz)
%   Ti = T
%   Ki = Kp / Ti

fprintf('\n--- METODA 3: Skogestad IMC (SIMC) - wg slajdu 11 ---\n');

% Dobór stałej Tz zależy od żądanej szybkości UR:
% - agresywny:       0.1*T < Tz < 0.8*T0
% - średni (default):      Tz = T0  (dla moderacyjnego, zalecane)
% - konserwatywny: 10*T < Tz < 80*T0

Tz_SIMC = T0;  % Tryb średni/moderate (zalecany)

% Wzory dla regulatora PI
Kp_SIMC = (T + T0) / (K * Tz_SIMC);
Ti_SIMC = T;
Ki_SIMC = Kp_SIMC / Ti_SIMC;

fprintf('Parametry metody SIMC (Skogestad IMC):\n');
fprintf('  Model obiektu: G(s) = %.4f*exp(-%.2f*s) / (%.2f*s + 1)\n', K, T0, T);
fprintf('  Tz (żądana stała czasowa UR) = %.4f s\n', Tz_SIMC);
fprintf('  Typ regulacji: średnia/moderate\n');
fprintf('\nObliczone nastawy SIMC (Skogestad IMC - regulator PI):\n');
fprintf('  Kp = (T + T0) / (k*Tz) = (%.4f + %.4f) / (%.4f*%.4f) = %.4f\n', T, T0, K, Tz_SIMC, Kp_SIMC);
fprintf('  Ti = T = %.4f s\n', Ti_SIMC);
fprintf('  Ki = Kp / Ti = %.4f\n', Ki_SIMC);

Kp_ZN = Kp_SIMC; Ki_ZN = Ki_SIMC;
fprintf('Uruchamiam symulację #4 (SIMC - skok SP)...\n');
[t] = sim(model, czas);
fprintf('Zapisuję wyniki dla SIMC (skok SP)...\n');
t_SIMC_sp = t; aTwew1_SIMC_sp = aTwew1; aTwewDwupunkt_SIMC_sp = aTwewDwupunkt;
aCVmodel_SIMC_sp = CVmodel1; aCVobiekt_SIMC_sp = CVobiekt;

% --- KROK 7: RYSOWANIE WYKRESÓW PORÓWNAWCZYCH (SKOK SP) ---
figure(3); hold on; grid on;
plot(t_ZN_sp, aTwewDwupunkt_ZN_sp, 'r-', 'LineWidth', 2, 'DisplayName', 'ZN (styczna)');
plot(t_PID_sp, aTwewDwupunkt_PID_sp, 'b--', 'LineWidth', 2, 'DisplayName', 'PID Tune');
plot(t_SIMC_sp, aTwewDwupunkt_SIMC_sp, 'g:', 'LineWidth', 2.5, 'DisplayName', 'SIMC (Skogestad)');
title('Porównanie metod na MODELU (URM) - Reakcja na skok SP (PV)');
xlabel('Czas [s]'); ylabel('Temperatura [C]');
legend('Location', 'southeast'); hold off;
saveas(gcf, 'porownanie_urm_pv.png');

figure(4); hold on; grid on;
plot(t_ZN_sp, aCVmodel_ZN_sp, 'r-', 'LineWidth', 2, 'DisplayName', 'ZN (styczna)');
plot(t_PID_sp, aCVmodel_PID_sp, 'b--', 'LineWidth', 2, 'DisplayName', 'PID Tune');
plot(t_SIMC_sp, aCVmodel_SIMC_sp, 'g:', 'LineWidth', 2.5, 'DisplayName', 'SIMC (Skogestad)');
title('Porównanie metod na MODELU (URM) - Reakcja na skok SP (CV)');
xlabel('Czas [s]'); ylabel('Sygnał sterujący CV');
legend('Location', 'northeast'); hold off;
saveas(gcf, 'porownanie_urm_cv.png');

figure(5); hold on; grid on;
plot(t_ZN_sp, aTwew1_ZN_sp, 'r-', 'LineWidth', 2, 'DisplayName', 'ZN (styczna)');
plot(t_PID_sp, aTwew1_PID_sp, 'b--', 'LineWidth', 2, 'DisplayName', 'PID Tune');
plot(t_SIMC_sp, aTwew1_SIMC_sp, 'g:', 'LineWidth', 2.5, 'DisplayName', 'SIMC (Skogestad)');
title('Porównanie metod na OBIEKCIE (URO) - Reakcja na skok SP (PV)');
xlabel('Czas [s]'); ylabel('Temperatura [C]');
legend('Location', 'southeast'); hold off;
saveas(gcf, 'porownanie_uro_pv.png');

figure(6); hold on; grid on;
plot(t_ZN_sp, aCVobiekt_ZN_sp, 'r-', 'LineWidth', 2, 'DisplayName', 'ZN (styczna)');
plot(t_PID_sp, aCVobiekt_PID_sp, 'b--', 'LineWidth', 2, 'DisplayName', 'PID Tune');
plot(t_SIMC_sp, aCVobiekt_SIMC_sp, 'g:', 'LineWidth', 2.5, 'DisplayName', 'SIMC (Skogestad)');
title('Porównanie metod na OBIEKCIE (URO) - Reakcja na skok SP (CV)');
xlabel('Czas [s]'); ylabel('Sygnał sterujący CV');
legend('Location', 'northeast'); hold off;
saveas(gcf, 'porownanie_uro_cv.png');

% === KROK 8: TEST NA TŁUMIENIE ZAKŁÓCEŃ
fprintf('\n--- Rozpoczynam KROK 8: Test na tłumienie zakłóceń (URO) ---\n');
% --- Ustawienia testu na zakłócenie ---
final_value = 0; 
dQk = 0;         
dFg = 0*FgN;
dTzew = 0;
dQt = 0.1 * QkN; 
fprintf('Test zakłócenia: final_value=0, dQk=0, dQt=%.2f\n', dQt);

% --- Uruchomienie #5: Test zakłócenia dla ZN ---
Kp_ZN = Kp_ZN_styczna; Ki_ZN = Ki_ZN_styczna;
fprintf('Uruchamiam symulację #5 (Zakłócenie, nastawy ZN)...\n');
[t] = sim(model, czas);
t_URO_zak_ZN = t;
aTwew1_URO_zak_ZN = aTwew1;
aCVobiekt_URO_zak_ZN = CVobiekt;

% --- Uruchomienie #6: Test zakłócenia dla PID TUNE ---
Kp_ZN = Kp_pidtune; Ki_ZN = Ki_pidtune;
fprintf('Uruchamiam symulację #6 (Zakłócenie, nastawy PID TUNE)...\n');
[t] = sim(model, czas);
t_URO_zak_PID = t;
aTwew1_URO_zak_PID = aTwew1;
aCVobiekt_URO_zak_PID = CVobiekt;

% --- Uruchomienie #7: Test zakłócenia dla SIMC ---
Kp_ZN = Kp_SIMC; Ki_ZN = Ki_SIMC;
fprintf('Uruchamiam symulację #7 (Zakłócenie, nastawy SIMC)...\n');
[t] = sim(model, czas);
t_URO_zak_SIMC = t;
aTwew1_URO_zak_SIMC = aTwew1;
aCVobiekt_URO_zak_SIMC = CVobiekt;

% --- Rysowanie wykresów zakłócenia ---
figure(7);
hold on; grid on;
plot(t_URO_zak_ZN, aTwew1_URO_zak_ZN, 'r-', 'LineWidth', 2, 'DisplayName', 'ZN (styczna)');
plot(t_URO_zak_PID, aTwew1_URO_zak_PID, 'b--', 'LineWidth', 2, 'DisplayName', 'PID Tune');
plot(t_URO_zak_SIMC, aTwew1_URO_zak_SIMC, 'g:', 'LineWidth', 2.5, 'DisplayName', 'SIMC (Skogestad)');
title('Porównanie metod na OBIEKCIE (URO) - Reakcja na zakłócenie (PV)');
xlabel('Czas [s]'); ylabel('Temperatura Twew [C]');
legend('Location', 'northeast');
hold off;
saveas(gcf, 'porownanie_uro_zak_pv.png');

figure(8);
hold on; grid on;
plot(t_URO_zak_ZN, aCVobiekt_URO_zak_ZN, 'r-', 'LineWidth', 2, 'DisplayName', 'ZN (styczna)');
plot(t_URO_zak_PID, aCVobiekt_URO_zak_PID, 'b--', 'LineWidth', 2, 'DisplayName', 'PID Tune');
plot(t_URO_zak_SIMC, aCVobiekt_URO_zak_SIMC, 'g:', 'LineWidth', 2.5, 'DisplayName', 'SIMC (Skogestad)');
title('Porównanie metod na OBIEKCIE (URO) - Reakcja na zakłócenie (CV)');
xlabel('Czas [s]'); ylabel('Sygnał sterujący CV (z obiektu)');
legend('Location', 'northeast');
hold off;
saveas(gcf, 'porownanie_uro_zak_cv.png');
fprintf('Zakończono. Wygenerowano 2 nowe wykresy z testu zakłócenia.\n');

% === KROK 9: ANALIZA BODLEGO I WSKAŹNIKI JAKOŚCI 
% ===================================================================
fprintf('\n--- Rozpoczynam KROK 9: Analiza Bodego i Wskaźniki Jakości ---\n');
G_urm = tf(K, [T 1], 'InputDelay', T0);
fprintf('Używam modelu FOPDT ze stycznej: K=%.2f, T=%.1f, T0=%.1f\n', K, T, T0);

%2. Wszystkie regulatory jako transmitancje
s = tf('s');
C_ZN = Kp_ZN_styczna + Ki_ZN_styczna/s;
C_ZN.Name = 'ZN (styczna)';
C_PIDTUNE = Kp_pidtune + Ki_pidtune/s;
C_PIDTUNE.Name = 'PID Tune';
C_SIMC = Kp_SIMC + Ki_SIMC/s;
C_SIMC.Name = 'SIMC (Skogestad)';

%3. Stwórz systemy otwarte i zamknięte
G_otwarty_ZN = C_ZN * G_urm;
G_otwarty_PIDTUNE = C_PIDTUNE * G_urm;
G_otwarty_SIMC = C_SIMC * G_urm;

G_zamkniety_ZN = feedback(G_otwarty_ZN, 1);
G_zamkniety_PIDTUNE = feedback(G_otwarty_PIDTUNE, 1);
G_zamkniety_SIMC = feedback(G_otwarty_SIMC, 1);

%5. Generuj wykres Bodego
figure(9);
bodeplot(G_otwarty_ZN, 'r-', G_otwarty_PIDTUNE, 'b--', G_otwarty_SIMC, 'g:');
title('Charakterystyki Bodego (Pętla otwarta, model URM)');
legend('ZN (styczna)', 'PID Tune', 'SIMC (Skogestad)', 'Location', 'southwest');
grid on;
ax = findall(gcf, 'type', 'axes');
for i = 1:length(ax)
    current_YLabel = get(get(ax(i), 'YLabel'), 'String');
    if strcmp(current_YLabel, 'Magnitude (dB)')
        ylabel(ax(i), 'Wzmocnienie ');
        xlabel(ax(i), 'Częstotliwość');
    elseif strcmp(current_YLabel, 'Phase (deg)')
        ylabel(ax(i), 'Faza ');
        xlabel(ax(i), 'Częstotliwość');
    end
end
saveas(gcf, 'charakterystyki_bode.png');

%6. Oblicz wskaźniki jakości i zapasy stabilności
fprintf('Obliczam wskaźniki...\n');
[Gm_ZN_lin, Pm_ZN] = margin(G_otwarty_ZN);
[Gm_PID_lin, Pm_PID] = margin(G_otwarty_PIDTUNE);
[Gm_SIMC_lin, Pm_SIMC] = margin(G_otwarty_SIMC);

Gm_ZN_dB = 20*log10(Gm_ZN_lin);
Gm_PID_dB = 20*log10(Gm_PID_lin);
Gm_SIMC_dB = 20*log10(Gm_SIMC_lin);

info_ZN = stepinfo(G_zamkniety_ZN);
info_PID = stepinfo(G_zamkniety_PIDTUNE);
info_SIMC = stepinfo(G_zamkniety_SIMC);

%7. Wyświetl tabelę wyników w konsoli (gotowa do wklejenia do LaTeX)
fprintf('\n--- TABELA WYNIKÓW (gotowa do LaTeXa) ---\n');
fprintf('Metoda & Kp & Ki & PM [deg] & GM [dB] & Czas reg. [s] & Przereg. [%%] \\\\ \\hline \n');
fprintf('ZN (styczna) & %.2f & %.4f & %.2f & %.2f & %.1f & %.1f \\\\ \n', ...
    Kp_ZN_styczna, Ki_ZN_styczna, Pm_ZN, Gm_ZN_dB, info_ZN.SettlingTime, info_ZN.Overshoot);
fprintf('PID Tune & %.2f & %.4f & %.2f & %.2f & %.1f & %.1f \\\\ \n', ...
    Kp_pidtune, Ki_pidtune, Pm_PID, Gm_PID_dB, info_PID.SettlingTime, info_PID.Overshoot);
fprintf('SIMC (Skogestad) & %.2f & %.4f & %.2f & %.2f & %.1f & %.1f \\\\ \n', ...
    Kp_SIMC, Ki_SIMC, Pm_SIMC, Gm_SIMC_dB, info_SIMC.SettlingTime, info_SIMC.Overshoot);
fprintf('---------------------------------------------------\n');
fprintf('Zakończono. Wygenerowano wykres Bodego i tabelę wskaźników z trzema metodami.\n');

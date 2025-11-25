clear all; close all; clc;

% =========================================================================
% 1. KONFIGURACJA MODELU
% =========================================================================
model_name = 'Copy_2_of_kociolsimulinkskok'; 
czas_sym = 150;
s = tf('s');

% Wymuszenie formatu danych (żeby uniknąć błędu 'dot indexing')
load_system(model_name);
set_param(model_name, 'ReturnWorkspaceOutputs', 'on');
set_param(model_name, 'TimeSaveName', 'tout');

% Funkcja do pobierania danych (obsługuje Array i Timeseries)
extract_data = @(out, name) getDataSafe(out, name);


% =========================================================================
% 2. ANALIZA PRZYPADKU A: T1 > T2 (Kaskada ma sens)
% =========================================================================
fprintf('\n=== ANALIZA PRZYPADKU A: T1=10 (Główny wolny) > T2=1 (Pomocniczy szybki) ===\n');
T1 = 10; 
T2 = 1;
K_wzm = 1;

% --- Definicja obiektów ---
G1_tf = K_wzm / (T1*s + 1);
G2_tf = K_wzm / (T2*s + 1);

% --- Strojenie ("Ręczne" przy pomocy pidtune) ---
% 1. Układ Klasyczny (Jeden regulator na G1*G2)
R_klasyk_obj = pidtune(G1_tf * G2_tf, 'PI');
Kp_klasyk_A = R_klasyk_obj.Kp; Ki_klasyk_A = R_klasyk_obj.Ki;

% 2. Układ Kaskadowy (Strojenie "Bottom-Up")
% Krok I: Pętla Wewnętrzna (R2 - P) dla obiektu G2
opts_R2 = pidtuneOptions('DesignFocus', 'reference-tracking');
R2_obj = pidtune(G2_tf, 'P', opts_R2);
Kp2_A = R2_obj.Kp; Ki2_A = R2_obj.Ki; 

% Krok II: Pętla Zewnętrzna (R1 - PI) dla (G2_zamkniete * G1)
G_wew_zamknieta = feedback(R2_obj * G2_tf, 1);
R1_obj = pidtune(G_wew_zamknieta * G1_tf, 'PI');
Kp1_A = R1_obj.Kp; Ki1_A = R1_obj.Ki;

fprintf('Nastawy A: Klasyk[Kp=%.2f Ki=%.2f] | Kaskada[R2=%.2f, R1: Kp=%.2f Ki=%.2f]\n', ...
    Kp_klasyk_A, Ki_klasyk_A, Kp2_A, Kp1_A, Ki1_A);

% --- SYMULACJE DLA PRZYPADKU A ---
% Przekazanie zmiennych do Simulinka
Kp1 = Kp1_A; Ki1 = Ki1_A; Kp2 = Kp2_A; Ki2 = Ki2_A;
Kp_klasyk = Kp_klasyk_A; Ki_klasyk = Ki_klasyk_A;

% Test 1: Skok wartości zadanej
Y_zad = 1; Z2_val = 0;
out = sim(model_name, czas_sym);
t_A = out.tout;
y_klasyk_sp_A = extract_data(out, 'y_klasyk');
y_kaskada_sp_A = extract_data(out, 'y_kaskada');

% Test 2: Skok zakłócenia
Y_zad = 0; Z2_val = 1;
out = sim(model_name, czas_sym);
y_klasyk_z2_A = extract_data(out, 'y_klasyk');
y_kaskada_z2_A = extract_data(out, 'y_kaskada');


% =========================================================================
% 3. ANALIZA PRZYPADKU B: T1 < T2 (Kaskada traci sens)
% =========================================================================
fprintf('\n=== ANALIZA PRZYPADKU B: T1=1 (Główny szybki) < T2=10 (Pomocniczy wolny) ===\n');
T1 = 1; 
T2 = 10; % Zamiana miejscami

% --- Definicja obiektów ---
G1_tf = K_wzm / (T1*s + 1);
G2_tf = K_wzm / (T2*s + 1);

% --- Strojenie ("Ręczne" przy pomocy pidtune) ---
% 1. Układ Klasyczny
R_klasyk_obj = pidtune(G1_tf * G2_tf, 'PI');
Kp_klasyk_B = R_klasyk_obj.Kp; Ki_klasyk_B = R_klasyk_obj.Ki;

% 2. Układ Kaskadowy
% Krok I: Pętla Wewnętrzna (R2 - P) dla G2 (teraz wolnego!)
R2_obj = pidtune(G2_tf, 'P', opts_R2);
Kp2_B = R2_obj.Kp; Ki2_B = R2_obj.Ki; 

% Krok II: Pętla Zewnętrzna (R1 - PI)
G_wew_zamknieta = feedback(R2_obj * G2_tf, 1);
R1_obj = pidtune(G_wew_zamknieta * G1_tf, 'PI');
Kp1_B = R1_obj.Kp; Ki1_B = R1_obj.Ki;

fprintf('Nastawy B: Klasyk[Kp=%.2f Ki=%.2f] | Kaskada[R2=%.2f, R1: Kp=%.2f Ki=%.2f]\n', ...
    Kp_klasyk_B, Ki_klasyk_B, Kp2_B, Kp1_B, Ki1_B);

% --- SYMULACJE DLA PRZYPADKU B ---
% Przekazanie zmiennych do Simulinka (nadpisanie)
Kp1 = Kp1_B; Ki1 = Ki1_B; Kp2 = Kp2_B; Ki2 = Ki2_B;
Kp_klasyk = Kp_klasyk_B; Ki_klasyk = Ki_klasyk_B;

% Test 1: Skok wartości zadanej
Y_zad = 1; Z2_val = 0;
out = sim(model_name, czas_sym);
t_B = out.tout;
y_klasyk_sp_B = extract_data(out, 'y_klasyk');
y_kaskada_sp_B = extract_data(out, 'y_kaskada');

% Test 2: Skok zakłócenia
Y_zad = 0; Z2_val = 1;
out = sim(model_name, czas_sym);
y_klasyk_z2_B = extract_data(out, 'y_klasyk');
y_kaskada_z2_B = extract_data(out, 'y_kaskada');


% =========================================================================
% 4. RYSOWANIE WYKRESÓW PORÓWNAWCZYCH
% =========================================================================
figure(1);

% --- WYKRES 1: Reakcja na SP (Porównanie A i B) ---
subplot(2,1,1);
plot(t_A, y_klasyk_sp_A, 'r-', 'LineWidth', 1.5); hold on;
plot(t_A, y_kaskada_sp_A, 'b--', 'LineWidth', 2);
plot(t_B, y_klasyk_sp_B, 'm-', 'LineWidth', 1.5);
plot(t_B, y_kaskada_sp_B, 'c--', 'LineWidth', 2);
title('Porównanie: Reakcja na Skok Wartości Zadanej');
xlabel('Czas [s]'); ylabel('Wyjście Y');
legend('Klasyczna (A: T1>T2)', 'Kaskada (A: T1>T2)', ...
       'Klasyczna (B: T1<T2)', 'Kaskada (B: T1<T2)', 'Location', 'southeast');
grid on;

% --- WYKRES 2: Tłumienie Zakłócenia (Porównanie A i B) ---
subplot(2,1,2);
plot(t_A, y_klasyk_z2_A, 'r-', 'LineWidth', 1.5); hold on;
plot(t_A, y_kaskada_z2_A, 'b--', 'LineWidth', 2);
plot(t_B, y_klasyk_z2_B, 'm-', 'LineWidth', 1.5);
plot(t_B, y_kaskada_z2_B, 'c--', 'LineWidth', 2);
title('Porównanie: Tłumienie Zakłócenia Z2');
xlabel('Czas [s]'); ylabel('Odchyłka Y');
legend('Klasyczna (A: T1>T2)', 'Kaskada (A: T1>T2)', ...
       'Klasyczna (B: T1<T2)', 'Kaskada (B: T1<T2)', 'Location', 'northeast');
grid on;

fprintf('\nGotowe! Wykresy pokazują przewagę kaskady w przypadku A i brak przewagi w przypadku B.\n');


% =========================================================================
% Funkcja pomocnicza do danych (Array/Timeseries)
% =========================================================================
function data = getDataSafe(out, varName)
    raw = out.get(varName);
    if isnumeric(raw)
        data = raw; 
    elseif isa(raw, 'timeseries')
        data = raw.Data;
    elseif isa(raw, 'Simulink.SimulationData.Signal')
        data = raw.Values.Data;
    else
        try data = raw.Data; catch, error(['Błąd formatu: ' varName]); end
    end
end
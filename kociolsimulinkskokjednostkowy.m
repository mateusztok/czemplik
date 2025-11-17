clear all; close all;
model = 'KociolPom1CvwCvg'; % Upewnij siê, ¿e to nazwa Twojego pliku .slx
aparam1;

% 1. Wartoœci nominalne (zostaj¹ tak jak by³y)
QgN = 2000;
QkN = QgN;
TzewN = -20;
TwewN = 20;
TgzN = 90;
TgpN = 70;
TkzN = TgzN;
TkpN = TgpN;
dQt = 0;
% 2. Parametry statyczne (zostaj¹ tak jak by³y)
FgN = QgN/(cpw*(TgzN-TgpN));
Kcg = QgN/(TgpN-TwewN);
Kcw = QgN/(TwewN-TzewN);

% 3. Warunki pocz¹tkowe (punkt pracy, zostaj¹ tak jak by³y)
Tzew0 = TzewN;
Qk0 = QkN;
Fg0 = FgN;
Fk0 = Fg0;
Qt0 = 0;

% Obliczanie stanu równowagi (kluczowe dla B_new i dla wykresu)
Twew0  = Qk0/Kcw + Tzew0;
Tgp0  = Qk0/Kcg + Twew0;
Tkz0  = Qk0/(cpw*Fk0) + Tgp0;

% 4. NOWE MACIERZE (zgodnie z obrazkiem 1)
% Twój wektor stanu x = [Twew; Tgp; Tkz]
% Twój wektor wejœæ u = [Qk; Tzew; Fg]

Matrix_C = eye(3);
Matrix_D = zeros(3, 3);


Matrix_A = [
    -(cpw*Fg0 +Kcg)/Cvg,   Kcg/Cvg,           (cpw*Fg0)/Cvg;
     Kcg/Cvws,          -(Kcg + Kcw)/Cvws,     0;
     cpw*Fg0/Cvk,                 0,       -cpw*Fg0/Cvk,
];

Matrix_B = [
    0,                 Kcw/Cvws,                    0;
    0,                 0,            cpw*(Tkz0 - Tgp0)/Cvg;
    1/Cvk,             0,           -cpw*(Tkz0 - Tgp0)/Cvk
];

% 6. Zak³ócenie (teraz mo¿esz te¿ testowaæ zmianê Fg!)
dQk = 0.1 * QkN;
dTzew = 0;
dFg = 0; % Mo¿esz tu wstawiæ np. 0.1 * FgN

% 7. Symulacja (teraz skrypt tylko uruchamia model)
czas = 6000;
czas_skok = 500;
fprintf('Uruchamiam symulacjê NL vs LIN w Simulinku...\n');
[t] = sim(model, czas);

% 8. Rysowanie wykresów (dane bierzemy z workspace)
figure(1);
hold on; grid on;
title('Porównanie modelu Nieliniowego z Liniowym dla Twew');

% Wyjœcie z modelu Nieliniowego (czerwony)
% 'aTwew' to jest Twew_NL. Rysujemy odchy³kê od Twew0.
plot(t, aTwew - Twew0, 'r-', 'LineWidth', 2.5, 'DisplayName', 'Model Nieliniowy');

% Wyjœcie z modelu Liniowego (niebieski)
% Chcemy narysowaæ Twew, które jest w DRUGIEJ kolumnie aTwewLin
plot(t, TwewLIN(:, 2), 'b--', 'LineWidth', 2.0, 'DisplayName', 'Model Liniowy');

xlabel('Czas [s]');
ylabel('Odchy³ka temperatury \DeltaTwew [C]');
legend('Location', 'southeast');
hold off;
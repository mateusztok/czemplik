%aparam1.m					%parametry wspólne ró¿nych modeli
%generuje parametry zastêpcze budynku: Cvw=no*..., Cvg=no*
%---------------------------------------------
skala = 60;			%skala=60 -> sek->min 
%skala=1;			%skala=60 -> sek->min 
cpw = 4190;			%J/kg K, woda
row = 980;				%kg/m3, woda .... stopni (dla 100stop. row=958;)
cpp = 1000;			%J/kg K, powietrze
rop = 1.2;				%kg/m3, powietrze
cps = 1500;			%J/kg K, œciany
ros = 600;				%kg/m3, œciany

%parametry pomieszczen w budynku
no = 1;                                       %iloœæ odbiorników
a1d = 3;a1s=4;a1w=2.5;		%d³ug*szer*wys
a1grub = 0.10;						%grubosc scian
Aw = 2*(a1d+a1s)*a1w;		 %[m2] (powierzchnia przegród zewnêtrznych)
Vw = a1d*a1s*a1w;				%[m3] (kubatura pomieszczenia)
Vs = Aw*a1grub;					  %kubatura 4 œcian zewnêtrznych
Vg = 50/1000;                       %[l/1000=m3] (pojemnoœæ grzejnika)
Vk = Vg;                                 %pojemnoœæ kot³a
Vo =10/1000;						 %[l/1000=m3] (pojemnoœæ wymiennika]
Vu = Vo;

%wyznaczenie pojemoœci cieplnych, opóŸnieñ
Cvw = (no*Vw)*rop*cpp/skala;			%[J/K] (pojemnosc cieplna pomieszczenia)
Cvs = (no*Vs)*ros*cps/skala;
Cvws = (Cvw +Cvs) / 2;                  %zastêpcza pojemnoœæ pomieszczenia
Cvg = (no*Vg)*row*cpw/skala;		%[J/K] (pojemnosc cieplna grzejnika)
Cvk = (Vk)*row*cpw/skala;               %[J/K] (pojemnosc cieplna pieca)
Cvo = (Vo)*row*cpw/skala;               %[J/K] (pojemnosc cieplna wezla co)
Cvu = (Vu)*row*cpw/skala;               %[J/K] (pojemnosc cieplna wezla cwu)
To = 20*60/skala;                                %opóŸnienie 5min
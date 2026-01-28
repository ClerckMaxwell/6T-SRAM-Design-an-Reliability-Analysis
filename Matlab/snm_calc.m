clc; clear; close all;

% 1. CARICAMENTO E PREPARAZIONE DATI
nome = 'Vqreadax.txt';
opts = detectImportOptions(nome);
opts.VariableNamingRule = 'preserve';
opts.Delimiter = '\t'; 
data = readtable(nome, opts);

% Estraiamo i dati grezzi
Vin_raw = data{:, 1};     
Vout_raw = data{:, 2};   


% --- RIMOZIONE VALORI NON FINITI (NaN o Inf) ---
% Questo risolve l'errore griddedInterpolant
isOk = isfinite(Vin_raw) & isfinite(Vout_raw);
Vin_raw = Vin_raw(isOk);
Vout_raw = Vout_raw(isOk);

% RIMOZIONE DUPLICATI E ORDINAMENTO
[Vin, idx] = unique(Vin_raw);
Vout = Vout_raw(idx);

% Ora l'interpolazione non fallirà più
x_interp = linspace(min(Vin), max(Vin), 1000);
y_interp = interp1(Vin, Vout, x_interp, 'pchip');

% 2. GENERAZIONE MATEMATICA DELLA SECONDA CURVA E CALCOLO GEOMETRICO
% Curva 1: (x, y) -> y_interp
% Curva 2: (y, x) -> Inversa matematica

% Calcoliamo 'q' della retta y = x + q per ogni punto della Curva 1
q_curva1 = y_interp - x_interp;

% Definiamo un range di ricerca per q
q_range = linspace(min(q_curva1), max(q_curva1), 1000);
diagonali = zeros(size(q_range));
p1_save = zeros(length(q_range), 2);
p2_save = zeros(length(q_range), 2);

for k = 1:length(q_range)
    q_target = q_range(k);
    
    % Punto P1 su VTC1 (blu) dove y - x = q
    [~, idx1] = min(abs(q_curva1 - q_target));
    p1_save(k,:) = [x_interp(idx1), y_interp(idx1)];
    
    % Punto P2 su VTC2 (rossa) dove y - x = -q
    % Poiché VTC2 è lo specchio di VTC1 (x,y -> y,x), cerchiamo su VTC1 
    % il punto dove x - y = q (ovvero y - x = -q) e poi invertiamo le coordinate
    [~, idx2] = min(abs(q_curva1 - (-q_target)));
    p2_save(k,:) = [y_interp(idx2), x_interp(idx2)];
    
    % Lunghezza diagonale d = distanza euclidea tra P1 e P2
    diagonali(k) = sqrt(sum((p1_save(k,:) - p2_save(k,:)).^2));
end

% 3. IDENTIFICAZIONE MASSIMI NEI DUE LOBI
% Tagliamo i bordi (0.05V) per evitare che il massimo venga trovato agli angoli (0,1) o (1,0)
mask_L1 = q_range > 0.05; % Lobo superiore
mask_L2 = q_range < -0.05; % Lobo inferiore

if any(mask_L1) && any(mask_L2)
    [diag1, i1] = max(diagonali(mask_L1));
    p1_L1 = p1_save(mask_L1,:); p2_L1 = p2_save(mask_L1,:);
    
    [diag2, i2] = max(diagonali(mask_L2));
    p1_L2 = p1_save(mask_L2,:); p2_L2 = p2_save(mask_L2,:);

    % SNM = Lato del quadrato = Diagonale / sqrt(2)
    snm1 = diag1 / sqrt(2);
    snm2 = diag2 / sqrt(2);
    SNM_finale = min(snm1, snm2);
else
    error('Lobi non rilevati. Controllare i dati di ingresso.');
end

% 4. PLOT E DISEGNO QUADRATI
figure('Color', 'w');
plot(x_interp, y_interp, 'b', 'LineWidth', 2, 'DisplayName', 'VTC1'); hold on;
plot(y_interp, x_interp, 'r', 'LineWidth', 2, 'DisplayName', 'VTC2 (Invertita)');


% Disegno Quadrato Lobo 1
plot([p1_L1(i1,1) p1_L1(i1,1) p2_L1(i1,1) p2_L1(i1,1) p1_L1(i1,1)], ...
     [p1_L1(i1,2) p2_L1(i1,2) p2_L1(i1,2) p1_L1(i1,2) p1_L1(i1,2)], 'k', 'LineWidth', 1.2);

% Disegno Quadrato Lobo 2
plot([p1_L2(i2,1) p1_L2(i2,1) p2_L2(i2,1) p2_L2(i2,1) p1_L2(i2,1)], ...
     [p1_L2(i2,2) p2_L2(i2,2) p2_L2(i2,2) p1_L2(i2,2) p1_L2(i2,2)], 'k', 'LineWidth', 1.2);

axis square; grid on;
xlabel('V_Q [V]'); ylabel('V_{Qneg} [V]');
title(['SNM calcolato (Metodo Grafico): ', num2str(round(SNM_finale*1000)), ' mV']);
legend('Location', 'best');
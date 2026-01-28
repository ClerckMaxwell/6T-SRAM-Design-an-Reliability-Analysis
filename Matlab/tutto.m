%% ANALISI STATICA SRAM: HSNM vs RSNM
% Descrizione: Script per il calcolo e la visualizzazione del Static Noise Margin 
% in configurazione Hold e Read al variare di W e Beta Ratio.

clc; clear; close all;

%% --- 1. CONFIGURAZIONE E PARAMETRI ---
files = struct('hold', 'Vqholdp012.txt', 'read', 'Vqreadp012.txt');

% Definizione parametri geometrici (Step: 0.12u a 1.2u)
w_values = (0.12:0.01:1.2) * 1e-6; 
w_fixed  = 0.375 * 1e-6;           % Valore fisso per calcolo Beta Ratio
beta_values = w_fixed ./ w_values;

%% --- 2. ELABORAZIONE DATI ---
% fprintf('Inizio elaborazione file LTspice...\n');

snm_h_vec = processa_file_parametrico(files.hold);
snm_r_vec = processa_file_parametrico(files.read);

% Calcolo derivata per sensibilità (RSNM)
[w_der, ~, derivata_r] = calcola_derivata_snm(w_values, snm_r_vec);

% fprintf('Elaborazione completata.\n');

%% --- 3. VISUALIZZAZIONE RISULTATI ---
figure('Color', 'w');
plot(w_values*1e6, snm_h_vec*1000, '-o', 'LineWidth', 1.5, 'DisplayName', 'HSNM');
hold on;
plot(w_values*1e6, snm_r_vec*1000, '-s', 'LineWidth', 1.5, 'DisplayName', 'RSNM');
grid on;
xlabel('W_{n} [\mu m]');
ylabel('SNM [mV]');
title('HSNM vs RSNM');
legend;
figure('Color', 'w');
plot(beta_values, snm_h_vec*1000, '-o', 'LineWidth', 1.5, 'DisplayName', 'HSNM');
hold on;
plot(beta_values, snm_r_vec*1000, '-s', 'LineWidth', 1.5, 'DisplayName', 'RSNM');
grid on;
xlabel('\beta_{ratio}');
ylabel('SNM [mV]');
title('HSNM vs RSNM');
legend;
 % --- CALCOLO DERIVATA ---
[w_der, ~, derivata_r] = calcola_derivata_snm(w_values, snm_r_vec);
% --- PLOT DERIVATA ---
figure('Color', 'w', 'Name', 'Sensibilità SNM');
plot(w_der * 1e6, derivata_r * 1e-6, '-d', 'LineWidth', 2, 'Color', [0.85 0.33 0.1]);
grid on;
xlabel('W_{pd} [\mum]');
ylabel('d(RSNM) / dW_{pd} [V/\mum]');
title('Sensibilità della Stabilità (Derivata dell''RSNM)');
legend('Efficacia dell''incremento di W');
% 
% =========================================================================
% FUNZIONI LOCALI
% =========================================================================

function snm_vettore = processa_file_parametrico(filename)
    % Legge i dati da file .txt esportato da LTspice (formato RAW/Parametrico)
    fid = fopen(filename, 'r');
    if fid == -1, error('File %s non trovato.', filename); end
    
    tline = fgetl(fid);
    all_vin = []; all_vout = [];
    snm_vettore = [];
    
    while ischar(tline)
        if contains(tline, 'Step')
            if ~isempty(all_vin)
                snm_vettore(end+1) = calcola_snm_core(all_vin, all_vout);
            end
            all_vin = []; all_vout = []; 
        else
            data = sscanf(tline, '%f %f');
            if length(data) == 2
                all_vin(end+1) = data(1);
                all_vout(end+1) = data(2);
            end
        end
        tline = fgetl(fid);
    end
    
    % Gestione ultimo step
    if ~isempty(all_vin)
        snm_vettore(end+1) = calcola_snm_core(all_vin, all_vout);
    end
    fclose(fid);
end

function SNM_finale = calcola_snm_core(Vin, Vout)
    % Metodo del quadrato massimo inscritto nelle "Butterfly Curves"
    [Vin, idx] = unique(Vin);
    Vout = Vout(idx);
    
    x_interp = linspace(min(Vin), max(Vin), 1000);
    y_interp = interp1(Vin, Vout, x_interp, 'pchip');
    
    % Differenza per trovare la diagonale del quadrato
    q_curva1 = y_interp - x_interp;
    q_range = linspace(min(q_curva1), max(q_curva1), 200);
    diagonali = zeros(size(q_range));
    
    for k = 1:length(q_range)
        q_target = q_range(k);
        [~, idx1] = min(abs(q_curva1 - q_target));
        [~, idx2] = min(abs(q_curva1 - (-q_target)));
        
        p1 = [x_interp(idx1), y_interp(idx1)];
        p2 = [y_interp(idx2), x_interp(idx2)];
        diagonali(k) = sqrt(sum((p1 - p2).^2));
    end
    
    % Filtraggio lobi (margine di 50mV per stabilità numerica)
    mask_L1 = q_range > 0.05; 
    mask_L2 = q_range < -0.05;
    
    if any(mask_L1) && any(mask_L2)
        diag1 = max(diagonali(mask_L1));
        diag2 = max(diagonali(mask_L2));
        SNM_finale = min(diag1, diag2) / sqrt(2);
    else
        SNM_finale = 0;
    end
end

function [dW, dSNM, derivata] = calcola_derivata_snm(w_values, snm_vec)
    % Calcola la sensibilità locale del SNM rispetto a W
    derivata = diff(snm_vec) ./ diff(w_values);
    dW = w_values(1:end-1) + diff(w_values)/2;
    dSNM = derivata;
end
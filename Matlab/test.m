clc; clear; close all;

% --- CONFIGURAZIONE ---
filename = 'Vqwn05.txt'; 

% Definiamo il vettore W come da te richiesto
w_values = (0.12:0.01:1.2) * 1e-6; 

% --- APERTURA FILE E CICLO DI LETTURA ---
fid = fopen(filename, 'r');
if fid == -1, error('File non trovato. Controlla il nome del file .txt'); end

% fprintf('Generazione n figure in corso...\n');

current_vin = [];
current_vout = [];
step_count = 0;

while ~feof(fid)
    tline = fgetl(fid);
    
    % Se troviamo la riga "Step Information", processiamo lo step precedente
    if contains(tline, 'Step')
        if ~isempty(current_vin)
            step_count = step_count + 1;
            % Verifichiamo di non superare l'indice dei w_values definiti
            if step_count <= length(w_values)
                w_curr = w_values(step_count);
                disegna_figura_singola(current_vin, current_vout, step_count, w_curr);
            end
        end
        current_vin = []; current_vout = []; % Reset per il prossimo step
        continue;
    end
    
    % Lettura dati numerici
    data = sscanf(tline, '%f %f');
    if length(data) == 2
        current_vin(end+1) = data(1);
        current_vout(end+1) = data(2);
    end
end

% Elabora l'ultimo step del file
if ~isempty(current_vin)
    step_count = step_count + 1;
    if step_count <= length(w_values)
        w_curr = w_values(step_count);
        disegna_figura_singola(current_vin, current_vout, step_count, w_curr);
    end
end

fclose(fid);

% =========================================================
% FUNZIONE PER CREARE UNA FIGURA PER OGNI STEP
% =========================================================
function disegna_figura_singola(Vin, Vout, step_num, w_val)
    % 1. Pulizia e Interpolazione
    [Vin, idx] = unique(Vin);
    Vout = Vout(idx);
    x_int = linspace(min(Vin), max(Vin), 1000);
    y_int = interp1(Vin, Vout, x_int, 'pchip');
    
    % 2. Calcolo Geometrico
    q_curva1 = y_int - x_int;
    q_range = linspace(min(q_curva1), max(q_curva1), 200);
    
    diagonali = zeros(size(q_range));
    p1_save = zeros(length(q_range), 2);
    p2_save = zeros(length(q_range), 2);
    
    for k = 1:length(q_range)
        q_target = q_range(k);
        [~, idx1] = min(abs(q_curva1 - q_target));
        [~, idx2] = min(abs(q_curva1 - (-q_target)));
        
        p1_save(k,:) = [x_int(idx1), y_int(idx1)];
        p2_save(k,:) = [y_int(idx2), x_int(idx2)];
        diagonali(k) = sqrt(sum((p1_save(k,:) - p2_save(k,:)).^2));
    end
    
    % 3. Selezione Lobi (Taglio bordi 0.05V)
    mask_L1 = q_range > 0.05; 
    mask_L2 = q_range < -0.05;
    
    if any(mask_L1) && any(mask_L2)
        % Trova massimi per i due lobi
        [diag1, i1] = max(diagonali(mask_L1));
        p1_L1 = p1_save(mask_L1,:); p2_L1 = p2_save(mask_L1,:);
        
        [diag2, i2] = max(diagonali(mask_L2));
        p1_L2 = p1_save(mask_L2,:); p2_L2 = p2_save(mask_L2,:);
        
        snm = min(diag1, diag2) / sqrt(2);

        % 4. Creazione FIGURA
        figure('Name', sprintf('Step %d - W=%.2fu', step_num, w_val*1e6), 'Color', 'w');
        plot(x_int, y_int, 'b', 'LineWidth', 2); hold on;
        plot(y_int, x_int, 'r', 'LineWidth', 2);
        plot([0 1], [0 1], 'k:', 'HandleVisibility', 'off'); % Bisettrice
        
        % Disegno Quadrato Lobo 1
        plot([p1_L1(i1,1) p1_L1(i1,1) p2_L1(i1,1) p2_L1(i1,1) p1_L1(i1,1)], ...
             [p1_L1(i1,2) p2_L1(i1,2) p2_L1(i1,2) p1_L1(i1,2) p1_L1(i1,2)], 'k--', 'LineWidth', 1.2);
         
        % Disegno Quadrato Lobo 2
        plot([p1_L2(i2,1) p1_L2(i2,1) p2_L2(i2,1) p2_L2(i2,1) p1_L2(i2,1)], ...
             [p1_L2(i2,2) p2_L2(i2,2) p2_L2(i2,2) p1_L2(i2,2) p1_L2(i2,2)], 'k--', 'LineWidth', 1.2);
        
        axis square; grid on;
        xlabel('V_{in} [V]'); ylabel('V_{out} [V]');
        title(sprintf('SNM = %d mV', round(snm*1000)));
        
        % Opzionale: chiudi le figure se sono troppe per evitare crash
        % if mod(step_num, 10) == 0, pause(0.1); end 
    end
end
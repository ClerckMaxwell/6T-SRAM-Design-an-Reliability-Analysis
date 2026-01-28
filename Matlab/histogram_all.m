clc; clear; close all;

% --- CONFIGURAZIONE ---
filename = 'seevnick_read091.log'; 
nome_misura = 'rsnm_seevnick'; 
snm_limit = 0.060; 
num_run = 7000;
vdd_values = 0.9:0.1:1; 
num_vdd = length(vdd_values);

% --- ESTRAZIONE DATI ---
fid = fopen(filename, 'r');
if fid == -1, error('File non trovato'); end
raw_values = zeros(1,num_vdd*7000);
inizio_dati = false;
i = 1;
while ~feof(fid)
    tline = fgetl(fid);
    if contains(tline, ['Measurement: ', nome_misura])
        inizio_dati = true;
        fgetl(fid); 
        continue;
    end
    if inizio_dati
        data = sscanf(tline, '%f %f'); 
        if length(data) >= 2
            raw_values(i) = data(2);
            i=i+1;
        end
    end
end
fclose(fid);

% --- ORGANIZZAZIONE DATI ---
snm_all = raw_values ./ sqrt(2);
if length(snm_all) ~= num_run * num_vdd
    num_vdd = floor(length(snm_all) / num_run);
    snm_all = snm_all(1 : num_run * num_vdd);
end
snm_matrix = reshape(snm_all, [num_run, num_vdd]);

% --- GENERAZIONE FIGURE INDIVIDUALI ---
for i = 1:num_vdd
    snm_curr = snm_matrix(:, i);
    vdd_curr = vdd_values(i);
    
    % Calcoli statistici
    mu = mean(snm_curr);
    sigma = std(snm_curr);
    failed_count = sum(snm_curr <= snm_limit); % Numero di celle fallite
    yield = ((num_run - failed_count) / num_run) * 100;
    
    % Creazione figura
    figure('Color', 'w', 'Name', sprintf('Vdd %.1fV', vdd_curr));
    
    % Istogramma delle Occorrenze
    h = histogram(snm_curr * 1000, 50, 'EdgeColor', 'w', ...
        'FaceColor', [0.2 0.6 0.8], 'FaceAlpha', 0.8);
    hold on;
    
    % Linea di soglia (60mV)
    xl = xline(snm_limit * 1000, '--r', 'LineWidth', 2);
    
    % Titolo e Sottotitolo (con aggiunta celle fallite)
    title(['Distribuzione RSNM @ V_{DD} = ', num2str(vdd_curr), ' V'], 'FontSize', 12);
    subtitle_text = sprintf('\\mu = %.2f mV  |  \\sigma = %.2f mV  |  Yield = %.2f%%  |  Fallite = %d/%d', ...
             mu*1000, sigma*1000, yield, failed_count, num_run);
    subtitle(subtitle_text, 'FontSize', 10, 'FontWeight', 'bold');
    
    grid on;
    xlabel('RSNM [mV]');
    ylabel('Numero di Occorrenze');
    
    % Legenda (spostata a destra per visibilità)
    legend(xl, {'Soglia di fallimento (60mV)'}, 'Location', 'northeast');
    
    hold off;
end
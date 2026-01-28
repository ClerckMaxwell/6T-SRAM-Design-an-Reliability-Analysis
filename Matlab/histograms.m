clc; clear; close all;

% --- CONFIGURAZIONE ---
filename = 'seevnick_read.log'; 
nome_misura = 'rsnm_seevnick'; % Deve essere uguale al nome nel .meas di Spice
snm_limit = 0.060; 

% --- ESTRAZIONE DATI INTELLIGENTE ---
fid = fopen(filename, 'r');
if fid == -1, error('File non trovato'); end

snm_values = [];
inizio_dati = false;

while ~feof(fid)
    tline = fgetl(fid);
    
    % 1. Cerchiamo la riga che segna l'inizio della tabella dei risultati
    % Di solito è "Measurement: nome_misura"
    if contains(tline, ['Measurement: ', nome_misura])
        inizio_dati = true;
        fgetl(fid); % Saltiamo la riga degli header (step, MAX, ecc.)
        continue;
    end
    
    % 2. Se siamo nella sezione dati, estraiamo i numeri
    if inizio_dati
        % Cerchiamo di leggere lo step e il valore MAX
        % Formato atteso: "   1    0.214559    -0.707    0.707"
        data = sscanf(tline, '%f %f'); 
        if length(data) >= 2
            snm_values(end+1) = data(2);
        elseif isempty(tline) || contains(tline, 'Measurement:')
            % Se incontriamo una riga vuota o un'altra misura, fermiamoci
            if ~isempty(snm_values), break; end
        end
    end
end
fclose(fid);

if isempty(snm_values)
    error('Non ho trovato dati per la misura "%s". Controlla il nome nel log.', nome_misura);
end
snm_values = snm_values./sqrt(2);
% --- ANALISI E PLOT ---
mu = mean(snm_values);
sigma = std(snm_values);
yield = (sum(snm_values > snm_limit) / length(snm_values)) * 100;

figure('Color', 'w');
h = histogram(snm_values *1000, 50, 'EdgeColor', 'w');
hold on;
xline(snm_limit *1000 , 'r--', 'LineWidth', 2, 'Label', 'Soglia Fallimento');
grid on;
title(['Analisi Monte Carlo V_{DD} = V']);
xlabel('HSNM [mV]'); ylabel('Occorrenze');
subtitle(sprintf('Yield: %.2f%% | Media: %.1f mV | \\sigma: %.1f mV', yield, mu*1000, sigma*1000));
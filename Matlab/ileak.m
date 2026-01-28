clc; clear; close all;

% --- CONFIGURAZIONE MULTI-FILE ---
file_list = {'ileak0102.log', 'ileak0304.log', 'ileak0507.log', 'ileak0810.log'};
vdd_per_file = {0.1:0.1:0.2, 0.3:0.1:0.4, 0.5:0.1:0.7, 0.8:0.1:1.0};
misure = {'ileak_pu', 'ileak_pd', 'ileak_ax'}; 
num_run = 7000; 

% Contenitori globali per medie e deviazioni standard
all_vdd = [];
all_mean_pu = []; all_std_pu = [];
all_mean_pd = []; all_std_pd = [];
all_mean_ax = []; all_std_ax = [];

fprintf('--- INIZIO ELABORAZIONE FILE ---\n');

% --- 1. CICLO SUI FILE ---
for f = 1:length(file_list)
    filename = file_list{f};
    vdd_values = vdd_per_file{f};
    num_vdd = length(vdd_values);
    total_per_measure = num_run * num_vdd;
    
    current_file_matrices = struct();
    
    % --- 2. ESTRAZIONE DATI DAL LOG CORRENTE ---
    for m = 1:length(misure)
        fid = fopen(filename, 'r');
        if fid == -1
            fprintf('Attenzione: File %s non trovato. Salto...\n', filename);
            continue; 
        end
        
        target = ['Measurement: ', misure{m}];
        temp_data = [];
        trovato = false;
        
        while ~feof(fid)
            tline = fgetl(fid);
            if contains(tline, target)
                trovato = true;
                fgetl(fid); 
                continue;
            end
            if trovato
                if isempty(strtrim(tline)) || contains(tline, 'Measurement:'), break; end
                valori_riga = textscan(tline, '%*f %f %*f %*f'); 
                if ~isempty(valori_riga{1}), temp_data(end+1) = abs(valori_riga{1}); end
                if length(temp_data) == total_per_measure, break; end
            end
        end
        fclose(fid);
        
        if length(temp_data) == total_per_measure
            current_file_matrices.(misure{m}) = reshape(temp_data, [num_vdd, num_run])';
        end
    end
    
    % --- 3. ELABORAZIONE STATISTICA E PLOT ---
    if isfield(current_file_matrices, 'ileak_pu')
        for v_idx = 1:num_vdd
            curr_v = vdd_values(v_idx);
            all_vdd = [all_vdd, curr_v];
            
            % Creazione figura per ogni Vdd
            figure('Color', 'w', 'Name', sprintf('Statistiche Leakage @ %.1fV', curr_v), ...
                   'Position', [50, 50, 1300, 450]);
            
            for m = 1:length(misure)
                subplot(1, 3, m);
                data = current_file_matrices.(misure{m})(:, v_idx);
                mu = mean(data);
                sig = std(data);
                
                % Salvataggio dati globali
                if m == 1
                    all_mean_pu = [all_mean_pu, mu]; all_std_pu = [all_std_pu, sig];
                elseif m == 2
                    all_mean_pd = [all_mean_pd, mu]; all_std_pd = [all_std_pd, sig];
                elseif m == 3
                    all_mean_ax = [all_mean_ax, mu]; all_std_ax = [all_std_ax, sig];
                end
                
                % Plot Istogramma
                h = histogram(data * 1e9, 50, 'EdgeColor', 'w', 'FaceAlpha', 0.6);
                if m == 1, h.FaceColor = [0.2 0.6 0.4]; end 
                if m == 2, h.FaceColor = [0.2 0.4 0.7]; end 
                if m == 3, h.FaceColor = [0.8 0.4 0.2]; end 
                
                grid on;
                title(sprintf('%s @ %.1f V', strrep(misure{m},'_','\_'), curr_v));
                xlabel('Corrente [nA]'); ylabel('Occorrenze');
                subtitle(sprintf('\\mu = %.2e nA\n\\sigma = %.2e nA', mu*1e9, sig*1e9), 'FontWeight', 'bold');
            end
        end
    end
end

% --- 4. CALCOLI FINALI ---
all_mean_tot = all_mean_pu + all_mean_pd + all_mean_ax;
all_p_tot = all_mean_tot .* all_vdd;

% --- 5. GRAFICI DI SCALING ---
% Correnti
figure('Color', 'w', 'Name', 'Master Current Scaling');
semilogy(all_vdd, all_mean_pu*1e9, '-o', 'LineWidth', 1.8); hold on;
semilogy(all_vdd, all_mean_pd*1e9, '-s', 'LineWidth', 1.8);
semilogy(all_vdd, all_mean_ax*1e9, '-^', 'LineWidth', 1.8);
semilogy(all_vdd, all_mean_tot*1e9, '--k', 'LineWidth', 2);
grid on; xlabel('V_{DD} [V]'); ylabel('Corrente Media [nA]');
title('Correnti di Leakage Medie (0.1V - 1.0V)');
legend('I_{PU}', 'I_{PD}', 'I_{AX}', 'I_{TOT}', 'Location', 'best');

% Potenza
figure('Color', 'w', 'Name', 'Master Power Scaling');
semilogy(all_vdd, all_p_tot*1e9, '-ro', 'LineWidth', 2, 'MarkerFaceColor', 'r');
grid on; xlabel('V_{DD} [V]'); ylabel('Potenza Media [nW]');
title('Potenza di Leakage Media Totale');

% --- 6. TABELLA RIASSUNTIVA (COMMAND WINDOW) ---
fprintf('\n--- TABELLA RIASSUNTIVA COMPLETA ---\n');
fprintf('%-6s | %-16s | %-16s | %-16s | %-10s\n', 'Vdd[V]', 'Ipu[nA] avg±std', 'Ipd[nA] avg±std', 'Iax[nA] avg±std', 'Ptot[nW]');
fprintf('------------------------------------------------------------------------------------\n');
for i = 1:length(all_vdd)
    fprintf(' %.1f    | %6.2f ± %5.2f | %6.2f ± %5.2f | %6.2f ± %5.2f | %8.2f\n', ...
        all_vdd(i), all_mean_pu(i)*1e9, all_std_pu(i)*1e9, ...
        all_mean_pd(i)*1e9, all_std_pd(i)*1e9, ...
        all_mean_ax(i)*1e9, all_std_ax(i)*1e9, all_p_tot(i)*1e9);
end

% --- 7. CODICE LATEX ---
fprintf('\n--- CODICE PER TABELLA LATEX ---\n\n');
fprintf('\\begin{table}[H]\n\\centering\n\\small\n');
fprintf('\\begin{tabular}{lccccr}\n\\toprule\n');
fprintf('$V_{DD}$ [V] & $I_{PU}$ [nA] & $I_{PD}$ [nA] & $I_{AX}$ [nA] & $I_{TOT}$ [nA] & $P_{TOT}$ [nW] \\\\ \\midrule\n');
for i = 1:length(all_vdd)
    fprintf('%.1f & %.2f $\\pm$ %.2f & %.2f $\\pm$ %.2f & %.2f $\\pm$ %.2f & %.2f & %.2f \\\\ \n', ...
        all_vdd(i), all_mean_pu(i)*1e9, all_std_pu(i)*1e9, ...
        all_mean_pd(i)*1e9, all_std_pd(i)*1e9, ...
        all_mean_ax(i)*1e9, all_std_ax(i)*1e9, ...
        all_mean_tot(i)*1e9, all_p_tot(i)*1e9);
end
fprintf('\\bottomrule\n\\end{tabular}\n\\caption{Sintesi statistica del leakage al variare della tensione.}\n\\end{table}\n');
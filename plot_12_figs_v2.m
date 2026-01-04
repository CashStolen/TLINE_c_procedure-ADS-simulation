% plot_12_figs_v2
% 12 figures total:
%   3 rise times (200ps, 2ns, 200ns) × 4 terminations (none, src_series, load_parallel, both)
% Each figure overlays: Vi (source), Vmid, Vo (load)
%
% Improvement vs plot_12_figs:
%   - Auto x-axis window computed from (tr, Td) so you don't get a long flat tail.
%   - Still saves PNGs.
%
% Assumes assignment parameters: length=0.1m, vp=2e8 m/s  ->  Td = 0.5 ns
% If you changed these in C, update Td_ns below.

function plot_12_figs_v2()
    riseLabels = {'200ps','2ns','200ns'};
    terms = {'none','src_series','load_parallel','both'};

    % Assignment one-way delay (ns)
    Td_ns = 0.5;

    % Convert rise label to tr in ns
    tr_map = containers.Map;
    tr_map('200ps') = 0.2;    % ns
    tr_map('2ns')   = 2.0;    % ns
    tr_map('200ns') = 200.0;  % ns

    % How much time to show:
    % show reflections (multiple bounces) AND show most of the rise.
    % end = 10*Td + 4*tr, with a little padding, but never exceed the data length.
    pad = 1.2;

    % Warn if expected files are missing
    missing = {};
    for r = 1:numel(riseLabels)
        for t = 1:numel(terms)
            fn = sprintf('tl_%s_tr%s.csv', terms{t}, riseLabels{r});
            if ~isfile(fn)
                missing{end+1} = fn; %#ok<AGROW>
            end
        end
    end
    if ~isempty(missing)
        fprintf('Warning: %d expected CSV files are missing.\n', numel(missing));
        fprintf('Missing examples (up to 10):\n');
        for k = 1:min(10, numel(missing))
            fprintf('  %s\n', missing{k});
        end
        fprintf('Continuing anyway (will plot what exists)...\n\n');
    end

    for r = 1:numel(riseLabels)
        trLab = riseLabels{r};
        if ~isKey(tr_map, trLab)
            error('Unknown rise label: %s', trLab);
        end
        tr_ns = tr_map(trLab);

        for t = 1:numel(terms)
            term = terms{t};
            fname = sprintf('tl_%s_tr%s.csv', term, trLab);
            if ~isfile(fname)
                continue;
            end

            T = readtable(fname);
            T = sortrows(T, 't_ns');

            time_ns = T.t_ns;
            Vi   = T.V_source;
            Vmid = T.V_mid;
            Vo   = T.V_load;

            % Compute a nice x-window, but don't go beyond the available data
            t_data_end = max(time_ns);
            t_show_end = pad * (10*Td_ns + 4*tr_ns);

            % For very fast edges, ensure at least a few ns are shown
            t_show_end = max(t_show_end, 8.0);

            t_show_end = min(t_show_end, t_data_end);
            xl = [0, t_show_end];

            figTitle = sprintf('tr=%s | term=%s', trLab, term);
            f = figure('Name', figTitle, 'NumberTitle', 'off');
            plot(time_ns, Vi, time_ns, Vmid, time_ns, Vo);
            grid on;
            xlim(xl);

            % Optional: keep y-range tidy (comment out if you dislike)
            ymin = min([Vi; Vmid; Vo]);
            ymax = max([Vi; Vmid; Vo]);
            yr = ymax - ymin;
            if yr < 1e-6
                ylim([ymin-0.1, ymax+0.1]);
            else
                ylim([ymin-0.1*yr, ymax+0.1*yr]);
            end

            xlabel('Time (ns)');
            ylabel('Voltage (V)');
            title(strrep(figTitle, '_', '\_'));
            legend('V_i (source)', 'V_{mid}', 'V_o (load)', 'Location', 'best');

            outpng = sprintf('fig_tr%s_%s.png', trLab, term);
            saveas(f, outpng);
        end
    end

    disp('Done: generated up to 12 figures (and saved PNG files).');
end

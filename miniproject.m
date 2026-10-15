
%% DSP MINI-PROJECT
% Interpolation for Smooth Reconstruction of Sensor Signals
% Experiments: Method comparison, factor selection, pre-filtering,
% noise robustness, aliasing, and real audio data.
% MATLAB R2019b or later
% Required toolbox: Signal Processing Toolbox

clc;
clear;
close all;

%% 1. CREATE PROJECT FOLDERS

if ~exist('results', 'dir')
    mkdir('results');
end

if ~exist('data', 'dir')
    mkdir('data');
end

fprintf('Project folder: %s\n', pwd);

methods = {'zero-order hold', 'linear', 'cubic spline', ...
           'FFT (sinc)', 'polyphase FIR'};

%% 2. GENERATE SYNTHETIC SENSOR SIGNAL

fs = 1000;
T = 2;
rng(0);

t = (0:1/fs:T-1/fs)';

x = sin(2*pi*5*t) ...
    + 0.5*sin(2*pi*20*t) ...
    + 0.25*sin(2*pi*50*t) ...
    + 0.05*randn(size(t));

N = numel(x);

% Save the generated dataset
writematrix([t x], fullfile(pwd, 'data', 'synthetic_sensor.csv'));

fprintf('\nSynthetic sensor dataset saved successfully.\n');

%% EXPERIMENT 1: COMPARE INTERPOLATION METHODS

M = 4;

xd = downsample_sig(x, M, true);

rows = cell(numel(methods), 4);
recon = struct();

for k = 1:numel(methods)

    xr = reconstruct(xd, M, N, methods{k});

    [a, b] = trim_edges(x, xr, 50);

    rows(k,:) = {methods{k}, ...
                 m_rmse(a,b), ...
                 m_mae(a,b), ...
                 m_corr(a,b)};

    recon.(matlab.lang.makeValidName(methods{k})) = xr;
end

T1 = cell2table(rows, ...
    'VariableNames', {'Method','RMSE','MAE','Correlation'});

disp('EXPERIMENT 1: INTERPOLATION METHOD COMPARISON');
disp(T1);

writetable(T1, fullfile('results', 'exp1_methods.csv'));

% Plot reconstruction
figure('Position', [100 100 900 450]);

idx = 101:300;

plot(t(idx), x(idx), 'k', 'LineWidth', 1.8);
hold on;
grid on;

% Actual retained low-rate samples
sampleIdx = idx(mod(idx-1, M) == 0);

plot(t(sampleIdx), x(sampleIdx), 'ko', ...
    'MarkerSize', 5, 'MarkerFaceColor', 'k');

plot(t(idx), recon.linear(idx), '--', 'LineWidth', 1.3);
plot(t(idx), recon.cubicSpline(idx), '--', 'LineWidth', 1.3);
plot(t(idx), recon.polyphaseFIR(idx), '--', 'LineWidth', 1.3);

xlabel('Time (s)');
ylabel('Amplitude');
title(sprintf('Signal Reconstruction Comparison (M = %d)', M));

legend('Original Signal', 'Low-Rate Samples', ...
       'Linear', 'Cubic Spline', 'Polyphase FIR', ...
       'Location', 'best');

print(gcf, fullfile('results', 'fig1_reconstruction.png'), ...
      '-dpng', '-r200');

%% EXPERIMENT 2: EFFECT OF DOWNSAMPLING FACTOR

Ms = [2 3 4 5 8 10 15 20];

R2 = zeros(numel(Ms), numel(methods));

for i = 1:numel(Ms)

    xd = downsample_sig(x, Ms(i), true);

    for k = 1:numel(methods)

        xr = reconstruct(xd, Ms(i), N, methods{k});

        [a, b] = trim_edges(x, xr, 60);

        R2(i,k) = m_rmse(a,b);
    end
end

T2 = array2table(R2, ...
    'VariableNames', matlab.lang.makeValidName(methods));

T2.M = Ms(:);
T2 = movevars(T2, 'M', 'Before', 1);

disp('EXPERIMENT 2: RMSE VS DOWNSAMPLING FACTOR');
disp(T2);

writetable(T2, fullfile('results', 'exp2_factor.csv'));

figure('Position', [100 100 800 450]);

semilogy(Ms, R2, 'o-', 'LineWidth', 1.4);
grid on;
hold on;

xline(10, 'r:', '50 Hz Nyquist limit', 'LineWidth', 1.5);

xlabel('Downsampling Factor M');
ylabel('RMSE (log scale)');
title('Reconstruction Error vs Downsampling Factor');

legend([methods, {'50 Hz Nyquist limit'}], ...
       'Location', 'best');

print(gcf, fullfile('results', 'fig2_factor.png'), ...
      '-dpng', '-r200');

% Find the largest tested factor meeting the error tolerance
tol = 0.1;

fprintf('\nLargest tested M with RMSE < %.2f:\n', tol);

for k = 1:numel(methods)

    ok = Ms(R2(:,k) < tol);

    if isempty(ok)
        fprintf('%-20s : none\n', methods{k});
    else
        fprintf('%-20s : M = %d\n', methods{k}, max(ok));
    end
end

%% EXPERIMENT 3: EFFECT OF ANTI-ALIASING PRE-FILTER

rows = {};

for Mv = [4 8 12]

    for pf = [true false]

        xd = downsample_sig(x, Mv, pf);

        % Linear, cubic spline and polyphase FIR
        for k = [2 3 5]

            xr = reconstruct(xd, Mv, N, methods{k});

            [a, b] = trim_edges(x, xr, 60);

            if pf
                lab = 'With pre-filter';
            else
                lab = 'Without pre-filter';
            end

            rows(end+1,:) = {Mv, lab, methods{k}, ...
                m_rmse(a,b), m_mae(a,b), m_corr(a,b)}; %#ok<SAGROW>
        end
    end
end

T3 = cell2table(rows, ...
    'VariableNames', {'M','Prefilter','Method','RMSE','MAE','Corr'});

disp('EXPERIMENT 3: PRE-FILTER EFFECT');
disp(T3);

writetable(T3, fullfile('results', 'exp3_prefilter.csv'));

%% EXPERIMENT 4: NOISE ROBUSTNESS

rows = {};

for nz = [0 0.05 0.1 0.3]

    rng(1);

    xn = sin(2*pi*5*t) ...
       + 0.5*sin(2*pi*20*t) ...
       + 0.25*sin(2*pi*50*t) ...
       + nz*randn(size(t));

    xd = downsample_sig(xn, 4, true);

    for k = [2 3 5]

        xr = reconstruct(xd, 4, N, methods{k});

        [a, b] = trim_edges(xn, xr, 50);

        rows(end+1,:) = {nz, methods{k}, m_rmse(a,b)}; %#ok<SAGROW>
    end
end

T4 = cell2table(rows, ...
    'VariableNames', {'NoiseStd','Method','RMSE'});

disp('EXPERIMENT 4: NOISE ROBUSTNESS');
disp(T4);

writetable(T4, fullfile('results', 'exp4_noise.csv'));

%% EXPERIMENT 5: FREQUENCY SPECTRUM AND ALIASING

Mv = 12;

xd_pf = downsample_sig(x, Mv, true);
xd_np = downsample_sig(x, Mv, false);

fsd = fs / Mv;

figure('Position', [100 100 900 400]);

subplot(1,2,1);
plot_spec(xd_pf, fsd);
title('With Anti-Aliasing Pre-Filter');

subplot(1,2,2);
plot_spec(xd_np, fsd);
title('Without Pre-Filter');

sgtitle('Effect of Pre-Filtering on the Downsampled Spectrum');

print(gcf, fullfile('results', 'fig3_aliasing.png'), ...
      '-dpng', '-r200');

%% EXPERIMENT 6: REAL DATA USING LIBRISPEECH AUDIO

audioFile = fullfile('data', 'librispeech_sample.flac');

if exist(audioFile, 'file')

    [xs, fss] = audioread(audioFile);

    % Convert stereo audio to mono
    if size(xs, 2) > 1
        xs = mean(xs, 2);
    end

    % Use up to two seconds of audio
    xs = xs(1:min(size(xs,1), 2*fss));
    Ns = numel(xs);

    rows = {};

    for Mv = [2 4 8]

        xd = downsample_sig(xs, Mv, true);

        for k = 1:numel(methods)

            xr = reconstruct(xd, Mv, Ns, methods{k});

            edge = min(300, floor((Ns-1)/4));

            [a, b] = trim_edges(xs, xr, edge);

            rows(end+1,:) = {Mv, methods{k}, ...
                m_rmse(a,b), m_mae(a,b), m_corr(a,b)}; %#ok<SAGROW>
        end
    end

    T5 = cell2table(rows, ...
        'VariableNames', {'M','Method','RMSE','MAE','Corr'});

    disp('EXPERIMENT 6: REAL AUDIO DATA');
    disp(T5);

    writetable(T5, fullfile('results', 'exp6_librispeech.csv'));

else

    disp(['LibriSpeech audio file not found. ' ...
          'Skipping real-data experiment.']);
    disp(['To run it, save a FLAC audio file as: ' audioFile]);

end

%% FINISH

fprintf('\nAll available experiments completed.\n');
fprintf('Check the data and results folders.\n');

%% LOCAL FUNCTIONS

function xd = downsample_sig(x, M, prefilter)

    x = x(:);

    if prefilter
        % Low-pass anti-aliasing filter followed by downsampling
        xd = decimate(x, M, 'fir');
    else
        % Direct downsampling without anti-aliasing filtering
        xd = x(1:M:end);
    end

    xd = xd(:);
end

function xr = reconstruct(xd, M, N, method)

    xd = xd(:);

    n = numel(xd);

    % Original sample positions on the high-rate grid
    td = 1 + (0:n-1)' * M;

    tq = (1:N)';

    switch method

        case 'zero-order hold'

            xr = interp1(td, xd, tq, 'previous', 'extrap');

        case 'linear'

            xr = interp1(td, xd, tq, 'linear', 'extrap');

        case 'cubic spline'

            xr = interp1(td, xd, tq, 'spline', 'extrap');

        case 'FFT (sinc)'

            % Fourier interpolation; output is adjusted below
            xr = interpft(xd, n*M);

        case 'polyphase FIR'

            % Polyphase FIR interpolation
            xr = resample(xd, M, 1);

        otherwise

            error('Unknown interpolation method: %s', method);
    end

    xr = xr(:);

    % Ensure the output contains exactly N samples
    if numel(xr) < N
        xr(end+1:N, 1) = xr(end);
    end

    xr = xr(1:N);
end

function [a, b] = trim_edges(x, xr, e)

    x = x(:);
    xr = xr(:);

    n = min(numel(x), numel(xr));

    % Keep the edge trimming within the signal bounds
    e = min(e, floor((n-1)/4));

    a = x(e+1:n-e);
    b = xr(e+1:n-e);
end

function v = m_rmse(a, b)

    v = sqrt(mean((a-b).^2));
end

function v = m_mae(a, b)

    v = mean(abs(a-b));
end

function v = m_corr(a, b)

    c = corrcoef(a, b);

    v = c(1,2);
end

function plot_spec(x, fs)

    x = x(:);
    L = numel(x);

    X = abs(fft(x)) / L;
    f = (0:L-1)' * fs / L;

    half = 1:floor(L/2);

    plot(f(half), X(half), 'LineWidth', 1.3);
    grid on;

    xlabel('Frequency (Hz)');
    ylabel('Magnitude');
end

%% FF_DISC_RAND_VAR_STATS Statistics for a Discrete Random Variable
%    Model simulation generates discrete random variables, to analyze, need
%    to calculate various statistics
%
%    Statistics include: mean, standard deviation, min, max,  percentiles,
%    proportion of outcomes held by x percentiles, etc.
%
%    * ST_VAR_NAME string name of the variable (choice/outcome) been
%    analyzed
%    * AR_CHOICE_UNIQUE_SORTED array 1 by N elements in the sample space of
%    the discrete random variable ordered. Unique consumption values
%    ordered. Unique asset choices ordered. etc.
%    * AR_CHOICE_PROB array 1 by N probability mass function associated
%    with each element of the sorted ar_choice_unique_sorted
%    * AR_FL_PERCENTILES array 1 by M some vector of percentiles (0 to 100)
%    that we would like to compute based on the discrete random variable's
%    probability mass function and x values.
%
%    DS_STATS_MAP = FF_DISC_RAND_VAR_STATS() computes distributational
%    statistics for a default binomial random variable.
%
%    DS_STATS_MAP = FF_DISC_RAND_VAR_STATS(ST_VAR_NAME,
%    AR_CHOICE_UNIQUE_SORTED, AR_CHOICE_PROB) computes distributional
%    statistics for the given discrete random variable with the provided
%    probabilities and name.
%
%    See also FX_DISC_RAND_VAR_STATS, FF_DISC_RAND_VAR_GINI
%

%%
function [ds_stats_map] = ff_disc_rand_var_stats(varargin)
%% Stats Show
%
% * $\mu_Y = E(Y) = \sum_{y} p(Y=y) \cdot y$
% * $\sigma_Y = \sqrt{ \sum_{y} p(Y=y) \cdot \left( y - \mu_y \right)^2}$
% * $p(y=0)$
% * $p(y=\min(y))$
% * $p(y=\max(y))$
% * percentiles: $min_{y} \left\{ P(Y \le y) - percentile \mid P(Y \le y) \ge percentile \right\}$
% * fraction of outcome held by up to percentiles: $E(Y<y)/E(Y)$
%

%% Parse Main Inputs and Set Defaults

% default percentiles to compute
ar_fl_percentiles = [0.1 1 5:5:25 35:15:65 75:5:95 99 99.9];
bl_display_drvstats = false;

% parse inputs
if (~isempty(varargin))

    if (length(varargin) == 3)
        [st_var_name, ar_choice_unique_sorted, ar_choice_prob] = varargin{:};
    elseif (length(varargin) == 4)
        [st_var_name, ar_choice_unique_sorted, ar_choice_prob, ...
            ar_fl_percentiles] = varargin{:};
    elseif (length(varargin) == 5)
        [st_var_name, ar_choice_unique_sorted, ar_choice_prob, ...
            ar_fl_percentiles, bl_display_drvstats] = varargin{:};
    end

else

    fl_binom_n = 30;
    fl_binom_p = 0.3;
    ar_binom_x = 0:1:fl_binom_n;

    % f(x)
    ar_choice_prob = binopdf(ar_binom_x, fl_binom_n, fl_binom_p);
    % x
    ar_choice_unique_sorted = ar_binom_x;

    % display
    st_var_name = 'binom';

    % display
    bl_display_drvstats = true;

end

%% *f(y), f(c), f(a)*: Compute Scalar Statistics for outcomes
% Compute these outcomes:
%
% * mean: $\mu_y = \sum_{y} p(Y=y) \cdot y$
% * sd: $\sigma_y = \sqrt{ \sum_{y} p(Y=y) \cdot \left( y - \mu_y
% \right)^2}$
% * prob(outcome=0): $p(y=0)$
% * prob(outcome=max(outcome)): $p(y=\max(y))$
%

% Mean of discrete random variable
fl_choice_mean = ar_choice_prob*ar_choice_unique_sorted';
fl_choice_sum_unweighted = sum(ar_choice_unique_sorted);

% SD of discrete random variable
fl_choice_sd = sqrt(ar_choice_prob*((ar_choice_unique_sorted'-fl_choice_mean).^2));
% Coef of Variation of discrete random variable
fl_choice_coefofvar = fl_choice_sd/fl_choice_mean;
% min of y from policy function, p(y) might be 0
fl_choice_min = min(ar_choice_unique_sorted);
% max of y from policy function, p(y) might be 0
fl_choice_max = max(ar_choice_unique_sorted);
% prob(outcome=min(outcome)), fraction of people not saving for example
fl_choice_prob_min = sum(ar_choice_prob(ar_choice_unique_sorted == min(ar_choice_unique_sorted)));
% prob(outcome=0), fraction of people not saving for example
fl_choice_prob_zero = sum(ar_choice_prob(ar_choice_unique_sorted == 0));
% prob(outcome<0), fraction of people borrowing
fl_choice_prob_below_zero = sum(ar_choice_prob(ar_choice_unique_sorted < 0));
% prob(outcome>0), fraction of people borrowing
fl_choice_prob_above_zero = sum(ar_choice_prob(ar_choice_unique_sorted > 0));
% prob(outcome=max(outcome)), fraction of people saving up to max of grid,
% in principle if this is large, need to increase grid max value
fl_choice_prob_max = sum(ar_choice_prob(ar_choice_unique_sorted == max(ar_choice_unique_sorted)));

%% *f(y), f(c), f(a)*: Compute Distributional Statistics for outcomes
% Compute these outcomes:
%
% * percentiles: $min_{y} \left\{ P(Y \le y) - percentile \mid P(Y \le y) \ge percentile \right\}$
% * share of outcome (consumption/assets) held by households below this
% percentile: $E(Y<y)/E(Y)$. Note that this statistics could exceed 1.
% Suppose the average level is negative, but there are both positive and
% negative $y$, then the statistics will first be what fraction of overall
% debt is held by up to this percentile, then it will exceed 100 percent,
% as we move towards the final $y<0$ values, then as it goes through the
% $Y>0$ values, we will move back to 100 percent.
%

% cumulative share of total outcome held by up to this level for outcomes
% like fraction of asset held by lowest highest fractions: E(X<x)
ar_choice_unique_cumufrac = cumsum(ar_choice_prob.*ar_choice_unique_sorted)/fl_choice_mean;

% Key Percentile Statistics
ar_choice_prob_cumsum = cumsum(ar_choice_prob)*100;

% ar_choice_percentiles: percentiles for the outcome variable
ar_choice_percentiles = zeros(size(ar_fl_percentiles));

% fraction of aggregate outcome variable held up to this percentile
ar_choice_perc_fracheld = zeros(size(ar_fl_percentiles));

for it_percentile = 1:length(ar_fl_percentiles)
    % get percentile of interest
    fl_cur_percentile = ar_fl_percentiles(it_percentile);
    % in the cumu prob array, first element higher or equal to current
    % percentile
    it_first_higher_idx = (cumsum(ar_choice_prob_cumsum >= fl_cur_percentile) == 1);
    % assign percentile
    fl_percentile = ar_choice_unique_sorted(it_first_higher_idx);
    fl_cumfrac = ar_choice_unique_cumufrac(it_first_higher_idx);
    if (length(fl_percentile) > 1)
        fl_percentile = fl_percentile(1);
        fl_cumfrac = fl_cumfrac(1);
    end
    ar_choice_percentiles(it_percentile) = fl_percentile;
    % asset held by up to this percentile
    ar_choice_perc_fracheld(it_percentile) = fl_cumfrac;
end

%% Call Gini function
[fl_gini_index] = ff_disc_rand_var_gini(ar_choice_unique_sorted, ar_choice_prob);

%% Collect Statistics

ds_stats_map = containers.Map('KeyType','char', 'ValueType','any');

% scalar statistics
ds_stats_map('fl_choice_mean') = fl_choice_mean;
ds_stats_map('fl_choice_sd') = fl_choice_sd;
ds_stats_map('fl_choice_coefofvar') = fl_choice_coefofvar;
ds_stats_map('fl_choice_min') = fl_choice_min;
ds_stats_map('fl_choice_max') = fl_choice_max;
ds_stats_map('fl_choice_sum_unweighted') = fl_choice_sum_unweighted;
ds_stats_map('fl_choice_prob_zero') = fl_choice_prob_zero;
ds_stats_map('fl_choice_prob_below_zero') = fl_choice_prob_below_zero;
ds_stats_map('fl_choice_prob_above_zero') = fl_choice_prob_above_zero;
ds_stats_map('fl_choice_prob_min') = fl_choice_prob_min;
ds_stats_map('fl_choice_prob_max') = fl_choice_prob_max;
ds_stats_map('fl_gini_index') = fl_gini_index;

% distributional array stats
ds_stats_map('ar_fl_percentiles') = ar_fl_percentiles;
ds_stats_map('ar_choice_percentiles') = ar_choice_percentiles;
ds_stats_map('ar_choice_perc_fracheld') = ar_choice_perc_fracheld;

%% Display
if (bl_display_drvstats)

    disp('----------------------------------------');
    disp('xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx');
    disp(['Summary Statistics for: ' char(st_var_name)])
    disp('xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx');
    disp('----------------------------------------');

    disp('fl_choice_mean');
    disp(fl_choice_mean);
    disp('fl_choice_sd');
    disp(fl_choice_sd);
    disp('fl_choice_coefofvar');
    disp(fl_choice_coefofvar);

    disp('fl_choice_prob_zero');
    disp(fl_choice_prob_zero);
    disp('fl_choice_prob_below_zero');
    disp(fl_choice_prob_below_zero);
    disp('fl_choice_prob_above_zero');
    disp(fl_choice_prob_above_zero);
    disp('fl_choice_prob_max');
    disp(fl_choice_prob_max);
    disp('fl_gini_index');
    disp(fl_gini_index);

    disp('tb_disc_cumu');
    tb_disc_cumu = table(ar_choice_unique_sorted', ar_choice_prob', ...
                         ar_choice_prob_cumsum', ar_choice_unique_cumufrac');
    st_var_name = [char(st_var_name) ' discrete val'];
    st_var_name_p = [char(st_var_name) ' prob mass'];
    tb_disc_cumu.Properties.VariableNames = ...
        matlab.lang.makeValidName([st_var_name, st_var_name_p, "CDF", "cumsum frac"]);
    disp(head(tb_disc_cumu,10));
    disp(tail(tb_disc_cumu,10));

    disp('tb_prob_drv');
    tb_prob_drv = table(ar_fl_percentiles', ar_choice_percentiles', ar_choice_perc_fracheld');
    st_var_name = [char(st_var_name) ' percentile values'];
    tb_prob_drv.Properties.VariableNames = matlab.lang.makeValidName(["percentiles", st_var_name, "frac of sum held below this percentile"]);
    disp(tb_prob_drv);

%     fft_container_map_display(ds_stats_map)
end
end

function [ALPHAK, P_O, P_C] = mALPHAK(CODES, CATEGORIES, SCALE)
% Calculate Krippendorff's alpha coefficient using generalized formulas
%   [ALPHAK, P_O, P_C] = mALPHAK(CODES, CATEGORIES, SCALE)
%
%   CODES should be a numerical matrix where each row corresponds to a
%   single item of measurement (e.g., participant or question) and each
%   column corresponds to a single source of measurement (i.e., rater).
%   This function can handle any number of raters and values.
%
%   CATEGORIES is an optional parameter specifying the possible categories
%   as a numerical vector. If this variable is not specified, then the
%   possible categories are inferred from the CODES matrix. This can
%   underestimate reliability if all possible categories aren't used.
%
%   SCALE is an optional parameter specifying the scale of measurement:
%   -Use 'nominal' for unordered categories (default)
%   -Use 'ordinal' for ordered categories of unequal size
%   -Use 'interval' for ordered categories with equal spacing
%   -Use 'ratio' for ordered categories with equal spacing and a zero point
%
%   ALPHAK is a chance-corrected index of agreement.
%
%   P_O is the percent observed agreement (from 0.000 to 1.000).
%
%   P_C is the estimated percent chance agreement (from 0.000 to 1.000).
%
%   Example usage: [ALPHAK, P_O, P_C] = mALPHAK(smiledata,[0,1],'nominal');
%   
%   (c) Jeffrey M Girard, 2016
%   
%   References:
%
%   Krippendorff, K. (1970). Estimating the reliability, systematic error
%   and random error of interval data. Educational and Psychological
%   Measurement, 30(1), 61�70.
%   
%   Krippendorff, K. (1980). Content analysis: An introduction to its
%   methodology. Newbury Park, CA: Sage Publications.
%
%   Gwet, K. L. (2014). Handbook of inter-rater reliability: The definitive
%   guide to measuring the extent of agreement among raters (4th ed.).
%   Gaithersburg, MD: Advanced Analytics.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Remove items that do not have codes from at least two raters
CODES(sum(isfinite(CODES),2)<2,:) = [];
%% Calculate basic descriptives
[n,r] = size(CODES);
x = unique(CODES);
x(~isfinite(x)) = [];
if nargin < 2
    CATEGORIES = x;
    SCALE = 'nominal';
elseif nargin < 3
    SCALE = 'nominal';
end
if isempty(CATEGORIES)
    CATEGORIES = x;
end
CATEGORIES = unique(CATEGORIES(:));
q = length(CATEGORIES);
%% Output basic descriptives
fprintf('Number of items = %d\n',n);
fprintf('Number of raters = %d\n',r);
fprintf('Possible categories = %s\n',mat2str(CATEGORIES));
fprintf('Observed categories = %s\n',mat2str(x));
fprintf('Scale of measurement = %s\n',SCALE);
%% Check for valid data from multiple raters
if n < 1
    ALPHAK = NaN;
    fprintf('\nERROR: At least 1 item is required.\n')
    return;
end
if r < 2
    ALPHAK = NaN;
    fprintf('\nERROR: At least 2 raters are required.\n');
    return;
end
if any(ismember(x,CATEGORIES)==0)
    ALPHAK = NaN;
    fprintf('ERROR: Categories were observed in CODES that were not included in CATEGORIES.\n');
    return;
end
%% Calculate weights based on data scale
weights = nan(q);
for k = 1:q
    for l = 1:q
        switch SCALE
            case 'nominal'
                weights = eye(q);
            case 'ordinal'
                if k==l
                    weights(k,l) = 1;
                else
                    M_kl = nchoosek((max(k,l) - min(k,l) + 1),2);
                    M_1q = nchoosek((max(1,q) - min(1,q) + 1),2);
                    weights(k,l) = 1 - (M_kl / M_1q);
                end
            case 'interval'
                if k==l
                    weights(k,l) = 1;
                else
                    dist = abs(CATEGORIES(k) - CATEGORIES(l));
                    maxdist = max(CATEGORIES) - min(CATEGORIES);
                    weights(k,l) = 1 - (dist / maxdist);
                end
            case 'ratio'
                weights(k,l) = 1 - (((CATEGORIES(k) - CATEGORIES(l)) / (CATEGORIES(k) + CATEGORIES(l)))^2) / (((max(CATEGORIES) - min(CATEGORIES)) / (max(CATEGORIES) + min(CATEGORIES)))^2);
                if CATEGORIES(k)==0 && CATEGORIES(l)==0, weights(k,l) = 1; end
            otherwise
                error('Scale must be nominal, ordinal, interval, or ratio');
        end
    end
end
%% Create n-by-q matrix (rater counts in item by category matrix)
nxq = zeros(n,q);
for k = 1:q
    codes_k = CODES == CATEGORIES(k);
    nxq(:,k) = codes_k * ones(r,1);
end
nxq_w = transpose(weights * transpose(nxq));
%% Calculate percent observed agreement
r_i = nxq * ones(q,1);
nxq = nxq(r_i >= 2,:);
nxq_w = nxq_w(r_i >= 2,:);
r_i = r_i(r_i >= 2);
rbar_i = mean(r_i);
nprime = size(nxq,1);
epsilon = 1 / sum(r_i);
observed = (nxq .* (nxq_w - 1)) * ones(q,1);
possible = rbar_i .* (r_i - 1);
P_O = (1 - epsilon) .* sum(observed ./ (possible)) ./ nprime + epsilon;
%% Calculate percent chance agreement
pihat = transpose(repmat(1/n,1,n) * (nxq ./ (r_i * ones(1,q))));
P_C = sum(sum(weights .* (pihat * transpose(pihat))));
%% Calculate reliability point estimate
ALPHAK = (P_O - P_C) / (1 - P_C);
%% Output reliability and variance components
fprintf('Percent observed agreement = %.3f\n',P_O);
fprintf('Percent chance agreement = %.3f\n',P_C);
fprintf('\nKrippendorff''s alpha coefficient = %.3f\n',ALPHAK);

end
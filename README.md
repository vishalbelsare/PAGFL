
<!-- README.md is generated from README.Rmd. Please edit that file -->

# PAGFL

<!-- badges: start -->

[![License:
MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![R-CMD-check](https://github.com/Paul-Haimerl/PAGFL/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/Paul-Haimerl/PAGFL/actions/workflows/R-CMD-check.yaml)
<!-- badges: end -->

In panel data analysis, the presence of unobservable group structures is
a common challenge. Disregarding group-level heterogeneity by assuming a
fully homogeneous panel can introduce bias. Conversely, estimating
individual coefficients for each cross-sectional unit is inefficient and
may lead to high uncertainty.

Mehrabani ([2023](https://doi.org/10.1016/j.jeconom.2022.12.002))
introduces the pairwise adaptive group fused Lasso (PAGFL), a fast
methodology to simultaneously identify latent group structures and
estimate group-specific coefficients.

The `PAGFL` package makes it easy to use this powerful procedure.

## Installation

You can install the development version of `PAGFL` from
[GitHub](https://github.com/) with:

``` r
# install.packages("devtools")
devtools::install_github("Paul-Haimerl/PAGFL")
```

After installation, attach the package as usual:

``` r
library(PAGFL)
```

## Data

The `PAGFL` packages includes a function that automatically simulates a
panel with a group structure:

``` r
# Simulate a simple panel with three distinct groups and two exogenous explanatory variables
set.seed(2)
sim <- sim_DGP(N = 50, n_periods = 80, p = 2, n_groups = 3)
y <- sim$y
X <- sim$X
```

`sim_DGP` also nests, among other, all DGPs employed in the simulation
study of Mehrabani
([2023](https://doi.org/10.1016/j.jeconom.2022.12.002), sec. 6). I refer
to the documentation of `sim_DGP` or Mehrabani
([2023](https://doi.org/10.1016/j.jeconom.2022.12.002), sec. 6) for more
details.

## Applying PAGFL

To execute the PAGFL procedure, simply pass the dependent and
independent variables, number of time periods and a penalization
parameter $\lambda$.

``` r
estim <- PAGFL(y = y, X = X, n_periods = 80, lambda = 5)
print(estim)
#> $IC
#> [1] 1.075838
#> 
#> $lambda
#> [1] 5
#> 
#> $alpha_hat
#>            [,1]      [,2]
#> [1,] -1.2512141 -1.357402
#> [2,]  0.5772769  1.790624
#> 
#> $K_hat
#> [1] 2
#> 
#> $groups_hat
#>  [1] 1 1 1 2 1 1 2 2 2 1 1 2 2 2 2 2 2 2 2 1 2 2 2 1 2 2 2 1 2 1 1 2 2 2 2 2 2 2
#> [39] 1 2 1 2 2 2 2 2 1 1 1 2
#> 
#> $iter
#> [1] 43
#> 
#> $convergence
#> [1] TRUE
```

Selecting a $\lambda$ value a priori can be tricky. Therefore, we
suggest iterating over a comprehensive range of candidate values. To
specify a suitable grid, create a logarithmic sequence ranging from 0 to
a penalty parameter that induces a fully homogeneous model. The
resulting $\lambda$ grid vector can be simply passed in place of any
specific value and a BIC IC selects the best fitting parameter.

``` r
lambda_set <- exp(log(10) * seq(log10(1e-4), log10(10), length.out = 10))
estim_set <- PAGFL(y = y, X = X, n_periods = 80, lambda = lambda_set)
print(estim_set)
#> $IC
#> [1] 1.049193
#> 
#> $lambda
#> [1] 0.05994843
#> 
#> $alpha_hat
#>            [,1]      [,2]
#> [1,] -1.2512141 -1.357402
#> [2,]  0.8342522  1.796975
#> [3,]  0.2989770  1.781551
#> 
#> $K_hat
#> [1] 3
#> 
#> $groups_hat
#>  [1] 1 1 1 2 1 1 3 2 3 1 1 2 2 2 2 3 2 3 2 1 3 3 3 1 2 2 3 1 2 1 1 3 3 2 2 2 2 3
#> [39] 1 2 1 3 3 3 2 3 1 1 1 3
#> 
#> $iter
#> [1] 792
#> 
#> $convergence
#> [1] TRUE
```

When, as above, the specific estimation method is left unspecified,
`PAGFL` defaults to penalized Least Squares (*PLS*) (Mehrabani,
[2023](https://doi.org/10.1016/j.jeconom.2022.12.002), sec. 2.2). *PLS*
is very efficient, but requires weakly exogenous regressors. However,
even endogenous predictors can be accounted for by employing a penalized
Generalized Method of Moments (*PGMM*) routine in combination with
exogenous instruments $Z$.

Lets specify a slightly more elaborate endogenous panel data set and
apply *PGMM*.

``` r
# Generate a panel where the predictors X correlate with the cross-sectional innovation, but can be instrumented with q = 3 variables in Z
sim_endo <- sim_DGP(N = 50, n_periods = 80, p = 2, n_groups = 3, q = 3)
y_endo <- sim_endo$y
X_endo <- sim_endo$X
Z <- sim_endo$Z

# Note that a method PGMM and the instrument matrix Z needs to be supplied
estim_endo <- PAGFL(y = y, X = X, n_periods = 80, lambda = 0.05, method = 'PGMM', Z = Z)
print(estim_endo)
#> $IC
#> [1] 9.027659
#> 
#> $lambda
#> [1] 0.05
#> 
#> $alpha_hat
#>           [,1]      [,2]
#> [1,] 0.5111912 0.3557388
#> 
#> $K_hat
#> [1] 1
#> 
#> $groups_hat
#>  [1] 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1
#> [39] 1 1 1 1 1 1 1 1 1 1 1 1
#> 
#> $iter
#> [1] 222
#> 
#> $convergence
#> [1] TRUE
```

Furthermore, `PAGFL` lets you select a minimum group size, toggle a
Split-panel Jackknife bias correction and adjust a list of additional
setting. Visit the documentation of `PAGFL` for more information.

## References

Mehrabani, A. (2023). Estimation and identification of latent group
structures in panel data. *Journal of Econometrics*, 235(2), 1464-1482.
DOI:
[10.1016/j.jeconom.2022.12.002](https://doi.org/10.1016/j.jeconom.2022.12.002)

#' Grouped Time-varying Panel Data Model
#'
#' @description Estimate a time-varying panel data model subject to an observed group structure. Coefficient functions are homogeneous within groups but heterogeneous across groups.
#' Time-varying coefficient functions are approximated as polynomial B-splines. The function supports both static and dynamic panel data models.
#'
#' @param formula a formula object describing the model to be estimated.
#' @param data a \code{data.frame} or \code{matrix} holding a panel data set. If no \code{index} variables are provided, the panel must be balanced and ordered in the long format \eqn{\bold{Y}=(Y_1^\prime, \dots, Y_N^\prime)^\prime}, \eqn{Y_i = (Y_{i1}, \dots, Y_{iT})^\prime} with \eqn{Y_{it} = (y_{it}, \bold{x}_{it}^\prime)^\prime}. Conversely, if \code{data} is not ordered or not balanced, \code{data} must include two index variables that declare the cross-sectional unit \eqn{i} and the time period \eqn{t} of each observation.
#' @param groups a numerical or character vector of length \eqn{N} that indicates the group membership of each cross-sectional unit \eqn{i}.
#' @param index a character vector holding two strings. The first string denotes the name of the index variable identifying the cross-sectional unit \eqn{i}, and the second string represents the name of the variable declaring the time period \eqn{t}. The data is automatically sorted according to the variables in \code{index}, which may produce errors when the time index is a character variable. In case of a balanced panel data set that is ordered in the long format, \code{index} can be left empty if the the number of time periods \code{n_periods} is supplied.
#' @param n_periods the number of observed time periods \eqn{T}. If an \code{index} character vector is passed, this argument can be left empty. Default is \code{Null}.
#' @param d the polynomial degree of the B-splines. Default is 3.
#' @param M the number of interior knots of the B-splines. If left unspecified, the default heuristic \eqn{M = \text{floor}((NT)^{\frac{1}{7}} - \log(p))} is used, following Haimerl et al. (2025). Note that \eqn{M} does not include the boundary knots and the entire sequence of knots is of length \eqn{M + d + 1}.
#' @param const_coef a character vector containing the variable names of explanatory variables that enter with time-constant coefficients.
#' @param rho the tuning parameter balancing the fitness and penalty terms in the IC. If left unspecified, the heuristic \eqn{\rho = 0.07 \frac{\log(NT)}{\sqrt{NT}}} of Haimerl et al. (2025) is used. We recommend the default.
#' @param verbose logical. If \code{TRUE}, helpful warning messages are shown. Default is \code{TRUE}.
#' @param parallel logical. If \code{TRUE}, certain operations are parallelized across multiple cores. Default is \code{TRUE}.
#' @param ... ellipsis
#'
#' @details
#' Consider the time-varying panel data model
#' \deqn{y_{it} = \gamma_i^0 + \bold{\beta}^{0\prime}_{i} (t/T) \bold{x}_{it} + \epsilon_{it}, \quad i = 1, \dots, N, \; t = 1, \dots, T,}
#' where \eqn{y_{it}} is the scalar dependent variable, \eqn{\gamma_i^0} is an individual fixed effect, \eqn{\bold{x}_{it}} is a \eqn{p \times 1} vector of explanatory variables, and \eqn{\epsilon_{it}} is a zero mean error.
#' The \eqn{p}-dimensional coefficient vector \eqn{\bold{\beta}_{i}^0 (t/T)} contains smooth functions of time and follows the observed group pattern
#' \deqn{\bold{\beta}_i^0 \left(\frac{t}{T} \right) = \sum_{k = 1}^K \bold{\alpha}_k^0 \left( \frac{t}{T} \right) \bold{1} \{i \in G_k \},}
#' with \eqn{\cup_{k = 1}^K G_k = \{1, \dots, N\}}, \eqn{G_k \cap G_j = \emptyset} for any \eqn{k \neq j},  \eqn{k,j = 1, \dots, K}. The group structure \eqn{G_1, \dots, G_K} is reflected in \code{groups}.
#'
#' The time-varying coefficient functions in \eqn{\bold{\alpha}_k (t/T)} and, in turn, \eqn{\bold{\beta}_i (t/T)} are estimated as polynomial B-splines. To this end, let \eqn{\bold{b}(v)} denote a \eqn{M + d +1} vector of polynomial basis functions with the polynomial degree \eqn{d} and \eqn{M} interior knots.
#' \eqn{\bold{\alpha}_k^0 (t/T)} is approximated by forming linear combinations of the basis functions \eqn{\bold{\alpha}_k^0 (t/T) \approx \bold{\Xi}_k^{0 \prime} \bold{b} (t/T)}, where \eqn{\bold{\Xi}_i^{0}} is a group-specific \eqn{(M + d + 1) \times p} matrix of spline control points.
#'
#' To estimate \eqn{\bold{\Xi}_k^{0}}, we project the explanatory variables onto the spline basis system, resulting in the \eqn{(M + d + 1)p \times 1} regressor vector \eqn{\bold{z}_{it} = \bold{x}_{it} \otimes \bold{b}(v)}. Subsequently, the DGP can be reformulated as
#' \deqn{y_{it} = \gamma_i^0 + \bold{\pi}_{i}^{0 \prime} \bold{z}_{it} + u_{it},}
#' where \eqn{\bold{\pi}_i^0 = \text{vec}(\bold{\Pi}_i^0)} and \eqn{\bold{\Xi}_k^0 = \bold{\Pi}_i^0} if \eqn{i \in G_k}. \eqn{u_{it} = \epsilon_{it} + \eta_{it}} collects the idiosyncratic \eqn{\epsilon_{it}} and the sieve approximation error \eqn{\eta_{it}}. Then, we obtain \eqn{\hat{\bold{\xi}}_k = \text{vec}( \hat{\bold{\Xi}}_k)} by
#' \deqn{\hat{\xi}_k = \left( \sum_{i \in G_k} \sum_{t = 1}^T \tilde{\bold{z}}_{it} \tilde{\bold{z}}_{it}^\prime \right)^{-1} \sum_{i \in G_k} \sum_{t = 1}^T \tilde{\bold{z}}_{it} \tilde{y}_{it},}
#' with \eqn{\tilde{a}_{it} = a_{it} - T^{-1} \sum_{t = 1}^T a_{it}}, \eqn{a = \{y, \bold{z}\}} to concentrate out the fixed effect \eqn{\gamma_i^0} (within-transformation). Lastly, \eqn{\hat{\bold{\alpha}}_k (t/T) = \hat{\bold{\Xi}}_k^{\prime} \bold{b} (t/T)}. We refer to Haimerl et al. (2025, sec. 2) for more details.
#'
#' In case of an unbalanced panel data set, the earliest and latest available observations per group define the start and end-points of the interval on which the group-specific time-varying coefficients are defined.
#'
#' @examples
#' # Simulate a time-varying panel with a trend and a group pattern
#' set.seed(1)
#' sim <- sim_tv_DGP(N = 10, n_periods = 50, intercept = TRUE, p = 2)
#' df <- data.frame(y = c(sim$y), X = sim$X)
#' groups <- sim$groups
#'
#' # Estimate the time-varying grouped panel data model
#' estim <- grouped_tv_plm(y ~ ., data = df, n_periods = 50, groups = groups)
#' summary(estim)
#'
#' @references
#' Haimerl, P., Smeekes, S., & Wilms, I. (2025). Estimation of latent group structures in time-varying panel data models. *arXiv preprint arXiv:2503.23165*. \doi{10.48550/arXiv.2503.23165}.
#'
#' @author Paul Haimerl
#'
#' @return An object of class \code{tv_gplm} holding
#' \item{\code{model}}{a \code{data.frame} containing the dependent and explanatory variables as well as cross-sectional and time indices,}
#' \item{\code{coefficients}}{let \eqn{p^{(1)}} denote the number of time-varying and \eqn{p^{(2)}} the number of time constant coefficients. A \code{list} holding (i) a \eqn{T \times p^{(1)} \times K} array of the group-specific functional coefficients and (ii) a \eqn{K \times p^{(2)}} matrix of time-constant estimates.}
#' \item{\code{groups}}{a \code{list} containing (i) the total number of groups \eqn{K} and (ii) a vector of group memberships \eqn{G = (g_1, \dots, g_N)}, where \eqn{g_i = k} if \eqn{i} is part of group \eqn{k},}
#' \item{\code{residuals}}{a vector of residuals of the demeaned model,}
#' \item{\code{fitted}}{a vector of fitted values of the demeaned model,}
#' \item{\code{args}}{a \code{list} of additional arguments,}
#' \item{\code{IC}}{a \code{list} containing (i) the value of the IC and (ii) the \emph{MSE},}
#' \item{\code{call}}{the function call.}
#'
#' An object of class \code{tv_gplm} has \code{print}, \code{summary}, \code{fitted}, \code{residuals}, \code{formula}, \code{df.residual}, and \code{coef} S3 methods.
#' @export
grouped_tv_plm <- function(formula, data, groups, index = NULL, n_periods = NULL, d = 3, M = floor(length(y)^(1 / 7) - log(p)),
                           const_coef = NULL, rho = .04 * log(N * n_periods) / sqrt(N * n_periods), verbose = TRUE, parallel = TRUE, ...) {
  #------------------------------#
  #### Preliminaries          ####
  #------------------------------#

  formula <- stats::as.formula(formula)
  prelim_checks(formula, data, index = index, n_periods = n_periods, const_coef = const_coef, verbose = verbose)
  # Construct a vector of the dependent variable and a regressor matrix
  data <- as.data.frame(data)
  if (any(all.vars(formula[[3]]) == ".")) {
    data <- stats::na.omit(data)
  } else {
    data <- data[stats::complete.cases(data[, c(index, all.vars(formula))]), ]
  }
  if (!is.null(index)) data <- data[order(data[, index[1]], data[, index[2]]), ]
  if (any(all.vars(formula[[3]]) == ".")) {
    if (!is.null(index)) {
      data_temp <- data[, !(colnames(data) %in% index)]
      if (NCOL(data) == 3) {
        data_temp <- as.data.frame(data_temp)
        colnames(data_temp) <- colnames(data)[!(colnames(data) %in% index)]
      }
    } else {
      data_temp <- data
    }
    X <- stats::model.matrix(formula, data_temp)
    rm(data_temp)
    intercept_indicator <- "1"
  } else {
    X <- stats::model.matrix(formula, data)
    intercept_indicator <- ifelse(attr(stats::terms(formula), "intercept") == 1, "1", "-1")
  }
  # Remove second intercepts if present
  sd_vec <- apply(as.matrix(X[, !(colnames(X) %in% "(Intercept)")]), 2, stats::sd)
  sd_vec_ind <- sd_vec != 0
  if (intercept_indicator == "1") sd_vec_ind <- c(TRUE, sd_vec_ind)
  regressor_names <- colnames(X)[sd_vec_ind]
  # Pull the regressors
  X <- as.matrix(X[, sd_vec_ind])
  colnames(X) <- regressor_names
  # Pull the outcome
  y <- as.matrix(data[[all.vars(formula[[2]])]])
  # Build the final data set
  model_data <- as.data.frame(cbind(c(y), X))
  colnames(model_data)[1] <- all.vars(formula[[2]])
  # Check constant coefficients
  if (!all(const_coef %in% regressor_names)) {
    stop(paste(const_coef[!const_coef %in% regressor_names], collapse = ", "), " not part of the formula\n")
  }
  regressor_names <- regressor_names[!(regressor_names %in% const_coef)]

  # Extract or produce index variables
  if (!is.null(index)) {
    i_index_labs <- data[, index[1]]
    i_index <- as.integer(factor(i_index_labs))
    t_index_labs <- data[, index[2]]
    t_index <- as.integer(factor(t_index_labs))
    n_periods <- length(unique(t_index))
    N <- length(unique(i_index))
    model_data <- cbind(model_data, data[, index[1]], data[, index[2]])
    colnames(model_data)[(ncol(model_data) - 1):ncol(model_data)] <- index
  } else {
    N <- NROW(y) / n_periods
    if (round(N) != N) stop("Either `n_periods` is incorrect or an unbalanced panel data set is passed without supplying `index`\n")
    t_index <- t_index_labs <- rep(1:n_periods, N)
    i_index <- i_index_labs <- rep(1:N, each = n_periods)
    model_data$i_index <- i_index
    model_data$t_index <- t_index
    index <- c("i_index", "t_index")
  }
  coef_t_index <- unique(t_index_labs)[order(unique(t_index))]
  coef_rownames <- as.character(coef_t_index)
  if (is.character(coef_t_index)) coef_t_index <- as.numeric(factor(coef_t_index))

  # Prepare constant coefficients
  if (!is.null(const_coef)) {
    X_const <- as.matrix(X[, const_coef])
    X <- as.matrix(X[, !(colnames(X) %in% const_coef)])
    p_const <- ncol(X_const)
  } else {
    X_const <- matrix()
    p_const <- 0
  }
  p <- ncol(X)
  M <- floor(max(M, 1))
  d <- floor(d)

  second_checks(y = y, X = X, p = p, verbose = verbose, dyn = TRUE, d = d, M = M, rho = rho)
  if (length(groups) != N) stop("`groups` must have the length N")

  # Get the group structure
  n_groups <- length(unique(groups))
  groups_index <- as.integer(factor(groups))

  #------------------------------#
  #### Estimate               ####
  #------------------------------#

  out <- tv_pagfl_oracle_routine(
    y = y, X = X, X_const = X_const, groups = groups_index, d = d, M = M, i_index = i_index, t_index = t_index, N = N, p_const = p_const, rho = rho, parallel = parallel
  )
  # Estimate fixed effects
  fe_vec <- getFE(y = y, i_index = i_index, N = N, method = "PLS")

  #------------------------------#
  #### Output                 ####
  #------------------------------#

  out <- tv_pagfl_output(
    out = out, fe_vec = fe_vec, p = p, p_const = p_const, n_periods = n_periods, d = d, M = M, coef_rownames = coef_rownames,
    regressor_names = regressor_names, const_coef = const_coef, index = index, i_index_labs = i_index_labs, i_index = i_index,
    t_index = t_index, model_data = model_data
  )
  out <- out[names(out) != "convergence"]
  out$IC <- out$IC[names(out$IC) != "lambda"]
  names(groups) <- unique(i_index_labs)
  out$groups$groups <- groups
  # List with additional arguments
  out$args <- list(
    formula = formula, labs = list(i = i_index_labs, t = t_index_labs, index = index), d = d, M = M, rho = rho
  )
  out$call <- match.call()
  class(out) <- "tv_gplm"
  return(out)
}

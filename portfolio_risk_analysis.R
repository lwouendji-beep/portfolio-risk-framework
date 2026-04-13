# =========================
# Portfolio VaR & Stress Testing Framework
# Version 1
# Assets:
# - TotalEnergies
# - Euro Stoxx 50
# - Euro Govt Bonds
# - Gold
# =========================

# ---- 1. Packages ----
library(quantmod)
library(PerformanceAnalytics)
library(tidyverse)
library(xts)
library(ggplot2)
library(tidyr)

# ---- 2. Download price data ----
# Yahoo tickers can vary, so check these if needed
tickers <- c("TTE", "UIM1.AS", "IEGA.AS", "GLD")

start_date <- as.Date("2021-01-01")
end_date <- as.Date("2026-03-01")

getSymbols(tickers, src = "yahoo", from = start_date, to = end_date)

# ---- 3. Extract adjusted close prices ----
prices <- na.omit(merge(
  Ad(TTE),
  Ad(UIM1.AS),
  Ad(IEGA.AS),
  Ad(GLD)
))

colnames(prices) <- c("TotalEnergies", "UBSEuroStoxx50", "EuroGovBond", "Gold")

# ---- 4. Compute daily returns ----
returns <- na.omit(Return.calculate(prices, method = "log"))

# ---- 5. Set portfolio weights ----
weights <- c(0.25, 0.25, 0.25, 0.25)

# Portfolio returns
portfolio_returns <- Return.portfolio(returns, weights = weights, rebalance_on = NA)
colnames(portfolio_returns) <- "Portfolio"

# ---- 6. Summary stats ----
summary_stats <- data.frame(
  Asset = colnames(returns),
  Mean = apply(returns, 2, mean),
  Volatility = apply(returns, 2, sd)
)

print(summary_stats)

# ---- 7. Correlation matrix ----
corr_matrix <- cor(returns)
print(corr_matrix)

corr_df <- as.data.frame(as.table(corr_matrix))
colnames(corr_df) <- c("Var1", "Var2", "value")

ggplot(corr_df, aes(Var1, Var2, fill = value)) +
  geom_tile() +
  scale_fill_gradient2(low = "red", mid = "white", high = "darkgreen", midpoint = 0) +
  theme_minimal() +
  labs(title = "Correlation Matrix", x = "", y = "")

# ---- 8. VaR and CVaR ----
# Historical VaR / CVaR
hist_var_95 <- VaR(portfolio_returns, p = 0.95, method = "historical")
hist_cvar_95 <- ES(portfolio_returns, p = 0.95, method = "historical")

# Parametric VaR
param_var_95 <- VaR(portfolio_returns, p = 0.95, method = "gaussian")

print(hist_var_95)
print(hist_cvar_95)
print(param_var_95)

# ---- 9. Rolling VaR chart ----
rolling_var <- rollapply(
  portfolio_returns,
  width = 60,
  FUN = function(x) as.numeric(VaR(x, p = 0.95, method = "historical")),
  by.column = FALSE,
  align = "right"
)

rolling_var_df <- data.frame(
  Date = index(rolling_var),
  RollingVaR = coredata(rolling_var)
)

ggplot(rolling_var_df, aes(x = Date, y = RollingVaR)) +
  geom_line(color = "darkred") +
  theme_minimal() +
  labs(title = "60-Day Rolling Historical VaR (95%)", y = "VaR", x = "")

# ---- 10. Asset contribution proxy ----
# Simple risk contribution proxy using volatility contribution
asset_vol <- apply(returns, 2, sd)
risk_contrib_proxy <- weights * asset_vol
risk_contrib_df <- data.frame(
  Asset = names(risk_contrib_proxy),
  Contribution = risk_contrib_proxy / sum(risk_contrib_proxy)
)

ggplot(risk_contrib_df, aes(x = Asset, y = Contribution, fill = Asset)) +
  geom_col() +
  theme_minimal() +
  labs(title = "Proxy Risk Contribution by Asset", y = "Share of Risk", x = "")

# ---- 11. Stress scenarios ----
stress_scenarios <- data.frame(
  Scenario = c("Equity Crash", "Rate Shock", "Energy Drop"),
  TotalEnergies = c(-0.15, -0.03, -0.20),
  EuroStoxx50   = c(-0.20, -0.05, -0.08),
  EuroGovBond   = c( 0.03, -0.06,  0.01),
  Gold          = c( 0.08, -0.02,  0.04)
)

stress_scenarios$PortfolioImpact <-
  weights[1] * stress_scenarios$TotalEnergies +
  weights[2] * stress_scenarios$EuroStoxx50 +
  weights[3] * stress_scenarios$EuroGovBond +
  weights[4] * stress_scenarios$Gold

print(stress_scenarios)

ggplot(stress_scenarios, aes(x = Scenario, y = PortfolioImpact, fill = Scenario)) +
  geom_col() +
  theme_minimal() +
  labs(title = "Portfolio Impact Under Stress Scenarios", y = "Portfolio Return", x = "")

# ---- 12. Reduce exposure test ----
# Reduce TotalEnergies from 25% to 10%, reallocate to bonds and gold
new_weights <- c(0.10, 0.25, 0.35, 0.30)

new_portfolio_returns <- Return.portfolio(returns, weights = new_weights, rebalance_on = NA)
colnames(new_portfolio_returns) <- "RebalancedPortfolio"

old_hist_var <- VaR(portfolio_returns, p = 0.95, method = "historical")
new_hist_var <- VaR(new_portfolio_returns, p = 0.95, method = "historical")

old_hist_cvar <- ES(portfolio_returns, p = 0.95, method = "historical")
new_hist_cvar <- ES(new_portfolio_returns, p = 0.95, method = "historical")

comparison <- data.frame(
  Metric = c("Historical VaR 95%", "Historical CVaR 95%"),
  Original = c(as.numeric(old_hist_var), as.numeric(old_hist_cvar)),
  Rebalanced = c(as.numeric(new_hist_var), as.numeric(new_hist_cvar))
)

print(comparison)

# ---- 13. Key takeaway printout ----
cat("Original Historical VaR (95%):", round(as.numeric(old_hist_var), 4), "\n")
cat("Rebalanced Historical VaR (95%):", round(as.numeric(new_hist_var), 4), "\n")
cat("Original Historical CVaR (95%):", round(as.numeric(old_hist_cvar), 4), "\n")
cat("Rebalanced Historical CVaR (95%):", round(as.numeric(new_hist_cvar), 4), "\n")
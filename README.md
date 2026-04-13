## README

Portfolio Risk Framework Simulation - Var and Stress Testing
============================
Laetitia Wouendji
April 2026

## Overview
*This project develops a portfolio risk framework in R to quantify downside risk and support allocation decisions. The model applies Value at Risk (VaR), Conditional VaR (CVaR), and stress testing to a multi-asset portfolio.*

## Portfolio Composition

Assets were selected to offer a broad risk exposure:

1. TotalEnergies (Energy exposure)
2. Euro Stoxx ETF (Equity market)
3. Euro Government Bonds (Rates)
4. Gold (Defensive asset)

## Methodology
I imported daily log returns form market data on  yahoo Finance using the "get" function from tidyverse. Removed missing values then calculated the assets mean and volatility over the period.
I built a correlation matrix to understand how individual asset movement impact the others within the portfolio


![](CorrelationMatrix.png)<!-- -->

I then calculated the historical and parametric VaR(95%) and the Expected Shortfall for the portfolio to highlight the real amplitude of the risk, should the event happen.


  ##          Portfolio
  ## HistVaR -0.01190464
  ## ParaVaR -0.01186999
  ## ES      -0.01753287 


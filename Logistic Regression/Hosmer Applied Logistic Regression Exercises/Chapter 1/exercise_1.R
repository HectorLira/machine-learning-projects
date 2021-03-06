library(ggplot2)
library(data.table)
library(dplyr)

setwd("~/Desktop/machine-learning-projects/Logistic Regression/Hosmer Applied Logistic Regression Exercises")

icu_data <- fread("datasets/ICU/ICU.txt", header = T)

# b)
ggplot(data = icu_data) +
  geom_point(aes(y = STA, x = AGE)) +
  xlim(c(10,100)) +
  ylim(c(0,1)) +
  ggtitle("Scatterplot of STA vs. AGE") +
  theme(plot.title = element_text(hjust = 0.5))

# c)
intervals <- 15 + 10 * 0:8
class_rep <- rowMeans(cbind(head(intervals, -1),
                            intervals[-1] - 1))

icu_data_summary <- icu_data %>%
  mutate(age_intervals = cut(AGE, breaks = intervals,
                             include.lowest = T,
                             right = F)) %>%
  group_by(age_intervals) %>%
  summarise(sta_mean = mean(STA)) %>%
  mutate(class_reps = class_rep)

ggplot(data = icu_data_summary,
       aes(y = sta_mean, x = class_reps)) +
  geom_line() +
  geom_point() +
  xlim(c(10,100)) +
  ylim(c(0,1)) +
  ggtitle("Scatterplot of Mean STA vs. AGE classes") +
  theme(plot.title = element_text(hjust = 0.5))

# e)
logistic_model <- glm(STA ~ AGE,
                      data = icu_data,
                      family = binomial)
summary(logistic_model)

logistic_model_function <- function(x){
  logit_prob <- logistic_model$coefficients[1] +
    logistic_model$coefficients[2] * x
  
  return(exp(logit_prob) / (1 + exp(logit_prob)))
}

ggplot(data = icu_data, aes(y = STA, x = AGE)) +
  geom_point() +
  # geom_smooth(method = "glm",
  #             method.args = list(family = "binomial"),
  #             se = F) +
  stat_function(fun = logistic_model_function,
                color = 'blue') +
  xlim(c(10,100)) +
  ylim(c(0,1)) +
  ggtitle("Scatterplot of STA vs. AGE (+ model)") +
  theme(plot.title = element_text(hjust = 0.5))

ggplot(data = icu_data_summary,
       aes(y = sta_mean, x = class_reps)) +
  geom_line() +
  geom_point() +
  stat_function(fun = logistic_model_function,
                color = 'blue') +
  xlim(c(10,100)) +
  ylim(c(0,1)) +
  ggtitle("Mean STA vs. AGE classes (+ model)") +
  theme(plot.title = element_text(hjust = 0.5))

# f)
## Likelihood ratio test
likelihood_without_variables <- function(y){
  n1 <- sum(y == 1)
  n0 <- sum(y == 0)
  n <- n1 + n0
  
  likelihood <- ((n1/n)^n1) * ((n0/n)^n0)
  
  return(likelihood)
}

logistic_likelihood <- function(y, model_predictions){
  likelihood <- prod((model_predictions^y) *
                       (1-model_predictions)^(1-y))
  
  return(likelihood)
}

predictions <- predict(logistic_model,
                       type = 'response')

G <- -2*log(likelihood_without_variables(icu_data$STA) /
              logistic_likelihood(icu_data$STA, predictions))
G

pchisq(G, df = 1, lower.tail = F)

## Wald test
### standard error
coef(summary(logistic_model))[2, 2]

wald_statistic <- coef(logistic_model)[2] /
                  coef(summary(logistic_model))[2, 2]
wald_statistic

2 * (1 - pnorm(q = wald_statistic))

## Score test
compute_st_statistic <- function(x, y){
  st_numerator <- sum(x*(y - mean(y)))
  st_denominator <- sqrt(mean(y)*
                         (1-mean(y))*
                         sum((x-mean(x))^2))
  
  st_statistic <- st_numerator / st_denominator
  
  return(st_statistic)
}

st_statistic <- compute_st_statistic(icu_data$AGE,
                                     icu_data$STA)
st_statistic

2 * (1 - pnorm(st_statistic))

## Deviance
-2 * log(logistic_likelihood(icu_data$STA, predictions))

logistic_model$deviance

# g)
alpha <- 0.05
se_b1 <- coef(summary(logistic_model))[2, 2]

logistic_model$coefficients[2] +
  c(lower = -qnorm(1-alpha/2)*se_b1,
    upper = qnorm(1-alpha/2)*se_b1)

confint.default(logistic_model,
                parm = 2,
                level = 1 - alpha)

# h)
summary(logistic_model)$cov.scaled

## logit prediction
x <- 60

sum(logistic_model$coefficients * c(1, x))
predict(logistic_model,
        newdata = data.frame(AGE = x),
        type = 'link')

## logistic probability prediction
logit_prediction <- sum(logistic_model$coefficients * c(1, x))
exp(logit_prediction) / (1 + exp(logit_prediction))
predict(logistic_model,
        newdata = data.frame(AGE = x),
        type = 'response')

## confidence intervals
### logit prediction confidence intervals
alpha <- 0.05

var_g <- summary(logistic_model)$cov.scaled[1,1] +
  (x^2) * summary(logistic_model)$cov.scaled[2,2] +
  2 * x * summary(logistic_model)$cov.scaled[2, 1]
se_g <- sqrt(var_g)

g <- predict(logistic_model,
             newdata = data.frame(AGE = x),
             type = 'link')

g + c(lower = -qnorm(1 - alpha/2) * se_g,
      g = 0,
      upper = qnorm(1 - alpha/2) * se_g)

### logistic probability confidence intervals
g_intervals <- g + c(lower = -qnorm(1 - alpha/2) * se_g,
                     g = 0,
                     upper = qnorm(1 - alpha/2) * se_g)

exp(g_intervals) / (1 + exp(g_intervals))
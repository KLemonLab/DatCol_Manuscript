### LMM FUNCTIONS ###

# Function to fit a mixed model, check for singularity, and extract results including ANOVA, fixed effects, random effects, and emmeans contrasts. 
# The function also backtransforms emmeans predictions if the response variable was log-transformed.
mixed_model_with_emmeans <- function(input_data, response, log_response, fixed_effects, random_effects1 = NULL, random_effects2 = NULL, adjust) {
  # Build the fixed effects formula: main effects and their interaction (A*B)
  fixed_formula <- paste(fixed_effects, collapse = " * ")
  
  # Build random effects formula in the format (1|A) + (1|A:B) if both are provided
  rand1 <- if (!is.null(random_effects1)) paste0("(1|", random_effects1, ")") else NULL
  rand2 <- if (!is.null(random_effects2)) paste0("(1|", random_effects1, ":", random_effects2, ")") else NULL
  random_formula <- paste(na.omit(c(rand1, rand2)), collapse = " + ")
  
  # Create the full model formula, with or without log
  response_part <- if (log_response) { paste0("log(", response, ")") } else { response }
  formula_str <- paste(response_part, "~", fixed_formula, "+", random_formula)
  model_formula <- as.formula(formula_str)
  model <- lmer(model_formula, data = input_data)
  
  # Extract random effects info
  singular <- isSingular(model)
  random_effects_df <- as.data.frame(VarCorr(model)) %>%
    mutate(proportion = round(100 * (vcov / sum(vcov)), 2)) %>%
    mutate(singular = singular)
  
  # Refit if singular and random_effects2 is provided
  if (singular && !is.null(random_effects2)) {
    fallback_formula_str <- paste(response_part, "~", fixed_formula, "+", paste0("(1|", random_effects2, ")"))
    model_formula <- as.formula(fallback_formula_str)
    model <- lmer(model_formula, data = input_data)
  }
  
  # Run ANOVA
  anova_tbl <- anova(model)
  effect_names <- rownames(anova_tbl)
  
  # Extract fixed effects coefficients and convert to dataframe
  fixed_effects_df <- as.data.frame(summary(model)$coefficients) %>%
    rownames_to_column(var = "term")
  
  # Generate emmeans model for pairwise contrasts based on the fixed effects only.
  emmeans_formula <- as.formula(paste("~", fixed_formula))
  emmeans_model <- emmeans(model, emmeans_formula)
  
  # For pairwise contrasts for each main effect
  emmeans_contrasts <- lapply(
    fixed_effects,
    function(effect) {
      summary(
        pairs(
          emmeans_model,
          simple = effect,
          adjust = adjust
        )
      )
    }
  )
  names(emmeans_contrasts) <- fixed_effects
  
  # Add interaction contrasts only if there is more than one fixed effect
  if (length(fixed_effects) > 1) {
    emmeans_contrasts[["interaction"]] <- summary(
      contrast(
        emmeans_model,
        interaction = rep("pairwise", length(fixed_effects)),
        by = NULL
      ),
      adjust = adjust
    )
  }
  
  # Convert emmeans predictions to dataframe for backtransformation
  emmeans_df <- as.data.frame(emmeans_model)
  
  # Backtransform if log_response == TRUE, otherwise just copy the values. Calculate confidence intervals as well.
  # Remove rows if emmean is NA to avoid creating conditions for missing predictions.
  emmeans_df <- emmeans_df %>%
    mutate(
      predicted_mean  = if (log_response) exp(emmean) else emmean,
      predicted_lower = if (log_response) exp(emmean - 2*SE) else emmean - 2*SE,
      predicted_upper = if (log_response) exp(emmean + 2*SE) else emmean + 2*SE,
      condition = paste(!!!syms(fixed_effects), sep = ".") 
    ) %>%
    filter(!is.na(emmean)) %>%
    droplevels()
  
  # Add a combined condition column to the original input data for easier joining later.
  input_data <- input_data %>%
    mutate(condition = paste(!!!syms(fixed_effects), sep = ".")) 
  
  # Return all results in a list
  return(list(
    input_data = input_data,
    model_formula = model_formula,
    anova = anova_tbl,
    random_effects = random_effects_df,
    fixed_effects = fixed_effects_df,
    emmeans_formula = emmeans_formula,
    emmeans_contrasts = emmeans_contrasts,
    emmeans_predictions = emmeans_df
  ))
}

# Function to format the results from the mixed model and emmeans contrasts into tidy dataframes for input summary, predictions, and contrasts. 
# It also calculates fold changes for main effect contrasts based on predicted means.
format_stats_results <- function(stats_results, grouping_vars = c("condition"), p.value_threshold = 0.05) {
  
  input_data <- stats_results$input_data
  predictions <- stats_results$emmeans_predictions
  contrasts <- stats_results$emmeans_contrasts
  response <- stats_results$model_formula[[2]]
  anova <- stats_results$anova
  random_effects <- stats_results$random_effects
  fixed_effects <- stats_results$fixed_effects
  
  if (is.call(response) && identical(response[[1]], as.name("log"))) {
    response <- response[[2]]
  }
  
  # Summarize input data
  input_summary <- input_data %>%
    group_by(across(all_of(grouping_vars))) %>%
    summarise(n = n(),
              mean = mean({{ response }}),
              sd = sd({{ response }}),
              se = sd / sqrt(n),
              .groups = "drop"
    )
  
  # Merge with predictions 
  predictions <- predictions %>%
    left_join(input_summary, by = "condition")
  
  # Determine main effects in contrast list
  effect_names <- names(contrasts)
  main_effects <- setdiff(effect_names, "interaction")
  has_interaction <- "interaction" %in% effect_names
  
  # P-values from ANOVA table (except Residual)
  anova_effect_names <- rownames(stats_results$anova)
  anova_pvalues <- stats_results$anova$`Pr(>F)`
  names(anova_pvalues) <- anova_effect_names
  
  # Helper to process main effects only
  process_main_effect <- function(name) {
    contr <- contrasts[[name]]
    contr$effect_name <- name
    # Get the correct pvalue from ANOVA
    contr$p.value.anova <- anova_pvalues[name]
    contr <- contr %>%
      mutate(contrast = str_replace_all(contrast, "\\s+", ""))
    contr <- contr %>%
      separate(contrast, into = c("condition1", "condition2"), sep = "-", remove = FALSE, fill = "right")
    # Add the combined condition columns as before
    other_effect <- setdiff(main_effects, name)
    if (length(other_effect) == 1 && other_effect %in% names(contr)) {
      if (name == main_effects[1]) {
        contr <- contr %>%
          mutate(
            condition1 = paste(condition1, .data[[other_effect]], sep = "."),
            condition2 = paste(condition2, .data[[other_effect]], sep = ".")
          ) 
      } else {
        contr <- contr %>%
          mutate(
            condition1 = paste(.data[[other_effect]], condition1, sep = "."),
            condition2 = paste(.data[[other_effect]], condition2, sep = ".")
          )
      }
    }
    contr
  }
  
  # Main effect contrasts
  main_contrasts <- lapply(main_effects, process_main_effect)
  main_contrasts_tbl <- bind_rows(main_contrasts) %>%
    select(effect_name, p.value.anova, contrast, estimate, SE, df, t.ratio, p.value, everything())
  
  # Join with predicted means for fold change, etc.
  main_contrasts_tbl <- main_contrasts_tbl %>%
    left_join(dplyr::select(predictions, condition, predicted_mean), by = join_by(condition1 == condition)) %>%
    left_join(dplyr::select(predictions, condition, predicted_mean), by = join_by(condition2 == condition), suffix = c(".1", ".2")) %>% 
    mutate(
      FC = predicted_mean.1 / predicted_mean.2, 
      log2FC = log2(FC),
      sign = case_when(p.value < p.value_threshold ~ "*", TRUE ~ "")
    ) 
  
  # Add group labels for the conditions in the contrasts by matching with the predictions dataframe. 
  # This assumes that the first grouping variable corresponds to the conditions in the contrasts.
  conditions_label_col = grouping_vars[1] 
  main_contrasts_tbl$group1 <- predictions[[conditions_label_col]][match(main_contrasts_tbl$condition1, predictions$condition)]
  main_contrasts_tbl$group2 <- predictions[[conditions_label_col]][match(main_contrasts_tbl$condition2, predictions$condition)]
  
  # Interaction contrasts (if present).
  interaction_tbl <- NULL
  if (has_interaction) {
    inter_contr <- contrasts$interaction
    inter_contr$effect_name <- "interaction"
    interaction_anova_name <- names(anova_pvalues)[grepl(":", names(anova_pvalues))]
    inter_contr$p.value.anova <- anova_pvalues[interaction_anova_name]
    interaction_tbl <- inter_contr %>%
      select(effect_name, p.value.anova, estimate, SE, df, t.ratio, p.value, everything()) %>% 
      mutate(
        sign = case_when(p.value < p.value_threshold ~ "*", TRUE ~ "")
      ) 
  }
  
  
  return(list(input_data = input_data,
              predictions = predictions,
              main = main_contrasts_tbl, 
              interaction = interaction_tbl,
              anova = anova,
              random_effects = random_effects,
              fixed_effects = fixed_effects
  ))
}
# Load libraries
library(ggplot2)
library(gridExtra)
library(readxl)   # for reading Excel
library(patchwork)
# Read the Excel file
df <- read_excel("Regional_Aggregated.xlsx")

# Check the column names
print(names(df))

# Factor ordering for x-axis
df$Row <- factor(df$Row, 
                 levels = c("World","North America","Central and south America",
                            "Europe","Africa","Middle East","Eurasia","Asia Pacific"))


# Register Times New Roman under a short alias
# Register Times New Roman under a short alias
windowsFonts(Times = windowsFont("Times New Roman"))

# Plot function with option to hide x-axis text
make_plot <- function(data, prefix, y_label, show_x = TRUE) {
  p <- ggplot(data, aes(x = Row)) +
    geom_boxplot(
      aes(
        ymin = !!sym(paste0(prefix, "_25")),
        lower = !!sym(paste0(prefix, "_25")),
        middle = !!sym(paste0(prefix, "_50")),
        upper = !!sym(paste0(prefix, "_75")),
        ymax = !!sym(paste0(prefix, "_75"))
      ),
      stat = "identity", width = 0.5, fill = "grey70", color = "black"
    ) +
    geom_point(aes(y = !!sym(paste0(prefix, "_weighted_average")),
                   shape = "Weighted mean", fill = "Weighted mean"),
               size = 3, color = "black") +
    geom_point(aes(y = !!sym(paste0(prefix, "_normal_avg")),
                   shape = "Mean", fill = "Mean"),
               size = 3, color = "black") +
    scale_shape_manual(name = NULL,
                       values = c("Weighted mean" = 21, "Mean" = 21)) +
    scale_fill_manual(name = NULL,
                      values = c("Weighted mean" = "black", "Mean" = "white")) +
    labs(y = y_label, x = "") +
    theme_minimal(base_size = 14, base_family = "Times") +
    theme(
      axis.text.x  = if (show_x) element_text(angle = 30, hjust = 1, family = "Times", color = "black") else element_blank(),
      axis.ticks.x = if (show_x) element_line(color = "black") else element_blank(),
      axis.text.y  = element_text(family = "Times", color = "black"),
      axis.title   = element_text(family = "Times", color = "black"),
      plot.title   = element_text(family = "Times", color = "black"),
      legend.text  = element_text(family = "Times", color = "black"),
      legend.title = element_text(family = "Times", color = "black"),
      panel.grid.minor = element_blank(),
      panel.grid.major = element_line(color = "grey80") # keep grid light gray
    )
  
  return(p)
}

# Example combining with patchwork
library(patchwork)

p1 <- make_plot(df, "LUE", "LUE (W/m²)", show_x = FALSE)
p2 <- make_plot(df, "LT", "LTA (m²/MWh)", show_x = FALSE)
p3 <- make_plot(df, "LT_yr", "LTL (m²/GWh)", show_x = TRUE)

final_plot <- p1 / p2 / p3
final_plot


# Load libraries
library(ggplot2)
library(readxl)   # for reading Excel
library(patchwork)
library(here)
library(showtext) # for font handling

# Add Times New Roman (adjust path if needed)
font_add("Times New Roman", regular = "C:/Windows/Fonts/times.ttf")
showtext_auto()

# Read the Excel file
df <- read_excel("Regional_Aggregated.xlsx")

# Factor ordering for x-axis
df$Row <- factor(df$Row, 
                 levels = c("World","North America","Central and south America",
                            "Europe","Africa","Middle East","Eurasia","Asia Pacific"))

# Plot function
make_plot <- function(data, prefix, y_label, show_x = TRUE) {
  p <- ggplot(data, aes(x = Row)) +
    geom_boxplot(
      aes(
        ymin   = !!sym(paste0(prefix, "_25")),
        lower  = !!sym(paste0(prefix, "_25")),
        middle = !!sym(paste0(prefix, "_50")),
        upper  = !!sym(paste0(prefix, "_75")),
        ymax   = !!sym(paste0(prefix, "_75"))
      ),
      stat = "identity", width = 0.2, fill = "grey70", color = "black", size = 0.15  
    ) +
    scale_x_discrete(expand = expansion(mult = c(0.05, 0.05))) +
    # Weighted mean point
    geom_point(aes(y = !!sym(paste0(prefix, "_weighted_average")),
                   shape = "Weighted mean", fill = "Weighted mean"),
               size = 0.5, color = "black") +
    scale_shape_manual(name = NULL, values = c("Weighted mean" = 21)) +
    scale_fill_manual(name = NULL, values = c("Weighted mean" = "black")) +
    labs(y = y_label, x = "") +
    theme_minimal(base_size = 40, base_family = "Times New Roman") +
    theme(
      axis.text.x  = if (show_x) element_text(angle = 30, hjust = 1, 
                                              family = "Times New Roman", color = "black") else element_blank(),
      axis.ticks.x = if (show_x) element_line(color = "grey80", size = 0.1) else element_blank(),
      axis.text.y  = element_text(family = "Times New Roman", color = "black"),
      axis.title   = element_text(family = "Times New Roman", color = "black"),
      legend.text  = element_text(family = "Times New Roman", color = "black"),
      panel.grid.minor = element_blank(),
      panel.grid.major = element_line(color = "grey80", size = 0.1)  # thinner grid lines
    )
  
  return(p)
}

# Create sub-figures
p1 <- make_plot(df, "LUE",   "LUE (W/m²)",   show_x = FALSE)
p2 <- make_plot(df, "LT",    "LTA (m²/MWh)", show_x = FALSE)
p3 <- make_plot(df, "LT_yr", "LTL (m²/GWh)", show_x = TRUE)

# Combine vertically
final_plot <- p1 / p2 / p3
final_plot

# Save as high-resolution PNG in same folder
ggsave(
  filename = here("Fig2.png"),
  plot = final_plot,
  width = 6, height = 5, dpi = 600
)

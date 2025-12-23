World Solar Land-Use Efficiency and Land Transformation Dataset (2017 Base Year LT and Lifetime LT)

1. World Solar Plants Area (Shapefile & KMZ File)
(1) Spatial Join Data (Shapefile) - Without Groundtruthing
    Original_SpatialJoin1_wri_NATUREART_1_1.shp: One-to-one spatial join results of Kruitwagen's dataset (2021 updated) with Water Resources Institute(WRI) capacity and generation dataset (2018 data).
    Original_SpatialJoin1_wri_NATUREART_1_MANY.shp: One-to-many spatial join results of Kruitwagen's dataset with WRI capacity and generation dataset.
(2) Supplementary Shapefile and KMZ by using Google Earth Pro Application (mannualy)
    Whole_world_unnormal_LUE_area.kmz: Supplementary area data by using Google Earth Pro (148 polygons for Japan-which is a significant updated data; and 1463 polygons for ROW).
    Whole_world_unnormal_LUE_area_.shp: Supplementary area data for regions with LUE higher than 65 W/m², transformed from Google Earth Pro features (.kmz).

2. Country Level LUE and LT Calculation
(1) Ground_truth_japan.xlsx: Summary of 148 polygons updated through groundtruthing (for Japan).
(2) Ground_truth_other_world.xlsx: Summary of 1463 polygons updated through groundtruthing (for the rest of the world PV).
(3) country_level_weighted_LUE_LT_calculation.m: Code to calculate country-level LUE and LT.
(4) Country&Regional_results_summarization.xlsx: Results of country and regional level LUE and LT calculations.
(5) Spatial_Join_original_data: Original Spatial join data required for running the code (without groundtruthing).

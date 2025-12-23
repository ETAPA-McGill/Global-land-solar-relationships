% 1. Replace the original area and capacity values with ground-truth data 
%    for areas with abnormal LUE values.
% 2. Aggregate the capacity values for all areas within the same polygon.
% 3. Calculate country-level metrics:
%    - LUE (weighted by capacity)
%    - LT (weighted by 2017 generation, base year)
%    - LT_yr (lifetime transformation, weighted by annual generation)


%%%%1. Replace the original area and capacity values with mannual/ground-truth data for areas with abnormal LUE values.
% (1)read [1-1 spatial join results-without mannual handling]

filePath = 'Spatial_Join_original_data.xlsx';
sheetName = '1_1';
% Read the required columns from the Excel sheet
original_data_1_1 = readtable(filePath, 'Sheet', sheetName, 'Range', 'A1:CT68662');
% Extract relevant columns
OBJECTID = original_data_1_1{:, 'OBJECTID'};
Join_Count = original_data_1_1{:, 'Join_Count'};
TARGET_FID = original_data_1_1{:, 'TARGET_FID'};
unique_id = original_data_1_1{:, 'unique_id'};
area = original_data_1_1{:, 'area'};
CapacityMW = original_data_1_1{:, 'Capacity_MW_'};
Generation2013 = original_data_1_1{:, 'Generation_2013_'};
Generation2014 = original_data_1_1{:, 'Generation_2014_'};
Generation2015 = original_data_1_1{:, 'Generation_2015_'};
Generation2016 = original_data_1_1{:, 'Generation_2016_'};
Generation2017 = original_data_1_1{:, 'Generation_2017_'};
LUEWm2 = original_data_1_1{:, 'LUE_W_m2_'};
LTm2MWh = original_data_1_1{:, 'LT_m2_MWh_'};
% located_country=original_data_1_1{:, 'iso_3166_1'};
WRIclean= table(Join_Count, TARGET_FID); %% id for join feature and target feature
WRIclean1 = table(OBJECTID, Join_Count, TARGET_FID, unique_id, area, CapacityMW, ...
                    Generation2013, Generation2014, Generation2015, Generation2016, ...
                    Generation2017, LUEWm2, LTm2MWh); % the area and generation, capcity data,  from 1-1 spatial join result
% WRIclean2= table(located_country); %% the location of the plants, from 1-1 spatial join result

filename = 'Country_list.mat'; %%%original_data_1_1{:, 'iso_3166_1'}; to remove the default "" by importing from excel we load it here
WRIclean2 = load(filename).WRIclean2;
% clearvars -except WRIclean WRIclean1 WRIclean2

%(2)read [1-many spatial join results-without mannual handling]
original_data=xlsread("Spatial_Join_original_data.xlsx"); %% the first sheet, [1-many spatial join resuts]
%%%%%%%%%%%%%%%%%%
WRIclean_1=table2array(WRIclean);
WRIcleanS1_1=[original_data(:,1),original_data(:,4:7),original_data(:,57),original_data(:,79:83)];%%% 4:7
%%% (3)read the updated data (manually-groundtruthing for other countries except Japan which has more mistakes in polygons) to update the original spatial-join data
UNNORMAL_LUE_WITHOUT_JAPAN = xlsread("Ground_truth_other_world.xlsx");

for jjj = 1:size(WRIcleanS1_1, 1)
    for iii = 1:size(UNNORMAL_LUE_WITHOUT_JAPAN, 1)
        if UNNORMAL_LUE_WITHOUT_JAPAN(iii, 4) == WRIcleanS1_1(jjj, 2)
            if ~isnan(UNNORMAL_LUE_WITHOUT_JAPAN(iii, 91))
                WRIcleanS1_1(jjj, 5) = UNNORMAL_LUE_WITHOUT_JAPAN(iii, 91);
            elseif ~isnan(UNNORMAL_LUE_WITHOUT_JAPAN(iii, 94))
                WRIcleanS1_1(jjj, 5) = UNNORMAL_LUE_WITHOUT_JAPAN(iii, 94);
            elseif ~isnan(UNNORMAL_LUE_WITHOUT_JAPAN(iii, 93))
                WRIcleanS1_1(jjj, 5) = UNNORMAL_LUE_WITHOUT_JAPAN(iii, 93);
            end
            if ~isnan(UNNORMAL_LUE_WITHOUT_JAPAN(iii, 92))
                WRIcleanS1_1(jjj, 6) = UNNORMAL_LUE_WITHOUT_JAPAN(iii, 92);
            end
        end
    end
end

%%% (4)Japan
UNNORMAL_LUE_JAPAN = xlsread("Ground_truth_japan.xlsx");

for jjj = 1:size(WRIcleanS1_1, 1)
    for iii = 1:size(UNNORMAL_LUE_JAPAN, 1)
        if UNNORMAL_LUE_JAPAN(iii, 4) == WRIcleanS1_1(jjj, 2)
            if ~isnan(UNNORMAL_LUE_JAPAN(iii, 117))
                WRIcleanS1_1(jjj, 5) = UNNORMAL_LUE_JAPAN(iii, 117);
            end
            if ~isnan(UNNORMAL_LUE_JAPAN(iii, 118))
                WRIcleanS1_1(jjj, 6) = UNNORMAL_LUE_JAPAN(iii, 118);
            end
        end
    end
end


%%% 2. Summarize those in the same polygon
ID = table2array(WRIclean(1:317, 2)); % Polygons joining several points, there are in total 317
SUB = zeros(317, 7);

for i = 1:317
    for j = 1:size(WRIcleanS1_1, 1)
        if WRIcleanS1_1(j, 2) == ID(i, 1)
            % Update SUB values based on conditions
            for k = 7:10
                if WRIcleanS1_1(j, k) > 0
                    SUB(i, k - 6) = SUB(i, k - 6) + WRIcleanS1_1(j, k);
                end
            end
            SUB(i, 5) = SUB(i, 5) + WRIcleanS1_1(j, 11); % 2017 gen
            SUB(i, 6) = SUB(i, 6) + WRIcleanS1_1(j, 6); % cap
            SUB(i, 7) = max(WRIcleanS1_1(j, 5), SUB(i, 7)); % area maximum
        end
    end
end




%%%%%% 3. Calculate country-level LUE

WRIclean1_1 = table2array(WRIclean1); % 6 is cap, 5 is area for WRIclean1

% Average generation calculations
for jj = 1:size(WRIclean1_1, 1)
    values = WRIclean1_1(jj, 7:11);
    values(isnan(values)) = [];
    WRIclean1_1(jj, 14) = mean(values); % Average generation
end

% Update area and capacity
WRIclean1_1(1:317, 5) = SUB(1:317, 7); % area
WRIclean1_1(1:317, 6) = SUB(1:317, 6); % cap

% Populate WRIclean1_1 with summarized data
for JJ = 2:6
    WRIclean1_1(1:317, 5 + JJ) = SUB(1:317, 5);
end

% Average generation calculations for the first 317 entries
for JJ = 1:317
    values = SUB(JJ, 1:4);
    values(values == 0) = [];
    if isempty(values)
        WRIclean1_1(JJ, 14) = SUB(JJ, 5);
    else
        WRIclean1_1(JJ, 14) = mean([SUB(JJ, 5), values]);
    end
end

% Update WRIclean1_1 based on WRIcleanS1_1
for JJJ = 318:size(WRIclean1_1, 1)
    for ttt = 1:size(WRIcleanS1_1, 1)
        if WRIclean1_1(JJJ, 3) == WRIcleanS1_1(ttt, 2)
            WRIclean1_1(JJJ, 5) = max(WRIclean1_1(JJJ, 5), WRIcleanS1_1(ttt, 5));
            WRIclean1_1(JJJ, 6) = min(WRIclean1_1(JJJ, 6), WRIcleanS1_1(ttt, 6));
        end
    end
end



WRIclean2_1 = table2array(WRIclean2);

Country = unique(WRIclean2_1); % Total of 130 countries
total_cap = zeros(130, 1);
total_gen = zeros(130, 1); % Generation for 2017
total_gen2 = zeros(130, 1); % Average generation
total_area = zeros(130, 1);
total_weight = zeros(130, 1);
total_weight2 = zeros(130, 1);
total_weight3 = zeros(130, 1);

LUE = zeros(130, 1);
LT = zeros(130, 1);

LUE_series=zeros(300,5000);LT_series=zeros(300,5000);LT_yr_series=zeros(300,5000);
polygon_count=zeros(300,1);

for i = 1:130
    for j = 1:4411 %% areas for 4411 polygons have been updated, by manually-ground-truthing
        if (WRIclean2_1(j, 1) == Country(i, 1) && WRIclean1_1(j, 2) > 0)
            polygon_count(i, 1) = polygon_count(i, 1) + 1;

            % Calculate LUE and LT
            LUE_series(i, polygon_count(i, 1)) = WRIclean1_1(j, 6) * 1000000 / WRIclean1_1(j, 5);
            LT_series(i, polygon_count(i, 1)) = WRIclean1_1(j, 5) / (WRIclean1_1(j, 11) * 1000);
            LT_yr_series(i, polygon_count(i, 1)) = WRIclean1_1(j, 5) / (WRIclean1_1(j, 14) * 30);

            % Aggregate totals
            total_weight(i, 1) = total_weight(i, 1) + LUE_series(i, polygon_count(i, 1)) * WRIclean1_1(j, 6);
            total_weight2(i, 1) = total_weight2(i, 1) + LT_series(i, polygon_count(i, 1)) * WRIclean1_1(j, 11);
            total_weight3(i, 1) = total_weight3(i, 1) + (WRIclean1_1(j, 5) / (WRIclean1_1(j, 14) * 30)) * WRIclean1_1(j, 14);
            total_cap(i, 1) = total_cap(i, 1) + WRIclean1_1(j, 6);
            total_area(i, 1) = total_area(i, 1) + WRIclean1_1(j, 5);
            total_gen(i, 1) = total_gen(i, 1) + WRIclean1_1(j, 11);
            total_gen2(i, 1) = total_gen2(i, 1) + WRIclean1_1(j, 14);
        end
    end

    % Calculate national weighted-average LUE and LT if area and generation totals are non-zero
    if total_area(i, 1) > 0
        LUE(i, 1) = total_weight(i, 1) / total_cap(i, 1); %%% this is national weighted average value
    else
        LUE(i, 1) = 0;
    end
    if total_gen(i, 1) > 0
        LT(i, 1) = total_weight2(i, 1) / total_gen(i, 1);
    else
        LT(i, 1) = 0;
    end
    if total_gen2(i, 1) > 0
        LT_yr(i, 1) = total_weight3(i, 1) / total_gen2(i, 1);
    else
        LT_yr(i, 1) = 0;
    end
end

% Calculate summary statistics for each country
sum_LUE = zeros(130, 1);
sum_LT = zeros(130, 1);
sum_LT_yr = zeros(130, 1);
average_LUE = zeros(130, 1); %%% this is average value rather than weighted-average
average_LT = zeros(130, 1);
average_LT_yr = zeros(130, 1);
LUE_25 = zeros(130, 1);
LUE_50 = zeros(130, 1);
LUE_75 = zeros(130, 1);
LT_25 = zeros(130, 1);
LT_50 = zeros(130, 1);
LT_75 = zeros(130, 1);
LT_yr_25 = zeros(130, 1);
LT_yr_50 = zeros(130, 1);
LT_yr_75 = zeros(130, 1);
LUE_SD = zeros(130, 1);
LT_SD = zeros(130, 1);
LT_yr_SD = zeros(130, 1);

for i = 1:130
    if (polygon_count(i) > 0)
        sum_LUE(i, 1) = sum(LUE_series(i, 1:polygon_count(i, 1)));
        sum_LT(i, 1) = sum(LT_series(i, 1:polygon_count(i, 1)));
        sum_LT_yr(i, 1) = sum(LT_yr_series(i, 1:polygon_count(i, 1)));
        average_LUE(i, 1) = sum_LUE(i, 1) / polygon_count(i, 1);  %%% this is average values rather than capacity-weighted average
        average_LT(i, 1) = sum_LT(i, 1) / polygon_count(i, 1);
        average_LT_yr(i, 1) = sum_LT_yr(i, 1) / polygon_count(i, 1);

        % Calculate standard deviation and percentiles
        LUE_SD(i, 1) = std(LUE_series(i, 1:polygon_count(i, 1)));
        LT_SD(i, 1) = std(LT_series(i, 1:polygon_count(i, 1)));
        LT_yr_SD(i, 1) = std(LT_yr_series(i, 1:polygon_count(i, 1)));
        LUE_50(i, 1) = median(LUE_series(i, 1:polygon_count(i, 1)));
        LT_50(i, 1) = median(LT_series(i, 1:polygon_count(i, 1)));
        LT_yr_50(i, 1) = median(LT_yr_series(i, 1:polygon_count(i, 1)));
        LUE_25(i, 1) = prctile(LUE_series(i, 1:polygon_count(i, 1)), 25);
        LUE_75(i, 1) = prctile(LUE_series(i, 1:polygon_count(i, 1)), 75);
        LT_25(i, 1) = prctile(LT_series(i, 1:polygon_count(i, 1)), 25);
        LT_75(i, 1) = prctile(LT_series(i, 1:polygon_count(i, 1)), 75);
        LT_yr_25(i, 1) = prctile(LT_yr_series(i, 1:polygon_count(i, 1)), 25);
        LT_yr_75(i, 1) = prctile(LT_yr_series(i, 1:polygon_count(i, 1)), 75);
    end
end

% Calculate global statistics
world_LUE_sum = [];
world_LT_sum = [];
world_LT_yr_sum = [];
for i = 1:130
    world_LUE_sum = [world_LUE_sum, LUE_series(i, 1:polygon_count(i, 1))];
    world_LT_sum = [world_LT_sum, LT_series(i, 1:polygon_count(i, 1))];
    world_LT_yr_sum = [world_LT_yr_sum, LT_yr_series(i, 1:polygon_count(i, 1))];
end

world_LUE_25 = prctile(world_LUE_sum, 25);
world_LUE_75 = prctile(world_LUE_sum, 75);
world_LUE_50 = prctile(world_LUE_sum, 50);
world_LUE_SD = std(world_LUE_sum);world_LUE_normal_avg = mean(world_LUE_sum);

world_LT_25 = prctile(world_LT_sum, 25);
world_LT_75 = prctile(world_LT_sum, 75);
world_LT_50 = prctile(world_LT_sum, 50);
world_LT_SD = std(world_LT_sum);world_LT_normal_avg = mean(world_LT_sum);

world_LT_yr_25 = prctile(world_LT_yr_sum, 25);
world_LT_yr_75 = prctile(world_LT_yr_sum, 75);
world_LT_yr_50 = prctile(world_LT_yr_sum, 50);
world_LT_yr_SD = std(world_LT_yr_sum);world_LT_yr_normal_avg = mean(world_LT_yr_sum);

% Calculate weighted LUE and LT for the world
World_LUE_weighted_average = sum(total_weight) / sum(total_cap);
World_LT_weighted_average = sum(total_weight2) / sum(total_gen);
World_LT_yr_weighted_average = sum(total_weight3) / sum(total_gen2);

%%%% ---LAST: calculate the regional RESULTS
EUROPE_LUE_sum=LUE_series(4,1:polygon_count(4,1));
EUROPE_LT_sum=LT_series(4,1:polygon_count(4,1));
EUROPE_LT_yr_sum=LT_yr_series(4,1:polygon_count(4,1));
for iiii=1:130
    if(iiii==4|iiii==8|iiii==12|iiii==15|iiii==17|iiii==23|iiii==27|iiii==35|iiii==36|iiii==34|iiii==37|iiii==39|iiii==41|iiii==44|iiii==45|iiii==46|iiii==49|iiii==53|iiii==54|iiii==60|iiii==72|iiii==73|iiii==75|iiii==77|iiii==90|iiii==96|iiii==99|iiii==101|iiii==102|iiii==103|iiii==107|iiii==109|iiii==119)
        EUROPE_LUE_sum=[EUROPE_LUE_sum,LUE_series(iiii,1:polygon_count(iiii,1))];
        EUROPE_LT_sum=[EUROPE_LT_sum,LT_series(iiii,1:polygon_count(iiii,1))];
        EUROPE_LT_yr_sum=[EUROPE_LT_yr_sum,LT_yr_series(iiii,1:polygon_count(iiii,1))];
    end
end
EUROPE_LUE_25=prctile(EUROPE_LUE_sum, 25);EUROPE_LUE_75=prctile(EUROPE_LUE_sum, 75);
EUROPE_LUE_50=prctile(EUROPE_LUE_sum, 50);
EUROPE_LUE_SD=std(EUROPE_LUE_sum);
EUROPE_LT_25=prctile(EUROPE_LT_sum, 25);EUROPE_LT_75=prctile(EUROPE_LT_sum, 75);
EUROPE_LT_50=prctile(EUROPE_LT_sum, 50);
EUROPE_LT_SD=std(EUROPE_LT_sum); 
EUROPE_LT_yr_25=prctile(EUROPE_LT_yr_sum, 25);EUROPE_LT_yr_75=prctile(EUROPE_LT_yr_sum, 75);
EUROPE_LT_yr_50=prctile(EUROPE_LT_yr_sum, 50);
EUROPE_LT_yr_SD=std(EUROPE_LT_yr_sum); 
EUROPE_LUE_normal_avg=mean(EUROPE_LUE_sum);EUROPE_LT_normal_avg=mean(EUROPE_LT_sum); EUROPE_LT_yr_normal_avg=mean(EUROPE_LT_yr_sum); 

EU_LUE_sum=LUE_series(17,1:polygon_count(17,1));
EU_LT_sum=LT_series(17,1:polygon_count(17,1));
EU_LT_yr_sum=LT_yr_series(17,1:polygon_count(17,1));
for iiii=1:130
    if(iiii==36|iiii==37|iiii==44|iiii==45|iiii==54|iiii==60|iiii==96|iiii==99|iiii==109)
        EU_LUE_sum=[EU_LUE_sum,LUE_series(iiii,1:polygon_count(iiii,1))];
        EU_LT_sum=[EU_LT_sum,LT_series(iiii,1:polygon_count(iiii,1))];
        EU_LT_yr_sum=[EU_LT_yr_sum,LT_yr_series(iiii,1:polygon_count(iiii,1))];
    end
end
EU_LUE_25=prctile(EU_LUE_sum, 25);EU_LUE_75=prctile(EU_LUE_sum, 75);
EU_LUE_50=prctile(EU_LUE_sum, 50);
EU_LUE_SD=std(EU_LUE_sum);
EU_LT_25=prctile(EU_LT_sum, 25);EU_LT_75=prctile(EU_LT_sum, 75);
EU_LT_50=prctile(EU_LT_sum, 50);
EU_LT_SD=std(EU_LT_sum); 
EU_LT_yr_25=prctile(EU_LT_yr_sum, 25);EU_LT_yr_75=prctile(EU_LT_yr_sum, 75);
EU_LT_yr_50=prctile(EU_LT_yr_sum, 50);
EU_LT_yr_SD=std(EU_LT_yr_sum); 
EU_LUE_normal_avg=mean(EU_LUE_sum);EU_LT_normal_avg=mean(EU_LT_sum); EU_LT_yr_normal_avg=mean(EU_LT_yr_sum); 


North_am_LUE_sum=LUE_series(13,1:polygon_count(13,1));
North_am_LT_sum=LT_series(13,1:polygon_count(13,1));
North_am_LT_yr_sum=LT_yr_series(13,1:polygon_count(13,1));
for iiii=1:130
    if(iiii==24|iiii==25|iiii==31|iiii==32|iiii==38|iiii==50|iiii==52|iiii==61|iiii==70|iiii==89|iiii==113|iiii==121)
        North_am_LUE_sum=[North_am_LUE_sum,LUE_series(iiii,1:polygon_count(iiii,1))];
        North_am_LT_sum=[North_am_LT_sum,LT_series(iiii,1:polygon_count(iiii,1))];
        North_am_LT_yr_sum=[North_am_LT_yr_sum,LT_yr_series(iiii,1:polygon_count(iiii,1))];
    end
end
North_am_LUE_25=prctile(North_am_LUE_sum, 25);North_am_LUE_75=prctile(North_am_LUE_sum, 75);
North_am_LUE_50=prctile(North_am_LUE_sum, 50);
North_am_LUE_SD=std(North_am_LUE_sum);
North_am_LT_25=prctile(North_am_LT_sum, 25);North_am_LT_75=prctile(North_am_LT_sum, 75);
North_am_LT_50=prctile(North_am_LT_sum, 50);
North_am_LT_SD=std(North_am_LT_sum); 
North_am_LT_yr_25=prctile(North_am_LT_yr_sum, 25);North_am_LT_yr_75=prctile(North_am_LT_yr_sum, 75);
North_am_LT_yr_50=prctile(North_am_LT_yr_sum, 50);
North_am_LT_yr_SD=std(North_am_LT_yr_sum); 
North_am_LUE_normal_avg=mean(North_am_LUE_sum);North_am_LT_normal_avg=mean(North_am_LT_sum); North_am_LT_yr_normal_avg=mean(North_am_LT_yr_sum); 



central_south_am_LUE_sum=LUE_series(7,1:polygon_count(7,1));
central_south_am_LT_sum=LT_series(7,1:polygon_count(7,1));
central_south_am_LT_yr_sum=LT_yr_series(7,1:polygon_count(7,1));
for iiii=1:130
    if(iiii==20|iiii==21|iiii==24|iiii==28|iiii==30|iiii==31|iiii==40|iiii==50|iiii==52|iiii==83|iiii==89|iiii==92|iiii==93|iiii==112|iiii==122)
        central_south_am_LUE_sum=[central_south_am_LUE_sum,LUE_series(iiii,1:polygon_count(iiii,1))];
        central_south_am_LT_sum=[central_south_am_LT_sum,LT_series(iiii,1:polygon_count(iiii,1))];
        central_south_am_LT_yr_sum=[central_south_am_LT_yr_sum,LT_yr_series(iiii,1:polygon_count(iiii,1))];
    end
end
central_south_am_LUE_25=prctile(central_south_am_LUE_sum, 25);central_south_am_LUE_75=prctile(central_south_am_LUE_sum, 75);
central_south_am_LUE_50=prctile(central_south_am_LUE_sum, 50);
central_south_am_LUE_SD=std(central_south_am_LUE_sum);
central_south_am_LT_25=prctile(central_south_am_LT_sum, 25);central_south_am_LT_75=prctile(central_south_am_LT_sum, 75);
central_south_am_LT_50=prctile(central_south_am_LT_sum, 50);
central_south_am_LT_SD=std(central_south_am_LT_sum); 
central_south_am_LT_yr_25=prctile(central_south_am_LT_yr_sum, 25);central_south_am_LT_yr_75=prctile(central_south_am_LT_yr_sum, 75);
central_south_am_LT_yr_50=prctile(central_south_am_LT_yr_sum, 50);
central_south_am_LT_yr_SD=std(central_south_am_LT_yr_sum); 
central_south_am_LUE_normal_avg=mean(central_south_am_LUE_sum);central_south_am_LT_normal_avg=mean(central_south_am_LT_sum); central_south_am_LT_yr_normal_avg=mean(central_south_am_LT_yr_sum); 



africa_LUE_sum=LUE_series(6,1:polygon_count(6,1));
africa_LT_sum=LT_series(6,1:polygon_count(6,1));
africa_LT_yr_sum=LT_yr_series(6,1:polygon_count(6,1));
for iiii=1:130
    if(iiii==16|iiii==19|iiii==22|iiii==33|iiii==39|iiii==42|iiii==43|iiii==48|iiii==64|iiii==74|iiii==76|iiii==78|iiii==81|iiii==82|iiii==85|iiii==87|iiii==88|iiii==104|iiii==106|iiii==110|iiii==111|iiii==116|iiii==120|iiii==129|iiii==130)
        africa_LUE_sum=[africa_LUE_sum,LUE_series(iiii,1:polygon_count(iiii,1))];
        africa_LT_sum=[africa_LT_sum,LT_series(iiii,1:polygon_count(iiii,1))];
        africa_LT_yr_sum=[africa_LT_yr_sum,LT_yr_series(iiii,1:polygon_count(iiii,1))];
    end
end
africa_LUE_25=prctile(africa_LUE_sum, 25);africa_LUE_75=prctile(africa_LUE_sum, 75);
africa_LUE_50=prctile(africa_LUE_sum, 50);
africa_LUE_SD=std(africa_LUE_sum);
africa_LT_25=prctile(africa_LT_sum, 25);africa_LT_75=prctile(africa_LT_sum, 75);
africa_LT_50=prctile(africa_LT_sum, 50);
africa_LT_SD=std(africa_LT_sum); 
africa_LT_yr_25=prctile(africa_LT_yr_sum, 25);africa_LT_yr_75=prctile(africa_LT_yr_sum, 75);
africa_LT_yr_50=prctile(africa_LT_yr_sum, 50);
africa_LT_yr_SD=std(africa_LT_yr_sum); 
africa_LUE_normal_avg=mean(africa_LUE_sum);africa_LT_normal_avg=mean(africa_LT_sum); africa_LT_yr_normal_avg=mean(africa_LT_yr_sum); 


middle_east_LUE_sum=LUE_series(1,1:polygon_count(1,1));
middle_east_LT_sum=LT_series(1,1:polygon_count(1,1));
middle_east_LT_yr_sum=LT_yr_series(1,1:polygon_count(1,1));
for iiii=1:130
    if(iiii==18|iiii==34|iiii==42|iiii==56|iiii==58|iiii==59|iiii==62|iiii==67|iiii==91|iiii==100|iiii==105|iiii==114|iiii==117|iiii==128)
        middle_east_LUE_sum=[middle_east_LUE_sum,LUE_series(iiii,1:polygon_count(iiii,1))];
        middle_east_LT_sum=[middle_east_LT_sum,LT_series(iiii,1:polygon_count(iiii,1))];
        middle_east_LT_yr_sum=[middle_east_LT_yr_sum,LT_yr_series(iiii,1:polygon_count(iiii,1))];
    end
end
middle_east_LUE_25=prctile(middle_east_LUE_sum, 25);middle_east_LUE_75=prctile(middle_east_LUE_sum, 75);
middle_east_LUE_50=prctile(middle_east_LUE_sum, 50);
middle_east_LUE_SD=std(middle_east_LUE_sum);
middle_east_LT_25=prctile(middle_east_LT_sum, 25);middle_east_LT_75=prctile(middle_east_LT_sum, 75);
middle_east_LT_50=prctile(middle_east_LT_sum, 50);
middle_east_LT_SD=std(middle_east_LT_sum); 
middle_east_LT_yr_25=prctile(middle_east_LT_yr_sum, 25);middle_east_LT_yr_75=prctile(middle_east_LT_yr_sum, 75);
middle_east_LT_yr_50=prctile(middle_east_LT_yr_sum, 50);
middle_east_LT_yr_SD=std(middle_east_LT_yr_sum); 
middle_east_LUE_normal_avg=mean(middle_east_LUE_sum);middle_east_LT_normal_avg=mean(middle_east_LT_sum); middle_east_LT_yr_normal_avg=mean(middle_east_LT_yr_sum); 



eurasia_LUE_sum=LUE_series(1,1:polygon_count(1,1));
eurasia_LT_sum=LT_series(1,1:polygon_count(1,1));
eurasia_LT_yr_sum=LT_yr_series(1,1:polygon_count(1,1));
for iiii=1:130
    if(iiii==2|iiii==4|iiii==5|iiii==6|iiii==8|iiii==10|iiii==11|iiii==12|iiii==14|iiii==15|iiii==17|iiii==18|iiii==23|iiii==27|iiii==29|iiii==34|iiii==35|iiii==36|iiii==37|iiii==41|iiii==44|iiii==45|iiii==46|iiii==47|iiii==49|iiii==53|iiii==54|iiii==55|iiii==56|iiii==57|iiii==58|iiii==59|iiii==60|iiii==62|iiii==63|iiii==65|iiii==67|iiii==68|iiii==69|iiii==71|iiii==72|iiii==73|iiii==75|iiii==80|iiii==84|iiii==94|iiii==95|iiii==96|iiii==99|iiii==100|iiii==101|iiii==102|iiii==103|iiii==105|iiii==107|iiii==108|iiii==109|iiii==114|iiii==115|iiii==117|iiii==119|iiii==123|iiii==125|iiii==128)
        eurasia_LUE_sum=[eurasia_LUE_sum,LUE_series(iiii,1:polygon_count(iiii,1))];
        eurasia_LT_sum=[eurasia_LT_sum,LT_series(iiii,1:polygon_count(iiii,1))];
        eurasia_LT_yr_sum=[eurasia_LT_yr_sum,LT_yr_series(iiii,1:polygon_count(iiii,1))];
    end
end
eurasia_LUE_25=prctile(eurasia_LUE_sum, 25);eurasia_LUE_75=prctile(eurasia_LUE_sum, 75);
eurasia_LUE_50=prctile(eurasia_LUE_sum, 50);
eurasia_LUE_SD=std(eurasia_LUE_sum);
eurasia_LT_25=prctile(eurasia_LT_sum, 25);eurasia_LT_75=prctile(eurasia_LT_sum, 75);
eurasia_LT_50=prctile(eurasia_LT_sum, 50);
eurasia_LT_SD=std(eurasia_LT_sum); 
eurasia_LT_yr_25=prctile(eurasia_LT_yr_sum, 25);eurasia_LT_yr_75=prctile(eurasia_LT_yr_sum, 75);
eurasia_LT_yr_50=prctile(eurasia_LT_yr_sum, 50);
eurasia_LT_yr_SD=std(eurasia_LT_yr_sum); 
eurasia_LUE_normal_avg=mean(eurasia_LUE_sum);eurasia_LT_normal_avg=mean(eurasia_LT_sum); eurasia_LT_yr_normal_avg=mean(eurasia_LT_yr_sum); 




asia_paci_LUE_sum=LUE_series(2,1:polygon_count(2,1));
asia_paci_LT_sum=LT_series(2,1:polygon_count(2,1));
asia_paci_LT_yr_sum=LT_yr_series(2,1:polygon_count(2,1));
for iiii=1:130
    if(iiii==9|iiii==14|iiii==55|iiii==57|iiii==63|iiii==65|iiii==69|iiii==71|iiii==80|iiii==84|iiii==86|iiii==94|iiii==95|iiii==115|iiii==125)
        asia_paci_LUE_sum=[asia_paci_LUE_sum,LUE_series(iiii,1:polygon_count(iiii,1))];
        asia_paci_LT_sum=[asia_paci_LT_sum,LT_series(iiii,1:polygon_count(iiii,1))];
        asia_paci_LT_yr_sum=[asia_paci_LT_yr_sum,LT_yr_series(iiii,1:polygon_count(iiii,1))];
    end
end
asia_paci_LUE_25=prctile(asia_paci_LUE_sum, 25);asia_paci_LUE_75=prctile(asia_paci_LUE_sum, 75);
asia_paci_LUE_50=prctile(asia_paci_LUE_sum, 50);
asia_paci_LUE_SD=std(asia_paci_LUE_sum);
asia_paci_LT_25=prctile(asia_paci_LT_sum, 25);asia_paci_LT_75=prctile(asia_paci_LT_sum, 75);
asia_paci_LT_50=prctile(asia_paci_LT_sum, 50);
asia_paci_LT_SD=std(asia_paci_LT_sum); 
asia_paci_LT_yr_25=prctile(asia_paci_LT_yr_sum, 25);asia_paci_LT_yr_75=prctile(asia_paci_LT_yr_sum, 75);
asia_paci_LT_yr_50=prctile(asia_paci_LT_yr_sum, 50);
asia_paci_LT_yr_SD=std(asia_paci_LT_yr_sum); 
asia_paci_LUE_normal_avg=mean(asia_paci_LUE_sum);asia_paci_LT_normal_avg=mean(asia_paci_LT_sum); asia_paci_LT_yr_normal_avg=mean(asia_paci_LT_yr_sum); 




asia_southeast_LUE_sum=LUE_series(55,1:polygon_count(55,1));
asia_southeast_LT_sum=LT_series(55,1:polygon_count(55,1));
asia_southeast_LT_yr_sum=LT_yr_series(55,1:polygon_count(55,1));
for iiii=1:130
    if(iiii==65|iiii==69|iiii==84|iiii==94|iiii==115|iiii==125)
        asia_southeast_LUE_sum=[asia_southeast_LUE_sum,LUE_series(iiii,1:polygon_count(iiii,1))];
        asia_southeast_LT_sum=[asia_southeast_LT_sum,LT_series(iiii,1:polygon_count(iiii,1))];
        asia_southeast_LT_yr_sum=[asia_southeast_LT_yr_sum,LT_yr_series(iiii,1:polygon_count(iiii,1))];
    end
end
asia_southeast_LUE_25=prctile(asia_southeast_LUE_sum, 25);asia_southeast_LUE_75=prctile(asia_southeast_LUE_sum, 75);
asia_southeast_LUE_50=prctile(asia_southeast_LUE_sum, 50);
asia_southeast_LUE_SD=std(asia_southeast_LUE_sum);
asia_southeast_LT_25=prctile(asia_southeast_LT_sum, 25);asia_southeast_LT_75=prctile(asia_southeast_LT_sum, 75);
asia_southeast_LT_50=prctile(asia_southeast_LT_sum, 50);
asia_southeast_LT_SD=std(asia_southeast_LT_sum); 
asia_southeast_LT_yr_25=prctile(asia_southeast_LT_yr_sum, 25);asia_southeast_LT_yr_75=prctile(asia_southeast_LT_yr_sum, 75);
asia_southeast_LT_yr_50=prctile(asia_southeast_LT_yr_sum, 50);
asia_southeast_LT_yr_SD=std(asia_southeast_LT_yr_sum); 
asia_southeast_LUE_normal_avg=mean(asia_southeast_LUE_sum);asia_southeast_LT_normal_avg=mean(asia_southeast_LT_sum); asia_southeast_LT_yr_normal_avg=mean(asia_southeast_LT_yr_sum); 




EUROPE_LUE_weighted_average=(total_weight(4,1)+total_weight(8,1)+total_weight(12,1)+total_weight(15,1)+total_weight(17,1)+total_weight(23,1)+total_weight(27,1)+total_weight(35,1)+total_weight(36,1)+total_weight(34,1)+total_weight(37,1)+total_weight(39,1)+total_weight(41,1)+total_weight(44,1)+total_weight(45,1)+total_weight(46,1)+total_weight(49,1)+total_weight(53,1)+total_weight(54,1)+total_weight(60,1)+total_weight(72,1)+total_weight(73,1)+total_weight(75,1)+total_weight(77,1)+total_weight(90,1)+total_weight(96,1)+total_weight(99,1)+total_weight(101,1)+total_weight(102,1)+total_weight(103,1)+total_weight(107,1)+total_weight(109,1)+total_weight(119,1))/(total_cap(4,1)+total_cap(8,1)+total_cap(12,1)+total_cap(15,1)+total_cap(17,1)+total_cap(23,1)+total_cap(27,1)+total_cap(35,1)+total_cap(36,1)+total_cap(34,1)+total_cap(37,1)+total_cap(39,1)+total_cap(41,1)+total_cap(44,1)+total_cap(45,1)+total_cap(46,1)+total_cap(49,1)+total_cap(53,1)+total_cap(54,1)+total_cap(60,1)+total_cap(72,1)+total_cap(73,1)+total_cap(75,1)+total_cap(77,1)+total_cap(90,1)+total_cap(96,1)+total_cap(99,1)+total_cap(101,1)+total_cap(102,1)+total_cap(103,1)+total_cap(107,1)+total_cap(109,1)+total_cap(119,1));
EUROPE_LT_weighted_average=(total_weight2(4,1)+total_weight2(8,1)+total_weight2(12,1)+total_weight2(15,1)+total_weight2(17,1)+total_weight2(23,1)+total_weight2(27,1)+total_weight2(35,1)+total_weight2(36,1)+total_weight2(34,1)+total_weight2(37,1)+total_weight2(39,1)+total_weight2(41,1)+total_weight2(44,1)+total_weight2(45,1)+total_weight2(46,1)+total_weight2(49,1)+total_weight2(53,1)+total_weight2(54,1)+total_weight2(60,1)+total_weight2(72,1)+total_weight2(73,1)+total_weight2(75,1)+total_weight2(77,1)+total_weight2(90,1)+total_weight2(96,1)+total_weight2(99,1)+total_weight2(101,1)+total_weight2(102,1)+total_weight2(103,1)+total_weight2(107,1)+total_weight2(109,1)+total_weight2(119,1))/(total_gen(4,1)+total_gen(8,1)+total_gen(12,1)+total_gen(15,1)+total_gen(17,1)+total_gen(23,1)+total_gen(27,1)+total_gen(35,1)+total_gen(36,1)+total_gen(34,1)+total_gen(37,1)+total_gen(39,1)+total_gen(41,1)+total_gen(44,1)+total_gen(45,1)+total_gen(46,1)+total_gen(49,1)+total_gen(53,1)+total_gen(54,1)+total_gen(60,1)+total_gen(72,1)+total_gen(73,1)+total_gen(75,1)+total_gen(77,1)+total_gen(90,1)+total_gen(96,1)+total_gen(99,1)+total_gen(101,1)+total_gen(102,1)+total_gen(103,1)+total_gen(107,1)+total_gen(109,1)+total_gen(119,1));
EUROPE_LT_yr_weighted_average=(total_weight3(4,1)+total_weight3(8,1)+total_weight3(12,1)+total_weight3(15,1)+total_weight3(17,1)+total_weight3(23,1)+total_weight3(27,1)+total_weight3(35,1)+total_weight3(36,1)+total_weight3(34,1)+total_weight3(37,1)+total_weight3(39,1)+total_weight3(41,1)+total_weight3(44,1)+total_weight3(45,1)+total_weight3(46,1)+total_weight3(49,1)+total_weight3(53,1)+total_weight3(54,1)+total_weight3(60,1)+total_weight3(72,1)+total_weight3(73,1)+total_weight3(75,1)+total_weight3(77,1)+total_weight3(90,1)+total_weight3(96,1)+total_weight3(99,1)+total_weight3(101,1)+total_weight3(102,1)+total_weight3(103,1)+total_weight3(107,1)+total_weight3(109,1)+total_weight3(119,1))/(total_gen2(4,1)+total_gen2(8,1)+total_gen2(12,1)+total_gen2(15,1)+total_gen2(17,1)+total_gen2(23,1)+total_gen2(27,1)+total_gen2(35,1)+total_gen2(36,1)+total_gen2(34,1)+total_gen2(37,1)+total_gen2(39,1)+total_gen2(41,1)+total_gen2(44,1)+total_gen2(45,1)+total_gen2(46,1)+total_gen2(49,1)+total_gen2(53,1)+total_gen2(54,1)+total_gen2(60,1)+total_gen2(72,1)+total_gen2(73,1)+total_gen2(75,1)+total_gen2(77,1)+total_gen2(90,1)+total_gen2(96,1)+total_gen2(99,1)+total_gen2(101,1)+total_gen2(102,1)+total_gen2(103,1)+total_gen2(107,1)+total_gen2(109,1)+total_gen2(119,1));





EU_LUE_weighted_average=(total_weight(9,1)+total_weight(17,1)+total_weight(36,1)+total_weight(37,1)+total_weight(44,1)+total_weight(45,1)+total_weight(54,1)+total_weight(60,1)+total_weight(96,1)+total_weight(99,1)+total_weight(109,1))*1/(total_cap(9,1)+total_cap(17,1)+total_cap(36,1)+total_cap(37,1)+total_cap(44,1)+total_cap(45,1)+total_cap(54,1)+total_cap(60,1)+total_cap(96,1)+total_cap(99,1)+total_cap(109,1));
North_am_LUE_weighted_average=(total_weight(13,1)+total_weight(24,1)+total_weight(25,1)+total_weight(31,1)+total_weight(32,1)+total_weight(38,1)+total_weight(50,1)+total_weight(52,1)+total_weight(61,1)+total_weight(70,1)+total_weight(89,1)+total_weight(113,1)+total_weight(121,1))*1/(total_cap(13,1)+total_cap(24,1)+total_cap(25,1)+total_cap(31,1)+total_cap(32,1)+total_cap(38,1)+total_cap(50,1)+total_cap(52,1)+total_cap(61,1)+total_cap(70,1)+total_cap(89,1)+total_cap(113,1)+total_cap(121,1));
central_south_am_LUE_weighted_average=(total_weight(7,1)+total_weight(20,1)+total_weight(21,1)+total_weight(24,1)+total_weight(28,1)+total_weight(30,1)+total_weight(31,1)+total_weight(40,1)+total_weight(50,1)+total_weight(52,1)+total_weight(83,1)+total_weight(89,1)+total_weight(92,1)+total_weight(93,1)+total_weight(112,1)+total_weight(122,1))*1/(total_cap(7,1)+total_cap(20,1)+total_cap(21,1)+total_cap(24,1)+total_cap(28,1)+total_cap(30,1)+total_cap(31,1)+total_cap(40,1)+total_cap(50,1)+total_cap(52,1)+total_cap(83,1)+total_cap(89,1)+total_cap(92,1)+total_cap(93,1)+total_cap(112,1)+total_cap(122,1));
% Europe_LUE=(total_weight(4,1)+total_weight(8,1)+total_weight(12,1)+total_weight(15,1)+total_weight(17,1)+total_weight(23,1)+total_weight(27,1)+total_weight(34,1)+total_weight(35,1)+total_weight(36,1)+total_weight(37,1)+total_weight(41,1)+total_weight(44,1)+total_weight(45,1)+total_weight(46,1)+total_weight(47,1)+total_weight(49,1)+total_weight(53,1)+total_weight(54,1)+total_weight(60,1)+total_weight(72,1)+total_weight(73,1)+total_weight(75,1)+total_weight(90,1)+total_weight(96,1)+total_weight(99,1)+total_weight(101,1)+total_weight(102,1)+total_weight(103,1)+total_weight(107,1)+total_weight(108,1)+total_weight(109,1)+total_weight(117,1)+total_weight(119,1)+total_weight(127,1))/(total_cap(4,1)+total_cap(8,1)+total_cap(12,1)+total_cap(15,1)+total_cap(17,1)+total_cap(23,1)+total_cap(27,1)+total_cap(34,1)+total_cap(35,1)+total_cap(36,1)+total_cap(37,1)+total_cap(41,1)+total_cap(44,1)+total_cap(45,1)+total_cap(46,1)+total_cap(47,1)+total_cap(49,1)+total_cap(53,1)+total_cap(54,1)+total_cap(60,1)+total_cap(72,1)+total_cap(73,1)+total_cap(75,1)+total_cap(90,1)+total_cap(96,1)+total_cap(99,1)+total_cap(101,1)+total_cap(102,1)+total_cap(103,1)+total_cap(107,1)+total_cap(108,1)+total_cap(109,1)+total_cap(117,1)+total_cap(119,1)+total_cap(127,1));
africa_LUE_weighted_average=(total_weight(6,1)+total_weight(16,1)+total_weight(19,1)+total_weight(22,1)+total_weight(33,1)+total_weight(39,1)+total_weight(42,1)+total_weight(43,1)+total_weight(48,1)+total_weight(64,1)+total_weight(74,1)+total_weight(76,1)+total_weight(78,1)+total_weight(81,1)+total_weight(82,1)+total_weight(85,1)+total_weight(87,1)+total_weight(88,1)+total_weight(104,1)+total_weight(106,1)+total_weight(110,1)+total_weight(111,1)+total_weight(116,1)+total_weight(120,1)+total_weight(129,1)+total_weight(130,1))*1/(total_cap(6,1)+total_cap(16,1)+total_cap(19,1)+total_cap(22,1)+total_cap(33,1)+total_cap(39,1)+total_cap(42,1)+total_cap(43,1)+total_cap(48,1)+total_cap(64,1)+total_cap(74,1)+total_cap(76,1)+total_cap(78,1)+total_cap(81,1)+total_cap(82,1)+total_cap(85,1)+total_cap(87,1)+total_cap(88,1)+total_cap(104,1)+total_cap(106,1)+total_cap(110,1)+total_cap(111,1)+total_cap(116,1)+total_cap(120,1)+total_cap(129,1)+total_cap(130,1));
middle_east_LUE_weighted_average=(total_weight(1,1)+total_weight(18,1)+total_weight(34,1)+total_weight(42,1)+total_weight(56,1)+total_weight(58,1)+total_weight(59,1)+total_weight(62,1)+total_weight(67,1)+total_weight(91,1)+total_weight(100,1)+total_weight(105,1)+total_weight(114,1)+total_weight(117,1)+total_weight(128,1))*1/(total_cap(1,1)+total_cap(18,1)+total_cap(34,1)+total_cap(42,1)+total_cap(56,1)+total_cap(58,1)+total_cap(59,1)+total_cap(62,1)+total_cap(67,1)+total_cap(91,1)+total_cap(100,1)+total_cap(105,1)+total_cap(114,1)+total_cap(117,1)+total_cap(128,1));
eurasia_LUE_weighted_average=(total_weight(1,1)+total_weight(2,1)+total_weight(4,1)+total_weight(5,1)+total_weight(6,1)+total_weight(8,1)+total_weight(10,1)+total_weight(11,1)+total_weight(12,1)+total_weight(14,1)+total_weight(15,1)+total_weight(17,1)+total_weight(18,1)+total_weight(23,1)+total_weight(27,1)+total_weight(29,1)+total_weight(34,1)+total_weight(35,1)+total_weight(36,1)+total_weight(37,1)+total_weight(41,1)+total_weight(44,1)+total_weight(45,1)+total_weight(46,1)+total_weight(47,1)+total_weight(49,1)+total_weight(53,1)+total_weight(54,1)+total_weight(55,1)+total_weight(56,1)+total_weight(57,1)+total_weight(58,1)+total_weight(59,1)+total_weight(60,1)+total_weight(62,1)+total_weight(63,1)+total_weight(65,1)+total_weight(67,1)+total_weight(68,1)+total_weight(69,1)+total_weight(71,1)+total_weight(72,1)+total_weight(73,1)+total_weight(75,1)+total_weight(80,1)+total_weight(84,1)+total_weight(91,1)+total_weight(94,1)+total_weight(95,1)+total_weight(96,1)+total_weight(99,1)+total_weight(100,1)+total_weight(101,1)+total_weight(102,1)+total_weight(103,1)+total_weight(105,1)+total_weight(107,1)+total_weight(108,1)+total_weight(109,1)+total_weight(114,1)+total_weight(115,1)+total_weight(117,1)+total_weight(119,1)+total_weight(123,1)+total_weight(125,1)+total_weight(128,1))*1/(total_cap(1,1)+total_cap(2,1)+total_cap(4,1)+total_cap(5,1)+total_cap(6,1)+total_cap(8,1)+total_cap(10,1)+total_cap(11,1)+total_cap(12,1)+total_cap(14,1)+total_cap(15,1)+total_cap(17,1)+total_cap(18,1)+total_cap(23,1)+total_cap(27,1)+total_cap(29,1)+total_cap(34,1)+total_cap(35,1)+total_cap(36,1)+total_cap(37,1)+total_cap(41,1)+total_cap(44,1)+total_cap(45,1)+total_cap(46,1)+total_cap(47,1)+total_cap(49,1)+total_cap(53,1)+total_cap(54,1)+total_cap(55,1)+total_cap(56,1)+total_cap(57,1)+total_cap(58,1)+total_cap(59,1)+total_cap(60,1)+total_cap(62,1)+total_cap(63,1)+total_cap(65,1)+total_cap(67,1)+total_cap(68,1)+total_cap(69,1)+total_cap(71,1)+total_cap(72,1)+total_cap(73,1)+total_cap(75,1)+total_cap(80,1)+total_cap(84,1)+total_cap(91,1)+total_cap(94,1)+total_cap(95,1)+total_cap(96,1)+total_cap(99,1)+total_cap(100,1)+total_cap(101,1)+total_cap(102,1)+total_cap(103,1)+total_cap(105,1)+total_cap(107,1)+total_cap(108,1)+total_cap(109,1)+total_cap(114,1)+total_cap(115,1)+total_cap(117,1)+total_cap(119,1)+total_cap(123,1)+total_cap(125,1)+total_cap(128,1));
asia_paci_LUE_weighted_average=(total_weight(2,1)+total_weight(9,1)+total_weight(14,1)+total_weight(55,1)+total_weight(57,1)+total_weight(63,1)+total_weight(65,1)+total_weight(69,1)+total_weight(71,1)+total_weight(80,1)+total_weight(84,1)+total_weight(86,1)+total_weight(94,1)+total_weight(95,1)+total_weight(115,1)+total_weight(125,1))*1/(total_cap(2,1)+total_cap(9,1)+total_cap(14,1)+total_cap(55,1)+total_cap(57,1)+total_cap(63,1)+total_cap(65,1)+total_cap(69,1)+total_cap(71,1)+total_cap(80,1)+total_cap(84,1)+total_cap(86,1)+total_cap(94,1)+total_cap(95,1)+total_cap(115,1)+total_cap(125,1));
asia_southeast_LUE_weighted_average=(total_weight(55,1)+total_weight(65,1)+total_weight(69,1)+total_weight(84,1)+total_weight(94,1)+total_weight(115,1)+total_weight(125,1))*1/(total_cap(55,1)+total_cap(65,1)+total_cap(69,1)+total_cap(84,1)+total_cap(94,1)+total_cap(115,1)+total_cap(125,1));


EU_LT_weighted_average=(total_weight2(9,1)+total_weight2(17,1)+total_weight2(36,1)+total_weight2(37,1)+total_weight2(44,1)+total_weight2(45,1)+total_weight2(54,1)+total_weight2(60,1)+total_weight2(96,1)+total_weight2(99,1)+total_weight2(109,1))*1/(total_gen(9,1)+total_gen(17,1)+total_gen(36,1)+total_gen(37,1)+total_gen(44,1)+total_gen(45,1)+total_gen(54,1)+total_gen(60,1)+total_gen(96,1)+total_gen(99,1)+total_gen(109,1));
North_am_LT_weighted_average=(total_weight2(13,1)+total_weight2(24,1)+total_weight2(25,1)+total_weight2(31,1)+total_weight2(32,1)+total_weight2(38,1)+total_weight2(50,1)+total_weight2(52,1)+total_weight2(61,1)+total_weight2(70,1)+total_weight2(89,1)+total_weight2(113,1)+total_weight2(121,1))*1/(total_gen(13,1)+total_gen(24,1)+total_gen(25,1)+total_gen(31,1)+total_gen(32,1)+total_gen(38,1)+total_gen(50,1)+total_gen(52,1)+total_gen(61,1)+total_gen(70,1)+total_gen(89,1)+total_gen(113,1)+total_gen(121,1));
central_south_am_LT_weighted_average=(total_weight2(7,1)+total_weight2(20,1)+total_weight2(21,1)+total_weight2(24,1)+total_weight2(28,1)+total_weight2(30,1)+total_weight2(31,1)+total_weight2(40,1)+total_weight2(50,1)+total_weight2(52,1)+total_weight2(83,1)+total_weight2(89,1)+total_weight2(92,1)+total_weight2(93,1)+total_weight2(112,1)+total_weight2(122,1))*1/(total_gen(7,1)+total_gen(20,1)+total_gen(21,1)+total_gen(24,1)+total_gen(28,1)+total_gen(30,1)+total_gen(31,1)+total_gen(40,1)+total_gen(50,1)+total_gen(52,1)+total_gen(83,1)+total_gen(89,1)+total_gen(92,1)+total_gen(93,1)+total_gen(112,1)+total_gen(122,1));
% Europe_LT=(total_weight2(4,1)+total_weight2(8,1)+total_weight2(12,1)+total_weight2(15,1)+total_weight2(17,1)+total_weight2(23,1)+total_weight2(27,1)+total_weight2(34,1)+total_weight2(35,1)+total_weight2(36,1)+total_weight2(37,1)+total_weight2(41,1)+total_weight2(44,1)+total_weight2(45,1)+total_weight2(46,1)+total_weight2(47,1)+total_weight2(49,1)+total_weight2(53,1)+total_weight2(54,1)+total_weight2(60,1)+total_weight2(72,1)+total_weight2(73,1)+total_weight2(75,1)+total_weight2(90,1)+total_weight2(96,1)+total_weight2(99,1)+total_weight2(101,1)+total_weight2(102,1)+total_weight2(103,1)+total_weight2(107,1)+total_weight2(108,1)+total_weight2(109,1)+total_weight2(117,1)+total_weight2(119,1)+total_weight2(127,1))/(total_gen(4,1)+total_gen(8,1)+total_gen(12,1)+total_gen(15,1)+total_gen(17,1)+total_gen(23,1)+total_gen(27,1)+total_gen(34,1)+total_gen(35,1)+total_gen(36,1)+total_gen(37,1)+total_gen(41,1)+total_gen(44,1)+total_gen(45,1)+total_gen(46,1)+total_gen(47,1)+total_gen(49,1)+total_gen(53,1)+total_gen(54,1)+total_gen(60,1)+total_gen(72,1)+total_gen(73,1)+total_gen(75,1)+total_gen(90,1)+total_gen(96,1)+total_gen(99,1)+total_gen(101,1)+total_gen(102,1)+total_gen(103,1)+total_gen(107,1)+total_gen(108,1)+total_gen(109,1)+total_gen(117,1)+total_gen(119,1)+total_gen(127,1));
africa_LT_weighted_average=(total_weight2(6,1)+total_weight2(16,1)+total_weight2(19,1)+total_weight2(22,1)+total_weight2(33,1)+total_weight2(39,1)+total_weight2(42,1)+total_weight2(43,1)+total_weight2(48,1)+total_weight2(64,1)+total_weight2(74,1)+total_weight2(76,1)+total_weight2(78,1)+total_weight2(81,1)+total_weight2(82,1)+total_weight2(85,1)+total_weight2(87,1)+total_weight2(88,1)+total_weight2(104,1)+total_weight2(106,1)+total_weight2(110,1)+total_weight2(111,1)+total_weight2(116,1)+total_weight2(120,1)+total_weight2(129,1)+total_weight2(130,1))*1/(total_gen(6,1)+total_gen(16,1)+total_gen(19,1)+total_gen(22,1)+total_gen(33,1)+total_gen(39,1)+total_gen(42,1)+total_gen(43,1)+total_gen(48,1)+total_gen(64,1)+total_gen(74,1)+total_gen(76,1)+total_gen(78,1)+total_gen(81,1)+total_gen(82,1)+total_gen(85,1)+total_gen(87,1)+total_gen(88,1)+total_gen(104,1)+total_gen(106,1)+total_gen(110,1)+total_gen(111,1)+total_gen(116,1)+total_gen(120,1)+total_gen(129,1)+total_gen(130,1));
middle_east_LT_weighted_average=(total_weight2(1,1)+total_weight2(18,1)+total_weight2(34,1)+total_weight2(42,1)+total_weight2(56,1)+total_weight2(58,1)+total_weight2(59,1)+total_weight2(62,1)+total_weight2(67,1)+total_weight2(91,1)+total_weight2(100,1)+total_weight2(105,1)+total_weight2(114,1)+total_weight2(117,1)+total_weight2(128,1))*1/(total_gen(1,1)+total_gen(18,1)+total_gen(34,1)+total_gen(42,1)+total_gen(56,1)+total_gen(58,1)+total_gen(59,1)+total_gen(62,1)+total_gen(67,1)+total_gen(91,1)+total_gen(100,1)+total_gen(105,1)+total_gen(114,1)+total_gen(117,1)+total_gen(128,1));
eurasia_LT_weighted_average=(total_weight2(1,1)+total_weight2(2,1)+total_weight2(4,1)+total_weight2(5,1)+total_weight2(6,1)+total_weight2(8,1)+total_weight2(10,1)+total_weight2(11,1)+total_weight2(12,1)+total_weight2(14,1)+total_weight2(15,1)+total_weight2(17,1)+total_weight2(18,1)+total_weight2(23,1)+total_weight2(27,1)+total_weight2(29,1)+total_weight2(34,1)+total_weight2(35,1)+total_weight2(36,1)+total_weight2(37,1)+total_weight2(41,1)+total_weight2(44,1)+total_weight2(45,1)+total_weight2(46,1)+total_weight2(47,1)+total_weight2(49,1)+total_weight2(53,1)+total_weight2(54,1)+total_weight2(55,1)+total_weight2(56,1)+total_weight2(57,1)+total_weight2(58,1)+total_weight2(59,1)+total_weight2(60,1)+total_weight2(62,1)+total_weight2(63,1)+total_weight2(65,1)+total_weight2(67,1)+total_weight2(68,1)+total_weight2(69,1)+total_weight2(71,1)+total_weight2(72,1)+total_weight2(73,1)+total_weight2(75,1)+total_weight2(80,1)+total_weight2(84,1)+total_weight2(91,1)+total_weight2(94,1)+total_weight2(95,1)+total_weight2(96,1)+total_weight2(99,1)+total_weight2(100,1)+total_weight2(101,1)+total_weight2(102,1)+total_weight2(103,1)+total_weight2(105,1)+total_weight2(107,1)+total_weight2(108,1)+total_weight2(109,1)+total_weight2(114,1)+total_weight2(115,1)+total_weight2(117,1)+total_weight2(119,1)+total_weight2(123,1)+total_weight2(125,1)+total_weight2(128,1))*1/(total_gen(1,1)+total_gen(2,1)+total_gen(4,1)+total_gen(5,1)+total_gen(6,1)+total_gen(8,1)+total_gen(10,1)+total_gen(11,1)+total_gen(12,1)+total_gen(14,1)+total_gen(15,1)+total_gen(17,1)+total_gen(18,1)+total_gen(23,1)+total_gen(27,1)+total_gen(29,1)+total_gen(34,1)+total_gen(35,1)+total_gen(36,1)+total_gen(37,1)+total_gen(41,1)+total_gen(44,1)+total_gen(45,1)+total_gen(46,1)+total_gen(47,1)+total_gen(49,1)+total_gen(53,1)+total_gen(54,1)+total_gen(55,1)+total_gen(56,1)+total_gen(57,1)+total_gen(58,1)+total_gen(59,1)+total_gen(60,1)+total_gen(62,1)+total_gen(63,1)+total_gen(65,1)+total_gen(67,1)+total_gen(68,1)+total_gen(69,1)+total_gen(71,1)+total_gen(72,1)+total_gen(73,1)+total_gen(75,1)+total_gen(80,1)+total_gen(84,1)+total_gen(91,1)+total_gen(94,1)+total_gen(95,1)+total_gen(96,1)+total_gen(99,1)+total_gen(100,1)+total_gen(101,1)+total_gen(102,1)+total_gen(103,1)+total_gen(105,1)+total_gen(107,1)+total_gen(108,1)+total_gen(109,1)+total_gen(114,1)+total_gen(115,1)+total_gen(117,1)+total_gen(119,1)+total_gen(123,1)+total_gen(125,1)+total_gen(128,1));
asia_paci_LT_weighted_average=(total_weight2(2,1)+total_weight2(9,1)+total_weight2(14,1)+total_weight2(55,1)+total_weight2(57,1)+total_weight2(63,1)+total_weight2(65,1)+total_weight2(69,1)+total_weight2(71,1)+total_weight2(80,1)+total_weight2(84,1)+total_weight2(86,1)+total_weight2(94,1)+total_weight2(95,1)+total_weight2(115,1)+total_weight2(125,1))*1/(total_gen(2,1)+total_gen(9,1)+total_gen(14,1)+total_gen(55,1)+total_gen(57,1)+total_gen(63,1)+total_gen(65,1)+total_gen(69,1)+total_gen(71,1)+total_gen(80,1)+total_gen(84,1)+total_gen(86,1)+total_gen(94,1)+total_gen(95,1)+total_gen(115,1)+total_gen(125,1));
asia_southeast_LT_weighted_average=(total_weight2(55,1)+total_weight2(65,1)+total_weight2(69,1)+total_weight2(84,1)+total_weight2(94,1)+total_weight2(115,1)+total_weight2(125,1))*1/(total_gen(55,1)+total_gen(65,1)+total_gen(69,1)+total_gen(84,1)+total_gen(94,1)+total_gen(115,1)+total_gen(125,1));

EU_LT_yr_weighted_average=(total_weight3(9,1)+total_weight3(17,1)+total_weight3(36,1)+total_weight3(37,1)+total_weight3(44,1)+total_weight3(45,1)+total_weight3(54,1)+total_weight3(60,1)+total_weight3(96,1)+total_weight3(99,1)+total_weight3(109,1))*1/(total_gen2(9,1)+total_gen2(17,1)+total_gen2(36,1)+total_gen2(37,1)+total_gen2(44,1)+total_gen2(45,1)+total_gen2(54,1)+total_gen2(60,1)+total_gen2(96,1)+total_gen2(99,1)+total_gen2(109,1));
North_am_LT_yr_weighted_average=(total_weight3(13,1)+total_weight3(24,1)+total_weight3(25,1)+total_weight3(31,1)+total_weight3(32,1)+total_weight3(38,1)+total_weight3(50,1)+total_weight3(52,1)+total_weight3(61,1)+total_weight3(70,1)+total_weight3(89,1)+total_weight3(113,1)+total_weight3(121,1))*1/(total_gen2(13,1)+total_gen2(24,1)+total_gen2(25,1)+total_gen2(31,1)+total_gen2(32,1)+total_gen2(38,1)+total_gen2(50,1)+total_gen2(52,1)+total_gen2(61,1)+total_gen2(70,1)+total_gen2(89,1)+total_gen2(113,1)+total_gen2(121,1));
central_south_am_LT_yr_weighted_average=(total_weight3(7,1)+total_weight3(20,1)+total_weight3(21,1)+total_weight3(24,1)+total_weight3(28,1)+total_weight3(30,1)+total_weight3(31,1)+total_weight3(40,1)+total_weight3(50,1)+total_weight3(52,1)+total_weight3(83,1)+total_weight3(89,1)+total_weight3(92,1)+total_weight3(93,1)+total_weight3(112,1)+total_weight3(122,1))*1/(total_gen2(7,1)+total_gen2(20,1)+total_gen2(21,1)+total_gen2(24,1)+total_gen2(28,1)+total_gen2(30,1)+total_gen2(31,1)+total_gen2(40,1)+total_gen2(50,1)+total_gen2(52,1)+total_gen2(83,1)+total_gen2(89,1)+total_gen2(92,1)+total_gen2(93,1)+total_gen2(112,1)+total_gen2(122,1));
% Europe_LT_yr=(total_weight3(4,1)+total_weight3(8,1)+total_weight3(12,1)+total_weight3(15,1)+total_weight3(17,1)+total_weight3(23,1)+total_weight3(27,1)+total_weight3(34,1)+total_weight3(35,1)+total_weight3(36,1)+total_weight3(37,1)+total_weight3(41,1)+total_weight3(44,1)+total_weight3(45,1)+total_weight3(46,1)+total_weight3(47,1)+total_weight3(49,1)+total_weight3(53,1)+total_weight3(54,1)+total_weight3(60,1)+total_weight3(72,1)+total_weight3(73,1)+total_weight3(75,1)+total_weight3(90,1)+total_weight3(96,1)+total_weight3(99,1)+total_weight3(101,1)+total_weight3(102,1)+total_weight3(103,1)+total_weight3(107,1)+total_weight3(108,1)+total_weight3(109,1)+total_weight3(117,1)+total_weight3(119,1)+total_weight3(127,1))/(total_gen2(4,1)+total_gen2(8,1)+total_gen2(12,1)+total_gen2(15,1)+total_gen2(17,1)+total_gen2(23,1)+total_gen2(27,1)+total_gen2(34,1)+total_gen2(35,1)+total_gen2(36,1)+total_gen2(37,1)+total_gen2(41,1)+total_gen2(44,1)+total_gen2(45,1)+total_gen2(46,1)+total_gen2(47,1)+total_gen2(49,1)+total_gen2(53,1)+total_gen2(54,1)+total_gen2(60,1)+total_gen2(72,1)+total_gen2(73,1)+total_gen2(75,1)+total_gen2(90,1)+total_gen2(96,1)+total_gen2(99,1)+total_gen2(101,1)+total_gen2(102,1)+total_gen2(103,1)+total_gen2(107,1)+total_gen2(108,1)+total_gen2(109,1)+total_gen2(117,1)+total_gen2(119,1)+total_gen2(127,1));
africa_LT_yr_weighted_average=(total_weight3(6,1)+total_weight3(16,1)+total_weight3(19,1)+total_weight3(22,1)+total_weight3(33,1)+total_weight3(39,1)+total_weight3(42,1)+total_weight3(43,1)+total_weight3(48,1)+total_weight3(64,1)+total_weight3(74,1)+total_weight3(76,1)+total_weight3(78,1)+total_weight3(81,1)+total_weight3(82,1)+total_weight3(85,1)+total_weight3(87,1)+total_weight3(88,1)+total_weight3(104,1)+total_weight3(106,1)+total_weight3(110,1)+total_weight3(111,1)+total_weight3(116,1)+total_weight3(120,1)+total_weight3(129,1)+total_weight3(130,1))*1/(total_gen2(6,1)+total_gen2(16,1)+total_gen2(19,1)+total_gen2(22,1)+total_gen2(33,1)+total_gen2(39,1)+total_gen2(42,1)+total_gen2(43,1)+total_gen2(48,1)+total_gen2(64,1)+total_gen2(74,1)+total_gen2(76,1)+total_gen2(78,1)+total_gen2(81,1)+total_gen2(82,1)+total_gen2(85,1)+total_gen2(87,1)+total_gen2(88,1)+total_gen2(104,1)+total_gen2(106,1)+total_gen2(110,1)+total_gen2(111,1)+total_gen2(116,1)+total_gen2(120,1)+total_gen2(129,1)+total_gen2(130,1));
middle_east_LT_yr_weighted_average=(total_weight3(1,1)+total_weight3(18,1)+total_weight3(34,1)+total_weight3(42,1)+total_weight3(56,1)+total_weight3(58,1)+total_weight3(59,1)+total_weight3(62,1)+total_weight3(67,1)+total_weight3(91,1)+total_weight3(100,1)+total_weight3(105,1)+total_weight3(114,1)+total_weight3(117,1)+total_weight3(128,1))*1/(total_gen2(1,1)+total_gen2(18,1)+total_gen2(34,1)+total_gen2(42,1)+total_gen2(56,1)+total_gen2(58,1)+total_gen2(59,1)+total_gen2(62,1)+total_gen2(67,1)+total_gen2(91,1)+total_gen2(100,1)+total_gen2(105,1)+total_gen2(114,1)+total_gen2(117,1)+total_gen2(128,1));
eurasia_LT_yr_weighted_average=(total_weight3(1,1)+total_weight3(2,1)+total_weight3(4,1)+total_weight3(5,1)+total_weight3(6,1)+total_weight3(8,1)+total_weight3(10,1)+total_weight3(11,1)+total_weight3(12,1)+total_weight3(14,1)+total_weight3(15,1)+total_weight3(17,1)+total_weight3(18,1)+total_weight3(23,1)+total_weight3(27,1)+total_weight3(29,1)+total_weight3(34,1)+total_weight3(35,1)+total_weight3(36,1)+total_weight3(37,1)+total_weight3(41,1)+total_weight3(44,1)+total_weight3(45,1)+total_weight3(46,1)+total_weight3(47,1)+total_weight3(49,1)+total_weight3(53,1)+total_weight3(54,1)+total_weight3(55,1)+total_weight3(56,1)+total_weight3(57,1)+total_weight3(58,1)+total_weight3(59,1)+total_weight3(60,1)+total_weight3(62,1)+total_weight3(63,1)+total_weight3(65,1)+total_weight3(67,1)+total_weight3(68,1)+total_weight3(69,1)+total_weight3(71,1)+total_weight3(72,1)+total_weight3(73,1)+total_weight3(75,1)+total_weight3(80,1)+total_weight3(84,1)+total_weight3(91,1)+total_weight3(94,1)+total_weight3(95,1)+total_weight3(96,1)+total_weight3(99,1)+total_weight3(100,1)+total_weight3(101,1)+total_weight3(102,1)+total_weight3(103,1)+total_weight3(105,1)+total_weight3(107,1)+total_weight3(108,1)+total_weight3(109,1)+total_weight3(114,1)+total_weight3(115,1)+total_weight3(117,1)+total_weight3(119,1)+total_weight3(123,1)+total_weight3(125,1)+total_weight3(128,1))*1/(total_gen2(1,1)+total_gen2(2,1)+total_gen2(4,1)+total_gen2(5,1)+total_gen2(6,1)+total_gen2(8,1)+total_gen2(10,1)+total_gen2(11,1)+total_gen2(12,1)+total_gen2(14,1)+total_gen2(15,1)+total_gen2(17,1)+total_gen2(18,1)+total_gen2(23,1)+total_gen2(27,1)+total_gen2(29,1)+total_gen2(34,1)+total_gen2(35,1)+total_gen2(36,1)+total_gen2(37,1)+total_gen2(41,1)+total_gen2(44,1)+total_gen2(45,1)+total_gen2(46,1)+total_gen2(47,1)+total_gen2(49,1)+total_gen2(53,1)+total_gen2(54,1)+total_gen2(55,1)+total_gen2(56,1)+total_gen2(57,1)+total_gen2(58,1)+total_gen2(59,1)+total_gen2(60,1)+total_gen2(62,1)+total_gen2(63,1)+total_gen2(65,1)+total_gen2(67,1)+total_gen2(68,1)+total_gen2(69,1)+total_gen2(71,1)+total_gen2(72,1)+total_gen2(73,1)+total_gen2(75,1)+total_gen2(80,1)+total_gen2(84,1)+total_gen2(91,1)+total_gen2(94,1)+total_gen2(95,1)+total_gen2(96,1)+total_gen2(99,1)+total_gen2(100,1)+total_gen2(101,1)+total_gen2(102,1)+total_gen2(103,1)+total_gen2(105,1)+total_gen2(107,1)+total_gen2(108,1)+total_gen2(109,1)+total_gen2(114,1)+total_gen2(115,1)+total_gen2(117,1)+total_gen2(119,1)+total_gen2(123,1)+total_gen2(125,1)+total_gen2(128,1));
asia_paci_LT_yr_weighted_average=(total_weight3(2,1)+total_weight3(9,1)+total_weight3(14,1)+total_weight3(55,1)+total_weight3(57,1)+total_weight3(63,1)+total_weight3(65,1)+total_weight3(69,1)+total_weight3(71,1)+total_weight3(80,1)+total_weight3(84,1)+total_weight3(86,1)+total_weight3(94,1)+total_weight3(95,1)+total_weight3(115,1)+total_weight3(125,1))*1/(total_gen2(2,1)+total_gen2(9,1)+total_gen2(14,1)+total_gen2(55,1)+total_gen2(57,1)+total_gen2(63,1)+total_gen2(65,1)+total_gen2(69,1)+total_gen2(71,1)+total_gen2(80,1)+total_gen2(84,1)+total_gen2(86,1)+total_gen2(94,1)+total_gen2(95,1)+total_gen2(115,1)+total_gen2(125,1));
asia_southeast_LT_yr_weighted_average=(total_weight3(55,1)+total_weight3(65,1)+total_weight3(69,1)+total_weight3(84,1)+total_weight3(94,1)+total_weight3(115,1)+total_weight3(125,1))*1/(total_gen2(55,1)+total_gen2(65,1)+total_gen2(69,1)+total_gen2(84,1)+total_gen2(94,1)+total_gen2(115,1)+total_gen2(125,1));



%%%%aggregate data in one table

Regions = {'World'; 'North America'; 'Central and south America'; ...
           'Europe'; 'Africa'; 'Middle East'; 'Eurasia'; 'Asia Pacific'};

Data = [ ...
    world_LUE_normal_avg, World_LUE_weighted_average, world_LUE_SD, world_LUE_25, world_LUE_50, world_LUE_75, ...
    world_LT_normal_avg, World_LT_weighted_average, world_LT_SD, world_LT_25, world_LT_50, world_LT_75, ...
    world_LT_yr_normal_avg, World_LT_yr_weighted_average, world_LT_yr_SD, world_LT_yr_25, world_LT_yr_50, world_LT_yr_75;

    North_am_LUE_normal_avg, North_am_LUE_weighted_average, North_am_LUE_SD, North_am_LUE_25, North_am_LUE_50, North_am_LUE_75, ...
    North_am_LT_normal_avg, North_am_LT_weighted_average, North_am_LT_SD, North_am_LT_25, North_am_LT_50, North_am_LT_75, ...
    North_am_LT_yr_normal_avg, North_am_LT_yr_weighted_average, North_am_LT_yr_SD, North_am_LT_yr_25, North_am_LT_yr_50, North_am_LT_yr_75;

    central_south_am_LUE_normal_avg, central_south_am_LUE_weighted_average, central_south_am_LUE_SD, central_south_am_LUE_25, central_south_am_LUE_50, central_south_am_LUE_75, ...
    central_south_am_LT_normal_avg, central_south_am_LT_weighted_average, central_south_am_LT_SD, central_south_am_LT_25, central_south_am_LT_50, central_south_am_LT_75, ...
    central_south_am_LT_yr_normal_avg, central_south_am_LT_yr_weighted_average, central_south_am_LT_yr_SD, central_south_am_LT_yr_25, central_south_am_LT_yr_50, central_south_am_LT_yr_75;

    EUROPE_LUE_normal_avg, EUROPE_LUE_weighted_average, EUROPE_LUE_SD, EUROPE_LUE_25, EUROPE_LUE_50, EUROPE_LUE_75, ...
    EUROPE_LT_normal_avg, EUROPE_LT_weighted_average, EUROPE_LT_SD, EUROPE_LT_25, EUROPE_LT_50, EUROPE_LT_75, ...
    EUROPE_LT_yr_normal_avg, EUROPE_LT_yr_weighted_average, EUROPE_LT_yr_SD, EUROPE_LT_yr_25, EUROPE_LT_yr_50, EUROPE_LT_yr_75;

    africa_LUE_normal_avg, africa_LUE_weighted_average, africa_LUE_SD, africa_LUE_25, africa_LUE_50, africa_LUE_75, ...
    africa_LT_normal_avg, africa_LT_weighted_average, africa_LT_SD, africa_LT_25, africa_LT_50, africa_LT_75, ...
    africa_LT_yr_normal_avg, africa_LT_yr_weighted_average, africa_LT_yr_SD, africa_LT_yr_25, africa_LT_yr_50, africa_LT_yr_75;

    middle_east_LUE_normal_avg, middle_east_LUE_weighted_average, middle_east_LUE_SD, middle_east_LUE_25, middle_east_LUE_50, middle_east_LUE_75, ...
    middle_east_LT_normal_avg, middle_east_LT_weighted_average, middle_east_LT_SD, middle_east_LT_25, middle_east_LT_50, middle_east_LT_75, ...
    middle_east_LT_yr_normal_avg, middle_east_LT_yr_weighted_average, middle_east_LT_yr_SD, middle_east_LT_yr_25, middle_east_LT_yr_50, middle_east_LT_yr_75;

    eurasia_LUE_normal_avg, eurasia_LUE_weighted_average, eurasia_LUE_SD, eurasia_LUE_25, eurasia_LUE_50, eurasia_LUE_75, ...
    eurasia_LT_normal_avg, eurasia_LT_weighted_average, eurasia_LT_SD, eurasia_LT_25, eurasia_LT_50, eurasia_LT_75, ...
    eurasia_LT_yr_normal_avg, eurasia_LT_yr_weighted_average, eurasia_LT_yr_SD, eurasia_LT_yr_25, eurasia_LT_yr_50, eurasia_LT_yr_75;

    asia_paci_LUE_normal_avg, asia_paci_LUE_weighted_average, asia_paci_LUE_SD, asia_paci_LUE_25, asia_paci_LUE_50, asia_paci_LUE_75, ...
    asia_paci_LT_normal_avg, asia_paci_LT_weighted_average, asia_paci_LT_SD, asia_paci_LT_25, asia_paci_LT_50, asia_paci_LT_75, ...
    asia_paci_LT_yr_normal_avg, asia_paci_LT_yr_weighted_average, asia_paci_LT_yr_SD, asia_paci_LT_yr_25, asia_paci_LT_yr_50, asia_paci_LT_yr_75
];

% Turn into table
colNames = {'LUE_normal_avg','LUE_weighted_average','LUE_SD','LUE_25','LUE_50','LUE_75', ...
            'LT_normal_avg','LT_weighted_average','LT_SD','LT_25','LT_50','LT_75', ...
            'LT_yr_normal_avg','LT_yr_weighted_average','LT_yr_SD','LT_yr_25','LT_yr_50','LT_yr_75'};
ResultTable = array2table(Data, 'RowNames', Regions, 'VariableNames', colNames);

% Export if needed
writetable(ResultTable,'Regional_Aggregated.xlsx','WriteRowNames',true);

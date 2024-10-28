function area_integral=get_integral_of_selection(BW,maptoget)
%returns area integral value of selected area
non_masked_area = extract.get_area_of_selection(BW,maptoget,0);
area_integral = non_masked_area * mean((maptoget(BW==1 & ~isnan(maptoget))),'omitnan');


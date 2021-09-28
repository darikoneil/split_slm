function f_sg_xyz_button_add_to_holo(app)

tab_data = app.UIImagePhaseTable.Data.Variables;

if isempty(tab_data)
    idx = 1;
else
    idx = size(tab_data,1)+1;
    tab_data(:,1) = 1:(idx-1);
end

coord = f_sg_mpl_get_coords(app, 'custom');

app.UIImagePhaseTable.Data = array2table([tab_data;...
                                        idx,...
                                        app.PatternnumberEditField.Value,...
                                        coord.xyzp(1),...
                                        coord.xyzp(2),...
                                        coord.xyzp(3)/1e-6,...
                                        coord.weight]);
                                    
end
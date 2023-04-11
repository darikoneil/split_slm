% fitting gaussian for each dimension

clear;
%close all;


data_source = 2;

if data_source == 1
    data_path = 'C:\Users\ys2605\Desktop\stuff\data\ETL_data\etl_psf_prairie1\3_28_23\';
    data_path2 = {'z100_20um_256_32ave-003',...
                  'z50_20um_256_32ave-002',...
                  'z0_20um_256_32ave-001',...
                  'z-50_20um_256_32ave-005',...
                  'z-100_20um_256_32ave-007'};
    z_loc = [100, 50, 0, -50, -100];
    description = 'EL-10-30-C';

elseif data_source == 2
    data_path = 'C:\Users\ys2605\Desktop\stuff\data\ETL_data\4_10_23\PSF_prairie2_25X_no_orb_ETLobj\';  
    data_path2 = {'PSF_ETLp2_25x_16z_01um_256_z150-006',...
                  'PSF_ETLp2_25x_16z_01um_256_z100-005',...
                  'PSF_ETLp2_25x_16z_01um_256_z50-004',...
                  'PSF_ETLp2_25x_16z_01um_256_z0-003',...
                  'PSF_ETLp2_25x_16z_01um_256_z-50-007',...
                  'PSF_ETLp2_25x_16z_01um_256_z-100-008',...
                  'PSF_ETLp2_25x_16z_01um_256_z-150-009'};
    z_loc = [150, 100, 50, 0, -50, -100, -150];
    description = 'EL-16-40-TC:Obj'; 
elseif data_source == 3
    data_path = 'C:\Users\ys2605\Desktop\stuff\data\ETL_data\4_10_23\PSF_prairie2_25x_no_orb\';
    data_path2 = {'PSF_25x_16z_01um_256-001',...
                  'PSF_25x_16z_01um_256-002'};
              
    z_loc = [0, 0];
    description = 'Regular path';
end

%%
FOV_size = 497; % in um (from prairie2 25x no orb)
pix = 256;
zoom = 16;
dz = 0.1; % in um

FOV_half_size = 20;

pix_size = FOV_size/zoom/pix;

do_mean = 0;

labs = {'y', 'x', 'z'};

manual_selection = 0;

dims_all = 1:3;
%%

plot_deets = 0;
plot_superdeets = 0;

num_fil = numel(data_path2);

points_all = cell(num_fil,1);
fwhm_all = cell(num_fil,1);
intensity_5pct = cell(num_fil,1);
intensity_mean_max_max = cell(num_fil,1);

z_loc2 = unique(z_loc);
num_loc = numel(z_loc2);

for n_loc = 1:num_loc
    
    
    fil_idx = find(z_loc == z_loc2(n_loc));
    
    num_fil = numel(fil_idx);
    points_all2 = {};
    PSF_all = {};
    for n_fil = 1:num_fil
        n_fil2 = fil_idx(n_fil);
        data = f_collect_prairie_tiffs4([data_path, data_path2{n_fil2}]);

        [x1, y1, z1] = size(data);
        
        pts2 = {};
        if manual_selection
            f1 = figure; 
            imagesc(mean(data,3))
            title('click to select psf');

            [x,y] = ginput(1);
            close(f1)

            points_all2 = {points_all2; [round(y), round(x)]};
        else
            mean_frame = mean(data,3);

            base = mean(mean_frame(:));
            std1 = std(mean_frame(:));

            mean_frame2 = mean_frame;
            look = 1;
            while look
                [val1, idx1] = max(mean_frame2(:));
                if val1 > (base + 5*std1)
                    [y_coord, x_coord] = ind2sub([x1, y1], idx1);

                    z_lice = data(y_coord, x_coord,:);

                    [~, idx1]  = max(z_lice);

                    % check if peak is far from center
                    y_min = max(y_coord - FOV_half_size, 1);
                    y_max = min(y_coord + FOV_half_size, y1);
                    x_min = max(x_coord - FOV_half_size, 1);
                    x_max = min(x_coord + FOV_half_size, x1);
                    if min([idx1, z1 - idx1]) > z1/4
                        % check if far from edge
                        if min([y_coord, y1 - y_coord]) > FOV_half_size
                            if min([x_coord, x1 - x_coord]) > FOV_half_size
                                points_all2 = [points_all2; [y_coord, x_coord]];
                                pts2 = [pts2; [y_coord, x_coord]];
                                PSF_all = [PSF_all; double(data(y_min:y_max, x_min:x_max,:))];
                            end
                        end
                    end
                    
                    mean_frame2(y_min:y_max, x_min:x_max) = 0;
                else
                    look = 0;
                end
            end

        end
        num_pts2 = numel(pts2);
        figure; 
        imagesc(mean_frame); hold on;
        for n_pt = 1:num_pts2
            rectangle('Position',[pts2{n_pt}(2) - FOV_half_size, pts2{n_pt}(1) - FOV_half_size, 2*FOV_half_size+1, 2*FOV_half_size+1])
        end
        title(sprintf('selected points, z=%d; data %d', z_loc(n_loc), n_fil));

    end
    
    num_pts = numel(points_all2);

    fwhm_all2 = zeros(num_pts,3);
    intensity_5pct2 = zeros(num_pts,1);
    intensity_mean_max_max2 = zeros(num_pts,1);
    for n_pt = 1:num_pts

        data2 = PSF_all{n_pt};

        baseline = median(reshape(mean(data,3),1,[]));

        data3 = data2 - baseline;

        x = (-FOV_half_size:FOV_half_size)'*pix_size;
        y = (-FOV_half_size:FOV_half_size)'*pix_size;
        z = linspace(-z1/2, z1/2, z1)'*dz;
        ax3 = {y, x, z};
        
        if plot_deets
            [x3, y3 ,z3] = meshgrid(x, y, z);
            figure;
            slice(x3, y3, z3, data3, 0, 0, 0);
        end
        
        fwhm_3d = zeros(3, 3);
        intens1 = zeros(3, 3);
        for n_d = 1:3

            dims2 = dims_all(dims_all ~= n_d);

            data_marg = mean(data3,n_d);

            if plot_deets
                figure();
                imagesc(ax3{dims2(1)}, ax3{dims2(2)}, squeeze(data_marg))
                title(sprintf('dims %d, %d', dims2(1), dims2(2)))
                axis equal tight;
                xlabel([labs{dims2(1)} ' axis'])
                ylabel([labs{dims2(2)} ' axis'])
                title(sprintf('z %d', z_loc(n_loc)));
            end

            for n_d2 = 1:2
                d2 = dims2(n_d2);
                d3 = dims2(dims2~=d2);

                x2 = squeeze(ax3{d3});
                if do_mean
                    data_marg2 = squeeze(permute(mean(data_marg, d2), [d3, d2]));
                    tag1 = 'mean';
                else
                    data_marg3 = squeeze(mean(data_marg, d3));
                    [~, idx1] = max(data_marg3);
                    data_marg4 = permute(data_marg, [d2, d3, n_d]);
                    data_marg2 = data_marg4(idx1,:)';
                    tag1 = 'peak';
                end

                % fwhm = 2*sqrt(2*log(2)) * std
                % f(x) =  a1*exp(-((x-b1)/c1)^2)
                f = fit(x2, data_marg2, 'gauss1');
                fwhm1 = 2*sqrt(2*log(2)) * (f.c1/sqrt(2));
                fwhm_3d(n_d, d3) = fwhm1;

                intens1(n_d, d3) = f.a1;

                if plot_superdeets
                    figure; hold on;
                    plot(x2, data_marg2);
                    line([f.b1 - fwhm1/2, f.b1 + fwhm1/2], [f.a1/2, f.a1/2], 'color', 'k')
                    legend('data', 'fwhm');
                    plot(f);
                    title(sprintf('z %d; dim %d %s; fwhm=%.2f', z_loc(n_loc), d3, tag1, fwhm1));
                    xlabel(labs{d3});
                    ylabel('intensity');
                end
            end
        end

        fwhm_all2(n_pt, :) = sum(fwhm_3d,1)/2;

        val1 = prctile(data2(:), 99);
        intensity_5pct2(n_pt) = mean(data2(data2>val1));
        intensity_mean_max_max2(n_pt) = sum(intens1(:))/6;
        
    end
    points_all{n_loc} = points_all2;
    fwhm_all{n_loc} = fwhm_all2;
    intensity_5pct{n_loc} = intensity_5pct2;
    intensity_mean_max_max{n_loc} = intensity_mean_max_max2;
end

%%

means = zeros(num_loc, 3);
sems = zeros(num_loc, 3);
for n_loc = 1:num_loc
    num_pts = size(fwhm_all{n_loc},1);
    means(n_loc,:) = mean(fwhm_all{n_loc},1);
    sems(n_loc,:) = std(fwhm_all{n_loc}, [], 1)/max(sqrt(num_pts-1),1);
end

colors1 = {'#0072BD' , '#D95319', '#EDB120'};
figure; hold on
for n_d = 1:3
    plot(z_loc2, means(:,n_d), '.-', 'color', colors1{n_d});
end
for n_d = 1:3
    errorbar(z_loc2, means(:,n_d), sems(:,n_d), 'color', colors1{n_d});
end
legend(labs);

title([description ' resolution']);
xlabel('z offset (um)');
ylabel('PSF size (um)');


%%
data_fwhm.fwhm = fwhm_all;
data_fwhm.points_all = points_all;
data_fwhm.intensity_5pct = intensity_5pct;
data_fwhm.intensity_mean_max_max = intensity_mean_max_max;
data_fwhm.axes = labs;
data_fwhm.z_loc = z_loc;
data_fwhm.z_loc_unique = z_loc2;
data_fwhm.fnames = data_path2;
data_fwhm.FOV_size = FOV_size; % in um
data_fwhm.FOV_half_size = FOV_half_size;
data_fwhm.pix = pix;
data_fwhm.zoom = zoom;
data_fwhm.dz = dz; 
data_fwhm.dxy = pix_size;
data_fwhm.description = description;

date1 = datetime;
save(sprintf('%s\\psf_data_ETLp2_%d_%d_%d', data_path, date1.Year, date1.Month, date1.Day), 'data_fwhm');

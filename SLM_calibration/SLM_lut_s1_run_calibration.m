%% Script for getting data for calibration lut
% can either use TDLC and grab frames or wait for trigger with some other method
% start by running the global calibration
% if need regional, use previos global for blaze deflect blank

% lut pipeline step 1/3

%% Parameters
ops.use_TLDC = 1;           % otherwise wait for trigger
ops.use_DAQ = 0;
ops.plot_phase = 1;

ops.NumGray = 256;          % bit depth
ops.NumRegions = 1;        % (squares only [1,4,9,16...])
ops.PixelsPerStripe = 8;	
ops.PixelValue = 0;

%ops.lut_fname = 'linear.lut'; %;
%ops.lut_fname = 'slm5221_at940_fo_1r_11_5_20.lut'; %'linear.lut';
ops.lut_fname = 'slm5221_at1064_fo_1r_11_5_20.lut'; %'linear.lut';

slm_roi = 'full'; % 'full' 'left_half'(1064) 'right_half'(940)

%%
save_pref = '940_slm5221_maitai';
%save_pref = '1064_slm5221_fianium';
%%
blaze_deflect_blank = 0;
blaze_period = 50;
blaze_increaseing = 0;
blaze_horizontal = 1;
bkg_lut_fname = 'computed_lut_940_slm5221_maitai_1r_11_03_20_14h_39m_fo.mat';

%% add paths
ops.working_dir = fileparts(which('SLM_lut_calibrationTLDC.m'));
addpath([ops.working_dir '\..\']);
addpath([ops.working_dir '\..\SLM_GUI_funcions']);

ops.time_stamp = sprintf('%s_%sh_%sm',datestr(now,'mm_dd_yy'),datestr(now,'HH'),datestr(now,'MM'));
ops.save_path = [ops.working_dir '\..\..\SLM_outputs\lut_calibration'];
ops.save_file_name = sprintf('%s\\lut_%s_%dr_%s.mat',ops.save_path, save_pref,ops.NumRegions, ops.time_stamp);
ops.save_file_name_im = sprintf('%s\\lut_images_%s_%dr_%s.mat',ops.save_path, save_pref,ops.NumRegions, ops.time_stamp);
if ~exist(ops.save_path, 'dir')
    mkdir(ops.save_path);
end

%%
if blaze_deflect_blank
    lut_path = [ops.working_dir '\lut_calibration\' bkg_lut_fname];
    lut_load = load(lut_path);
    LUT_conv = lut_load.LUT_conv;
    LUT_conv = round(LUT_conv);
end

%%
regions = (1:ops.NumRegions)-1;

if numel(regions) > 1
    if strcmpi(slm_roi, 'full')
        regions_run = regions;
    elseif strcmpi(slm_roi, 'left_half')
        [rows, cols] = ind2sub([sqrt(numel(regions)) sqrt(numel(regions))], 1:numel(regions));
        ind1 = sub2ind([sqrt(numel(regions)) sqrt(numel(regions))], cols(cols<=(max(cols)/2)), rows(cols<=(max(cols)/2)));
        regions_run = sort(regions(ind1));
    elseif strcmpi(slm_roi, 'right_half')
        [rows, cols] = ind2sub([sqrt(numel(regions)) sqrt(numel(regions))], 1:numel(regions));
        ind1 = sub2ind([sqrt(numel(regions)) sqrt(numel(regions))], cols(cols>(max(cols)/2)), rows(cols<=(max(cols)/2)));
        regions_run = sort(regions(ind1));
    end
else
    regions_run = regions;
end

%% Initialize SLM
try %#ok<*TRYNC>
    f_SLM_BNS_close(ops);
end
ops = f_SLM_BNS_initialize(ops);

%%
cont1 = input('Turn laser on and reply [y] to continue:', 's');

%%
if ops.use_TLDC
    try
        TLDC_set_Cam_Close(cam_out.hdl_cam);
    end
    [cam_out, ops.cam_params] = f_TLDC_initialize(ops);
end

if ops.use_DAQ
    % Setup counter
    session = daq.createSession('ni');
    session.addCounterInputChannel(app.NIDAQdeviceEditField.Value, 'ctr0', 'EdgeCount');
    resetCounters(session);
end


%% create gratings and upload
if ops.SDK_created == 1 && strcmpi(cont1, 'y')
    region_gray = zeros(ops.NumGray*numel(regions_run),2);
    
    %allocate arrays for our images
    SLM_image = libpointer('uint8Ptr', zeros(ops.width*ops.height,1));
    calllib('ImageGen', 'Generate_Solid', SLM_image, ops.width, ops.height, ops.PixelValue);
    f_SLM_BNS_update(ops, SLM_image);
    
    SLM_mask = libpointer('uint8Ptr', zeros(ops.width*ops.height,1));
    calllib('ImageGen', 'Generate_Solid', SLM_mask, ops.width, ops.height, 1);
	
    if ops.plot_phase
        SLM_fig = figure;
        SLM_im = imagesc(reshape(SLM_image.Value, ops.width, ops.height)');
        caxis([0 255]);
        SLM_fig.Children.Title.String = 'SLM phase';
    end
    
    if ops.use_TLDC
        calib_im_series = zeros(size(cam_out.cam_frame,1), size(cam_out.cam_frame,2), ops.NumGray*numel(regions_run), 'uint8');
        cam_fig = figure;
        cam_im = imagesc(cam_out.cam_frame');
        %caxis([1 256]);
        cam_fig.Children.Title.String = 'Camera';
    end
    
    if ~ops.use_TLDC
        frame_start_times = zeros(ops.NumGray*numel(regions_run),1);
        SLM_frame = 1;
        tic;
    end
    
    if blaze_deflect_blank
        pointer_bkg = libpointer('uint8Ptr', zeros(ops.width*ops.height,1));
        calllib('ImageGen', 'Generate_Grating',...
                pointer_bkg,...
                ops.width, ops.height,...
                blaze_period,...
                blaze_increaseing,...
                blaze_horizontal);
        
        pointer_bkg.Value = LUT_conv(pointer_bkg.Value+1,2);
    end
    
    n_idx = 1;
    %loop through each region
    for Region = regions_run
        for Gray = 0:(ops.NumGray-1)
            
            region_gray(n_idx,:) = [Region, Gray];

            %Generate the stripe pattern and mask out current region
            calllib('ImageGen', 'Generate_Stripe', SLM_image, ops.width, ops.height, ops.PixelValue, Gray, ops.PixelsPerStripe);
            calllib('ImageGen', 'Mask_Image', SLM_image, ops.width, ops.height, Region, ops.NumRegions); % 
            
            % update mask
            calllib('ImageGen', 'Generate_Solid', SLM_mask, ops.width, ops.height, 1);
            calllib('ImageGen', 'Mask_Image', SLM_mask, ops.width, ops.height, Region, ops.NumRegions); % 
            
            if blaze_deflect_blank
                SLM_image.Value(~logical(SLM_mask.Value)) = pointer_bkg.Value(~logical(SLM_mask.Value));
            end
            if ops.use_DAQ
                % wait for counter
                imaging = 1;
                while imaging
                    scan_frame = inputSingleScan(session)+1;
                    if scan_frame > SLM_frame
                        f_SLM_BNS_update(ops, SLM_image);
                        frame_start_times(scan_frame) = toc;
                        SLM_frame = scan_frame;
                        if scan_frame > ops.NumGray*numel(regions_run)
                            imaging = 0;
                        end
                    end

                    if (toc -  frame_start_times(scan_frame)) > 15
                        pause(0.0001);
                        if ~imaging_button.Value
                            imaging = 0;
                            disp(['Aborted trigger wait frame ' num2str(SLM_frame)]);
                        end
                    end
                end
            end
            
            if ops.use_TLDC   % Thorlabs camera
                f_SLM_BNS_update(ops, SLM_image);
                pause(0.01); %let the SLM settle for 10 ms
                TLDC_get_Cam_Im(cam_out.hdl_cam);
                cam_im.CData = cam_out.cam_frame';
                calib_im_series(:,:,n_idx) = (cam_out.cam_frame);
                cam_fig.Children.Title.String = sprintf('Gray %d/%d; Region %d/%d', Gray+1,ops.NumGray,Region+1,numel(regions_run));
                pause(.2);
            end
            
            if ops.plot_phase
                SLM_im.CData = reshape(SLM_image.Value, ops.width, ops.height)';
                SLM_fig.Children.Title.String = sprintf('Gray %d/%d; Region %d/%d', Gray+1,ops.NumGray,Region+1,numel(regions_run));
                drawnow;
                %figure; imagesc(reshape(SLM_image.Value, ops.width, ops.height)')
            end
            
            n_idx = n_idx + 1;
        end
    end
    calllib('ImageGen', 'Generate_Solid', SLM_image, ops.width, ops.height, ops.PixelValue);
    f_SLM_BNS_update(ops, SLM_image);
    
    save(ops.save_file_name, 'region_gray', 'ops', '-v7.3');
    if ops.use_TLDC
        save(ops.save_file_name_im, 'calib_im_series', '-v7.3');
    end
end

%% close SLM

cont1 = input('Done, turnb off laser and press [y] close SLM:', 's');

try 
    f_SLM_BNS_close(ops);
end
if ops.use_TLDC
    TLDC_set_Cam_Close(cam_out.hdl_cam);            
end


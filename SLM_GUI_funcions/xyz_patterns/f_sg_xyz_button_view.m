function f_sg_xyz_button_view(app, view_source, view_out)

%% get coords
if strcmpi(view_source, 'custom')
    coord = f_sg_mpl_get_coords(app, view_source);
elseif strcmpi(view_source, 'table_selection')
    if size(app.UIImagePhaseTableSelection,1) > 0
        coord = f_sg_mpl_get_coords(app, view_source);
    else
        coord = [];
    end
elseif strcmpi(view_source, 'pattern')
    coord = f_sg_mpl_get_coords(app, view_source, app.PatternSpinner.Value);
end

%% gen image and view without saving to buffer
if ~isempty(coord)
    reg1 = f_sg_get_reg_deets(app, app.CurrentregionDropDown.Value);
    
    %holo_phase = f_sg_gen_holo_wgs(app, coord, reg1);
    
    %holo_phase = f_sg_xyz_gen_holo(coord, reg1);
    
    
    %% generate holo (need to apply AO separately for each)                  
    holo_phase = f_sg_PhaseHologram2(coord, reg1);
    
    complex_exp = sum(exp(1i*(holo_phase)).*reshape(coord.weight,[1 1 numel(coord.weight)]),3);

    phase = angle(complex_exp);
    
%     coord0.xyzp = [0 0 0];
%     coord0.weight = 1;         
%     holo_phase0 = f_sg_PhaseHologram(coord0.xyzp,...
%                         sum(reg1.m_idx), sum(reg1.n_idx),...
%                         reg1.NA,...
%                         reg1.objective_RI,...
%                         reg1.wavelength*1e-9,...
%                         reg1.phase_diameter);
    
    %% apply mask
%     num_holo = numel(coord.weight);   
%     for n_holo = 1:num_holo
%         temp_holo = complex_exp(:,:,n_holo);
%         temp_holo(~reg1.holo_mask) = 0;
%         complex_exp(:,:,n_holo) = temp_holo;
%     end
%     holo_phase_corr = holo_phase;
%     
%     if app.ApplyAOcorrectionButton.Value
%         AO_phase = f_sg_AO_get_z_corrections(app, reg1, coord.xyzp(:,3));
% 
%         holo_phase_corr = holo_phase+AO_phase;
%     else
%         holo_phase_corr = holo_phase;
%     end

    %
    %holo_phase0(~reg1.holo_mask) = 0;
    %SLM_phase0 = angle(sum(exp(1i*(holo_phase0)),3));
    %data_holo0 = f_sg_simulate_weights(reg1, SLM_phase0, coord0);

    %I_target = ones(numel(coord.weight),1);
    %w_out = f_sg_optimize_phase_w(app, holo_phase_corr, coord, I_target);

    %sum([w_out.I_final; w_out.data_w.zero_ord_mag])
    
    %weight = coord.weight
    %weight = w_out.w_final;
    %complex_exp = sum(exp(1i*(holo_phase)).*reshape(coord.weight,[1 1 numel(coord.weight)]),3);
    %complex_exp(~reg1.holo_mask) = 0;
    
    
    %figure; imagesc(abs(temp_cmplx))
    %figure; imagesc(angle(temp_cmplx))
    
    %mean(complex_exp(reg1.holo_mask))
    %max(abs(complex_exp(reg1.holo_mask)))
    %min(abs(complex_exp(reg1.holo_mask)))
    
    %complex_exp(reg1.holo_mask) = complex_exp(reg1.holo_mask) - mean(complex_exp(reg1.holo_mask));
    
    %phase = angle(complex_exp);
%     
%     if 0
%         temp_phase = phase;
%         
%         for n1 = 1:10
%             temp_cmplx = exp(1i*temp_phase);
%             disp(mean(temp_cmplx(:)))
%             temp_cmplx = temp_cmplx - mean(temp_cmplx(:));
%             temp_phase = angle(temp_cmplx);
%         end
%         
%         phase = temp_phase;
%     end
    
    
    SLM_phase = app.SLM_phase;
    SLM_phase(reg1.m_idx, reg1.n_idx) = phase;

    %im1 = fftshift(fft2(complex_exp));
    %figure; imagesc(abs(im1))
    
    %SLM_phase = angle(sum(exp(1i*(holo_phase_corr)).*reshape(coord.weight,[1 1 numel(coord.weight)]),3));
    
    if strcmpi(view_out, 'phase')
        f_sg_view_hologram_phase(app, SLM_phase);
        title(sprintf('%s defocus %.1f um', view_source, app.fftdefocusumEditField.Value));
    elseif strcmpi(view_out, 'fft')
        [im_amp, xy_axis] = f_sg_compute_holo_fft(reg1, SLM_phase(reg1.m_idx, reg1.n_idx), app.fftdefocusumEditField.Value);
        if app.fftampsquaredCheckBox.Value
            im_amp = im_amp.^2;
        end
        f_sg_view_hologram_fft(app, im_amp, xy_axis);
        title(sprintf('%s PSF at %.1f um', view_source, app.fftdefocusumEditField.Value));
    end
end

end
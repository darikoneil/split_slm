function [wf_out, params] = f_sg_AO_compute_wf(app, reg_params)
reg1 = f_sg_get_reg_deets(app, reg_params.reg_name); 

params = struct;
params.phase_diameter = reg_params.phase_diameter;
params.AO_iteration = 1;
params.AO_correction = [];
params.SLMm = reg1.SLMm;
params.SLMn = reg1.SLMn;

if app.ApplyAOcorrectionButton.Value
    if isempty(reg_params.AO_correction_fname)
        wf_out = [];
    elseif strcmpi(reg_params.AO_correction_fname, 'none')
        wf_out = [];
    else
        data = load([app.SLM_ops.AO_correction_dir '\' reg_params.AO_correction_fname]);
        if isstruct(data.AO_correction)
            wf_out = struct;
            if isfield(data.AO_correction, 'AO_data')
                wf_out.AO_data = data.AO_correction.AO_data;
            end
            if isfield(data.AO_correction, 'fit_fx') % newest implementation
                wf_out.fit_fx = data.AO_correction.fit_fx;
                max_mode = numel(wf_out.fit_fx);
                maxZn = ceil((-1 + sqrt(1 + 4*max_mode*2))/2)-1;
                zernike_nm_all = f_sg_get_zernike_mode_nm(0:maxZn);
                wf_out.all_modes = f_sg_gen_zernike_modes(reg1, zernike_nm_all);
            elseif isfield(data.AO_correction, 'fit_weights')
                wf_out.fit_weights = data.AO_correction.fit_weights;
                if isfield(data.AO_correction, 'fit_params')
                    z_weight_params = data.AO_correction.fit_params(1);
                elseif isfield(data.AO_correction, 'AO_data')
                    z_weight_params = data.AO_correction.AO_data(1).ao_params;
                end
                if isfield(z_weight_params, 'phase_diameter')
                    params.phase_diameter = z_weight_params.phase_diameter;
                elseif isfield(z_weight_params, 'beam_diameter')
                    params.phase_diameter = z_weight_params.beam_diameter;
                elseif isfield(z_weight_params, 'beam_width')
                    params.phase_diameter = z_weight_params.beam_width;
                end
                wf_out.all_modes = f_sg_AO_compute_wf_core(wf_out.fit_weights, params);
            end
            
            if isfield(data.AO_correction, 'z_weights')
                wf_out.Z_corr = struct();
                for n_corr = 1:numel([data.AO_correction.z_weights])
                    wf_out.Z_corr(n_corr).Z = data.AO_correction.z_weights(n_corr).Z;
                    z_weight_params = data.AO_correction.z_weights(n_corr).ao_params;
                    if isfield(z_weight_params, 'phase_diameter')
                        params.phase_diameter = z_weight_params.phase_diameter;
                    elseif isfield(z_weight_params, 'beam_diameter')
                        params.phase_diameter = z_weight_params.beam_diameter;
                    elseif isfield(z_weight_params, 'beam_width')
                        params.phase_diameter = z_weight_params.beam_width;
                    end
                    full_correction = cat(1,data.AO_correction.z_weights(n_corr).AO_correction{:,1});
                    wf_out.Z_corr(n_corr).wf_out = f_sg_AO_compute_wf_core(full_correction, params);
                end
            end
            
            
        else
            params.phase_diameter = reg1.phase_diameter;

            full_correction = cat(1,data.AO_correction{:,1});

            wf_out = f_sg_AO_compute_wf_core(full_correction, params);

            params.AO_correction = full_correction;
            params.AO_iteration = size(full_correction,1)+1;
        end
    end
else
    wf_out = [];
end
end
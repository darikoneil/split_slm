function f_SLM_BNS512_update(ops, image_pointer)

% loads image
x = calllib('Blink_SDK_C', 'Write_image', ops.sdk, ops.board_number, image_pointer, ops.width*ops.height, ops.wait_For_Trigger, ops.external_Pulse);
% checks if image is complete
% calllib('Blink_SDK_C', 'Is_slm_transient_constructed', ops.sdk);
if ~x
    disp(calllib('Blink_SDK_C', 'Get_last_error_message', ops.sdk));
end

end
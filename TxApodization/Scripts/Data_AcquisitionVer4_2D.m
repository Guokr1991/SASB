% Toolbox needed:
% * Field
%
% Function needed: 
% * Calculate_RTD

% Varargin:
%   * useCaseParams:
%   * transducerType: 
%   * media:
%   * savepath
%   * loadpath
%   * symmetric
%       * symmetric: enforce symmetri arround xmitting reference point
%       * nonsymmetric: alow asymmetri arround xmitting reference point
%   * cutoff
%       * cutoff: the apodization function is truncated to valid size
%       * recalc: the apodization function is recalculated to valid size


function [] = Data_AcquisitionVer4_2D(varargin)
% addpath('Z:\Matlab\SequentialBeamformation\myFun')

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%               Check if number of arguments is correct                 %%
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if(rem(nargin,2) > 0)
    error('Wrong number of arguments')
end
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%                              Parse arguments                          %%
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
useCaseParams = [];
savepath = [];
transducerType = [];
symmetric = 'nonsymmetric';
media = [];
exc_fsXWF = [];
fs_xwf = [];
xmt_impulse_response = [];
xmt_impulse_response_fs = [];
rcv_impulse_response = [];
rcv_impulse_response_fs = [];
debug = 0;
debug_scanlines = 0;
debug_IR = 0;
debug_excitation = '';
debug_plot_emissions = 0;
baffle = 0;
scanlines = [];
display = 1;
max_no_active_elements = 64;
tx_apo = [];
rx_apo = [];
for k = 1:2:nargin
    switch(lower(varargin{k}))
        case{'tx_apo'}
            tx_apo = varargin{k+1};
        case{'rx_apo'}
            rx_apo = varargin{k+1};    
        case{'usecaseparams'}
            useCaseParams = varargin{k+1};
        case{'transducertype'}
            transducerType = varargin{k+1};
        case{'media'}
            media = varargin{k+1};
        case{'savepath'}
            savepath = varargin{k+1};
        case{'symmetric'}
            switch(lower(varargin{k+1}))
                case{'symmetric'}
                    symmetric = 'symmetric';
                case{'nonsymmetric'}    
                    symmetric = 'nonsymmetric';
                otherwise
                    error('Undefined symmetric type')
            end
        case{'excitation_waveform'}
            exc_fsXWF = varargin{k+1};
        case{'excitation_fs'}
            fs_xwf = varargin{k+1};
        case{'xmt_impulse_response'}
            xmt_impulse_response = varargin{k+1};
        case{'xmt_impulse_response_fs'}
            xmt_impulse_response_fs = varargin{k+1};
        case{'rcv_impulse_response'}
            rcv_impulse_response = varargin{k+1};    
        case{'rcv_impulse_response_fs'}
            rcv_impulse_response_fs = varargin{k+1};
        case{'debug'}
            if(ischar(varargin{k+1}))
                switch(lower(varargin{k+1}))
                    case{'off'}
                        debug = 0;
                    case{'on'}
                        debug = 1;
                    otherwise
                        error('Undefined debug type')
                end
            else
                debug = varargin{k+1};
            end
        case{'debug_scanlines'}
            if(ischar(varargin{k+1}))
                switch(lower(varargin{k+1}))
                    case{'off'}
                        debug_scanlines = 0;
                    case{'on'}
                        debug_scanlines = 1;
                    otherwise
                        error('Undefined debug_scanlines type')
                end
            else
                debug_scanlines = varargin{k+1};
            end
        case{'debug_ir'}
            if(ischar(varargin{k+1}))
                switch(lower(varargin{k+1}))
                    case{'off'}
                        debug_IR = 0;
                    case{'on'}
                        debug_IR = 1;
                    otherwise
                        error('Undefined debug_IR type')
                end
            else
                debug_IR = varargin{k+1};
            end
        case{'debug_excitation'}
            if(ischar(varargin{k+1}))
                switch(lower(varargin{k+1}))
                    case{'off'}
                        debug_excitation = '';
                    case{'on'}
                        debug_excitation = 'plot';
                    otherwise
                        error('Undefined debug_excitation type')
                end
            else
                debug_excitation = varargin{k+1};
            end
        case{'debug_plot_emissions'}
            if(ischar(varargin{k+1}))
                switch(lower(varargin{k+1}))
                    case{'off'}
                        debug_plot_emissions = 0;
                    case{'on'}
                        debug_plot_emissions = 1;
                    otherwise
                        error('Undefined debug_plot_emissions type')
                end
            else
                debug_excitation = varargin{k+1};
            end
            
        case{'baffle'}
            if(ischar(varargin{k+1}))
                switch(lower(varargin{k+1}))
                    case{'off'}
                        baffle = 0;
                    case{'on'}
                        baffle = 1;
                    otherwise
                        error('Undefined baffle type')
                end
            else
                baffle = varargin{k+1};
            end
        case{'apodization'}
            switch(lower(varargin{k+1}))
                case{'rect','boxcar'}
                    useCaseParams.bfxmitparams(1).xmitapodishape = 0;
                case{'hamming','hamm'}
                    useCaseParams.bfxmitparams(1).xmitapodishape = 1;
                case{'gauss'}
                    useCaseParams.bfxmitparams(1).xmitapodishape = 2;
                case{'hanning','hann'}
                    useCaseParams.bfxmitparams(1).xmitapodishape = 3;
                case{'black','blackman'}
                    useCaseParams.bfxmitparams(1).xmitapodishape = 4;
                case{'bart','bartlett'}
                    useCaseParams.bfxmitparams(1).xmitapodishape = 5;    
                otherwise
                    error('Undefined apodization type')
            end 
        case{'scanlines'}
            scanlines = varargin{k+1};
        case{'display'}
            display = varargin{k+1};  
        otherwise
            fprintf('This option is not available: %s\n',varargin{k});     
    end 
end

if(isempty(transducerType))
    error('TransducerType was not specified')
end

if(isempty(useCaseParams))
    error('UseCase was not specified')
end


if(isempty(savepath))
    error('Savepath was not specified')
end

if(isempty(media))
    error('Media was not specified')
end

if(~isempty(exc_fsXWF) && isempty(fs_xwf))
    error('Excitation fs was not specified')
end

if(~isempty(xmt_impulse_response) && isempty(xmt_impulse_response_fs))
    error('xmt IR fs was not specified')
end

if(~isempty(rcv_impulse_response) && isempty(rcv_impulse_response_fs))
    error('rcv IR fs was not specified')
end
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Remove Data library and create a new
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if(debug == 0)
    if(display == 1)
        fprintf('********** Data_Acquisition *********************\n');
        fprintf('--> Removing RF Data library\n');
    end
%     if(isdir([savepath 'RF_Data']))
%         rmdir([savepath 'RF_Data'],'s')
%         pause(1)
%     end
%     mkdir([savepath 'RF_Data'])
else
    fprintf('********** Data_Acquisition *********************\n');
    fprintf('--> Working in debug mode.\n')
    fprintf('--> Data will not be generated.\n')
end
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Initialize FieldII parameters
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if useCaseParams.bfrcvparams(1).smpfreq < 120e6,
    fieldII.fs = useCaseParams.bfrcvparams(1).smpfreq * ceil(120e6/useCaseParams.bfrcvparams(1).smpfreq);
else
    fieldII.fs = useCaseParams.bfrcvparams(1).smpfreq;
end
fieldII.c = useCaseParams.scanparams(1).c_sound;
if(display == 1)
    fprintf('--> Initializing Field II parameters\n');
    fprintf('  --> Fs: %d\n',fieldII.fs);
    fprintf('  --> C: %d\n',fieldII.c);

    if(~isempty(exc_fsXWF))
        fprintf('  --> excitation waveform: user specified\n');
    else
        fprintf('  --> excitation waveform: specified in usecase\n');    
    end
end
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Define transducer
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if(isa(transducerType,'transducer'))
    if(display == 1)
        fprintf('--> Transducer was specified outside Data_AcquisitionVer3\n'); 
    end
    TransducerDescription = transducerType;
else
    if(display == 1)
        fprintf('--> Setting up transducer object\n');
    end
    TransducerDescription = transducer('id',transducerType,...
                           'aclayerthickness',useCaseParams.acmodparams(1).layerthickness1 + ...
                                              useCaseParams.acmodparams(1).layerthickness2 + ...
                                              useCaseParams.acmodparams(1).layerthickness3,...
                           'ROC',useCaseParams.acmodparams(1).shellradius,...
                           'nr_elements_x',useCaseParams.acmodparams(1).elements,...
                           'nr_elements_y',0,...
                           'elevation_focus',0); % elevation focus set to zeros for 2d arrays on test bassis
end


if(~isempty(xmt_impulse_response))
    TransducerDescription.set_XMT_IR(xmt_impulse_response,xmt_impulse_response_fs);
end
if(~isempty(rcv_impulse_response))
    TransducerDescription.set_RCV_IR(rcv_impulse_response,rcv_impulse_response_fs);
end
TransducerDescription.set_impulse_response_fs(fieldII.fs);
if(debug_IR == 1)
    TransducerDescription.plot_IR;
end
if(display == 1)
    fprintf('--> Transducer parameters\n');
    fprintf('  --> ID: %s\n',TransducerDescription.id);
    fprintf('  --> type: %s\n',TransducerDescription.type);
    fprintf('  --> ROC: %d\n',TransducerDescription.ROC);
    fprintf('  --> aclayerthickness: %d\n',TransducerDescription.aclayerthickness);
    fprintf('  --> nr of elements x: %d\n',TransducerDescription.nr_elements_x);
    fprintf('  --> nr of elements y: %d\n',TransducerDescription.nr_elements_y);
    fprintf('  --> pitch: %d\n',TransducerDescription.pitch);
    fprintf('  --> elevation_focus: %d\n',TransducerDescription.elevation_focus);
end
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Define Excitation pulse
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if(display == 1)
    fprintf('--> Setting up excitation pulse\n');
end
if(isempty(exc_fsXWF)) % if excitation is not specified - load from usecase
    if(display == 1)
        fprintf('  --> Loading excitation waveform from usecase\n');
    end
    exc_fsXWF = ConvertExcitationCodeToWaveform(...
        useCaseParams.bfxmitparams(1).xwf_binary0);
    fs_xwf = useCaseParams.bfxmitparams(1).xwf_fs;
else
    if(display == 1)
        fprintf('  --> User specified excitation waveform is used\n');
    end
end
if(display == 1)
    fprintf('  --> Resampling waveform if needed\n');
end

if(length(exc_fsXWF) > 1)
    exc_fs = resample(exc_fsXWF,fieldII.fs,fs_xwf);
    fieldII.excitation = exc_fs - repmat(mean(exc_fs),size(exc_fs,1),1);
else
    exc_fs = exc_fsXWF;
    fieldII.excitation = exc_fs;
end


%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Generate transmit scan lines
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
xmt = Generate_Scanlines(useCaseParams, max_no_active_elements, symmetric, 'transmit', debug_scanlines);
if(~isempty(tx_apo))
    xmt.txapo = repmat(tx_apo',361,1);
else
    xmt.txapo = xmt.apo;
end
if(~isempty(rx_apo))
    xmt.rxapo = repmat(rx_apo',361,1);
else
    xmt.rxapo = xmt.apo;
end

plot_setup_for_article =0;
if(plot_setup_for_article)
    fontsize = 20;

    figure(103)
    % p(1) = plot3(xmt.scanline_ref_point(:,1)*1000,xmt.scanline_ref_point(:,2)*1000, xmt.scanline_ref_point(:,3)*1000,'.');
    hold on
    p(2) = plot3(xmt.focus_point(:,1)*1000,xmt.focus_point(:,2)*1000, xmt.focus_point(:,3)*1000,'.');

    for k = 1:1:xmt.no_lines
        plot3([xmt.scanline_ref_point(k,1) xmt.focus_point(k,1)],[xmt.scanline_ref_point(k,2) xmt.focus_point(k,2)],[xmt.scanline_ref_point(k,3) xmt.focus_point(k,3)],'r')
    end
%     p(3) = plot3(TransducerDescription.element_positions(:,1)*1000,...
%                  TransducerDescription.element_positions(:,2)*1000,...
%                  TransducerDescription.element_positions(:,3)*1000,'s');

%     p(11) = plot3(  [TransducerDescription.element_positions(1,1) TransducerDescription.element_positions(64,1) TransducerDescription.element_positions(end,1) TransducerDescription.element_positions(end-63,1) TransducerDescription.element_positions(1,1)]*1000,...
%                 [TransducerDescription.element_positions(1,2) TransducerDescription.element_positions(64,2) TransducerDescription.element_positions(end,2) TransducerDescription.element_positions(end-63,2) TransducerDescription.element_positions(1,2)]*1000,...
%                 [TransducerDescription.element_positions(1,3) TransducerDescription.element_positions(64,3) TransducerDescription.element_positions(end,3) TransducerDescription.element_positions(end-63,3) TransducerDescription.element_positions(1,3)]*1000);

    p(11) = fill3(  [TransducerDescription.element_positions(1,1) TransducerDescription.element_positions(64,1) TransducerDescription.element_positions(end,1) TransducerDescription.element_positions(end-63,1) TransducerDescription.element_positions(1,1)]*1000,...
                [TransducerDescription.element_positions(1,2) TransducerDescription.element_positions(64,2) TransducerDescription.element_positions(end,2) TransducerDescription.element_positions(end-63,2) TransducerDescription.element_positions(1,2)]*1000,...
                [TransducerDescription.element_positions(1,3) TransducerDescription.element_positions(64,3) TransducerDescription.element_positions(end,3) TransducerDescription.element_positions(end-63,3) TransducerDescription.element_positions(1,3)]*1000,[0.5 0.5 0.5]);

%     cmap = flipud(colormap(gray(256)));
%     surface('XData',reshape(TransducerDescription.element_positions(:,1)*1000,64,[]),...
%             'YData',reshape(TransducerDescription.element_positions(:,2)*1000,64,[]),...
%             'ZData',reshape(TransducerDescription.element_positions(:,3)*1000,64,[]),...
%             'CData',reshape(cmap(round(xmt.apo(181,:)*255)+1),64,[]),...
%             'FaceColor','texturemap','EdgeColor','none');

    set(p(2),'Color',[0.2 0.2 0.2])
%     set(p(3),'Color',[0.5 0.5 0.5])

    set(p(11),'FaceColor',[0.5 0.5 0.5])
    xlabel('x-axis [mm]','fontsize',fontsize)
    set(gca,'xtick',[-17.89 0 17.89])
    set(gca,'ytick',[-17.89 0 17.89])
    set(gca,'ztick',[0 40])

    ylabel('y-axis [mm]')
    zlabel('z-axis [mm]')
    set(gca,'ZDir','reverse')
    box on
    cfu_figure_set_font('font_size',fontsize);
    set(gcf,'position',[1360         674         560         420])
    set(gca,'View',[-38 34])
    axis equal



    p(4) = plot3([xmt.scanline_ref_point(1,1) xmt.scanline_direction(1,1)*0.1]*1000,[xmt.scanline_ref_point(1,2) xmt.scanline_direction(1,2)*0.1]*1000, [xmt.scanline_ref_point(1,3) xmt.scanline_direction(1,3)*0.1]*1000,'r');
    p(5) = plot3([xmt.scanline_ref_point(19,1) xmt.scanline_direction(19,1)*0.1]*1000,[xmt.scanline_ref_point(19,2) xmt.scanline_direction(19,2)*0.1]*1000, [xmt.scanline_ref_point(19,3) xmt.scanline_direction(19,3)*0.1]*1000,'r');
    p(6) = plot3([xmt.scanline_ref_point(end-18,1) xmt.scanline_direction(end-18,1)*0.1]*1000,[xmt.scanline_ref_point(end-18,2) xmt.scanline_direction(end-18,2)*0.1]*1000, [xmt.scanline_ref_point(end-18,3) xmt.scanline_direction(end-18,3)*0.1]*1000,'r');
    p(7) = plot3([xmt.scanline_ref_point(end,1) xmt.scanline_direction(end,1)*0.1]*1000,[xmt.scanline_ref_point(end,2) xmt.scanline_direction(end,2)*0.1]*1000, [xmt.scanline_ref_point(end,3) xmt.scanline_direction(end,3)*0.1]*1000,'r');
    p(10) = plot3(  [xmt.scanline_direction(1,1) xmt.scanline_direction(19,1) xmt.scanline_direction(end,1) xmt.scanline_direction(end-18,1) xmt.scanline_direction(1,1)]*0.1*1000,...
                [xmt.scanline_direction(1,2) xmt.scanline_direction(19,2) xmt.scanline_direction(end,2) xmt.scanline_direction(end-18,2) xmt.scanline_direction(1,2)]*0.1*1000,...
                [xmt.scanline_direction(1,3) xmt.scanline_direction(19,3) xmt.scanline_direction(end,3) xmt.scanline_direction(end-18,3) xmt.scanline_direction(1,3)]*0.1*1000)


    p(8)=circle_3D(100,[0 0 0],[0.5 0.5 0],50/180*pi,130/180*pi);
    p(9)=circle_3D(100,[0 0 0],[-0.5 0.5 0],50/180*pi,130/180*pi);
    set(p(8),'color',[0 0 0])
    set(p(9),'color',[0 0 0])
    set(p(10),'color',[0 0 0])
    axis([-60 60 -60 60 0 100])
    hold off
    
    % 
    % 
    % saveas(gcf,['/data/cfudata3/mah/SASB3D/matlab/scan_setup'],'fig')
    % saveas(gcf,['/data/cfudata3/mah/SASB3D/matlab/scan_setup'],'png') 
    % saveas(gcf,['/data/cfudata3/mah/SASB3D/matlab/scan_setup'],'eps') 
    % mlf2pdf(gcf,['/data/cfudata3/mah/SASB3D/matlab/scan_setup'])
    %

    fontsize = 44;
    figure(10)
     mh_apo = mfr_emission(...
    'type',           'dense_64x64', ...
    'no_act_elm',      64*64, ...
    'c',               1540,   ...
    'apo',             xmt.apo(181,:)');
    
    mh_apo.plot_apo

    yh = ylabel('y-axis [mm]');
    xh = xlabel('x-axis [mm]');
    
    
    cfu_figure_set_font('font_size',fontsize);
    set(yh,'position',[-17.3 -0.0594595 1.00084])
    
    set(gca,'position',[ 0.1179    0.3048    0.7290    0.5500])
    ah = get(gcf,'children');
    for k = 1:length(ah)
        if(strcmp(get(ah(k),'Tag'),'Colorbar'))
            set(get(ah(k),'YLabel'),'Position',[ 5.0600    0.4651    9.1603])
        end
    end
%     
%     saveas(gcf,['/data/cfudata3/mah/SASB3D/matlab/sasb_tx_apo'],'fig')
%     saveas(gcf,['/data/cfudata3/mah/SASB3D/matlab/sasb_tx_apo'],'png') 
%     saveas(gcf,['/data/cfudata3/mah/SASB3D/matlab/sasb_tx_apo'],'eps') 
%     mlf2pdf(gcf,['/data/cfudata3/mah/SASB3D/matlab/sasb_tx_apo'])

    
    colorbar off

%     saveas(gcf,['/data/cfudata3/mah/SASB3D/matlab/sasb_rx_apo'],'fig')
%     saveas(gcf,['/data/cfudata3/mah/SASB3D/matlab/sasb_rx_apo'],'png') 
%     saveas(gcf,['/data/cfudata3/mah/SASB3D/matlab/sasb_rx_apo'],'eps') 
% %     mlf2pdf(gcf,['/data/cfudata3/mah/SASB3D/matlab/sasb_rx_apo'])
    
    
        addpat('/home/mah/Papers/Conference/SPIE 2014/mofi_mah/SPIE_2014/matlab/')


    mofi_rx_apo = par_beam_rx_apo;
    mofi_tx_apo = par_beam_tx_apo;
    
    fontsize = 44;
    figure(11)
     mh_apo = mfr_emission(...
    'type',           'dense_64x64', ...
    'no_act_elm',      64*64, ...
    'c',               1540,   ...
    'apo',             mofi_tx_apo);
    
    mh_apo.plot_apo

    yh = ylabel('y-axis [mm]');
    xh = xlabel('x-axis [mm]');
    
        
    cfu_figure_set_font('font_size',fontsize);
    set(yh,'position',[-17.3 -0.0594595 1.00084])
    
    set(gca,'position',[ 0.1179    0.3048    0.7290    0.5500])
    ah = get(gcf,'children');
    for k = 1:length(ah)
        if(strcmp(get(ah(k),'Tag'),'Colorbar'))
            set(get(ah(k),'YLabel'),'Position',[ 5.0600    0.4651    9.1603])
        end
    end
%     

    saveas(gcf,['/data/cfudata3/mah/SASB3D/matlab/pb_tx_apo'],'fig')
    saveas(gcf,['/data/cfudata3/mah/SASB3D/matlab/pb_tx_apo'],'png') 
    saveas(gcf,['/data/cfudata3/mah/SASB3D/matlab/pb_tx_apo'],'eps') 
%     mlf2pdf(gcf,['/data/cfudata3/mah/SASB3D/matlab/sasb_tx_apo'])

    figure(12)
     mh_apo = mfr_emission(...
    'type',           'dense_64x64', ...
    'no_act_elm',      64*64, ...
    'c',               1540,   ...
    'apo',             mofi_rx_apo);
    
    mh_apo.plot_apo

    yh = ylabel('y-axis [mm]');
    xh = xlabel('x-axis [mm]');
    
        
    cfu_figure_set_font('font_size',fontsize);
    set(yh,'position',[-17.3 -0.0594595 1.00084])
    
    set(gca,'position',[ 0.1179    0.3048    0.7290    0.5500])

    colorbar off

    saveas(gcf,['/data/cfudata3/mah/SASB3D/matlab/pb_rx_apo'],'fig')
    saveas(gcf,['/data/cfudata3/mah/SASB3D/matlab/pb_rx_apo'],'png') 
    saveas(gcf,['/data/cfudata3/mah/SASB3D/matlab/pb_rx_apo'],'eps') 
    
end
 

% figure,plot(TransducerDescription.element_positions(:,1),TransducerDescription.element_positions(:,3),'*r')
% hold on
% plot(Geo.element_position_table(:,1),Geo.element_position_table(:,2),'sb')
% hold off
% title('Element positions')

% fprintf('Transducer element pos 1 (x,z): %d / %d\n',...
%     TransducerDescription.element_positions(1,1),TransducerDescription.element_positions(1,3))
% fprintf('Geo element pos 1 (x,z): %d / %d\n',...
%     Geo.element_position_table(1,1),Geo.element_position_table(1,2))

% figure,plot(xmt.scanline_ref_point(:,1),xmt.scanline_ref_point(:,3),'*r')
% hold on
% plot(Geo.scan_line_table(:,2),Geo.scan_line_table(:,3),'sb')
% hold off
% title('Scan line ref positions')

% fprintf('xmt scan line ref pos 1 (x,z): %d / %d\n',...
%     xmt.scanline_ref_point(2,1),xmt.scanline_ref_point(2,3))
% fprintf('Geo scan line ref pos 1 (x,z): %d / %d\n',...
%     Geo.scan_line_table(1,2),Geo.scan_line_table(1,3))

if(display == 1)
    fprintf('--> Generating scan lines\n');
    fprintf('  --> Focus: %d\n', unique(xmt.focus))
    fprintf('  --> F#: %d\n', unique(xmt.fnum))
    fprintf('  --> Nr of lines: %d\n', xmt.no_lines)
    fprintf('  --> Apodization function: %s\n',xmt.apod_fun_name)
end
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Field Initialization
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
field_init(-1) 
% Set the sampling frequency and speed of sound
set_field('fs',fieldII.fs);
set_field('c',fieldII.c);   
if(display == 1)
    fprintf('--> Initializing FieldII\n');
end
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Calculate Round trip delay due to transducer/waveform specification
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if(display == 1)
    fprintf('--> Calculating Round Trip Delay\n');
end
if(size(fieldII.excitation,2) > 1)
    xmt.RT_delay = Calculate_RTD(fieldII.excitation(:,96),TransducerDescription.xmt_impulse_response,TransducerDescription.rcv_impulse_response,fieldII.fs);
else
    xmt.RT_delay = Calculate_RTD(fieldII.excitation(:,1),TransducerDescription.xmt_impulse_response,TransducerDescription.rcv_impulse_response,fieldII.fs);
end
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Generate the transducer apertures for emission and reception
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%   
fieldII.aperture.no_sub_x           = 3;
fieldII.aperture.no_sub_y           = 3;

% create aperture using transducer class
%[rect,center] = TransducerDescription.create_aperture(fieldII.aperture.no_sub_x,fieldII.aperture.no_sub_y);
% create emit aperture in FieldII
%fieldII.emit_aperture = xdc_rectangles(rect, center, [0 0 0]);
% create receive aperture in FieldII
%fieldII.receive_aperture = xdc_rectangles(rect, center, [0 0 0]);

fieldII.emit_aperture = xdc_focused_array(  TransducerDescription.nr_elements_x, ...
                                            TransducerDescription.width, ...
                                            TransducerDescription.height, ...
                                            TransducerDescription.kerf, ...
                                            TransducerDescription.elevation_focus, ...
                                            11, 11, [0 0 0]);
fieldII.receive_aperture = xdc_focused_array(TransducerDescription.nr_elements_x, ...
                                            TransducerDescription.width, ...
                                            TransducerDescription.height, ...
                                            TransducerDescription.kerf, ...
                                            TransducerDescription.elevation_focus, ...
                                            11, 11, [0 0 0]);

% fieldII.emit_aperture = xdc_2d_array(TransducerDescription.nr_elements_x,...
%                                      0, ...
%                                      TransducerDescription.pitch, ...
%                                      TransducerDescription.pitch, ...
%                                      TransducerDescription.kerf, ...
%                                      TransducerDescription.kerf, ...
%                                      ones(TransducerDescription.nr_elements_x,...
%                                           TransducerDescription.nr_elements_y), ...
%                                      fieldII.aperture.no_sub_x , ....
%                                      fieldII.aperture.no_sub_y, ...
%                                      [0 0 0]);
% 
% fieldII.receive_aperture = xdc_2d_array(TransducerDescription.nr_elements_x,...
%                                         0, ...
%                                         TransducerDescription.pitch, ...
%                                         TransducerDescription.pitch, ...
%                                         TransducerDescription.kerf, ...
%                                         TransducerDescription.kerf, ...
%                                         ones(TransducerDescription.nr_elements_x,...
%                                              TransducerDescription.nr_elements_y), ...
%                                         fieldII.aperture.no_sub_x , ....
%                                         fieldII.aperture.no_sub_y, ...
%                                         [0 0 0]);

if(debug == 1)
    try
    % fetch data from Field II
    data = xdc_get(fieldII.receive_aperture,'rect');
    % fetch unique element indexes
    [val index] = unique(data(1,:));
    % fetch data structure from Field II
    data = xdc_get(fieldII.receive_aperture);

    figure;
    TransducerDescription.plot_elements
    TransducerDescription.plot_GeoDebugger_elements
    hold on
    plot(data(24,index)*1000,data(26,index)*1000,'og','displayname','Element center position (FieldII)')
    plot(TransducerDescription.element_positions(:,1)*1000,TransducerDescription.element_positions(:,3)*1000,'xg','displayname','Element center position (transducer)')
    title('FieldII element setup')     
    end
end

% Set excitation waveform of the emit aperture
if(min(size(fieldII.excitation,2),size(fieldII.excitation,1)) > 1) % switch on single or multi excitation wfm
    if(display == 1)
        fprintf('--> Field is using ele_waveform\n');
    end
    ele_waveform(fieldII.emit_aperture,[1:TransducerDescription.nr_elements]', fieldII.excitation'); 
else
    if(display == 1)
        fprintf('--> Field is using xdc_excitation\n');
    end
    xdc_excitation(fieldII.emit_aperture, reshape(fieldII.excitation(:),1,[]));
end

% Set the impulse response for the receive and transmit aperture
xdc_impulse(fieldII.receive_aperture, reshape(TransducerDescription.rcv_impulse_response(:),1,[]));
xdc_impulse(fieldII.emit_aperture, TransducerDescription.xmt_impulse_response); 

% Initialization of delays and RCV apodization
% xdc_apodization(fieldII.receive_aperture,0,ones( 1,TransducerDescription.nr_elements_x*TransducerDescription.nr_elements_y));
xdc_focus_times(fieldII.receive_aperture,0,zeros(1,TransducerDescription.nr_elements_x*TransducerDescription.nr_elements_y));
xdc_focus_times(fieldII.emit_aperture,   0,zeros(1,TransducerDescription.nr_elements_x*TransducerDescription.nr_elements_y));

% Set the soft-baffle option
if(baffle == 1)
    xdc_baffle(fieldII.emit_aperture, 1); 
    xdc_baffle(fieldII.receive_aperture, 1); 
end
% set_field('use_lines', 1);

%% Do imaging
if(display == 1)
    fprintf('--> Calculating field\n');
end
if(isempty(scanlines))
    scanlines = 1:xmt.no_lines;
end

RFdata_temp = zeros(3500,xmt.no_lines);

field_rcv_focus = 1;
if(debug == 0) 
    for lateral_index = scanlines  
        if(rem(lateral_index,ceil(xmt.no_lines/5)) == 0 && display == 1)
            fprintf('Calculating field for line nr. %d of %d\n',lateral_index,xmt.no_lines);
        end
        
        % setup transmit apodization function
        trm_apo = xmt.txapo(lateral_index,:)';
%         trm_apo = xmt.txapo(181,:);
        trm_delay = xmt.delays(lateral_index,:);

        % setup transmit delay profile and apodization function
        xdc_apodization(fieldII.emit_aperture, 0, trm_apo');
        xdc_times_focus(fieldII.emit_aperture,0,trm_delay);
        
        % setup receive delay profile and apodization function
%         xdc_apodization(fieldII.receive_aperture, 0, trm_apo);
%         xdc_times_focus(fieldII.receive_aperture,0,trm_delay);
        
%         
%         figure(4)
%         imagesc(reshape(trm_apo,64,64))
%         
%         figure(5)
%         imagesc(reshape(trm_delay,32,32))
%         drawnow
        % calculate the field
        
        switch(field_rcv_focus)
            case 0
%                 xdc_center_focus(fieldII.emit_aperture, xmt.scanline_ref_point(lateral_index,:));
%                 xdc_center_focus(fieldII.receive_aperture, xmt.scanline_ref_point(lateral_index,:));
%                 keyboard
                [RFdata, tstart] = calc_scat_multi(fieldII.emit_aperture, fieldII.receive_aperture,media.phantom_positions, media.phantom_amplitudes);
                %imagesc(RFdata)
                %drawnow
            case 1
                rrm_apo = xmt.rxapo(lateral_index,:);
                rrm_apo = xmt.rxapo(181,:);
                xdc_apodization(fieldII.receive_aperture,0,rrm_apo);
                xdc_focus_times(fieldII.receive_aperture,0,trm_delay);
% 
%                  xdc_center_focus(fieldII.emit_aperture, xmt.scanline_ref_point(lateral_index,:));
%                  xdc_focus(fieldII.emit_aperture,0,xmt.focus_point(lateral_index,:));
%                  
%                  xdc_center_focus(fieldII.receive_aperture, xmt.scanline_ref_point(lateral_index,:));
%                  xdc_focus(fieldII.receive_aperture,0,xmt.focus_point(lateral_index,:));
                [RFdata, tstart] = calc_scat(fieldII.emit_aperture, fieldII.receive_aperture,media.phantom_positions, media.phantom_amplitudes);
        end
        % Compensation for the response length (excitation and impulse response dependent)        
        tstart = tstart - xmt.RT_delay;

        % Compensation for the height of the TransducerDescription element elevation curvature
%         tstart = tstart - TransducerDescription.calculate_elevation_curvature_delay(fieldII.c);
% keyboard
        % Compensation for the 'time delay-offset' 
        % tstart is the time from the minimum focus time (xdc_times_focus) 
        % to the first signal hits the aperture. If the outher most 
        % elements is excited at time 0 and the center element at time 
        % delta_t, tstart needs to be adjusted for delta_t, such that  
        % tstart = d*2/c where d = focus distance and c speed of
        % sound. This means that delta_t should be substracted from tstart.
         switch(field_rcv_focus)
            case 0
%                tstart = tstart - xmt.delay_offsets(lateral_index);
            case 1
                tstart = tstart - xmt.delay_offsets(lateral_index)*2;
         end
        
        
         
%          t1 = tstart*fieldII.c/2; 
%          
%          x = [t1:1/fieldII.fs*fieldII.c/2:t1+(size(RFdata,1)-1)/fieldII.fs*fieldII.c/2];
%          [amp,xid] = max(abs(hilbert(RFdata(:,65))));
%          x(xid)
%          keyboard
         
        % Downsample RF to scPrm.B.bfrcvparams.smpfreq
        if useCaseParams.bfrcvparams(1).smpfreq < fieldII.fs
            RFdata = downsample(RFdata,fieldII.fs/useCaseParams.bfrcvparams(1).smpfreq);
        end

        % Remove the rf-mean from each channel
%         RFdata = RFdata - repmat(mean(RFdata),size(RFdata,1),1);
        
        switch(field_rcv_focus)
            case 0
                save([savepath 'RF_Data' filesep 'RF_Data_line_nr_' num2str(lateral_index)],...
                    'lateral_index','RFdata','tstart','TransducerDescription','xmt','fieldII','media')
            case 1
                
                RFdata_temp(1:length(RFdata), lateral_index) = RFdata;
                tstart_temp(lateral_index,:) = tstart;
%             
            
                if(lateral_index == scanlines(end))
                    RFdata = RFdata_temp;
                    tstart = tstart_temp;
                    
                    str = sprintf('%sFirst_Stage_RF_Data_Beamformed%ssasbsim%sFirst_Stage_RF_Data_Beamformed.mat',savepath,filesep,filesep);
                
                    [p,n] = fileparts(str);
                  
                    if(isdir([p]))
                        rmdir([p],'s')
                        pause(1)
                    end
                    mkdir([p])
                    
                    save(str,'lateral_index','RFdata','tstart','TransducerDescription','xmt','fieldII','media','useCaseParams')
                    
%                     temp = reshape(RFdata_temp,[],sqrt(xmt.no_lines),sqrt(xmt.no_lines));
%                     
%                     figure(1)
%                     imagesc(abs(hilbert(squeeze(temp(:,11,:)))))
%                     
%                     figure(2)
%                     imagesc(abs(hilbert(squeeze(temp(:,:,11)))))
%                     
                    
%                     drawnow
                
                end
%                 figure(3)
%                 imagesc(abs(hilbert(RFdata_temp)))
%                 drawnow
                
%                 temp = reshape(RFdata_temp,[],sqrt(xmt.no_lines),sqrt(xmt.no_lines));
% 
%                 figure(1)
%                 imagesc(20*log10(abs(hilbert(squeeze(temp(:,sqrt(xmt.no_lines),:))))))
% 
%                 figure(2)
%                 imagesc(20*log10(abs(hilbert(squeeze(temp(:,:,sqrt(xmt.no_lines)))))))


                drawnow
                    
                    

        end
        
    end
else
    if(debug_plot_emissions == 1)
        data_receive = xdc_get(fieldII.receive_aperture);
        data_emit = xdc_get(fieldII.emit_aperture);

        f1 = figure;
        plot(data_receive(24,:),data_receive(26,:),'x')
        hold on
        plot(data_emit(24,:),data_emit(26,:),'o')

        for lateral_index = 1:xmt.no_lines  
            % setup transmit apodization function
            trm_apo = xmt.apo(lateral_index,:);

            apo_temp = trm_apo(trm_apo ~= 0);
            apo_temp = abs(apo_temp./max(apo_temp)-1);
            if(max(apo_temp) ~= 0)
                apo_temp = apo_temp./max(apo_temp)*xmt.focus;
            end

            clf
            set(f1,'Position',[10 700 1904 420])
            plot(TransducerDescription.element_positions(:,1),TransducerDescription.element_positions(:,3),'s','LineWidth',1,'MarkerEdgeColor','k','MarkerFaceColor','none','MarkerSize',12)
            hold on
            plot(TransducerDescription.element_positions(xmt.valid(lateral_index,:) == 1,1),TransducerDescription.element_positions(xmt.valid(lateral_index,:) == 1,3),'s','LineWidth',2,'MarkerEdgeColor','k','MarkerFaceColor','k','MarkerSize',12)
            plot(xmt.focus_point(lateral_index,1),xmt.focus_point(lateral_index,3),'-wx','LineWidth',2,'MarkerEdgeColor','b','MarkerFaceColor','b','MarkerSize',12)
            plot([xmt.scanline_ref_point(lateral_index,1) xmt.focus_point(lateral_index,1)],[xmt.scanline_ref_point(lateral_index,3) xmt.focus_point(lateral_index,3)],'--','color',[0 0 0],'linewidth',2,'DisplayName','Active scanline')
            plot(TransducerDescription.element_positions(xmt.valid(lateral_index,:) == 1,1),apo_temp,'.-','LineWidth',2)

            axis ij
            axis([xmt.scanline_ref_point(lateral_index,1)-32*TransducerDescription.pitch xmt.scanline_ref_point(lateral_index,1)+32*TransducerDescription.pitch -0.001 0.05])
            title(['Transmit setup for scanline ' num2str(lateral_index)],'fontsize',14)
            hold off
            axis image
            axis([min(xmt.focus_point(:,1)) max(xmt.focus_point(:,1)) -0.02 max(0.03,xmt.focus)])
            legend('Element Positions','Transmitting elements','Focus point','Transmit center line','Apodization')
            drawnow 
        end
    end
end
%% Clean-up

% Free space for apertures
xdc_free(fieldII.emit_aperture)
xdc_free(fieldII.receive_aperture)
field_end

if(display == 1)
    fprintf('--> Finished acquiring data\n');
    fprintf('*************************************************\n');
end

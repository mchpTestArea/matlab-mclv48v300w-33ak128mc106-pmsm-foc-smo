%% ************************************************************************
% Model         :   Field Oriented Control of PMSM Using SMO
% Description   :   Set Parameters for FOC of PMSM Using SMO
% File name     :   mchp_pmsm_foc_ips_dsPIC33_data.m
% Copyright 2025 Microchip Technology Inc.

%% Simulation Parameters
clc;
clear all;
%% Set PWM Switching frequency
PWM_frequency 	= 20e3;             %Hz // converter s/w freq
T_pwm           = 1/PWM_frequency;  %s  // PWM switching time period

%% Set Sample Times
Ts          	= T_pwm;        %sec        // simulation time step for controller
Ts_simulink     = T_pwm/2;      %sec        // simulation time step for model simulation
Ts_motor        = T_pwm/2;      %Sec        // Simulation sample time
Ts_inverter     = T_pwm/2;      %sec        // simulation time step for average value inverter
Ts_speed        = 30*Ts;        %Sec        // Sample time for speed controller

%% Set data type for controller & code-gen
dataType        = 'single';    

%% System Parameters
% Set motor parameters

%Long Hurst Motor (Uncomment while using this motor from line below)

pmsm.model          = 'Hurst 300';      %           // Manufacturer Model Number
pmsm.sn             = '123456';         %           // Manufacturer Model Number
pmsm.p              = 5;                    %           // Pole Pairs for the motor
pmsm.Rs             = 0.285;                %Ohm        // Stator Resistor
pmsm.Ld             = 2.8698e-4;            %H          // D-axis inductance value
pmsm.Lq             = 2.8698e-4;            %H          // Q-axis inductance value
pmsm.Lav            = (pmsm.Ld+pmsm.Lq)/2;  %H          // Average inductance
pmsm.Ke             = 7.3425;               %Bemf Const	// Vline_peak/krpm
pmsm.Kt             = 0.274;                %Nm/A       // Torque constant
pmsm.J              = 7.061551833333e-6;     %Kg-m2      // Inertia in SI units
pmsm.B              = 2.636875217824e-6;     %Kg-m2/s    // Friction Co-efficient
pmsm.I_rated        = 3.42*sqrt(2);   %A      	// Rated current (phase-peak)
pmsm.N_max          = 3200;           %rpm        // Max speed
pmsm.N_rated        = 2896;           %rpm        // rated speed
pmsm.f_rated        = (pmsm.N_rated*pmsm.p*2)/120;                %Hz    // Rated Frequency
pmsm.w_rated_elec   = pmsm.f_rated*2*pi;                      %rad/sec    // Rated electrical speed
pmsm.w_base_elec    = pmsm.w_rated_elec*1;                     %rad/sec    // Base electrical speed
pmsm.FluxPM         = (pmsm.Ke)/(sqrt(3)*2*pi*1000*pmsm.p/60);    %PM flux computed from Ke
pmsm.T_rated        = (3/2)*pmsm.p*pmsm.FluxPM*pmsm.I_rated;      %Get T_rated from I_rated
pmsm.QEPSlits       = 1000;

%% Calibration Parameters Hurst 300
CalibSpeed      = 500;          %rpm
CalibId         = 0;
CalibIq         = 1;

CalibFreq       = (CalibSpeed)/60;
CalibTime       = 1/CalibFreq;

CalibVd         = -0.7;
CalibVq         = 2.69;

%% Inverter parameters 

inverter.model         = 'MCLV-48V-300W';           % 		// Manufacturer Model Number
inverter.sn            = 'INV_XXXX';         		% 		// Manufacturer Serial Number
inverter.V_dc          = 24;       					%V      // DC Link Voltage of the Inverter
inverter.ISenseMax     = 22.0441; 					%Amps   // Max current that can be measured
inverter.I_trip        = 10;                  		%Amps   // Max current for trip
inverter.Rds_on        = 1e-3;                      %Ohms   // Rds ON
inverter.Rshunt        = 0.003;                      %Ohms   // Rshunt
inverter.R_board       = inverter.Rds_on + inverter.Rshunt/3;  %Ohms
inverter.MaxADCCnt     = 4095;      				%Counts // ADC Counts Max Value
inverter.invertingAmp  = -1;                        % 		// Non inverting current measurement amplifier
inverter.deadtime      = 1e-6;                      %sec    // Deadtime for the PWM 
inverter.OpampFb_Rf    = 4.99e3;                    %Ohms   // Opamp Feedback resistance for current measurement
inverter.opampInput_R  = 200;                       %Ohms   // Opamp Input resistance for current measurement
inverter.opamp_Gain    = inverter.OpampFb_Rf/inverter.opampInput_R; % // Opamp Gain used for current measurement

%% Derive Characteristics
pmsm.N_base = mcb_getBaseSpeed(pmsm,inverter); %rpm // Base speed of motor at given Vdc

%% PU System details // Set base values for pu conversion
SI_System = mcb_SetSISystem(pmsm);

%% Controller design // Get ballpark values!
% Get PI Gains
PI_params_SI = mcb.internal.SetControllerParameters(pmsm,inverter,SI_System,T_pwm,Ts,Ts_speed);

%Updating delays for simulation
PI_params_SI.delay_Currents    = int32(Ts/Ts_simulink);
PI_params_SI.delay_Position    = int32(Ts/Ts_simulink);
PI_params_SI.delay_Speed       = int32(Ts_speed/Ts_simulink);
% PI_params_SI.delay_Speed1       = (PI_params.delay_IIR + 0.5*Ts)/Ts_speed;


%% PI Parameters for Hurst 300

PI_Kp_id    = 0.852;
PI_Ki_id    = (6.60e2)*Ts;
PI_Kp_iq    = 0.852;
PI_Ki_iq    = (6.60e2)*Ts;
PI_Kp_speed = 0.0062756;
PI_Ki_speed = (1.96e-6);

fc = 10;

%% Serial Communication for Debugging

Ts_serialIn         = 100e-3;
Ts_serialOut        = 500e-6;

target.frameSize    = 120;
target.comport      = 'COM5';
target.BaudRate     = 921659;
classdef PrepMode < Simulink.IntEnumType
  enumeration
    Init(0)
    SensorCalib(1)
    CalcPIGain(2)
  end
end
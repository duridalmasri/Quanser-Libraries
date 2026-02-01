% =========================
% FIX #1: kill old timers
% =========================
oldT = timerfindall('Tag','QCAR_TL_TIMER');
if ~isempty(oldT)
    stop(oldT);
    delete(oldT);
end
clear oldT

%% Configurable Params

% Choose spawn location of QCar
% 1 => calibration location
% 2 => taxi hub area
spawn_location = 1;
trafficLightPeriod = 5;     % seconds

%% Set up QLabs Connection and Variables

% MATLAB Path

newPathEntry = fullfile(getenv('QAL_DIR'), '0_libraries', 'matlab', 'qvl');
pathCell = regexp(path, pathsep, 'split');
if ispc  % Windows is not case-sensitive
  onPath = any(strcmpi(newPathEntry, pathCell));
else
  onPath = any(strcmp(newPathEntry, pathCell));
end

if onPath == 0
    path(path, newPathEntry)
    savepath
end

% Stop RT models
try
    qc_stop_model('tcpip://localhost:17000', 'QCar2_Workspace')
catch error
end
pause(1)

try
    qc_stop_model('tcpip://localhost:17000', 'QCar2_Workspace_studio')
    pause(1)
catch error
end
pause(1)

% QLab connection
qlabs = QuanserInteractiveLabs();
connection_established = qlabs.open('localhost');
pause(0.5);

if connection_established == false
    disp("Failed to open connection.")
    return
end
disp('Connected')
verbose = true;
% =========================
% FIX #2: safe destroy_all (retry + reconnect)
% =========================
pause(0.5);  % let QLabs fully initialize

num_destroyed = 0;
ok = false;

for attempt = 1:3
    try
        num_destroyed = qlabs.destroy_all_spawned_actors();
        ok = true;
        break;
    catch ME
        fprintf("destroy_all failed (attempt %d): %s\n", attempt, ME.message);
        pause(0.5);
    end
end

if ~ok
    error("QLabs is not responding. Close & re-open the Quanser Virtual Stage/QLabs app, then run Setup_Competition_Map again.");
end



%World Objects

cone = QLabsTrafficCone(qlabs);
cone.spawn([1.081, 0.692, 0.006], [0, 0, pi], [0.5, 0.5, 0.5], 0, 1);
cone.spawn([1.220, -0.777, 0.006], [0, 0, pi], [0.5, 0.5, 0.5], 0, 1);
cone.spawn([0.802, 2.769, 0.006], [0, 0, pi], [0.5, 0.5, 0.5], 0, 1);

%% Signage

% stop signs
%parking lot
myStopSign = QLabsStopSign(qlabs);

myStopSign.spawn_degrees([-1.5, 3.6, 0.006], ...
                        [0, 0, -35], ...
                        [0.1, 0.1, 0.1], ...
                        false);  

myStopSign.spawn_degrees([-1.5, 2.2, 0.006], ...
                        [0, 0, 35], ...
                        [0.1, 0.1, 0.1], ...
                        false);

%x+ side
myStopSign.spawn_degrees([2.410, 0.206, 0.006], ...
                        [0, 0, -90], ...
                        [0.1, 0.1, 0.1], ...
                        false); 

myStopSign.spawn_degrees([1.766, 1.697, 0.006], ...
                        [0, 0, 90], ...
                        [0.1, 0.1, 0.1], ...
                        false);

%roundabout signs
myRoundaboutSign = QLabsRoundaboutSign(qlabs);
myRoundaboutSign.spawn_degrees([2.392, 2.522, 0.006], ...
                          [0, 0, -90], ...
                          [0.1, 0.1, 0.1], ...
                          false);

myRoundaboutSign.spawn_degrees([0.698, 2.483, 0.006], ...
                          [0, 0, -145], ...
                          [0.1, 0.1, 0.1], ...
                          false);

myRoundaboutSign.spawn_degrees([0.007, 3.973, 0.006], ...
                        [0, 0, 135], ...
                        [0.1, 0.1, 0.1], ...
                        false);


%yield sign
%one way exit yield
myYieldSign = QLabsYieldSign(qlabs);
myYieldSign.spawn_degrees([0.0, -1.3, 0.006], ...
                          [0, 0, -180], ...
                          [0.1, 0.1, 0.1], ...
                          false);

%roundabout yields
myYieldSign.spawn_degrees([2.4, 3.2, 0.006], ...
                        [0, 0, -90], ...
                        [0.1, 0.1, 0.1], ...
                        false);

myYieldSign.spawn_degrees([1.1, 2.8, 0.006], ...
                        [0, 0, -145], ...
                        [0.1, 0.1, 0.1], ...
                        false);

myYieldSign.spawn_degrees([0.49, 3.8, 0.006], ...
                        [0, 0, 135], ...
                        [0.1, 0.1, 0.1], ...
                        false);


%Signage line guidance (white lines)
mySpline = QLabsBasicShape(qlabs);
mySpline.spawn_degrees ([2.21, 0.2, 0.006], ...
                        [0, 0, 0], ...
                        [0.27, 0.02, 0.001], ...
                        false);

mySpline.spawn_degrees ([1.951, 1.68, 0.006], ...
                        [0, 0, 0], ...
                        [0.27, 0.02, 0.001], ...
                        false);

mySpline.spawn_degrees ([-0.05, -1.02, 0.006], ...
                        [0, 0, 90], ...
                        [0.38, 0.02, 0.001], ...
                        false);

% Flooring

x_offset = 0.13;
y_offset = 1.67;
hFloor = QLabsQCarFlooring(qlabs);
hFloor.spawn_degrees([x_offset, y_offset, 0.001],[0, 0, -90]);

% Spawning crosswalks
myCrossWalk = QLabsCrosswalk(qlabs);
myCrossWalk.spawn_degrees   ([-2 + x_offset, -1.475 + y_offset, 0.01], ...
                            [0,0,0], ...
                            [0.1,0.1,0.075], ...
                            0);

myCrossWalk.spawn_degrees   ([-0.5, 0.95, 0.006], ...
                            [0,0,90], ...
                            [0.1,0.1,0.075], ...
                            0);

myCrossWalk.spawn_degrees   ([0.15, 0.32, 0.006], ...
                            [0,0,0], ...
                            [0.1,0.1,0.075], ...
                            0);

myCrossWalk.spawn_degrees   ([0.75, 0.95, 0.006], ...
                            [0,0,90], ...
                            [0.1,0.1,0.075], ...
                            0);

myCrossWalk.spawn_degrees   ([0.13, 1.57, 0.006], ...
                            [0,0,0], ...
                            [0.1,0.1,0.075], ...
                            0);

myCrossWalk.spawn_degrees   ([1.45, 0.95, 0.006], ...
                            [0,0,90], ...
                            [0.1,0.1,0.075], ...
                            0);

%region: Walls
hWall = QLabsWalls(qlabs);
hWall.set_enable_dynamics(false);

for y = 0:4
    hWall.spawn_degrees([-2.4 + x_offset, (-y*1.0)+2.55 + y_offset, 0.001], [0, 0, 0]);
end

for x = 0:4
    hWall.spawn_degrees([-1.9+x + x_offset, 3.05+ y_offset, 0.001], [0, 0, 90]);
end

for y = 0:5
    hWall.spawn_degrees([2.4+ x_offset, (-y*1.0)+2.55 + y_offset, 0.001], [0, 0, 0]);
end

for x = 0:3
    hWall.spawn_degrees([-0.9+x+ x_offset, -3.05+ y_offset, 0.001], [0, 0, 90]);
end

hWall.spawn_degrees([-2.03 + x_offset, -2.275+ y_offset, 0.001], [0, 0, 48]);
hWall.spawn_degrees([-1.575+ x_offset, -2.7+ y_offset, 0.001], [0, 0, 48]);

%spawn cameras 1. birds eye, 2. edge 1, possess the qcar

camera1Loc = [0.15, 1.7, 5];
camera1Rot = [0, 90, 0];
camera1 = QLabsFreeCamera(qlabs);
camera1.spawn_degrees(camera1Loc, camera1Rot);

camera1.possess();

camera2Loc = [-0.36+ x_offset, -3.691+ y_offset, 2.652];
camera2Rot = [0, 47, 90];
camera2=QLabsFreeCamera(qlabs);
camera2.spawn_degrees (camera2Loc, camera2Rot);

%% Spawn QCar 2 and start rt model

% Use user configured parameters

calibration_location_rotation = [0, 2.13, 0.005, 0, 0, -90];
taxi_hub_location_rotation = [-1.205, -0.83, 0.005, 0, 0, -44.7];

%QCar
myCar = QLabsQCar2(qlabs);

switch spawn_location
    case 1
        spawn = calibration_location_rotation;
    case 2
        spawn = taxi_hub_location_rotation;
end


myCar.spawn_id_degrees(0, spawn(1:3), spawn(4:6), [1/10, 1/10, 1/10], 1);

% Start RT models
file_workspace = fullfile(getenv('RTMODELS_DIR'), 'QCar2', 'QCar2_Workspace_studio.rt-win64');
pause(2)
system(['quarc_run -D -r -t tcpip://localhost:17000 ', file_workspace]);
pause(3)

%% Traffic Lights (non-blocking timer)

try
    % Delete any previous traffic light timer (avoid duplicates)
    oldT = timerfindall('Tag','QCAR_TL_TIMER');
    if ~isempty(oldT)
        stop(oldT);
        delete(oldT);
    end

    clear trafficLight1 trafficLight2 trafficLight3 trafficLight4

    trafficLight1 = QLabsTrafficLight(qlabs);
    trafficLight2 = QLabsTrafficLight(qlabs);
    trafficLight3 = QLabsTrafficLight(qlabs);
    trafficLight4 = QLabsTrafficLight(qlabs);

    % Intersection 1
    trafficLight1.spawn_id_degrees(1, [0.6,  1.55, 0.006], [0,0,0],   [0.1 0.1 0.1], 0, false);
    trafficLight2.spawn_id_degrees(2, [-0.6, 1.28, 0.006], [0,0,90],  [0.1 0.1 0.1], 0, false);
    trafficLight3.spawn_id_degrees(3, [-0.37,0.3,  0.006], [0,0,180], [0.1 0.1 0.1], 0, false);
    trafficLight4.spawn_id_degrees(4, [0.75, 0.48, 0.006], [0,0,-90], [0.1 0.1 0.1], 0, false);

    % Create timer
    tlTimer = timer( ...
        'Tag','QCAR_TL_TIMER', ...
        'ExecutionMode','fixedSpacing', ...
        'Period', trafficLightPeriod, ...
        'BusyMode','drop');

    tlTimer.UserData.flag = 0;

    tlTimer.TimerFcn = @(src,~) trafficLightStep(src, trafficLight1, trafficLight2, trafficLight3, trafficLight4);

    start(tlTimer);
    trafficLightStep(tlTimer, trafficLight1, trafficLight2, trafficLight3, trafficLight4);
    assignin('base','tlTimer', tlTimer);   % so you can stop it from command window

catch ME
    disp(ME.message)
end

function trafficLightStep(src, tl1, tl2, tl3, tl4)
    flag = src.UserData.flag;

    if flag == 0
        tl1.set_color(single(QLabsTrafficLight.COLOR_RED),   false);
        tl3.set_color(single(QLabsTrafficLight.COLOR_RED),   false);
        tl2.set_color(single(QLabsTrafficLight.COLOR_GREEN), false);
        tl4.set_color(single(QLabsTrafficLight.COLOR_GREEN), false);

    elseif flag == 1
        tl1.set_color(single(QLabsTrafficLight.COLOR_RED),    false);
        tl3.set_color(single(QLabsTrafficLight.COLOR_RED),    false);
        tl2.set_color(single(QLabsTrafficLight.COLOR_YELLOW), false);
        tl4.set_color(single(QLabsTrafficLight.COLOR_YELLOW), false);

    elseif flag == 2
        tl1.set_color(single(QLabsTrafficLight.COLOR_GREEN), false);
        tl3.set_color(single(QLabsTrafficLight.COLOR_GREEN), false);
        tl2.set_color(single(QLabsTrafficLight.COLOR_RED),   false);
        tl4.set_color(single(QLabsTrafficLight.COLOR_RED),   false);

    else
        tl1.set_color(single(QLabsTrafficLight.COLOR_YELLOW), false);
        tl3.set_color(single(QLabsTrafficLight.COLOR_YELLOW), false);
        tl2.set_color(single(QLabsTrafficLight.COLOR_RED),    false);
        tl4.set_color(single(QLabsTrafficLight.COLOR_RED),    false);
    end

    src.UserData.flag = mod(flag + 1, 4);
end


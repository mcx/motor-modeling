%%% Solver which iterates in on the optimal phase, instead of searching all
%%% phases at max resolution

format compact
clear all
%%% Generate a Percent Max Torque lookup table %%%

n = 400;  % Phase resolution
n2 = 8; % Current intervals
n3 = 8; % Velocity intervals
tdot_max = 2500;
mag_max = sqrt(3/2)*200;
tdot = linspace(0.01, tdot_max, n3)';

phase_min = pi/2;
phase_max = 2*pi;
tol = (phase_max - phase_min)/n;
%phase_max = 2*pi;

pmi = linspace(1, 0, n2);   %Percent Max current.  Easier to generate table this way, then interpolate torques

mag_vec = linspace(1, sqrt(3/2)*200, n2);
%phase = linspace(phase_min, phase_max, n);

mag_vec = zeros(n3, 1);
mag_log_vec = zeros(n2, n3);
phi_min_vec = zeros(n2, n3);
mag_max_vec = zeros(n2, n3);
tdot_vec = zeros(n2, n3);
torque_min_vec = zeros(n2, n3);
tdot_vec = zeros(n2, n3);
i_mag_vec =  zeros(n2, n3);
percent = zeros(n2, n3);

%%% Find max achievable current and pos/neg torques vs speed %%%    parfor k = 1:n3
for k = 1:n3
    tic
    phi = linspace(phase_min, phase_max, 5)';
    delta = phi(2) - phi(1);
    torque = zeros(5, 1);
    mag = zeros(5, 1);
    parfor x = 1:5
        [torque(x), mag(x)] = motor_fun(mag_max, phi(x), tdot(k));
    end
    tmin = min(torque);
    ind_min = find(torque==tmin);
    ind_min = ind_min(1);
    ind = [ind_min-1; ind_min; ind_min+1];
    while(delta > tol)
        delta = delta/2;

        if(ind(3) > length(phi))
            phi = circshift(phi, -1);
            torque = circshift(torque, -1);
            mag = circshift(mag, -1);
            ind = ind-1;
        elseif (ind(1)==0)
            phi = circshift(phi, 1);
            torque = circshift(torque, 1);
            mag = circshift(mag, 1);
            ind = ind+1;
        end

        phi = [phi(ind(1)); phi(ind(1))+delta; phi(ind(2)); phi(ind(2))+delta; phi(ind(3))];
        [t1, m1] = motor_fun(mag_max, phi(2), tdot(k));
        [t2, m2] = motor_fun(mag_max, phi(4), tdot(k));
        torque = [torque(ind(1));t1; torque(ind(2)); t2; torque(ind(3))];
        mag = [mag(ind(1)); m1; mag(ind(2)); m2; mag(ind(3))];
        tmin = min(torque);
        ind_min = find(torque==tmin);
        ind_min = ind_min(1);
        ind = [ind_min-1; ind_min; ind_min+1];
        %torque_vec = [torque_vec;torque];
        %phase_vec = [phase_vec;phase];
        torque_min_vec(1, k) = max(torque);
        phi_min_vec(1, k) = phi(ind_min);
        mag_max_vec(1, k) = mag(ind_min);
        tdot_vec(1, k) = tdot(k);
    end   
end

max_current = mag_max_vec(1,:);
max_current = min(max_current, mag_max);

tic
parfor j = 1:n2
    
    for k = 1:n3
        phi = linspace(phase_min, phase_max, 5)';
        delta = phi(2) - phi(1);
        torque = zeros(5, 1);
        mag = zeros(5, 1);
        
        for x = 1:5
            [torque(x), mag(x)] = motor_fun(max_current(k)*pmi(j), phi(x), tdot(k));
        end
        tmin = max(torque);
        ind_min = find(torque==tmin);
        ind_min = ind_min(1);
        ind = [ind_min-1; ind_min; ind_min+1];
        while(delta > tol)
            delta = delta/2;

            if(ind(3) > length(phi))
                phi = circshift(phi, -1);
                torque = circshift(torque, -1);
                mag = circshift(mag, -1);
                ind = ind-1;
            elseif (ind(1)==0)
                phi = circshift(phi, 1);
                torque = circshift(torque, 1);
                mag = circshift(mag, 1);
                ind = ind+1;
            end

            phi = [phi(ind(1)); phi(ind(1))+delta; phi(ind(2)); phi(ind(2))+delta; phi(ind(3))];
            [t1, m1] = motor_fun(max_current(k)*pmi(j), phi(2), tdot(k));
            [t2, m2] = motor_fun(max_current(k)*pmi(j), phi(4), tdot(k));
            torque = [torque(ind(1));t1; torque(ind(2)); t2; torque(ind(3))];
            mag = [mag(ind(1)); m1; mag(ind(2)); m2; mag(ind(3))];
            tmin = min(torque);
            ind_min = find(torque==tmin);
            ind_min = ind_min(1);
            ind = [ind_min-1; ind_min; ind_min+1];
            %torque_vec = [torque_vec;torque];
            %phase_vec = [phase_vec;phase];
            torque_min_vec(j, k) = max(torque);
            phi_min_vec(j, k) = phi(ind_min);
            mag_max_vec(j, k) = max_current(k)*pmi(j);%mag(ind_max);
            tdot_vec(j, k) = tdot(k);
        end   
    end

    
end
toc

%figure;plot(tdot, torque_max_vec(1,:)); title('Max Torque')
%figure;plot(tdot, phi_max_vec(1,:));  title('Max Phase')
%figure;plot(tdot, mag_max_vec(1,:)); title('Max Current')
figure; surf(tdot_vec, mag_max_vec, torque_min_vec);
figure;surf(tdot_vec, mag_max_vec, phi_min_vec);
% figure;plot(tdot, i_mag_max_vec); title('Max Current')%figure;plot(tdot, t_max_vec, tdot, t_min_vec); title('Max/Min Torque')
%figure;plot(tdot, phi_max_vec, tdot, phi_min_vec);  title('Max/Min Phase')
%figure;plot(tdot, i_mag_max_vec, tdot, i_mag_min_vec); title('Max/Min Current')

%figure; scatter(phase_vec, torque_vec);
data.tdot = tdot_vec;
data.mag = mag_max_vec;
data.torque = torque_min_vec;
data.phi = phi_min_vec;
%save('data.mat', data);

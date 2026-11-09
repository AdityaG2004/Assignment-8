function zbus_program()
% ZBUS_PROGRAM  Generalized Z-bus building and modification program.
%
%   1. Insert the elements of an N-bus power system.
%   2. Wait for a command to change the network topology.
%   3. Identify the type of change required (Type 1, 2, 3 or 4).
%   4. Modify the Z-bus matrix accordingly and display the new matrix.
%
%   Each element is entered as  [from_bus  to_bus  impedance]
%   Bus 0 is the reference bus. Impedances may be complex, e.g. [1 2 0.1+0.2j]
%   To remove an existing element, enter it again with negative impedance.

clc;
fprintf('========== Z-BUS MATRIX BUILDING AND MODIFICATION ==========\n\n');

% ---------------- Step 1: insert the N-bus system ----------------
N  = input('Number of buses (excluding reference bus 0): ');
ne = input('Number of elements: ');
fprintf('\nEnter each element as [from_bus to_bus impedance]   (reference bus = 0)\n');
F = zeros(1, ne);  T = zeros(1, ne);  Zb = zeros(1, ne);
for k = 1:ne
    e = input(sprintf('  Element %d: ', k));
    F(k) = real(e(1));  T(k) = real(e(2));  Zb(k) = e(3);
end

Z      = zeros(N);        % Z-bus matrix (indexed by bus number)
exists = false(1, N);     % buses already included in Z-bus

% Build Z-bus element by element. An element is added only once it touches
% the reference or an already-included bus, so elements may be entered in any order.
fprintf('\n---------------- Building Z-bus ----------------\n');
pending = 1:ne;
while ~isempty(pending)
    added = false;
    for k = pending
        if is_known(F(k), exists) || is_known(T(k), exists)
            fprintf('\nElement %d: bus %d - bus %d, Zb = %s\n', k, F(k), T(k), cstr(Zb(k)));
            [Z, exists] = modify_zbus(Z, exists, F(k), T(k), Zb(k));
            show_zbus(Z, exists);
            pending(pending == k) = [];
            added = true;
            break;
        end
    end
    if ~added
        fprintf('\nWarning: element(s) %s are not connected to the network and were skipped.\n', ...
                mat2str(pending));
        break;
    end
end

fprintf('\n================ Z-bus of the given system ================\n');
show_zbus(Z, exists);

% ---------------- Step 2-4: wait for topology changes ----------------
while true
    cmd = input(['\nEnter change in topology as [from_bus to_bus impedance]\n' ...
                 '(press Enter to exit): ']);
    if isempty(cmd)
        break;
    end
    [Z, exists] = modify_zbus(Z, exists, real(cmd(1)), real(cmd(2)), cmd(3));
    fprintf('\nNew Z-bus matrix:\n');
    show_zbus(Z, exists);
end
fprintf('\nFinal Z-bus matrix:\n');
show_zbus(Z, exists);
end


% =====================================================================
function [Z, exists] = modify_zbus(Z, exists, p, q, zb)
% Identify the type of modification and update Z-bus.

if p == q || p < 0 || q < 0 || p ~= fix(p) || q ~= fix(q)
    fprintf('Invalid bus numbers. No change made.\n');
    return;
end
kp = is_known(p, exists);
kq = is_known(q, exists);
if ~kp && ~kq
    fprintf('Invalid: both buses are new, element is not connected to the network. No change made.\n');
    return;
end
if ~kp                      % make p the bus already in the network
    [p, q]   = deal(q, p);
    [kp, kq] = deal(kq, kp);
end

if ~kq
    % ---------- q is a NEW bus ----------
    if q > numel(exists)    % grow matrix if a bus beyond N is added
        Z(q, q) = 0;
        exists(end+1:q) = false;
    end
    if p == 0
        fprintf('Type 1: new bus %d connected to reference through Zb = %s\n', q, cstr(zb));
        Z(q, :) = 0;
        Z(:, q) = 0;
        Z(q, q) = zb;
    else
        fprintf('Type 2: new bus %d connected to existing bus %d through Zb = %s\n', q, p, cstr(zb));
        Z(q, :) = Z(p, :);
        Z(:, q) = Z(:, p);
        Z(q, q) = Z(p, p) + zb;
    end
    exists(q) = true;
else
    % ---------- both buses already exist: Kron reduction ----------
    if p == 0
        [p, q] = deal(q, p);
    end
    idx = find(exists);
    if q == 0
        fprintf('Type 3: existing bus %d connected to reference through Zb = %s\n', p, cstr(zb));
        c   = Z(idx, p);
        zth = Z(p, p) + zb;
    else
        fprintf('Type 4: element Zb = %s added between existing buses %d and %d\n', cstr(zb), p, q);
        c   = Z(idx, p) - Z(idx, q);
        zth = Z(p, p) + Z(q, q) - 2*Z(p, q) + zb;
    end
    if abs(zth) < 1e-12
        fprintf('Invalid: this change isolates part of the network (singular). No change made.\n');
        return;
    end
    Z(idx, idx) = Z(idx, idx) - (c * c.') / zth;   % .' = transpose without conjugate
end
end


% =====================================================================
function k = is_known(b, exists)
% True if bus b is the reference or is already in Z-bus.
k = (b == 0) || (b <= numel(exists) && exists(b));
end


% =====================================================================
function show_zbus(Z, exists)
% Display Z-bus with bus numbers.
idx = find(exists);
fprintf('%8s', '');
for j = idx
    fprintf('%20s', sprintf('Bus %d', j));
end
fprintf('\n');
for i = idx
    fprintf('%8s', sprintf('Bus %d', i));
    for j = idx
        fprintf('%20s', cstr(Z(i, j)));
    end
    fprintf('\n');
end
end


% =====================================================================
function s = cstr(z)
% Complex number to string.
if abs(imag(z)) < 1e-12
    s = sprintf('%.4f', real(z));
elseif abs(real(z)) < 1e-12
    s = sprintf('%.4fj', imag(z));
else
    s = sprintf('%.4f%+.4fj', real(z), imag(z));
end
end

# Z-bus Matrix Building and Modification (MATLAB)

EE315 Power Systems – Project/Assignment 8

A generalized MATLAB program to calculate the Z-bus matrix of an N-bus power system and modify it for any change in network topology.

## How it works
1. Insert the elements of an N-bus power system.
2. Wait for a command to change the topology of the network.
3. Identify the type of change required.
4. Modify the Z-bus matrix accordingly and display the new matrix.

| Type | Modification | Update |
|---|---|---|
| 1 | New bus *q* to reference through Zb | Add row/column of zeros, Z_qq = Zb |
| 2 | New bus *q* to existing bus *p* through Zb | Copy row/column *p*, Z_qq = Z_pp + Zb |
| 3 | Existing bus *p* to reference through Zb | Kron reduction: Z = Z − Z_col,p Z_row,p / (Z_pp + Zb) |
| 4 | Zb between existing buses *p* and *q* | Kron reduction: Z = Z − (Z_p − Z_q)(Z_p − Z_q)ᵀ / (Z_pp + Z_qq − 2Z_pq + Zb) |

To **remove** an element, add it again with **negative** impedance (−Zb).

## Usage
Run in MATLAB:
```matlab
zbus_program
```
Enter each element as `[from_bus to_bus impedance]`, with bus `0` as the reference. Complex impedances are allowed, e.g. `[1 2 0.1+0.2j]` or `[1 0 1.25j]`.

### Example
```
Number of buses (excluding reference bus 0): 4
Number of elements: 5
  Element 1: [1 0 1.25j]
  Element 2: [1 2 0.25j]
  Element 3: [2 3 0.4j]
  Element 4: [3 0 1.25j]
  Element 5: [3 4 0.125j]

Enter change in topology as [from_bus to_bus impedance]
(press Enter to exit): [4 1 0.2j]
```

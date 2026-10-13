B1 : CS hold time 



Found by comparing the RTL timing against the datasheet. No hold time was enforced to  fulfil the minimum 20 ns tCSH. Then HOLD state was added into the RTL to fulfil the datasheet spec in Rev. G Table 10 (tCSH ≥ 20 ns). This state hold cs low for 30 ns after the last sclk falling edge. The clean run shows 0 C2 errors, and the measures gap is 30 ns on every transaction. On the fault injection, with the limit raised to 35 ns, C2 fired 7/7, and E2 was correctly skipped by the reset gate.



B2: CS disable time (tCSD)



Found by comparing the RTL timing against the datasheet. No disable time was enforced to fulfil the minimum 20 ns tCSD. Then DISABLE state was added into the RTL to fulfil the datasheet spec in Rev. G Table 10 (tCSD ≥ 20 ns). This state holds cs high for 30 ns. 30 ns is guaranteed by the DISABLE state; 50 ns measure in simulation is due to tb back-to-back stimulus. The clean run shows 0 C3 errors, and the measured gap is 50 ns back-to-back, longer after R1 and after E2. On the fault injection, with the limit raised to 51 ns, C3 fired 5/5. 


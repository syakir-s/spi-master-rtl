**# Bug Log**



Final status: PASS 672 checks, 0 errors (behavioural simulation, XSim). 2 DUT issues found in design review; 4 TB issues found and fixed



**## B1 : CS hold time**



Found by comparing the RTL timing against the datasheet. No hold time was enforced to  fulfil the minimum 20 ns tCSH. Then HOLD state was added into the RTL to fulfil the datasheet spec in Rev. G Table 10 (tCSH ≥ 20 ns). This state holds cs low for 30 ns after the last sclk falling edge. The clean run shows 0 C2 errors, and the measured gap is 30 ns on every transaction. On the fault injection, with the limit raised to 35 ns, C2 fired 7/7, and E2 was correctly skipped by the reset gate.



**## B2: CS disable time (tCSD)**



Found by comparing the RTL timing against the datasheet. No disable time was enforced to fulfil the minimum 20 ns tCSD. Then DISABLE state was added into the RTL to fulfil the datasheet spec in Rev. G Table 10 (tCSD ≥ 20 ns). This state holds cs high for 30 ns. 30 ns is guaranteed by the DISABLE state; 50 ns measured in simulation is due to tb back-to-back stimulus. The clean run shows 0 C3 errors, and the measured gap is 50 ns back-to-back, longer after R1 and after E2. On the fault injection, with the limit raised to 51 ns, C3 fired 5/5.



**## B3: same-timestep races in TB monitors**



I1: Found when the predicted I1 PASS count (6) did not match the simulation log (5).



P2 tHD: Found when the P2 tHD test reported false violation messages on a correct DUT.



C1: Found in code review before simulation: the check could read sclk\_count as 0, before the increment occurs, skip the first edge, and pass even on broken tCSS timing.



Root cause: two processes are triggered in the same timestep, and the simulator does not guarantee which runs first.



Fix I1: Added @(posedge iclk) before the R1 test to prevent R1's rst = 1 on the same timestep so the rst rises one clock after I3's busy falls. I1's check now runs while the rst is still low.



Fix P2 tHD: Change the @(sclk) to @(mosi) to prevent the timing snapshot and the check sharing the same event.



Fix C1: Nest the C1 check into the same block as the sclk\_count increment, and placed after it, so the check always sees the updated count (1 on the first edge).



Verified by:



I1: The log now shows I3’s I1 PASS line before R1; 7 I1 PASS lines in total, one per non-reset transaction.



P2 tHD: No P2 tHD test reported error message.



C1: Fault injection is made; raised the limit from 100 to 101, which fired 8/8, once per transaction. Firing at exactly 100 ns proves the check runs on the first sclk edge. On clean run there is no C1 error.



**## B4: E2 test couldn’t fail**



Found in review after the first E2 run passed, by asking whether the check could ever fail.



Symptom: The rst = 1 is on the 2500 ns (ADDRESS phase) into the E2 transaction which the data\_out was already data\_out = 0xFF from R1's rst = 1, so the E2 would always give PASS, whatever E2's rst state was.



Root cause: The expected value was already there due to previous R1's rst = 1, so the check could not catch any changes in the latest transaction.



Fix: Moved the rst = 1 to 4100 ns (DATA phase) into the transaction and added a 20 ns (2-cycle) settle delay before the check.



Verified by: Waveform at E2’s reset: just before reset (\~33,411 ns) data\_out = 0xAF, partly overwritten by the read of 0xAB; after reset it returns to 0xFF and the E2 check passes. If reset failed, data\_out would stay 0xAF and the check would fail. Verified by waveform; no fault-injection was made.



**## B5: C2 depended on P4’s condition**



Found when code review the C2 draft.



Symptom: The original code C2 condition included sclk\_count == 24, intended to select the last sclk edge.



Root cause: The sclk\_count made C2 depend on P4’s pass condition; a pulse-count bug would hide the tCSH bug.



Fix: Remove the sclk\_count == 24 in the condition so the C2's test runs independently from the P4's test; C2's test now checks on every non-reset transaction.



Verified by: Clean run: 0 C2 errors appeared; fault injection: increased the limit 20 → 35 fired 7/7 at gap = 30 ns and skipped transaction with rst = 1.



**## B6: C3 guard used the wrong variable, plus the reset-time edge**



Found in code review of the C3 draft.



Symptom:



1. The original code included t\_csh != 0 condition instead of t\_csd, a copy paste error from the C2's test code.
2. No !rst gate on the @(posedge cs) snapshot. At simulation start, while rst = 1, the cs transition from x → 1, counts as posedge, so fake rise time would be recorded and T1 would be treated as real tCSD case.	

&#x20;



Root cause: 	



1\. Copy-paste variable from C2's test code.

2\. x → 1 counts as a posedge in Verilog.

&#x09;

Fix: 		



1\. Guard changed to t\_csd != 0.

2\. !rst gate added to the snapshot block, so rises while rst = 1 are not recorded



Verified by: Fault-injection: increased the limit 20 → 51 fired 5/5 (gap 50 ns), no error showed near T1's test (\~35 ns), proving fake rises was not recorded; clean run: 0 C3 errors.



**## Known Limitations**



* tCSS has zero margin: met at exactly the minimum value 100ns Rev. G Table 10 (tCSS ≥ 100 ns). Left as is and documented.



* P2 (tSU/tHD) monitors not fault-injected



* P3 (MSB-first) has no dedicated monitor: covered indirectly by T1/T2/E1/E3, because the byte values only match if the bit order is correct.



* E2 is verified by waveform only, not fault-injected (from B4).



* Simulation only: behavioural sim in XSim; not validated on hardware (Nexys A7 / real ADXL362).



* Scope: single-byte register read/write only; no FIFO read (0x0D) or multi-byte burst.

&#x20;

